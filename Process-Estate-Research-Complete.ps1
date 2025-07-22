#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete OCR + AI processing for Estate Research Project
    Uses the real OCR processor, not the placeholder
    
.DESCRIPTION
    This script:
    1. Performs REAL OCR using Adobe Acrobat
    2. AI renames ALL PDFs with descriptive names
    3. Shows complete results
#>

param(
    [string]$TargetFolder = "C:\Projects\Estate Research Project"
)

Write-Host "`n=== Estate Research Project - Complete OCR + AI Processing ===" -ForegroundColor Cyan
Write-Host "Using Adobe Acrobat for OCR and Gemini 2.5 for AI naming`n" -ForegroundColor Green

# Clear state to ensure fresh processing
$stateFile = Join-Path $PSScriptRoot ".processing_status.json"
if (Test-Path $stateFile) {
    Write-Host "[INFO] Clearing previous state for fresh processing..." -ForegroundColor Yellow
    Remove-Item $stateFile -Force
}

# Step 1: Run REAL OCR using Universal PDF OCR Processor
Write-Host "`n[STEP 1] Running Adobe Acrobat OCR on all PDFs..." -ForegroundColor Cyan

# Get all PDFs that need OCR
$pdfs = Get-ChildItem -Path $TargetFolder -Filter "*.pdf" | Where-Object { 
    $_.Name -match "comm\d+\.pdf|New Will signed\.pdf"
}

if ($pdfs.Count -gt 0) {
    Write-Host "[INFO] Found $($pdfs.Count) PDFs needing OCR" -ForegroundColor Yellow
    
    # Use the real OCR processor
    & "$PSScriptRoot\Universal-PDF-OCR-Processor.ps1" `
        -TargetFolder $TargetFolder `
        -DocumentType "legal" `
        -Language "eng"
    
    Write-Host "`n[INFO] OCR processing complete!" -ForegroundColor Green
} else {
    Write-Host "[INFO] No PDFs need OCR processing" -ForegroundColor Gray
}

# Wait for OCR to complete
Start-Sleep -Seconds 3

# Step 2: Get all PDFs for AI renaming
Write-Host "`n[STEP 2] Collecting all PDFs for AI analysis..." -ForegroundColor Cyan
$allPDFs = Get-ChildItem -Path $TargetFolder -Filter "*.pdf" | Sort-Object Name

if ($allPDFs.Count -eq 0) {
    Write-Host "[ERROR] No PDF files found!" -ForegroundColor Red
    return
}

Write-Host "[INFO] Found $($allPDFs.Count) PDFs to analyze" -ForegroundColor Green

# Step 3: Process each PDF with AI
Write-Host "`n[STEP 3] Running AI analysis with descriptive naming..." -ForegroundColor Cyan
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
                Write-Host "  Description: $($jsonData.analysis.description)" -ForegroundColor Gray
                Write-Host "  Info: $($jsonData.analysis.key_info)" -ForegroundColor Gray
            }
        }
        elseif ($jsonData.status -eq "error") {
            $errorCount++
            Write-Host "  [ERROR] $($jsonData.error)" -ForegroundColor Red
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

# Show renamed files
if ($successCount -gt 0) {
    Write-Host "`nSuccessfully renamed files:" -ForegroundColor Green
    $results | Where-Object { $_.status -eq "renamed" } | ForEach-Object {
        Write-Host "  $($_.original_name) -> $($_.new_name)" -ForegroundColor White
    }
}

# Final check - list all PDFs in the directory
Write-Host "`n[FINAL] Current PDFs in Estate Research Project:" -ForegroundColor Cyan
Get-ChildItem -Path $TargetFolder -Filter "*.pdf" | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor White
}