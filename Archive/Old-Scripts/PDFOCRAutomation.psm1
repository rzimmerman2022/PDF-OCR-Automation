# PDF OCR Automation PowerShell Module
# Main module file that exports functions

# Get the module directory
$script:ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import the main script
. "$script:ModuleRoot\Universal-PDF-OCR-Processor.ps1"

<#
.SYNOPSIS
    Starts the PDF OCR processor with specified parameters.
.DESCRIPTION
    Main function to process PDF files with OCR and intelligent renaming.
.EXAMPLE
    Start-PDFOCRProcessor -TargetFolder "C:\Documents" -DocumentType business
#>
function Start-PDFOCRProcessor {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$TargetFolder = ".\Documents",
        
        [ValidateSet("auto", "business", "invoice", "legal", "technical", "general")]
        [string]$DocumentType = "auto",
        
        [ValidateSet("eng", "spa", "fra", "deu", "ita", "por", "rus", "chi_sim", "chi_tra", "jpn", "kor", "ara", "multi")]
        [string]$OCRLanguage = "eng",
        
        [switch]$WhatIf,
        
        [switch]$DetailedOutput
    )
    
    # Call the main script with parameters
    & "$script:ModuleRoot\Universal-PDF-OCR-Processor.ps1" `
        -TargetFolder $TargetFolder `
        -DocumentType $DocumentType `
        -OCRLanguage $OCRLanguage `
        -WhatIf:$WhatIf `
        -DetailedOutput:$DetailedOutput
}

<#
.SYNOPSIS
    Tests the PDF OCR environment and prerequisites.
.DESCRIPTION
    Validates that all requirements are met for PDF OCR processing.
.EXAMPLE
    Test-PDFOCREnvironment
#>
function Test-PDFOCREnvironment {
    [CmdletBinding()]
    param()
    
    Write-Host "Testing PDF OCR Environment..." -ForegroundColor Cyan
    
    $results = @{
        PowerShellVersion = $false
        AdobeAcrobat = $false
        RequiredFolders = $false
        ScriptIntegrity = $false
    }
    
    # Test PowerShell version
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        $results.PowerShellVersion = $true
        Write-Host "✓ PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
    } else {
        Write-Host "✗ PowerShell version too old: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    }
    
    # Test Adobe Acrobat
    if (Get-Command acrobat.exe -ErrorAction SilentlyContinue) {
        $results.AdobeAcrobat = $true
        Write-Host "✓ Adobe Acrobat Pro found" -ForegroundColor Green
    } else {
        Write-Host "✗ Adobe Acrobat Pro not found" -ForegroundColor Red
        Write-Host "  Run: Add-AdobeToPath" -ForegroundColor Yellow
    }
    
    # Test folders
    $folders = @("Documents", "Reports", "Technical", "Invoices", "Processed")
    $allFoldersExist = $true
    foreach ($folder in $folders) {
        if (-not (Test-Path "$script:ModuleRoot\$folder")) {
            $allFoldersExist = $false
        }
    }
    $results.RequiredFolders = $allFoldersExist
    
    if ($allFoldersExist) {
        Write-Host "✓ All required folders exist" -ForegroundColor Green
    } else {
        Write-Host "✗ Some folders missing - run Setup.ps1" -ForegroundColor Red
    }
    
    # Test script integrity
    $mainScript = "$script:ModuleRoot\Universal-PDF-OCR-Processor.ps1"
    if (Test-Path $mainScript) {
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $mainScript -Raw), [ref]$errors)
        if ($errors.Count -eq 0) {
            $results.ScriptIntegrity = $true
            Write-Host "✓ Script syntax valid" -ForegroundColor Green
        } else {
            Write-Host "✗ Script has syntax errors" -ForegroundColor Red
        }
    }
    
    # Summary
    $passedTests = ($results.Values | Where-Object {$_}).Count
    $totalTests = $results.Count
    
    Write-Host "`nEnvironment Test Summary: $passedTests/$totalTests passed" -ForegroundColor $(
        if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" }
    )
    
    return $results
}

<#
.SYNOPSIS
    Adds Adobe Acrobat to system PATH.
.DESCRIPTION
    Searches for Adobe Acrobat installation and adds it to PATH.
.EXAMPLE
    Add-AdobeToPath
#>
function Add-AdobeToPath {
    [CmdletBinding()]
    param()
    
    & "$script:ModuleRoot\Add-AdobeToPath.ps1"
}

<#
.SYNOPSIS
    Gets statistics about PDF processing operations.
.DESCRIPTION
    Analyzes log files and provides statistics about OCR operations.
.EXAMPLE
    Get-PDFOCRStatistics -Days 30
#>
function Get-PDFOCRStatistics {
    [CmdletBinding()]
    param(
        [int]$Days = 7
    )
    
    Write-Host "PDF OCR Processing Statistics (Last $Days days)" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    # Get processed files from all folders
    $cutoffDate = (Get-Date).AddDays(-$Days)
    $processedFiles = @()
    
    $folders = @("Documents", "Reports", "Technical", "Invoices", "Processed")
    foreach ($folder in $folders) {
        $path = Join-Path $script:ModuleRoot $folder
        if (Test-Path $path) {
            $files = Get-ChildItem -Path $path -Filter "*.pdf" | 
                     Where-Object {$_.LastWriteTime -ge $cutoffDate}
            $processedFiles += $files
        }
    }
    
    # Calculate statistics
    $stats = @{
        TotalFiles = $processedFiles.Count
        TotalSizeMB = [Math]::Round(($processedFiles | Measure-Object Length -Sum).Sum / 1MB, 2)
        ByType = @{}
        ByLanguage = @{}
        DailyAverage = [Math]::Round($processedFiles.Count / [Math]::Max($Days, 1), 1)
    }
    
    # Analyze file patterns
    foreach ($file in $processedFiles) {
        if ($file.Name -match '^\d{4}-\d{2}-\d{2}_(\w+)_') {
            $type = $matches[1]
            if (-not $stats.ByType.ContainsKey($type)) {
                $stats.ByType[$type] = 0
            }
            $stats.ByType[$type]++
        }
    }
    
    # Display statistics
    Write-Host "`nTotal Processed: $($stats.TotalFiles) files ($($stats.TotalSizeMB) MB)"
    Write-Host "Daily Average: $($stats.DailyAverage) files/day"
    
    if ($stats.ByType.Count -gt 0) {
        Write-Host "`nBy Document Type:" -ForegroundColor Yellow
        foreach ($type in $stats.ByType.Keys | Sort-Object) {
            Write-Host "  $type`: $($stats.ByType[$type]) files"
        }
    }
    
    # Recent files
    if ($processedFiles.Count -gt 0) {
        Write-Host "`nMost Recent Files:" -ForegroundColor Yellow
        $processedFiles | Sort-Object LastWriteTime -Descending | 
                         Select-Object -First 5 | 
                         ForEach-Object {
                             Write-Host "  $($_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) - $($_.Name)"
                         }
    }
    
    return $stats
}

<#
.SYNOPSIS
    Installs PDF OCR Automation to specified location.
.DESCRIPTION
    Runs the installation script with optional parameters.
.EXAMPLE
    Install-PDFOCRAutomation -InstallPath "C:\Tools\PDFAutomation" -AddToPath
#>
function Install-PDFOCRAutomation {
    [CmdletBinding()]
    param(
        [string]$InstallPath = "$env:USERPROFILE\Documents\PDF-OCR-Automation",
        [switch]$AddToPath,
        [switch]$CreateShortcut
    )
    
    & "$script:ModuleRoot\Install-PDFOCRAutomation.ps1" `
        -InstallPath $InstallPath `
        -AddToPath:$AddToPath `
        -CreateShortcut:$CreateShortcut
}

# Create aliases
New-Alias -Name Process-PDFs -Value Start-PDFOCRProcessor -Force
New-Alias -Name OCR-PDFs -Value Start-PDFOCRProcessor -Force

# Export module members
Export-ModuleMember -Function * -Alias *