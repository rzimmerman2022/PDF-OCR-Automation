# PDF-OCR-Automation

🚀 **Enterprise-grade OCR automation for converting scanned PDFs into searchable, AI-readable documents**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://docs.microsoft.com/en-us/powershell/)

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Configuration](#configuration)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## 🎯 Overview

PDF-OCR-Automation transforms non-searchable PDFs (scanned documents, images) into fully searchable PDFs with embedded text layers that AI models can read and process. Built on industry-standard OCR engines (OCRmyPDF, Tesseract), it implements best practices for maximum accuracy and reliability.

### Before & After

- **Before OCR**: Your scanned PDFs are just images - AI models can't read them
- **After OCR**: Full searchable text layer added - AI can now extract, analyze, and process the content

## ✨ Features

- 📄 **Searchable PDFs**: Creates PDFs with invisible text layers (like Adobe Acrobat Pro)
- 🎯 **Best Practices**: 300 DPI, grayscale conversion, noise removal for 5-10% better accuracy
- 📦 **Optimization**: Reduces file size with `--optimize 3` flag
- 🌍 **Multi-language**: Supports 100+ languages with explicit specification
- 🔍 **Error Handling**: Comprehensive stderr capture with helpful diagnostics
- 🚀 **Batch Processing**: Process entire folders efficiently
- 🤖 **AI-Ready Output**: Ensures PDFs are readable by AI models and automation tools
- ⚡ **Performance**: Parallel processing with configurable worker threads
- 🎪 **Quick OCR Utility**: New `ocr_pdfs.py` for instant OCR on any folder

## 📁 Project Structure

```
PDF-OCR-Automation/
├── 📄 README.md                    # This file - start here
├── 📄 LICENSE                      # MIT License
├── 📄 .gitignore                   # Git ignore rules
├── 📄 .editorconfig               # Editor configuration
├── 📄 requirements.txt            # Python dependencies
├── 📄 pyproject.toml             # Python project metadata
├── 📄 Makefile                    # Build automation
│
├── 📂 src/                        # Source code
│   ├── 📂 core/                   # Core functionality
│   ├── 📂 processors/             # OCR processors
│   │   ├── OCRmyPDF-Processor.ps1
│   │   └── ocr_processor.py
│   ├── 📂 utils/                  # Utility functions
│   └── 📂 validators/             # Validation tools
│       └── verify_ai_readable.py
│
├── 📂 scripts/                    # Executable scripts
│   ├── 📂 install/               # Installation scripts
│   │   ├── install_ocr_tools.ps1
│   │   └── install_tesseract.ps1
│   └── 📂 examples/              # Example scripts
│       └── Invoice-OCR-Example.ps1
│
├── 📄 ocr_pdfs.py                # Quick OCR utility for any folder
│
├── 📂 config/                     # Configuration files
│   ├── default.json              # Default settings
│   └── env.example               # Environment template
│
├── 📂 tests/                      # Test suite
│   ├── 📂 unit/                  # Unit tests
│   ├── 📂 integration/           # Integration tests
│   └── 📂 fixtures/              # Test data
│
├── 📂 docs/                       # Documentation
│   ├── OCR-BEST-PRACTICES.md
│   ├── QUICK-START-GUIDE.md
│   └── TROUBLESHOOTING.md
│
├── 📂 samples/                    # Sample PDFs
│   ├── scanned_document.pdf
│   └── scanned_document_OCR.pdf
│
├── 📂 output/                     # Output directory
│   ├── 📂 logs/                  # Process logs
│   ├── 📂 processed/             # Processed files
│   └── 📂 reports/               # Reports
│
├── 📂 tools/                      # Additional tools
└── 📂 archive/                    # Archived/deprecated files
```

## 🔧 Installation

### Prerequisites

- Windows OS with PowerShell 5.1+
- Python 3.8+
- Administrator privileges (for installation)

### Quick Install (Recommended)

Run in **Administrator PowerShell**:

```powershell
# Clone the repository
git clone https://github.com/yourusername/PDF-OCR-Automation.git
cd PDF-OCR-Automation

# Run installation script
.\scripts\install\install_ocr_tools.ps1
```

### Manual Installation

1. **Install Chocolatey** (if not installed):
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

2. **Install OCR toolchain**:
```powershell
choco install python3 tesseract ghostscript pngquant unpaper -y
```

3. **Install Python dependencies**:
```powershell
pip install -r requirements.txt
```

### Verify Installation

```powershell
# Check installations
ocrmypdf --version
tesseract --version
python --version
```

## 🚀 Quick Start

### PowerShell (Recommended)

```powershell
# Process a single PDF
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath "C:\path\to\input.pdf" -Language eng

# Process entire folder
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath "C:\path\to\pdfs" -Language eng
```

### Python

```bash
# Process a single PDF
python src/processors/ocr_processor.py "C:\path\to\input.pdf"

# Process entire folder
python src/processors/ocr_processor.py "C:\path\to\pdfs" --language eng

# Quick OCR any folder - NEW!
python ocr_pdfs.py "C:\path\to\any\folder"
```

### Direct OCRmyPDF

```bash
ocrmypdf input.pdf output.pdf --language eng --optimize 3 --deskew --clean --clean-final
```

## 📖 Usage

### Basic Processing

```powershell
# Simple OCR with default settings
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath "document.pdf"

# Specify language (e.g., German)
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath "document.pdf" -Language deu

# Process folder with Spanish
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath "C:\Documents" -Language spa
```

### Advanced Options

```powershell
# Custom output directory
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath "input.pdf" -OutputPath "C:\Processed"

# Force re-OCR existing text
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath "input.pdf" -ForceOCR

# Custom DPI and optimization
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath "input.pdf" -DPI 600 -OptimizeLevel 2
```

### Verify AI Readability

```python
# Check if PDF is AI-readable
python src/validators/verify_ai_readable.py "processed_document.pdf"
```

## ⚙️ Configuration

### Environment Variables

Copy `config/env.example` to `.env` and customize:

```env
# OCR Settings
OCR_LANGUAGE=eng
OCR_DPI=300
OCR_OPTIMIZE_LEVEL=3

# Processing
PARALLEL_JOBS=4
BATCH_SIZE=10

# Paths
TESSERACT_PATH=C:\Program Files\Tesseract-OCR
OUTPUT_PATH=./output/processed
```

### Configuration File

Edit `config/default.json` for global settings:

```json
{
  "ocr": {
    "language": "eng",
    "dpi": 300,
    "optimize": 3
  },
  "processing": {
    "parallelJobs": 4,
    "batchSize": 10
  }
}
```

## 🧪 Testing

### Run All Tests

```bash
# Using Make
make test

# Using pytest directly
pytest tests/ -v

# With coverage report
pytest tests/ -v --cov=src --cov-report=html
```

### Run Specific Tests

```bash
# Unit tests only
pytest tests/unit/

# Integration tests
pytest tests/integration/

# Specific test file
pytest tests/unit/test_ocr_processor.py
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Install development dependencies
pip install -r requirements.txt
pip install -e .

# Set up pre-commit hooks
pre-commit install

# Run linting
make lint

# Format code
make format
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OCRmyPDF](https://github.com/ocrmypdf/OCRmyPDF) - The core OCR engine
- [Tesseract](https://github.com/tesseract-ocr/tesseract) - Open source OCR engine
- [Ghostscript](https://www.ghostscript.com/) - PDF processing
- All contributors who have helped improve this project

---

**Need help?** Check out our [documentation](docs/) or [open an issue](https://github.com/yourusername/PDF-OCR-Automation/issues).