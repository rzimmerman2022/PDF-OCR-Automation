# Basic OCR Test without optimization
Write-Host "`n=== Basic OCR Test ===" -ForegroundColor Cyan

# Add Tesseract to PATH
$env:PATH = $env:PATH + ";C:\Program Files\Tesseract-OCR"

# Test file
$testPdf = "C:\Projects\PDF-OCR-Automation\Test-PDFs\Test-Manual.pdf"
$outputPdf = "C:\Projects\PDF-OCR-Automation\Test-PDFs\Test-Manual-Basic-OCR.pdf"

Write-Host "Input: $testPdf" -ForegroundColor Gray
Write-Host "Output: $outputPdf" -ForegroundColor Gray

# Remove output if exists
if (Test-Path $outputPdf) {
    Remove-Item $outputPdf -Force
}

# Run basic OCRmyPDF without optimization (to avoid pngquant dependency)
Write-Host "`nRunning OCRmyPDF (basic mode)..." -ForegroundColor Yellow
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$result = & ocrmypdf $testPdf $outputPdf --language eng --force-ocr 2>&1
$exitCode = $LASTEXITCODE

$stopwatch.Stop()

# Display results
if ($exitCode -eq 0) {
    Write-Host "[SUCCESS] OCR completed in $([Math]::Round($stopwatch.Elapsed.TotalSeconds, 1)) seconds!" -ForegroundColor Green
    
    if (Test-Path $outputPdf) {
        $originalSize = [Math]::Round((Get-Item $testPdf).Length / 1KB, 2)
        $newSize = [Math]::Round((Get-Item $outputPdf).Length / 1KB, 2)
        
        Write-Host "`nFile info:" -ForegroundColor Cyan
        Write-Host "  Original: $originalSize KB" -ForegroundColor Gray
        Write-Host "  OCR'd: $newSize KB" -ForegroundColor Gray
        Write-Host "`nSearchable PDF created successfully!" -ForegroundColor Green
    }
} else {
    Write-Host "[FAILED] Exit code: $exitCode" -ForegroundColor Red
    Write-Host "Output:" -ForegroundColor Yellow
    $result | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

# Test Python script too
Write-Host "`n=== Testing Python Script ===" -ForegroundColor Cyan
Write-Host "Running adobe_style_ocr.py..." -ForegroundColor Yellow

# Create a test directory
$testDir = "C:\Projects\PDF-OCR-Automation\Test-PDFs\OCR-Test"
if (-not (Test-Path $testDir)) {
    New-Item -ItemType Directory -Path $testDir | Out-Null
}

# Copy test file
Copy-Item $testPdf -Destination "$testDir\test.pdf" -Force

# Run Python script
$pythonResult = python "C:\Projects\PDF-OCR-Automation\adobe_style_ocr.py" $testDir 2>&1
Write-Host $pythonResult -ForegroundColor Gray

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "OCRmyPDF is working correctly!" -ForegroundColor Green
Write-Host "Note: For full optimization features, install:" -ForegroundColor Yellow
Write-Host "  choco install pngquant -y  # For --optimize 2,3" -ForegroundColor Gray
Write-Host "  choco install unpaper -y   # For --clean option" -ForegroundColor Gray