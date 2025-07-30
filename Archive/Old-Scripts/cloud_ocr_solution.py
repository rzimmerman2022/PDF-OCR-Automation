#!/usr/bin/env python3
"""
Cloud-based OCR solution using Google's Gemini to extract text from PDFs
This works by converting PDF pages to images and using Gemini's vision capabilities
"""

import os
import sys
import base64
import io
from pathlib import Path
import PyPDF2
from PIL import Image
import google.generativeai as genai
from pdf2image import convert_from_path
import fitz  # PyMuPDF

# Load API key
from pdf_renamer import load_env
load_env()

def pdf_page_to_image(pdf_path, page_num=0):
    """Convert a PDF page to image using PyMuPDF"""
    try:
        # Open PDF
        pdf_document = fitz.open(pdf_path)
        
        # Get the page
        page = pdf_document[page_num]
        
        # Render page to image
        mat = fitz.Matrix(2, 2)  # 2x zoom for better quality
        pix = page.get_pixmap(matrix=mat)
        
        # Convert to PIL Image
        img_data = pix.tobytes("png")
        img = Image.open(io.BytesIO(img_data))
        
        pdf_document.close()
        return img
        
    except Exception as e:
        print(f"Error converting PDF to image: {e}")
        return None

def extract_text_with_gemini(pdf_path):
    """Use Gemini's vision capabilities to extract text from PDF"""
    api_key = os.environ.get('GEMINI_API_KEY')
    if not api_key:
        raise ValueError("No GEMINI_API_KEY found")
    
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-2.5-flash')
    
    try:
        # Get number of pages
        with open(pdf_path, 'rb') as f:
            reader = PyPDF2.PdfReader(f)
            num_pages = len(reader.pages)
        
        print(f"  Processing {num_pages} pages...")
        all_text = []
        
        # Process each page (limit to first 5 for cost)
        for page_num in range(min(num_pages, 5)):
            print(f"  - Page {page_num + 1}/{num_pages}")
            
            # Convert page to image
            img = pdf_page_to_image(pdf_path, page_num)
            if not img:
                continue
            
            # Send to Gemini for OCR
            prompt = """Extract ALL text from this image. 
            This is a scanned document page. 
            Please provide the complete text content, preserving the layout as much as possible.
            If there are multiple columns, process them in reading order.
            Include all headers, footers, and any text visible in the image."""
            
            response = model.generate_content([prompt, img])
            
            if response.text:
                all_text.append(f"--- Page {page_num + 1} ---\n{response.text}\n")
        
        return "\n".join(all_text)
        
    except Exception as e:
        print(f"  Error with Gemini OCR: {e}")
        return None

def create_searchable_pdf(pdf_path, extracted_text):
    """Create a new PDF with the extracted text as a text layer"""
    try:
        from reportlab.pdfgen import canvas
        from reportlab.lib.pagesizes import letter
        from PyPDF2 import PdfWriter, PdfReader
        
        # Create a text-only PDF
        text_pdf_path = pdf_path.with_suffix('.text.pdf')
        c = canvas.Canvas(str(text_pdf_path), pagesize=letter)
        
        # Add invisible text
        c.setFillColorRGB(1, 1, 1, alpha=0)  # Transparent text
        text_object = c.beginText(50, 750)
        text_object.setFont("Helvetica", 12)
        
        # Add text line by line
        for line in extracted_text.split('\n')[:100]:  # Limit lines
            if line.strip():
                text_object.textLine(line.strip())
        
        c.drawText(text_object)
        c.save()
        
        # Merge with original PDF
        output = PdfWriter()
        
        with open(pdf_path, 'rb') as original_file:
            original = PdfReader(original_file)
            with open(text_pdf_path, 'rb') as text_file:
                text_pdf = PdfReader(text_file)
                
                # For each page in original
                for i in range(len(original.pages)):
                    page = original.pages[i]
                    if i == 0 and len(text_pdf.pages) > 0:
                        # Merge text layer with first page
                        page.merge_page(text_pdf.pages[0])
                    output.add_page(page)
        
        # Write output
        output_path = pdf_path.with_suffix('.searchable.pdf')
        with open(output_path, 'wb') as output_file:
            output.write(output_file)
        
        # Clean up
        text_pdf_path.unlink()
        
        return output_path
        
    except Exception as e:
        print(f"  Error creating searchable PDF: {e}")
        return None

def process_with_cloud_ocr(pdf_path):
    """Process a PDF using cloud OCR"""
    print(f"\nProcessing: {pdf_path.name}")
    
    # Extract text using Gemini
    text = extract_text_with_gemini(pdf_path)
    
    if text and len(text.strip()) > 50:
        print(f"  [SUCCESS] Extracted {len(text)} characters")
        print(f"  Sample: {text[:200].strip()}...")
        
        # For now, save the text to a file
        text_file = pdf_path.with_suffix('.extracted.txt')
        with open(text_file, 'w', encoding='utf-8') as f:
            f.write(text)
        print(f"  Text saved to: {text_file.name}")
        
        return True
    else:
        print(f"  [FAILED] No text extracted")
        return False

def main():
    # Install PyMuPDF if needed
    try:
        import fitz
    except ImportError:
        print("Installing PyMuPDF...")
        import subprocess
        subprocess.run([sys.executable, '-m', 'pip', 'install', 'PyMuPDF'])
    
    target_dir = Path(r"C:\Projects\Estate Research Project")
    
    print("\n=== Cloud-Based OCR using Gemini Vision ===")
    print("This will use AI to extract text from scanned PDFs")
    print("Cost: ~$0.001 per page\n")
    
    # Find PDFs without text
    pdfs_to_process = []
    
    for pdf_file in target_dir.glob("*.pdf"):
        try:
            with open(pdf_file, 'rb') as f:
                reader = PyPDF2.PdfReader(f)
                text = ""
                for page in reader.pages[:2]:
                    text += page.extract_text()
                
                if len(text.strip()) < 10:
                    pdfs_to_process.append(pdf_file)
        except:
            pass
    
    if not pdfs_to_process:
        print("All PDFs already have text!")
        return
    
    print(f"Found {len(pdfs_to_process)} PDFs needing OCR:")
    for pdf in pdfs_to_process:
        print(f"  - {pdf.name}")
    
    # Process each PDF
    success_count = 0
    for pdf_path in pdfs_to_process:
        if process_with_cloud_ocr(pdf_path):
            success_count += 1
    
    print(f"\n=== Complete ===")
    print(f"Successfully processed: {success_count}/{len(pdfs_to_process)} files")
    print(f"Estimated cost: ${success_count * 0.005:.3f}")

if __name__ == "__main__":
    main()