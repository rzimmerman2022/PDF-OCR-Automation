# OCR PDFs Utility - Quick Batch Processing

## Overview

`ocr_pdfs.py` is a streamlined utility for quickly OCR'ing all PDFs in any specified folder. It creates searchable PDFs with invisible text layers, making them AI-readable while preserving the original appearance.

## Features

- 🚀 **Simple command-line interface** - just specify a folder path
- 🔍 **Automatic detection** - identifies which PDFs need OCR
- 💾 **Backup creation** - preserves original files before processing
- 📊 **Progress tracking** - shows real-time processing status
- ✅ **Summary report** - displays results after completion

## Usage

### Basic Usage

```bash
python ocr_pdfs.py "C:\path\to\your\folder"
```

### Examples

```bash
# Process estate documents
python ocr_pdfs.py "C:\Users\Documents\Estate Research"

# Process invoices
python ocr_pdfs.py "D:\Business\Invoices\2025"

# Process downloads folder
python ocr_pdfs.py "C:\Users\YourName\Downloads"
```

## How It Works

1. **Scans the specified folder** for all PDF files
2. **Checks each PDF** to determine if it already has searchable text
3. **Skips PDFs** that are already searchable (no unnecessary processing)
4. **Creates backups** of PDFs that need OCR (`.backup` extension)
5. **Performs OCR** using optimized settings for best quality
6. **Reports results** including success/failure counts

## Requirements

- Python 3.8+
- OCRmyPDF installed (`pip install ocrmypdf`)
- Tesseract OCR installed (via Chocolatey or manual installation)
- Ghostscript (for PDF processing)

## Output

The utility provides detailed output during processing:

```
============================================================
OCR PROCESSING - PDF BATCH PROCESSOR
============================================================
Directory: C:\Users\Documents\Estate Research

Scanning for PDFs...

Found 15 PDF files

Checking: document1.pdf... Needs OCR
Checking: document2.pdf... Already searchable
...

============================================================
Summary:
  - Total PDFs: 15
  - Already searchable: 5
  - Need OCR: 10
============================================================

[1/10] Processing: document1.pdf
------------------------------------------------------------
  [SUCCESS] OCR completed for: document1.pdf

...

============================================================
OCR PROCESSING COMPLETE
============================================================
  - Successfully processed: 10/10
  - Already searchable: 5
  - Failed: 0

============================================================
All successfully processed PDFs now have searchable text layers!
You can search, copy text, and use them with any PDF reader.
============================================================
```

## Best Practices

1. **Test on a small folder first** to ensure proper setup
2. **Verify backups** are created before processing large batches
3. **Check available disk space** - OCR can temporarily increase file sizes
4. **Process similar documents together** for consistent results

## Troubleshooting

### Common Issues

**"No PDF files found"**
- Verify the folder path is correct
- Ensure the folder contains PDF files (not in subfolders)

**"Missing requirements"**
- Install Tesseract OCR: `choco install tesseract`
- Install Python dependencies: `pip install ocrmypdf`

**"Permission denied"**
- Close any PDFs open in readers
- Run with appropriate permissions

## Integration with Main System

This utility integrates seamlessly with the PDF-OCR-Automation system:

- Uses the same OCR processor (`src/processors/ocr_processor.py`)
- Follows project best practices for OCR quality
- Compatible with all language settings
- Maintains consistent output standards

## Performance Notes

- Processing time depends on PDF size and complexity
- Typical processing: 5-30 seconds per page
- Parallel processing used when available
- Original PDFs preserved as `.backup` files