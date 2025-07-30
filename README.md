# PDF-OCR-Automation

🚀 **Transform non-searchable PDFs into AI-readable documents with advanced OCR technology**

This project provides enterprise-grade OCR capabilities using OCRmyPDF and Tesseract, implementing best practices for reliable text extraction from scanned documents and image-based PDFs.

## 🎯 What This Does

- **Before OCR**: Your scanned PDFs are just images - AI models can't read them
- **After OCR**: Full searchable text layer added - AI can now extract, analyze, and process the content

## ✨ Key Features

- 📄 **Searchable PDFs**: Creates PDFs with invisible text layers (like Adobe Acrobat Pro)
- 🎯 **Best Practices**: 300 DPI, grayscale conversion, noise removal for 5-10% better accuracy
- 📦 **Optimization**: Reduces file size with --optimize 3 flag
- 🌍 **Multi-language**: Supports 100+ languages with explicit specification
- 🔍 **Error Handling**: Comprehensive stderr capture with helpful diagnostics
- 🚀 **Batch Processing**: Process entire folders efficiently
- 🤖 **AI-Ready Output**: Ensures PDFs are readable by AI models and automation tools

## 📋 Prerequisites

- Windows OS with PowerShell 5.1+
- Python 3.x
- Administrator privileges (for installation)

## 🔧 Installation

### Quick Install (Recommended)

Run this in an **Administrator PowerShell**:

```powershell
# 1. Install Chocolatey (if not already installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install complete OCR toolchain
choco install python3 -y
choco install --pre tesseract -y
choco install ghostscript -y
choco install pngquant -y
choco install unpaper -y
pip install --upgrade ocrmypdf
```

### Verify Installation

```powershell
# Run the installation checker
.\Installation\install_ocr_tools.ps1
```

## 🚀 Quick Start

### 1. Basic OCR Command

```powershell
# Add Tesseract to PATH (required for each session)
$env:PATH = $env:PATH + ";C:\Program Files\Tesseract-OCR"

# Simple OCR
ocrmypdf input.pdf output.pdf --language eng

# With best practices
ocrmypdf input.pdf output.pdf --language eng --optimize 3 --deskew --clean --oversample 300
```

### 2. PowerShell Script (Recommended)

```powershell
# Process single file
.\OCR-Scripts\PowerShell\Enhanced-OCRmyPDF-Processor.ps1 -InputPath "scan.pdf" -Language eng -Optimize 3

# Process entire folder
.\OCR-Scripts\PowerShell\Enhanced-OCRmyPDF-Processor.ps1 -InputPath "C:\Scans" -Language eng -Optimize 3

# Preview mode (no changes)
.\OCR-Scripts\PowerShell\Enhanced-OCRmyPDF-Processor.ps1 -InputPath "C:\Scans" -WhatIf
```

### 3. Python Script

```powershell
# Process folder with automatic detection
python .\OCR-Scripts\Python\adobe_style_ocr.py "C:\Documents\Scans"
```

## 📁 Project Structure

```
PDF-OCR-Automation/
├── OCR-Scripts/           # Main OCR processing scripts
│   ├── PowerShell/        # Enhanced-OCRmyPDF-Processor.ps1
│   └── Python/            # adobe_style_ocr.py, verify-ai-readable.py
├── Installation/          # Installation and setup scripts
├── Documentation/         # Detailed guides and best practices
├── Test-PDFs/            # Sample PDFs for testing
├── Examples/             # Example scripts and use cases
└── Archive/              # Old scripts and logs
```

## 🎓 Common Use Cases

### Invoice Processing
```powershell
.\OCR-Scripts\PowerShell\Enhanced-OCRmyPDF-Processor.ps1 -InputPath ".\Invoices" -Language eng -Optimize 3
```

### Multi-language Documents
```powershell
# English and Spanish
.\OCR-Scripts\PowerShell\Enhanced-OCRmyPDF-Processor.ps1 -InputPath "doc.pdf" -Language "eng+spa"

# Asian languages
.\OCR-Scripts\PowerShell\Enhanced-OCRmyPDF-Processor.ps1 -InputPath "doc.pdf" -Language "eng+jpn+chi_sim"
```

### Large Color Scans
```powershell
# Maximum compression without quality loss
.\OCR-Scripts\PowerShell\Enhanced-OCRmyPDF-Processor.ps1 -InputPath "large_scan.pdf" -Optimize 3 -Grayscale
```

## 📊 Performance & Results

- **Accuracy**: 5-10% improvement with pre-clean settings
- **File Size**: 30-75% reduction with optimization
- **Speed**: ~2-10 seconds per page (depends on complexity)
- **Success Rate**: 95%+ on quality scans

## 🔍 Troubleshooting

### "Tesseract not found"
```powershell
# Add to PATH temporarily
$env:PATH = $env:PATH + ";C:\Program Files\Tesseract-OCR"

# Or reinstall
choco install --pre tesseract -y
```

### "pngquant not found" (for --optimize 2,3)
```powershell
choco install pngquant -y
```

### Low OCR Quality
- Enable pre-clean: `-Grayscale -CleanPages`
- Increase DPI: `-DPI 300` or higher
- Check scan quality (avoid JPEG compression)

## 📚 Documentation

- **[OCR Best Practices](./Documentation/OCR-BEST-PRACTICES.md)** - Detailed implementation guide
- **[Test Results](./Documentation/OCR-FUNCTIONALITY-TEST-RESULTS.md)** - Proof of concept
- **[Troubleshooting Guide](./TROUBLESHOOTING.md)** - Common issues and solutions

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **OCRmyPDF** - The powerful OCR engine
- **Tesseract OCR** - Google's OCR engine
- **Ghostscript** - PDF rendering

---

**Note**: This tool is designed for legitimate document processing. Please ensure you have the right to process any PDFs you use with this tool.