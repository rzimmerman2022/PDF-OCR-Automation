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
from tqdm import tqdm

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
    def __init__(self, api_key: str = None):
        self.api_key = api_key or os.environ.get('GEMINI_API_KEY')
        if not self.api_key:
            raise ValueError("No API key provided. Set GEMINI_API_KEY or pass via parameter.")
        
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel('gemini-2.5-flash')
        
        # Cost tracking - Gemini 2.5 Flash pricing
        # Assuming ~1000 tokens per PDF analysis (500 input + 500 output)
        # Output tokens: $0.60/M tokens = $0.0006 per 1000 tokens
        self.cost_per_pdf = 0.0006  # Updated cost estimate
        self.total_cost = 0.0
        self.files_processed = 0
        self.total_input_tokens = 0
        self.total_output_tokens = 0
        
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
        prompt = f"""You are an expert document analyst. Create a standardized filename following ISO 8601 and industry best practices.

Current filename: {current_filename}
Content excerpt:
{text[:2000]}

ENHANCED NAMING CONVENTION - ISO STANDARD WITH DESCRIPTIVE CONTENT:
The filename MUST follow this exact pattern:
YYYYMMDD_DocType_Description_Entity_ID

COMPONENTS (in order):
1. DATE PREFIX (MANDATORY): YYYYMMDD format (ISO 8601)
   - Use document date if found in content
   - Use today's date ({datetime.now().strftime('%Y%m%d')}) if no date found
   - ALWAYS start filename with date

2. DOCUMENT TYPE (MANDATORY): Use full descriptive names
   - Invoice
   - Contract
   - Report
   - Letter
   - Will
   - Trust
   - Waiver
   - Agreement
   - Certificate
   - Legal
   - Financial
   - Medical
   - Correspondence

3. DESCRIPTION (MANDATORY): Brief descriptive content
   - What the document is about (3-5 words)
   - Key subject matter
   - Main purpose
   - Use TitleCase
   - Examples: "EstatePlanning", "PropertySale", "QuarterlyFinancials"

4. ENTITY (MANDATORY): Primary organization/person
   - Full name or company (can abbreviate if too long)
   - Person's full last name
   - Use TitleCase

5. IDENTIFIER (OPTIONAL): Reference numbers
   - Case numbers (e.g., 24PR371)
   - Invoice numbers
   - Account numbers
   - Keep original format

RULES:
- Total length: Maximum 100 characters (increased for clarity)
- Use underscores (_) between components
- Use hyphens (-) within components if needed
- NO spaces anywhere
- TitleCase for all text components
- Keep numbers as-is

EXAMPLES:
- 20241119_Trust_LettersOfAdministration_RoganEstate_24PR371
- 20240422_Waiver_ConsentInformalAdmin_RoganDennis_24PR
- 20240115_Invoice_ConsultingServices_AcmeCorp_2024-001
- 20240301_Report_QuarterlyFinancialSummary_FinanceDept_Q1-2024
- 20240720_Contract_RealEstatePurchase_SmithJohn_SALE2024
- 20250722_Correspondence_EmailChain_ClientComms_Case123

Return JSON with:
{{
    "filename": "complete_filename_without_extension",
    "document_type": "full type name (e.g., Invoice, Contract, Trust)",
    "description": "brief description used in filename",
    "entity": "primary entity name",
    "identifier": "reference number if any",
    "date_used": "YYYYMMDD date used in filename",
    "date_source": "where date came from (document/today)",
    "key_info": "one-line summary of document content",
    "confidence": "high/medium/low"
}}"""

        try:
            response = self.model.generate_content(prompt)
            response_text = response.text.strip()
            
            # Try to extract JSON from the response
            # Sometimes Gemini adds markdown formatting
            if "```json" in response_text:
                response_text = response_text.split("```json")[1].split("```")[0].strip()
            elif "```" in response_text:
                response_text = response_text.split("```")[1].split("```")[0].strip()
            
            result = json.loads(response_text)
            
            # Sanitize filename
            filename = result.get('filename', 'Unknown_Document')
            filename = re.sub(r'[<>:"/\\|?*]', '_', filename)
            filename = filename[:100]  # Increased limit to 100 chars for descriptive names
            
            # Track token usage for accurate cost calculation
            self.total_input_tokens += len(prompt.split()) * 1.3  # Rough estimate
            self.total_output_tokens += len(response_text.split()) * 1.3
            
            return filename, result
            
        except json.JSONDecodeError as e:
            print(f"[ERROR] Failed to parse AI response as JSON: {str(e)}")
            print(f"[DEBUG] Raw response: {response.text[:200]}...")
            # Fallback naming - follows enhanced format
            today = datetime.now().strftime("%Y%m%d")
            return f"{today}_Document_UnknownContent_Unknown", {
                "document_type": "Document",
                "description": "UnknownContent",
                "entity": "Unknown",
                "identifier": "",
                "date_used": today,
                "date_source": "today",
                "key_info": "JSON parsing failed",
                "confidence": "low"
            }
        except Exception as e:
            print(f"[ERROR] AI analysis failed: {str(e)}")
            # Fallback naming - follows enhanced format
            today = datetime.now().strftime("%Y%m%d")
            return f"{today}_Document_AnalysisFailed_Unknown", {
                "document_type": "Document",
                "description": "AnalysisFailed",
                "entity": "Unknown",
                "identifier": "",
                "date_used": today,
                "date_source": "today",
                "key_info": f"Analysis failed: {str(e)}",
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
            
        except Exception as e:
            result["status"] = "error"
            result["error"] = str(e)
            print(f"[ERROR] Failed to process {pdf_path}: {str(e)}")
        
        return result
    
    def process_files(self, file_paths: List[str]) -> List[Dict]:
        """Process multiple PDF files"""
        results = []
        
        print(f"\n[INFO] Processing {len(file_paths)} files...")
        print(f"[INFO] Using Gemini 2.5 Flash AI Model")
        print(f"[INFO] Estimated cost: ${self.cost_per_pdf:.4f} per file")
        print(f"\n" + "="*60 + "\n")
        
        # Create progress bar with custom format
        pbar_format = '{desc}: {percentage:3.0f}%|{bar}| {n_fmt}/{total_fmt} [Cost: ${postfix[0]:.4f}]'
        with tqdm(total=len(file_paths), desc="Processing PDFs", 
                 bar_format=pbar_format, postfix=[0.0]) as pbar:
            
            for i, file_path in enumerate(file_paths):
                # Update progress bar description
                pbar.set_description(f"Processing: {os.path.basename(file_path)[:30]}...")
                
                result = self.process_pdf(file_path)
                results.append(result)
                
                # Update progress bar with cost
                pbar.postfix[0] = self.total_cost
                pbar.update(1)
                
                # Output result as JSON for PowerShell
                print(f"\nRESULT_JSON: {json.dumps(result)}")
                sys.stdout.flush()
                
                # Rate limiting
                if i < len(file_paths) - 1:
                    time.sleep(0.5)
        
        # Summary
        summary = {
            "total_processed": len(results),
            "successful": len([r for r in results if r["status"] == "renamed"]),
            "skipped": len([r for r in results if r["status"] == "skip"]),
            "errors": len([r for r in results if r["status"] == "error"]),
            "total_cost": round(self.total_cost, 4),
            "cost_per_file": self.cost_per_pdf,
            "model_used": "gemini-2.5-flash"
        }
        
        print(f"\n\n" + "="*60)
        print(f"[SUMMARY] Processing Complete!")
        print(f"[SUMMARY] Files Processed: {summary['total_processed']}")
        print(f"[SUMMARY] Successfully Renamed: {summary['successful']}")
        print(f"[SUMMARY] Skipped (already named): {summary['skipped']}")
        print(f"[SUMMARY] Errors: {summary['errors']}")
        print(f"[SUMMARY] Total AI Cost: ${summary['total_cost']:.4f}")
        print(f"[SUMMARY] Model Used: {summary['model_used']}")
        print("="*60)
        print(f"\nSUMMARY_JSON: {json.dumps(summary)}")
        
        return results

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='AI-powered PDF file renaming using Gemini 2.5')
    parser.add_argument('files', nargs='+', help='PDF files to process')
    parser.add_argument('--api-key', help='Gemini API key')
    
    args = parser.parse_args()
    
    try:
        analyzer = PDFAnalyzer(api_key=args.api_key)
        results = analyzer.process_files(args.files)
        
        # Save results log
        log_data = {
            "timestamp": datetime.now().isoformat(),
            "results": results,
            "model": "gemini-2.5-flash",
            "total_cost": analyzer.total_cost
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