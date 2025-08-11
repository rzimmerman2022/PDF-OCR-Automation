param(
    [Parameter(Mandatory=$true)]
    [string]$InputPdf
)

$ErrorActionPreference = 'Stop'

# Prepare temp workdir
$work = Join-Path $PSScriptRoot 'work'
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Path $work | Out-Null

# Copy input to work as image-only baseline
$orig = Join-Path $work 'original.pdf'
Copy-Item $InputPdf $orig -Force

# Run OCR using Python pipeline in the work folder
$repoRoot = (Resolve-Path "$PSScriptRoot\..\..\").Path
Write-Host "Repo: $repoRoot" -ForegroundColor Gray

# Ensure Python can import src
$env:PYTHONPATH = "$repoRoot\src"

# Invoke ocr_pdfs.py on the work directory
python "$repoRoot\ocr_pdfs.py" "$work"

# Validate AI readability comparison (before vs after)
# Assume in-place OCR overwrote original; copy backup for before
$before = "$orig"
$after = "$orig"

# If backup exists use it as before
$backup = "$orig.backup"
if (Test-Path $backup) {
  $before = $backup
}

python -m src.validators.verify_ai_readable --original "$before" --ocr "$after" --out (Join-Path $work 'ai_readability_test_results.json')

Write-Host "Smoke test artifacts in: $work" -ForegroundColor Cyan
