# Add Adobe Acrobat to PATH if found
$adobePaths = @(
    "C:\Program Files\Adobe\Acrobat DC\Acrobat",
    "C:\Program Files (x86)\Adobe\Acrobat DC\Acrobat",
    "C:\Program Files\Adobe\Acrobat 2020\Acrobat",
    "C:\Program Files\Adobe\Acrobat XI\Acrobat"
)

$found = $false
foreach ($path in $adobePaths) {
    if (Test-Path "$path\Acrobat.exe") {
        Write-Host "Found Adobe Acrobat at: $path" -ForegroundColor Green
        
        # Add to current session PATH
        $env:PATH = "$path;$env:PATH"
        Write-Host "Added to current session PATH" -ForegroundColor Green
        
        # Instructions for permanent addition
        Write-Host "`nTo make this permanent, add the following to your system PATH:" -ForegroundColor Yellow
        Write-Host $path -ForegroundColor Cyan
        Write-Host "`nOr run this command as Administrator:" -ForegroundColor Yellow
        Write-Host "[Environment]::SetEnvironmentVariable('PATH', `"$path;`" + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')" -ForegroundColor Cyan
        
        $found = $true
        break
    }
}

if (-not $found) {
    Write-Warning "Adobe Acrobat Pro not found in common locations"
    Write-Host "Please ensure Adobe Acrobat Pro (not Reader) is installed" -ForegroundColor Yellow
}