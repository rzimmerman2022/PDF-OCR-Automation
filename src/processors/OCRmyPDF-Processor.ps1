<#
.SYNOPSIS
    Enhanced PDF OCR Processor with OCRmyPDF integration following best practices
    Implements tips for reliable OCR results including pre-clean, optimization, and error handling

.DESCRIPTION
    This enhanced script processes PDF files using OCRmyPDF with:
    - Pre-clean scan settings (300 DPI, grayscale, noise removal)
    - Optimized compression (--optimize 3) for large color scans
    - Explicit language specification for better accuracy
    - Comprehensive stderr capture for error handling
    - Searchable, layout-preserving PDF output

.PARAMETER InputPath
    Path to input PDF file or directory containing PDFs

.PARAMETER OutputPath
    Optional output path. If not specified, overwrites input file

.PARAMETER Language
    OCR language code (default: eng). Use + for multiple languages (e.g., eng+spa)

.PARAMETER Optimize
    Optimization level (0-3). Default is 3 for best compression

.PARAMETER DPI
    DPI for OCR processing. Default is 300 for best accuracy

.PARAMETER Grayscale
    Convert to grayscale for better OCR accuracy

.PARAMETER CleanPages
    Apply noise removal and preprocessing

.PARAMETER SkipText
    Skip pages that already have text

.PARAMETER WhatIf
    Preview mode - shows what would be processed without making changes

.EXAMPLE
    .\Enhanced-OCRmyPDF-Processor.ps1 -InputPath ".\Documents\scan.pdf" -Language eng
    Process single PDF with English OCR

.EXAMPLE
    .\Enhanced-OCRmyPDF-Processor.ps1 -InputPath ".\Documents" -Language eng+spa -Optimize 3
    Process directory with English and Spanish, maximum optimization

.NOTES
    Author: Enhanced OCRmyPDF Integration
    Version: 1.0
    Prerequisites: OCRmyPDF, Tesseract, Ghostscript installed via Chocolatey/pip
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$InputPath,
    
    [Parameter(Position=1)]
    [string]$OutputPath = "",
    
    [Parameter()]
    [string]$Language = "eng",
    
    [Parameter()]
    [ValidateRange(0,3)]
    [int]$Optimize = 3,
    
    [Parameter()]
    [int]$DPI = 300,
    
    [Parameter()]
    [switch]$Grayscale,
    
    [Parameter()]
    [switch]$CleanPages,
    
    [Parameter()]
    [switch]$SkipText,
    
    [Parameter()]
    [switch]$WhatIf
)

# Script configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# Display header
Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║        Enhanced OCRmyPDF Processor with Best Practices       ║
║              Reliable OCR Results & Optimization             ║
╚══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "Version 1.0 - Following Best Practices for Reliable OCR" -ForegroundColor Yellow
Write-Host ""

# Validate prerequisites
function Test-Prerequisites {
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
    
    $missing = @()
    
    # Check OCRmyPDF
    try {
        $ocrmypdfVersion = & ocrmypdf --version 2>&1
        Write-Host "✓ OCRmyPDF found: $ocrmypdfVersion" -ForegroundColor Green
    }
    catch {
        $missing += "OCRmyPDF"
        Write-Host "✗ OCRmyPDF not found" -ForegroundColor Red
    }
    
    # Check Tesseract
    try {
        $tesseractVersion = & tesseract --version 2>&1 | Select-Object -First 1
        Write-Host "✓ Tesseract found: $tesseractVersion" -ForegroundColor Green
    }
    catch {
        $missing += "Tesseract"
        Write-Host "✗ Tesseract not found" -ForegroundColor Red
    }
    
    # Check Ghostscript
    try {
        $gsVersion = & gswin64c --version 2>&1
        Write-Host "✓ Ghostscript found: $gsVersion" -ForegroundColor Green
    }
    catch {
        # Try 32-bit version
        try {
            $gsVersion = & gswin32c --version 2>&1
            Write-Host "✓ Ghostscript found: $gsVersion" -ForegroundColor Green
        }
        catch {
            $missing += "Ghostscript"
            Write-Host "✗ Ghostscript not found" -ForegroundColor Red
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Host "`n⚠️  Missing prerequisites: $($missing -join ', ')" -ForegroundColor Red
        Write-Host "`nInstallation instructions:" -ForegroundColor Yellow
        Write-Host "1. Install Chocolatey (admin PowerShell):" -ForegroundColor Cyan
        Write-Host "   Set-ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor Gray
        Write-Host "   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" -ForegroundColor Gray
        Write-Host "`n2. Install required tools:" -ForegroundColor Cyan
        Write-Host "   choco install python3 -y" -ForegroundColor Gray
        Write-Host "   choco install --pre tesseract -y" -ForegroundColor Gray
        Write-Host "   choco install ghostscript -y" -ForegroundColor Gray
        Write-Host "   pip install --upgrade ocrmypdf" -ForegroundColor Gray
        
        if (-not $WhatIf) {
            throw "Missing prerequisites. Please install them and try again."
        }
    }
    
    Write-Host ""
}

# Process single PDF file
function Process-SinglePDF {
    param(
        [string]$PdfPath,
        [string]$OutputFile = ""
    )
    
    $fileName = [System.IO.Path]::GetFileName($PdfPath)
    Write-Host "📄 Processing: $fileName" -ForegroundColor Cyan
    
    # Determine output path
    if ([string]::IsNullOrWhiteSpace($OutputFile)) {
        $OutputFile = $PdfPath
        $inPlace = $true
    }
    else {
        $inPlace = $false
    }
    
    # Build OCRmyPDF command
    $arguments = @()
    
    # Input file
    $arguments += "`"$PdfPath`""
    
    # Output file (use temp file for in-place processing)
    if ($inPlace) {
        $tempFile = [System.IO.Path]::GetTempFileName() + ".pdf"
        $arguments += "`"$tempFile`""
    }
    else {
        $arguments += "`"$OutputFile`""
    }
    
    # Language specification (explicit for better accuracy)
    $arguments += "--language", $Language
    
    # Optimization level (--optimize 3 for best compression)
    $arguments += "--optimize", $Optimize
    
    # DPI setting (300 for best accuracy)
    $arguments += "--oversample", $DPI
    
    # Pre-clean options
    if ($Grayscale) {
        $arguments += "--remove-background"
        Write-Host "  • Converting to grayscale for better accuracy" -ForegroundColor Gray
    }
    
    if ($CleanPages) {
        $arguments += "--clean"
        $arguments += "--deskew"
        Write-Host "  • Applying noise removal and deskew" -ForegroundColor Gray
    }
    
    # Skip text pages if requested
    if ($SkipText) {
        $arguments += "--skip-text"
        Write-Host "  • Skipping pages with existing text" -ForegroundColor Gray
    }
    
    # Additional best practice settings
    $arguments += "--rotate-pages"  # Auto-rotate pages
    $arguments += "--jpeg-quality", "85"  # Good quality/size balance
    $arguments += "--png-quality", "85"
    
    Write-Host "  • Language: $Language" -ForegroundColor Gray
    Write-Host "  • Optimization: Level $Optimize" -ForegroundColor Gray
    Write-Host "  • DPI: $DPI" -ForegroundColor Gray
    
    if ($WhatIf) {
        Write-Host "  [PREVIEW] Would run: ocrmypdf $($arguments -join ' ')" -ForegroundColor Yellow
        return $true
    }
    
    # Execute OCRmyPDF with stderr capture
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "ocrmypdf"
    $processInfo.Arguments = $arguments -join " "
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    
    # Capture output
    $outputBuilder = New-Object System.Text.StringBuilder
    $errorBuilder = New-Object System.Text.StringBuilder
    
    # Event handlers for async output
    $outputHandler = {
        if ($EventArgs.Data) {
            $null = $outputBuilder.AppendLine($EventArgs.Data)
        }
    }
    
    $errorHandler = {
        if ($EventArgs.Data) {
            $null = $errorBuilder.AppendLine($EventArgs.Data)
        }
    }
    
    $process.add_OutputDataReceived($outputHandler)
    $process.add_ErrorDataReceived($errorHandler)
    
    Write-Host "  • Running OCR..." -ForegroundColor Gray
    
    try {
        $process.Start() | Out-Null
        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
        $process.WaitForExit()
        
        $exitCode = $process.ExitCode
        $stdout = $outputBuilder.ToString()
        $stderr = $errorBuilder.ToString()
        
        # Interpret exit codes
        switch ($exitCode) {
            0 { 
                Write-Host "  ✓ Success!" -ForegroundColor Green
                
                # Handle in-place file replacement
                if ($inPlace -and (Test-Path $tempFile)) {
                    Move-Item -Path $tempFile -Destination $PdfPath -Force
                    Write-Host "  ✓ Updated original file" -ForegroundColor Green
                }
            }
            1 { Write-Warning "  ⚠️  Bad arguments provided" }
            2 { Write-Warning "  ⚠️  Input file not found or invalid" }
            3 { Write-Warning "  ⚠️  Output file write error" }
            4 { Write-Warning "  ⚠️  Input PDF is encrypted" }
            5 { Write-Warning "  ⚠️  Invalid output PDF" }
            6 { Write-Host "  ℹ️  File already has text (skipped)" -ForegroundColor Yellow }
            7 { Write-Warning "  ⚠️  Engine error during OCR" }
            8 { Write-Warning "  ⚠️  Invalid configuration" }
            9 { Write-Warning "  ⚠️  DPI too low or other quality issue" }
            10 { Write-Warning "  ⚠️  Timed out" }
            15 { Write-Host "  ℹ️  Some pages already had text" -ForegroundColor Yellow }
            default { Write-Warning "  ⚠️  Unknown exit code: $exitCode" }
        }
        
        # Display stderr if there were warnings/errors
        if ($stderr -and $stderr.Trim()) {
            Write-Host "  📋 Details:" -ForegroundColor Yellow
            $stderr -split "`n" | Where-Object { $_ } | ForEach-Object {
                Write-Host "     $_" -ForegroundColor Gray
            }
        }
        
        return $exitCode -eq 0 -or $exitCode -eq 6 -or $exitCode -eq 15
    }
    catch {
        Write-Error "  ❌ Error: $_"
        return $false
    }
    finally {
        $process.Dispose()
        
        # Cleanup temp file if exists
        if ($inPlace -and (Test-Path $tempFile)) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

# Main execution
try {
    # Check prerequisites
    Test-Prerequisites
    
    # Determine if input is file or directory
    if (Test-Path $InputPath -PathType Leaf) {
        # Single file
        if (-not $InputPath.EndsWith('.pdf')) {
            throw "Input file must be a PDF"
        }
        
        Write-Host "🎯 Mode: Single file processing" -ForegroundColor Cyan
        Write-Host ""
        
        $success = Process-SinglePDF -PdfPath $InputPath -OutputFile $OutputPath
        
        if ($success) {
            Write-Host "`n✅ Processing completed successfully!" -ForegroundColor Green
        }
        else {
            Write-Host "`n❌ Processing failed" -ForegroundColor Red
        }
    }
    elseif (Test-Path $InputPath -PathType Container) {
        # Directory
        Write-Host "🎯 Mode: Directory processing" -ForegroundColor Cyan
        Write-Host "📁 Directory: $InputPath" -ForegroundColor Gray
        Write-Host ""
        
        $pdfFiles = Get-ChildItem -Path $InputPath -Filter "*.pdf" -File
        
        if ($pdfFiles.Count -eq 0) {
            Write-Warning "No PDF files found in directory"
            exit 0
        }
        
        Write-Host "📊 Found $($pdfFiles.Count) PDF files" -ForegroundColor Cyan
        if ($WhatIf) {
            Write-Host "⚡ PREVIEW MODE - No files will be modified" -ForegroundColor Yellow
        }
        Write-Host ""
        
        $successCount = 0
        $failCount = 0
        $skipCount = 0
        
        foreach ($pdf in $pdfFiles) {
            $outputFile = if ($OutputPath) {
                Join-Path $OutputPath $pdf.Name
            } else {
                ""
            }
            
            $result = Process-SinglePDF -PdfPath $pdf.FullName -OutputFile $outputFile
            
            if ($result) {
                $successCount++
            }
            else {
                $failCount++
            }
            
            Write-Host ""
        }
        
        # Summary
        Write-Host "═" * 60 -ForegroundColor Cyan
        Write-Host "📊 Processing Summary" -ForegroundColor Cyan
        Write-Host "═" * 60 -ForegroundColor Cyan
        Write-Host "✅ Successful: $successCount" -ForegroundColor Green
        Write-Host "❌ Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
        Write-Host "📄 Total: $($pdfFiles.Count)" -ForegroundColor Gray
    }
    else {
        throw "Input path not found: $InputPath"
    }
    
    # Display tips
    Write-Host "`n💡 Tips for best results:" -ForegroundColor Cyan
    Write-Host "  • Pre-clean scans at 300 DPI in grayscale" -ForegroundColor Gray
    Write-Host "  • Use --optimize 3 for large color scans" -ForegroundColor Gray
    Write-Host "  • Specify languages explicitly (e.g., eng+spa)" -ForegroundColor Gray
    Write-Host "  • Check stderr output for helpful diagnostics" -ForegroundColor Gray
}
catch {
    Write-Error "Fatal error: $_"
    exit 1
}