#!/usr/bin/env pwsh
# Restore comm*.pdf files that were incorrectly moved

$backupDir = "C:\Projects\Estate Research Project\_backup"
$mainDir = "C:\Projects\Estate Research Project"

Write-Host "Restoring comm*.pdf files to main directory..." -ForegroundColor Yellow

$commPdfs = Get-ChildItem -Path $backupDir -Filter "comm*.pdf" -File
foreach ($file in $commPdfs) {
    Write-Host "  Restoring: $($file.Name)" -ForegroundColor Gray
    Move-Item -Path $file.FullName -Destination $mainDir -Force
}

Write-Host "`nRestored $($commPdfs.Count) comm*.pdf files" -ForegroundColor Green