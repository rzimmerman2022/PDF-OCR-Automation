# PDF OCR Automation Suite

A powerful PowerShell-based automation tool for batch PDF OCR processing, text extraction, content analysis, and intelligent file renaming using Adobe Acrobat Pro.

##  Features

- **Batch OCR Processing** - Automatically OCR multiple PDF files
- **Multi-Format Export** - Generate searchable PDFs, editable DOCX, and plain text
- **Intelligent Content Recognition** - Extract dates, document types, and key information
- **Smart File Naming** - Rename files based on extracted content
- **Robust Error Handling** - Comprehensive logging and error recovery
- **Extensible Pattern Matching** - Easily customize for different document types

##  Use Cases

### Medical Records
- Lab results and test reports
- Medical imaging reports
- Patient records and histories
- Insurance documents

### Business Documents
- Invoices and receipts
- Contracts and agreements
- Financial statements
- Legal documents

### Academic & Research
- Research papers and journals
- Historical documents
- Books and manuscripts
- Archive digitization

##  Requirements

- **Windows OS** (PowerShell 5.1 or later)
- **Adobe Acrobat Pro** (required for OCR automation - Reader will NOT work)
- **Administrator privileges** (recommended for COM object access)

##  Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/rzimmerman2022/PDF-OCR-Automation.git
   cd PDF-OCR-Automation
   ```

2. **Test your setup:**
   ```powershell
   .\PDF-OCR-Processor.ps1 -WhatIf
   ```

3. **Process files:**
   ```powershell
   .\PDF-OCR-Processor.ps1
   ```

##  Output Examples

### Before Processing:
```
2025-07-19_LabResults_TestDetails_01.pdf
2025-07-19_LabResults_TestDetails_02.pdf
```

### After Processing:
```
2025-07-19_LabResults_CBC-Complete-Blood-Count.pdf
2025-07-19_LabResults_CBC-Complete-Blood-Count.docx
2025-07-19_LabResults_Lipid-Panel-Cholesterol.pdf
2025-07-19_LabResults_Lipid-Panel-Cholesterol.docx
```

##  Important

This tool requires **Adobe Acrobat Pro** (not Reader) for OCR functionality. The COM automation features used are not available in Adobe Reader.

##  Privacy

All processing is done locally on your machine. No files are sent to external services.
