#!/usr/bin/env python3
"""
Estate Research Project - AI-Powered File Naming System
Implements the Dennis Rogan Real Estate Research Project SOP v2.1

File Naming Convention:
YYYYMMDD_MatterID_LastName_FirstName_MiddleName_Dept_DocType_Subtype_Lifecycle_SecTag_LegalDescription.ext

Supports: Documents, Multimedia (images, audio, video), Data files
Includes: Tie-breaker rule for duplicates, Compilation file handling, Validation regex
"""

import os
import re
import json
import sys
import hashlib
from datetime import datetime
from pathlib import Path
import PyPDF2
import google.generativeai as genai
from typing import Dict, Tuple, Optional, List
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

class EstateResearchRenamerV2:
    """PDF and multimedia renamer following Estate Research Project SOP v2.1"""
    
    # Department codes
    DEPARTMENTS = {
        'legal': 'LEG',
        'financial': 'FIN', 
        'administrative': 'ADM',
        'tax': 'TAX',
        'insurance': 'INS',
        'real estate': 'REI'
    }
    
    # Security tags with handling requirements
    SECURITY_TAGS = {
        'public': 'P',           # No restrictions
        'internal': 'I',         # Access control required
        'confidential': 'C',     # Encrypted storage
        'strictly confidential': 'S',  # Encrypted + logged access
        'regulated': 'R'         # Special compliance handling
    }
    
    # Lifecycle states
    LIFECYCLE_STATES = {
        'draft': 'D',
        'signed': 'S',
        'amendment': 'A',
        'final': 'F',
        'revision': 'R'
    }
    
    # Derivative codes
    DERIVATIVE_CODES = ['_OCR', '_BK', '_RED']
    
    # Supported file types
    SUPPORTED_EXTENSIONS = {
        'documents': ['.pdf', '.docx', '.doc', '.txt'],
        'images': ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff'],
        'audio': ['.wav', '.mp3', '.m4a', '.aac', '.wma'],
        'video': ['.mp4', '.avi', '.mov', '.wmv', '.mkv'],
        'data': ['.xlsx', '.xls', '.csv', '.json', '.xml']
    }
    
    # Validation regex pattern (SOP v2.1)
    VALIDATION_PATTERN = re.compile(
        r'^([0-9]{8})_([A-Za-z0-9_]+)_([A-Za-z]+)_([A-Za-z]+)_([A-Za-z]+|NA)_'
        r'(LEG|FIN|ADM|TAX|INS|REI)_([A-Za-z]+)_([A-Za-z]+)_'
        r'([DSFAR][0-9]+(_OCR|_BK|_RED)?)_([PICSR])_'
        r'([A-Za-z0-9_]+)(-[0-9]{2})?'
        r'\.(pdf|docx|xlsx|jpg|png|mp4|wav|csv)$'
    )
    
    def __init__(self, api_key: str = None):
        self.api_key = api_key or os.environ.get('GEMINI_API_KEY')
        if not self.api_key:
            raise ValueError("No API key provided. Set GEMINI_API_KEY or pass via parameter.")
        
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel('gemini-2.5-flash')
        
        # Cost tracking
        self.cost_per_file = 0.0006
        self.total_cost = 0.0
        self.files_processed = 0
        
        # Collision tracking for tie-breaker rule
        self.collision_log = []
        
    def get_file_type_category(self, extension: str) -> str:
        """Determine file type category from extension"""
        ext = extension.lower()
        for category, extensions in self.SUPPORTED_EXTENSIONS.items():
            if ext in extensions:
                return category
        return 'unknown'
        
    def extract_text_from_file(self, file_path: str) -> Tuple[str, Dict]:
        """Extract text/content from various file types"""
        extension = Path(file_path).suffix.lower()
        category = self.get_file_type_category(extension)
        metadata = {'file_type': category, 'extension': extension}
        
        try:
            if category == 'documents' and extension == '.pdf':
                text = self.extract_pdf_text(file_path)
                metadata['pages'] = self.get_pdf_page_count(file_path)
            elif category == 'images':
                text = f"Image file: {Path(file_path).name}"
                metadata['description'] = 'Visual content - requires manual description'
            elif category in ['audio', 'video']:
                text = f"{category.title()} file: {Path(file_path).name}"
                metadata['duration'] = 'Unknown - requires media analysis'
            elif category == 'data':
                text = f"Data file: {Path(file_path).name}"
                metadata['format'] = extension[1:].upper()
            else:
                text = f"File: {Path(file_path).name}"
                
            return text, metadata
            
        except Exception as e:
            print(f"[ERROR] Failed to extract content: {str(e)}")
            return "", metadata
            
    def extract_pdf_text(self, pdf_path: str, max_pages: int = 10) -> str:
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
            print(f"[ERROR] PDF text extraction failed: {str(e)}")
            return ""
            
    def get_pdf_page_count(self, pdf_path: str) -> int:
        """Get number of pages in PDF"""
        try:
            with open(pdf_path, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)
                return len(pdf_reader.pages)
        except:
            return 0
            
    def detect_compilation_file(self, text: str, metadata: Dict) -> bool:
        """Detect if file contains multiple distinct documents"""
        # Simple heuristic - can be enhanced
        indicators = [
            "exhibit", "attachment", "appendix", "schedule",
            "compiled", "collection", "bundle", "packet"
        ]
        
        text_lower = text.lower()
        indicator_count = sum(1 for ind in indicators if ind in text_lower)
        
        # Check page count for PDFs
        if metadata.get('file_type') == 'documents' and metadata.get('pages', 0) > 50:
            indicator_count += 2
            
        return indicator_count >= 3
        
    def analyze_with_ai(self, text: str, current_filename: str, metadata: Dict) -> Tuple[str, Dict]:
        """Use Gemini AI to analyze document and generate filename per SOP v2.1"""
        
        # Check if it's a compilation file
        is_compilation = self.detect_compilation_file(text, metadata)
        
        prompt = f"""Analyze this file for the Dennis Rogan Real Estate Research Project and generate a filename following SOP v2.1:

NAMING STRUCTURE (use underscore between ALL fields):
YYYYMMDD_MatterID_LastName_FirstName_MiddleName_Dept_DocType_Subtype_Lifecycle_SecTag_LegalDescription

SPECIAL RULES:
1. MiddleName: Use "NA" if not applicable/available
2. MatterID: Convert hyphens to underscores (24-PR-371 → 24_PR_371)
3. Compilation files: Use DocType "Collection" with appropriate subtype
4. File type: {metadata.get('file_type', 'unknown')}
5. Is compilation: {is_compilation}

FIELD REQUIREMENTS:
- Date: YYYYMMDD (use 00000000 if undated)
- MatterID: Alphanumeric with underscores only
- Dept codes: LEG, FIN, ADM, TAX, INS, REI
- Lifecycle: D#, S#, A#, F#, R# (plus _OCR, _BK, _RED derivatives)
- Security: P, I, C, S, R (based on content sensitivity)
- LegalDescription: TitleCase, no spaces, max 50 chars

Current filename: {current_filename}
File type: {metadata.get('file_type', 'document')}
Extension: {metadata.get('extension', '.pdf')}
Content excerpt: {text[:1500] if text else 'No text content - ' + metadata.get('description', '')}

Return JSON with ALL these fields:
{{
    "date": "YYYYMMDD format",
    "matter_id": "case ID with hyphens converted to underscores",
    "last_name": "last name",
    "first_name": "first name", 
    "middle_name": "middle name or NA",
    "dept_code": "3-letter department code",
    "doc_type": "document type (use Collection if compilation)",
    "subtype": "document subtype",
    "lifecycle": "lifecycle code with number",
    "has_derivative": "true/false",
    "derivative_code": "_OCR, _BK, or _RED if applicable, empty otherwise",
    "security_tag": "1-letter security code",
    "legal_description": "concise description in TitleCase with underscores",
    "confidence": "high/medium/low",
    "reasoning": "brief explanation of naming choices",
    "is_compilation": {"true" if is_compilation else "false"},
    "compilation_contents": "list primary contents if compilation"
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
                result.get('middle_name', 'NA'),
                result.get('dept_code', 'ADM'),
                result.get('doc_type', 'Document'),
                result.get('subtype', 'General'),
                result.get('lifecycle', 'F1')
            ]
            
            # Add derivative code if present
            if result.get('has_derivative') == 'true' and result.get('derivative_code'):
                components[-1] += result.get('derivative_code', '')
                
            # Add security tag and legal description
            components.extend([
                result.get('security_tag', 'C'),
                result.get('legal_description', 'UnknownDocument')
            ])
            
            filename = '_'.join(components)
            
            # Sanitize filename
            filename = re.sub(r'[<>:"/\\|?*]', '_', filename)
            
            # Ensure max 140 chars (leave room for tie-breaker)
            if len(filename) > 137:  # 140 - 3 chars for "-##"
                # Truncate legal description if needed
                parts = filename.split('_')
                while len('_'.join(parts)) > 137 and len(parts[-1]) > 10:
                    parts[-1] = parts[-1][:-1]
                filename = '_'.join(parts)
            
            return filename, result
            
        except Exception as e:
            print(f"[ERROR] AI analysis failed: {str(e)}")
            # Fallback naming
            timestamp = datetime.now().strftime("%Y%m%d")
            file_type = metadata.get('file_type', 'document').title()
            return f"{timestamp}_UNKNOWN_Unknown_Unknown_NA_ADM_{file_type}_General_F1_C_AIAnalysisFailed", {
                "error": str(e),
                "confidence": "low"
            }
            
    def apply_tie_breaker_rule(self, base_filename: str, directory: str, extension: str) -> str:
        """Apply tie-breaker rule for duplicate filenames per SOP 6.5"""
        original_path = os.path.join(directory, base_filename + extension)
        
        if not os.path.exists(original_path):
            return base_filename + extension
            
        # Need to apply tie-breaker
        counter = 2
        while counter <= 99:
            # Add suffix to legal description (last component before extension)
            suffix = f"-{counter:02d}"
            new_filename = f"{base_filename}{suffix}{extension}"
            new_path = os.path.join(directory, new_filename)
            
            if not os.path.exists(new_path):
                # Log the collision
                self.collision_log.append({
                    "timestamp": datetime.now().isoformat(),
                    "original_attempt": base_filename + extension,
                    "final_name": new_filename,
                    "directory": directory
                })
                return new_filename
                
            counter += 1
            
        raise ValueError(f"Unable to resolve filename collision - exceeded 99 duplicates for {base_filename}")
        
    def validate_filename(self, filename: str) -> bool:
        """Validate filename against SOP v2.1 regex pattern"""
        return bool(self.VALIDATION_PATTERN.match(filename))
        
    def generate_checksum(self, file_path: str) -> str:
        """Generate SHA-256 checksum for S and R classified files"""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
        
    def process_file(self, file_path: str) -> Dict:
        """Process a single file (any supported type)"""
        result = {
            "original_path": file_path,
            "original_name": os.path.basename(file_path),
            "status": "pending",
            "new_name": None,
            "analysis": {},
            "error": None,
            "file_type": None,
            "checksum": None
        }
        
        try:
            # Get file extension and metadata
            extension = Path(file_path).suffix.lower()
            result["file_type"] = self.get_file_type_category(extension)
            
            # Extract content
            print(f"[INFO] Extracting content from: {os.path.basename(file_path)}")
            text, metadata = self.extract_text_from_file(file_path)
            
            if not text and result["file_type"] == "documents":
                result["status"] = "error"
                result["error"] = "No text extracted - may need OCR"
                return result
                
            # Analyze with AI
            print(f"[INFO] Analyzing content with AI...")
            new_base_name, analysis = self.analyze_with_ai(text, os.path.basename(file_path), metadata)
            result["analysis"] = analysis
            
            # Apply tie-breaker rule if needed
            directory = os.path.dirname(file_path)
            new_name = self.apply_tie_breaker_rule(new_base_name, directory, extension)
            result["new_name"] = new_name
            
            # Validate the generated filename
            if not self.validate_filename(new_name):
                print(f"[WARNING] Generated filename failed validation: {new_name}")
                
            # Generate checksum for S and R security tags
            if analysis.get('security_tag') in ['S', 'R']:
                result["checksum"] = self.generate_checksum(file_path)
                print(f"[INFO] Generated SHA-256 checksum for secure file")
                
            # Check if renaming is needed
            if os.path.basename(file_path).lower() == new_name.lower():
                result["status"] = "skip"
                print(f"[INFO] File already has appropriate name")
            else:
                # Perform actual rename
                new_path = os.path.join(directory, new_name)
                os.rename(file_path, new_path)
                result["status"] = "renamed"
                print(f"[SUCCESS] Renamed to: {new_name}")
                
                # Create checksum file if needed
                if result["checksum"]:
                    checksum_path = new_path + ".sha256"
                    with open(checksum_path, 'w') as f:
                        f.write(f"{result['checksum']}  {new_name}\n")
                    print(f"[INFO] Created checksum file: {os.path.basename(checksum_path)}")
                
            # Update cost tracking
            self.files_processed += 1
            self.total_cost += self.cost_per_file
            
        except Exception as e:
            result["status"] = "error"
            result["error"] = str(e)
            print(f"[ERROR] Processing failed: {str(e)}")
            
        return result
        
    def process_files(self, file_paths: list) -> list:
        """Process multiple files of any supported type"""
        results = []
        
        print(f"\n[INFO] Processing {len(file_paths)} files...")
        print(f"[INFO] Using Estate Research Project SOP v2.1")
        print(f"[INFO] Supported types: documents, images, audio, video, data")
        print(f"[INFO] Estimated cost: ${self.cost_per_file:.4f} per file")
        print(f"\n" + "="*60 + "\n")
        
        # Create progress bar
        pbar_format = '{desc}: {percentage:3.0f}%|{bar}| {n_fmt}/{total_fmt} [Cost: ${postfix[0]:.4f}]'
        with tqdm(total=len(file_paths), desc="Processing files", 
                 bar_format=pbar_format, postfix=[0.0]) as pbar:
                 
            for i, file_path in enumerate(file_paths):
                # Update progress bar description
                pbar.set_description(f"Processing: {os.path.basename(file_path)[:30]}...")
                
                result = self.process_file(file_path)
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
            "naming_convention": "Estate Research Project SOP v2.1",
            "file_types_processed": list(set(r["file_type"] for r in results if r.get("file_type"))),
            "collisions_resolved": len(self.collision_log)
        }
        
        print(f"\n\n" + "="*60)
        print(f"[SUMMARY] Processing Complete!")
        print(f"[SUMMARY] Files Processed: {summary['total_processed']}")
        print(f"[SUMMARY] Successfully Renamed: {summary['successful']}")
        print(f"[SUMMARY] Skipped (already named): {summary['skipped']}")
        print(f"[SUMMARY] Errors: {summary['errors']}")
        print(f"[SUMMARY] Collisions Resolved: {summary['collisions_resolved']}")
        print(f"[SUMMARY] File Types: {', '.join(summary['file_types_processed'])}")
        print(f"[SUMMARY] Total AI Cost: ${summary['total_cost']:.4f}")
        print(f"[SUMMARY] Naming Convention: {summary['naming_convention']}")
        print("="*60)
        print(f"\nSUMMARY_JSON: {json.dumps(summary)}")
        
        return results

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Estate Research Project - AI File Renamer v2.1')
    parser.add_argument('files', nargs='+', help='Files to process (any supported type)')
    parser.add_argument('--api-key', help='Gemini API key')
    parser.add_argument('--validate-only', action='store_true', help='Only validate filenames without renaming')
    
    args = parser.parse_args()
    
    try:
        renamer = EstateResearchRenamerV2(api_key=args.api_key)
        
        if args.validate_only:
            # Validation mode
            for file_path in args.files:
                filename = os.path.basename(file_path)
                is_valid = renamer.validate_filename(filename)
                status = "VALID" if is_valid else "INVALID"
                print(f"{status}: {filename}")
        else:
            # Processing mode
            results = renamer.process_files(args.files)
            
            # Save results log
            log_data = {
                "timestamp": datetime.now().isoformat(),
                "results": results,
                "naming_convention": "Estate Research Project SOP v2.1",
                "collision_log": renamer.collision_log
            }
            
            log_file = Path(__file__).parent / f"estate_rename_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            with open(log_file, 'w') as f:
                json.dump(log_data, f, indent=2)
                
            print(f"\n[INFO] Log saved to: {log_file}")
            
            # Save collision log if any
            if renamer.collision_log:
                collision_file = Path(__file__).parent / f"collision_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
                with open(collision_file, 'w') as f:
                    json.dump(renamer.collision_log, f, indent=2)
                print(f"[INFO] Collision log saved to: {collision_file}")
        
    except Exception as e:
        print(f"[ERROR] {str(e)}")
        sys.exit(1)
        
if __name__ == "__main__":
    main()