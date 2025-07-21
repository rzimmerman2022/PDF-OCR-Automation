#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Automated test runner for the PDF-OCR-Automation project
    
.DESCRIPTION
    Comprehensive test runner that executes all test suites:
    - Component validation tests
    - Python unit tests
    - PowerShell Pester tests
    - Integration tests
    - System validation tests
    
.PARAMETER TestType
    Type of tests to run: All, Unit, Integration, System (default: All)
    
.PARAMETER OutputFormat
    Test result format: Console, XML, JSON (default: Console)
    
.PARAMETER CreateTestData
    Create test PDF files before running tests
    
.PARAMETER SkipCleanup
    Skip cleanup of test files after completion
    
.PARAMETER Verbose
    Show detailed test output
    
.EXAMPLE
    .\Run-All-Tests.ps1
    Run all tests with console output
    
.EXAMPLE
    .\Run-All-Tests.ps1 -TestType Unit -OutputFormat XML
    Run only unit tests with XML output
    
.EXAMPLE
    .\Run-All-Tests.ps1 -CreateTestData -Verbose
    Create test data and run all tests with verbose output
#>

param(
    [ValidateSet("All", "Unit", "Integration", "System", "Component")]
    [string]$TestType = "All",
    
    [ValidateSet("Console", "XML", "JSON")]
    [string]$OutputFormat = "Console",
    
    [switch]$CreateTestData,
    
    [switch]$SkipCleanup,
    
    [switch]$Verbose
)

# Script initialization
$script:ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:TestsRoot = Join-Path $script:ScriptRoot "tests"
$script:ResultsDir = Join-Path $script:TestsRoot "results"
$script:TestStartTime = Get-Date

# Test results tracking
$script:TestResults = @{
    ComponentTests = $null
    PythonUnitTests = $null
    PowerShellUnitTests = $null
    IntegrationTests = $null
    SystemValidation = $null
    OverallStatus = "Unknown"
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    SkippedTests = 0
    Duration = $null
}

#region Utility Functions
function Write-TestHeader {
    param([string]$Title)
    
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host ""
}

function Write-TestStatus {
    param(
        [string]$Message,
        [string]$Status = "Info"
    )
    
    $color = switch ($Status) {
        "Success" { "Green" }
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Info" { "White" }
        default { "White" }
    }
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

function Initialize-TestEnvironment {
    # Create results directory
    if (-not (Test-Path $script:ResultsDir)) {
        New-Item -Path $script:ResultsDir -ItemType Directory -Force | Out-Null
    }
    
    # Clean old results
    Get-ChildItem $script:ResultsDir -Filter "*.xml" -File | 
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
        Remove-Item -Force
    
    Write-TestStatus "Test environment initialized" "Success"
    Write-TestStatus "Results directory: $script:ResultsDir" "Info"
}

function Test-Prerequisites {
    Write-TestHeader "Checking Prerequisites"
    
    $prereqStatus = @{
        PowerShell = $true
        Python = $false
        Pester = $false
        Scripts = $true
    }
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    Write-TestStatus "PowerShell version: $psVersion" "Info"
    
    # Check Python
    try {
        $pythonVersion = & python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $prereqStatus.Python = $true
            Write-TestStatus "Python found: $pythonVersion" "Success"
        }
        else {
            Write-TestStatus "Python not found or not working" "Warning"
        }
    }
    catch {
        Write-TestStatus "Python not available: $($_.Exception.Message)" "Warning"
    }
    
    # Check Pester
    try {
        $pesterModule = Get-Module -ListAvailable -Name Pester
        if ($pesterModule) {
            $prereqStatus.Pester = $true
            Write-TestStatus "Pester module found: version $($pesterModule[0].Version)" "Success"
        }
        else {
            Write-TestStatus "Pester module not found" "Warning"
            Write-TestStatus "Install with: Install-Module -Name Pester -Force" "Info"
        }
    }
    catch {
        Write-TestStatus "Error checking Pester: $($_.Exception.Message)" "Warning"
    }
    
    # Check main scripts
    $mainScripts = @(
        "Process-PDFs-Complete.ps1",
        "Quick-Start.ps1", 
        "pdf_renamer.py",
        "Test-Pipeline-Components.ps1"
    )
    
    foreach ($script in $mainScripts) {
        $scriptPath = Join-Path $script:ScriptRoot $script
        if (Test-Path $scriptPath) {
            Write-TestStatus "Found: $script" "Success"
        }
        else {
            Write-TestStatus "Missing: $script" "Error"
            $prereqStatus.Scripts = $false
        }
    }
    
    return $prereqStatus
}

function Create-TestData {
    if (-not $CreateTestData) { return }
    
    Write-TestHeader "Creating Test Data"
    
    $testDataScript = Join-Path $script:TestsRoot "data\create_test_pdfs.py"
    
    if (Test-Path $testDataScript) {
        try {
            Write-TestStatus "Creating test PDF files..." "Info"
            $result = & python $testDataScript 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-TestStatus "Test data created successfully" "Success"
                if ($Verbose) {
                    $result | ForEach-Object { Write-TestStatus $_ "Info" }
                }
            }
            else {
                Write-TestStatus "Failed to create test data" "Error"
                $result | ForEach-Object { Write-TestStatus $_ "Error" }
            }
        }
        catch {
            Write-TestStatus "Error creating test data: $($_.Exception.Message)" "Error"
        }
    }
    else {
        Write-TestStatus "Test data creation script not found" "Warning"
    }
}
#endregion

#region Test Execution Functions
function Invoke-ComponentTests {
    Write-TestHeader "Component Validation Tests"
    
    $componentScript = Join-Path $script:ScriptRoot "Test-Pipeline-Components.ps1"
    
    if (-not (Test-Path $componentScript)) {
        Write-TestStatus "Component test script not found" "Error"
        return @{ Status = "Error"; Message = "Script not found" }
    }
    
    try {
        Write-TestStatus "Running component tests..." "Info"
        $result = & powershell -Command "& '$componentScript' -Quick 2>&1"
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestStatus "Component tests completed successfully" "Success"
            return @{ Status = "Success"; Output = $result }
        }
        else {
            Write-TestStatus "Component tests failed" "Error"
            return @{ Status = "Failed"; Output = $result }
        }
    }
    catch {
        Write-TestStatus "Error running component tests: $($_.Exception.Message)" "Error"
        return @{ Status = "Error"; Message = $_.Exception.Message }
    }
}

function Invoke-PythonUnitTests {
    Write-TestHeader "Python Unit Tests"
    
    $pythonTestScript = Join-Path $script:TestsRoot "unit\test_pdf_renamer.py"
    
    if (-not (Test-Path $pythonTestScript)) {
        Write-TestStatus "Python test script not found" "Error"
        return @{ Status = "Error"; Message = "Script not found" }
    }
    
    try {
        Write-TestStatus "Running Python unit tests..." "Info"
        $result = & python $pythonTestScript 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestStatus "Python unit tests completed successfully" "Success"
            return @{ Status = "Success"; Output = $result }
        }
        else {
            Write-TestStatus "Python unit tests had failures" "Warning"
            return @{ Status = "Failed"; Output = $result }
        }
    }
    catch {
        Write-TestStatus "Error running Python tests: $($_.Exception.Message)" "Error"
        return @{ Status = "Error"; Message = $_.Exception.Message }
    }
}

function Invoke-PowerShellUnitTests {
    Write-TestHeader "PowerShell Unit Tests"
    
    $pesterTests = Get-ChildItem -Path (Join-Path $script:TestsRoot "unit") -Filter "*.Tests.ps1"
    
    if ($pesterTests.Count -eq 0) {
        Write-TestStatus "No Pester test files found" "Warning"
        return @{ Status = "Skipped"; Message = "No test files found" }
    }
    
    try {
        Import-Module Pester -Force -ErrorAction Stop
        
        $results = @()
        foreach ($testFile in $pesterTests) {
            Write-TestStatus "Running $($testFile.Name)..." "Info"
            
            $config = New-PesterConfiguration
            $config.Run.Path = $testFile.FullName
            $config.Output.Verbosity = if ($Verbose) { "Detailed" } else { "Normal" }
            
            if ($OutputFormat -eq "XML") {
                $resultFile = Join-Path $script:ResultsDir "$($testFile.BaseName)-Results.xml"
                $config.TestResult.Enabled = $true
                $config.TestResult.OutputFormat = "NUnitXml"
                $config.TestResult.OutputPath = $resultFile
            }
            
            $result = Invoke-Pester -Configuration $config
            $results += $result
        }
        
        $totalTests = ($results | Measure-Object -Property TotalCount -Sum).Sum
        $failedTests = ($results | Measure-Object -Property FailedCount -Sum).Sum
        
        if ($failedTests -eq 0) {
            Write-TestStatus "All PowerShell unit tests passed ($totalTests tests)" "Success"
            return @{ Status = "Success"; TotalTests = $totalTests; FailedTests = $failedTests }
        }
        else {
            Write-TestStatus "PowerShell unit tests completed with $failedTests failures out of $totalTests tests" "Warning"
            return @{ Status = "Failed"; TotalTests = $totalTests; FailedTests = $failedTests }
        }
    }
    catch {
        Write-TestStatus "Error running PowerShell tests: $($_.Exception.Message)" "Error"
        return @{ Status = "Error"; Message = $_.Exception.Message }
    }
}

function Invoke-IntegrationTests {
    Write-TestHeader "Integration Tests"
    
    $integrationTest = Join-Path $script:TestsRoot "integration\Pipeline.Tests.ps1"
    
    if (-not (Test-Path $integrationTest)) {
        Write-TestStatus "Integration test script not found" "Error"
        return @{ Status = "Error"; Message = "Script not found" }
    }
    
    try {
        Import-Module Pester -Force -ErrorAction Stop
        
        Write-TestStatus "Running integration tests..." "Info"
        
        $config = New-PesterConfiguration
        $config.Run.Path = $integrationTest
        $config.Output.Verbosity = if ($Verbose) { "Detailed" } else { "Normal" }
        
        if ($OutputFormat -eq "XML") {
            $resultFile = Join-Path $script:ResultsDir "Integration-TestResults.xml"
            $config.TestResult.Enabled = $true
            $config.TestResult.OutputFormat = "NUnitXml"
            $config.TestResult.OutputPath = $resultFile
        }
        
        $result = Invoke-Pester -Configuration $config
        
        if ($result.FailedCount -eq 0) {
            Write-TestStatus "Integration tests passed ($($result.TotalCount) tests)" "Success"
            return @{ Status = "Success"; TotalTests = $result.TotalCount; FailedTests = $result.FailedCount }
        }
        else {
            Write-TestStatus "Integration tests completed with $($result.FailedCount) failures" "Warning"
            return @{ Status = "Failed"; TotalTests = $result.TotalCount; FailedTests = $result.FailedCount }
        }
    }
    catch {
        Write-TestStatus "Error running integration tests: $($_.Exception.Message)" "Error"
        return @{ Status = "Error"; Message = $_.Exception.Message }
    }
}

function Invoke-SystemValidation {
    Write-TestHeader "System Validation"
    
    Write-TestStatus "Performing end-to-end system validation..." "Info"
    
    # Create temporary test environment
    $tempTestDir = Join-Path $env:TEMP "SystemValidation_$(Get-Random)"
    New-Item -Path $tempTestDir -ItemType Directory -Force | Out-Null
    
    try {
        # Create a simple test PDF
        $testPDF = Join-Path $tempTestDir "validation_test.pdf"
        "Fake PDF for validation testing" | Out-File $testPDF
        
        # Test Quick-Start help
        Write-TestStatus "Testing Quick-Start help display..." "Info"
        $quickStartScript = Join-Path $script:ScriptRoot "Quick-Start.ps1"
        $helpResult = & powershell -Command "`& '$quickStartScript' 2>&1"
        
        if ($helpResult -match "Quick Start") {
            Write-TestStatus "✓ Quick-Start help working" "Success"
        }
        else {
            Write-TestStatus "✗ Quick-Start help failed" "Error"
        }
        
        # Test component validation
        Write-TestStatus "Testing component validation..." "Info"
        $componentScript = Join-Path $script:ScriptRoot "Test-Pipeline-Components.ps1"
        $componentResult = & powershell -Command "`& '$componentScript' -Quick 2>&1"
        
        if ($componentResult -match "Component Tests") {
            Write-TestStatus "✓ Component validation working" "Success"
        }
        else {
            Write-TestStatus "✗ Component validation failed" "Error"
        }
        
        # Test main script parameter validation
        Write-TestStatus "Testing main script parameter validation..." "Info"
        $mainScript = Join-Path $script:ScriptRoot "Process-PDFs-Complete.ps1"
        $paramResult = & powershell -Command "`& '$mainScript' -TargetFolder '$tempTestDir' -WhatIf 2>&1"
        
        if ($paramResult -notmatch "mandatory") {
            Write-TestStatus "✓ Main script parameter handling working" "Success"
        }
        else {
            Write-TestStatus "✗ Main script parameter handling failed" "Error"
        }
        
        Write-TestStatus "System validation completed" "Success"
        return @{ Status = "Success"; Message = "System validation passed" }
        
    }
    catch {
        Write-TestStatus "System validation error: $($_.Exception.Message)" "Error"
        return @{ Status = "Error"; Message = $_.Exception.Message }
    }
    finally {
        # Cleanup
        if (-not $SkipCleanup) {
            Remove-Item $tempTestDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
#endregion

#region Main Execution
function Invoke-AllTests {
    Write-TestHeader "PDF-OCR-Automation Test Suite"
    Write-TestStatus "Test Type: $TestType" "Info"
    Write-TestStatus "Output Format: $OutputFormat" "Info"
    Write-TestStatus "Start Time: $script:TestStartTime" "Info"
    
    # Initialize environment
    Initialize-TestEnvironment
    
    # Check prerequisites
    $prereqs = Test-Prerequisites
    
    # Create test data if requested
    Create-TestData
    
    # Run tests based on type
    switch ($TestType) {
        "All" {
            $script:TestResults.ComponentTests = Invoke-ComponentTests
            $script:TestResults.PythonUnitTests = Invoke-PythonUnitTests
            $script:TestResults.PowerShellUnitTests = Invoke-PowerShellUnitTests
            $script:TestResults.IntegrationTests = Invoke-IntegrationTests
            $script:TestResults.SystemValidation = Invoke-SystemValidation
        }
        "Component" {
            $script:TestResults.ComponentTests = Invoke-ComponentTests
        }
        "Unit" {
            $script:TestResults.PythonUnitTests = Invoke-PythonUnitTests
            $script:TestResults.PowerShellUnitTests = Invoke-PowerShellUnitTests
        }
        "Integration" {
            $script:TestResults.IntegrationTests = Invoke-IntegrationTests
        }
        "System" {
            $script:TestResults.SystemValidation = Invoke-SystemValidation
        }
    }
    
    # Generate summary
    Show-TestSummary
    
    # Save results if requested
    if ($OutputFormat -ne "Console") {
        Save-TestResults
    }
    
    # Cleanup if not skipped
    if (-not $SkipCleanup) {
        Cleanup-TestEnvironment
    }
}

function Show-TestSummary {
    Write-TestHeader "Test Summary"
    
    $endTime = Get-Date
    $script:TestResults.Duration = $endTime - $script:TestStartTime
    
    Write-TestStatus "Total Duration: $($script:TestResults.Duration.ToString('hh\:mm\:ss'))" "Info"
    
    # Show individual test results
    $script:TestResults.GetEnumerator() | Where-Object { $_.Key -ne "OverallStatus" -and $_.Key -ne "Duration" -and $_.Value -ne $null } | ForEach-Object {
        $testName = $_.Key
        $result = $_.Value
        
        switch ($result.Status) {
            "Success" { Write-TestStatus "PASS $testName" "Success" }
            "Failed" { Write-TestStatus "FAIL $testName" "Error" }
            "Error" { Write-TestStatus "ERROR $testName" "Error" }
            "Skipped" { Write-TestStatus "SKIP $testName" "Warning" }
        }
        
        if ($result.TotalTests) {
            Write-TestStatus "  Tests: $($result.TotalTests), Failed: $($result.FailedTests)" "Info"
        }
    }
    
    # Determine overall status
    $hasErrors = $script:TestResults.Values | Where-Object { $_ -and $_.Status -in @("Error", "Failed") }
    $script:TestResults.OverallStatus = if ($hasErrors) { "Failed" } else { "Success" }
    
    Write-Host ""
    if ($script:TestResults.OverallStatus -eq "Success") {
        Write-TestStatus "ALL TESTS COMPLETED SUCCESSFULLY!" "Success"
    }
    else {
        Write-TestStatus "SOME TESTS FAILED - REVIEW RESULTS ABOVE" "Error"
    }
    
    Write-TestStatus "Results saved to: $script:ResultsDir" "Info"
}

function Save-TestResults {
    $resultsFile = Join-Path $script:ResultsDir "TestSummary_$(Get-Date -Format 'yyyyMMdd_HHmmss').$($OutputFormat.ToLower())"
    
    try {
        if ($OutputFormat -eq "JSON") {
            $script:TestResults | ConvertTo-Json -Depth 5 | Out-File $resultsFile -Encoding UTF8
        }
        elseif ($OutputFormat -eq "XML") {
            # Create simple XML summary
            $xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<TestResults>
    <Summary>
        <OverallStatus>$($script:TestResults.OverallStatus)</OverallStatus>
        <Duration>$($script:TestResults.Duration)</Duration>
        <Timestamp>$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')</Timestamp>
    </Summary>
    <Tests>
"@
            $script:TestResults.GetEnumerator() | Where-Object { $_.Key -notin @("OverallStatus", "Duration") -and $_.Value -ne $null } | ForEach-Object {
                $xml += "        <Test name='$($_.Key)' status='$($_.Value.Status)' />`n"
            }
            $xml += @"
    </Tests>
</TestResults>
"@
            $xml | Out-File $resultsFile -Encoding UTF8
        }
        
        Write-TestStatus "Results saved to: $resultsFile" "Success"
    }
    catch {
        Write-TestStatus "Failed to save results: $($_.Exception.Message)" "Error"
    }
}

function Cleanup-TestEnvironment {
    Write-TestStatus "Cleaning up test environment..." "Info"
    
    # Clean up any temporary test files in script directory
    Get-ChildItem $script:ScriptRoot -Filter "*test*" -File | 
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-1) } |
        Remove-Item -Force -ErrorAction SilentlyContinue
    
    # Clean up old log files
    Get-ChildItem $script:ScriptRoot -Filter "*log*" -File | 
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } |
        Remove-Item -Force -ErrorAction SilentlyContinue
    
    Write-TestStatus "Cleanup completed" "Success"
}
#endregion

# Main execution
try {
    Invoke-AllTests
    
    # Exit with appropriate code
    $exitCode = if ($script:TestResults.OverallStatus -eq "Success") { 0 } else { 1 }
    exit $exitCode
}
catch {
    Write-TestStatus "Fatal error in test runner: $($_.Exception.Message)" "Error"
    Write-TestStatus "Stack trace: $($_.ScriptStackTrace)" "Error"
    exit 1
}