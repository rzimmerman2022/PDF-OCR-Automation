# Quick Start Guide - PDF OCR Automation

Get up and running in 5 minutes!

## 🚀 Quick Installation

### Option 1: Automated Installation (Recommended)

```powershell
# Clone the repository
git clone https://github.com/yourusername/PDF-OCR-Automation.git
cd PDF-OCR-Automation

# Run installation script in Administrator PowerShell
.\scripts\install\install_ocr_tools.ps1
```

### Option 2: Manual Installation

```powershell
# Run in Administrator PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install python3 tesseract ghostscript pngquant unpaper -y
pip install -r requirements.txt
```

## ✅ Test Your Installation

```powershell
# Check if everything is installed
tesseract --version
ocrmypdf --version
python --version
```

## 🎯 Your First OCR

```powershell
# Process a single PDF (PowerShell - Recommended)
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath "input.pdf" -Language eng

# Process a single PDF (Python)
python src\processors\ocr_processor.py "input.pdf"

# Quick OCR any folder - NEW!
python ocr_pdfs.py "C:\path\to\any\folder"

# Run OCR on a PDF
ocrmypdf "scanned.pdf" "searchable.pdf" --language eng --optimize 3
```

## 🔥 Process Multiple PDFs

```powershell
# PowerShell script (full control)
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath "C:\MyPDFs" -Language eng

# Quick Python utility (simple & fast) - NEW!
python ocr_pdfs.py "C:\MyPDFs"
```

## 📝 Common Tasks

### Make a scanned PDF searchable:
```powershell
ocrmypdf scan.pdf output.pdf --language eng --force-ocr
```

### Process invoices in a folder:
```powershell
# PowerShell approach
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath ".\Invoices" -Language eng

# Quick Python approach - NEW!
python ocr_pdfs.py ".\Invoices"
```

### Multi-language document:
```powershell
ocrmypdf doc.pdf output.pdf --language "eng+spa+fra"
```

## 💡 Tips

1. **Tesseract PATH**: Add to each PowerShell session or add permanently to system PATH
2. **Force OCR**: Use `--force-ocr` for PDFs that already have some text
3. **Preview Mode**: Use `-WhatIf` to see what would happen without making changes

## 🆘 Need Help?

- Check [README.md](README.md) for detailed instructions
- See [Documentation/OCR-BEST-PRACTICES.md](Documentation/OCR-BEST-PRACTICES.md) for optimization tips
- Run test script: `python .\OCR-Scripts\Python\verify-ai-readable.py`

---

**That's it! You're ready to convert scanned PDFs into AI-readable documents!**