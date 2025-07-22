#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick OCR fix for comm PDFs using Adobe Acrobat directly
#>

param(
    [string]$TargetFolder = "C:\Projects\Estate Research Project"
)

Write-Host "`n=== Quick OCR Fix for Remaining PDFs ===" -ForegroundColor Cyan

# Get PDFs that need OCR
$pdfsToOCR = Get-ChildItem -Path $TargetFolder -Filter "*.pdf" | Where-Object {
    $_.Name -match "comm\d+\.pdf|New Will signed\.pdf"
}

if ($pdfsToOCR.Count -eq 0) {
    Write-Host "No PDFs need OCR!" -ForegroundColor Green
    return
}

Write-Host "Found $($pdfsToOCR.Count) PDFs needing OCR:" -ForegroundColor Yellow
$pdfsToOCR | ForEach-Object { Write-Host "  - $($_.Name)" }

try {
    Write-Host "`nInitializing Adobe Acrobat..." -ForegroundColor Gray
    $acroApp = New-Object -ComObject AcroExch.App
    $acroApp.Show()
    
    foreach ($pdf in $pdfsToOCR) {
        Write-Host "`nProcessing: $($pdf.Name)" -ForegroundColor Cyan
        
        try {
            # Create PDF document object
            $acroPDDoc = New-Object -ComObject AcroExch.PDDoc
            
            # Open the PDF
            if ($acroPDDoc.Open($pdf.FullName)) {
                Write-Host "  - PDF opened successfully" -ForegroundColor Gray
                
                # Get JavaScript object for OCR
                $jsObject = $acroPDDoc.GetJSObject()
                
                # Perform OCR on all pages
                Write-Host "  - Running OCR..." -ForegroundColor Yellow
                $jsObject.OCRPages(0, ($acroPDDoc.GetNumPages() - 1), "eng", $true)
                
                # Save the OCR'd PDF
                Write-Host "  - Saving OCR'd PDF..." -ForegroundColor Gray
                $acroPDDoc.Save(1, $pdf.FullName)
                
                Write-Host "  [SUCCESS] OCR completed!" -ForegroundColor Green
                
                # Close the document
                $acroPDDoc.Close()
            } else {
                Write-Host "  [ERROR] Failed to open PDF" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "  [ERROR] OCR failed: $_" -ForegroundColor Red
        }
    }
    
    # Clean up
    $acroApp.Exit()
    Write-Host "`nOCR processing complete!" -ForegroundColor Green
    
    # Now run AI renaming on these files
    Write-Host "`n=== Running AI Renaming on OCR'd Files ===" -ForegroundColor Cyan
    
    foreach ($pdf in $pdfsToOCR) {
        Write-Host "`nRenaming: $($pdf.Name)" -ForegroundColor Yellow
        
        $output = & python "$PSScriptRoot\pdf_renamer.py" $pdf.FullName 2>&1
        
        $jsonLine = $output | Where-Object { $_ -match "^RESULT_JSON:" }
        if ($jsonLine) {
            $jsonData = ($jsonLine -replace "^RESULT_JSON:\s*", "") | ConvertFrom-Json
            
            if ($jsonData.status -eq "renamed") {
                Write-Host "  [SUCCESS] -> $($jsonData.new_name)" -ForegroundColor Green
                if ($jsonData.analysis.description) {
                    Write-Host "  Description: $($jsonData.analysis.description)" -ForegroundColor Gray
                }
            }
            elseif ($jsonData.status -eq "error") {
                Write-Host "  [ERROR] $($jsonData.error)" -ForegroundColor Red
            }
        }
    }
}
catch {
    Write-Host "[ERROR] Adobe Acrobat initialization failed: $_" -ForegroundColor Red
    Write-Host "Make sure Adobe Acrobat Pro (not Reader) is installed" -ForegroundColor Yellow
}
finally {
    # Release COM objects
    if ($acroPDDoc) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($acroPDDoc) | Out-Null }
    if ($acroApp) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($acroApp) | Out-Null }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}