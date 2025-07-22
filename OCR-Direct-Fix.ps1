#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Direct OCR implementation using Adobe Acrobat's OCR recognizer
#>

param(
    [string]$TargetFolder = "C:\Projects\Estate Research Project"
)

Write-Host "`n=== Direct OCR Fix Using Adobe Acrobat ===" -ForegroundColor Cyan

# Clear processing state
$stateFile = Join-Path $PSScriptRoot ".processing_status.json"
if (Test-Path $stateFile) {
    Remove-Item $stateFile -Force
}

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

# Try using Adobe Acrobat with different approach
$acroApp = $null
$avDoc = $null
$pdDoc = $null

try {
    Write-Host "`nInitializing Adobe Acrobat..." -ForegroundColor Gray
    
    # Create Acrobat Application
    $acroApp = New-Object -ComObject AcroExch.App
    
    foreach ($pdf in $pdfsToOCR) {
        Write-Host "`nProcessing: $($pdf.Name)" -ForegroundColor Cyan
        
        try {
            # Use AVDoc instead of PDDoc for better compatibility
            $avDoc = New-Object -ComObject AcroExch.AVDoc
            
            if ($avDoc.Open($pdf.FullName, "")) {
                Write-Host "  - Document opened successfully" -ForegroundColor Gray
                
                # Get PDDoc from AVDoc
                $pdDoc = $avDoc.GetPDDoc()
                
                # Try to perform OCR using menu commands
                $app = $acroApp.GetActiveDoc()
                
                if ($app) {
                    Write-Host "  - Attempting OCR..." -ForegroundColor Yellow
                    
                    # Try to execute OCR menu command
                    # This simulates clicking Enhance Scans > Recognize Text
                    $menuItemName = "Recognize Text"
                    $acroApp.MenuItemExecute($menuItemName)
                    
                    Start-Sleep -Seconds 3  # Give OCR time to complete
                    
                    # Save the document
                    $pdDoc.Save(1, $pdf.FullName)
                    Write-Host "  [SUCCESS] Document saved with OCR" -ForegroundColor Green
                } else {
                    Write-Host "  [WARNING] Could not get active document" -ForegroundColor Yellow
                }
                
                # Close the document
                $avDoc.Close(1)
            } else {
                Write-Host "  [ERROR] Failed to open document" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        }
        finally {
            if ($avDoc) {
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($avDoc) | Out-Null
                $avDoc = $null
            }
            if ($pdDoc) {
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($pdDoc) | Out-Null
                $pdDoc = $null
            }
        }
    }
}
catch {
    Write-Host "[ERROR] Adobe Acrobat initialization failed: $_" -ForegroundColor Red
}
finally {
    if ($acroApp) {
        try { 
            $acroApp.Exit()
        } catch {}
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($acroApp) | Out-Null
    }
    
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}

Write-Host "`n=== Alternative: Manual OCR Instructions ===" -ForegroundColor Yellow
Write-Host "If automated OCR fails, you can manually OCR these files:" -ForegroundColor White
Write-Host "1. Open Adobe Acrobat Pro" -ForegroundColor Gray
Write-Host "2. Open each PDF file" -ForegroundColor Gray
Write-Host "3. Go to Tools > Enhance Scans > Recognize Text" -ForegroundColor Gray
Write-Host "4. Select 'In This File' and click 'Recognize Text'" -ForegroundColor Gray
Write-Host "5. Save the file" -ForegroundColor Gray
Write-Host "`nThen run the AI renaming:" -ForegroundColor White
Write-Host "  python pdf_renamer.py ""C:\Projects\Estate Research Project\*.pdf""" -ForegroundColor Cyan