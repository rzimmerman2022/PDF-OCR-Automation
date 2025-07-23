#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete OCR and AI Renaming workflow for Estate Research Project - SOP v2.1
    
.DESCRIPTION
    This script implements the full SOP v2.1 naming convention with:
    - Support for all file types (documents, images, audio, video, data)
    - OCR processing for scanned PDFs
    - Tie-breaker rule for duplicate filenames
    - Security classification and checksum generation
    - Compilation file detection
    - Full validation and compliance checking
#>

param(
    [string]$TargetFolder = "C:\Projects\Estate Research Project",
    [switch]$TestMode,      # Process only first 5 files for testing
    [switch]$ValidateOnly,  # Only validate existing filenames
    [string[]]$FileTypes = @("*.pdf", "*.jpg", "*.png", "*.mp4", "*.wav", "*.xlsx", "*.csv", "*.docx")
)

Write-Host "`n" + "="*80 -ForegroundColor Cyan
Write-Host "ESTATE RESEARCH PROJECT - FILE PROCESSING SYSTEM" -ForegroundColor Cyan
Write-Host "Implementing SOP v2.1 - Complete Naming Convention" -ForegroundColor Yellow
Write-Host "="*80 -ForegroundColor Cyan

# Load configuration
$scriptPath = $PSScriptRoot
$logPath = Join-Path $scriptPath "logs"
if (!(Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
}

# Function to check if file needs OCR (for PDFs only)
function Test-PDFNeedsOCR {
    param([string]$FilePath)
    
    $checkCmd = @"
import PyPDF2
try:
    with open(r'$FilePath', 'rb') as f:
        reader = PyPDF2.PdfReader(f)
        text = ''
        for i in range(min(3, len(reader.pages))):
            text += reader.pages[i].extract_text()
        print('HAS_TEXT' if len(text.strip()) > 50 else 'NEEDS_OCR')
except:
    print('NEEDS_OCR')
"@
    
    $result = & python -c $checkCmd 2>$null
    return $result -eq 'NEEDS_OCR'
}

# Function to perform OCR on PDF
function Invoke-PDFOCR {
    param([string]$FilePath)
    
    Write-Host "  [OCR] Processing: $(Split-Path -Leaf $FilePath)" -ForegroundColor Yellow
    
    $tempOutput = [System.IO.Path]::ChangeExtension($FilePath, ".OCR_TEMP.pdf")
    
    # Try adobe_style_ocr.py first (best quality)
    $ocrResult = & python "$scriptPath\adobe_style_ocr.py" $FilePath $tempOutput 2>&1
    
    if (Test-Path $tempOutput) {
        # Replace original with OCR'd version
        Remove-Item $FilePath -Force
        Rename-Item $tempOutput $FilePath
        Write-Host "    [SUCCESS] PDF is now searchable" -ForegroundColor Green
        return $true
    } else {
        Write-Host "    [ERROR] OCR failed" -ForegroundColor Red
        return $false
    }
}

# Function to validate filename against SOP v2.1 pattern
function Test-FileNameCompliance {
    param([string]$FileName)
    
    $pattern = '^([0-9]{8})_([A-Za-z0-9_]+)_([A-Za-z]+)_([A-Za-z]+)_([A-Za-z]+|NA)_' +
               '(LEG|FIN|ADM|TAX|INS|REI)_([A-Za-z]+)_([A-Za-z]+)_' +
               '([DSFAR][0-9]+(_OCR|_BK|_RED)?)_([PICSR])_' +
               '([A-Za-z0-9_]+)(-[0-9]{2})?' +
               '\.(pdf|docx|xlsx|jpg|png|mp4|wav|csv)$'
    
    return $FileName -match $pattern
}

# Step 1: Validation Mode
if ($ValidateOnly) {
    Write-Host "`n[VALIDATION MODE] Checking filename compliance..." -ForegroundColor Cyan
    
    $files = Get-ChildItem -Path $TargetFolder -File -Include $FileTypes -Recurse | 
        Where-Object { $_.DirectoryName -notlike "*_backup*" }
    
    $compliant = 0
    $nonCompliant = 0
    
    foreach ($file in $files) {
        if (Test-FileNameCompliance -FileName $file.Name) {
            Write-Host "  [VALID] $($file.Name)" -ForegroundColor Green
            $compliant++
        } else {
            Write-Host "  [INVALID] $($file.Name)" -ForegroundColor Red
            $nonCompliant++
        }
    }
    
    Write-Host "`nValidation Summary:" -ForegroundColor Cyan
    Write-Host "  Compliant: $compliant files" -ForegroundColor Green
    Write-Host "  Non-compliant: $nonCompliant files" -ForegroundColor $(if ($nonCompliant -gt 0) { "Red" } else { "Gray" })
    Write-Host "  Compliance Rate: $([math]::Round($compliant / ($compliant + $nonCompliant) * 100, 2))%" -ForegroundColor Yellow
    
    exit
}

# Step 2: Get all files to process
Write-Host "`n[STEP 1] Scanning for files..." -ForegroundColor Cyan
$allFiles = Get-ChildItem -Path $TargetFolder -File -Include $FileTypes -Recurse | 
    Where-Object { $_.DirectoryName -notlike "*_backup*" } |
    Sort-Object Name

if ($TestMode) {
    $allFiles = $allFiles | Select-Object -First 5
    Write-Host "[TEST MODE] Processing only first 5 files" -ForegroundColor Yellow
}

Write-Host "[INFO] Found $($allFiles.Count) files to process" -ForegroundColor Green

# Group files by type
$filesByType = $allFiles | Group-Object Extension
Write-Host "[INFO] File types found:" -ForegroundColor Gray
foreach ($group in $filesByType) {
    Write-Host "  - $($group.Name): $($group.Count) files" -ForegroundColor Gray
}

# Step 3: OCR Processing for PDFs
Write-Host "`n[STEP 2] Checking PDFs for OCR requirements..." -ForegroundColor Cyan
$pdfFiles = $allFiles | Where-Object { $_.Extension -eq '.pdf' }
$ocrProcessed = 0

foreach ($pdf in $pdfFiles) {
    if (Test-PDFNeedsOCR -FilePath $pdf.FullName) {
        if (Invoke-PDFOCR -FilePath $pdf.FullName) {
            $ocrProcessed++
        }
    }
}

if ($ocrProcessed -gt 0) {
    Write-Host "[INFO] OCR completed on $ocrProcessed PDFs" -ForegroundColor Green
} else {
    Write-Host "[INFO] No PDFs required OCR processing" -ForegroundColor Gray
}

# Step 4: AI Renaming with SOP v2.1
Write-Host "`n[STEP 3] Running AI analysis and renaming..." -ForegroundColor Cyan
Write-Host "[INFO] Using Estate Research SOP v2.1 naming convention" -ForegroundColor Yellow

$renameResults = @()
$checksumFiles = @()

foreach ($file in $allFiles) {
    Write-Host "`n  Analyzing: $($file.Name)" -ForegroundColor Yellow
    Write-Host "    Type: $($file.Extension) file" -ForegroundColor Gray
    
    # Run Estate Research renamer v2
    $output = & python "$scriptPath\estate_research_renamer_v2.py" $file.FullName 2>&1
    
    # Parse JSON result
    $jsonLine = $output | Where-Object { $_ -match "^RESULT_JSON:" }
    if ($jsonLine) {
        $jsonData = ($jsonLine -replace "^RESULT_JSON:\s*", "") | ConvertFrom-Json
        $renameResults += $jsonData
        
        if ($jsonData.status -eq "renamed") {
            Write-Host "    [RENAMED] -> $($jsonData.new_name)" -ForegroundColor Green
            
            # Show key components
            if ($jsonData.analysis) {
                $a = $jsonData.analysis
                Write-Host "    Components:" -ForegroundColor Gray
                Write-Host "      Date: $($a.date)" -ForegroundColor DarkGray
                Write-Host "      Matter: $($a.matter_id)" -ForegroundColor DarkGray
                Write-Host "      Person: $($a.last_name), $($a.first_name) $($a.middle_name)" -ForegroundColor DarkGray
                Write-Host "      Dept: $($a.dept_code) | Type: $($a.doc_type)_$($a.subtype)" -ForegroundColor DarkGray
                Write-Host "      Lifecycle: $($a.lifecycle)$(if($a.derivative_code){$a.derivative_code})" -ForegroundColor DarkGray
                Write-Host "      Security: $($a.security_tag)" -ForegroundColor DarkGray
                
                # Highlight special cases
                if ($a.is_compilation -eq "true") {
                    Write-Host "      [COMPILATION] Contents: $($a.compilation_contents)" -ForegroundColor Magenta
                }
                if ($jsonData.new_name -match '-\d{2}\.') {
                    Write-Host "      [TIE-BREAKER] Duplicate resolved with suffix" -ForegroundColor Cyan
                }
            }
            
            # Track files needing checksums
            if ($jsonData.checksum) {
                $checksumFiles += @{
                    Name = $jsonData.new_name
                    Checksum = $jsonData.checksum
                    Security = $jsonData.analysis.security_tag
                }
            }
        }
        elseif ($jsonData.status -eq "skip") {
            Write-Host "    [SKIP] Already properly named" -ForegroundColor Gray
        }
        elseif ($jsonData.status -eq "error") {
            Write-Host "    [ERROR] $($jsonData.error)" -ForegroundColor Red
        }
    }
}

# Step 5: Security and Compliance Report
Write-Host "`n[STEP 4] Security Classification Summary..." -ForegroundColor Cyan

$securityGroups = $renameResults | Where-Object { $_.analysis.security_tag } | 
    Group-Object { $_.analysis.security_tag }

foreach ($group in $securityGroups) {
    $tagInfo = switch ($group.Name) {
        'P' { @{ Name = "Public"; Color = "Green" } }
        'I' { @{ Name = "Internal"; Color = "Yellow" } }
        'C' { @{ Name = "Confidential"; Color = "Magenta" } }
        'S' { @{ Name = "Strictly Confidential"; Color = "Red" } }
        'R' { @{ Name = "Regulated"; Color = "DarkRed" } }
    }
    
    Write-Host "  $($tagInfo.Name) [$($group.Name)]: $($group.Count) files" -ForegroundColor $tagInfo.Color
}

if ($checksumFiles.Count -gt 0) {
    Write-Host "`n[INFO] Generated SHA-256 checksums for $($checksumFiles.Count) secure files" -ForegroundColor Yellow
    Write-Host "[INFO] Checksum files created with .sha256 extension" -ForegroundColor Gray
}

# Step 6: Summary Report
Write-Host "`n" + "="*80 -ForegroundColor Cyan
Write-Host "PROCESSING COMPLETE - SUMMARY REPORT" -ForegroundColor Cyan
Write-Host "="*80 -ForegroundColor Cyan

$summary = @{
    TotalProcessed = $allFiles.Count
    OCRPerformed = $ocrProcessed
    Renamed = ($renameResults | Where-Object { $_.status -eq "renamed" }).Count
    AlreadyNamed = ($renameResults | Where-Object { $_.status -eq "skip" }).Count
    Errors = ($renameResults | Where-Object { $_.status -eq "error" }).Count
    FileTypes = ($filesByType | ForEach-Object { "$($_.Count) $($_.Name)" }) -join ", "
    CompilationFiles = ($renameResults | Where-Object { $_.analysis.is_compilation -eq "true" }).Count
    CollisionsResolved = ($renameResults | Where-Object { $_.new_name -match '-\d{2}\.' }).Count
    EstimatedCost = [math]::Round($renameResults.Count * 0.0006, 4)
}

Write-Host "Total files processed: $($summary.TotalProcessed)"
Write-Host "File types: $($summary.FileTypes)"
Write-Host "OCR performed: $($summary.OCRPerformed) PDFs" -ForegroundColor $(if ($summary.OCRPerformed -gt 0) { "Yellow" } else { "Gray" })
Write-Host "Successfully renamed: $($summary.Renamed) files" -ForegroundColor $(if ($summary.Renamed -gt 0) { "Green" } else { "Gray" })
Write-Host "Already properly named: $($summary.AlreadyNamed) files" -ForegroundColor Gray
Write-Host "Compilation files detected: $($summary.CompilationFiles)" -ForegroundColor $(if ($summary.CompilationFiles -gt 0) { "Magenta" } else { "Gray" })
Write-Host "Filename collisions resolved: $($summary.CollisionsResolved)" -ForegroundColor $(if ($summary.CollisionsResolved -gt 0) { "Cyan" } else { "Gray" })
Write-Host "Errors encountered: $($summary.Errors) files" -ForegroundColor $(if ($summary.Errors -gt 0) { "Red" } else { "Gray" })
Write-Host "Total AI cost: `$$($summary.EstimatedCost)" -ForegroundColor Yellow

# Step 7: Compliance Check
Write-Host "`n[COMPLIANCE] Checking all files against SOP v2.1..." -ForegroundColor Cyan
$finalFiles = Get-ChildItem -Path $TargetFolder -File -Include $FileTypes -Recurse | 
    Where-Object { $_.DirectoryName -notlike "*_backup*" }

$compliantCount = 0
$nonCompliantFiles = @()

foreach ($file in $finalFiles) {
    if (Test-FileNameCompliance -FileName $file.Name) {
        $compliantCount++
    } else {
        $nonCompliantFiles += $file.Name
    }
}

$complianceRate = [math]::Round($compliantCount / $finalFiles.Count * 100, 2)
Write-Host "Compliance Rate: $complianceRate%" -ForegroundColor $(if ($complianceRate -ge 98) { "Green" } elseif ($complianceRate -ge 90) { "Yellow" } else { "Red" })

if ($nonCompliantFiles.Count -gt 0 -and $nonCompliantFiles.Count -le 10) {
    Write-Host "`nNon-compliant files:" -ForegroundColor Red
    $nonCompliantFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

# Step 8: Save detailed log
$detailedLog = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    SOPVersion = "2.1"
    Summary = $summary
    ComplianceRate = $complianceRate
    SecurityClassification = $securityGroups | ForEach-Object { @{ Tag = $_.Name; Count = $_.Count } }
    ChecksumFiles = $checksumFiles
    ProcessingResults = $renameResults
}

$logFile = Join-Path $logPath "estate_processing_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$detailedLog | ConvertTo-Json -Depth 10 | Set-Content $logFile
Write-Host "`n[LOG] Detailed log saved to: $logFile" -ForegroundColor Gray

Write-Host "`n[INFO] Estate Research Project SOP v2.1 Implementation Complete" -ForegroundColor Green
Write-Host "[INFO] All files processed according to standard operating procedures" -ForegroundColor Green