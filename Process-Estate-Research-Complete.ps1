#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete processing for Estate Research Project with forced renaming
    
.DESCRIPTION
    This script:
    1. Performs OCR on all PDFs
    2. Forces AI renaming even for files with specific names
    3. Shows complete analysis results
#>

param(
    [string]$TargetFolder = "C:\Projects\Estate Research Project"
)

Write-Host "`n=== Estate Research Project - Complete Processing ===" -ForegroundColor Cyan
Write-Host "Using Gemini 2.5 Flash for intelligent document analysis`n" -ForegroundColor Green

# Step 1: Clear processing state to force reprocessing
$stateFile = Join-Path $PSScriptRoot ".processing_status.json"
if (Test-Path $stateFile) {
    Write-Host "[1/3] Clearing previous processing state..." -ForegroundColor Yellow
    Remove-Item $stateFile -Force
}

# Step 2: Run OCR on all PDFs
Write-Host "[2/3] Running OCR on all PDFs..." -ForegroundColor Yellow
& "$PSScriptRoot\Process-PDFs-Complete.ps1" -TargetFolder $TargetFolder -SkipDryRun -AutoConfirm -OCROnly

# Step 3: Force AI renaming on all PDFs
Write-Host "`n[3/3] Analyzing and renaming all PDFs with AI..." -ForegroundColor Yellow

$pdfs = Get-ChildItem -Path $TargetFolder -Filter "*.pdf"
$results = @()

foreach ($pdf in $pdfs) {
    Write-Host "`nProcessing: $($pdf.Name)" -ForegroundColor Cyan
    
    # Call Python script directly to bypass generic filename check
    $output = & python "$PSScriptRoot\pdf_renamer.py" $pdf.FullName 2>&1
    
    # Parse the JSON result
    $jsonLine = $output | Where-Object { $_ -match "^RESULT_JSON:" }
    if ($jsonLine) {
        $jsonData = ($jsonLine -replace "^RESULT_JSON:\s*", "") | ConvertFrom-Json
        $results += $jsonData
        
        if ($jsonData.status -eq "renamed") {
            Write-Host "  [OK] Renamed to: $($jsonData.new_name)" -ForegroundColor Green
            if ($jsonData.analysis) {
                Write-Host "  - Type: $($jsonData.analysis.document_type)" -ForegroundColor Gray
                Write-Host "  - Industry: $($jsonData.analysis.industry)" -ForegroundColor Gray
                Write-Host "  - Key Info: $($jsonData.analysis.key_info)" -ForegroundColor Gray
            }
        } elseif ($jsonData.status -eq "error") {
            Write-Host "  [ERROR] $($jsonData.error)" -ForegroundColor Red
        }
    }
}

# Summary
Write-Host "`n=== Processing Summary ===" -ForegroundColor Cyan
$successful = @($results | Where-Object { $_.status -eq "renamed" }).Count
$errors = @($results | Where-Object { $_.status -eq "error" }).Count
$totalCost = $successful * 0.0006

Write-Host "Total files processed: $($results.Count)"
Write-Host "Successfully renamed: $successful" -ForegroundColor Green
Write-Host "Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Gray" })
Write-Host "Total AI cost: `$$([math]::Round($totalCost, 4))" -ForegroundColor Yellow
Write-Host "`nAll files have been processed with industry-standard naming conventions!" -ForegroundColor Green