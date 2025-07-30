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

##  Project Structure

```
PDF-OCR-Automation/
├── Universal-PDF-OCR-Processor.ps1   # Main universal script
├── Setup.ps1                         # Environment setup & validation
├── Add-AdobeToPath.ps1              # Adobe PATH configuration helper
├── README.md                         # This documentation
├── SUMMARY.md                       # Project summary
├── LICENSE                          # MIT license
├── .gitignore                       # Git ignore rules
│
├── Templates/                       # Customization templates
│   ├── Universal-OCR-Template.ps1    # Base template for new document types
│   └── Config-Template.ps1           # Configuration template
│
├── Examples/                        # Working examples  
│   └── Invoice-OCR-Example.ps1       # Invoice processing example
│
├── Tests/                           # Automated test suite
│   ├── Test-PDFOCRProcessor.ps1      # Unit tests for main script
│   └── Test-OCRPerformance.ps1       # Performance validation tests
│
├── Test-PDFs/                       # Sample test documents
│   ├── Create-TestContent.ps1        # Generate test content
│   └── *.html, *.txt                 # Test document templates
│
└── [Documents|Reports|Technical|Invoices|Processed]/  # Working folders
```

##  Prerequisites

### Required Software
- **Windows OS** with PowerShell 5.1 or higher
- **Adobe Acrobat Pro** (not Reader) - Full version required for COM automation
- **Sufficient disk space** for temporary file processing

### Environment Setup
1. **Install Adobe Acrobat Pro** and ensure it's licensed
2. **Run Setup Script**: `.\Setup.ps1` to validate environment
3. **Add Adobe to PATH**: Run `.\Add-AdobeToPath.ps1` if Adobe is not on PATH
4. **Test Environment**: `.\Universal-PDF-OCR-Processor.ps1 -WhatIf`

> **Note**: Adobe Acrobat Pro (not Reader) is required for OCR functionality. The scripts will run in preview mode without it for testing purposes.

##  Parameters & Options

### Main Parameters
| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `TargetFolder` | String | Folder containing PDFs to process | `".\Documents"` |
| `DocumentType` | String | Type filter: auto, business, technical, invoice, legal, general | `business` |
| `WhatIf` | Switch | Preview mode - no changes made | `-WhatIf` |
| `DetailedOutput` | Switch | Verbose logging for troubleshooting | `-DetailedOutput` |

### Document Type Patterns
The script automatically detects content using advanced pattern matching:

**Business**: Annual Report, Meeting Minutes, Business Plan, Financial Statement, Performance Review

**Technical**: User Manual, Technical Specification, API Documentation, Test Report, System Requirements
**Invoice**: Invoice, Bill, Receipt, Purchase Order, Estimate, Credit Note  
**Legal**: Contract, Agreement, Patent, Compliance, Affidavit, Court Order
**Technical**: Report, Manual, Specification, Presentation, Certificate

##  Naming Convention Examples

### Before vs After Processing
```
Before:  Scanned_Document_001.pdf
After:   2025-07-19_Business_Annual-Report.pdf

Before:  technical_manual_v2.pdf
After:   2025-07-19_Technical_User-Manual.pdf

Before:  IMG_20250715_invoice.pdf  
After:   2025-07-15_Invoice_Payment-Receipt.pdf

Before:  contract_final_v3.pdf
After:   2025-07-19_Legal_Contract-Agreement.pdf
```

### Smart Duplicate Handling
```
2025-07-19_Business_Annual-Report.pdf
2025-07-19_Business_Annual-Report_2.pdf
2025-07-19_Business_Annual-Report_3.pdf
```

##  Customization & Extension

### Adding New Document Types
1. Copy `Templates/Universal-OCR-Template.ps1`
2. Modify pattern matching for your document type
3. Add to the `$DocumentPatterns` hashtable
4. Test with `-WhatIf` mode

### Creating Industry-Specific Scripts
Use the templates to create specialized processors:

#### Healthcare Example
```powershell
# Copy template
Copy-Item ".\Templates\Universal-OCR-Template.ps1" ".\Healthcare-OCR-Processor.ps1"

# Add patterns for medical documents
$DocumentPatterns["medical"] = @(
    @{Pattern = 'patient\s+record'; Type = 'Patient-Record'},
    @{Pattern = 'lab\s+results?'; Type = 'Lab-Results'},
    @{Pattern = 'prescription'; Type = 'Prescription'}
)
```

#### Real Estate Example
```powershell
# Customize for property documents
$DocumentPatterns["realestate"] = @(
    @{Pattern = 'purchase\s+agreement'; Type = 'Purchase-Agreement'},
    @{Pattern = 'property\s+deed'; Type = 'Property-Deed'},
    @{Pattern = 'inspection\s+report'; Type = 'Inspection-Report'}
)
```

##  Troubleshooting

### Common Issues & Solutions

#### Adobe Acrobat Not Found
```powershell
# Run the Adobe PATH helper
.\Add-AdobeToPath.ps1

# Or manually add to PATH:
$env:PATH += ";C:\Program Files\Adobe\Acrobat DC\Acrobat"
```

#### Permission Errors
```powershell
# Run PowerShell as Administrator
Start-Process powershell -Verb RunAs

# Then navigate to script folder and run
cd "C:\Projects\PDF-OCR-Automation"
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Documents"
```

#### OCR Failures
```powershell
# For 64-bit systems, try 32-bit PowerShell
C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Documents"
```

#### File Access Issues
```powershell
# Check for locked files
Get-Process | Where-Object {$_.MainWindowTitle -like "*Adobe*"} | Stop-Process -Force

# Verify permissions
Get-Acl ".\Documents\*.pdf" | Format-List
```

### Performance Tips
- **Close other applications** during large batch processing
- **Use SSD storage** for faster temporary file operations  
- **Process folders with <100 files** at a time for stability
- **Monitor disk space** - OCR can create large temporary files

##  Contributing & Usage Rights

### Open Source License
This project is licensed under the **MIT License** - see `LICENSE` file for details.

### Commercial Use Welcome
-  Use in business environments
-  Modify for specific needs  
-  Integrate into workflows
-  Share and distribute

### Contributions
-  Bug reports and fixes welcome
-  Feature requests considered
-  Documentation improvements appreciated
-  Test cases and examples valued

##  Business Value

### Portfolio Showcase
This repository demonstrates:
- **Advanced PowerShell scripting** with COM automation
- **Document processing workflows** and pattern recognition  
- **Error handling and logging** best practices
- **Modular, extensible design** principles
- **User experience focus** with clear feedback and preview modes

### Practical Applications
- **Business Document Management** - Organize company reports and documentation
- **Technical Documentation Systems** - Maintain product manuals and specifications
- **Legal Document Processing** - Systematize case files
- **Invoice Management** - Streamline accounting workflows  
- **Technical Documentation** - Organize engineering specs
- **General Office Automation** - Any document-heavy business

---

##  Testing & Validation

### Running Tests
```powershell
# Run all automated tests
.\Tests\Test-PDFOCRProcessor.ps1

# Run performance validation
.\Tests\Test-OCRPerformance.ps1 -GenerateReport

# Generate test PDFs
.\Test-PDFs\Create-TestContent.ps1
```

### Test Coverage
- ✅ Environment validation
- ✅ Script syntax checking
- ✅ Parameter validation
- ✅ Error handling
- ✅ Performance benchmarks
- ✅ OCR accuracy measurement

##  Ready to Get Started?

1. **Setup**: Run `.\Setup.ps1` to validate environment
2. **Configure**: Run `.\Add-AdobeToPath.ps1` if Adobe isn't on PATH
3. **Test**: Run `.\Universal-PDF-OCR-Processor.ps1 -WhatIf` to preview  
4. **Process**: Add PDFs to any folder and run the script
5. **Customize**: Use templates to adapt for your specific needs

**Transform your document chaos into organized, searchable intelligence!**

---

### Support & Feedback
- 📧 Report issues on GitHub
- 🔧 Pull requests welcome
- 📚 Check the troubleshooting guide
- 🚀 Share your success stories 
