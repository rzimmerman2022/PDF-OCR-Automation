# Universal PDF OCR Automation Suite 

**Intelligent Document Processing with Adobe Acrobat Pro Integration**

Transform any folder of PDF documents into intelligently named, searchable files with automatic content detection and OCR processing.

##  Universal Capabilities

###  Supported Document Types
- **Medical Records** - Lab results, visit summaries, prescriptions, imaging reports
- **Invoices & Financial** - Bills, receipts, purchase orders, estimates, credit notes  
- **Legal Documents** - Contracts, agreements, filings, patents, compliance docs
- **Technical Reports** - Manuals, specifications, engineering docs, presentations
- **General Business** - Any PDF document with automatic content detection

###  Key Features
- **Flexible Folder Processing** - Process any folder, anywhere on your system
- **Automatic Content Detection** - Intelligently identifies document types and key information
- **Smart Naming** - Generates descriptive filenames based on content analysis
- **OCR Integration** - Makes scanned documents fully searchable
- **Preview Mode** - Test processing without making changes
- **Universal Application** - Works across industries and document types

##  Quick Start

### Basic Usage
```powershell
# Process any documents
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Documents" -DocumentType medical

# Process invoices  
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Invoices" -DocumentType invoice

# Process any folder with auto-detection
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder "C:\MyDocuments\PDFs"

# Preview mode (safe testing)
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Documents" -WhatIf
```

### Advanced Examples
```powershell
# Process legal documents with detailed output
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder "C:\Legal\Contracts" -DocumentType legal -DetailedOutput

# Auto-detect document types in mixed folder
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Mixed-Documents" -DocumentType auto

# Preview processing of specific folder
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder "\\Server\Shared\PDFs" -WhatIf
```

##  Project Structure

```
PDF-OCR-Automation/

  Universal-PDF-OCR-Processor.ps1   # Main universal script
  Setup.ps1                         # Environment setup
  README.md                         # This documentation
  LICENSE                           # MIT license
  .gitignore                        # Git ignore rules

  Templates/                        # Customization templates
    Universal-OCR-Template.ps1       # Base template for new document types
    Config-Template.ps1              # Configuration template

  Examples/                         # Working examples  
    Invoice-OCR-Example.ps1          # Invoice processing example

  Documents/                    # Medical records folder
  Invoices/                         # Invoice documents folder  
  Documents/                        # General documents folder
  Processed/                        # Output folder for results
```

##  Prerequisites

### Required Software
- **Windows OS** with PowerShell 5.1 or higher
- **Adobe Acrobat Pro** (not Reader) - Full version required for COM automation
- **Sufficient disk space** for temporary file processing

### Environment Setup
1. **Install Adobe Acrobat Pro** and ensure it''s licensed
2. **Add Acrobat to PATH** (typically `C:\Program Files\Adobe\Acrobat DC\Acrobat\`)
3. **Run Setup Script**: `.\Setup.ps1` to create required folders
4. **Test Environment**: `.\Universal-PDF-OCR-Processor.ps1 -WhatIf`

##  Parameters & Options

### Main Parameters
| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `TargetFolder` | String | Folder containing PDFs to process | `".\Documents"` |
| `DocumentType` | String | Type filter: auto, medical, invoice, legal, general | `medical` |
| `WhatIf` | Switch | Preview mode - no changes made | `-WhatIf` |
| `DetailedOutput` | Switch | Verbose logging for troubleshooting | `-DetailedOutput` |

### Document Type Patterns
The script automatically detects content using advanced pattern matching:

**Medical**: CBC, CMP, Lipid Panel, HbA1c, Thyroid, PSA, Urinalysis, Visit Summary
**Invoice**: Invoice, Bill, Receipt, Purchase Order, Estimate, Credit Note  
**Legal**: Contract, Agreement, Patent, Compliance, Affidavit, Court Order
**Technical**: Report, Manual, Specification, Presentation, Certificate

##  Naming Convention Examples

### Before vs After Processing
```
Before:  Scanned_Document_001.pdf
After:   2025-07-19_MedRecord_CBC-Complete-Blood-Count.pdf

Before:  IMG_20250715_invoice.pdf  
After:   2025-07-15_Invoice_Payment-Receipt.pdf

Before:  contract_final_v3.pdf
After:   2025-07-19_Legal_Contract-Agreement.pdf
```

### Smart Duplicate Handling
```
2025-07-19_MedRecord_CBC-Complete-Blood-Count.pdf
2025-07-19_MedRecord_CBC-Complete-Blood-Count_2.pdf
2025-07-19_MedRecord_CBC-Complete-Blood-Count_3.pdf
```

##  Customization & Extension

### Adding New Document Types
1. Copy `Templates/Universal-OCR-Template.ps1`
2. Modify pattern matching for your document type
3. Add to the `$DocumentPatterns` hashtable
4. Test with `-WhatIf` mode

### Creating Industry-Specific Scripts
Use the templates to create specialized processors:
- Real Estate documents
- HR records  
- Engineering specifications
- Financial statements
- Insurance claims

##  Troubleshooting

### Common Issues
| Issue | Solution |
|-------|----------|
| "Adobe Acrobat executable not found" | Install Acrobat Pro, add to PATH |
| "Failed to create Adobe Acrobat application object" | Run PowerShell as Administrator |
| OCR fails on some documents | Use Windows PowerShell (x86) on 64-bit systems |
| Files won''t rename | Check file permissions, close open files |

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
- **Medical Practice Management** - Organize patient records
- **Legal Document Processing** - Systematize case files
- **Invoice Management** - Streamline accounting workflows  
- **Technical Documentation** - Organize engineering specs
- **General Office Automation** - Any document-heavy business

---

##  Ready to Get Started?

1. **Setup**: Run `.\Setup.ps1` to create folders
2. **Test**: Run `.\Universal-PDF-OCR-Processor.ps1 -WhatIf` to verify environment  
3. **Process**: Add PDFs to appropriate folder and run the script
4. **Customize**: Use templates to adapt for your specific needs

**Transform your document chaos into organized, searchable intelligence!** 
