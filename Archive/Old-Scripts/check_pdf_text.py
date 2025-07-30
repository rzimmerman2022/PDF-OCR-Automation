#!/usr/bin/env python3
"""Check if PDFs have extractable text"""

import os
import sys
import PyPDF2
from pathlib import Path

def check_pdf_text(pdf_path):
    """Check if a PDF has extractable text"""
    try:
        with open(pdf_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            num_pages = len(pdf_reader.pages)
            
            total_text = ""
            for page_num in range(min(num_pages, 3)):  # Check first 3 pages
                page = pdf_reader.pages[page_num]
                text = page.extract_text()
                total_text += text
            
            # Check if we got meaningful text
            text_length = len(total_text.strip())
            word_count = len(total_text.split())
            
            return {
                "filename": os.path.basename(pdf_path),
                "pages": num_pages,
                "text_length": text_length,
                "word_count": word_count,
                "has_text": text_length > 10,
                "sample": total_text[:200].replace('\n', ' ').strip() if total_text else "NO TEXT FOUND"
            }
    except Exception as e:
        return {
            "filename": os.path.basename(pdf_path),
            "error": str(e)
        }

def main():
    if len(sys.argv) < 2:
        target_dir = r"C:\Projects\Estate Research Project"
    else:
        target_dir = sys.argv[1]
    
    print(f"\n=== Checking PDFs for extractable text ===")
    print(f"Directory: {target_dir}\n")
    
    # Find all PDFs
    pdf_files = list(Path(target_dir).glob("*.pdf"))
    
    if not pdf_files:
        print("No PDF files found!")
        return
    
    # Check each PDF
    need_ocr = []
    have_text = []
    
    for pdf_path in pdf_files:
        result = check_pdf_text(str(pdf_path))
        
        print(f"\nFile: {result['filename']}")
        if 'error' in result:
            print(f"  ERROR: {result['error']}")
        else:
            print(f"  Pages: {result['pages']}")
            print(f"  Text length: {result['text_length']} chars")
            print(f"  Word count: {result['word_count']} words")
            print(f"  Has text: {'YES' if result['has_text'] else 'NO'}")
            if result['sample']:
                print(f"  Sample: {result['sample'][:100]}...")
            
            if result['has_text']:
                have_text.append(result['filename'])
            else:
                need_ocr.append(result['filename'])
    
    # Summary
    print(f"\n=== SUMMARY ===")
    print(f"Total PDFs: {len(pdf_files)}")
    print(f"Have text (ready for AI): {len(have_text)}")
    print(f"Need OCR: {len(need_ocr)}")
    
    if need_ocr:
        print(f"\nFiles needing OCR:")
        for f in need_ocr:
            print(f"  - {f}")
    
    if have_text:
        print(f"\nFiles ready for AI renaming:")
        for f in have_text:
            print(f"  - {f}")

if __name__ == "__main__":
    main()