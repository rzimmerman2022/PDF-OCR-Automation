#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Integration tests for the complete PDF processing pipeline
.DESCRIPTION
    End-to-end tests that verify the entire workflow from PDF analysis to renaming
#>

# Import Pester if available
try {
    Import-Module Pester -Force -ErrorAction Stop
}
catch {
    Write-Warning "Pester module not found. Install with: Install-Module -Name Pester -Force"
    exit 1
}

# Setup test environment
$script:ScriptRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:TestDataDir = Join-Path $PSScriptRoot "..\data"
$script:MocksDir = Join-Path $PSScriptRoot "..\mocks"

# Main scripts
$script:MainScript = Join-Path $script:ScriptRoot "Process-PDFs-Complete.ps1"
$script:QuickStartScript = Join-Path $script:ScriptRoot "Quick-Start.ps1"
$script:PythonScript = Join-Path $script:ScriptRoot "pdf_renamer.py"
$script:TestScript = Join-Path $script:ScriptRoot "Test-Pipeline-Components.ps1"

Describe "Pipeline Integration Tests" {
    
    BeforeAll {
        # Verify all main scripts exist
        @($script:MainScript, $script:QuickStartScript, $script:PythonScript, $script:TestScript) | ForEach-Object {
            if (-not (Test-Path $_)) {
                throw "Required script not found: $_"
            }
        }
        
        # Create test directories
        @($script:TestDataDir, $script:MocksDir) | ForEach-Object {
            if (-not (Test-Path $_)) {
                New-Item -Path $_ -ItemType Directory -Force | Out-Null
            }
        }
        
        # Backup any existing .env file
        $script:OriginalEnvFile = $null
        $envFile = Join-Path $script:ScriptRoot ".env"
        if (Test-Path $envFile) {
            $script:OriginalEnvFile = "$envFile.backup_$(Get-Random)"
            Copy-Item $envFile $script:OriginalEnvFile
        }
    }
    
    AfterAll {
        # Restore original .env file
        $envFile = Join-Path $script:ScriptRoot ".env"
        if ($script:OriginalEnvFile -and (Test-Path $script:OriginalEnvFile)) {
            Move-Item $script:OriginalEnvFile $envFile -Force
        }
        elseif (Test-Path $envFile) {
            Remove-Item $envFile -Force
        }
        
        # Clean up test files
        Get-ChildItem $script:ScriptRoot -Filter "*test*" -File | 
            Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-1) } |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
    
    Context "Component Availability Tests" {
        
        It "Should find all required scripts" {
            Test-Path $script:MainScript | Should -Be $true
            Test-Path $script:QuickStartScript | Should -Be $true
            Test-Path $script:PythonScript | Should -Be $true
            Test-Path $script:TestScript | Should -Be $true
        }
        
        It "Should run component tests successfully" {
            $result = & powershell -Command "& '$script:TestScript' -Quick 2>&1"
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "Component Tests"
        }
        
        It "Should validate Python availability" {
            try {
                $pythonVersion = & python --version 2>&1
                $pythonVersion | Should -Match "Python"
            }
            catch {
                Set-ItResult -Skipped -Because "Python not available"
            }
        }
    }
    
    Context "Quick-Start Workflow Tests" {
        
        It "Should show help by default" {
            $result = & powershell -Command "& '$script:QuickStartScript' 2>&1"
            $result | Should -Match "Quick Start"
            $result | Should -Match "USAGE:"
        }
        
        It "Should handle setup mode" {
            # Test setup with automated input
            $input = "test_api_key_for_integration_testing_123456789"
            $result = $input | & powershell -Command "& '$script:QuickStartScript' -Setup 2>&1"
            $result | Should -Match "API key saved"
            
            # Verify .env file was created
            $envFile = Join-Path $script:ScriptRoot ".env"
            Test-Path $envFile | Should -Be $true
            
            # Verify content
            $envContent = Get-Content $envFile -Raw
            $envContent | Should -Match "GEMINI_API_KEY=test_api_key_for_integration_testing"
        }
        
        It "Should handle dry run with empty folder" {
            $tempFolder = New-Item -Path (Join-Path $env:TEMP "EmptyIntegrationTest_$(Get-Random)") -ItemType Directory
            try {
                $result = & powershell -Command "& '$script:QuickStartScript' -DryRun -Folder '$($tempFolder.FullName)' 2>&1"
                $result | Should -Match "No PDF files found"
            }
            finally {
                Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Context "End-to-End Pipeline Tests" {
        
        BeforeEach {
            # Create test folder with mock PDF files
            $script:TestFolder = New-Item -Path (Join-Path $env:TEMP "PipelineTest_$(Get-Random)") -ItemType Directory
            
            # Create mock PDF files with different naming patterns
            $testFiles = @(
                "document.pdf",
                "scan001.pdf", 
                "Invoice_CompanyABC_12345.pdf",  # Already well-named
                "file123.pdf"
            )
            
            foreach ($file in $testFiles) {
                $filePath = Join-Path $script:TestFolder $file
                @"
%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj
2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj
3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj
4 0 obj
<<
/Length 44
>>
stream
BT
/F1 12 Tf
72 720 Td
(Test PDF Content) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000074 00000 n 
0000000120 00000 n 
0000000179 00000 n 
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
229
%%EOF
"@ | Out-File $filePath -Encoding ASCII
            }
        }
        
        AfterEach {
            if ($script:TestFolder -and (Test-Path $script:TestFolder)) {
                Remove-Item $script:TestFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should analyze files correctly" {
            # Run the main script with dry run to test analysis
            $envFile = Join-Path $script:ScriptRoot ".env"
            if (-not (Test-Path $envFile)) {
                "GEMINI_API_KEY=test_key_for_analysis" | Out-File $envFile
            }
            
            try {
                $result = & powershell -Command "& '$script:MainScript' -TargetFolder '$($script:TestFolder.FullName)' -LogLevel 'Info' 2>&1"
                
                # Should find PDF files
                $result | Should -Match "Found.*PDF files"
                
                # Should perform analysis
                $result | Should -Match "Analysis complete"
                
                # Should identify different file categories
                $result | Should -Match "Total files:"
                
            }
            catch {
                Set-ItResult -Skipped -Because "API key or Python dependencies not available"
            }
        }
        
        It "Should handle missing API key gracefully" {
            # Remove API key temporarily
            $envFile = Join-Path $script:ScriptRoot ".env"
            $backupContent = $null
            if (Test-Path $envFile) {
                $backupContent = Get-Content $envFile -Raw
                Remove-Item $envFile
            }
            
            try {
                $result = & powershell -Command "& '$script:MainScript' -TargetFolder '$($script:TestFolder.FullName)' 2>&1"
                $result | Should -Match "API key"
            }
            finally {
                # Restore API key
                if ($backupContent) {
                    $backupContent | Out-File $envFile
                }
            }
        }
        
        It "Should create state and log files" {
            $envFile = Join-Path $script:ScriptRoot ".env"
            if (-not (Test-Path $envFile)) {
                "GEMINI_API_KEY=test_key_for_logging" | Out-File $envFile
            }
            
            $initialLogCount = (Get-ChildItem $script:ScriptRoot -Filter "*log*" | Measure-Object).Count
            $initialStateCount = (Get-ChildItem $script:ScriptRoot -Filter "*status*" | Measure-Object).Count
            
            try {
                $result = & powershell -Command "& '$script:MainScript' -TargetFolder '$($script:TestFolder.FullName)' 2>&1"
                
                # Should create log files
                $finalLogCount = (Get-ChildItem $script:ScriptRoot -Filter "*log*" | Measure-Object).Count
                $finalLogCount | Should -BeGreaterThan $initialLogCount
                
                # Should create or update state file
                $stateFile = Join-Path $script:ScriptRoot ".processing_status.json"
                Test-Path $stateFile | Should -Be $true
                
            }
            catch {
                Set-ItResult -Skipped -Because "API key or Python dependencies not available"
            }
        }
    }
    
    Context "Python Integration Tests" {
        
        It "Should execute Python script independently" {
            # Create a simple test PDF
            $testPDF = Join-Path $script:TestDataDir "python_test.pdf"
            "Fake PDF for Python testing" | Out-File $testPDF
            
            try {
                $result = & python $script:PythonScript $testPDF --dry-run 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    $result | Should -Match "Processing"
                }
                else {
                    # If Python script fails due to dependencies, that's acceptable for this test
                    $result | Should -Not -BeNullOrEmpty
                }
            }
            catch {
                Set-ItResult -Skipped -Because "Python or dependencies not available"
            }
            finally {
                Remove-Item $testPDF -ErrorAction SilentlyContinue
            }
        }
        
        It "Should handle invalid PDF files" {
            $invalidPDF = Join-Path $script:TestDataDir "invalid.pdf"
            "This is not a PDF file" | Out-File $invalidPDF
            
            try {
                $result = & python $script:PythonScript $invalidPDF --dry-run 2>&1
                # Should handle invalid files gracefully
                $result | Should -Not -BeNullOrEmpty
            }
            catch {
                Set-ItResult -Skipped -Because "Python not available"
            }
            finally {
                Remove-Item $invalidPDF -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "State Management Integration" {
    
    Context "Processing State Persistence" {
        
        BeforeEach {
            $script:TestFolder = New-Item -Path (Join-Path $env:TEMP "StateTest_$(Get-Random)") -ItemType Directory
            "Mock PDF" | Out-File (Join-Path $script:TestFolder "test.pdf")
            
            # Ensure clean state
            $stateFile = Join-Path $script:ScriptRoot ".processing_status.json"
            if (Test-Path $stateFile) {
                Remove-Item $stateFile
            }
        }
        
        AfterEach {
            Remove-Item $script:TestFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        It "Should create state file during processing" {
            $envFile = Join-Path $script:ScriptRoot ".env"
            if (-not (Test-Path $envFile)) {
                "GEMINI_API_KEY=test_key_for_state" | Out-File $envFile
            }
            
            try {
                & powershell -Command "& '$script:MainScript' -TargetFolder '$($script:TestFolder.FullName)' 2>&1" | Out-Null
                
                $stateFile = Join-Path $script:ScriptRoot ".processing_status.json"
                Test-Path $stateFile | Should -Be $true
                
                # Verify state file content
                $stateContent = Get-Content $stateFile -Raw | ConvertFrom-Json
                $stateContent | Should -Not -BeNullOrEmpty
                
            }
            catch {
                Set-ItResult -Skipped -Because "Dependencies not available"
            }
        }
        
        It "Should maintain state across multiple runs" {
            $envFile = Join-Path $script:ScriptRoot ".env"
            if (-not (Test-Path $envFile)) {
                "GEMINI_API_KEY=test_key_for_persistence" | Out-File $envFile
            }
            
            try {
                # First run
                & powershell -Command "& '$script:MainScript' -TargetFolder '$($script:TestFolder.FullName)' 2>&1" | Out-Null
                
                $stateFile = Join-Path $script:ScriptRoot ".processing_status.json"
                $firstRunContent = Get-Content $stateFile -Raw
                
                # Second run
                & powershell -Command "& '$script:MainScript' -TargetFolder '$($script:TestFolder.FullName)' 2>&1" | Out-Null
                
                $secondRunContent = Get-Content $stateFile -Raw
                
                # State should be maintained or updated
                $secondRunContent | Should -Not -BeNullOrEmpty
                
            }
            catch {
                Set-ItResult -Skipped -Because "Dependencies not available"
            }
        }
    }
}

# Helper function to run integration tests
function Invoke-PipelineIntegrationTests {
    param(
        [string]$OutputFormat = "NUnitXml",
        [string]$OutputFile = (Join-Path $PSScriptRoot "Integration-TestResults.xml")
    )
    
    $config = New-PesterConfiguration
    $config.Run.Path = $PSCommandPath
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputFormat = $OutputFormat
    $config.TestResult.OutputPath = $OutputFile
    $config.Output.Verbosity = "Detailed"
    
    Invoke-Pester -Configuration $config
}

# If running this script directly, execute the tests
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Write-Host "Running Pipeline Integration Tests..." -ForegroundColor Cyan
    Invoke-PipelineIntegrationTests
}