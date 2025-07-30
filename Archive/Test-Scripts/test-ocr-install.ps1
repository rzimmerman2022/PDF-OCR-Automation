# Test OCR Installation Script
Write-Host "`n=== Testing OCR Installation ===" -ForegroundColor Cyan

# Check Python
Write-Host "`nChecking Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[OK] Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python not found" -ForegroundColor Red
}

# Check pip
Write-Host "`nChecking pip..." -ForegroundColor Yellow
try {
    $pipVersion = pip --version 2>&1
    Write-Host "[OK] pip found: $pipVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] pip not found" -ForegroundColor Red
}

# Check Tesseract
Write-Host "`nChecking Tesseract..." -ForegroundColor Yellow
try {
    $tesseractVersion = tesseract --version 2>&1 | Select-Object -First 1
    Write-Host "[OK] Tesseract found: $tesseractVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Tesseract not found" -ForegroundColor Red
    Write-Host "Install with: choco install --pre tesseract -y" -ForegroundColor Yellow
}

# Check Ghostscript
Write-Host "`nChecking Ghostscript..." -ForegroundColor Yellow
$gsFound = $false
try {
    $gsVersion = gswin64c --version 2>&1
    Write-Host "[OK] Ghostscript (64-bit) found: $gsVersion" -ForegroundColor Green
    $gsFound = $true
} catch {
    try {
        $gsVersion = gswin32c --version 2>&1
        Write-Host "[OK] Ghostscript (32-bit) found: $gsVersion" -ForegroundColor Green
        $gsFound = $true
    } catch {
        Write-Host "[ERROR] Ghostscript not found" -ForegroundColor Red
        Write-Host "Install with: choco install ghostscript -y" -ForegroundColor Yellow
    }
}

# Check OCRmyPDF
Write-Host "`nChecking OCRmyPDF..." -ForegroundColor Yellow
try {
    $ocrmypdfVersion = ocrmypdf --version 2>&1
    Write-Host "[OK] OCRmyPDF found: $ocrmypdfVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] OCRmyPDF not found" -ForegroundColor Red
    Write-Host "Install with: pip install --upgrade ocrmypdf" -ForegroundColor Yellow
}

Write-Host "`n=== Installation Status Summary ===" -ForegroundColor Cyan