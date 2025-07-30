#!/usr/bin/env python3
"""
Create a simulated scanned PDF that needs OCR
This creates an image-based PDF without text layer
"""

from PIL import Image, ImageDraw, ImageFont
import os
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.lib.utils import ImageReader
import io

def create_scanned_document():
    """Create an image that looks like a scanned document"""
    # Create a white image
    width, height = 2100, 2970  # A4 at 250 DPI
    img = Image.new('RGB', (width, height), color='white')
    draw = ImageDraw.Draw(img)
    
    # Add some noise to make it look scanned
    import random
    for _ in range(5000):
        x = random.randint(0, width-1)
        y = random.randint(0, height-1)
        gray = random.randint(240, 255)
        img.putpixel((x, y), (gray, gray, gray))
    
    # Try to use a font, fallback to default if not available
    try:
        # Try Windows fonts
        font_paths = [
            "C:/Windows/Fonts/arial.ttf",
            "C:/Windows/Fonts/Arial.ttf",
            "C:/Windows/Fonts/calibri.ttf",
            "arial.ttf"
        ]
        font = None
        for font_path in font_paths:
            if os.path.exists(font_path):
                font = ImageFont.truetype(font_path, 60)
                break
        if not font:
            font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()
    
    # Add title
    title = "IMPORTANT BUSINESS DOCUMENT"
    draw.text((width//2 - 400, 200), title, fill='black', font=font)
    
    # Add date
    draw.text((200, 400), "Date: November 15, 2024", fill='black', font=font)
    
    # Add body text
    body_text = [
        "To: All Stakeholders",
        "",
        "Subject: Quarterly Performance Report",
        "",
        "This document contains critical information about our",
        "company's performance in Q3 2024. The following metrics",
        "demonstrate our continued growth:",
        "",
        "Revenue: $12.5 million (up 23% YoY)",
        "Customer Base: 45,000 active users",
        "Market Share: 18.5% in our segment",
        "",
        "Key Achievements:",
        "- Launched new product line successfully",
        "- Expanded to 3 new international markets",
        "- Improved customer satisfaction to 94%",
        "",
        "Future Outlook:",
        "We project continued growth in Q4 with expected",
        "revenue of $15 million. Our strategic initiatives",
        "include AI integration and sustainability programs.",
        "",
        "This information is confidential and should not",
        "be shared outside the organization.",
        "",
        "Sincerely,",
        "John Smith",
        "CEO"
    ]
    
    y_pos = 600
    for line in body_text:
        draw.text((200, y_pos), line, fill='black', font=font)
        y_pos += 80
    
    # Add slight rotation to simulate scan misalignment
    img = img.rotate(0.5, fillcolor='white', expand=True)
    
    # Save as image
    img_path = "C:/Projects/PDF-OCR-Automation/Test-PDFs/scanned_document.png"
    img.save(img_path, 'PNG')
    print(f"Created image: {img_path}")
    
    # Convert to PDF (image-only, no text layer)
    pdf_path = "C:/Projects/PDF-OCR-Automation/Test-PDFs/scanned_document.pdf"
    c = canvas.Canvas(pdf_path, pagesize=letter)
    
    # Resize image to fit on page
    img_width = 8.5 * 72  # 8.5 inches in points
    img_height = 11 * 72   # 11 inches in points
    
    # Draw image on PDF
    c.drawImage(img_path, 0, 0, width=img_width, height=img_height)
    c.save()
    
    print(f"Created PDF: {pdf_path}")
    print("This PDF contains only an image - no searchable text!")
    
    # Clean up temporary image
    os.remove(img_path)
    
    return pdf_path

def verify_no_text(pdf_path):
    """Verify that the PDF has no extractable text"""
    try:
        import PyPDF2
        with open(pdf_path, 'rb') as f:
            reader = PyPDF2.PdfReader(f)
            text = ""
            for page in reader.pages:
                text += page.extract_text()
            
            if text.strip():
                print(f"\nWARNING: PDF has text: {text[:100]}...")
            else:
                print("\n✓ Confirmed: PDF has NO searchable text (perfect for OCR testing)")
    except Exception as e:
        print(f"\nCould not verify text content: {e}")

if __name__ == "__main__":
    print("Creating a scanned PDF document for OCR testing...")
    print("=" * 60)
    
    # Install required packages if needed
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError:
        print("Installing Pillow...")
        import subprocess
        subprocess.run([sys.executable, "-m", "pip", "install", "Pillow"])
        from PIL import Image, ImageDraw, ImageFont
    
    try:
        from reportlab.pdfgen import canvas
    except ImportError:
        print("Installing reportlab...")
        import subprocess
        import sys
        subprocess.run([sys.executable, "-m", "pip", "install", "reportlab"])
        from reportlab.pdfgen import canvas
    
    # Create the PDF
    pdf_path = create_scanned_document()
    
    # Verify it has no text
    verify_no_text(pdf_path)
    
    print("\nReady for OCR testing!")
    print(f"Test file: {pdf_path}")