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
    # Try to find Adobe in common locations
    $adobePaths = @(
        "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe",
        "C:\Program Files (x86)\Adobe\Acrobat DC\Acrobat\Acrobat.exe",
        "C:\Program Files\Adobe\Acrobat 2020\Acrobat\Acrobat.exe"
    )
    
    $found = $false
    foreach ($path in $adobePaths) {
        if (Test-Path $path) {
            Write-Warning "Adobe Acrobat Pro found but not on PATH: $path"
            Write-Host "Run .\Add-AdobeToPath.ps1 to add it to your PATH" -ForegroundColor Yellow
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        Write-Warning "Adobe Acrobat Pro not found"
        Write-Host "Please install Adobe Acrobat Pro (not Reader) to use OCR features" -ForegroundColor Yellow
    }
} else {
    Write-Host " Found Adobe Acrobat at: $acroExe" -ForegroundColor Green
}

# Create default folders
$folders = @("Reports", "Technical", "Invoices", "Documents", "Processed")
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
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content "Universal-PDF-OCR-Processor.ps1" -Raw), [ref]$null)
    Write-Host " Main script syntax is valid" -ForegroundColor Green
} catch {
    Write-Error "Script syntax error: $_"
}

Write-Host "`nSetup complete!" -ForegroundColor Green
Write-Host "To test: .\Universal-PDF-OCR-Processor.ps1 -WhatIf" -ForegroundColor Cyan
Write-Host "To run:  .\Universal-PDF-OCR-Processor.ps1" -ForegroundColor Cyan
