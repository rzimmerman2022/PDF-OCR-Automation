# PDF OCR Automation Suite - Installer Script
# This script sets up the PDF OCR Automation environment

param(
    [string]$InstallPath = "$env:USERPROFILE\Documents\PDF-OCR-Automation",
    [switch]$AddToPath,
    [switch]$CreateShortcut
)

Write-Host @"

╔═══════════════════════════════════════════════════════════════════╗
║             PDF OCR AUTOMATION SUITE - INSTALLER                  ║
║           Universal Document Processing with Adobe Acrobat        ║
╚═══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin -and $AddToPath) {
    Write-Warning "Adding to PATH requires administrator privileges. Please run as administrator."
    $AddToPath = $false
}

# Step 1: Check prerequisites
Write-Host "`n[1/7] Checking prerequisites..." -ForegroundColor Yellow

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "PowerShell 5.1 or later is required. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}
Write-Host "  ✓ PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# Check for Adobe Acrobat
$adobeFound = $false
$adobePaths = @(
    "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe",
    "C:\Program Files (x86)\Adobe\Acrobat DC\Acrobat\Acrobat.exe",
    "C:\Program Files\Adobe\Acrobat 2020\Acrobat\Acrobat.exe"
)

foreach ($path in $adobePaths) {
    if (Test-Path $path) {
        Write-Host "  ✓ Adobe Acrobat Pro found at: $path" -ForegroundColor Green
        $adobeFound = $true
        $adobePath = Split-Path $path -Parent
        break
    }
}

if (-not $adobeFound) {
    Write-Warning "  ⚠ Adobe Acrobat Pro not found. OCR features will not work without it."
    Write-Host "    Please install Adobe Acrobat Pro from: https://www.adobe.com/acrobat/acrobat-pro.html" -ForegroundColor Yellow
}

# Step 2: Create installation directory
Write-Host "`n[2/7] Creating installation directory..." -ForegroundColor Yellow

if (Test-Path $InstallPath) {
    Write-Host "  ! Installation directory already exists: $InstallPath" -ForegroundColor Yellow
    $response = Read-Host "  Do you want to update the existing installation? (Y/N)"
    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host "Installation cancelled." -ForegroundColor Red
        exit 0
    }
} else {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    Write-Host "  ✓ Created: $InstallPath" -ForegroundColor Green
}

# Step 3: Copy files
Write-Host "`n[3/7] Copying files..." -ForegroundColor Yellow

$filesToCopy = @(
    "Universal-PDF-OCR-Processor.ps1",
    "Setup.ps1",
    "Add-AdobeToPath.ps1",
    "README.md",
    "SUMMARY.md",
    "LICENSE",
    "TROUBLESHOOTING.md",
    "OCR-OPTIMIZATION.md"
)

$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path

foreach ($file in $filesToCopy) {
    $sourcePath = Join-Path $currentPath $file
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $InstallPath -Force
        Write-Host "  ✓ Copied: $file" -ForegroundColor Green
    } else {
        Write-Warning "  ⚠ File not found: $file"
    }
}

# Copy directories
$directoriesToCopy = @("Templates", "Examples", "Tests", "Test-PDFs")
foreach ($dir in $directoriesToCopy) {
    $sourcePath = Join-Path $currentPath $dir
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $InstallPath -Recurse -Force
        Write-Host "  ✓ Copied directory: $dir" -ForegroundColor Green
    }
}

# Step 4: Create working directories
Write-Host "`n[4/7] Creating working directories..." -ForegroundColor Yellow

$workingDirs = @("Documents", "Reports", "Technical", "Invoices", "Processed")
foreach ($dir in $workingDirs) {
    $dirPath = Join-Path $InstallPath $dir
    if (-not (Test-Path $dirPath)) {
        New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
        Write-Host "  ✓ Created: $dir" -ForegroundColor Green
    }
}

# Step 5: Add to PATH (if requested)
if ($AddToPath) {
    Write-Host "`n[5/7] Adding to system PATH..." -ForegroundColor Yellow
    
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if ($currentPath -notlike "*$InstallPath*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$InstallPath", "Machine")
        Write-Host "  ✓ Added to system PATH" -ForegroundColor Green
        Write-Host "  ! You may need to restart your terminal for PATH changes to take effect" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ Already in PATH" -ForegroundColor Green
    }
    
    # Also add Adobe to PATH if found
    if ($adobeFound -and $adobePath -and $currentPath -notlike "*$adobePath*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$adobePath", "Machine")
        Write-Host "  ✓ Added Adobe Acrobat to PATH" -ForegroundColor Green
    }
} else {
    Write-Host "`n[5/7] Skipping PATH configuration (requires admin or -AddToPath flag)" -ForegroundColor Gray
}

# Step 6: Create shortcuts (if requested)
if ($CreateShortcut) {
    Write-Host "`n[6/7] Creating shortcuts..." -ForegroundColor Yellow
    
    $WshShell = New-Object -ComObject WScript.Shell
    
    # Desktop shortcut
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcut = $WshShell.CreateShortcut("$desktopPath\PDF OCR Processor.lnk")
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-NoExit -ExecutionPolicy Bypass -File `"$InstallPath\Universal-PDF-OCR-Processor.ps1`""
    $shortcut.WorkingDirectory = $InstallPath
    $shortcut.IconLocation = "shell32.dll,69"
    $shortcut.Description = "Universal PDF OCR Processor"
    $shortcut.Save()
    Write-Host "  ✓ Created desktop shortcut" -ForegroundColor Green
    
    # Start Menu shortcut
    $startMenuPath = [Environment]::GetFolderPath("StartMenu")
    $programsPath = Join-Path $startMenuPath "Programs\PDF OCR Automation"
    if (-not (Test-Path $programsPath)) {
        New-Item -ItemType Directory -Path $programsPath -Force | Out-Null
    }
    
    $shortcut = $WshShell.CreateShortcut("$programsPath\PDF OCR Processor.lnk")
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-NoExit -ExecutionPolicy Bypass -File `"$InstallPath\Universal-PDF-OCR-Processor.ps1`""
    $shortcut.WorkingDirectory = $InstallPath
    $shortcut.IconLocation = "shell32.dll,69"
    $shortcut.Description = "Universal PDF OCR Processor"
    $shortcut.Save()
    Write-Host "  ✓ Created Start Menu shortcut" -ForegroundColor Green
} else {
    Write-Host "`n[6/7] Skipping shortcut creation (use -CreateShortcut flag to enable)" -ForegroundColor Gray
}

# Step 7: Verify installation
Write-Host "`n[7/7] Verifying installation..." -ForegroundColor Yellow

# Run setup script
$setupScript = Join-Path $InstallPath "Setup.ps1"
if (Test-Path $setupScript) {
    Write-Host "  Running setup verification..." -ForegroundColor Gray
    Push-Location $InstallPath
    & $setupScript
    Pop-Location
}

# Create a batch file for easy execution
$batchContent = @"
@echo off
cd /d "$InstallPath"
powershell.exe -NoExit -ExecutionPolicy Bypass -File "Universal-PDF-OCR-Processor.ps1" %*
"@
$batchContent | Out-File "$InstallPath\PDF-OCR-Processor.bat" -Encoding ASCII
Write-Host "  ✓ Created batch file for easy execution" -ForegroundColor Green

# Installation summary
Write-Host "`n" + "="*70 -ForegroundColor Cyan
Write-Host " INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "="*70 -ForegroundColor Cyan

Write-Host "`nInstallation Location: $InstallPath" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Navigate to: $InstallPath"
Write-Host "2. Run: .\Universal-PDF-OCR-Processor.ps1 -WhatIf"
Write-Host "3. Or use the batch file: PDF-OCR-Processor.bat"

if ($CreateShortcut) {
    Write-Host "`nShortcuts created on Desktop and Start Menu" -ForegroundColor Green
}

if (-not $adobeFound) {
    Write-Host "`nIMPORTANT: Install Adobe Acrobat Pro for OCR functionality" -ForegroundColor Yellow
}

Write-Host "`nFor help and documentation, see:" -ForegroundColor Cyan
Write-Host "- README.md - General documentation"
Write-Host "- TROUBLESHOOTING.md - Common issues and solutions"
Write-Host "- OCR-OPTIMIZATION.md - Performance tips"

Write-Host "`nEnjoy processing your PDFs!" -ForegroundColor Green