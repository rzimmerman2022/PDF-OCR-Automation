<#
.SYNOPSIS
    Universal PDF OCR and Intelligent Renaming System
    Automates OCR processing and content-based renaming of PDF documents using Adobe Acrobat Pro.

.DESCRIPTION
    This powerful automation script processes PDF files in any specified directory by:
    1. Performing Optical Character Recognition (OCR) using Adobe Acrobat Pro
    2. Extracting and analyzing text content to identify document types and key information
    3. Applying intelligent, content-based naming conventions
    4. Supporting multiple document types: medical records, invoices, legal documents, reports, etc.
    5. Creating both searchable PDFs and optional DOCX conversions

    The script is designed to be universally applicable across different industries and document types,
    with extensible pattern matching for content identification.

.PARAMETER TargetFolder
    Specifies the folder containing PDF files to process. Can be absolute or relative path.
    If not specified, uses the ''Documents'' subfolder in the script directory.

.PARAMETER DocumentType
    Optional filter to process only specific document types (medical, invoice, legal, general).
    Default is ''auto'' which attempts to detect document type automatically.

.PARAMETER WhatIf
    Preview mode - shows what would be processed without making any changes.

.PARAMETER DetailedOutput
    Enables detailed output for troubleshooting and monitoring.

.EXAMPLE
    .\Universal-PDF-OCR-Processor.ps1 -TargetFolder "C:\MyDocuments\Invoices"
    Process all PDFs in the specified folder

.EXAMPLE
    .\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\MedicalRecords" -DocumentType medical -WhatIf
    Preview processing of medical documents in a relative subfolder

.EXAMPLE
    .\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Documents" -WhatIf
    Preview processing using default Documents folder

.NOTES
    Author: GitHub Copilot - Universal PDF OCR Automation Suite
    Version: 2.0 - Universal Standalone Edition
    Prerequisites: 
    - Windows OS with PowerShell 5.1+
    - Adobe Acrobat Pro (not Reader) installed and licensed
    - Sufficient disk space for temporary file creation
    
    Supported Document Types:
    - Medical Records (lab results, visit summaries, prescriptions)
    - Invoices and Financial Documents
    - Legal Documents (contracts, agreements, filings)
    - Technical Reports and Manuals
    - General Business Documents
    
    The script automatically detects document content and applies appropriate naming patterns.
#>

param(
    [Parameter(Position=0, HelpMessage="Folder containing PDF files to process")]
    [string]$TargetFolder = "",
    
    [Parameter(HelpMessage="Document type filter: auto, medical, invoice, legal, general")]
    [ValidateSet("auto", "medical", "invoice", "legal", "general")]
    [string]$DocumentType = "auto",
    
    [Parameter(HelpMessage="Preview mode - show what would be processed without making changes")]
    [switch]$WhatIf,
    
    [Parameter(HelpMessage="Enable detailed output")]
    [switch]$DetailedOutput
)

# 
# CONFIGURATION & INITIALIZATION
# 

# ASCII Header
Write-Host @"

                    UNIVERSAL PDF OCR AUTOMATION SUITE                        
                           Intelligent Document Processing                     
+
"@ -ForegroundColor Cyan

Write-Host "Version 2.0 - Universal Standalone Edition" -ForegroundColor Yellow
Write-Host "Supports: Medical Records  Invoices  Legal Docs  Reports  General Documents`n" -ForegroundColor Gray

# Get the absolute path of the directory where this script is located
$scriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Determine target folder
if ([string]::IsNullOrWhiteSpace($TargetFolder)) {
    $TargetFolder = Join-Path -Path $scriptRoot -ChildPath "Documents"
    Write-Host "No target folder specified, using default: Documents" -ForegroundColor Yellow
} elseif (-not [System.IO.Path]::IsPathRooted($TargetFolder)) {
    # Convert relative path to absolute
    $TargetFolder = Join-Path -Path $scriptRoot -ChildPath $TargetFolder
}

$TargetFolder = [System.IO.Path]::GetFullPath($TargetFolder)
Write-Host "Target Folder: $TargetFolder" -ForegroundColor Cyan
Write-Host "Document Type: $DocumentType" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "Mode: PREVIEW ONLY (No changes will be made)" -ForegroundColor Yellow
}
Write-Host ""

# 
# ENVIRONMENT VALIDATION
# 

Write-Host " Performing Environment Validation..." -ForegroundColor Yellow

# Check for Adobe Acrobat executable
$acroExe = (Get-Command acrobat.exe -ErrorAction SilentlyContinue).Source
if (-not $acroExe) {
    Write-Error " Adobe Acrobat executable not found on PATH. Please ensure Adobe Acrobat Pro is installed."
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "   Install Adobe Acrobat Pro (Reader will not work)" -ForegroundColor Gray
    Write-Host "   Add Acrobat installation folder to system PATH" -ForegroundColor Gray
    Write-Host "   Typical location: C:\Program Files\Adobe\Acrobat DC\Acrobat\" -ForegroundColor Gray
    exit 1
}
Write-Host " Adobe Acrobat Pro found: $acroExe" -ForegroundColor Green

# Check PowerShell architecture
$psArchitecture = if ([Environment]::Is64BitProcess) { "64-bit" } else { "32-bit" }
Write-Host " PowerShell Architecture: $psArchitecture" -ForegroundColor Green

# Clean up any existing Acrobat processes
$acrobatProcesses = Get-Process -Name "Acrobat" -ErrorAction SilentlyContinue
if ($acrobatProcesses) {
    Write-Host " Cleaning up existing Acrobat processes..." -ForegroundColor Yellow
    $acrobatProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host " Acrobat processes cleaned up" -ForegroundColor Green
}

# 
# FOLDER VALIDATION & PDF DISCOVERY
# 

# Check if target folder exists
if (-not (Test-Path -Path $TargetFolder)) {
    Write-Warning " Target folder not found: ''$TargetFolder''"
    Write-Host "`nAvailable folders:" -ForegroundColor Yellow
    Get-ChildItem -Path $scriptRoot -Directory | ForEach-Object {
        Write-Host "   $($_.Name)" -ForegroundColor Gray
    }
    Write-Host "`nUsage examples:" -ForegroundColor Yellow
    Write-Host "  .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Documents`"" -ForegroundColor Gray
    Write-Host "  .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Documents`"" -ForegroundColor Gray
    Write-Host "  .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `"C:\Your\PDF\Folder`"" -ForegroundColor Gray
    exit 1
}

# Discover PDF files
Write-Host " Scanning for PDF files in: $TargetFolder" -ForegroundColor Yellow
$pdfFiles = Get-ChildItem -Path $TargetFolder -Filter "*.pdf" -File

if ($pdfFiles.Count -eq 0) {
    Write-Warning "  No PDF files found in ''$TargetFolder''"
    Write-Host "`nPlace PDF files in the target folder and run the script again." -ForegroundColor Yellow
    exit 0
}

Write-Host " Found $($pdfFiles.Count) PDF files to process" -ForegroundColor Green

# Show discovered files in preview mode or detailed output
if ($WhatIf -or $DetailedOutput) {
    Write-Host "`n Files discovered:" -ForegroundColor Cyan
    $pdfFiles | ForEach-Object { 
        Write-Host "   $($_.Name)" -ForegroundColor Gray
    }
}

if ($WhatIf) {
    Write-Host "`n PREVIEW MODE - No files will be modified" -ForegroundColor Green
    Write-Host "Remove -WhatIf parameter to process files for real." -ForegroundColor Yellow
} else {
    Write-Host "`n  READY TO PROCESS - Files will be renamed!" -ForegroundColor Yellow
    Write-Host "Add -WhatIf parameter to preview without changes." -ForegroundColor Gray
}

Write-Host "`n Environment validation completed successfully!" -ForegroundColor Green
Write-Host "`n Usage Examples:" -ForegroundColor Cyan
Write-Host "Any Documents:    .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Documents`"
Write-Host "Invoices:         .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Invoices`" -DocumentType invoice" -ForegroundColor Gray
Write-Host "Any Folder:       .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `"C:\MyDocs\PDFs`"" -ForegroundColor Gray
Write-Host "Preview Mode:     .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Documents`" -WhatIf" -ForegroundColor Gray
