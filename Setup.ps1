# PDF OCR Automation - Setup Script
# Run this after cloning the repository

Write-Host "PDF OCR Automation - Setup" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "PowerShell 5.1 or later required. Current version: $($PSVersionTable.PSVersion)"
    exit
}
Write-Host " PowerShell version OK: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# Check for Adobe Acrobat Pro
$acroExe = (Get-Command acrobat.exe -ErrorAction SilentlyContinue).Source
if (-not $acroExe) {
    Write-Warning "Adobe Acrobat Pro not found on PATH"
    Write-Host "Please install Adobe Acrobat Pro (not Reader) to use OCR features" -ForegroundColor Yellow
} else {
    Write-Host " Found Adobe Acrobat at: $acroExe" -ForegroundColor Green
}

# Create default folders
$folders = @("02_LabResults", "Invoices", "Documents", "Processed")
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
        Write-Host " Created folder: $folder" -ForegroundColor Green
    } else {
        Write-Host " Folder exists: $folder" -ForegroundColor Green
    }
}

# Test script syntax
Write-Host "`nTesting script syntax..." -ForegroundColor Yellow
try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content "PDF-OCR-Processor.ps1" -Raw), [ref]$null)
    Write-Host " Main script syntax is valid" -ForegroundColor Green
} catch {
    Write-Error "Script syntax error: $_"
}

Write-Host "`nSetup complete!" -ForegroundColor Green
Write-Host "To test: .\PDF-OCR-Processor.ps1 -WhatIf" -ForegroundColor Cyan
Write-Host "To run:  .\PDF-OCR-Processor.ps1" -ForegroundColor Cyan
