# Quick Start Guide - PDF OCR Automation

Get up and running in 5 minutes!

## 🚀 Quick Installation

```powershell
# Run in Administrator PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install python3 --pre tesseract ghostscript pngquant unpaper -y
pip install --upgrade ocrmypdf
```

## ✅ Test Your Installation

```powershell
# Check if everything is installed
tesseract --version
ocrmypdf --version
```

## 🎯 Your First OCR

```powershell
# Add Tesseract to PATH
$env:PATH = $env:PATH + ";C:\Program Files\Tesseract-OCR"

# Run OCR on a PDF
ocrmypdf "scanned.pdf" "searchable.pdf" --language eng --optimize 3
```

## 🔥 Process Multiple PDFs

```powershell
# Use the PowerShell script
.\OCR-Scripts\PowerShell\Enhanced-OCRmyPDF-Processor.ps1 -InputPath "C:\MyPDFs" -Language eng -Optimize 3
```

## 📝 Common Tasks

### Make a scanned PDF searchable:
```powershell
ocrmypdf scan.pdf output.pdf --language eng --force-ocr
```

### Process invoices in a folder:
```powershell
.\OCR-Scripts\PowerShell\Enhanced-OCRmyPDF-Processor.ps1 -InputPath ".\Invoices" -Language eng
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