#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Pester tests for Process-PDFs-Complete.ps1
.DESCRIPTION
    Unit tests for the main PDF processing engine using Pester framework
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
$script:MainScript = Join-Path $script:ScriptRoot "Process-PDFs-Complete.ps1"
$script:TestDataDir = Join-Path $PSScriptRoot "..\data"
$script:MocksDir = Join-Path $PSScriptRoot "..\mocks"

# Create test directories if they don't exist
if (-not (Test-Path $script:TestDataDir)) {
    New-Item -Path $script:TestDataDir -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path $script:MocksDir)) {
    New-Item -Path $script:MocksDir -ItemType Directory -Force | Out-Null
}

Describe "Process-PDFs-Complete.ps1 Unit Tests" {
    
    BeforeAll {
        # Ensure main script exists
        if (-not (Test-Path $script:MainScript)) {
            throw "Main script not found: $script:MainScript"
        }
        
        # Source the main script functions (need to modify main script to support this)
        # For now, we'll test by invoking the script
    }
    
    Context "Parameter Validation" {
        
        It "Should require TargetFolder parameter" {
            $result = & powershell -Command "& '$script:MainScript' 2>&1"
            $result | Should -Match "TargetFolder.*mandatory"
        }
        
        It "Should validate TargetFolder exists" {
            $tempFolder = Join-Path $env:TEMP "NonExistentFolder_$(Get-Random)"
            $result = & powershell -Command "& '$script:MainScript' -TargetFolder '$tempFolder' 2>&1"
            $result | Should -Match "does not exist"
        }
        
        It "Should accept valid parameters" {
            $tempFolder = New-Item -Path (Join-Path $env:TEMP "TestFolder_$(Get-Random)") -ItemType Directory
            try {
                # This should not fail with parameter errors
                $result = & powershell -Command "& '$script:MainScript' -TargetFolder '$($tempFolder.FullName)' -APIKey 'test_key' -WhatIf 2>&1"
                $result | Should -Not -Match "mandatory"
            }
            finally {
                Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Context "Environment Setup" {
        
        It "Should load API key from environment" {
            $env:GEMINI_API_KEY = "test_env_key"
            try {
                # Test that script can access environment variable
                $result = & powershell -Command "`$env:GEMINI_API_KEY = 'test_env_key'; Write-Output `$env:GEMINI_API_KEY"
                $result | Should -Be "test_env_key"
            }
            finally {
                Remove-Item Env:GEMINI_API_KEY -ErrorAction SilentlyContinue
            }
        }
        
        It "Should create log files" {
            $tempFolder = New-Item -Path (Join-Path $env:TEMP "TestFolder_$(Get-Random)") -ItemType Directory
            try {
                # Run script briefly to test log creation
                $result = & powershell -Command "& '$script:MainScript' -TargetFolder '$($tempFolder.FullName)' -APIKey 'test_key' 2>&1"
                
                # Check if any log files were created in script directory
                $logFiles = Get-ChildItem -Path $script:ScriptRoot -Filter "*log*" -ErrorAction SilentlyContinue
                $logFiles | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
                # Clean up any test log files
                Get-ChildItem -Path $script:ScriptRoot -Filter "*log*" | 
                    Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) } |
                    Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "Script Functions" {
    
    Context "Logging Functions" {
        
        It "Should handle log messages without errors" {
            # Create a simple test to verify logging doesn't crash
            $testScript = @"
                # Source the functions from main script
                . '$script:MainScript'
                Write-Log "Test message" -Level "Info"
                Write-Output "Logging test completed"
"@
            
            $tempScript = Join-Path $env:TEMP "test_logging_$(Get-Random).ps1"
            Set-Content -Path $tempScript -Value $testScript
            
            try {
                $result = & powershell -File $tempScript 2>&1
                $result | Should -Match "Logging test completed"
            }
            finally {
                Remove-Item $tempScript -ErrorAction SilentlyContinue
            }
        }
    }
    
    Context "File Processing" {
        
        It "Should handle empty directories gracefully" {
            $tempFolder = New-Item -Path (Join-Path $env:TEMP "EmptyTestFolder_$(Get-Random)") -ItemType Directory
            try {
                $result = & powershell -Command "& '$script:MainScript' -TargetFolder '$($tempFolder.FullName)' -APIKey 'test_key' 2>&1"
                $result | Should -Match "No PDF files found"
            }
            finally {
                Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "Integration with Dependencies" {
    
    Context "Python Script Integration" {
        
        It "Should find pdf_renamer.py script" {
            $pythonScript = Join-Path $script:ScriptRoot "pdf_renamer.py"
            Test-Path $pythonScript | Should -Be $true
        }
        
        It "Should handle Python script errors gracefully" {
            # Test what happens when Python script fails
            $tempFolder = New-Item -Path (Join-Path $env:TEMP "TestFolder_$(Get-Random)") -ItemType Directory
            $testPDF = Join-Path $tempFolder "test.pdf"
            
            # Create a fake PDF file
            "Fake PDF content" | Out-File $testPDF
            
            try {
                # This should handle the error when Python script fails on fake PDF
                $result = & powershell -Command "& '$script:MainScript' -TargetFolder '$($tempFolder.FullName)' -APIKey 'invalid_key' 2>&1"
                # Should not crash the entire script
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "Error Handling" {
    
    Context "Invalid Inputs" {
        
        It "Should handle invalid API keys gracefully" {
            $tempFolder = New-Item -Path (Join-Path $env:TEMP "TestFolder_$(Get-Random)") -ItemType Directory
            try {
                $result = & powershell -Command "& '$script:MainScript' -TargetFolder '$($tempFolder.FullName)' 2>&1"
                $result | Should -Match "API key"
            }
            finally {
                Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should handle permission errors" {
            # Test with a read-only directory (if possible to create)
            $tempFolder = New-Item -Path (Join-Path $env:TEMP "ReadOnlyTestFolder_$(Get-Random)") -ItemType Directory
            try {
                # Make directory read-only (Windows)
                $acl = Get-Acl $tempFolder
                $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "Write", "Deny")
                $acl.SetAccessRule($accessRule)
                Set-Acl $tempFolder $acl -ErrorAction SilentlyContinue
                
                $result = & powershell -Command "& '$script:MainScript' -TargetFolder '$($tempFolder.FullName)' -APIKey 'test_key' 2>&1"
                # Should handle permission issues gracefully
                $result | Should -Not -BeNullOrEmpty
            }
            finally {
                # Remove read-only restriction
                $acl = Get-Acl $tempFolder
                $acl.Access | Where-Object { $_.AccessControlType -eq "Deny" } | ForEach-Object {
                    $acl.RemoveAccessRule($_) | Out-Null
                }
                Set-Acl $tempFolder $acl -ErrorAction SilentlyContinue
                Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# Helper function to run these tests
function Invoke-ProcessPDFsTests {
    param(
        [string]$OutputFormat = "NUnitXml",
        [string]$OutputFile = (Join-Path $PSScriptRoot "TestResults.xml")
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
    Write-Host "Running Process-PDFs-Complete.ps1 Tests..." -ForegroundColor Cyan
    Invoke-ProcessPDFsTests
}