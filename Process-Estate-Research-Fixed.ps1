#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete OCR + AI processing for Estate Research Project
    
.DESCRIPTION
    This script ensures proper workflow:
    1. OCR all PDFs that need it
    2. AI rename ALL PDFs (not just generic names)
    3. Show complete results
#>

param(
    [string]$TargetFolder = "C:\Projects\Estate Research Project",
    [switch]$ForceRenameAll
)

Write-Host "`n=== Estate Research Project - Complete OCR + AI Processing ===" -ForegroundColor Cyan
Write-Host "Workflow: OCR -> AI Analysis -> Smart Rename`n" -ForegroundColor Green

# Clear state to ensure fresh processing
$stateFile = Join-Path $PSScriptRoot ".processing_status.json"
if (Test-Path $stateFile) {
    Write-Host "[INFO] Clearing previous state for fresh processing..." -ForegroundColor Yellow
    Remove-Item $stateFile -Force
}

# Step 1: Run complete processing with OCR
Write-Host "`n[STEP 1] Running OCR on all PDFs that need it..." -ForegroundColor Cyan
& "$PSScriptRoot\Process-PDFs-Complete.ps1" `
    -TargetFolder $TargetFolder `
    -SkipDryRun `
    -AutoConfirm

# Wait for OCR to complete
Start-Sleep -Seconds 2

# Step 2: Get all PDFs for AI renaming
Write-Host "`n[STEP 2] Collecting all PDFs for AI analysis..." -ForegroundColor Cyan
$allPDFs = Get-ChildItem -Path $TargetFolder -Filter "*.pdf" | Sort-Object Name

if ($allPDFs.Count -eq 0) {
    Write-Host "[ERROR] No PDF files found!" -ForegroundColor Red
    return
}

Write-Host "[INFO] Found $($allPDFs.Count) PDFs to analyze" -ForegroundColor Green

# Step 3: Process each PDF with AI
Write-Host "`n[STEP 3] Running AI analysis on all PDFs..." -ForegroundColor Cyan
$results = @()
$successCount = 0
$errorCount = 0

foreach ($pdf in $allPDFs) {
    Write-Host "`nAnalyzing: $($pdf.Name)" -ForegroundColor Yellow
    
    # Call Python AI script directly
    $output = & python "$PSScriptRoot\pdf_renamer.py" $pdf.FullName 2>&1
    
    # Parse JSON result
    $jsonLine = $output | Where-Object { $_ -match "^RESULT_JSON:" }
    if ($jsonLine) {
        $jsonData = ($jsonLine -replace "^RESULT_JSON:\s*", "") | ConvertFrom-Json
        $results += $jsonData
        
        if ($jsonData.status -eq "renamed") {
            $successCount++
            Write-Host "  [SUCCESS] -> $($jsonData.new_name)" -ForegroundColor Green
            if ($jsonData.analysis.document_type) {
                Write-Host "  Type: $($jsonData.analysis.document_type)" -ForegroundColor Gray
                Write-Host "  Info: $($jsonData.analysis.key_info)" -ForegroundColor Gray
            }
        }
        elseif ($jsonData.status -eq "error") {
            $errorCount++
            Write-Host "  [ERROR] $($jsonData.error)" -ForegroundColor Red
            
            # If error is "No text extracted", file needs OCR
            if ($jsonData.error -match "No text extracted") {
                Write-Host "  [INFO] This file needs OCR processing first" -ForegroundColor Yellow
            }
        }
        elseif ($jsonData.status -eq "skip") {
            Write-Host "  [SKIP] File already has appropriate name" -ForegroundColor Gray
        }
    }
}

# Summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "PROCESSING COMPLETE" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "Total PDFs processed: $($allPDFs.Count)"
Write-Host "Successfully renamed: $successCount" -ForegroundColor Green
Write-Host "Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Gray" })
Write-Host "Total AI cost: `$$([math]::Round($successCount * 0.0006, 4))" -ForegroundColor Yellow

if ($errorCount -gt 0) {
    Write-Host "`n[NOTE] Files with 'No text extracted' errors need OCR first." -ForegroundColor Yellow
    Write-Host "The system should have OCR'd them in Step 1. Check if OCR is working." -ForegroundColor Yellow
}

# Show renamed files
if ($successCount -gt 0) {
    Write-Host "`nRenamed files:" -ForegroundColor Green
    $results | Where-Object { $_.status -eq "renamed" } | ForEach-Object {
        Write-Host "  $($_.original_name) -> $($_.new_name)" -ForegroundColor White
    }
}