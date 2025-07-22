#!/usr/bin/env pwsh
# Direct test of AI renaming on Estate Research Project files

$targetDir = "C:\Projects\Estate Research Project"
$pdfs = Get-ChildItem -Path $targetDir -Filter "*.pdf" | Select-Object -First 3

if ($pdfs.Count -eq 0) {
    Write-Host "No PDF files found in $targetDir" -ForegroundColor Red
    exit
}

Write-Host "Testing AI renaming on Estate Research Project files..." -ForegroundColor Cyan
Write-Host "Using Gemini 2.5 Flash for analysis`n" -ForegroundColor Green

foreach ($pdf in $pdfs) {
    Write-Host "Processing: $($pdf.Name)" -ForegroundColor Yellow
    
    # Call Python script directly
    $result = & python "$PSScriptRoot\pdf_renamer.py" $pdf.FullName 2>&1
    
    # Display result
    $result | ForEach-Object { Write-Host $_ }
    Write-Host "`n" -NoNewline
}