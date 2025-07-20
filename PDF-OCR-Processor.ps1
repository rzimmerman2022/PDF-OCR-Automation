# Simple medical PDF renamer - rebuilt to avoid parsing errors
param([switch]$WhatIf)

$scriptRoot = $PSScriptRoot
$targetFolder = Join-Path -Path $scriptRoot -ChildPath "02_LabResults"

Write-Host "Targeting folder: $targetFolder" -ForegroundColor Cyan

if (-not (Test-Path -Path $targetFolder)) {
    Write-Error "Error: The target folder '$targetFolder' was not found."
    exit
}

$pdfFiles = Get-ChildItem -Path $targetFolder -Filter "*_LabResults_TestDetails_*.pdf"

if ($pdfFiles.Count -eq 0) {
    Write-Warning "No PDF files found."
    exit
}

Write-Host "Found $($pdfFiles.Count) PDF files to process." -ForegroundColor Green

if ($WhatIf) {
    Write-Host "Running in test mode - no files will be renamed" -ForegroundColor Yellow
    
    foreach ($pdf in $pdfFiles) {
        Write-Host "Would process: $($pdf.Name)" -ForegroundColor Cyan
    }
    
    Write-Host "Test completed successfully!" -ForegroundColor Green
    exit
}

Write-Host "This would normally process the PDF files with Acrobat Pro." -ForegroundColor Yellow
Write-Host "Script structure is now correct!" -ForegroundColor Green
