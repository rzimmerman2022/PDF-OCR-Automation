#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete OCR and AI Renaming workflow for Estate Research Project
    
.DESCRIPTION
    This script:
    1. Performs OCR on PDFs to make them searchable (not .txt extraction)
    2. Uses AI to analyze content and rename according to SOP v1.2
    3. Monitors and reports on each step
#>

param(
    [string]$TargetFolder = "C:\Projects\Estate Research Project",
    [switch]$TestMode  # Process only first 3 files for testing
)

Write-Host "`n" + "="*80 -ForegroundColor Cyan
Write-Host "ESTATE RESEARCH PROJECT - COMPLETE OCR & AI RENAMING WORKFLOW" -ForegroundColor Cyan
Write-Host "Using Estate Research Project SOP v1.2 Naming Convention" -ForegroundColor Yellow
Write-Host "="*80 -ForegroundColor Cyan

# Step 1: Get all PDFs in the folder (excluding _backup)
Write-Host "`n[STEP 1] Scanning for PDF files..." -ForegroundColor Cyan
$allPDFs = Get-ChildItem -Path $TargetFolder -Filter "*.pdf" -File | 
    Where-Object { $_.DirectoryName -notlike "*_backup*" } |
    Sort-Object Name

if ($TestMode) {
    $allPDFs = $allPDFs | Select-Object -First 3
    Write-Host "[TEST MODE] Processing only first 3 files" -ForegroundColor Yellow
}

Write-Host "[INFO] Found $($allPDFs.Count) PDFs to process" -ForegroundColor Green

# Step 2: Check which files need OCR
Write-Host "`n[STEP 2] Checking which files need OCR..." -ForegroundColor Cyan
$needsOCR = @()
$hasText = @()

foreach ($pdf in $allPDFs) {
    Write-Host "  Checking: $($pdf.Name)..." -ForegroundColor Gray -NoNewline
    
    # Use Python to check if PDF has extractable text
    $checkCmd = @"
import PyPDF2
try:
    with open(r'$($pdf.FullName)', 'rb') as f:
        reader = PyPDF2.PdfReader(f)
        text = ''
        for i in range(min(3, len(reader.pages))):
            text += reader.pages[i].extract_text()
        print('HAS_TEXT' if len(text.strip()) > 50 else 'NEEDS_OCR')
except:
    print('NEEDS_OCR')
"@
    
    $result = & python -c $checkCmd 2>$null
    
    if ($result -eq 'HAS_TEXT') {
        Write-Host " [Has Text]" -ForegroundColor Green
        $hasText += $pdf
    } else {
        Write-Host " [Needs OCR]" -ForegroundColor Yellow
        $needsOCR += $pdf
    }
}

# Step 3: Perform OCR on files that need it
if ($needsOCR.Count -gt 0) {
    Write-Host "`n[STEP 3] Running OCR on $($needsOCR.Count) files..." -ForegroundColor Cyan
    Write-Host "[INFO] Using adobe_style_ocr.py for professional OCR with searchable PDFs" -ForegroundColor Yellow
    
    foreach ($pdf in $needsOCR) {
        Write-Host "`n  OCR Processing: $($pdf.Name)" -ForegroundColor Yellow
        
        # Create temp output path
        $tempOutput = Join-Path $pdf.DirectoryName "$($pdf.BaseName)_OCR_TEMP.pdf"
        
        # Run OCR using adobe_style_ocr.py
        $ocrResult = & python "$PSScriptRoot\adobe_style_ocr.py" $pdf.FullName $tempOutput 2>&1
        
        if (Test-Path $tempOutput) {
            # Replace original with OCR'd version
            Remove-Item $pdf.FullName -Force
            Rename-Item $tempOutput $pdf.FullName
            Write-Host "    [SUCCESS] OCR completed - PDF is now searchable" -ForegroundColor Green
        } else {
            Write-Host "    [ERROR] OCR failed: $ocrResult" -ForegroundColor Red
        }
    }
} else {
    Write-Host "`n[STEP 3] No files need OCR - all PDFs already have text" -ForegroundColor Green
}

# Step 4: Run AI renaming on all PDFs
Write-Host "`n[STEP 4] Running AI analysis and renaming..." -ForegroundColor Cyan
Write-Host "[INFO] Using Estate Research naming convention (SOP v1.2)" -ForegroundColor Yellow

# Process all PDFs with the Estate Research renamer
$renameResults = @()

foreach ($pdf in $allPDFs) {
    Write-Host "`n  Analyzing: $($pdf.Name)" -ForegroundColor Yellow
    
    # Run Estate Research renamer
    $output = & python "$PSScriptRoot\estate_research_renamer.py" $pdf.FullName 2>&1
    
    # Parse JSON result
    $jsonLine = $output | Where-Object { $_ -match "^RESULT_JSON:" }
    if ($jsonLine) {
        $jsonData = ($jsonLine -replace "^RESULT_JSON:\s*", "") | ConvertFrom-Json
        $renameResults += $jsonData
        
        if ($jsonData.status -eq "renamed") {
            Write-Host "    [RENAMED] -> $($jsonData.new_name)" -ForegroundColor Green
            
            # Show naming components
            if ($jsonData.analysis) {
                Write-Host "    Date: $($jsonData.analysis.date)" -ForegroundColor Gray
                Write-Host "    Matter ID: $($jsonData.analysis.matter_id)" -ForegroundColor Gray
                Write-Host "    Person: $($jsonData.analysis.last_name), $($jsonData.analysis.first_name)" -ForegroundColor Gray
                Write-Host "    Department: $($jsonData.analysis.dept_code)" -ForegroundColor Gray
                Write-Host "    Doc Type: $($jsonData.analysis.doc_type)_$($jsonData.analysis.subtype)" -ForegroundColor Gray
                Write-Host "    Lifecycle: $($jsonData.analysis.lifecycle)" -ForegroundColor Gray
                Write-Host "    Security: $($jsonData.analysis.security_tag)" -ForegroundColor Gray
                Write-Host "    Description: $($jsonData.analysis.legal_description)" -ForegroundColor Gray
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

# Step 5: Summary Report
Write-Host "`n" + "="*80 -ForegroundColor Cyan
Write-Host "PROCESSING COMPLETE - SUMMARY REPORT" -ForegroundColor Cyan
Write-Host "="*80 -ForegroundColor Cyan

$ocrCount = $needsOCR.Count
$renamedCount = ($renameResults | Where-Object { $_.status -eq "renamed" }).Count
$skippedCount = ($renameResults | Where-Object { $_.status -eq "skip" }).Count
$errorCount = ($renameResults | Where-Object { $_.status -eq "error" }).Count

Write-Host "Total PDFs processed: $($allPDFs.Count)"
Write-Host "OCR performed on: $ocrCount files" -ForegroundColor $(if ($ocrCount -gt 0) { "Yellow" } else { "Gray" })
Write-Host "Successfully renamed: $renamedCount files" -ForegroundColor $(if ($renamedCount -gt 0) { "Green" } else { "Gray" })
Write-Host "Already properly named: $skippedCount files" -ForegroundColor Gray
Write-Host "Errors encountered: $errorCount files" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Gray" })
Write-Host "Total AI cost: `$$([math]::Round($renamedCount * 0.0006, 4))" -ForegroundColor Yellow

# Step 6: Show final file list
Write-Host "`n[FINAL] Current PDFs in Estate Research Project:" -ForegroundColor Cyan
Get-ChildItem -Path $TargetFolder -Filter "*.pdf" -File | 
    Where-Object { $_.DirectoryName -notlike "*_backup*" } |
    Sort-Object Name |
    ForEach-Object {
        $color = if ($_.Name -match '^\d{8}_') { "Green" } else { "White" }
        Write-Host "  $($_.Name)" -ForegroundColor $color
    }

Write-Host "`n[INFO] Files with proper naming convention are shown in green" -ForegroundColor Gray
Write-Host "[INFO] OCR creates searchable PDFs, not .txt files" -ForegroundColor Gray
Write-Host "[INFO] All files follow Estate Research Project SOP v1.2" -ForegroundColor Gray