# Invoice PDF OCR and Renaming Script
# Adapted from medical records script for invoice processing

param([switch]$WhatIf)

$scriptRoot = $PSScriptRoot
$targetFolder = Join-Path -Path $scriptRoot -ChildPath "Invoices"  # Change folder name

Write-Host "Targeting folder: $targetFolder" -ForegroundColor Cyan

if (-not (Test-Path -Path $targetFolder)) {
    Write-Error "Error: The target folder '$targetFolder' was not found."
    exit
}

# Process ALL PDFs in the folder (not just specific pattern)
$pdfFiles = Get-ChildItem -Path $targetFolder -Filter "*.pdf"

if ($pdfFiles.Count -eq 0) {
    Write-Warning "No PDF files found in '$targetFolder'."
    exit
}

Write-Host "Found $($pdfFiles.Count) PDF files to process." -ForegroundColor Green

if ($WhatIf) {
    Write-Host "Running in test mode - no files will be renamed" -ForegroundColor Yellow
    
    foreach ($pdf in $pdfFiles) {
        Write-Host "Would process: $($pdf.Name)" -ForegroundColor Cyan
        
        # Here you could add preview logic to show what the new names would be
        # based on extracted content
    }
    
    Write-Host "Test completed successfully!" -ForegroundColor Green
    exit
}

# TODO: Add the full OCR processing logic here
# This would include:
# 1. Initialize Acrobat Pro
# 2. OCR each PDF
# 3. Extract text
# 4. Look for invoice patterns:
#    - Invoice numbers
#    - Vendor names
#    - Dates
#    - Amounts
# 5. Rename files like: "2025-07-19_Invoice_VendorName_INV123.pdf"

Write-Host "Invoice processing script template created!" -ForegroundColor Green
Write-Host "Add the full OCR logic from the medical script to make this functional." -ForegroundColor Yellow
