# PDF-OCR-Automation Project Structure

## 📁 Directory Layout

```
PDF-OCR-Automation/
│
├── 📄 README.md                    # Main documentation (START HERE)
├── 📄 LICENSE                      # MIT License
├── 📄 .gitignore                   # Git ignore rules
├── 📄 .env.example                 # Environment variables template
│
├── 📂 OCR-Scripts/                 # MAIN OCR PROCESSING SCRIPTS
│   ├── 📂 PowerShell/
│   │   └── Enhanced-OCRmyPDF-Processor.ps1  # Main batch OCR processor
│   └── 📂 Python/
│       ├── adobe_style_ocr.py      # Python OCR processor
│       └── verify-ai-readable.py   # Verify AI can read PDFs
│
├── 📂 Installation/                # SETUP & INSTALLATION
│   ├── install_ocr_tools.ps1      # Check/install all OCR tools
│   └── install_tesseract.ps1      # Tesseract-specific installer
│
├── 📂 Documentation/               # ALL DOCUMENTATION
│   ├── OCR-BEST-PRACTICES.md      # Detailed best practices guide
│   ├── OCR-FUNCTIONALITY-TEST-RESULTS.md  # Test results
│   ├── QUICK-START-GUIDE.md       # 5-minute quick start
│   └── TROUBLESHOOTING.md         # Common issues & solutions
│
├── 📂 Examples/                    # EXAMPLE SCRIPTS
│   └── Invoice-OCR-Example.ps1    # Invoice processing example
│
├── 📂 Test-PDFs/                   # SAMPLE PDF FILES
│   ├── scanned_document.pdf       # Test scanned PDF (no text)
│   └── scanned_document_OCR.pdf   # After OCR (searchable)
│
├── 📂 Tests/                       # AUTOMATED TESTS
│   └── (various test scripts)
│
└── 📂 Archive/                     # OLD/DEPRECATED FILES
    ├── Old-Scripts/                # Previous versions
    ├── Estate-Scripts/             # Domain-specific old scripts
    └── Logs/                       # Old log files
```

## 🚀 Quick Start Scripts

### For OCR Processing:

1. **PowerShell (Recommended)**:
   ```powershell
   .\OCR-Scripts\PowerShell\Enhanced-OCRmyPDF-Processor.ps1 -InputPath "C:\PDFs" -Language eng
   ```

2. **Python**:
   ```powershell
   python .\OCR-Scripts\Python\adobe_style_ocr.py "C:\PDFs"
   ```

3. **Direct OCRmyPDF**:
   ```powershell
   ocrmypdf input.pdf output.pdf --language eng --optimize 3
   ```

### For Installation:

```powershell
.\Installation\install_ocr_tools.ps1
```

## 📝 Key Files Explained

### Essential Files (Root Directory)
- **README.md** - Start here for overview and instructions
- **LICENSE** - MIT license for open source use
- **.env.example** - Template for environment variables

### Main Scripts
- **Enhanced-OCRmyPDF-Processor.ps1** - Full-featured PowerShell OCR processor
  - Batch processing
  - Progress tracking
  - Error handling
  - All best practices implemented

- **adobe_style_ocr.py** - Python alternative
  - Similar functionality
  - Cross-platform compatible

### Documentation
- **OCR-BEST-PRACTICES.md** - Detailed guide on optimization
- **QUICK-START-GUIDE.md** - Get running in 5 minutes
- **TROUBLESHOOTING.md** - Fix common issues

## ❌ What NOT to Use

Files in the `Archive/` folder are deprecated:
- Old Adobe Acrobat-based scripts
- Estate-specific processors
- Previous versions

## ✅ Best Practices

1. Always use scripts from `OCR-Scripts/` folder
2. Check `Installation/` for setup help
3. Read `Documentation/` for detailed guides
4. Test with files in `Test-PDFs/`

## 🎯 Purpose

This project converts scanned PDFs (image-only) into searchable PDFs that AI models can read and process. It uses industry-standard OCR tools with optimizations for best results.