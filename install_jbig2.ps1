# Install jbig2 encoder for optimal PDF compression
# This is required for gold standard OCR processing

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "JBIG2 ENCODER INSTALLATION" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[WARNING] This script should be run as Administrator for best results" -ForegroundColor Yellow
    Write-Host ""
}

# Create tools directory if it doesn't exist
$toolsDir = "C:\Tools"
if (!(Test-Path $toolsDir)) {
    Write-Host "[INFO] Creating tools directory: $toolsDir" -ForegroundColor Green
    New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
}

# jbig2enc GitHub releases URL
$jbig2ReleasesUrl = "https://github.com/agl/jbig2enc/releases"

Write-Host "[INFO] Installing jbig2 encoder..." -ForegroundColor Green
Write-Host ""

# Method 1: Try downloading pre-built Windows binary
Write-Host "Method 1: Checking for pre-built Windows binary..." -ForegroundColor Cyan

# Download and extract jbig2enc
$jbig2Dir = "$toolsDir\jbig2enc"
if (!(Test-Path $jbig2Dir)) {
    New-Item -ItemType Directory -Path $jbig2Dir -Force | Out-Null
}

# Since pre-built Windows binaries are rare, we'll use an alternative approach
# Method 2: Install via Chocolatey if available
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "[INFO] Chocolatey detected. Installing jbig2 via Chocolatey..." -ForegroundColor Green
    choco install jbig2 -y
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] jbig2 installed via Chocolatey" -ForegroundColor Green
    }
} else {
    Write-Host "[INFO] Chocolatey not found. Trying alternative methods..." -ForegroundColor Yellow
}

# Method 3: Install via Anaconda/Conda if available
if (Get-Command conda -ErrorAction SilentlyContinue) {
    Write-Host "[INFO] Conda detected. Installing jbig2 via Conda..." -ForegroundColor Green
    conda install -c conda-forge jbig2enc -y
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] jbig2 installed via Conda" -ForegroundColor Green
    }
}

# Method 4: Download pre-compiled Windows binary from alternative sources
Write-Host ""
Write-Host "Method 4: Downloading Windows binary from alternative sources..." -ForegroundColor Cyan

# Alternative: Use img2pdf which includes jbig2 support
Write-Host "[INFO] Installing img2pdf with jbig2 support..." -ForegroundColor Green
pip install img2pdf[jbig2]

# Install additional jbig2 Python wrapper
Write-Host "[INFO] Installing Python jbig2 wrapper..." -ForegroundColor Green
pip install jbig2

# Method 5: Build from source (requires build tools)
Write-Host ""
Write-Host "Method 5: Build from source instructions:" -ForegroundColor Cyan
Write-Host "If the above methods don't work, you can build jbig2enc from source:" -ForegroundColor Yellow
Write-Host "1. Install Visual Studio Build Tools or MinGW" -ForegroundColor White
Write-Host "2. Clone repository: git clone https://github.com/agl/jbig2enc.git" -ForegroundColor White
Write-Host "3. Follow build instructions in the repository" -ForegroundColor White
Write-Host ""

# Add to PATH if installation successful
$paths = @(
    "$toolsDir\jbig2enc",
    "$env:LOCALAPPDATA\Programs\jbig2enc",
    "$env:ProgramFiles\jbig2enc",
    "$env:ProgramFiles(x86)\jbig2enc"
)

$jbig2Found = $false
foreach ($path in $paths) {
    if (Test-Path "$path\jbig2.exe") {
        Write-Host "[INFO] Found jbig2.exe at: $path" -ForegroundColor Green
        # Add to PATH if not already there
        if ($env:PATH -notlike "*$path*") {
            Write-Host "[INFO] Adding to PATH: $path" -ForegroundColor Green
            [Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$path", [EnvironmentVariableTarget]::User)
            $env:PATH = "$env:PATH;$path"
        }
        $jbig2Found = $true
        break
    }
}

# Verify installation
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "VERIFICATION" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

try {
    $jbig2Version = & jbig2 --version 2>&1
    if ($LASTEXITCODE -eq 0 -or $jbig2Version) {
        Write-Host "[SUCCESS] jbig2 is installed and accessible" -ForegroundColor Green
        Write-Host "Version: $jbig2Version" -ForegroundColor White
    } else {
        throw "jbig2 command not found"
    }
} catch {
    Write-Host "[WARNING] jbig2 command not found in PATH" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "MANUAL INSTALLATION REQUIRED:" -ForegroundColor Yellow
    Write-Host "1. Download jbig2enc from: $jbig2ReleasesUrl" -ForegroundColor White
    Write-Host "2. Extract to: $toolsDir\jbig2enc" -ForegroundColor White
    Write-Host "3. Add to PATH: $toolsDir\jbig2enc" -ForegroundColor White
    Write-Host "4. Restart PowerShell and run this script again" -ForegroundColor White
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "INSTALLATION COMPLETE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: You may need to restart your terminal for PATH changes to take effect" -ForegroundColor Yellow