# Simple OCR Test
Write-Host "`n=== Simple OCR Test ===" -ForegroundColor Cyan

# Add Tesseract to PATH
$env:PATH = $env:PATH + ";C:\Program Files\Tesseract-OCR"

# Test file
$testPdf = "C:\Projects\PDF-OCR-Automation\Test-PDFs\Test-Manual.pdf"
$outputPdf = "C:\Projects\PDF-OCR-Automation\Test-PDFs\Test-Manual-Simple-OCR.pdf"

Write-Host "Input: $testPdf" -ForegroundColor Gray
Write-Host "Output: $outputPdf" -ForegroundColor Gray

# Remove output if exists
if (Test-Path $outputPdf) {
    Remove-Item $outputPdf -Force
}

# Run basic OCRmyPDF with force-ocr since the PDF already has text
Write-Host "`nRunning OCRmyPDF..." -ForegroundColor Yellow
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Capture both stdout and stderr
$process = Start-Process -FilePath "ocrmypdf" -ArgumentList @(
    $testPdf,
    $outputPdf,
    "--language", "eng",
    "--optimize", "3",
    "--force-ocr",  # Force OCR even if text exists
    "--oversample", "300"
) -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\ocr_stdout.txt" -RedirectStandardError "$env:TEMP\ocr_stderr.txt"

$stopwatch.Stop()
$exitCode = $process.ExitCode

# Read output
$stdout = Get-Content "$env:TEMP\ocr_stdout.txt" -ErrorAction SilentlyContinue
$stderr = Get-Content "$env:TEMP\ocr_stderr.txt" -ErrorAction SilentlyContinue

# Display results
if ($exitCode -eq 0) {
    Write-Host "[SUCCESS] OCR completed in $($stopwatch.Elapsed.TotalSeconds) seconds!" -ForegroundColor Green
    
    if (Test-Path $outputPdf) {
        $originalSize = [Math]::Round((Get-Item $testPdf).Length / 1KB, 2)
        $newSize = [Math]::Round((Get-Item $outputPdf).Length / 1KB, 2)
        $reduction = [Math]::Round((($originalSize - $newSize) / $originalSize) * 100, 1)
        
        Write-Host "`nFile sizes:" -ForegroundColor Cyan
        Write-Host "  Original: $originalSize KB" -ForegroundColor Gray
        Write-Host "  Optimized: $newSize KB" -ForegroundColor Gray
        Write-Host "  Reduction: $reduction%" -ForegroundColor Green
    }
} else {
    Write-Host "[FAILED] Exit code: $exitCode" -ForegroundColor Red
}

# Show stderr output if any
if ($stderr) {
    Write-Host "`nOCRmyPDF output:" -ForegroundColor Yellow
    $stderr | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

# Cleanup temp files
Remove-Item "$env:TEMP\ocr_stdout.txt" -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\ocr_stderr.txt" -ErrorAction SilentlyContinue

Write-Host "`nTest complete!" -ForegroundColor Green