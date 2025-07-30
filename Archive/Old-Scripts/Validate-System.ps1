#!/usr/bin/env pwsh
<#
.SYNOPSIS
    System Validation Script for PDF-OCR-Automation
    
.DESCRIPTION
    Simple validation script that verifies the system is working correctly
#>

param(
    [switch]$Verbose
)

$script:ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:TestsPassed = 0
$script:TestsFailed = 0

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    if ($Passed) {
        Write-Host "[PASS] $TestName" -ForegroundColor Green
        $script:TestsPassed++
    }
    else {
        Write-Host "[FAIL] $TestName" -ForegroundColor Red
        $script:TestsFailed++
    }
    
    if ($Message -and ($Verbose -or -not $Passed)) {
        Write-Host "       $Message" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== PDF-OCR-Automation System Validation ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check Python installation
try {
    $pythonVersion = & python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-TestResult "Python Installation" $true "Found: $pythonVersion"
    }
    else {
        Write-TestResult "Python Installation" $false "Python not found"
    }
}
catch {
    Write-TestResult "Python Installation" $false "Error checking Python"
}

# Test 2: Check Python packages
$packages = @("PyPDF2", "google.generativeai")
foreach ($package in $packages) {
    try {
        $result = & python -c "import $package; print('OK')" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Python Package: $package" $true "Package available"
        }
        else {
            Write-TestResult "Python Package: $package" $false "Package not found"
        }
    }
    catch {
        Write-TestResult "Python Package: $package" $false "Error checking package"
    }
}

# Test 3: Check main scripts
$scripts = @(
    "Process-PDFs-Complete.ps1",
    "Quick-Start.ps1",
    "pdf_renamer.py",
    "Test-Pipeline-Components.ps1"
)

foreach ($script in $scripts) {
    $scriptPath = Join-Path $script:ScriptRoot $script
    if (Test-Path $scriptPath) {
        Write-TestResult "Script: $script" $true "File exists"
    }
    else {
        Write-TestResult "Script: $script" $false "File not found"
    }
}

# Test 4: Check API key configuration
$envFile = Join-Path $script:ScriptRoot ".env"
if (Test-Path $envFile) {
    Write-TestResult "API Configuration" $true ".env file exists"
}
else {
    Write-TestResult "API Configuration" $false ".env file not found"
}

# Test 5: Test Python script execution
try {
    $testResult = & python (Join-Path $script:ScriptRoot "pdf_renamer.py") --help 2>&1
    if ($testResult -match "usage:") {
        Write-TestResult "Python Script Execution" $true "pdf_renamer.py responds correctly"
    }
    else {
        Write-TestResult "Python Script Execution" $false "pdf_renamer.py not responding"
    }
}
catch {
    Write-TestResult "Python Script Execution" $false "Error testing Python script"
}

# Test 6: Test Quick-Start help
try {
    $helpResult = & powershell -ExecutionPolicy Bypass -Command "& '$(Join-Path $script:ScriptRoot 'Quick-Start.ps1')'" 2>&1
    if ($helpResult -match "Quick Start") {
        Write-TestResult "Quick-Start Help" $true "Help display working"
    }
    else {
        Write-TestResult "Quick-Start Help" $false "Help not displaying correctly"
    }
}
catch {
    Write-TestResult "Quick-Start Help" $false "Error testing Quick-Start"
}

# Test 7: Create and test with sample files
$tempDir = Join-Path $env:TEMP "SystemValidation_$(Get-Random)"
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

try {
    # Create a simple test file
    $testFile = Join-Path $tempDir "test.pdf"
    "Mock PDF content for testing" | Out-File $testFile
    
    # Test main script parameter handling
    $mainScript = Join-Path $script:ScriptRoot "Process-PDFs-Complete.ps1"
    $paramTest = & powershell -ExecutionPolicy Bypass -Command "& '$mainScript' -TargetFolder '$tempDir' -WhatIf" 2>&1
    
    if ($paramTest -notmatch "mandatory") {
        Write-TestResult "Main Script Parameter Handling" $true "Parameters processed correctly"
    }
    else {
        Write-TestResult "Main Script Parameter Handling" $false "Parameter validation failed"
    }
}
catch {
    Write-TestResult "Main Script Parameter Handling" $false "Error testing main script"
}
finally {
    # Cleanup
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Test 8: Directory structure validation
$testDirs = @("tests", "tests\unit", "tests\integration", "tests\data")
foreach ($dir in $testDirs) {
    $dirPath = Join-Path $script:ScriptRoot $dir
    if (Test-Path $dirPath) {
        Write-TestResult "Directory: $dir" $true "Directory exists"
    }
    else {
        Write-TestResult "Directory: $dir" $false "Directory missing"
    }
}

# Summary
Write-Host ""
Write-Host "=== VALIDATION SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($script:TestsPassed + $script:TestsFailed)" -ForegroundColor White
Write-Host "Passed: $script:TestsPassed" -ForegroundColor Green
Write-Host "Failed: $script:TestsFailed" -ForegroundColor $(if ($script:TestsFailed -eq 0) { "Green" } else { "Red" })

if ($script:TestsFailed -eq 0) {
    Write-Host ""
    Write-Host "✓ SYSTEM VALIDATION SUCCESSFUL!" -ForegroundColor Green
    Write-Host "The PDF-OCR-Automation system is ready for use." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Set up API key: .\Quick-Start.ps1 -Setup" -ForegroundColor White
    Write-Host "2. Test with dry run: .\Quick-Start.ps1 -DryRun" -ForegroundColor White
    Write-Host "3. Process files: .\Quick-Start.ps1 -Process" -ForegroundColor White
    
    exit 0
}
else {
    Write-Host ""
    Write-Host "✗ SYSTEM VALIDATION FAILED" -ForegroundColor Red
    Write-Host "Please address the failed tests above before proceeding." -ForegroundColor Red
    
    exit 1
}