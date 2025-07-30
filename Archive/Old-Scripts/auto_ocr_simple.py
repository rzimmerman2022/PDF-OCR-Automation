#!/usr/bin/env python3
"""Simple automatic OCR using ocrmypdf"""

import os
import sys
import shutil
from pathlib import Path
import PyPDF2

def has_text(pdf_path):
    """Check if PDF has extractable text"""
    try:
        with open(pdf_path, 'rb') as f:
            reader = PyPDF2.PdfReader(f)
            text = ""
            for i, page in enumerate(reader.pages):
                if i >= 2:  # Check first 2 pages only
                    break
                text += page.extract_text()
            return len(text.strip()) > 10
    except:
        return False

def ocr_pdf(pdf_path):
    """OCR a single PDF using ocrmypdf"""
    try:
        import ocrmypdf
        
        print(f"  Running OCR on {pdf_path.name}...")
        
        # Create temp file
        temp_path = pdf_path.with_suffix('.pdf.ocr')
        
        # Run OCR (without clean option to avoid unpaper dependency)
        result = ocrmypdf.ocr(
            str(pdf_path),
            str(temp_path),
            rotate_pages=True,
            deskew=True,
            force_ocr=True,
            skip_text=False,
            language='eng'
        )
        
        if result == 0:
            # Replace original with OCR'd version
            shutil.move(str(temp_path), str(pdf_path))
            print(f"  [SUCCESS] OCR completed for {pdf_path.name}")
            return True
        else:
            print(f"  [ERROR] OCR failed with code: {result}")
            if temp_path.exists():
                temp_path.unlink()
            return False
            
    except Exception as e:
        print(f"  [ERROR] {str(e)}")
        return False

def main():
    target_dir = Path(r"C:\Projects\Estate Research Project")
    
    print("\n=== Automatic OCR Processing ===")
    print(f"Directory: {target_dir}\n")
    
    # Find PDFs without text
    pdfs_to_ocr = []
    
    for pdf_file in target_dir.glob("*.pdf"):
        if has_text(pdf_file):
            print(f"[OK] {pdf_file.name} - Has text")
        else:
            print(f"[NEED OCR] {pdf_file.name} - No text")
            pdfs_to_ocr.append(pdf_file)
    
    if not pdfs_to_ocr:
        print("\nAll PDFs already have text!")
        return
    
    # Process PDFs
    print(f"\n=== Processing {len(pdfs_to_ocr)} PDFs ===")
    
    success_count = 0
    for pdf_path in pdfs_to_ocr:
        # Create backup
        backup_path = pdf_path.with_suffix('.pdf.backup')
        shutil.copy2(pdf_path, backup_path)
        
        if ocr_pdf(pdf_path):
            # Verify it worked
            if has_text(pdf_path):
                success_count += 1
                backup_path.unlink()  # Remove backup
            else:
                print(f"  [WARNING] Still no text after OCR")
                shutil.move(str(backup_path), str(pdf_path))  # Restore backup
        else:
            shutil.move(str(backup_path), str(pdf_path))  # Restore backup
    
    print(f"\n=== Complete ===")
    print(f"Successfully OCR'd: {success_count}/{len(pdfs_to_ocr)} files")
    
    if success_count > 0:
        print(f"\nNow running AI renaming on OCR'd files...")
        
        # Run AI renaming on successfully OCR'd files
        for pdf_path in pdfs_to_ocr:
            if has_text(pdf_path):
                print(f"\nRenaming: {pdf_path.name}")
                os.system(f'python "{Path(__file__).parent / "pdf_renamer.py"}" "{pdf_path}"')

if __name__ == "__main__":
    main()