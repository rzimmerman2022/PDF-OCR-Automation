# OCR Settings & Optimization Guide

This guide covers best practices and optimization techniques for maximizing OCR accuracy and performance.

## Table of Contents
- [OCR Quality Settings](#ocr-quality-settings)
- [Performance Optimization](#performance-optimization)
- [Language Configuration](#language-configuration)
- [Batch Processing Tips](#batch-processing-tips)
- [Advanced Techniques](#advanced-techniques)

---

## OCR Quality Settings

### Optimal Scan Settings

For best OCR results, ensure source documents meet these specifications:

| Setting | Recommended | Minimum | Notes |
|---------|-------------|---------|-------|
| Resolution | 300 DPI | 200 DPI | Higher DPI improves accuracy |
| Color Mode | B&W (1-bit) | Grayscale | Color only if needed |
| File Format | PDF | TIFF | Avoid lossy compression |
| Page Size | Standard | Any | Consistent sizing helps |
| Orientation | Portrait | Any | Auto-rotation available |

### Pre-Processing Tips

```powershell
# Function to check PDF quality
function Test-PDFQuality {
    param([string]$PDFPath)
    
    $file = Get-Item $PDFPath
    $sizeMB = [Math]::Round($file.Length / 1MB, 2)
    
    # Rough quality indicators
    $quality = @{
        FileSize = $sizeMB
        PagesEstimate = [Math]::Floor($sizeMB / 0.5)  # ~0.5MB per page for 300DPI
        QualityRating = if ($sizeMB -lt 0.1) { "Low" } 
                       elseif ($sizeMB -lt 1) { "Medium" } 
                       else { "High" }
    }
    
    return $quality
}

# Check your PDFs
Get-ChildItem ".\Documents\*.pdf" | ForEach-Object {
    $quality = Test-PDFQuality $_.FullName
    Write-Host "$($_.Name): $($quality.QualityRating) quality ($($quality.FileSize) MB)"
}
```

### Improving Scan Quality

1. **Clean Scanner Glass**
   - Remove dust and smudges
   - Use appropriate cleaning solution

2. **Document Preparation**
   - Flatten creased pages
   - Remove staples/clips
   - Align pages properly

3. **Scanner Settings**
   ```
   Resolution: 300 DPI
   Color Mode: Black & White
   File Type: PDF
   Compression: None or Lossless
   Auto-Crop: Enabled
   Deskew: Enabled
   ```

---

## Performance Optimization

### Memory Management

```powershell
# Add to script for better memory handling
function Optimize-Memory {
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
}

# Call after processing each batch
Optimize-Memory
```

### Parallel Processing

```powershell
# Process multiple PDFs in parallel (requires PowerShell 7+)
$files = Get-ChildItem ".\Documents\*.pdf"
$files | ForEach-Object -Parallel {
    # Process each file
    & ".\Universal-PDF-OCR-Processor.ps1" -TargetFolder $_.DirectoryName -WhatIf
} -ThrottleLimit 4
```

### Batch Size Optimization

| System RAM | Recommended Batch | Max Concurrent |
|------------|------------------|----------------|
| 4 GB | 5-10 files | 1 |
| 8 GB | 10-25 files | 2 |
| 16 GB | 25-50 files | 4 |
| 32 GB+ | 50-100 files | 8 |

```powershell
# Adaptive batch sizing based on available memory
function Get-OptimalBatchSize {
    $totalRAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    $availableRAM = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB / 1024
    
    $batchSize = [Math]::Floor($availableRAM * 10)  # ~100MB per PDF estimate
    return [Math]::Min($batchSize, 50)  # Cap at 50 files
}

$optimalBatch = Get-OptimalBatchSize
Write-Host "Optimal batch size: $optimalBatch files"
```

---

## Language Configuration

### Multi-Language OCR Setup

Update the main script to support multiple languages:

```powershell
# Enhanced language configuration
$ocrLanguages = @{
    "eng" = @{Name = "English"; Code = "eng"}
    "spa" = @{Name = "Spanish"; Code = "spa"}
    "fra" = @{Name = "French"; Code = "fra"}
    "deu" = @{Name = "German"; Code = "deu"}
    "ita" = @{Name = "Italian"; Code = "ita"}
    "por" = @{Name = "Portuguese"; Code = "por"}
    "rus" = @{Name = "Russian"; Code = "rus"}
    "chi_sim" = @{Name = "Chinese (Simplified)"; Code = "chi_sim"}
    "chi_tra" = @{Name = "Chinese (Traditional)"; Code = "chi_tra"}
    "jpn" = @{Name = "Japanese"; Code = "jpn"}
    "kor" = @{Name = "Korean"; Code = "kor"}
    "ara" = @{Name = "Arabic"; Code = "ara"}
}

# Auto-detect language based on content
function Detect-DocumentLanguage {
    param([string]$Text)
    
    # Simple language detection patterns
    $patterns = @{
        "spa" = '[áéíóúñ¿¡]'
        "fra" = '[àâçèéêëîïôùûü]'
        "deu" = '[äöüßÄÖÜ]'
        "rus" = '[а-яА-Я]'
        "chi" = '[\u4e00-\u9fff]'
        "jpn" = '[\u3040-\u309f\u30a0-\u30ff]'
        "ara" = '[\u0600-\u06ff]'
    }
    
    foreach ($lang in $patterns.Keys) {
        if ($Text -match $patterns[$lang]) {
            return $lang
        }
    }
    
    return "eng"  # Default to English
}
```

### Language-Specific Optimization

```powershell
# OCR settings by language
$languageSettings = @{
    "eng" = @{DPI = 300; Preprocessing = "standard"}
    "chi_sim" = @{DPI = 400; Preprocessing = "enhanced"}
    "ara" = @{DPI = 400; Preprocessing = "bidi"}
    "jpn" = @{DPI = 400; Preprocessing = "vertical"}
}
```

---

## Batch Processing Tips

### Progress Tracking

```powershell
# Add progress bar to main script
$totalFiles = $pdfFiles.Count
$currentFile = 0

foreach ($pdf in $pdfFiles) {
    $currentFile++
    $percentComplete = ($currentFile / $totalFiles) * 100
    
    Write-Progress -Activity "Processing PDFs" `
                   -Status "File $currentFile of $totalFiles" `
                   -PercentComplete $percentComplete `
                   -CurrentOperation $pdf.Name
    
    # Process file...
}
```

### Error Recovery

```powershell
# Implement retry logic for failed files
$maxRetries = 3
$retryDelay = 5  # seconds

function Process-PDFWithRetry {
    param(
        [string]$FilePath,
        [int]$MaxAttempts = 3
    )
    
    $attempt = 0
    $success = $false
    
    while ($attempt -lt $MaxAttempts -and -not $success) {
        $attempt++
        
        try {
            # Attempt processing
            $result = Process-PDFWithOCR -FilePath $FilePath -WhatIfMode:$false
            $success = $true
        }
        catch {
            Write-Warning "Attempt $attempt failed for $FilePath"
            if ($attempt -lt $MaxAttempts) {
                Start-Sleep -Seconds $retryDelay
            }
        }
    }
    
    return $success
}
```

### Performance Monitoring

```powershell
# Track processing statistics
$stats = @{
    StartTime = Get-Date
    ProcessedCount = 0
    SuccessCount = 0
    FailedCount = 0
    TotalSizeMB = 0
    AverageTimeSec = 0
}

# After each file
$stats.ProcessedCount++
$stats.TotalSizeMB += (Get-Item $pdf.FullName).Length / 1MB

# Generate report
function Get-ProcessingReport {
    $duration = (Get-Date) - $stats.StartTime
    $avgTime = $duration.TotalSeconds / $stats.ProcessedCount
    
    @"
Processing Statistics
====================
Total Files: $($stats.ProcessedCount)
Successful: $($stats.SuccessCount)
Failed: $($stats.FailedCount)
Total Size: $([Math]::Round($stats.TotalSizeMB, 2)) MB
Duration: $($duration.ToString('hh\:mm\:ss'))
Avg Time/File: $([Math]::Round($avgTime, 2)) seconds
Processing Rate: $([Math]::Round($stats.ProcessedCount / $duration.TotalMinutes, 2)) files/min
"@
}
```

---

## Advanced Techniques

### Custom OCR Zones

```powershell
# Define specific regions for OCR
function Set-OCRZones {
    param($PDDoc)
    
    $jsObject = $PDDoc.GetJSObject()
    
    # Define zones (in points, 72 points = 1 inch)
    $zones = @(
        @{Name = "Header"; X = 72; Y = 72; Width = 468; Height = 100}
        @{Name = "Body"; X = 72; Y = 180; Width = 468; Height = 500}
        @{Name = "Footer"; X = 72; Y = 700; Width = 468; Height = 50}
    )
    
    foreach ($zone in $zones) {
        # Apply OCR to specific zone
        $rect = $jsObject.newRect($zone.X, $zone.Y, 
                                  $zone.X + $zone.Width, 
                                  $zone.Y + $zone.Height)
        # Process zone...
    }
}
```

### OCR Confidence Scoring

```powershell
# Analyze OCR quality
function Get-OCRConfidence {
    param([string]$Text)
    
    $indicators = @{
        GarbageChars = ($Text -match '[■□▪▫◆◇○●]').Count
        RandomChars = ($Text -match '[^\w\s\.\,\;\:\!\?\-]').Count
        WordRatio = ($Text -split '\s+' | Where-Object {$_.Length -gt 2}).Count / 
                   ($Text -split '\s+').Count
    }
    
    # Calculate confidence (0-100)
    $confidence = 100
    $confidence -= $indicators.GarbageChars * 5
    $confidence -= $indicators.RandomChars * 2
    $confidence *= $indicators.WordRatio
    
    return [Math]::Max(0, [Math]::Min(100, $confidence))
}
```

### Post-OCR Cleanup

```powershell
# Clean up common OCR errors
function Repair-OCRText {
    param([string]$Text)
    
    # Common OCR substitutions
    $replacements = @{
        ' l ' = ' I '      # lowercase L to uppercase I
        'l\b' = 'I'        # ending lowercase L
        '\brn' = 'm'       # rn to m
        '\bvv' = 'w'       # vv to w
        '0' = 'O'          # zero to O in text context
        '1' = 'I'          # one to I in text context
        '\s+' = ' '        # multiple spaces
        '\.{2,}' = '.'     # multiple periods
    }
    
    $cleaned = $Text
    foreach ($pattern in $replacements.Keys) {
        $cleaned = $cleaned -replace $pattern, $replacements[$pattern]
    }
    
    return $cleaned.Trim()
}
```

---

## Quick Reference Card

### Command-Line Options

```powershell
# High-quality OCR
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Documents" `
    -DocumentType auto -DetailedOutput

# Specific language
$env:OCR_LANGUAGE = "spa"
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Spanish-Docs"

# Performance mode
$env:OCR_QUALITY = "fast"
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Large-Batch"

# Debug mode
$DebugPreference = "Continue"
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Test" -WhatIf
```

### Environment Variables

| Variable | Purpose | Values |
|----------|---------|--------|
| OCR_LANGUAGE | Default OCR language | eng, spa, fra, etc. |
| OCR_QUALITY | Processing quality | fast, balanced, best |
| OCR_THREADS | Parallel processing | 1-8 |
| OCR_TIMEOUT | Max time per file | seconds (default: 300) |

---

## Benchmarks & Expected Performance

### Processing Times (per page)

| Quality | Simple Text | Mixed Content | Complex Layout |
|---------|-------------|---------------|----------------|
| Fast | 2-5 sec | 5-10 sec | 10-20 sec |
| Balanced | 5-10 sec | 10-20 sec | 20-40 sec |
| Best | 10-20 sec | 20-40 sec | 40-60 sec |

### Accuracy Expectations

| Document Type | Expected Accuracy | Notes |
|---------------|------------------|-------|
| Printed Text | 98-99% | Modern fonts |
| Typewritten | 95-98% | Good condition |
| Handwritten | 70-90% | Varies greatly |
| Poor Quality Scan | 80-95% | Depends on degradation |
| Multi-column | 90-95% | May need zones |

---

For more optimization tips specific to your use case, run:
```powershell
.\Tests\Test-OCRPerformance.ps1 -GenerateReport
```