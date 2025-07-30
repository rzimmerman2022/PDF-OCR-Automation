#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install Tesseract OCR for Windows
#>

Write-Host "`n=== Installing Tesseract OCR for Windows ===" -ForegroundColor Cyan

# Check if Tesseract is already installed
try {
    $tesseractPath = (Get-Command tesseract -ErrorAction SilentlyContinue).Source
    if ($tesseractPath) {
        Write-Host "Tesseract is already installed at: $tesseractPath" -ForegroundColor Green
        tesseract --version
        return
    }
} catch {}

Write-Host "Tesseract not found. Installing..." -ForegroundColor Yellow

# Option 1: Using Chocolatey (if available)
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Installing via Chocolatey..." -ForegroundColor Gray
    choco install tesseract -y
} 
# Option 2: Using winget (Windows Package Manager)
elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Installing via Windows Package Manager..." -ForegroundColor Gray
    winget install UB-Mannheim.TesseractOCR
}
# Option 3: Manual download
else {
    Write-Host "`nAutomatic installation not available." -ForegroundColor Yellow
    Write-Host "Please install Tesseract manually:" -ForegroundColor White
    
    Write-Host "`n1. Download Tesseract from:" -ForegroundColor Gray
    Write-Host "   https://github.com/UB-Mannheim/tesseract/wiki" -ForegroundColor Cyan
    
    Write-Host "`n2. Run the installer and make sure to:" -ForegroundColor Gray
    Write-Host "   - Check 'Add to PATH' during installation" -ForegroundColor Yellow
    Write-Host "   - Or install to: C:\Program Files\Tesseract-OCR" -ForegroundColor Yellow
    
    Write-Host "`n3. After installation, restart PowerShell" -ForegroundColor Gray
    
    # Open download page
    Start-Process "https://github.com/UB-Mannheim/tesseract/wiki"
}

Write-Host "`nAfter Tesseract is installed, run:" -ForegroundColor Green
Write-Host "  python auto_ocr_simple.py" -ForegroundColor Cyan