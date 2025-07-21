#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick Start wrapper for PDF Processing Engine
    User-friendly interface with clear help and parameter handling

.DESCRIPTION
    Simplified interface for the complete PDF processing pipeline.
    Provides setup, dry run testing, and live processing modes.

.PARAMETER Setup
    Run setup wizard to configure API key

.PARAMETER DryRun
    Preview what would be renamed without making changes

.PARAMETER Process
    Actually rename files (skips dry run for cost savings)

.PARAMETER BatchSize
    Number of files to process in each batch (default: 5)

.PARAMETER Folder
    Target folder containing PDF files (defaults to current directory)

.EXAMPLE
    .\Quick-Start.ps1 -Setup
    Set up API key

.EXAMPLE
    .\Quick-Start.ps1 -DryRun
    Preview what would be renamed

.EXAMPLE
    .\Quick-Start.ps1 -Process
    Actually rename files (skips dry run)

.EXAMPLE
    .\Quick-Start.ps1 -Process -Folder "C:\MyPDFs" -BatchSize 10
    Process specific folder with larger batch size
#>

param(
    [switch]$Setup,
    [switch]$DryRun,
    [switch]$Process,
    [int]$BatchSize = 5,
    [string]$Folder = ""
)

$script:ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Show-Help {
    Write-Host ""
    Write-Host "PDF Analysis - Quick Start" -ForegroundColor Cyan
    Write-Host "==========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\Quick-Start.ps1 -Setup        # Set up API key" -ForegroundColor White
    Write-Host "  .\Quick-Start.ps1 -DryRun       # Preview what would be renamed" -ForegroundColor White
    Write-Host "  .\Quick-Start.ps1 -Process      # Actually rename files (skips dry run)" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONAL PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -Folder <path>                  # Specify target folder" -ForegroundColor White
    Write-Host "  -BatchSize <number>             # Files per batch (default: 5)" -ForegroundColor White
    Write-Host ""
    Write-Host "RECOMMENDED WORKFLOW:" -ForegroundColor Cyan
    Write-Host "1. Run setup once: .\Quick-Start.ps1 -Setup" -ForegroundColor White
    Write-Host "2. Test with dry run: .\Quick-Start.ps1 -DryRun" -ForegroundColor White
    Write-Host "3. Process files: .\Quick-Start.ps1 -Process" -ForegroundColor White
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\Quick-Start.ps1 -Setup" -ForegroundColor Gray
    Write-Host "  .\Quick-Start.ps1 -DryRun -Folder 'C:\MyPDFs'" -ForegroundColor Gray
    Write-Host "  .\Quick-Start.ps1 -Process -BatchSize 10" -ForegroundColor Gray
    Write-Host ""
}

function Invoke-Setup {
    Write-Host ""
    Write-Host "=== API KEY SETUP ===" -ForegroundColor Cyan
    Write-Host ""
    
    $envFile = Join-Path $script:ScriptRoot ".env"
    $existingKey = $null
    
    # Check for existing API key
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^GEMINI_API_KEY=(.+)$') {
                $existingKey = $matches[1].Trim().Trim('"').Trim("'")
            }
        }
    }
    
    if ($existingKey) {
        $keyPreview = $existingKey.Substring(0, [Math]::Min(10, $existingKey.Length)) + "..."
        Write-Host "Existing API key found: $keyPreview" -ForegroundColor Green
        
        do {
            $response = Read-Host "Keep existing key? (y/n)"
            $response = $response.ToLower()
        } while ($response -notin @("y", "yes", "n", "no"))
        
        if ($response -in @("y", "yes")) {
            Write-Host "Using existing API key" -ForegroundColor Green
            return
        }
    }
    
    # Get new API key
    Write-Host "To get a Gemini API key:" -ForegroundColor Yellow
    Write-Host "1. Go to https://makersuite.google.com/app/apikey" -ForegroundColor White
    Write-Host "2. Create a new API key" -ForegroundColor White
    Write-Host "3. Copy the key and paste it below" -ForegroundColor White
    Write-Host ""
    
    $newKey = Read-Host "Enter your Gemini API key" -AsSecureString
    $plainKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($newKey))
    
    if ($plainKey -and $plainKey.Length -gt 10) {
        # Save to .env file
        $envContent = "GEMINI_API_KEY=$plainKey"
        Set-Content -Path $envFile -Value $envContent -Encoding UTF8
        
        Write-Host ""
        Write-Host "API key saved successfully!" -ForegroundColor Green
        Write-Host "File: $envFile" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Test with: .\Quick-Start.ps1 -DryRun" -ForegroundColor White
        Write-Host "2. Process files: .\Quick-Start.ps1 -Process" -ForegroundColor White
    }
    else {
        Write-Host "Invalid API key. Please try again." -ForegroundColor Red
        exit 1
    }
}

function Invoke-DryRun {
    param([string]$TargetFolder)
    
    Write-Host ""
    Write-Host "=== DRY RUN MODE ===" -ForegroundColor Yellow
    Write-Host "This will preview what would be renamed without making changes" -ForegroundColor White
    Write-Host ""
    
    $mainScript = Join-Path $script:ScriptRoot "Process-PDFs-Complete.ps1"
    if (-not (Test-Path $mainScript)) {
        Write-Host "ERROR: Main processing script not found: $mainScript" -ForegroundColor Red
        exit 1
    }
    
    # Build parameters
    $params = @{
        TargetFolder = $TargetFolder
        BatchSize = $BatchSize
        AutoConfirm = $true
    }
    
    try {
        & $mainScript @params
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

function Invoke-Processing {
    param([string]$TargetFolder)
    
    Write-Host ""
    Write-Host "=== LIVE PROCESSING MODE ===" -ForegroundColor Green
    Write-Host "This will actually rename files (skips dry run to save costs)" -ForegroundColor White
    Write-Host ""
    
    $mainScript = Join-Path $script:ScriptRoot "Process-PDFs-Complete.ps1"
    if (-not (Test-Path $mainScript)) {
        Write-Host "ERROR: Main processing script not found: $mainScript" -ForegroundColor Red
        exit 1
    }
    
    # Build parameters
    $params = @{
        TargetFolder = $TargetFolder
        BatchSize = $BatchSize
        AutoConfirm = $true
        SkipDryRun = $true
    }
    
    try {
        & $mainScript @params
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

function Get-TargetFolder {
    param([string]$ProvidedFolder)
    
    if ($ProvidedFolder) {
        if (Test-Path $ProvidedFolder) {
            return $ProvidedFolder
        }
        else {
            Write-Host "ERROR: Specified folder does not exist: $ProvidedFolder" -ForegroundColor Red
            exit 1
        }
    }
    
    # Default to current directory
    $currentDir = Get-Location
    $pdfCount = (Get-ChildItem -Path $currentDir -Filter "*.pdf" -Recurse).Count
    
    if ($pdfCount -eq 0) {
        Write-Host "WARNING: No PDF files found in current directory" -ForegroundColor Yellow
        Write-Host "Current directory: $currentDir" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Specify a folder with: -Folder 'C:\Path\To\PDFs'" -ForegroundColor White
        exit 1
    }
    
    Write-Host "Using current directory: $currentDir" -ForegroundColor Gray
    Write-Host "Found $pdfCount PDF files" -ForegroundColor Green
    
    return $currentDir
}

# Main execution
try {
    # Show header
    Write-Host ""
    Write-Host "PDF Processing - Quick Start" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    
    # Determine mode
    $modeCount = @($Setup, $DryRun, $Process).Where({ $_ }).Count
    
    if ($modeCount -eq 0) {
        # No mode specified - show help
        Show-Help
        exit 0
    }
    elseif ($modeCount -gt 1) {
        Write-Host ""
        Write-Host "ERROR: Please specify only one mode (-Setup, -DryRun, or -Process)" -ForegroundColor Red
        Show-Help
        exit 1
    }
    
    # Execute based on mode
    if ($Setup) {
        Invoke-Setup
    }
    elseif ($DryRun) {
        $targetFolder = Get-TargetFolder -ProvidedFolder $Folder
        Invoke-DryRun -TargetFolder $targetFolder
    }
    elseif ($Process) {
        $targetFolder = Get-TargetFolder -ProvidedFolder $Folder
        Invoke-Processing -TargetFolder $targetFolder
    }
}
catch {
    Write-Host ""
    Write-Host "FATAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}