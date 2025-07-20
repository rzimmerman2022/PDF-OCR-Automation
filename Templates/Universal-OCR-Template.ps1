# Universal PDF OCR Processor Template
# Adapt this template for different document types

param(
    [switch]$WhatIf,
    [string]$DocumentType = "General",
    [string]$TargetFolder = "Documents"
)

$scriptRoot = $PSScriptRoot
$targetFolder = Join-Path -Path $scriptRoot -ChildPath $TargetFolder

Write-Host "PDF OCR Processor - $DocumentType Mode" -ForegroundColor Cyan
Write-Host "Targeting folder: $targetFolder" -ForegroundColor Cyan

# Environment checks
Write-Host "`nPerforming environment checks..." -ForegroundColor Yellow

$acroExe = (Get-Command acrobat.exe -ErrorAction SilentlyContinue).Source
if (-not $acroExe) {
    Write-Error "Adobe Acrobat Pro required. Please install Adobe Acrobat Pro."
    exit
}
Write-Host "   Found Acrobat at: $acroExe" -ForegroundColor Green

# Check target folder
if (-not (Test-Path -Path $targetFolder)) {
    Write-Warning "Target folder '$targetFolder' not found. Creating it..."
    New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
}

# Get PDF files
$pdfFiles = Get-ChildItem -Path $targetFolder -Filter "*.pdf"

if ($pdfFiles.Count -eq 0) {
    Write-Warning "No PDF files found in '$targetFolder'."
    exit
}

Write-Host "`nFound $($pdfFiles.Count) PDF files to process." -ForegroundColor Green

if ($WhatIf) {
    Write-Host "`n=== PREVIEW MODE - No files will be modified ===" -ForegroundColor Yellow
    
    foreach ($pdf in $pdfFiles) {
        Write-Host "Would process: $($pdf.Name)" -ForegroundColor Cyan
        # Add preview logic here to show what new names would be
    }
    
    Write-Host "`nPreview completed! Remove -WhatIf to process files." -ForegroundColor Green
    exit
}

Write-Host "`nTo implement full processing:"
Write-Host "1. Copy the OCR logic from PDF-OCR-Processor.ps1"
Write-Host "2. Customize the content patterns for your document type"
Write-Host "3. Modify the naming convention"
Write-Host "4. Test with -WhatIf first!"
