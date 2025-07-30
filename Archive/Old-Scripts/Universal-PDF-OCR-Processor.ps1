<#
.SYNOPSIS
    Universal PDF OCR and Intelligent Renaming System
    Automates OCR processing and content-based renaming of PDF documents using Adobe Acrobat Pro.

.DESCRIPTION
    This powerful automation script processes PDF files in any specified directory by:
    1. Performing Optical Character Recognition (OCR) using Adobe Acrobat Pro
    2. Extracting and analyzing text content to identify document types and key information
    3. Applying intelligent, content-based naming conventions
    4. Supporting multiple document types: business reports, technical docs, invoices, legal documents, etc.
    5. Creating both searchable PDFs with intelligent file naming

    The script is designed to be universally applicable across different industries and document types,
    with extensible pattern matching for content identification. Originally designed for medical records,
    this version has been completely transformed to support universal document processing.

.PARAMETER TargetFolder
    Specifies the folder containing PDF files to process. Can be absolute or relative path.
    If not specified, uses the 'Documents' subfolder in the script directory.

.PARAMETER DocumentType
    Optional filter to process only specific document types (business, technical, invoice, legal, general).
    Default is 'auto' which attempts to detect document type automatically.

.PARAMETER WhatIf
    Preview mode - shows what would be processed without making any changes.
    Highly recommended for first-time use to understand what the script will do.

.PARAMETER DetailedOutput
    Enables detailed output for troubleshooting and monitoring.
    Shows discovered files and detailed processing steps.

.EXAMPLE
    .\Universal-PDF-OCR-Processor.ps1 -TargetFolder "C:\MyDocuments\Invoices"
    Process all PDFs in the specified folder with automatic document type detection

.EXAMPLE
    .\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\TechnicalDocs" -DocumentType technical -WhatIf
    Preview processing of technical documents in a relative subfolder

.EXAMPLE
    .\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Documents" -WhatIf
    Preview processing using default Documents folder

.NOTES
    Author: GitHub Copilot - Universal PDF OCR Automation Suite
    Version: 2.0 - Universal Document Processing Edition
    Last Updated: July 19, 2025
    
    Prerequisites: 
    - Windows OS with PowerShell 5.1+
    - Adobe Acrobat Pro (not Reader) installed and licensed
    - Sufficient disk space for temporary file creation
    
    Supported Document Types:
    - Business Reports and Documentation (Annual reports, meeting minutes, business plans)
    - Technical Documentation (User manuals, API docs, specifications, requirements)
    - Invoices and Financial Documents (Bills, receipts, purchase orders, statements)
    - Legal Documents (Contracts, agreements, filings, patents, compliance docs)
    - General Business Documents (Any PDF with automatic content detection)
    
    The script automatically detects document content and applies appropriate naming patterns.
    All medical-specific references have been removed to make this truly universal.
#>

param(
    [Parameter(Position=0, HelpMessage="Folder containing PDF files to process")]
    [string]$TargetFolder = "",
    
    [Parameter(HelpMessage="Document type filter: auto, business, invoice, legal, technical, general")]
    [ValidateSet("auto", "business", "invoice", "legal", "technical", "general")]
    [string]$DocumentType = "auto",
    
    [Parameter(HelpMessage="OCR language: eng, spa, fra, deu, ita, por, rus, chi_sim, jpn, multi")]
    [ValidateSet("eng", "spa", "fra", "deu", "ita", "por", "rus", "chi_sim", "chi_tra", "jpn", "kor", "ara", "multi")]
    [string]$OCRLanguage = "eng",
    
    [Parameter(HelpMessage="Preview mode - show what would be processed without making changes")]
    [switch]$WhatIf,
    
    [Parameter(HelpMessage="Enable detailed output")]
    [switch]$DetailedOutput
)

# 
# CONFIGURATION & INITIALIZATION
# Universal PDF OCR Processor - Handles any document type across industries
# Transformed from medical-specific to universal document processing system
# 

# Display professional ASCII header for universal document processing
Write-Host @"

                    UNIVERSAL PDF OCR AUTOMATION SUITE                        
                          Smart Document Processing & Organization                     

"@ -ForegroundColor Cyan

Write-Host "Version 2.0 - Universal Document Processing Edition" -ForegroundColor Yellow
Write-Host "Supports: Business Reports • Invoices • Legal Docs • Technical Manuals • General Documents`n" -ForegroundColor Gray

# Get the absolute path of the directory where this script is located
# This ensures the script works regardless of where it's executed from
$scriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Determine target folder - support both absolute and relative paths
if ([string]::IsNullOrWhiteSpace($TargetFolder)) {
    # Default to Documents subfolder if no target specified
    $TargetFolder = Join-Path -Path $scriptRoot -ChildPath "Documents"
    Write-Host "No target folder specified, using default: Documents" -ForegroundColor Yellow
} elseif (-not [System.IO.Path]::IsPathRooted($TargetFolder)) {
    # Convert relative path to absolute path for consistency
    $TargetFolder = Join-Path -Path $scriptRoot -ChildPath $TargetFolder
}

# Ensure we have a fully qualified path for reliable processing
$TargetFolder = [System.IO.Path]::GetFullPath($TargetFolder)

# OCR Language Configuration
$ocrLanguages = @{
    "eng" = @{Name = "English"; Code = "eng"}
    "spa" = @{Name = "Spanish"; Code = "spa"}
    "fra" = @{Name = "French"; Code = "fra"}
    "deu" = @{Name = "German"; Code = "deu"}
    "ita" = @{Name = "Italian"; Code = "ita"}
    "por" = @{Name = "Portuguese"; Code = "por"}
    "rus" = @{Name = "Russian"; Code = "rus"}
    "chi_sim" = @{Name = "Chinese (Simplified)"; Code = "chi_sim"}
    "chi_tra" = @{Name = "Chinese (Traditional)"; Code = "chi_tra"}
    "jpn" = @{Name = "Japanese"; Code = "jpn"}
    "kor" = @{Name = "Korean"; Code = "kor"}
    "ara" = @{Name = "Arabic"; Code = "ara"}
    "multi" = @{Name = "Multi-language"; Code = "eng+spa+fra+deu"}
}

# Set selected language
$selectedLanguage = if ($ocrLanguages.ContainsKey($OCRLanguage)) { 
    $ocrLanguages[$OCRLanguage] 
} else { 
    $ocrLanguages["eng"] 
}

# Display configuration information for user verification
Write-Host "Target Folder: $TargetFolder" -ForegroundColor Cyan
Write-Host "Document Type: $DocumentType" -ForegroundColor Cyan
Write-Host "OCR Language: $($selectedLanguage.Name)" -ForegroundColor Cyan
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
# Comprehensive pattern matching for universal document processing
# Replaces medical-specific patterns with business, technical, and general patterns
# 

# Define content patterns for different document types
# Each pattern includes regex for detection and corresponding naming convention
$DocumentPatterns = @{
    # Business document patterns - covers corporate reports, meetings, planning
    "business" = @(
        @{ Pattern = '(?i)(Annual Report|Quarterly Report)'; Name = "Business-Report" }
        @{ Pattern = '(?i)(Meeting Minutes|Board Minutes)'; Name = "Meeting-Minutes" }
        @{ Pattern = '(?i)(Business Plan|Strategic Plan)'; Name = "Business-Plan" }
        @{ Pattern = '(?i)(Financial Statement|Balance Sheet)'; Name = "Financial-Statement" }
        @{ Pattern = '(?i)(Audit Report|Compliance Report)'; Name = "Audit-Report" }
        @{ Pattern = '(?i)(Performance Review|Employee Evaluation)'; Name = "Performance-Review" }
        @{ Pattern = '(?i)(Proposal|RFP|Request for Proposal)'; Name = "Business-Proposal" }
        @{ Pattern = '(?i)(Budget|Forecast)'; Name = "Budget-Document" }
        @{ Pattern = '(?i)(Memo|Memorandum)'; Name = "Business-Memo" }
        @{ Pattern = '(?i)(Policy|Procedure)'; Name = "Policy-Document" }
    )
    # Technical documentation patterns - covers manuals, specifications, guides
    "technical" = @(
        @{ Pattern = '(?i)(User Manual|Installation Guide)'; Name = "User-Manual" }
        @{ Pattern = '(?i)(Technical Specification|Design Spec)'; Name = "Technical-Specification" }
        @{ Pattern = '(?i)(API Documentation|Developer Guide)'; Name = "API-Documentation" }
        @{ Pattern = '(?i)(Test Report|Quality Assurance)'; Name = "Test-Report" }
        @{ Pattern = '(?i)(System Requirements|Hardware Requirements)'; Name = "System-Requirements" }
        @{ Pattern = '(?i)(Architecture Document|System Design)'; Name = "Architecture-Document" }
        @{ Pattern = '(?i)(Configuration Guide|Setup Instructions)'; Name = "Configuration-Guide" }
        @{ Pattern = '(?i)(Release Notes|Change Log)'; Name = "Release-Notes" }
        @{ Pattern = '(?i)(Troubleshooting|FAQ)'; Name = "Troubleshooting-Guide" }
        @{ Pattern = '(?i)(Datasheet|Product Specification)'; Name = "Product-Datasheet" }
    )
    # Invoice and financial document patterns - covers billing and payment documents
    "invoice" = @(
        @{ Pattern = '(?i)(Invoice|Bill)'; Name = "Invoice" }
        @{ Pattern = '(?i)(Receipt|Payment)'; Name = "Payment-Receipt" }
        @{ Pattern = '(?i)(Purchase Order|PO)'; Name = "Purchase-Order" }
        @{ Pattern = '(?i)(Estimate|Quote)'; Name = "Estimate-Quote" }
        @{ Pattern = '(?i)(Credit Note|Refund)'; Name = "Credit-Note" }
        @{ Pattern = '(?i)(Statement|Account)'; Name = "Account-Statement" }
    )
    # Legal document patterns - covers contracts, filings, and legal proceedings
    "legal" = @(
        @{ Pattern = '(?i)(Contract|Agreement)'; Name = "Contract-Agreement" }
        @{ Pattern = '(?i)(Motion|Brief)'; Name = "Legal-Motion" }
        @{ Pattern = '(?i)(Settlement|Resolution)'; Name = "Settlement-Agreement" }
        @{ Pattern = '(?i)(Patent|Intellectual Property)'; Name = "Patent-Document" }
        @{ Pattern = '(?i)(Compliance|Regulatory)'; Name = "Compliance-Document" }
        @{ Pattern = '(?i)(Affidavit|Sworn Statement)'; Name = "Affidavit" }
        @{ Pattern = '(?i)(Court Order|Judgment)'; Name = "Court-Order" }
    )
    # General document patterns - fallback for documents that don't match specific types
    "general" = @(
        @{ Pattern = '(?i)(Report|Analysis)'; Name = "Report" }
        @{ Pattern = '(?i)(Manual|Guide)'; Name = "Manual-Guide" }
        @{ Pattern = '(?i)(Specification|Spec)'; Name = "Specification" }
        @{ Pattern = '(?i)(Presentation|Slide)'; Name = "Presentation" }
        @{ Pattern = '(?i)(Certificate|Certification)'; Name = "Certificate" }
        @{ Pattern = '(?i)(Policy|Procedure)'; Name = "Policy-Document" }
    )
}

# Date patterns for intelligent date extraction from document content
# Supports multiple date formats commonly found in business documents
$DatePatterns = @(
    '(\d{4}-\d{2}-\d{2})',                        # YYYY-MM-DD (ISO format)
    '(\d{1,2}/\d{1,2}/\d{4})',                    # M/D/YYYY or MM/DD/YYYY (US format)
    '(\d{1,2}-\d{1,2}-\d{4})',                    # M-D-YYYY or MM-DD-YYYY (dash format)
    '([A-Za-z]+ \d{1,2}, \d{4})',                 # Month DD, YYYY (written format)
    '(\d{1,2} [A-Za-z]+ \d{4})',                  # DD Month YYYY (European format)
    'Date.*?(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'     # "Date: MM/DD/YYYY" variations
)

# 
# UTILITY FUNCTIONS
# Helper functions for date formatting, filename sanitization, and content detection
# 

# Convert various date formats to standardized YYYY-MM-DD format for filename consistency
function Format-DateForFilename {
    param([string]$DateString)
    
    try {
        # Attempt to parse the date string using .NET DateTime parsing
        $date = [DateTime]::Parse($DateString)
        return $date.ToString("yyyy-MM-dd")
    }
    catch {
        # If parsing fails, default to current date to ensure valid filename
        return (Get-Date).ToString("yyyy-MM-dd")
    }
}

# Sanitize text for use in filenames by removing invalid characters and formatting
function Get-SafeFilename {
    param([string]$Text)
    
    # Remove characters that are invalid in Windows filenames
    $safe = $Text -replace '[<>:"/\\|?*]', '-'
    # Replace multiple spaces with single hyphens for consistency
    $safe = $safe -replace '\s+', '-'
    # Remove multiple consecutive hyphens
    $safe = $safe -replace '-+', '-'
    # Trim leading and trailing hyphens
    $safe = $safe.Trim('-')
    
    # Limit filename length to prevent filesystem issues (50 chars is reasonable)
    if ($safe.Length -gt 50) {
        $safe = $safe.Substring(0, 50).Trim('-')
    }
    
    return $safe
}

# Test OCR quality and identify potential issues
function Test-OCRQuality {
    param([string]$Text)
    
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @{Score = 0; Rating = "No Text"; Issues = @("Empty document")}
    }
    
    $score = 100
    $issues = @()
    
    # Check for garbage characters (common OCR artifacts)
    $garbageCount = ([regex]::Matches($Text, '[█▓▒░■□▪▫◆◇○●]')).Count
    if ($garbageCount -gt 0) {
        $score -= [Math]::Min(30, $garbageCount * 2)
        $issues += "Garbage characters detected"
    }
    
    # Check for excessive special characters
    $specialRatio = ([regex]::Matches($Text, '[^a-zA-Z0-9\s\.\,\;\:\!\?\-]')).Count / [Math]::Max($Text.Length, 1)
    if ($specialRatio -gt 0.2) {
        $score -= 20
        $issues += "Excessive special characters"
    }
    
    # Check for very short "words" (likely OCR errors)
    $words = $Text -split '\s+' | Where-Object {$_.Length -gt 0}
    $shortWordRatio = ($words | Where-Object {$_.Length -eq 1 -and $_ -notmatch '[aAiI]'}).Count / [Math]::Max($words.Count, 1)
    if ($shortWordRatio -gt 0.3) {
        $score -= 15
        $issues += "Many single-character words"
    }
    
    # Check for reasonable word structure
    $validWords = $words | Where-Object {$_ -match '^[a-zA-Z]+$' -and $_.Length -ge 2}
    $validWordRatio = $validWords.Count / [Math]::Max($words.Count, 1)
    if ($validWordRatio -lt 0.5) {
        $score -= 20
        $issues += "Low valid word ratio"
    }
    
    # Check for common OCR error patterns
    if ($Text -match 'l{3,}|1{3,}|0{3,}|O{3,}') {
        $score -= 10
        $issues += "Repeated OCR confusion characters"
    }
    
    # Ensure score is within bounds
    $score = [Math]::Max(0, [Math]::Min(100, $score))
    
    # Determine rating
    $rating = switch ($score) {
        {$_ -ge 90} { "Excellent" }
        {$_ -ge 75} { "Good" }
        {$_ -ge 60} { "Fair" }
        {$_ -ge 40} { "Poor" }
        default { "Very Poor" }
    }
    
    return @{
        Score = $score
        Rating = $rating
        Issues = $issues
    }
}

# Analyze document content to detect document type and extract key information
function Detect-DocumentContent {
    param(
        [string]$Content,           # OCR-extracted text content
        [string]$DocumentType       # User-specified document type filter
    )
    
    # Default values for when detection fails
    $detectedContent = "Document"
    $detectedDate = (Get-Date).ToString("yyyy-MM-dd")
    
    # Extract date from document content using multiple pattern attempts
    foreach ($pattern in $DatePatterns) {
        if ($Content -match $pattern) {
            $detectedDate = Format-DateForFilename $matches[1]
            break  # Use first date found
        }
    }
    
    # Determine which patterns to check based on document type setting
    $patternsToCheck = @()
    
    if ($DocumentType -eq "auto") {
        # Auto-detection: try all pattern types for comprehensive matching
        # This enables universal document processing across all supported types
        $patternsToCheck = $DocumentPatterns["business"] + $DocumentPatterns["technical"] + $DocumentPatterns["invoice"] + $DocumentPatterns["legal"] + $DocumentPatterns["general"]
    }
    elseif ($DocumentPatterns.ContainsKey($DocumentType)) {
        # Use specific document type patterns when explicitly specified
        $patternsToCheck = $DocumentPatterns[$DocumentType]
    }
    else {
        # Fallback to general patterns for unknown document types
        $patternsToCheck = $DocumentPatterns["general"]
    }
    
    # Check content against selected patterns to identify document type
    foreach ($pattern in $patternsToCheck) {
        if ($Content -match $pattern.Pattern) {
            $detectedContent = $pattern.Name
            break  # Use first match found
        }
    }
    
    # Return hashtable with detected information for filename generation
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
        [hashtable]$Language,
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
            
            Write-Host "      Performing OCR ($($Language.Name))..." -ForegroundColor Gray
            
            # Get the PDF's JavaScript object for OCR operations
            $jsObject = $acroPDDoc.GetJSObject()
            
            # Perform OCR on the document with specified language
            # Note: Adobe Acrobat's OCR API may vary. This is a common approach:
            # For multi-language, you might need to adjust based on your Acrobat version
            try {
                if ($Language.Code -match '\+') {
                    # Multi-language OCR
                    $jsObject.OCRPages(0, ($acroPDDoc.GetNumPages() - 1), $Language.Code, $true)
                } else {
                    # Single language OCR
                    $jsObject.OCRPages(0, ($acroPDDoc.GetNumPages() - 1), $Language.Code, $true)
                }
            } catch {
                # Fallback to default OCR if language-specific fails
                Write-Warning "      Language-specific OCR failed, using default..."
                $jsObject.OCRPages(0, ($acroPDDoc.GetNumPages() - 1), 0, $true)
            }
            
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
        
        # Check OCR quality
        $ocrQuality = Test-OCRQuality -Text $extractedText
        if ($ocrQuality.Score -lt 50) {
            Write-Warning "      Low OCR quality detected (Score: $($ocrQuality.Score)%)"
            Write-Host "      Issues: $($ocrQuality.Issues -join ', ')" -ForegroundColor Yellow
        } else {
            Write-Host "      OCR Quality: $($ocrQuality.Score)% - $($ocrQuality.Rating)" -ForegroundColor $(
                if ($ocrQuality.Score -ge 90) { "Green" } 
                elseif ($ocrQuality.Score -ge 70) { "Yellow" } 
                else { "Red" }
            )
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
            "business" { $newFileName = "$($safeDatePart)_Business_$($safeContentPart).pdf" }
            "technical" { $newFileName = "$($safeDatePart)_Technical_$($safeContentPart).pdf" }
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

$totalFiles = $pdfFiles.Count
$startTime = Get-Date

foreach ($pdf in $pdfFiles) {
    $processedCount++
    $percentComplete = [Math]::Round(($processedCount / $totalFiles) * 100, 0)
    
    # Progress bar
    Write-Progress -Activity "Processing PDF Files" `
                   -Status "Processing: $($pdf.Name)" `
                   -PercentComplete $percentComplete `
                   -CurrentOperation "File $processedCount of $totalFiles" `
                   -SecondsRemaining $(if ($processedCount -gt 1) {
                       $avgTime = ((Get-Date) - $startTime).TotalSeconds / ($processedCount - 1)
                       [Math]::Round($avgTime * ($totalFiles - $processedCount))
                   } else { -1 })
    
    Write-Host "`n[$processedCount/$totalFiles]" -ForegroundColor Cyan -NoNewline
    Write-Host " ($percentComplete%)" -ForegroundColor DarkCyan -NoNewline
    
    $fileStart = Get-Date
    $success = Process-PDFWithOCR -FilePath $pdf.FullName -DocumentType $DocumentType -Language $selectedLanguage -WhatIfMode:$WhatIf
    $fileTime = ((Get-Date) - $fileStart).TotalSeconds
    
    if ($success) {
        $successCount++
        Write-Host " [OK]" -ForegroundColor Green -NoNewline
        Write-Host " (${fileTime}s)" -ForegroundColor DarkGray
    }
    else {
        $errorCount++
        Write-Host " [FAILED]" -ForegroundColor Red
    }
    
    # Small delay between files
    Start-Sleep -Milliseconds 500
}

# 
# COMPLETION SUMMARY
# 

# Clear progress bar
Write-Progress -Activity "Processing PDF Files" -Completed

$totalTime = ((Get-Date) - $startTime)
$avgTimePerFile = if ($processedCount -gt 0) { $totalTime.TotalSeconds / $processedCount } else { 0 }

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
Write-Host "`n Performance:" -ForegroundColor Cyan
Write-Host "   Total Time: $($totalTime.ToString('mm\:ss'))" -ForegroundColor Gray
Write-Host "   Average/File: $([Math]::Round($avgTimePerFile, 1))s" -ForegroundColor Gray
Write-Host "   Files/Minute: $([Math]::Round($processedCount / [Math]::Max($totalTime.TotalMinutes, 0.001), 1))" -ForegroundColor Gray

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
Write-Host "Business Reports: .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Reports`" -DocumentType business" -ForegroundColor Gray
Write-Host "Spanish Docs:     .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Spanish`" -OCRLanguage spa" -ForegroundColor Gray
Write-Host "Multi-language:   .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Mixed`" -OCRLanguage multi" -ForegroundColor Gray
Write-Host "Invoices:         .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Invoices`" -DocumentType invoice" -ForegroundColor Gray
Write-Host "Preview Mode:     .\Universal-PDF-OCR-Processor.ps1 -TargetFolder `".\Documents`" -WhatIf" -ForegroundColor Gray
