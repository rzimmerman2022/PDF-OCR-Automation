#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Pester tests for Quick-Start.ps1
.DESCRIPTION
    Unit tests for the Quick-Start wrapper script
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
$script:QuickStartScript = Join-Path $script:ScriptRoot "Quick-Start.ps1"

Describe "Quick-Start.ps1 Unit Tests" {
    
    BeforeAll {
        # Ensure Quick-Start script exists
        if (-not (Test-Path $script:QuickStartScript)) {
            throw "Quick-Start script not found: $script:QuickStartScript"
        }
    }
    
    Context "Parameter Validation" {
        
        It "Should show help when no parameters provided" {
            $result = & powershell -Command "& '$script:QuickStartScript' 2>&1"
            $result | Should -Match "USAGE:"
            $result | Should -Match "Quick Start"
        }
        
        It "Should reject multiple modes" {
            $result = & powershell -Command "& '$script:QuickStartScript' -Setup -DryRun 2>&1"
            $result | Should -Match "only one mode"
        }
        
        It "Should accept single mode parameters" {
            # Test each mode individually (they should not error on parameter validation)
            
            # Setup mode
            $result = & powershell -Command "& '$script:QuickStartScript' -Setup -WhatIf 2>&1"
            $result | Should -Not -Match "only one mode"
            
            # DryRun mode (will fail due to missing folder, but parameter validation should pass)
            $result = & powershell -Command "& '$script:QuickStartScript' -DryRun 2>&1"
            $result | Should -Not -Match "only one mode"
            
            # Process mode (will fail due to missing folder, but parameter validation should pass)
            $result = & powershell -Command "& '$script:QuickStartScript' -Process 2>&1"
            $result | Should -Not -Match "only one mode"
        }
    }
    
    Context "Setup Mode" {
        
        It "Should detect existing API key" {
            $envFile = Join-Path $script:ScriptRoot ".env"
            $backupFile = $null
            
            # Backup existing .env if it exists
            if (Test-Path $envFile) {
                $backupFile = "$envFile.backup_$(Get-Random)"
                Copy-Item $envFile $backupFile
            }
            
            try {
                # Create test .env file
                "GEMINI_API_KEY=test_existing_key" | Out-File $envFile -Encoding UTF8
                
                # Test setup mode with existing key
                $result = & powershell -Command "echo 'y' | & '$script:QuickStartScript' -Setup 2>&1"
                $result | Should -Match "Existing API key found"
                
            }
            finally {
                # Restore backup or remove test file
                if ($backupFile -and (Test-Path $backupFile)) {
                    Move-Item $backupFile $envFile -Force
                }
                elseif (Test-Path $envFile) {
                    Remove-Item $envFile -Force
                }
            }
        }
        
        It "Should handle missing .env file" {
            $envFile = Join-Path $script:ScriptRoot ".env"
            $backupFile = $null
            
            # Backup existing .env if it exists
            if (Test-Path $envFile) {
                $backupFile = "$envFile.backup_$(Get-Random)"
                Move-Item $envFile $backupFile
            }
            
            try {
                # Test setup mode without existing .env
                $input = @"
test_new_api_key_123456789
"@
                $result = $input | & powershell -Command "& '$script:QuickStartScript' -Setup 2>&1"
                $result | Should -Match "API key saved"
                
                # Verify .env file was created
                Test-Path $envFile | Should -Be $true
                
            }
            finally {
                # Clean up test .env file
                if (Test-Path $envFile) {
                    Remove-Item $envFile -Force
                }
                
                # Restore backup
                if ($backupFile -and (Test-Path $backupFile)) {
                    Move-Item $backupFile $envFile -Force
                }
            }
        }
    }
    
    Context "Folder Validation" {
        
        It "Should detect empty directories" {
            $tempFolder = New-Item -Path (Join-Path $env:TEMP "EmptyTestFolder_$(Get-Random)") -ItemType Directory
            try {
                $result = & powershell -Command "& '$script:QuickStartScript' -DryRun -Folder '$($tempFolder.FullName)' 2>&1"
                $result | Should -Match "No PDF files found"
            }
            finally {
                Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should handle non-existent folders" {
            $nonExistentFolder = Join-Path $env:TEMP "NonExistent_$(Get-Random)"
            $result = & powershell -Command "& '$script:QuickStartScript' -DryRun -Folder '$nonExistentFolder' 2>&1"
            $result | Should -Match "does not exist"
        }
        
        It "Should accept folders with PDF files" {
            $tempFolder = New-Item -Path (Join-Path $env:TEMP "TestFolder_$(Get-Random)") -ItemType Directory
            $testPDF = Join-Path $tempFolder "test.pdf"
            "Fake PDF" | Out-File $testPDF
            
            try {
                $result = & powershell -Command "& '$script:QuickStartScript' -DryRun -Folder '$($tempFolder.FullName)' 2>&1"
                $result | Should -Match "Found.*PDF files"
            }
            finally {
                Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Context "Integration with Main Script" {
        
        It "Should find main processing script" {
            $mainScript = Join-Path $script:ScriptRoot "Process-PDFs-Complete.ps1"
            Test-Path $mainScript | Should -Be $true
        }
        
        It "Should pass parameters correctly to main script" {
            $tempFolder = New-Item -Path (Join-Path $env:TEMP "TestFolder_$(Get-Random)") -ItemType Directory
            $testPDF = Join-Path $tempFolder "test.pdf"
            "Fake PDF" | Out-File $testPDF
            
            try {
                # Test that parameters are passed (should fail due to no API key, but parameter passing should work)
                $result = & powershell -Command "& '$script:QuickStartScript' -DryRun -Folder '$($tempFolder.FullName)' -BatchSize 10 2>&1"
                
                # Should attempt to run main script
                $result | Should -Not -Match "Main processing script not found"
                
            }
            finally {
                Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "Quick-Start.ps1 Help System" {
    
    Context "Help Display" {
        
        It "Should show comprehensive help" {
            $result = & powershell -Command "& '$script:QuickStartScript' 2>&1"
            
            # Check for key help sections
            $result | Should -Match "USAGE:"
            $result | Should -Match "RECOMMENDED WORKFLOW:"
            $result | Should -Match "EXAMPLES:"
            $result | Should -Match "-Setup"
            $result | Should -Match "-DryRun"
            $result | Should -Match "-Process"
        }
        
        It "Should show parameter options" {
            $result = & powershell -Command "& '$script:QuickStartScript' 2>&1"
            $result | Should -Match "-Folder"
            $result | Should -Match "-BatchSize"
        }
    }
}

Describe "Error Handling" {
    
    Context "Graceful Error Handling" {
        
        It "Should handle script errors without crashing" {
            # Test with invalid parameters that should be handled gracefully
            $result = & powershell -Command "& '$script:QuickStartScript' -Process -Folder 'C:\NonExistent\Path' 2>&1"
            
            # Should show error but not crash
            $result | Should -Match "ERROR:"
            $result | Should -Not -Match "Exception"
        }
        
        It "Should handle missing dependencies" {
            # Test behavior when main script is missing
            $tempScript = $script:QuickStartScript + ".temp"
            Copy-Item $script:QuickStartScript $tempScript
            
            try {
                # Modify temp script to point to non-existent main script
                $content = Get-Content $tempScript -Raw
                $content = $content -replace "Process-PDFs-Complete\.ps1", "NonExistent-Script.ps1"
                Set-Content $tempScript $content
                
                $tempFolder = New-Item -Path (Join-Path $env:TEMP "TestFolder_$(Get-Random)") -ItemType Directory
                $testPDF = Join-Path $tempFolder "test.pdf"
                "Fake PDF" | Out-File $testPDF
                
                try {
                    $result = & powershell -Command "& '$tempScript' -DryRun -Folder '$($tempFolder.FullName)' 2>&1"
                    $result | Should -Match "not found"
                }
                finally {
                    Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
                }
                
            }
            finally {
                Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# Helper function to run these tests
function Invoke-QuickStartTests {
    param(
        [string]$OutputFormat = "NUnitXml",
        [string]$OutputFile = (Join-Path $PSScriptRoot "QuickStart-TestResults.xml")
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
    Write-Host "Running Quick-Start.ps1 Tests..." -ForegroundColor Cyan
    Invoke-QuickStartTests
}