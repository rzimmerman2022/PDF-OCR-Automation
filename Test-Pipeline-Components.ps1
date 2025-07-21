#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test Pipeline Components - Verify system readiness for PDF processing

.DESCRIPTION
    Comprehensive system verification script that checks:
    - Python availability and version
    - Required Python packages
    - API key configuration
    - Target directories
    - File permissions
    - PowerShell modules

.PARAMETER Quick
    Run only essential checks (faster)

.PARAMETER Verbose
    Show detailed output for all checks

.EXAMPLE
    .\Test-Pipeline-Components.ps1
    Run all system checks

.EXAMPLE
    .\Test-Pipeline-Components.ps1 -Quick
    Run only essential checks

.EXAMPLE
    .\Test-Pipeline-Components.ps1 -Verbose
    Show detailed output
#>

param(
    [switch]$Quick,
    [switch]$Verbose
)

$script:ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:TestResults = @()

# Test result tracking
function Add-TestResult {
    param(
        [string]$Component,
        [string]$Test,
        [bool]$Passed,
        [string]$Message = "",
        [string]$Details = ""
    )
    
    $script:TestResults += [PSCustomObject]@{
        Component = $Component
        Test = $Test
        Passed = $Passed
        Message = $Message
        Details = $Details
        Timestamp = Get-Date
    }
    
    # Display result
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "[$status] $Component - $Test" -ForegroundColor $color
    if ($Message) {
        Write-Host "       $Message" -ForegroundColor Gray
    }
    if ($Verbose -and $Details) {
        Write-Host "       Details: $Details" -ForegroundColor DarkGray
    }
}

function Test-PythonInstallation {
    Write-Host "`n=== Python Installation ===" -ForegroundColor Cyan
    
    # Check Python availability
    try {
        $pythonVersion = & python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Add-TestResult "Python" "Installation" $true "Found: $pythonVersion"
            
            # Check Python version (should be 3.7+)
            if ($pythonVersion -match "Python (\d+)\.(\d+)") {
                $major = [int]$matches[1]
                $minor = [int]$matches[2]
                
                if ($major -ge 3 -and $minor -ge 7) {
                    Add-TestResult "Python" "Version" $true "Version $major.$minor is supported"
                }
                else {
                    Add-TestResult "Python" "Version" $false "Version $major.$minor is too old (need 3.7+)"
                }
            }
        }
        else {
            Add-TestResult "Python" "Installation" $false "Python not found in PATH"
        }
    }
    catch {
        Add-TestResult "Python" "Installation" $false "Error checking Python: $($_.Exception.Message)"
    }
    
    # Check pip
    try {
        $pipVersion = & python -m pip --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Add-TestResult "Python" "pip" $true "pip is available"
        }
        else {
            Add-TestResult "Python" "pip" $false "pip not available"
        }
    }
    catch {
        Add-TestResult "Python" "pip" $false "Error checking pip"
    }
}

function Test-PythonPackages {
    Write-Host "`n=== Python Packages ===" -ForegroundColor Cyan
    
    $requiredPackages = @(
        "PyPDF2",
        "google-generativeai",
        "pathlib"
    )
    
    foreach ($package in $requiredPackages) {
        try {
            $result = & python -c "import $package; print('OK')" 2>&1
            if ($LASTEXITCODE -eq 0 -and $result -eq "OK") {
                Add-TestResult "Packages" $package $true "Package is installed"
            }
            else {
                Add-TestResult "Packages" $package $false "Package not found" -Details "Install with: pip install $package"
            }
        }
        catch {
            Add-TestResult "Packages" $package $false "Error checking package"
        }
    }
}

function Test-APIConfiguration {
    Write-Host "`n=== API Configuration ===" -ForegroundColor Cyan
    
    # Check environment variable
    $envKey = $env:GEMINI_API_KEY
    if ($envKey) {
        $keyPreview = $envKey.Substring(0, [Math]::Min(10, $envKey.Length)) + "..."
        Add-TestResult "API" "Environment Variable" $true "GEMINI_API_KEY found: $keyPreview"
    }
    else {
        Add-TestResult "API" "Environment Variable" $false "GEMINI_API_KEY not set"
    }
    
    # Check .env file
    $envFile = Join-Path $script:ScriptRoot ".env"
    if (Test-Path $envFile) {
        $envFileKey = $null
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^GEMINI_API_KEY=(.+)$') {
                $envFileKey = $matches[1].Trim().Trim('"').Trim("'")
            }
        }
        
        if ($envFileKey) {
            $keyPreview = $envFileKey.Substring(0, [Math]::Min(10, $envFileKey.Length)) + "..."
            Add-TestResult "API" ".env File" $true "API key found in .env: $keyPreview"
        }
        else {
            Add-TestResult "API" ".env File" $false ".env file exists but no valid API key found"
        }
    }
    else {
        Add-TestResult "API" ".env File" $false ".env file not found"
    }
    
    # Overall API key availability
    $hasApiKey = $envKey -or $envFileKey
    Add-TestResult "API" "Availability" $hasApiKey $(if ($hasApiKey) { "API key is available" } else { "No API key configured" })
}

function Test-ScriptFiles {
    Write-Host "`n=== Script Files ===" -ForegroundColor Cyan
    
    $requiredScripts = @(
        "Process-PDFs-Complete.ps1",
        "Quick-Start.ps1",
        "pdf_renamer.py"
    )
    
    foreach ($script in $requiredScripts) {
        $scriptPath = Join-Path $script:ScriptRoot $script
        if (Test-Path $scriptPath) {
            # Check if file is readable
            try {
                $content = Get-Content $scriptPath -TotalCount 1 -ErrorAction Stop
                Add-TestResult "Scripts" $script $true "File exists and is readable"
            }
            catch {
                Add-TestResult "Scripts" $script $false "File exists but cannot be read" -Details $_.Exception.Message
            }
        }
        else {
            Add-TestResult "Scripts" $script $false "File not found"
        }
    }
}

function Test-PowerShellModules {
    if ($Quick) { return }
    
    Write-Host "`n=== PowerShell Modules ===" -ForegroundColor Cyan
    
    $modules = @(
        "Microsoft.PowerShell.Archive"
    )
    
    foreach ($module in $modules) {
        if (Get-Module -ListAvailable -Name $module) {
            Add-TestResult "PowerShell" $module $true "Module is available"
        }
        else {
            Add-TestResult "PowerShell" $module $false "Module not found"
        }
    }
}

function Test-FilePermissions {
    if ($Quick) { return }
    
    Write-Host "`n=== File Permissions ===" -ForegroundColor Cyan
    
    # Test write permissions in script directory
    $testFile = Join-Path $script:ScriptRoot "permission_test_$(Get-Random).tmp"
    try {
        "test" | Out-File $testFile -ErrorAction Stop
        Remove-Item $testFile -ErrorAction SilentlyContinue
        Add-TestResult "Permissions" "Script Directory Write" $true "Can write to script directory"
    }
    catch {
        Add-TestResult "Permissions" "Script Directory Write" $false "Cannot write to script directory" -Details $_.Exception.Message
    }
    
    # Test current directory permissions
    $currentDir = Get-Location
    $testFile2 = Join-Path $currentDir "permission_test_$(Get-Random).tmp"
    try {
        "test" | Out-File $testFile2 -ErrorAction Stop
        Remove-Item $testFile2 -ErrorAction SilentlyContinue
        Add-TestResult "Permissions" "Current Directory Write" $true "Can write to current directory"
    }
    catch {
        Add-TestResult "Permissions" "Current Directory Write" $false "Cannot write to current directory" -Details $_.Exception.Message
    }
}

function Test-SamplePDFProcessing {
    if ($Quick) { return }
    
    Write-Host "`n=== Sample PDF Processing ===" -ForegroundColor Cyan
    
    # Look for test PDFs
    $testPDFs = Get-ChildItem -Path $script:ScriptRoot -Filter "*.pdf" -Recurse | Select-Object -First 1
    
    if ($testPDFs) {
        Add-TestResult "Sample" "PDF Files Found" $true "Found test PDF: $($testPDFs.Name)"
        
        # Test Python script with dry run
        if ($script:TestResults | Where-Object { $_.Component -eq "API" -and $_.Test -eq "Availability" -and $_.Passed }) {
            try {
                $pythonScript = Join-Path $script:ScriptRoot "pdf_renamer.py"
                $result = & python $pythonScript $testPDFs.FullName --dry-run 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Add-TestResult "Sample" "Python Script Test" $true "pdf_renamer.py executed successfully"
                }
                else {
                    Add-TestResult "Sample" "Python Script Test" $false "pdf_renamer.py failed" -Details $result
                }
            }
            catch {
                Add-TestResult "Sample" "Python Script Test" $false "Error testing Python script" -Details $_.Exception.Message
            }
        }
        else {
            Add-TestResult "Sample" "Python Script Test" $false "Skipped (no API key)"
        }
    }
    else {
        Add-TestResult "Sample" "PDF Files Found" $false "No test PDF files found in directory"
    }
}

function Show-Summary {
    Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Cyan
    
    $totalTests = $script:TestResults.Count
    $passedTests = ($script:TestResults | Where-Object { $_.Passed }).Count
    $failedTests = $totalTests - $passedTests
    
    Write-Host "Total tests: $totalTests" -ForegroundColor White
    Write-Host "Passed: $passedTests" -ForegroundColor Green
    Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })
    
    if ($failedTests -gt 0) {
        Write-Host "`nFAILED TESTS:" -ForegroundColor Red
        $script:TestResults | Where-Object { -not $_.Passed } | ForEach-Object {
            Write-Host "  $($_.Component) - $($_.Test): $($_.Message)" -ForegroundColor Red
            if ($_.Details) {
                Write-Host "    $($_.Details)" -ForegroundColor Gray
            }
        }
        
        Write-Host "`nRECOMMENDATIONS:" -ForegroundColor Yellow
        
        # Python issues
        if ($script:TestResults | Where-Object { $_.Component -eq "Python" -and -not $_.Passed }) {
            Write-Host "  Install Python 3.7+ from https://python.org" -ForegroundColor White
        }
        
        # Package issues
        if ($script:TestResults | Where-Object { $_.Component -eq "Packages" -and -not $_.Passed }) {
            Write-Host "  Install Python packages: pip install PyPDF2 google-generativeai" -ForegroundColor White
        }
        
        # API issues
        if ($script:TestResults | Where-Object { $_.Component -eq "API" -and -not $_.Passed }) {
            Write-Host "  Set up API key: .\Quick-Start.ps1 -Setup" -ForegroundColor White
        }
        
        # Script issues
        if ($script:TestResults | Where-Object { $_.Component -eq "Scripts" -and -not $_.Passed }) {
            Write-Host "  Ensure all script files are present and not corrupted" -ForegroundColor White
        }
    }
    else {
        Write-Host "`nALL TESTS PASSED! ✓" -ForegroundColor Green
        Write-Host "System is ready for PDF processing." -ForegroundColor Green
        Write-Host "`nNext steps:" -ForegroundColor Yellow
        Write-Host "  .\Quick-Start.ps1 -DryRun     # Test with dry run" -ForegroundColor White
        Write-Host "  .\Quick-Start.ps1 -Process    # Process files" -ForegroundColor White
    }
    
    # Save detailed results
    if (-not $Quick) {
        $resultsFile = Join-Path $script:ScriptRoot "test_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $script:TestResults | ConvertTo-Json -Depth 3 | Out-File $resultsFile -Encoding UTF8
        Write-Host "`nDetailed results saved to: $resultsFile" -ForegroundColor Gray
    }
}

# Main execution
Write-Host "PDF Processing Pipeline - Component Tests" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Mode: $(if ($Quick) { 'Quick' } else { 'Full' })" -ForegroundColor Gray

if ($Quick) {
    Write-Host "Running essential checks only..." -ForegroundColor Yellow
}
else {
    Write-Host "Running comprehensive system verification..." -ForegroundColor Yellow
}

# Run tests
Test-PythonInstallation
Test-PythonPackages
Test-APIConfiguration
Test-ScriptFiles

if (-not $Quick) {
    Test-PowerShellModules
    Test-FilePermissions
    Test-SamplePDFProcessing
}

# Show summary
Show-Summary

# Exit with appropriate code
$failedCount = ($script:TestResults | Where-Object { -not $_.Passed }).Count
exit $(if ($failedCount -eq 0) { 0 } else { 1 })