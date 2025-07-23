#!/usr/bin/env python3
"""
Create searchable PDFs like Adobe Pro using ocrmypdf
This creates PDFs with invisible text layers, just like Adobe Acrobat Pro's OCR
"""

import os
import sys
import subprocess
from pathlib import Path
import PyPDF2
import shutil

def check_requirements():
    """Check if Tesseract and ocrmypdf are available"""
    # Check for Tesseract
    tesseract_paths = [
        'tesseract',  # In PATH
        r'C:\Program Files\Tesseract-OCR\tesseract.exe',  # Common location
        r'C:\Users\{}\AppData\Local\Programs\Tesseract-OCR\tesseract.exe'.format(os.environ.get('USERNAME', ''))
    ]
    
    tesseract_found = False
    for tesseract_path in tesseract_paths:
        try:
            result = subprocess.run([tesseract_path, '--version'], capture_output=True, text=True)
            if 'tesseract' in result.stdout.lower():
                print(f"[OK] Tesseract found at: {tesseract_path}")
                # Set environment variable for ocrmypdf
                if tesseract_path != 'tesseract':
                    os.environ['TESSERACT_PATH'] = tesseract_path
                    # Also add to PATH
                    tesseract_dir = os.path.dirname(tesseract_path)
                    os.environ['PATH'] = tesseract_dir + os.pathsep + os.environ.get('PATH', '')
                tesseract_found = True
                break
        except FileNotFoundError:
            continue
    
    if not tesseract_found:
        print("[ERROR] Tesseract is not installed!")
        print("\nTo create searchable PDFs like Adobe Pro, you need Tesseract.")
        print("Run: .\\install_ocr_tools.ps1")
        return False
    
    # Check for ocrmypdf
    try:
        import ocrmypdf
        print("[OK] ocrmypdf is installed")
        return True
    except ImportError:
        print("[ERROR] ocrmypdf not installed. Installing...")
        subprocess.run([sys.executable, '-m', 'pip', 'install', 'ocrmypdf'])
        return True

def has_text(pdf_path):
    """Check if PDF already has searchable text"""
    try:
        with open(pdf_path, 'rb') as f:
            reader = PyPDF2.PdfReader(f)
            text = ""
            for i, page in enumerate(reader.pages):
                if i >= 2:  # Check first 2 pages
                    break
                text += page.extract_text()
            return len(text.strip()) > 10
    except:
        return False

def ocr_pdf_like_adobe(pdf_path, output_path=None, backup=True):
    """
    OCR a PDF just like Adobe Acrobat Pro
    Creates a searchable PDF with invisible text layer
    """
    try:
        import ocrmypdf
        
        # Configure Tesseract path if needed
        if 'TESSERACT_PATH' in os.environ:
            # Set the path for pytesseract
            import pytesseract
            pytesseract.pytesseract.tesseract_cmd = os.environ['TESSERACT_PATH']
        
        if not output_path:
            output_path = pdf_path
        
        # Create backup if requested
        if backup and output_path == pdf_path:
            backup_path = pdf_path.with_suffix('.pdf.backup')
            shutil.copy2(pdf_path, backup_path)
            print(f"  [BACKUP] Created backup: {backup_path.name}")
        
        print(f"  [OCR] Processing with Adobe-style OCR...")
        
        # Run OCR with settings similar to Adobe Pro
        result = ocrmypdf.ocr(
            str(pdf_path),
            str(output_path),
            # Adobe-like settings
            rotate_pages=True,           # Auto-rotate pages
            deskew=True,                 # Straighten scanned pages
            clean=False,                 # Don't use unpaper (not installed)
            force_ocr=True,              # OCR even if text exists
            skip_text=False,             # Process all pages
            optimize=1,                  # Optimize PDF size
            language='eng',              # English OCR
            # Quality settings
            jpg_quality=95,              # High quality for images
            png_quality=95,
            jbig2_lossy=False,          # Lossless compression
            # Text settings
            oversample=300,              # 300 DPI for OCR accuracy
        )
        
        if result == ocrmypdf.ExitCode.ok:
            print(f"  [SUCCESS] Created searchable PDF like Adobe Pro!")
            
            # Verify it worked
            if has_text(output_path):
                print(f"  [VERIFIED] PDF is now searchable")
                
                # Remove backup if successful
                if backup and output_path == pdf_path and backup_path.exists():
                    backup_path.unlink()
                    print(f"  [CLEANUP] Removed backup")
            else:
                print(f"  [WARNING] PDF may not be searchable")
                
            return True
        else:
            print(f"  [ERROR] OCR failed with code: {result}")
            
            # Restore backup if failed
            if backup and output_path == pdf_path and backup_path.exists():
                shutil.copy2(backup_path, pdf_path)
                backup_path.unlink()
                print(f"  [RESTORED] Restored from backup")
                
            return False
            
    except Exception as e:
        print(f"  [ERROR] {str(e)}")
        
        # Common errors and solutions
        if "tesseract" in str(e).lower():
            print("\n  SOLUTION: Install Tesseract OCR")
            print("  Run: .\\install_ocr_tools.ps1")
        elif "unpaper" in str(e).lower():
            print("\n  Note: 'unpaper' not required for basic OCR")
            
        return False

def process_directory(directory):
    """Process all PDFs in directory that need OCR"""
    target_dir = Path(directory)
    
    print(f"\n{'='*60}")
    print("ADOBE-STYLE OCR FOR SEARCHABLE PDFS")
    print(f"{'='*60}")
    print(f"Directory: {target_dir}\n")
    
    # Check requirements first
    if not check_requirements():
        return
    
    print("\nScanning for PDFs without searchable text...\n")
    
    # Find PDFs needing OCR
    pdfs_to_process = []
    
    for pdf_file in target_dir.glob("*.pdf"):
        if pdf_file.name.endswith('.backup'):
            continue
            
        if has_text(pdf_file):
            print(f"[SKIP] {pdf_file.name} - Already searchable")
        else:
            print(f"[NEED OCR] {pdf_file.name} - No searchable text")
            pdfs_to_process.append(pdf_file)
    
    if not pdfs_to_process:
        print("\nAll PDFs are already searchable!")
        return
    
    print(f"\n{'='*60}")
    print(f"Creating {len(pdfs_to_process)} searchable PDFs (like Adobe Pro)")
    print(f"{'='*60}\n")
    
    success_count = 0
    
    for i, pdf_path in enumerate(pdfs_to_process, 1):
        print(f"[{i}/{len(pdfs_to_process)}] Processing: {pdf_path.name}")
        
        if ocr_pdf_like_adobe(pdf_path):
            success_count += 1
        
        print()  # Blank line between files
    
    print(f"{'='*60}")
    print(f"COMPLETE: {success_count}/{len(pdfs_to_process)} PDFs now searchable")
    print(f"{'='*60}")
    
    if success_count > 0:
        print("\nYour PDFs now have invisible text layers, just like Adobe Pro!")
        print("You can search, copy text, and use them with any PDF reader.")

def main():
    if len(sys.argv) > 1:
        if sys.argv[1].endswith('.pdf'):
            # Single file
            pdf_path = Path(sys.argv[1])
            print(f"\nProcessing single file: {pdf_path.name}")
            ocr_pdf_like_adobe(pdf_path)
        else:
            # Directory
            process_directory(sys.argv[1])
    else:
        # Default directory
        process_directory(r"C:\Projects\Estate Research Project")

if __name__ == "__main__":
    main()