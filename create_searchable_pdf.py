#!/usr/bin/env python3
"""
Create searchable PDFs by overlaying extracted text on original PDFs
"""

import os
import sys
from pathlib import Path
import PyPDF2
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import io

def create_text_overlay(text, page_width, page_height):
    """Create a PDF with invisible text overlay"""
    packet = io.BytesIO()
    can = canvas.Canvas(packet, pagesize=(page_width, page_height))
    
    # Make text invisible (transparent)
    can.setFillAlpha(0)  # Fully transparent
    
    # Split text into lines and write
    lines = text.split('\n')
    y_position = page_height - 40  # Start from top
    
    for line in lines:
        if y_position < 40:  # Leave bottom margin
            break
        if line.strip():
            # Write invisible text at approximate positions
            can.drawString(40, y_position, line[:100])  # Limit line length
            y_position -= 12  # Move down for next line
    
    can.save()
    packet.seek(0)
    return packet

def make_pdf_searchable(pdf_path, extracted_text_path, output_path=None):
    """Create a searchable PDF from original PDF and extracted text"""
    
    if not output_path:
        output_path = pdf_path
    
    # Read the extracted text
    try:
        with open(extracted_text_path, 'r', encoding='utf-8') as f:
            full_text = f.read()
    except Exception as e:
        print(f"Error reading text file: {e}")
        return False
    
    # Split text by pages
    pages_text = full_text.split('--- Page ')
    page_texts = {}
    
    for page_section in pages_text[1:]:  # Skip first empty split
        try:
            page_num_end = page_section.index(' ---')
            page_num = int(page_section[:page_num_end]) - 1  # 0-indexed
            page_text = page_section[page_num_end + 5:]  # Skip " ---\n"
            page_texts[page_num] = page_text
        except:
            continue
    
    # Read original PDF
    try:
        with open(pdf_path, 'rb') as f:
            reader = PyPDF2.PdfReader(f)
            writer = PyPDF2.PdfWriter()
            
            # Process each page
            for i in range(len(reader.pages)):
                page = reader.pages[i]
                
                # If we have text for this page, add invisible text layer
                if i in page_texts:
                    # Get page dimensions
                    page_box = page.mediabox
                    width = float(page_box.width)
                    height = float(page_box.height)
                    
                    # Create text overlay
                    text_overlay = create_text_overlay(page_texts[i], width, height)
                    overlay_pdf = PyPDF2.PdfReader(text_overlay)
                    
                    # Merge the overlay with the original page
                    page.merge_page(overlay_pdf.pages[0])
                
                writer.add_page(page)
            
            # Save the searchable PDF
            temp_path = pdf_path.with_suffix('.searchable.pdf')
            with open(temp_path, 'wb') as output_file:
                writer.write(output_file)
            
            # Replace original if same output path
            if output_path == pdf_path:
                os.replace(temp_path, pdf_path)
            else:
                os.replace(temp_path, output_path)
            
            print(f"[OK] Created searchable PDF: {Path(output_path).name}")
            return True
            
    except Exception as e:
        print(f"Error processing PDF: {e}")
        return False

def cleanup_extracted_files(directory):
    """Process all extracted.txt files and create searchable PDFs"""
    
    target_dir = Path(directory)
    extracted_files = list(target_dir.glob("*.extracted.txt"))
    
    if not extracted_files:
        print("No extracted text files found!")
        return
    
    print(f"\nFound {len(extracted_files)} extracted text files")
    print("Creating searchable PDFs...\n")
    
    success_count = 0
    
    for txt_file in extracted_files:
        # Get corresponding PDF name
        pdf_name = txt_file.stem.replace('.extracted', '') + '.pdf'
        pdf_path = target_dir / pdf_name
        
        if not pdf_path.exists():
            print(f"[WARNING] No PDF found for {txt_file.name}")
            continue
        
        print(f"Processing: {pdf_name}")
        
        if make_pdf_searchable(pdf_path, txt_file):
            success_count += 1
            # Delete the txt file after successful processing
            txt_file.unlink()
            print(f"  [DELETED] {txt_file.name}")
        else:
            print(f"  [FAILED] Failed to process {pdf_name}")
    
    print(f"\n{'='*60}")
    print(f"Successfully created {success_count} searchable PDFs")
    print(f"Deleted {success_count} .extracted.txt files")
    print(f"{'='*60}")

def main():
    if len(sys.argv) > 1:
        directory = sys.argv[1]
    else:
        directory = r"C:\Projects\Estate Research Project"
    
    cleanup_extracted_files(directory)

if __name__ == "__main__":
    main()