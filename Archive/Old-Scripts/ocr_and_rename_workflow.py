#!/usr/bin/env python3
"""
Complete OCR and rename workflow using cloud OCR
"""

import os
import sys
from pathlib import Path
import PyPDF2
from cloud_ocr_solution import extract_text_with_gemini, pdf_page_to_image
from pdf_renamer import PDFAnalyzer, load_env

def process_pdf_with_ocr_and_rename(pdf_path):
    """Process a single PDF with OCR extraction and AI renaming"""
    print(f"\n{'='*60}")
    print(f"Processing: {pdf_path.name}")
    print('='*60)
    
    # First check if PDF has text
    try:
        with open(pdf_path, 'rb') as f:
            reader = PyPDF2.PdfReader(f)
            text = ""
            for page in reader.pages[:2]:
                text += page.extract_text()
            
            if len(text.strip()) > 10:
                print("[OK] PDF already has extractable text")
                # Run AI renaming directly
                renamer = PDFAnalyzer()
                return renamer.process_pdf(str(pdf_path))
    except Exception as e:
        print(f"Error checking PDF: {e}")
    
    print("[NO TEXT] No extractable text found - using cloud OCR")
    
    # Check if we already have extracted text
    extracted_file = pdf_path.with_suffix('.extracted.txt')
    
    if extracted_file.exists():
        print("[OK] Found existing extracted text file")
        with open(extracted_file, 'r', encoding='utf-8') as f:
            extracted_text = f.read()
    else:
        print("[PROCESSING] Extracting text with Gemini Vision API...")
        extracted_text = extract_text_with_gemini(pdf_path)
        
        if not extracted_text or len(extracted_text.strip()) < 50:
            print("[FAILED] Failed to extract text with OCR")
            return None
        
        # Save extracted text
        with open(extracted_file, 'w', encoding='utf-8') as f:
            f.write(extracted_text)
        print(f"[OK] Saved extracted text to {extracted_file.name}")
    
    print(f"[OK] Extracted {len(extracted_text)} characters")
    print(f"  Sample: {extracted_text[:200].strip()}...")
    
    # Now use AI to analyze the extracted text and rename
    print("\n[ANALYZING] Analyzing content with AI for renaming...")
    
    renamer = PDFAnalyzer()
    
    # Override the extract_text method to use our extracted text
    original_extract = renamer.extract_text
    
    def custom_extract(file_path):
        return extracted_text
    
    renamer.extract_text = custom_extract
    
    # Run the renaming
    result = renamer.process_pdf(str(pdf_path))
    
    # Restore original method
    renamer.extract_text = original_extract
    
    return result

def main():
    load_env()
    
    if len(sys.argv) < 2:
        target_dir = Path(r"C:\Projects\Estate Research Project")
        pdfs = list(target_dir.glob("*.pdf"))
    else:
        if sys.argv[1].endswith('.pdf'):
            pdfs = [Path(sys.argv[1])]
        else:
            target_dir = Path(sys.argv[1])
            pdfs = list(target_dir.glob("*.pdf"))
    
    print(f"\n{'='*60}")
    print("PDF OCR AND RENAME WORKFLOW")
    print(f"{'='*60}")
    print(f"Found {len(pdfs)} PDFs to process")
    
    success_count = 0
    
    for pdf_path in pdfs:
        result = process_pdf_with_ocr_and_rename(pdf_path)
        if result and result.get('status') == 'renamed':
            success_count += 1
            print(f"[SUCCESS] Renamed to {result['new_name']}")
        elif result and result.get('status') == 'skipped':
            print(f"[SKIPPED] Already properly named")
        else:
            print(f"[FAILED] Could not process {pdf_path.name}")
    
    print(f"\n{'='*60}")
    print(f"COMPLETE: Successfully processed {success_count}/{len(pdfs)} files")
    print(f"{'='*60}")

if __name__ == "__main__":
    main()