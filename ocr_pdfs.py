#!/usr/bin/env python3
"""
PDF-OCR-Automation - Main Entry Point

Universal OCR utility for batch processing PDF files. Creates searchable PDFs with 
invisible text layers using industry-standard OCR engines (OCRmyPDF + Tesseract).

Features:
    - Adobe Acrobat Pro-style OCR processing
    - Automatic detection of PDFs that need OCR
    - Batch processing with progress tracking
    - Multiple language support (100+ languages)
    - Backup and recovery capabilities
    - AI-readable output validation

Usage:
    python ocr_pdfs.py <folder_path>
    
Examples:
    python ocr_pdfs.py "C:\\Documents\\PDFs"
    python ocr_pdfs.py "/home/user/scanned-docs"
    python ocr_pdfs.py "."  # Current directory

Output:
    - Original PDFs are backed up with .backup extension
    - Processed PDFs replace originals with searchable versions
    - Processing summary shows success/failure counts
    - Failed files are reported for manual review

Requirements:
    - Python 3.8+
    - OCRmyPDF >= 16.0.0 
    - Tesseract OCR >= 4.1.0
    - Sufficient disk space for backups

Author: PDF-OCR-Automation Team
Version: 2.0.0
License: MIT
"""

import sys
import os
from pathlib import Path

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from processors.ocr_processor import check_requirements, has_text, ocr_pdf_like_adobe

def process_pdfs(folder_path=None):
    """Process all PDFs in the specified folder"""
    if folder_path:
        target_dir = Path(folder_path)
    else:
        # Get folder from command line argument
        if len(sys.argv) < 2:
            print("\nUsage: python ocr_pdfs.py <folder_path>")
            print("Example: python ocr_pdfs.py \"C:\\Path\\To\\Your\\Folder\"")
            sys.exit(1)
        target_dir = Path(sys.argv[1])
    
    print(f"\n{'='*60}")
    print("OCR PROCESSING - PDF BATCH PROCESSOR")
    print(f"{'='*60}")
    print(f"Directory: {target_dir}\n")
    
    # Check requirements first
    if not check_requirements():
        print("\n[ERROR] Missing requirements. Please install Tesseract OCR.")
        return
    
    # Check if directory exists
    if not target_dir.exists():
        print(f"\n[ERROR] Directory not found: {target_dir}")
        return
    
    print("\nScanning for PDFs...\n")
    
    # Find all PDFs
    pdf_files = list(target_dir.glob("*.pdf"))
    
    if not pdf_files:
        print("\n[ERROR] No PDF files found in directory")
        return
    
    print(f"Found {len(pdf_files)} PDF files\n")
    
    # Check which PDFs need OCR
    pdfs_to_process = []
    already_searchable = []
    
    for pdf_file in pdf_files:
        if pdf_file.name.endswith('.backup'):
            continue
            
        print(f"Checking: {pdf_file.name}...", end=" ")
        
        if has_text(pdf_file):
            print("Already searchable")
            already_searchable.append(pdf_file)
        else:
            print("Needs OCR")
            pdfs_to_process.append(pdf_file)
    
    print(f"\n{'='*60}")
    print(f"Summary:")
    print(f"  - Total PDFs: {len(pdf_files)}")
    print(f"  - Already searchable: {len(already_searchable)}")
    print(f"  - Need OCR: {len(pdfs_to_process)}")
    print(f"{'='*60}\n")
    
    if not pdfs_to_process:
        print("All PDFs are already searchable!")
        return
    
    # Process PDFs that need OCR
    print(f"Starting OCR processing for {len(pdfs_to_process)} PDFs...\n")
    
    success_count = 0
    failed_files = []
    
    for i, pdf_path in enumerate(pdfs_to_process, 1):
        print(f"\n[{i}/{len(pdfs_to_process)}] Processing: {pdf_path.name}")
        print("-" * 60)
        
        try:
            if ocr_pdf_like_adobe(pdf_path, backup=True, language='eng'):
                success_count += 1
                print(f"  [SUCCESS] OCR completed for: {pdf_path.name}")
            else:
                failed_files.append(pdf_path.name)
                print(f"  [FAILED] Could not OCR: {pdf_path.name}")
        except Exception as e:
            failed_files.append(pdf_path.name)
            print(f"  [ERROR] Exception processing {pdf_path.name}: {str(e)}")
    
    # Final summary
    print(f"\n{'='*60}")
    print("OCR PROCESSING COMPLETE")
    print(f"{'='*60}")
    print(f"  - Successfully processed: {success_count}/{len(pdfs_to_process)}")
    print(f"  - Already searchable: {len(already_searchable)}")
    print(f"  - Failed: {len(failed_files)}")
    
    if failed_files:
        print("\nFailed files:")
        for file in failed_files:
            print(f"  - {file}")
    
    print(f"\n{'='*60}")
    print("All successfully processed PDFs now have searchable text layers!")
    print("You can search, copy text, and use them with any PDF reader.")
    print(f"{'='*60}")

if __name__ == "__main__":
    # Check if folder path provided as argument
    if len(sys.argv) > 1:
        process_pdfs()
    else:
        print("\nError: No folder path provided!")
        print("Usage: python ocr_pdfs.py <folder_path>")
        print("Example: python ocr_pdfs.py \"C:\\Path\\To\\Your\\Folder\"")
        sys.exit(1)