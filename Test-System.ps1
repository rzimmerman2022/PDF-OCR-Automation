#!/usr/bin/env pwsh
param([switch]$Verbose)

Write-Host "=== PDF-OCR-Automation System Test ===" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0

# Test Python
try {
    $result = & python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] Python: $result" -ForegroundColor Green
        $passed++
    }
    else {
        Write-Host "[FAIL] Python not found" -ForegroundColor Red  
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Python error" -ForegroundColor Red
    $failed++
}

# Test packages
$packages = @("PyPDF2", "google.generativeai")
foreach ($pkg in $packages) {
    try {
        $result = & python -c "import $pkg; print('OK')" 2>&1
        if ($result -match "OK") {
            Write-Host "[PASS] Package: $pkg" -ForegroundColor Green
            $passed++
        }
        else {
            Write-Host "[FAIL] Package: $pkg" -ForegroundColor Red
            $failed++
        }
    }
    catch {
        Write-Host "[FAIL] Package: $pkg" -ForegroundColor Red
        $failed++
    }
}

# Test scripts
$scripts = @("Process-PDFs-Complete.ps1", "Quick-Start.ps1", "pdf_renamer.py")
foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "[PASS] Script: $script" -ForegroundColor Green
        $passed++
    }
    else {
        Write-Host "[FAIL] Script: $script" -ForegroundColor Red
        $failed++
    }
}

# Test .env
if (Test-Path ".env") {
    Write-Host "[PASS] API Configuration (.env file)" -ForegroundColor Green
    $passed++
}
else {
    Write-Host "[FAIL] API Configuration (.env file)" -ForegroundColor Red
    $failed++
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

if ($failed -eq 0) {
    Write-Host "System validation successful!" -ForegroundColor Green
}
else {
    Write-Host "System validation failed - check errors above" -ForegroundColor Red
}