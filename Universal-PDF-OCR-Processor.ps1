# Universal PDF OCR Processor (Wrapper)
# Invokes the enhanced OCRmyPDF processor to create searchable PDFs

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

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "UNIVERSAL PDF OCR PROCESSOR" -ForegroundColor Cyan
Write-Host "This wrapper calls the enhanced OCRmyPDF processor (Tesseract)" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan

# Resolve the enhanced processor path relative to this file
$processorPath = Join-Path -Path $PSScriptRoot -ChildPath 'src\processors\OCRmyPDF-Processor.ps1'

if (-not (Test-Path $processorPath)) {
    Write-Error "Enhanced processor not found: $processorPath"
    Write-Error "Ensure the repository is intact and try again."
    exit 1
}

Write-Host "Using processor: $processorPath" -ForegroundColor Gray

try {
    & $processorPath `
        -InputPath $InputPath `
        -OutputPath $OutputPath `
        -Language $Language `
        -Optimize $Optimize `
        -DPI $DPI `
        $(if ($Grayscale) { '-Grayscale' }) `
        $(if ($CleanPages) { '-CleanPages' }) `
        $(if ($SkipText) { '-SkipText' }) `
        $(if ($WhatIf) { '-WhatIf' })
}
catch {
    Write-Error $_
    exit 1
}
