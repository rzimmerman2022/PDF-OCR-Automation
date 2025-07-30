# PDF-OCR-Automation Project Cleanup Script
# This script organizes the project structure for clarity

Write-Host "`n=== PDF-OCR-AUTOMATION PROJECT CLEANUP ===" -ForegroundColor Cyan
Write-Host "Organizing project structure for clarity..." -ForegroundColor Yellow

# Create organized folder structure
$folders = @(
    ".\Archive\Logs",
    ".\Archive\Estate-Scripts",
    ".\Archive\Old-Scripts",
    ".\Archive\Test-Scripts",
    ".\OCR-Scripts",
    ".\OCR-Scripts\PowerShell",
    ".\OCR-Scripts\Python",
    ".\Installation",
    ".\Documentation"
)

Write-Host "`n1. Creating folder structure..." -ForegroundColor Yellow
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "   Created: $folder" -ForegroundColor Gray
    }
}

# Move files to appropriate locations
Write-Host "`n2. Moving files to organized locations..." -ForegroundColor Yellow

# Move all log files to Archive
Write-Host "   Moving log files..." -ForegroundColor Gray
Move-Item -Path ".\*.log" -Destination ".\Archive\Logs" -Force -ErrorAction SilentlyContinue
Move-Item -Path ".\*_log_*.json" -Destination ".\Archive\Logs" -Force -ErrorAction SilentlyContinue
Move-Item -Path ".\collision_log_*.json" -Destination ".\Archive\Logs" -Force -ErrorAction SilentlyContinue
Move-Item -Path ".\processing_log_*.log" -Destination ".\Archive\Logs" -Force -ErrorAction SilentlyContinue

# Move Estate-specific scripts to Archive
Write-Host "   Moving Estate scripts..." -ForegroundColor Gray
$estateScripts = @(
    "Process-Estate-*.ps1",
    "estate_*.py",
    "Test-Estate-*.ps1"
)
foreach ($pattern in $estateScripts) {
    Move-Item -Path ".\$pattern" -Destination ".\Archive\Estate-Scripts" -Force -ErrorAction SilentlyContinue
}

# Move test scripts
Write-Host "   Moving test scripts..." -ForegroundColor Gray
Move-Item -Path ".\test-*.ps1" -Destination ".\Archive\Test-Scripts" -Force -ErrorAction SilentlyContinue
Move-Item -Path ".\basic-ocr-test.ps1" -Destination ".\Archive\Test-Scripts" -Force -ErrorAction SilentlyContinue
Move-Item -Path ".\simple-ocr-test.ps1" -Destination ".\Archive\Test-Scripts" -Force -ErrorAction SilentlyContinue

# Move main OCR scripts to proper location
Write-Host "   Organizing main OCR scripts..." -ForegroundColor Gray
Move-Item -Path ".\Enhanced-OCRmyPDF-Processor.ps1" -Destination ".\OCR-Scripts\PowerShell\" -Force
Move-Item -Path ".\adobe_style_ocr.py" -Destination ".\OCR-Scripts\Python\" -Force
Move-Item -Path ".\verify-ai-readable.py" -Destination ".\OCR-Scripts\Python\" -Force

# Move installation scripts
Write-Host "   Moving installation scripts..." -ForegroundColor Gray
Move-Item -Path ".\install_*.ps1" -Destination ".\Installation\" -Force

# Move old/unused scripts to Archive
Write-Host "   Archiving old scripts..." -ForegroundColor Gray
$oldScripts = @(
    "OCR-Direct-Fix.ps1",
    "Quick-OCR-Fix.ps1",
    "auto_ocr_*.py",
    "cloud_ocr_solution.py",
    "create_searchable_pdf.py",
    "check_pdf_text.py",
    "match_and_embed_text.py",
    "ocr_and_rename_workflow.py",
    "pdf_renamer.py",
    "Restore-CommPDFs.ps1",
    "Move-BackupFiles.ps1",
    "Test-Direct-Rename.ps1"
)
foreach ($script in $oldScripts) {
    Move-Item -Path ".\$script" -Destination ".\Archive\Old-Scripts" -Force -ErrorAction SilentlyContinue
}

# Move documentation to Documentation folder
Write-Host "   Organizing documentation..." -ForegroundColor Gray
$docs = @(
    "OCR-BEST-PRACTICES.md",
    "OCR-FUNCTIONALITY-TEST-RESULTS.md",
    "TESTING_DOCUMENTATION.md",
    "NAMING_CONVENTION_STANDARD.md",
    "COMPLETE_PROJECT_SUMMARY_*.md"
)
foreach ($doc in $docs) {
    Move-Item -Path ".\$doc" -Destination ".\Documentation\" -Force -ErrorAction SilentlyContinue
}

# Clean up test output files
Write-Host "`n3. Cleaning up test outputs..." -ForegroundColor Yellow
Remove-Item -Path ".\Test-PDFs\OCR-Test" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\Test-PDFs\OCR-Python-Test" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\Test-PDFs\*-OCR.pdf" -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\Test-PDFs\*.backup" -Force -ErrorAction SilentlyContinue

Write-Host "`n4. Files to keep in root:" -ForegroundColor Yellow
$keepInRoot = @(
    "README.md",
    "LICENSE",
    "Setup.ps1",
    "Quick-Start.ps1",
    "Universal-PDF-OCR-Processor.ps1",
    "PDFOCRAutomation.psm1",
    "PDFOCRAutomation.psd1"
)

foreach ($file in $keepInRoot) {
    if (Test-Path $file) {
        Write-Host "   [OK] $file" -ForegroundColor Green
    }
}

Write-Host "`n=== CLEANUP COMPLETE ===" -ForegroundColor Green
Write-Host "`nProject structure is now organized!" -ForegroundColor Cyan
Write-Host "Main scripts are in: .\OCR-Scripts" -ForegroundColor Gray
Write-Host "Documentation is in: .\Documentation" -ForegroundColor Gray
Write-Host "Archived files are in: .\Archive" -ForegroundColor Gray