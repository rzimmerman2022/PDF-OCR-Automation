#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete PDF Processing Engine with OCR and AI Renaming
    Core component of the PDF-OCR-Automation system

.DESCRIPTION
    Comprehensive PDF processing pipeline that:
    1. Scans directory for PDF files
    2. Performs OCR on searchable/non-searchable PDFs
    3. Uses AI to analyze and rename files with descriptive names
    4. Tracks processing state and costs
    5. Provides detailed logging and error handling
    
    This script serves as the main processing engine, handling the complete
    workflow from file discovery through OCR processing to AI-powered renaming.
    It maintains state between runs, allowing for resumable processing and
    preventing duplicate work.

.PARAMETER TargetFolder
    Directory containing PDF files to process

.PARAMETER APIKey
    Gemini API key (can also be set via GEMINI_API_KEY environment variable or .env file)

.PARAMETER BatchSize
    Number of files to process in each batch (default: 5)

.PARAMETER SkipDryRun
    Skip dry run analysis and go directly to renaming (saves API costs)

.PARAMETER AutoConfirm
    Automatically confirm processing without user prompts

.PARAMETER LogLevel
    Logging level: Debug, Info, Warning, Error (default: Info)

.EXAMPLE
    .\Process-PDFs-Complete.ps1 -TargetFolder "C:\PDFs" -SkipDryRun -AutoConfirm
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetFolder,
    
    [string]$APIKey = "",
    
    [int]$BatchSize = 5,
    
    [switch]$SkipDryRun,
    
    [switch]$AutoConfirm,
    
    [ValidateSet("Debug", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info",
    
    [switch]$ForceRenameAll
)

# Script initialization
# Store the script's directory path for relative file references throughout execution
$script:ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create unique log file for this session with timestamp to prevent conflicts
# Format: processing_log_20250121_143052.log for easy chronological sorting
$script:LogFile = Join-Path $script:ScriptRoot "processing_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# State file tracks processing status of each PDF file across sessions
# This enables resumable processing and prevents duplicate API calls
$script:StateFile = Join-Path $script:ScriptRoot ".processing_status.json"
$script:ProcessingState = @{}

# Store ForceRenameAll flag at script level
$script:ForceRenameAll = $ForceRenameAll

# Session statistics for comprehensive tracking and reporting
# These metrics help monitor processing efficiency and API costs
$script:SessionStats = @{
    TotalFiles = 0
    FilesNeedingOCR = 0
    FilesNeedingRename = 0
    FilesAlreadyComplete = 0
    OCRProcessed = 0
    AIRenamed = 0
    Errors = 0
    TotalCost = 0.0
    StartTime = Get-Date
}

# Import required modules
if (Get-Module -ListAvailable -Name "Microsoft.PowerShell.Archive") {
    Import-Module Microsoft.PowerShell.Archive -Force
}

#region Logging Functions
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info",
        [string]$Color = $null
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Only log if level is appropriate
    $logLevels = @("Debug", "Info", "Warning", "Error")
    $currentLevelIndex = $logLevels.IndexOf($script:LogLevel)
    $messageLevelIndex = $logLevels.IndexOf($Level)
    
    if ($messageLevelIndex -ge $currentLevelIndex) {
        # Console output with color
        $consoleColor = switch ($Level) {
            "Debug" { "Gray" }
            "Info" { if ($Color) { $Color } else { "White" } }
            "Warning" { "Yellow" }
            "Error" { "Red" }
        }
        Write-Host $logEntry -ForegroundColor $consoleColor
    }

    # Write to log file with retry logic
    try {
        $retryCount = 0
        $maxRetries = 3
        $logWritten = $false

        while (-not $logWritten -and $retryCount -lt $maxRetries) {
            try {
                Add-Content -Path $script:LogFile -Value $logEntry -ErrorAction Stop
                $logWritten = $true
            }
            catch {
                $retryCount++
                Start-Sleep -Milliseconds (50 * $retryCount)
            }
        }

        if (-not $logWritten) {
            # Create unique log file to avoid conflicts
            $uniqueLogFile = $script:LogFile -replace "\.log$", "_$(Get-Random).log"
            Add-Content -Path $uniqueLogFile -Value $logEntry -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Silent fail for logging - don't break the pipeline
    }
}

function Write-Progress-Custom {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete,
        [string]$CurrentOperation
    )

    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete -CurrentOperation $CurrentOperation
    Write-Log "Progress: $Activity - $Status ($PercentComplete%) - $CurrentOperation" -Level "Debug"
}
#endregion

#region State Management
function Load-ProcessingState {
    if (Test-Path $script:StateFile) {
        try {
            $stateJson = Get-Content $script:StateFile -Raw | ConvertFrom-Json
            $script:ProcessingState = @{}
            $stateJson.PSObject.Properties | ForEach-Object {
                $script:ProcessingState[$_.Name] = $_.Value
            }
            Write-Log "Loaded processing state for $($script:ProcessingState.Count) files" -Level "Info"
        }
        catch {
            Write-Log "Failed to load processing state: $($_.Exception.Message)" -Level "Warning"
            $script:ProcessingState = @{}
        }
    }
}

function Save-ProcessingState {
    try {
        $script:ProcessingState | ConvertTo-Json -Depth 3 | Out-File $script:StateFile -Encoding UTF8
        Write-Log "Saved processing state for $($script:ProcessingState.Count) files" -Level "Debug"
    }
    catch {
        Write-Log "Failed to save processing state: $($_.Exception.Message)" -Level "Warning"
    }
}

function Update-FileState {
    param(
        [string]$FilePath,
        [string]$Status,
        [hashtable]$Properties = @{}
    )

    $fileName = (Get-Item $FilePath).Name
    $fileInfo = @{
        Status = $Status
        LastProcessed = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        FilePath = $FilePath
    }

    foreach ($key in $Properties.Keys) {
        $fileInfo[$key] = $Properties[$key]
    }

    $script:ProcessingState[$fileName] = $fileInfo
    Save-ProcessingState
}

function Get-FileState {
    param([string]$FilePath)
    
    $fileName = (Get-Item $FilePath).Name
    return $script:ProcessingState[$fileName]
}
#endregion

#region API Key Management
function Get-APIKey {
    # Load API key from .env file if it exists and no key provided
    if (-not $APIKey -and -not $env:GEMINI_API_KEY) {
        $envFile = Join-Path $script:ScriptRoot ".env"
        if (Test-Path $envFile) {
            Write-Log "Loading API key from .env file" -Level "Info"
            Get-Content $envFile | ForEach-Object {
                if ($_ -match '^GEMINI_API_KEY=(.+)$') {
                    $env:GEMINI_API_KEY = $matches[1].Trim().Trim('"').Trim("'")
                    Write-Log "API key loaded from .env file" -Level "Info" -Color "Green"
                }
            }
        }
    }

    # Use API key from parameter or environment
    $apiKeyToUse = if ($APIKey) { $APIKey } else { $env:GEMINI_API_KEY }
    
    if ($apiKeyToUse) {
        $keyPreview = $apiKeyToUse.Substring(0, [Math]::Min(10, $apiKeyToUse.Length)) + "..."
        Write-Log "API key found: $keyPreview" -Level "Info" -Color "Green"
    }
    
    return $apiKeyToUse
}
#endregion

#region File Analysis
function Test-IsGenericFilename {
    param([string]$FileName)

    $genericPatterns = @(
        "_TestDetails_\d+\.",
        "document\d*\.",
        "file\d*\.",
        "scan\d*\.",
        "pdf\d*\.",
        "untitled\d*\.",
        "\d{8,}\.",
        "[a-f0-9]{8,}\."
    )

    foreach ($pattern in $genericPatterns) {
        if ($FileName -match $pattern) {
            return $true
        }
    }
    return $false
}

function Test-NeedsOCR {
    param([string]$FilePath)
    
    # Check if file has been OCR processed
    $fileState = Get-FileState -FilePath $FilePath
    if ($fileState -and $fileState.Status -eq "OCR_Complete") {
        return $false
    }
    
    # Add your OCR detection logic here
    # For now, assume all PDFs might need OCR
    return $true
}

function Analyze-PDFFiles {
    param([string[]]$FilePaths)

    $analysis = @{
        Total = $FilePaths.Count
        Unknown = @()
        NeedsOCR = @()
        NeedsRename = @()
        Complete = @()
    }

    Write-Log "Analyzing $($FilePaths.Count) PDF files..." -Level "Info"

    foreach ($pdf in $FilePaths) {
        $fileName = (Get-Item $pdf).Name
        $needsOCR = Test-NeedsOCR -FilePath $pdf
        $needsRename = if ($script:ForceRenameAll) { $true } else { Test-IsGenericFilename -FileName $fileName }

        # Check existing state
        $fileState = Get-FileState -FilePath $pdf
        if ($fileState) {
            if ($fileState.Status -eq "AI_Renamed" -or $fileState.Status -eq "SkippedRename") {
                $needsRename = $false
            }
            if ($fileState.Status -eq "OCR_Complete") {
                $needsOCR = $false
            }
        }

        # Categorize files
        if ($needsOCR -and $needsRename) {
            $analysis.Unknown += $pdf
        }
        elseif ($needsOCR) {
            $analysis.NeedsOCR += $pdf
        }
        elseif ($needsRename) {
            $analysis.NeedsRename += $pdf
        }
        else {
            $analysis.Complete += $pdf
        }
    }

    # Update session stats
    $script:SessionStats.TotalFiles = $analysis.Total
    $script:SessionStats.FilesNeedingOCR = $analysis.NeedsOCR.Count + $analysis.Unknown.Count
    $script:SessionStats.FilesNeedingRename = $analysis.NeedsRename.Count + $analysis.Unknown.Count
    $script:SessionStats.FilesAlreadyComplete = $analysis.Complete.Count

    Write-Log "Analysis complete:" -Level "Info" -Color "Cyan"
    Write-Log "  Total files: $($analysis.Total)" -Level "Info"
    Write-Log "  Need OCR only: $($analysis.NeedsOCR.Count)" -Level "Info"
    Write-Log "  Need rename only: $($analysis.NeedsRename.Count)" -Level "Info"
    Write-Log "  Need both OCR and rename: $($analysis.Unknown.Count)" -Level "Info"
    Write-Log "  Already complete: $($analysis.Complete.Count)" -Level "Info"

    return $analysis
}
#endregion

#region User Interaction
function Get-UserConfirmation {
    param(
        [string]$Message,
        [switch]$AutoConfirm
    )

    if ($AutoConfirm) {
        Write-Log "Auto-confirming: $Message" -Level "Info" -Color "Green"
        return $true
    }

    do {
        $response = Read-Host "$Message (y/n)"
        $response = $response.ToLower()
    } while ($response -notin @("y", "yes", "n", "no"))

    return $response -in @("y", "yes")
}
#endregion

#region OCR Processing
function Invoke-OCRProcessing {
    param(
        [string[]]$FilePaths,
        [int]$BatchSize = 5
    )

    Write-Log "Starting OCR processing for $($FilePaths.Count) files..." -Level "Info" -Color "Cyan"
    
    $processedCount = 0
    $errorCount = 0
    
    # Initialize Adobe Acrobat once for all files
    $acroApp = $null
    $acroPDDoc = $null
    
    try {
        Write-Log "Initializing Adobe Acrobat Pro..." -Level "Info"
        $acroApp = New-Object -ComObject AcroExch.App -ErrorAction Stop
        $acroApp.Show() | Out-Null
        
        for ($i = 0; $i -lt $FilePaths.Count; $i += $BatchSize) {
            $batch = $FilePaths[$i..[Math]::Min($i + $BatchSize - 1, $FilePaths.Count - 1)]
            
            Write-Progress-Custom -Activity "OCR Processing" -Status "Processing batch $([Math]::Floor($i / $BatchSize) + 1)" -PercentComplete ([Math]::Round(($i / $FilePaths.Count) * 100)) -CurrentOperation "Files $($i + 1) to $($i + $batch.Count)"

            foreach ($file in $batch) {
                try {
                    Write-Log "OCR processing: $(Split-Path $file -Leaf)" -Level "Info"
                    
                    # Create PDF document object
                    $acroPDDoc = New-Object -ComObject AcroExch.PDDoc
                    
                    # Open the PDF
                    if ($acroPDDoc.Open($file)) {
                        # Get JavaScript object for OCR operations
                        $jsObject = $acroPDDoc.GetJSObject()
                        
                        if ($jsObject) {
                            # Perform OCR on all pages (English)
                            try {
                                $numPages = $acroPDDoc.GetNumPages()
                                $jsObject.OCRPages(0, ($numPages - 1), "eng", $true)
                                
                                # Save the OCR'd PDF
                                $saveResult = $acroPDDoc.Save(1, $file)
                                
                                if ($saveResult) {
                                    Update-FileState -FilePath $file -Status "OCR_Complete"
                                    $processedCount++
                                    $script:SessionStats.OCRProcessed++
                                    Write-Log "OCR completed: $(Split-Path $file -Leaf)" -Level "Info" -Color "Green"
                                } else {
                                    throw "Failed to save OCR'd PDF"
                                }
                            }
                            catch {
                                # Fallback: Try without language parameter
                                Write-Log "Trying OCR with default language settings..." -Level "Debug"
                                $jsObject.OCRPages()
                                $acroPDDoc.Save(1, $file)
                                
                                Update-FileState -FilePath $file -Status "OCR_Complete"
                                $processedCount++
                                $script:SessionStats.OCRProcessed++
                                Write-Log "OCR completed (default language): $(Split-Path $file -Leaf)" -Level "Info" -Color "Green"
                            }
                        } else {
                            throw "Failed to get JavaScript object for OCR"
                        }
                        
                        # Close the document
                        $acroPDDoc.Close()
                    } else {
                        throw "Failed to open PDF file"
                    }
                }
                catch {
                    Write-Log "OCR failed for $(Split-Path $file -Leaf): $($_.Exception.Message)" -Level "Error"
                    Update-FileState -FilePath $file -Status "OCR_Error" -Properties @{ Error = $_.Exception.Message }
                    $errorCount++
                    $script:SessionStats.Errors++
                }
                finally {
                    # Clean up PDF document object
                    if ($acroPDDoc) {
                        try { $acroPDDoc.Close() } catch {}
                        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($acroPDDoc) | Out-Null
                        $acroPDDoc = $null
                    }
                }
            }
        }
    }
    catch {
        Write-Log "Adobe Acrobat initialization failed: $($_.Exception.Message)" -Level "Error"
        Write-Log "Please ensure Adobe Acrobat Pro (not Reader) is installed" -Level "Warning"
        $errorCount = $FilePaths.Count
    }
    finally {
        # Clean up Adobe Acrobat application
        if ($acroApp) {
            try { $acroApp.Exit() } catch {}
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($acroApp) | Out-Null
            $acroApp = $null
        }
        
        # Force garbage collection
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
    }

    Write-Progress -Activity "OCR Processing" -Completed
    Write-Log "OCR processing completed. Processed: $processedCount, Errors: $errorCount" -Level "Info" -Color "Cyan"
    
    return @{
        ProcessedCount = $processedCount
        ErrorCount = $errorCount
    }
}
#endregion

#region AI Renaming
function Invoke-AIRenaming {
    param(
        [string[]]$FilePaths,
        [string]$APIKey,
        [bool]$DryRun = $true
    )

    if ($FilePaths.Count -eq 0) {
        Write-Log "No files provided for AI renaming" -Level "Warning"
        return @()
    }

    $pythonScript = Join-Path $script:ScriptRoot "pdf_renamer.py"
    if (-not (Test-Path $pythonScript)) {
        throw "Python script not found: $pythonScript"
    }

    # Build Python command
    $pythonArgs = @($pythonScript)
    $pythonArgs += $FilePaths
    
    if ($APIKey) {
        $pythonArgs += "--api-key"
        $pythonArgs += $APIKey
    }
    
    if ($DryRun) {
        $pythonArgs += "--dry-run"
    }

    Write-Log "Executing AI renaming with Python script..." -Level "Info"
    Write-Log "Command: python $($pythonArgs -join ' ')" -Level "Debug"

    try {
        $output = & python $pythonArgs 2>&1
        $results = @()
        $summary = $null

        # Parse output
        foreach ($line in $output) {
            if ($line -match '^RESULT_JSON: (.+)$') {
                try {
                    $result = $matches[1] | ConvertFrom-Json
                    $results += $result
                }
                catch {
                    Write-Log "Failed to parse result JSON: $line" -Level "Warning"
                }
            }
            elseif ($line -match '^SUMMARY_JSON: (.+)$') {
                try {
                    $summary = $matches[1] | ConvertFrom-Json
                }
                catch {
                    Write-Log "Failed to parse summary JSON: $line" -Level "Warning"
                }
            }
            else {
                Write-Log "Python: $line" -Level "Debug"
            }
        }

        # Update session stats
        if ($summary) {
            $script:SessionStats.TotalCost += $summary.total_cost
            if (-not $DryRun) {
                $script:SessionStats.AIRenamed += $summary.successful
            }
        }

        # Update file states
        foreach ($result in $results) {
            if ($result.status -eq "renamed") {
                Update-FileState -FilePath $result.file_path -Status "AI_Renamed" -Properties @{ 
                    NewName = $result.new_name
                    Analysis = $result.analysis
                }
            }
            elseif ($result.status -eq "skip") {
                Update-FileState -FilePath $result.file_path -Status "SkippedRename"
            }
            elseif ($result.status -eq "error") {
                $script:SessionStats.Errors++
            }
        }

        return @{
            Results = $results
            Summary = $summary
        }
    }
    catch {
        Write-Log "AI renaming failed: $($_.Exception.Message)" -Level "Error"
        throw
    }
}
#endregion

#region Main Processing Logic
function Start-MainProcessing {
    Write-Log "=== PDF Processing Engine Started ===" -Level "Info" -Color "Cyan"
    Write-Log "Target folder: $TargetFolder" -Level "Info"
    Write-Log "Batch size: $BatchSize" -Level "Info"
    Write-Log "Skip dry run: $SkipDryRun" -Level "Info"
    Write-Log "Auto confirm: $AutoConfirm" -Level "Info"

    # Validate target folder
    if (-not (Test-Path $TargetFolder)) {
        throw "Target folder does not exist: $TargetFolder"
    }

    # Load processing state
    Load-ProcessingState

    # Get API key
    $apiKeyToUse = Get-APIKey
    if (-not $apiKeyToUse) {
        throw "No API key found. Set GEMINI_API_KEY environment variable, create .env file, or pass via -APIKey parameter"
    }

    # Find PDF files
    Write-Log "Scanning for PDF files..." -Level "Info"
    $pdfFiles = Get-ChildItem -Path $TargetFolder -Filter "*.pdf" -Recurse | Select-Object -ExpandProperty FullName
    
    if ($pdfFiles.Count -eq 0) {
        Write-Log "No PDF files found in target folder" -Level "Warning"
        return
    }

    Write-Log "Found $($pdfFiles.Count) PDF files" -Level "Info" -Color "Green"

    # Analyze files
    $analysis = Analyze-PDFFiles -FilePaths $pdfFiles

    # Step 1: OCR Processing
    if ($analysis.NeedsOCR.Count -gt 0 -or $analysis.Unknown.Count -gt 0) {
        $ocrFiles = $analysis.NeedsOCR + $analysis.Unknown
        
        if (Get-UserConfirmation -Message "Process $($ocrFiles.Count) files with OCR?" -AutoConfirm:$AutoConfirm) {
            Write-Log "Step 1: Starting OCR processing..." -Level "Info" -Color "Yellow"
            $ocrResults = Invoke-OCRProcessing -FilePaths $ocrFiles -BatchSize $BatchSize
            Write-Log "OCR processing completed" -Level "Info" -Color "Green"
        }
        else {
            Write-Log "OCR processing skipped by user" -Level "Info"
        }
    }
    else {
        Write-Log "No files need OCR processing" -Level "Info" -Color "Green"
    }

    # Step 2: AI Renaming
    $filesToRename = $analysis.NeedsRename + $analysis.Unknown
    
    if ($filesToRename.Count -eq 0) {
        Write-Log "No files need renaming - all files already have specific names!" -Level "Info" -Color "Green"
        Write-Log "Found $($analysis.Complete.Count) files already properly named" -Level "Info" -Color "Green"
        return
    }

    if ($SkipDryRun) {
        # Skip dry run - go straight to renaming
        Write-Log "Skipping dry run - proceeding directly to AI renaming..." -Level "Info"
        if (Get-UserConfirmation -Message "Proceed with renaming $($filesToRename.Count) files? (NO DRY RUN)" -AutoConfirm:$AutoConfirm) {
            Write-Log "Step 2: Executing AI renaming directly..." -Level "Info" -Color "Yellow"
            $renameResults = Invoke-AIRenaming -FilePaths $filesToRename -APIKey $apiKeyToUse -DryRun $false
            
            $successCount = $renameResults.Summary.successful
            $errorCount = $renameResults.Summary.errors
            
            if ($successCount -eq 0 -and $errorCount -eq 0) {
                Write-Log "AI renaming completed. No files needed renaming (already have specific names)" -Level "Info"
            }
            else {
                Write-Log "AI renaming completed. Successfully renamed: $successCount files, Errors: $errorCount files" -Level "Info"
            }
        }
    }
    else {
        # Traditional flow with dry run first
        Write-Log "Step 2a: Running AI analysis (dry run)..." -Level "Info" -Color "Yellow"
        $dryRunResults = Invoke-AIRenaming -FilePaths $filesToRename -APIKey $apiKeyToUse -DryRun $true
        
        $readyToRename = $dryRunResults.Summary.successful
        Write-Log "AI analysis (dry run) completed. Analyzed: $($dryRunResults.Results.Count) files ($readyToRename ready to rename)" -Level "Info"
        
        if ($readyToRename -gt 0) {
            if (Get-UserConfirmation -Message "Proceed with renaming $readyToRename files?" -AutoConfirm:$AutoConfirm) {
                Write-Log "Step 2b: Executing AI renaming..." -Level "Info" -Color "Yellow"
                $renameResults = Invoke-AIRenaming -FilePaths $filesToRename -APIKey $apiKeyToUse -DryRun $false
                
                $successCount = $renameResults.Summary.successful
                $errorCount = $renameResults.Summary.errors
                
                Write-Log "AI renaming completed. Successfully renamed: $successCount files, Errors: $errorCount files" -Level "Info"
            }
            else {
                Write-Log "AI renaming cancelled by user" -Level "Info"
            }
        }
        else {
            Write-Log "No files ready for renaming after analysis" -Level "Info"
        }
    }

    # Final statistics
    Show-SessionSummary
}

function Show-SessionSummary {
    $endTime = Get-Date
    $duration = $endTime - $script:SessionStats.StartTime
    
    Write-Log "=== Session Summary ===" -Level "Info" -Color "Cyan"
    Write-Log "Duration: $($duration.ToString('hh\:mm\:ss'))" -Level "Info"
    Write-Log "Total files: $($script:SessionStats.TotalFiles)" -Level "Info"
    Write-Log "OCR processed: $($script:SessionStats.OCRProcessed)" -Level "Info"
    Write-Log "AI renamed: $($script:SessionStats.AIRenamed)" -Level "Info"
    Write-Log "Errors: $($script:SessionStats.Errors)" -Level "Info"
    Write-Log "Total cost: $($script:SessionStats.TotalCost.ToString('F4'))" -Level "Info"
    Write-Log "Log file: $script:LogFile" -Level "Info"
    Write-Log "========================" -Level "Info" -Color "Cyan"
}
#endregion

# Main execution
try {
    Start-MainProcessing
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)" -Level "Error"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level "Error"
    exit 1
}