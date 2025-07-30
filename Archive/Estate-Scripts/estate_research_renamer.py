#!/usr/bin/env python3
"""
Estate Research Project - AI-Powered PDF File Naming System
Implements the Dennis Rogan Real Estate Research Project SOP v1.2

File Naming Convention:
YYYYMMDD_MatterID_LastName_FirstName_MiddleName_Dept_DocType_Subtype_Lifecycle_SecTag_LegalDescription.ext
"""

import os
import re
import json
import sys
from datetime import datetime
from pathlib import Path
import PyPDF2
import google.generativeai as genai
from typing import Dict, Tuple, Optional
from tqdm import tqdm

# Load environment variables
def load_env():
    """Load environment variables from .env file"""
    env_path = Path(__file__).parent / '.env'
    if env_path.exists():
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key] = value
                    
load_env()

class EstateResearchRenamer:
    """PDF renamer following Estate Research Project naming conventions"""
    
    # Department codes
    DEPARTMENTS = {
        'legal': 'LEG',
        'financial': 'FIN', 
        'administrative': 'ADM',
        'tax': 'TAX',
        'insurance': 'INS',
        'real estate': 'REI'
    }
    
    # Security tags
    SECURITY_TAGS = {
        'public': 'P',
        'internal': 'I',
        'confidential': 'C',
        'strictly confidential': 'S',
        'regulated': 'R'
    }
    
    def __init__(self, api_key: str = None):
        self.api_key = api_key or os.environ.get('GEMINI_API_KEY')
        if not self.api_key:
            raise ValueError("No API key provided. Set GEMINI_API_KEY or pass via parameter.")
        
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel('gemini-2.5-flash')
        
        # Cost tracking
        self.cost_per_pdf = 0.0006
        self.total_cost = 0.0
        self.files_processed = 0
        
    def extract_text(self, pdf_path: str, max_pages: int = 10) -> str:
        """Extract text from PDF file"""
        try:
            text = ""
            with open(pdf_path, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)
                num_pages = min(len(pdf_reader.pages), max_pages)
                
                for page_num in range(num_pages):
                    page = pdf_reader.pages[page_num]
                    page_text = page.extract_text()
                    if page_text:
                        text += page_text + "\n"
                        
            return text.strip()
        except Exception as e:
            print(f"[ERROR] Failed to extract text: {str(e)}")
            return ""
            
    def analyze_with_ai(self, text: str, current_filename: str) -> Tuple[str, Dict]:
        """Use Gemini AI to analyze document and generate filename"""
        
        prompt = f"""Analyze this document for the Dennis Rogan Real Estate Research Project and generate a filename following this EXACT convention:

NAMING STRUCTURE (use underscore between ALL fields):
YYYYMMDD_MatterID_LastName_FirstName_MiddleName_Dept_DocType_Subtype_Lifecycle_SecTag_LegalDescription

FIELD RULES:
1. YYYYMMDD: Document date in 8-digit format (execution date for legal docs, correspondence date, etc.)
2. MatterID: Case/matter ID (convert hyphens to underscores, e.g., 24-PR-371 becomes 24_PR_371)
3. LastName_FirstName_MiddleName: Primary person (e.g., Rogan_Dennis_William)
4. Dept: Department code - MUST be one of: LEG, FIN, ADM, TAX, INS, REI
5. DocType_Subtype: Document classification (e.g., Amendment_Trust, Certificate_Death, Correspondence_Vendor)
6. Lifecycle: Document version - MUST be one of: D1/D2 (draft), S1/S2 (signed), A1/A2 (amendment), F1/F2 (final), OCR, BK
7. SecTag: Security level - MUST be one of: P (public), I (internal), C (confidential), S (strictly confidential), R (regulated)
8. LegalDescription: Concise description, TitleCase, no spaces (use underscores)

Current filename: {current_filename}
Content excerpt: {text[:2000]}

Return JSON with these EXACT fields:
{{
    "date": "YYYYMMDD format",
    "matter_id": "case ID with hyphens converted to underscores",
    "last_name": "last name",
    "first_name": "first name", 
    "middle_name": "middle name or empty string",
    "dept_code": "3-letter department code from list above",
    "doc_type": "document type",
    "subtype": "document subtype",
    "lifecycle": "lifecycle code from list above",
    "security_tag": "1-letter security code from list above",
    "legal_description": "concise description in TitleCase with underscores",
    "filename": "complete filename without extension",
    "confidence": "high/medium/low",
    "reasoning": "brief explanation of naming choices"
}}"""

        try:
            response = self.model.generate_content(prompt)
            response_text = response.text.strip()
            
            # Extract JSON from response
            if "```json" in response_text:
                response_text = response_text.split("```json")[1].split("```")[0].strip()
            elif "```" in response_text:
                response_text = response_text.split("```")[1].split("```")[0].strip()
                
            result = json.loads(response_text)
            
            # Build filename from components
            components = [
                result.get('date', '00000000'),
                result.get('matter_id', 'UNKNOWN'),
                result.get('last_name', 'Unknown'),
                result.get('first_name', 'Unknown'),
                result.get('middle_name', '') or '',
                result.get('dept_code', 'ADM'),
                result.get('doc_type', 'Document'),
                result.get('subtype', 'General'),
                result.get('lifecycle', 'F1'),
                result.get('security_tag', 'C'),
                result.get('legal_description', 'UnknownDocument')
            ]
            
            # Filter out empty middle name
            components = [c for c in components if c]
            
            filename = '_'.join(components)
            
            # Sanitize filename
            filename = re.sub(r'[<>:"/\\|?*]', '_', filename)
            filename = filename[:140]  # Keep under 140 chars for path length
            
            return filename, result
            
        except Exception as e:
            print(f"[ERROR] AI analysis failed: {str(e)}")
            # Fallback naming
            timestamp = datetime.now().strftime("%Y%m%d")
            return f"{timestamp}_UNKNOWN_Unknown_Unknown_ADM_Document_General_F1_C_AIAnalysisFailed", {
                "error": str(e),
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
            
            if not text:
                result["status"] = "error"
                result["error"] = "No text extracted - may need OCR"
                return result
                
            # Analyze with AI
            print(f"[INFO] Analyzing content with AI...")
            new_base_name, analysis = self.analyze_with_ai(text, os.path.basename(pdf_path))
            result["analysis"] = analysis
            
            # Add extension
            new_name = new_base_name + ".pdf"
            result["new_name"] = new_name
            
            # Check if renaming is needed
            if os.path.basename(pdf_path).lower() == new_name.lower():
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
                print(f"[SUCCESS] Renamed to: {new_name}")
                
            # Update cost tracking
            self.files_processed += 1
            self.total_cost += self.cost_per_pdf
            
        except Exception as e:
            result["status"] = "error"
            result["error"] = str(e)
            print(f"[ERROR] Processing failed: {str(e)}")
            
        return result
        
    def process_files(self, file_paths: list) -> list:
        """Process multiple PDF files"""
        results = []
        
        print(f"\n[INFO] Processing {len(file_paths)} files...")
        print(f"[INFO] Using Estate Research Project naming convention")
        print(f"[INFO] Estimated cost: ${self.cost_per_pdf:.4f} per file")
        print(f"\n" + "="*60 + "\n")
        
        # Create progress bar
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
                    import time
                    time.sleep(0.5)
                    
        # Summary
        summary = {
            "total_processed": len(results),
            "successful": len([r for r in results if r["status"] == "renamed"]),
            "skipped": len([r for r in results if r["status"] == "skip"]),
            "errors": len([r for r in results if r["status"] == "error"]),
            "total_cost": round(self.total_cost, 4),
            "naming_convention": "Estate Research Project SOP v1.2"
        }
        
        print(f"\n\n" + "="*60)
        print(f"[SUMMARY] Processing Complete!")
        print(f"[SUMMARY] Files Processed: {summary['total_processed']}")
        print(f"[SUMMARY] Successfully Renamed: {summary['successful']}")
        print(f"[SUMMARY] Skipped (already named): {summary['skipped']}")
        print(f"[SUMMARY] Errors: {summary['errors']}")
        print(f"[SUMMARY] Total AI Cost: ${summary['total_cost']:.4f}")
        print(f"[SUMMARY] Naming Convention: {summary['naming_convention']}")
        print("="*60)
        print(f"\nSUMMARY_JSON: {json.dumps(summary)}")
        
        return results

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Estate Research Project - AI PDF Renamer')
    parser.add_argument('files', nargs='+', help='PDF files to process')
    parser.add_argument('--api-key', help='Gemini API key')
    
    args = parser.parse_args()
    
    try:
        renamer = EstateResearchRenamer(api_key=args.api_key)
        results = renamer.process_files(args.files)
        
        # Save results log
        log_data = {
            "timestamp": datetime.now().isoformat(),
            "results": results,
            "naming_convention": "Estate Research Project SOP v1.2"
        }
        
        log_file = Path(__file__).parent / f"estate_rename_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(log_file, 'w') as f:
            json.dump(log_data, f, indent=2)
            
        print(f"\n[INFO] Log saved to: {log_file}")
        
    except Exception as e:
        print(f"[ERROR] {str(e)}")
        sys.exit(1)
        
if __name__ == "__main__":
    main()