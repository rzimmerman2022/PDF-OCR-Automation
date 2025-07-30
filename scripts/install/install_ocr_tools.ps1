#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install OCR tools for creating searchable PDFs with best practices
    Includes OCRmyPDF, Tesseract, and Ghostscript for reliable OCR results
    
.DESCRIPTION
    This script installs all necessary components for OCRmyPDF:
    - OCRmyPDF: Python wrapper for Tesseract with PDF handling
    - Tesseract: The OCR engine
    - Ghostscript: PDF rendering engine
    
    Following best practices:
    - Pre-clean scans at 300 DPI in grayscale
    - Use --optimize 3 for large color scans
    - Specify languages explicitly
    - Capture stderr for diagnostics
    
.NOTES
    Run this script with Administrator privileges for system-wide installation
#>

Write-Host "`n=== Installing OCR Tools for Searchable PDFs ===" -ForegroundColor Cyan
Write-Host "This will install tools to create proper OCR'd PDFs with best practices" -ForegroundColor Gray
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "⚠️  Not running as Administrator" -ForegroundColor Yellow
    Write-Host "   Some installations may require admin privileges" -ForegroundColor Gray
    Write-Host ""
}

# Install Python packages
Write-Host "📦 Installing Python packages..." -ForegroundColor Yellow
Write-Host "   Installing OCRmyPDF..." -ForegroundColor Gray
pip install --upgrade ocrmypdf

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

# Check for Ghostscript
Write-Host "`nChecking for Ghostscript..." -ForegroundColor Yellow
$gsFound = $false
try {
    $gsPath = (Get-Command gswin64c -ErrorAction SilentlyContinue).Source
    if (-not $gsPath) {
        $gsPath = (Get-Command gswin32c -ErrorAction SilentlyContinue).Source
    }
    if ($gsPath) {
        Write-Host "[OK] Ghostscript found at: $gsPath" -ForegroundColor Green
        $gsFound = $true
    }
} catch {}

if (-not $gsFound) {
    Write-Host "[REQUIRED] Ghostscript not found!" -ForegroundColor Red
    Write-Host "`nGhostscript is required for OCRmyPDF to process PDFs:" -ForegroundColor White
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "`nOption 1 - Install with Chocolatey:" -ForegroundColor Cyan
        Write-Host "  choco install ghostscript -y" -ForegroundColor Gray
    }
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "`nOption 2 - Install with Windows Package Manager:" -ForegroundColor Cyan
        Write-Host "  winget install ArtifexSoftware.Ghostscript" -ForegroundColor Gray
    }
}

Write-Host "`n=== Installation Summary ===" -ForegroundColor Cyan
Write-Host "OCRmyPDF with best practices for reliable results:" -ForegroundColor White
Write-Host ""
Write-Host "✅ Features:" -ForegroundColor Green
Write-Host "- Preserves original PDF quality" -ForegroundColor Gray
Write-Host "- Adds invisible text layer for searching" -ForegroundColor Gray
Write-Host "- Maintains exact appearance of scanned documents" -ForegroundColor Gray
Write-Host "- Can deskew and clean up scans" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 Best Practices:" -ForegroundColor Cyan
Write-Host "- Pre-clean scans: 300 DPI, grayscale, remove noise" -ForegroundColor Gray
Write-Host "- Use --optimize 3 for large color scans" -ForegroundColor Gray
Write-Host "- Specify languages explicitly (e.g., eng+spa)" -ForegroundColor Gray
Write-Host "- Capture stderr for helpful diagnostics" -ForegroundColor Gray

Write-Host "`n🚀 Quick Start Commands:" -ForegroundColor Green
Write-Host "  Basic OCR:" -ForegroundColor Cyan
Write-Host "    ocrmypdf input.pdf output.pdf --language eng" -ForegroundColor Gray
Write-Host ""
Write-Host "  With best practices:" -ForegroundColor Cyan
Write-Host "    ocrmypdf input.pdf output.pdf --language eng --optimize 3 --deskew --clean --oversample 300" -ForegroundColor Gray
Write-Host ""
Write-Host "  PowerShell script:" -ForegroundColor Cyan
Write-Host "    .\\Enhanced-OCRmyPDF-Processor.ps1 -InputPath `".\Documents`" -Language eng -Optimize 3" -ForegroundColor Gray
Write-Host ""
Write-Host "  Python script:" -ForegroundColor Cyan
Write-Host "    python adobe_style_ocr.py" -ForegroundColor Gray

# Complete installation command for convenience
Write-Host "`n📦 Complete Installation (Admin PowerShell):" -ForegroundColor Yellow
Write-Host "# 1. Install Chocolatey if needed" -ForegroundColor Gray
Write-Host "Set-ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor Gray
Write-Host "[System.Net.ServicePointManager]::SecurityProtocol = 3072" -ForegroundColor Gray
Write-Host "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray
Write-Host "# 2. Install the complete toolchain" -ForegroundColor Gray
Write-Host "choco install python3 -y" -ForegroundColor Gray
Write-Host "choco install --pre tesseract -y" -ForegroundColor Gray
Write-Host "choco install ghostscript -y" -ForegroundColor Gray
Write-Host "pip install --upgrade ocrmypdf" -ForegroundColor Gray