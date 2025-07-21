# Universal PDF OCR Automation Suite 

**Intelligent Document Processing with Adobe Acrobat Pro Integration**

Transform any folder of PDF documents into intelligently named, searchable files with automatic content detection and OCR processing.

##  Universal Capabilities

###  Supported Document Types
- **Business Reports** - Annual reports, meeting minutes, financial statements, business plans
- **Technical Documentation** - User manuals, specifications, API docs, system requirements  
- **Invoices & Financial** - Bills, receipts, purchase orders, estimates, credit notes  
- **Legal Documents** - Contracts, agreements, filings, patents, compliance docs
- **General Business** - Any PDF document with automatic content detection

###  Key Features
- **Flexible Folder Processing** - Process any folder, anywhere on your system
- **Automatic Content Detection** - Intelligently identifies document types and key information
- **Smart Naming** - Generates descriptive filenames based on content analysis
- **OCR Integration** - Makes scanned documents fully searchable
- **Preview Mode** - Test processing without making changes
- **Universal Application** - Works across industries and document types

##  Quick Start

### Installation
```powershell
# 1. Clone the repository
git clone https://github.com/yourusername/PDF-OCR-Automation.git
cd PDF-OCR-Automation

# 2. Run setup script
.\Setup.ps1

# 3. Add Adobe to PATH (if needed)
.\Add-AdobeToPath.ps1

# 4. Test the installation
.\Universal-PDF-OCR-Processor.ps1 -WhatIf
```

### Basic Usage
```powershell
# Process any documents
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Documents"

# Process business reports  
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Reports" -DocumentType business

# Process technical documentation
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Technical" -DocumentType technical

# Process invoices  
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Invoices" -DocumentType invoice

# Process any folder with auto-detection
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder "C:\MyDocuments\PDFs"

# Preview mode (safe testing)
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Documents" -WhatIf
```

### Real-World Examples

#### Example 1: Processing Monthly Invoices
```powershell
# Create invoice batch folder
mkdir "2025-01-Invoices"
# Copy/move PDFs to folder
# Process with intelligent naming
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\2025-01-Invoices" -DocumentType invoice

# Results:
# Scanned_001.pdf → 2025-01-15_Invoice_ABC-Corp-12345.pdf
# IMG_4567.pdf → 2025-01-20_Invoice_Payment-Receipt-67890.pdf
```

#### Example 2: Organizing Technical Documentation
```powershell
# Process product manuals
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder "D:\Product-Manuals" -DocumentType technical -DetailedOutput

# Results:
# manual_v2.pdf → 2025-07-19_Technical_User-Manual-v2.pdf
# spec_sheet.pdf → 2025-07-19_Technical_Product-Specification.pdf
```

#### Example 3: Legal Document Management
```powershell
# Preview processing of legal documents
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder "\\Legal\Contracts\2025" -DocumentType legal -WhatIf

# See what would be renamed without making changes
```

#### Example 4: Mixed Document Processing
```powershell
# Auto-detect various document types in one folder
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder "C:\Unorganized\PDFs" -DocumentType auto

# Script automatically categorizes:
# - Invoices → 2025-XX-XX_Invoice_*.pdf
# - Reports → 2025-XX-XX_Business_*.pdf
# - Contracts → 2025-XX-XX_Legal_*.pdf
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
