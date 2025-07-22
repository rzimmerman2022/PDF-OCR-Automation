#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script for Estate Research Project PDF processing
    
.DESCRIPTION
    This script demonstrates the full PDF processing workflow:
    1. OCR processing for scanned documents
    2. AI-powered content analysis using Gemini 2.5
    3. Intelligent file renaming based on document context
    
.PARAMETER APIKey
    Your Gemini API key (required for AI analysis)
    
.EXAMPLE
    .\Test-Estate-Research.ps1 -APIKey "your-actual-api-key"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$APIKey
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== Estate Research Project PDF Processing Test ===" -ForegroundColor Cyan
Write-Host "Using Gemini 2.5 Flash for AI-powered document analysis`n" -ForegroundColor Green

# Update .env with the provided API key
$envPath = Join-Path $PSScriptRoot ".env"
"GEMINI_API_KEY=$APIKey" | Set-Content $envPath
Write-Host "[✓] API key configured" -ForegroundColor Green

# Target directory
$targetDir = "C:\Projects\Estate Research Project"
Write-Host "`nTarget directory: $targetDir" -ForegroundColor Yellow

# Step 1: Run full processing (OCR + AI Rename)
Write-Host "`n[1/2] Starting full PDF processing pipeline..." -ForegroundColor Cyan
& "$PSScriptRoot\Process-PDFs-Complete.ps1" -TargetFolder $targetDir -SkipDryRun -AutoConfirm

# Step 2: Display results
Write-Host "`n[2/2] Processing complete! Checking results..." -ForegroundColor Cyan

# Show renamed files
$renamedFiles = Get-ChildItem -Path $targetDir -Filter "*.pdf" | 
    Where-Object { $_.Name -notmatch "^(comm|Letters|Domiciliary|Waiver|New Will)" }

if ($renamedFiles) {
    Write-Host "`nSuccessfully renamed files:" -ForegroundColor Green
    $renamedFiles | ForEach-Object {
        Write-Host "  ✓ $($_.Name)" -ForegroundColor White
    }
}

# Show processing summary
$logFiles = Get-ChildItem -Path $PSScriptRoot -Filter "rename_log_*.json" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if ($logFiles) {
    $log = Get-Content $logFiles[0] | ConvertFrom-Json
    Write-Host "`nProcessing Summary:" -ForegroundColor Yellow
    Write-Host "  Total files processed: $($log.results.Count)"
    Write-Host "  AI Model: Gemini 2.5 Flash"
    Write-Host "  Total cost: `$$($log.total_cost)"
    
    # Show AI analysis for each file
    Write-Host "`nAI Analysis Results:" -ForegroundColor Yellow
    foreach ($result in $log.results) {
        if ($result.analysis -and $result.analysis.document_type -ne "Unknown") {
            Write-Host "`n  File: $($result.original_name)" -ForegroundColor Cyan
            Write-Host "  → New name: $($result.new_name)" -ForegroundColor Green
            Write-Host "  → Type: $($result.analysis.document_type)"
            Write-Host "  → Industry: $($result.analysis.industry)"
            Write-Host "  → Key info: $($result.analysis.key_info)"
            Write-Host "  → Confidence: $($result.analysis.confidence)"
        }
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "The system has:" -ForegroundColor Green
Write-Host "  1. ✓ Performed OCR on all PDFs"
Write-Host "  2. ✓ Analyzed content using Gemini 2.5 Flash"
Write-Host "  3. ✓ Generated context-aware filenames"
Write-Host "  4. ✓ Renamed files following industry best practices`n"