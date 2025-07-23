#!/usr/bin/env python3
"""
Automatic OCR solution using multiple approaches
"""

import os
import sys
import subprocess
from pathlib import Path
import PyPDF2

def check_tesseract():
    """Check if Tesseract OCR is installed"""
    try:
        result = subprocess.run(['tesseract', '--version'], capture_output=True, text=True)
        return 'tesseract' in result.stdout.lower()
    except:
        return False

def check_poppler():
    """Check if Poppler utils are installed (for pdf2image)"""
    try:
        result = subprocess.run(['pdftoppm', '-h'], capture_output=True, text=True)
        return True
    except:
        return False

def install_ocr_tools():
    """Install OCR dependencies"""
    print("\n=== Installing OCR Dependencies ===")
    
    # Install Python packages
    packages = ['pytesseract', 'pdf2image', 'Pillow', 'ocrmypdf']
    
    for package in packages:
        print(f"Installing {package}...")
        subprocess.run([sys.executable, '-m', 'pip', 'install', package], 
                      capture_output=True)
    
    print("\nPython packages installed!")
    
    # Check for system dependencies
    if not check_tesseract():
        print("\n⚠️  Tesseract OCR not found!")
        print("Please install Tesseract:")
        print("1. Download from: https://github.com/UB-Mannheim/tesseract/wiki")
        print("2. Add to PATH during installation")
        print("3. Restart your terminal")
        return False
    
    if not check_poppler():
        print("\n⚠️  Poppler not found!")
        print("Please install Poppler:")
        print("1. Download from: https://github.com/oschwartz10612/poppler-windows/releases")
        print("2. Extract and add 'bin' folder to PATH")
        print("3. Restart your terminal")
        return False
    
    return True

def ocr_with_ocrmypdf(pdf_path, output_path=None):
    """OCR using ocrmypdf - most reliable method"""
    try:
        import ocrmypdf
        
        if not output_path:
            output_path = pdf_path
        
        print(f"  OCR processing with ocrmypdf...")
        
        # Run OCR
        result = ocrmypdf.ocr(
            pdf_path,
            output_path,
            rotate_pages=True,
            deskew=True,
            clean=True,
            force_ocr=True,  # Force OCR even if text exists
            skip_text=False,  # Don't skip pages with text
            language='eng'
        )
        
        if result == 0:
            print(f"  ✓ OCR successful!")
            return True
        else:
            print(f"  ✗ OCR failed with code: {result}")
            return False
            
    except Exception as e:
        print(f"  ✗ OCR error: {str(e)}")
        return False

def ocr_with_tesseract(pdf_path):
    """OCR using Tesseract directly"""
    try:
        from pdf2image import convert_from_path
        import pytesseract
        from PIL import Image
        
        print(f"  Converting PDF to images...")
        
        # Convert PDF to images
        images = convert_from_path(pdf_path, dpi=300)
        
        # OCR each page
        text_data = []
        for i, image in enumerate(images):
            print(f"  OCR page {i+1}/{len(images)}...")
            text = pytesseract.image_to_string(image)
            text_data.append(text)
        
        # Create searchable PDF (this is complex, so we'll use ocrmypdf instead)
        print(f"  ✓ Text extracted, but need ocrmypdf to create searchable PDF")
        return False
        
    except Exception as e:
        print(f"  ✗ Tesseract error: {str(e)}")
        return False

def process_pdfs(target_dir):
    """Process all PDFs needing OCR"""
    # First, ensure we have the tools
    print("Checking OCR tools...")
    
    try:
        import ocrmypdf
        print("✓ ocrmypdf is installed")
    except ImportError:
        print("Installing OCR tools...")
        if not install_ocr_tools():
            print("\nPlease install the required tools and run again.")
            return
    
    # Find PDFs without text
    print(f"\n=== Scanning PDFs in {target_dir} ===")
    
    pdfs_to_ocr = []
    
    for pdf_file in Path(target_dir).glob("*.pdf"):
        try:
            with open(pdf_file, 'rb') as f:
                reader = PyPDF2.PdfReader(f)
                text = ""
                for page in reader.pages[:2]:  # Check first 2 pages
                    text += page.extract_text()
                
                if len(text.strip()) < 10:
                    pdfs_to_ocr.append(pdf_file)
                    print(f"  ✗ {pdf_file.name} - No text found")
                else:
                    print(f"  ✓ {pdf_file.name} - Has text")
        except Exception as e:
            print(f"  ? {pdf_file.name} - Error: {e}")
    
    if not pdfs_to_ocr:
        print("\nAll PDFs already have text!")
        return
    
    # Process PDFs needing OCR
    print(f"\n=== Processing {len(pdfs_to_ocr)} PDFs with OCR ===")
    
    success_count = 0
    
    for pdf_path in pdfs_to_ocr:
        print(f"\nProcessing: {pdf_path.name}")
        
        # Create backup
        backup_path = pdf_path.with_suffix('.pdf.backup')
        import shutil
        shutil.copy2(pdf_path, backup_path)
        
        # Try OCR
        if ocr_with_ocrmypdf(str(pdf_path)):
            success_count += 1
            
            # Verify OCR worked
            try:
                with open(pdf_path, 'rb') as f:
                    reader = PyPDF2.PdfReader(f)
                    text = reader.pages[0].extract_text()
                    if len(text.strip()) > 10:
                        print(f"  ✓ Verified: Text is now extractable")
                        print(f"  Sample: {text[:100].strip()}...")
                        # Remove backup
                        backup_path.unlink()
                    else:
                        print(f"  ⚠️  Warning: Still no text after OCR")
                        # Restore backup
                        shutil.copy2(backup_path, pdf_path)
                        backup_path.unlink()
            except:
                pass
        else:
            # Restore from backup if OCR failed
            shutil.copy2(backup_path, pdf_path)
            backup_path.unlink()
    
    print(f"\n=== OCR Complete ===")
    print(f"Successfully processed: {success_count}/{len(pdfs_to_ocr)} files")
    
    if success_count > 0:
        print(f"\nNow run AI renaming:")
        print(f'python pdf_renamer.py "{target_dir}\\*.pdf"')

def main():
    target_dir = r"C:\Projects\Estate Research Project"
    
    if len(sys.argv) > 1:
        target_dir = sys.argv[1]
    
    process_pdfs(target_dir)

if __name__ == "__main__":
    main()