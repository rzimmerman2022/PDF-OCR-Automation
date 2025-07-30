#!/usr/bin/env pwsh
# Move backup and comm files to _backup folder

$sourceDir = "C:\Projects\Estate Research Project"
$backupDir = Join-Path $sourceDir "_backup"

# Create backup directory if it doesn't exist
if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

Write-Host "Moving backup files to _backup folder..." -ForegroundColor Yellow

# Move .txt files
$txtFiles = Get-ChildItem -Path $sourceDir -Filter "*.txt" -File
foreach ($file in $txtFiles) {
    Write-Host "  Moving: $($file.Name)" -ForegroundColor Gray
    Move-Item -Path $file.FullName -Destination $backupDir -Force
}

# Move .pdfbackup files
$pdfBackups = Get-ChildItem -Path $sourceDir -Filter "*.pdfbackup" -File
foreach ($file in $pdfBackups) {
    Write-Host "  Moving: $($file.Name)" -ForegroundColor Gray
    Move-Item -Path $file.FullName -Destination $backupDir -Force
}

# Move comm*.pdf files
$commPdfs = Get-ChildItem -Path $sourceDir -Filter "comm*.pdf" -File
foreach ($file in $commPdfs) {
    Write-Host "  Moving: $($file.Name)" -ForegroundColor Gray
    Move-Item -Path $file.FullName -Destination $backupDir -Force
}

$totalMoved = $txtFiles.Count + $pdfBackups.Count + $commPdfs.Count
Write-Host "`nMoved $totalMoved files to _backup folder" -ForegroundColor Green