#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Set up your Gemini API key for the PDF-OCR-Automation system
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$APIKey
)

$envPath = Join-Path $PSScriptRoot ".env"

# Validate API key format (basic check)
if ($APIKey.Length -lt 20) {
    Write-Host "Error: API key seems too short. Please provide a valid Gemini API key." -ForegroundColor Red
    exit 1
}

# Write to .env file
"GEMINI_API_KEY=$APIKey" | Set-Content $envPath

Write-Host "`n[OK] API key has been saved to .env file" -ForegroundColor Green
Write-Host "`nYou can now run the PDF processing:" -ForegroundColor Yellow
Write-Host '  .\Process-PDFs-Complete.ps1 -TargetFolder "C:\Projects\Estate Research Project" -SkipDryRun -AutoConfirm' -ForegroundColor Cyan
Write-Host "`nOr use Quick-Start:" -ForegroundColor Yellow
Write-Host '  .\Quick-Start.ps1 -Process -Folder "C:\Projects\Estate Research Project"' -ForegroundColor Cyan