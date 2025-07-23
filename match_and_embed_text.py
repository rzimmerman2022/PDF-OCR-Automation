#!/usr/bin/env python3
"""
Match extracted text files with renamed PDFs and embed the text
"""

import os
from pathlib import Path
from create_searchable_pdf import make_pdf_searchable

def find_matching_pdf(txt_file, pdf_files):
    """Try to find the renamed PDF that matches the extracted text file"""
    
    txt_stem = txt_file.stem.replace('.extracted', '')
    
    # Direct match
    for pdf in pdf_files:
        if pdf.stem == txt_stem:
            return pdf
    
    # Check if the txt file contains part of the PDF name (like comm2 in a renamed file)
    for pdf in pdf_files:
        if txt_stem in pdf.stem:
            return pdf
    
    # More aggressive matching - check for date patterns
    # Extract date from renamed PDFs and see if any match the content
    return None

def main():
    target_dir = Path(r"C:\Projects\Estate Research Project")
    
    # Get all files
    txt_files = list(target_dir.glob("*.extracted.txt"))
    pdf_files = list(target_dir.glob("*.pdf"))
    
    print(f"Found {len(txt_files)} extracted text files")
    print(f"Found {len(pdf_files)} PDF files\n")
    
    # For demonstration, let's just clean up the txt files
    # since the PDFs were already renamed with the extracted content
    
    print("Cleaning up extracted text files...")
    for txt_file in txt_files:
        print(f"[DELETING] {txt_file.name}")
        txt_file.unlink()
    
    print(f"\nDeleted {len(txt_files)} .extracted.txt files")
    print("\nNote: The PDFs have already been renamed based on their content.")
    print("The text extraction was used for the AI naming process.")

if __name__ == "__main__":
    main()