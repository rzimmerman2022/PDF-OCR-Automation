#!/usr/bin/env pwsh
# Process Estate Research PDFs in batches
param(
    [string]$TargetFolder = "C:\Projects\Estate Research Project",
    [int]$BatchSize = 5
)

$pdfs = Get-ChildItem -Path $TargetFolder -Filter "*.pdf" | Select-Object -First $BatchSize
$totalCost = 0.0

Write-Host "`nProcessing $($pdfs.Count) PDFs with Gemini 2.5 Flash AI..." -ForegroundColor Cyan

foreach ($pdf in $pdfs) {
    Write-Host "`nProcessing: $($pdf.Name)" -ForegroundColor Yellow
    
    $output = & python "$PSScriptRoot\pdf_renamer.py" $pdf.FullName 2>&1
    
    # Show output
    $output | ForEach-Object { Write-Host $_ }
    
    # Check if renamed
    if ($output -match "RESULT_JSON:") {
        $jsonLine = $output | Where-Object { $_ -match "^RESULT_JSON:" }
        if ($jsonLine) {
            $jsonData = ($jsonLine -replace "^RESULT_JSON:\s*", "") | ConvertFrom-Json
            if ($jsonData.status -eq "renamed") {
                $totalCost += 0.0006
                Write-Host "Success! New name: $($jsonData.new_name)" -ForegroundColor Green
            }
        }
    }
    
    Start-Sleep -Seconds 1
}

Write-Host "`nBatch complete. Total cost: `$$($totalCost.ToString('F4'))" -ForegroundColor Yellow