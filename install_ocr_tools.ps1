#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install OCR tools for creating searchable PDFs like Adobe Pro
#>

Write-Host "`n=== Installing OCR Tools for Searchable PDFs ===" -ForegroundColor Cyan
Write-Host "This will install tools to create proper OCR'd PDFs (like Adobe Pro)" -ForegroundColor Gray

# Install Python packages
Write-Host "`nInstalling Python packages..." -ForegroundColor Yellow
pip install ocrmypdf

# Check if Tesseract is installed
Write-Host "`nChecking for Tesseract OCR..." -ForegroundColor Yellow
try {
    $tesseractPath = (Get-Command tesseract -ErrorAction SilentlyContinue).Source
    if ($tesseractPath) {
        Write-Host "[OK] Tesseract found at: $tesseractPath" -ForegroundColor Green
        tesseract --version
    }
} catch {}

if (-not $tesseractPath) {
    Write-Host "`n[REQUIRED] Tesseract OCR not found!" -ForegroundColor Red
    Write-Host "`nTo create searchable PDFs like Adobe Pro, you need Tesseract:" -ForegroundColor White
    
    # Check for package managers
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "`nOption 1 - Install with Chocolatey:" -ForegroundColor Cyan
        Write-Host "  choco install tesseract" -ForegroundColor Gray
    }
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "`nOption 2 - Install with Windows Package Manager:" -ForegroundColor Cyan
        Write-Host "  winget install UB-Mannheim.TesseractOCR" -ForegroundColor Gray
    }
    
    Write-Host "`nOption 3 - Manual Installation:" -ForegroundColor Cyan
    Write-Host "1. Download from: https://github.com/UB-Mannheim/tesseract/wiki" -ForegroundColor Gray
    Write-Host "2. Run the installer" -ForegroundColor Gray
    Write-Host "3. IMPORTANT: Check 'Add to PATH' during installation" -ForegroundColor Yellow
    Write-Host "4. Restart your terminal after installation" -ForegroundColor Gray
    
    Write-Host "`nOpening download page..." -ForegroundColor Gray
    Start-Process "https://github.com/UB-Mannheim/tesseract/wiki"
}

Write-Host "`n=== Installation Summary ===" -ForegroundColor Cyan
Write-Host "ocrmypdf creates searchable PDFs just like Adobe Pro:" -ForegroundColor White
Write-Host "- Preserves original PDF quality" -ForegroundColor Gray
Write-Host "- Adds invisible text layer for searching" -ForegroundColor Gray
Write-Host "- Maintains exact appearance of scanned documents" -ForegroundColor Gray
Write-Host "- Can deskew and clean up scans" -ForegroundColor Gray

Write-Host "`nOnce Tesseract is installed, run:" -ForegroundColor Green
Write-Host "  python adobe_style_ocr.py" -ForegroundColor Cyan