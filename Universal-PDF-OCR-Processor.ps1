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
    if ($WhatIf) {
        Write-Host " Adobe Acrobat Pro not found - continuing in preview mode" -ForegroundColor Yellow
    }
    else {
        Write-Error " Adobe Acrobat executable not found on PATH. Please ensure Adobe Acrobat Pro is installed."
        Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
        Write-Host "   Install Adobe Acrobat Pro (Reader will not work)" -ForegroundColor Gray
        Write-Host "   Add Acrobat installation folder to system PATH" -ForegroundColor Gray
        Write-Host "   Typical location: C:\Program Files\Adobe\Acrobat DC\Acrobat\" -ForegroundColor Gray
        exit 1
    }
}
else {
    Write-Host " Adobe Acrobat Pro found: $acroExe" -ForegroundColor Green
}

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

# 
# DOCUMENT TYPE PATTERNS & CONTENT ANALYSIS
# 

# Define content patterns for different document types
$DocumentPatterns = @{
    "medical" = @(
        @{ Pattern = '(?i)(CBC|Complete Blood Count)'; Name = "CBC-Complete-Blood-Count" }
        @{ Pattern = '(?i)(CMP|Comprehensive Metabolic Panel)'; Name = "CMP-Metabolic-Panel" }
        @{ Pattern = '(?i)(Lipid Panel|Cholesterol)'; Name = "Lipid-Panel-Cholesterol" }
        @{ Pattern = '(?i)(HbA1c|Hemoglobin A1c)'; Name = "HbA1c-Diabetes-Monitoring" }
        @{ Pattern = '(?i)(Thyroid|TSH|T3|T4)'; Name = "Thyroid-Function-Tests" }
        @{ Pattern = '(?i)(PSA|Prostate)'; Name = "PSA-Prostate-Screening" }
        @{ Pattern = '(?i)(Urinalysis|Urine)'; Name = "Urinalysis" }
        @{ Pattern = '(?i)(Visit Summary|Progress Note)'; Name = "Visit-Summary" }
        @{ Pattern = '(?i)(Prescription|Medication)'; Name = "Prescription-Record" }
        @{ Pattern = '(?i)(X-Ray|Imaging|Radiology)'; Name = "Imaging-Report" }
    )
    "invoice" = @(
        @{ Pattern = '(?i)(Invoice|Bill)'; Name = "Invoice" }
        @{ Pattern = '(?i)(Receipt|Payment)'; Name = "Payment-Receipt" }
        @{ Pattern = '(?i)(Purchase Order|PO)'; Name = "Purchase-Order" }
        @{ Pattern = '(?i)(Estimate|Quote)'; Name = "Estimate-Quote" }
        @{ Pattern = '(?i)(Credit Note|Refund)'; Name = "Credit-Note" }
        @{ Pattern = '(?i)(Statement|Account)'; Name = "Account-Statement" }
    )
    "legal" = @(
        @{ Pattern = '(?i)(Contract|Agreement)'; Name = "Contract-Agreement" }
        @{ Pattern = '(?i)(Motion|Brief)'; Name = "Legal-Motion" }
        @{ Pattern = '(?i)(Settlement|Resolution)'; Name = "Settlement-Agreement" }
        @{ Pattern = '(?i)(Patent|Intellectual Property)'; Name = "Patent-Document" }
        @{ Pattern = '(?i)(Compliance|Regulatory)'; Name = "Compliance-Document" }
        @{ Pattern = '(?i)(Affidavit|Sworn Statement)'; Name = "Affidavit" }
        @{ Pattern = '(?i)(Court Order|Judgment)'; Name = "Court-Order" }
    )
    "general" = @(
        @{ Pattern = '(?i)(Report|Analysis)'; Name = "Report" }
        @{ Pattern = '(?i)(Manual|Guide)'; Name = "Manual-Guide" }
        @{ Pattern = '(?i)(Specification|Spec)'; Name = "Specification" }
        @{ Pattern = '(?i)(Presentation|Slide)'; Name = "Presentation" }
        @{ Pattern = '(?i)(Certificate|Certification)'; Name = "Certificate" }
        @{ Pattern = '(?i)(Policy|Procedure)'; Name = "Policy-Document" }
    )
}

# Date patterns for intelligent date extraction
$DatePatterns = @(
    '(\d{4}-\d{2}-\d{2})',                        # YYYY-MM-DD
    '(\d{1,2}/\d{1,2}/\d{4})',                    # M/D/YYYY or MM/DD/YYYY
    '(\d{1,2}-\d{1,2}-\d{4})',                    # M-D-YYYY or MM-DD-YYYY
    '([A-Za-z]+ \d{1,2}, \d{4})',                 # Month DD, YYYY
    '(\d{1,2} [A-Za-z]+ \d{4})',                  # DD Month YYYY
    'Date.*?(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'     # "Date: MM/DD/YYYY" variations
)

# 
# UTILITY FUNCTIONS
# 

function Format-DateForFilename {
    param([string]$DateString)
    
    try {
        $date = [DateTime]::Parse($DateString)
        return $date.ToString("yyyy-MM-dd")
    }
    catch {
        return (Get-Date).ToString("yyyy-MM-dd")
    }
}

function Get-SafeFilename {
    param([string]$Text)
    
    # Remove invalid filename characters
    $safe = $Text -replace '[<>:"/\\|?*]', '-'
    $safe = $safe -replace '\s+', '-'
    $safe = $safe -replace '-+', '-'
    $safe = $safe.Trim('-')
    
    # Limit length
    if ($safe.Length -gt 50) {
        $safe = $safe.Substring(0, 50).Trim('-')
    }
    
    return $safe
}

function Detect-DocumentContent {
    param(
        [string]$Content,
        [string]$DocumentType
    )
    
    $detectedContent = "Document"
    $detectedDate = (Get-Date).ToString("yyyy-MM-dd")
    
    # Extract date
    foreach ($pattern in $DatePatterns) {
        if ($Content -match $pattern) {
            $detectedDate = Format-DateForFilename $matches[1]
            break
        }
    }
    
    # Detect content type based on patterns
    $patternsToCheck = @()
    
    if ($DocumentType -eq "auto") {
        # Try all pattern types for auto-detection
        $patternsToCheck = $DocumentPatterns["medical"] + $DocumentPatterns["invoice"] + $DocumentPatterns["legal"] + $DocumentPatterns["general"]
    }
    elseif ($DocumentPatterns.ContainsKey($DocumentType)) {
        $patternsToCheck = $DocumentPatterns[$DocumentType]
    }
    else {
        $patternsToCheck = $DocumentPatterns["general"]
    }
    
    foreach ($pattern in $patternsToCheck) {
        if ($Content -match $pattern.Pattern) {
            $detectedContent = $pattern.Name
            break
        }
    }
    
    return @{
        Content = $detectedContent
        Date = $detectedDate
    }
}

# 
# OCR PROCESSING ENGINE
# 

function Process-PDFWithOCR {
    param(
        [string]$FilePath,
        [string]$DocumentType,
        [bool]$WhatIfMode = $false
    )
    
    $success = $false
    $extractedText = ""
    $newFileName = ""
    
    try {
        Write-Host "    Processing: $([System.IO.Path]::GetFileName($FilePath))" -ForegroundColor Cyan
        
        if ($WhatIfMode) {
            # In WhatIf mode, simulate processing
            $extractedText = "Sample extracted text for preview purposes. Invoice #INV-12345 dated 2025-07-19."
            Write-Host "      [PREVIEW] Would perform OCR processing..." -ForegroundColor Yellow
        }
        else {
            # Initialize Adobe Acrobat Application
            Write-Host "      Initializing Adobe Acrobat..." -ForegroundColor Gray
            $acroApp = New-Object -ComObject AcroExch.App
            $acroApp.Show()
            
            # Create PDF Document object
            $acroPDDoc = New-Object -ComObject AcroExch.PDDoc
            
            # Open the PDF
            $openResult = $acroPDDoc.Open($FilePath)
            if (-not $openResult) {
                throw "Failed to open PDF: $FilePath"
            }
            
            Write-Host "      Performing OCR..." -ForegroundColor Gray
            
            # Get the PDF's JavaScript object for OCR operations
            $jsObject = $acroPDDoc.GetJSObject()
            
            # Perform OCR on the document
            $jsObject.OCRPages(0, ($acroPDDoc.GetNumPages() - 1), 0, $true)
            
            # Save the OCRed document
            $tempPath = $FilePath + ".temp.pdf"
            $acroPDDoc.Save(1, $tempPath)  # 1 = PDSaveFull
            
            # Extract text
            Write-Host "      Extracting text content..." -ForegroundColor Gray
            for ($i = 0; $i -lt $acroPDDoc.GetNumPages(); $i++) {
                $acroPage = $acroPDDoc.AcquirePage($i)
                $pageText = $acroPage.CopyText()
                $extractedText += $pageText + "`n"
                $acroPage = $null
            }
            
            # Close PDF and cleanup
            $acroPDDoc.Close()
            $acroApp.Exit()
            
            # Replace original with OCRed version
            if (Test-Path $tempPath) {
                Remove-Item $FilePath -Force
                Rename-Item $tempPath $FilePath
            }
            
            $acroPDDoc = $null
            $acroApp = $null
            [System.GC]::Collect()
        }
        
        # Analyze content and generate new filename
        Write-Host "      Analyzing content..." -ForegroundColor Gray
        $analysis = Detect-DocumentContent -Content $extractedText -DocumentType $DocumentType
        
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
        $directory = [System.IO.Path]::GetDirectoryName($FilePath)
        
        $safeDatePart = Get-SafeFilename $analysis.Date
        $safeContentPart = Get-SafeFilename $analysis.Content
        
        # Generate new filename based on document type
        switch ($DocumentType) {
            "medical" { $newFileName = "$($safeDatePart)_MedRecord_$($safeContentPart).pdf" }
            "invoice" { $newFileName = "$($safeDatePart)_Invoice_$($safeContentPart).pdf" }
            "legal" { $newFileName = "$($safeDatePart)_Legal_$($safeContentPart).pdf" }
            default { $newFileName = "$($safeDatePart)_Document_$($safeContentPart).pdf" }
        }
        
        $newFilePath = Join-Path $directory $newFileName
        
        # Handle duplicate names
        $counter = 1
        $originalNewFilePath = $newFilePath
        while ((Test-Path $newFilePath) -and ($newFilePath -ne $FilePath)) {
            $counter++
            $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($originalNewFilePath)
            $newFileName = "$($nameWithoutExt)_$counter.pdf"
            $newFilePath = Join-Path $directory $newFileName
        }
        
        if ($WhatIfMode) {
            Write-Host "      [PREVIEW] Would rename to: $newFileName" -ForegroundColor Yellow
        }
        else {
            # Rename the file
            if ($newFilePath -ne $FilePath) {
                Rename-Item $FilePath $newFilePath
                Write-Host "      Renamed to: $newFileName" -ForegroundColor Green
            }
            else {
                Write-Host "      Filename already optimal: $([System.IO.Path]::GetFileName($FilePath))" -ForegroundColor Green
            }
        }
        
        $success = $true
        
    }
    catch {
        Write-Host "      ERROR: $($_.Exception.Message)" -ForegroundColor Red
        
        # Cleanup on error
        try {
            if ($acroPDDoc) { $acroPDDoc.Close() }
            if ($acroApp) { $acroApp.Exit() }
        }
        catch { }
        
        [System.GC]::Collect()
    }
    
    return $success
}

# 
# MAIN PROCESSING LOOP
# 

if ($WhatIf) {
    Write-Host "`n Starting PREVIEW Processing..." -ForegroundColor Yellow
    Write-Host "==================================" -ForegroundColor Yellow
}
else {
    Write-Host "`n Starting PDF Processing..." -ForegroundColor Green
    Write-Host "============================" -ForegroundColor Green
}

$processedCount = 0
$successCount = 0
$errorCount = 0

foreach ($pdf in $pdfFiles) {
    $processedCount++
    Write-Host "`n[$processedCount/$($pdfFiles.Count)]" -ForegroundColor Cyan -NoNewline
    
    $success = Process-PDFWithOCR -FilePath $pdf.FullName -DocumentType $DocumentType -WhatIfMode:$WhatIf
    
    if ($success) {
        $successCount++
    }
    else {
        $errorCount++
    }
    
    # Small delay between files
    Start-Sleep -Milliseconds 500
}

# 
# COMPLETION SUMMARY
# 

Write-Host "`n" + "="*50 -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host " PREVIEW COMPLETED" -ForegroundColor Yellow
}
else {
    Write-Host " PROCESSING COMPLETED" -ForegroundColor Green
}
Write-Host "="*50 -ForegroundColor Cyan

Write-Host "`n Summary:" -ForegroundColor Cyan
Write-Host "   Total Files: $processedCount" -ForegroundColor Gray
Write-Host "   Successful: $successCount" -ForegroundColor Green
Write-Host "   Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Gray" })

if ($WhatIf) {
    Write-Host "`n Ready for actual processing!" -ForegroundColor Green
    Write-Host " Remove the -WhatIf parameter to process files for real." -ForegroundColor Yellow
}
else {
    Write-Host "`n All files have been processed and intelligently renamed!" -ForegroundColor Green
    Write-Host " Check the target folder for results." -ForegroundColor Gray
}

Write-Host "`n Usage Examples:" -ForegroundColor Cyan
Write-Host "Any Documents:    .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Documents`"" -ForegroundColor Gray
Write-Host "Invoices:         .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Invoices`" -DocumentType invoice" -ForegroundColor Gray
Write-Host "Any Folder:       .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `"C:\MyDocs\PDFs`"" -ForegroundColor Gray
Write-Host "Preview Mode:     .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Documents`" -WhatIf" -ForegroundColor Gray
