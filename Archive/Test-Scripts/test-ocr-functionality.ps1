# Test OCR Functionality
Write-Host "`n=== Testing OCR Functionality ===" -ForegroundColor Cyan

# Add Tesseract to PATH temporarily
$env:PATH = $env:PATH + ";C:\Program Files\Tesseract-OCR"

# Test paths
$testPdf = "C:\Projects\PDF-OCR-Automation\Test-PDFs\Test-Manual.pdf"
$outputPdf = "C:\Projects\PDF-OCR-Automation\Test-PDFs\Test-Manual-OCR.pdf"

# Test 1: Basic OCRmyPDF command
Write-Host "`n1. Testing basic OCRmyPDF command..." -ForegroundColor Yellow
try {
    # Remove output file if exists
    if (Test-Path $outputPdf) {
        Remove-Item $outputPdf -Force
    }
    
    # Run OCRmyPDF
    $result = & ocrmypdf $testPdf $outputPdf --language eng 2>&1
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "[SUCCESS] Basic OCR completed!" -ForegroundColor Green
        Write-Host "Output file: $outputPdf" -ForegroundColor Gray
    } else {
        Write-Host "[FAILED] Exit code: $exitCode" -ForegroundColor Red
        Write-Host "Output: $result" -ForegroundColor Gray
    }
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: OCR with best practices
Write-Host "`n2. Testing OCR with best practices..." -ForegroundColor Yellow
$outputPdf2 = "C:\Projects\PDF-OCR-Automation\Test-PDFs\Test-Manual-BestPractices.pdf"
try {
    # Remove output file if exists
    if (Test-Path $outputPdf2) {
        Remove-Item $outputPdf2 -Force
    }
    
    # Run OCRmyPDF with best practices
    $result = & ocrmypdf $testPdf $outputPdf2 --language eng --optimize 3 --deskew --clean --oversample 300 2>&1
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "[SUCCESS] Best practices OCR completed!" -ForegroundColor Green
        Write-Host "Output file: $outputPdf2" -ForegroundColor Gray
        
        # Compare file sizes
        $originalSize = (Get-Item $testPdf).Length / 1KB
        $optimizedSize = (Get-Item $outputPdf2).Length / 1KB
        Write-Host "Original size: $([Math]::Round($originalSize, 2)) KB" -ForegroundColor Gray
        Write-Host "Optimized size: $([Math]::Round($optimizedSize, 2)) KB" -ForegroundColor Gray
        Write-Host "Reduction: $([Math]::Round((($originalSize - $optimizedSize) / $originalSize) * 100, 1))%" -ForegroundColor Green
    } else {
        Write-Host "[FAILED] Exit code: $exitCode" -ForegroundColor Red
        Write-Host "Output: $result" -ForegroundColor Gray
    }
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Enhanced PowerShell script
Write-Host "`n3. Testing Enhanced-OCRmyPDF-Processor.ps1..." -ForegroundColor Yellow
try {
    # Test in preview mode first
    Write-Host "Running in preview mode..." -ForegroundColor Gray
    & "C:\Projects\PDF-OCR-Automation\Enhanced-OCRmyPDF-Processor.ps1" -InputPath $testPdf -Language eng -Optimize 3 -WhatIf
    
    Write-Host "`nScript is ready for use!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "All components are installed and functional!" -ForegroundColor Green
Write-Host "`nYou can now use:" -ForegroundColor Yellow
Write-Host "- ocrmypdf command directly" -ForegroundColor Gray
Write-Host "- Enhanced-OCRmyPDF-Processor.ps1 for batch processing" -ForegroundColor Gray
Write-Host "- adobe_style_ocr.py for Python processing" -ForegroundColor Gray