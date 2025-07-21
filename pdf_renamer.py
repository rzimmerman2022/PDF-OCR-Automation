#!/usr/bin/env python3
"""
PDF AI Renaming Script - Uses Gemini AI to analyze and rename PDF files
Part of the PDF-OCR-Automation System

This script serves as the AI-powered analysis component that:
1. Extracts text content from PDF files
2. Analyzes content using Google's Gemini AI
3. Generates descriptive filenames based on document content
4. Handles batch processing with cost tracking
5. Provides both dry-run and live renaming modes

Author: PDF-OCR-Automation System
Version: 2.0
"""

import os
import sys
import json
import re
import time
from pathlib import Path
from datetime import datetime
import PyPDF2
import google.generativeai as genai
from typing import List, Dict, Tuple, Optional

def load_env():
    """
    Load environment variables from .env file if it exists
    
    This function automatically loads API keys and configuration from a .env file
    in the script's directory, eliminating the need to set system environment variables.
    Supports both quoted and unquoted values, and ignores comment lines.
    """
    env_path = Path(__file__).parent / '.env'
    if env_path.exists():
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key] = value.strip('"').strip("'")

load_env()

class PDFAnalyzer:
    def __init__(self, api_key: str = None, dry_run: bool = False):
        self.api_key = api_key or os.environ.get('GEMINI_API_KEY')
        if not self.api_key:
            raise ValueError("No API key provided. Set GEMINI_API_KEY or pass via parameter.")
        
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel('gemini-1.5-flash')
        self.dry_run = dry_run
        
        # Cost tracking
        self.cost_per_pdf = 0.0001  # Estimated cost per PDF analysis
        self.total_cost = 0.0
        self.files_processed = 0
        
    def extract_text(self, pdf_path: str, max_pages: int = 5) -> str:
        """Extract text from PDF file"""
        try:
            text = ""
            with open(pdf_path, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)
                num_pages = min(len(pdf_reader.pages), max_pages)
                
                for page_num in range(num_pages):
                    page = pdf_reader.pages[page_num]
                    text += page.extract_text() + "\n"
                    
            return text[:5000]  # Limit text length for API
        except Exception as e:
            print(f"[ERROR] Failed to extract text from {pdf_path}: {str(e)}")
            return ""
    
    def generate_filename(self, text: str, current_filename: str) -> Tuple[str, Dict]:
        """Generate new filename based on content analysis"""
        prompt = f"""Analyze this document content and suggest a descriptive filename.

Current filename: {current_filename}
Content excerpt:
{text[:2000]}

Rules:
1. Use format: DocumentType_MainSubject_KeyIdentifier_Date
2. Keep under 60 characters
3. Use underscores, no spaces
4. Include date if found (YYYY-MM-DD format)
5. Be specific about document type (Invoice, Report, Contract, Manual, etc.)
6. Include key identifiers (company names, invoice numbers, etc.)

Return JSON with:
{{
    "filename": "suggested_filename_without_extension",
    "document_type": "type of document",
    "key_info": "brief summary of key information",
    "confidence": "high/medium/low"
}}"""

        try:
            response = self.model.generate_content(prompt)
            result = json.loads(response.text)
            
            # Sanitize filename
            filename = result.get('filename', 'Unknown_Document')
            filename = re.sub(r'[<>:"/\\|?*]', '_', filename)
            filename = filename[:60]  # Limit length
            
            return filename, result
            
        except Exception as e:
            print(f"[ERROR] AI analysis failed: {str(e)}")
            # Fallback naming
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            return f"Document_{timestamp}", {
                "document_type": "Unknown",
                "key_info": "Analysis failed",
                "confidence": "low"
            }
    
    def process_pdf(self, pdf_path: str) -> Dict:
        """Process a single PDF file"""
        result = {
            "original_path": pdf_path,
            "original_name": os.path.basename(pdf_path),
            "status": "pending",
            "new_name": None,
            "analysis": {},
            "error": None
        }
        
        try:
            # Extract text
            print(f"[INFO] Extracting text from: {os.path.basename(pdf_path)}")
            text = self.extract_text(pdf_path)
            
            if not text.strip():
                result["status"] = "error"
                result["error"] = "No text extracted - may need OCR"
                return result
            
            # Generate new filename
            print(f"[INFO] Analyzing content with AI...")
            new_name, analysis = self.generate_filename(text, result["original_name"])
            
            # Add extension
            new_name = new_name + ".pdf"
            result["new_name"] = new_name
            result["analysis"] = analysis
            
            # Check if rename needed
            if result["original_name"].lower() == new_name.lower():
                result["status"] = "skip"
                print(f"[INFO] File already has appropriate name")
            else:
                if self.dry_run:
                    result["status"] = "dry_run"
                    print(f"[DRY RUN] Would rename: {result['original_name']} -> {new_name}")
                else:
                    # Perform actual rename
                    new_path = os.path.join(os.path.dirname(pdf_path), new_name)
                    
                    # Handle duplicate names
                    if os.path.exists(new_path) and new_path != pdf_path:
                        base, ext = os.path.splitext(new_name)
                        counter = 1
                        while os.path.exists(new_path):
                            new_name = f"{base}_{counter}{ext}"
                            new_path = os.path.join(os.path.dirname(pdf_path), new_name)
                            counter += 1
                        result["new_name"] = new_name
                    
                    os.rename(pdf_path, new_path)
                    result["status"] = "renamed"
                    print(f"[SUCCESS] Renamed: {result['original_name']} -> {new_name}")
            
            # Update cost tracking
            self.files_processed += 1
            self.total_cost += self.cost_per_pdf
            print(f"[COST] Running total: ${self.total_cost:.4f} ({self.files_processed} files)")
            
        except Exception as e:
            result["status"] = "error"
            result["error"] = str(e)
            print(f"[ERROR] Failed to process {pdf_path}: {str(e)}")
        
        return result
    
    def process_files(self, file_paths: List[str]) -> List[Dict]:
        """Process multiple PDF files"""
        results = []
        
        print(f"\n[INFO] Processing {len(file_paths)} files...")
        print(f"[INFO] Mode: {'DRY RUN' if self.dry_run else 'LIVE PROCESSING'}")
        
        for i, file_path in enumerate(file_paths, 1):
            print(f"\n[{i}/{len(file_paths)}] Processing: {os.path.basename(file_path)}")
            result = self.process_pdf(file_path)
            results.append(result)
            
            # Output result as JSON for PowerShell
            print(f"RESULT_JSON: {json.dumps(result)}")
            sys.stdout.flush()
            
            # Rate limiting
            if i < len(file_paths):
                time.sleep(0.5)
        
        # Summary
        summary = {
            "total_processed": len(results),
            "successful": len([r for r in results if r["status"] in ["renamed", "dry_run"]]),
            "skipped": len([r for r in results if r["status"] == "skip"]),
            "errors": len([r for r in results if r["status"] == "error"]),
            "dry_run": self.dry_run,
            "total_cost": round(self.total_cost, 4),
            "cost_per_file": self.cost_per_pdf
        }
        
        print(f"\n[SUMMARY] Processed: {summary['total_processed']} files")
        print(f"[SUMMARY] Successful: {summary['successful']}, Skipped: {summary['skipped']}, Errors: {summary['errors']}")
        print(f"[SUMMARY] Total cost: ${summary['total_cost']:.4f}")
        print(f"SUMMARY_JSON: {json.dumps(summary)}")
        
        return results

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='AI-powered PDF file renaming')
    parser.add_argument('files', nargs='+', help='PDF files to process')
    parser.add_argument('--api-key', help='Gemini API key')
    parser.add_argument('--dry-run', action='store_true', help='Preview changes without renaming')
    
    args = parser.parse_args()
    
    try:
        analyzer = PDFAnalyzer(api_key=args.api_key, dry_run=args.dry_run)
        results = analyzer.process_files(args.files)
        
        # Save results log
        log_data = {
            "timestamp": datetime.now().isoformat(),
            "results": results,
            "dry_run": args.dry_run
        }
        
        log_file = Path(__file__).parent / f"rename_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(log_file, 'w', encoding='utf-8') as f:
            json.dump(log_data, f, indent=2, ensure_ascii=True)
        
        print(f"\n[INFO] Log saved to: {log_file}")
        
    except Exception as e:
        print(f"[FATAL] {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()