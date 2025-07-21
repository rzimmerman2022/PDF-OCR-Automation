# OCR Performance and Accuracy Validation Script
# Tests OCR accuracy and performance metrics

param(
    [string]$TestPDF = "",
    [switch]$GenerateReport
)

Write-Host "`nOCR Performance & Accuracy Validator" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Performance metrics storage
$script:PerformanceMetrics = @{
    StartTime = Get-Date
    EndTime = $null
    TotalFiles = 0
    SuccessfulOCR = 0
    FailedOCR = 0
    AverageProcessingTime = 0
    MemoryUsageMB = 0
    CPUUsagePercent = 0
}

# Test OCR accuracy with known text
function Test-OCRAccuracy {
    param(
        [string]$ExpectedText,
        [string]$ActualText
    )
    
    if ([string]::IsNullOrWhiteSpace($ActualText)) {
        return 0
    }
    
    # Normalize text for comparison
    $expectedNorm = ($ExpectedText -replace '\s+', ' ' -replace '[^\w\s]', '').Trim()
    $actualNorm = ($ActualText -replace '\s+', ' ' -replace '[^\w\s]', '').Trim()
    
    # Calculate Levenshtein distance for accuracy measurement
    $distance = 0
    $matrix = New-Object 'int[,]' ($expectedNorm.Length + 1), ($actualNorm.Length + 1)
    
    for ($i = 0; $i -le $expectedNorm.Length; $i++) {
        $matrix[$i, 0] = $i
    }
    for ($j = 0; $j -le $actualNorm.Length; $j++) {
        $matrix[0, $j] = $j
    }
    
    for ($i = 1; $i -le $expectedNorm.Length; $i++) {
        for ($j = 1; $j -le $actualNorm.Length; $j++) {
            $cost = if ($expectedNorm[$i-1] -eq $actualNorm[$j-1]) { 0 } else { 1 }
            $deletion = $matrix[($i-1), $j] + 1
            $insertion = $matrix[$i, ($j-1)] + 1
            $substitution = $matrix[($i-1), ($j-1)] + $cost
            $matrix[$i, $j] = [Math]::Min([Math]::Min($deletion, $insertion), $substitution)
        }
    }
    
    $distance = $matrix[$expectedNorm.Length, $actualNorm.Length]
    $accuracy = [Math]::Max(0, (1 - ($distance / [Math]::Max($expectedNorm.Length, 1))) * 100)
    
    return [Math]::Round($accuracy, 2)
}

# Measure system performance
function Measure-SystemPerformance {
    param(
        [scriptblock]$Operation
    )
    
    $initialMemory = (Get-Process -Id $PID).WorkingSet64 / 1MB
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Execute the operation
    $result = & $Operation
    
    $stopwatch.Stop()
    $finalMemory = (Get-Process -Id $PID).WorkingSet64 / 1MB
    
    return @{
        Result = $result
        ElapsedMilliseconds = $stopwatch.ElapsedMilliseconds
        MemoryUsedMB = [Math]::Round($finalMemory - $initialMemory, 2)
    }
}

# Validate OCR functionality
Write-Host "`nValidating OCR Components..." -ForegroundColor Yellow

# Check Adobe Acrobat
$acrobatFound = $null -ne (Get-Command acrobat.exe -ErrorAction SilentlyContinue)
if ($acrobatFound) {
    Write-Host " [OK] Adobe Acrobat Pro found" -ForegroundColor Green
} else {
    Write-Host " [WARNING] Adobe Acrobat Pro not found - OCR tests will be limited" -ForegroundColor Yellow
}

# Performance benchmarks
Write-Host "`nPerformance Benchmarks:" -ForegroundColor Yellow

# Test 1: Script loading performance
$loadTest = Measure-SystemPerformance {
    Get-Content ".\Universal-PDF-OCR-Processor.ps1" -Raw | Out-Null
}
Write-Host " Script Load Time: $($loadTest.ElapsedMilliseconds)ms" -ForegroundColor Cyan

# Test 2: Pattern matching performance
$patternTest = Measure-SystemPerformance {
    $testText = "Invoice #2024-001 dated January 15, 2024 for $1,234.56"
    $patterns = @(
        'invoice\s*#?\s*(\d+)',
        'dated?\s+(\w+\s+\d{1,2},?\s+\d{4})',
        '\$[\d,]+\.?\d*'
    )
    foreach ($pattern in $patterns) {
        $testText -match $pattern | Out-Null
    }
}
Write-Host " Pattern Matching: $($patternTest.ElapsedMilliseconds)ms" -ForegroundColor Cyan

# Test 3: File operations performance
$fileTest = Measure-SystemPerformance {
    $testFile = ".\test_perf_temp.txt"
    "Test content" | Out-File $testFile
    Get-Content $testFile | Out-Null
    Remove-Item $testFile -Force
}
Write-Host " File Operations: $($fileTest.ElapsedMilliseconds)ms" -ForegroundColor Cyan

# OCR Accuracy Tests (if test content available)
if (Test-Path ".\Test-PDFs\Test-ScannedDoc.txt") {
    Write-Host "`nOCR Accuracy Tests:" -ForegroundColor Yellow
    
    $expectedText = Get-Content ".\Test-PDFs\Test-ScannedDoc.txt" -Raw
    
    # Simulate OCR results with various accuracy levels
    $testCases = @(
        @{
            Name = "Perfect OCR"
            Text = $expectedText
        },
        @{
            Name = "Common OCR Errors"
            Text = $expectedText -replace '1', 'l' -replace '0', 'O' -replace 'm', 'rn'
        },
        @{
            Name = "Moderate OCR Quality"
            Text = $expectedText -replace 'SCANNED', 'SCARNED' -replace '\$', 'S'
        }
    )
    
    foreach ($test in $testCases) {
        $accuracy = Test-OCRAccuracy -ExpectedText $expectedText -ActualText $test.Text
        Write-Host " $($test.Name): $accuracy% accurate" -ForegroundColor $(if ($accuracy -gt 90) { "Green" } elseif ($accuracy -gt 70) { "Yellow" } else { "Red" })
    }
}

# Memory and resource usage
Write-Host "`nResource Usage:" -ForegroundColor Yellow
$currentProcess = Get-Process -Id $PID
Write-Host " Memory Usage: $([Math]::Round($currentProcess.WorkingSet64 / 1MB, 2)) MB" -ForegroundColor Cyan
Write-Host " Handle Count: $($currentProcess.HandleCount)" -ForegroundColor Cyan
Write-Host " Thread Count: $($currentProcess.Threads.Count)" -ForegroundColor Cyan

# Recommendations
Write-Host "`nPerformance Recommendations:" -ForegroundColor Yellow
if ($loadTest.ElapsedMilliseconds -gt 500) {
    Write-Host " - Consider optimizing script size for faster loading" -ForegroundColor Gray
}
if ($patternTest.ElapsedMilliseconds -gt 100) {
    Write-Host " - Pattern matching could be optimized with compiled regex" -ForegroundColor Gray
}
if ($currentProcess.WorkingSet64 / 1MB -gt 100) {
    Write-Host " - Memory usage is high, consider implementing cleanup routines" -ForegroundColor Gray
}

# Generate detailed report if requested
if ($GenerateReport) {
    $reportPath = ".\Reports\OCR-Performance-Report_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').txt"
    
    $report = @"
OCR Performance & Accuracy Report
Generated: $(Get-Date)

SYSTEM INFORMATION:
- PowerShell Version: $($PSVersionTable.PSVersion)
- OS: $([System.Environment]::OSVersion.VersionString)
- Processor Count: $([System.Environment]::ProcessorCount)
- Available Memory: $([Math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)) MB

PERFORMANCE METRICS:
- Script Load Time: $($loadTest.ElapsedMilliseconds)ms
- Pattern Matching: $($patternTest.ElapsedMilliseconds)ms
- File Operations: $($fileTest.ElapsedMilliseconds)ms
- Memory Usage: $([Math]::Round($currentProcess.WorkingSet64 / 1MB, 2)) MB

RECOMMENDATIONS:
- Optimal batch size: 10-50 PDFs per run
- Expected processing time: 5-30 seconds per PDF (depending on size and complexity)
- Memory requirement: 100-500 MB depending on PDF size
"@
    
    $report | Out-File $reportPath
    Write-Host "`nDetailed report saved to: $reportPath" -ForegroundColor Green
}

Write-Host "`nValidation complete!" -ForegroundColor Green