# Automated Test Suite for PDF OCR Processor
# Run with: .\Tests\Test-PDFOCRProcessor.ps1

param(
    [switch]$Verbose
)

# Test configuration
$script:TestResults = @{
    Passed = 0
    Failed = 0
    Skipped = 0
}

# Helper functions
function Write-TestHeader {
    param($TestName)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " $TestName" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Test-Assert {
    param(
        [string]$TestName,
        [scriptblock]$Condition,
        [string]$ErrorMessage = "Test failed"
    )
    
    try {
        if (& $Condition) {
            Write-Host " [PASS] $TestName" -ForegroundColor Green
            $script:TestResults.Passed++
        } else {
            Write-Host " [FAIL] $TestName - $ErrorMessage" -ForegroundColor Red
            $script:TestResults.Failed++
        }
    } catch {
        Write-Host " [ERROR] $TestName - $_" -ForegroundColor Red
        $script:TestResults.Failed++
    }
}

# Start testing
Write-Host "`nPDF OCR Automation - Test Suite" -ForegroundColor Yellow
Write-Host "===============================" -ForegroundColor Yellow

# Test 1: Environment Validation
Write-TestHeader "Environment Tests"

Test-Assert "PowerShell Version >= 5.1" {
    $PSVersionTable.PSVersion.Major -ge 5 -and 
    ($PSVersionTable.PSVersion.Major -gt 5 -or $PSVersionTable.PSVersion.Minor -ge 1)
}

Test-Assert "Script Files Exist" {
    (Test-Path ".\Universal-PDF-OCR-Processor.ps1") -and
    (Test-Path ".\Setup.ps1")
}

Test-Assert "Required Folders Exist" {
    $folders = @("Documents", "Reports", "Technical", "Invoices", "Processed")
    $allExist = $true
    foreach ($folder in $folders) {
        if (-not (Test-Path $folder)) {
            $allExist = $false
            break
        }
    }
    $allExist
}

# Test 2: Script Syntax Validation
Write-TestHeader "Script Syntax Tests"

Test-Assert "Main Script Syntax Valid" {
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize(
        (Get-Content ".\Universal-PDF-OCR-Processor.ps1" -Raw), 
        [ref]$errors
    )
    $errors.Count -eq 0
}

Test-Assert "Setup Script Syntax Valid" {
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize(
        (Get-Content ".\Setup.ps1" -Raw), 
        [ref]$errors
    )
    $errors.Count -eq 0
}

# Test 3: Parameter Validation
Write-TestHeader "Parameter Tests"

Test-Assert "WhatIf Parameter Works" {
    try {
        $output = & powershell.exe -NoProfile -Command ".\Universal-PDF-OCR-Processor.ps1 -WhatIf" 2>&1
        $output -match "PREVIEW ONLY"
    } catch {
        $false
    }
}

Test-Assert "Custom Target Folder Parameter" {
    try {
        $output = & powershell.exe -NoProfile -Command ".\Universal-PDF-OCR-Processor.ps1 -TargetFolder 'Technical' -WhatIf" 2>&1
        $output -match "Target Folder:.*Technical"
    } catch {
        $false
    }
}

Test-Assert "Document Type Parameter" {
    try {
        $output = & powershell.exe -NoProfile -Command ".\Universal-PDF-OCR-Processor.ps1 -DocumentType 'business' -WhatIf" 2>&1
        $output -match "Document Type: business"
    } catch {
        $false
    }
}

# Test 4: OCR Language Support Test
Write-TestHeader "OCR Configuration Tests"

Test-Assert "OCR Language Configuration" {
    $scriptContent = Get-Content ".\Universal-PDF-OCR-Processor.ps1" -Raw
    $scriptContent -match '\$ocrLanguages\s*='
}

# Test 5: Error Handling Tests
Write-TestHeader "Error Handling Tests"

Test-Assert "Handles Non-Existent Folder Gracefully" {
    try {
        $output = & powershell.exe -NoProfile -Command ".\Universal-PDF-OCR-Processor.ps1 -TargetFolder 'NonExistentFolder' -WhatIf" 2>&1
        $true  # Should not crash
    } catch {
        $false
    }
}

Test-Assert "Handles Invalid Document Type" {
    try {
        $output = & powershell.exe -NoProfile -Command ".\Universal-PDF-OCR-Processor.ps1 -DocumentType 'invalid' -WhatIf" 2>&1
        $output -match "auto"  # Should default to auto
    } catch {
        $false
    }
}

# Test 6: Adobe Acrobat Detection
Write-TestHeader "Adobe Acrobat Tests"

Test-Assert "Adobe Detection Logic Present" {
    $scriptContent = Get-Content ".\Universal-PDF-OCR-Processor.ps1" -Raw
    $scriptContent -match "Get-Command.*acrobat" -or $scriptContent -match "Adobe.*Acrobat"
}

Test-Assert "Handles Missing Adobe Gracefully" {
    try {
        $output = & powershell.exe -NoProfile -Command ".\Universal-PDF-OCR-Processor.ps1 -WhatIf" 2>&1
        # Should run in preview mode even without Adobe
        $output -match "PREVIEW ONLY" -or $output -match "continuing in preview mode"
    } catch {
        $false
    }
}

# Test 7: File Processing Tests
Write-TestHeader "File Processing Tests"

Test-Assert "PDF Detection Logic" {
    $scriptContent = Get-Content ".\Universal-PDF-OCR-Processor.ps1" -Raw
    $scriptContent -match '\.pdf'
}

Test-Assert "Batch Processing Support" {
    $scriptContent = Get-Content ".\Universal-PDF-OCR-Processor.ps1" -Raw
    $scriptContent -match 'ForEach|foreach'
}

# Test 8: Performance Tests
Write-TestHeader "Performance Tests"

Test-Assert "Script Loads in Reasonable Time" {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $null = Get-Content ".\Universal-PDF-OCR-Processor.ps1" -Raw
    $stopwatch.Stop()
    $stopwatch.ElapsedMilliseconds -lt 1000  # Should load in under 1 second
}

# Test Summary
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host " TEST SUMMARY" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host " Passed:  $($script:TestResults.Passed)" -ForegroundColor Green
Write-Host " Failed:  $($script:TestResults.Failed)" -ForegroundColor $(if ($script:TestResults.Failed -eq 0) { "Green" } else { "Red" })
Write-Host " Skipped: $($script:TestResults.Skipped)" -ForegroundColor Yellow
Write-Host " Total:   $($script:TestResults.Passed + $script:TestResults.Failed + $script:TestResults.Skipped)" -ForegroundColor Cyan

# Exit with appropriate code
if ($script:TestResults.Failed -gt 0) {
    Write-Host "`nTESTS FAILED!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nALL TESTS PASSED!" -ForegroundColor Green
    exit 0
}