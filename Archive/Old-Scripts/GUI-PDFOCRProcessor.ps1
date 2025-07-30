# GUI Wrapper for PDF OCR Processor
# Provides a user-friendly interface for non-technical users

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PDF OCR Automation Suite"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Create a nice gradient background
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Universal PDF OCR Processor"
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(560, 30)
$titleLabel.TextAlign = "MiddleCenter"
$titleLabel.ForeColor = [System.Drawing.Color]::DarkBlue
$form.Controls.Add($titleLabel)

# Subtitle
$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "Process and rename PDFs with intelligent OCR"
$subtitleLabel.Font = New-Object System.Drawing.Font("Arial", 10)
$subtitleLabel.Location = New-Object System.Drawing.Point(20, 50)
$subtitleLabel.Size = New-Object System.Drawing.Size(560, 20)
$subtitleLabel.TextAlign = "MiddleCenter"
$subtitleLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($subtitleLabel)

# Folder Selection Group
$folderGroup = New-Object System.Windows.Forms.GroupBox
$folderGroup.Text = "Select Folder"
$folderGroup.Location = New-Object System.Drawing.Point(20, 90)
$folderGroup.Size = New-Object System.Drawing.Size(560, 60)
$form.Controls.Add($folderGroup)

$folderTextBox = New-Object System.Windows.Forms.TextBox
$folderTextBox.Location = New-Object System.Drawing.Point(10, 25)
$folderTextBox.Size = New-Object System.Drawing.Size(440, 20)
$folderTextBox.Text = ".\Documents"
$folderGroup.Controls.Add($folderTextBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Location = New-Object System.Drawing.Point(460, 23)
$browseButton.Size = New-Object System.Drawing.Size(90, 25)
$browseButton.Text = "Browse..."
$browseButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select folder containing PDF files"
    $folderBrowser.ShowNewFolderButton = $true
    
    if ($folderBrowser.ShowDialog() -eq "OK") {
        $folderTextBox.Text = $folderBrowser.SelectedPath
    }
})
$folderGroup.Controls.Add($browseButton)

# Options Group
$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Text = "Processing Options"
$optionsGroup.Location = New-Object System.Drawing.Point(20, 160)
$optionsGroup.Size = New-Object System.Drawing.Size(560, 120)
$form.Controls.Add($optionsGroup)

# Document Type
$docTypeLabel = New-Object System.Windows.Forms.Label
$docTypeLabel.Text = "Document Type:"
$docTypeLabel.Location = New-Object System.Drawing.Point(10, 25)
$docTypeLabel.Size = New-Object System.Drawing.Size(100, 20)
$optionsGroup.Controls.Add($docTypeLabel)

$docTypeCombo = New-Object System.Windows.Forms.ComboBox
$docTypeCombo.Location = New-Object System.Drawing.Point(120, 22)
$docTypeCombo.Size = New-Object System.Drawing.Size(150, 20)
$docTypeCombo.DropDownStyle = "DropDownList"
$docTypeCombo.Items.AddRange(@("Auto-Detect", "Business", "Invoice", "Legal", "Technical", "General"))
$docTypeCombo.SelectedIndex = 0
$optionsGroup.Controls.Add($docTypeCombo)

# OCR Language
$langLabel = New-Object System.Windows.Forms.Label
$langLabel.Text = "OCR Language:"
$langLabel.Location = New-Object System.Drawing.Point(290, 25)
$langLabel.Size = New-Object System.Drawing.Size(100, 20)
$optionsGroup.Controls.Add($langLabel)

$langCombo = New-Object System.Windows.Forms.ComboBox
$langCombo.Location = New-Object System.Drawing.Point(400, 22)
$langCombo.Size = New-Object System.Drawing.Size(150, 20)
$langCombo.DropDownStyle = "DropDownList"
$langCombo.Items.AddRange(@("English", "Spanish", "French", "German", "Italian", "Portuguese", "Multi-language"))
$langCombo.SelectedIndex = 0
$optionsGroup.Controls.Add($langCombo)

# Preview Mode Checkbox
$previewCheckbox = New-Object System.Windows.Forms.CheckBox
$previewCheckbox.Text = "Preview Mode (don't make changes)"
$previewCheckbox.Location = New-Object System.Drawing.Point(10, 55)
$previewCheckbox.Size = New-Object System.Drawing.Size(250, 20)
$previewCheckbox.Checked = $true
$optionsGroup.Controls.Add($previewCheckbox)

# Detailed Output Checkbox
$detailedCheckbox = New-Object System.Windows.Forms.CheckBox
$detailedCheckbox.Text = "Show detailed output"
$detailedCheckbox.Location = New-Object System.Drawing.Point(10, 85)
$detailedCheckbox.Size = New-Object System.Drawing.Size(250, 20)
$optionsGroup.Controls.Add($detailedCheckbox)

# Progress Group
$progressGroup = New-Object System.Windows.Forms.GroupBox
$progressGroup.Text = "Progress"
$progressGroup.Location = New-Object System.Drawing.Point(20, 290)
$progressGroup.Size = New-Object System.Drawing.Size(560, 80)
$form.Controls.Add($progressGroup)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 25)
$progressBar.Size = New-Object System.Drawing.Size(540, 20)
$progressBar.Style = "Continuous"
$progressGroup.Controls.Add($progressBar)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready to process PDFs"
$statusLabel.Location = New-Object System.Drawing.Point(10, 50)
$statusLabel.Size = New-Object System.Drawing.Size(540, 20)
$statusLabel.TextAlign = "MiddleCenter"
$progressGroup.Controls.Add($statusLabel)

# Buttons
$processButton = New-Object System.Windows.Forms.Button
$processButton.Location = New-Object System.Drawing.Point(150, 390)
$processButton.Size = New-Object System.Drawing.Size(120, 35)
$processButton.Text = "Process PDFs"
$processButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$processButton.BackColor = [System.Drawing.Color]::LightGreen
$processButton.Add_Click({
    # Disable controls during processing
    $processButton.Enabled = $false
    $browseButton.Enabled = $false
    $cancelButton.Text = "Cancel"
    
    # Map GUI selections to script parameters
    $docTypeMap = @{
        "Auto-Detect" = "auto"
        "Business" = "business"
        "Invoice" = "invoice"
        "Legal" = "legal"
        "Technical" = "technical"
        "General" = "general"
    }
    
    $langMap = @{
        "English" = "eng"
        "Spanish" = "spa"
        "French" = "fra"
        "German" = "deu"
        "Italian" = "ita"
        "Portuguese" = "por"
        "Multi-language" = "multi"
    }
    
    $targetFolder = $folderTextBox.Text
    $documentType = $docTypeMap[$docTypeCombo.SelectedItem]
    $ocrLanguage = $langMap[$langCombo.SelectedItem]
    $whatIf = $previewCheckbox.Checked
    $detailed = $detailedCheckbox.Checked
    
    # Update status
    $statusLabel.Text = "Starting PDF processing..."
    $progressBar.Value = 0
    
    # Build command
    $scriptPath = Join-Path $PSScriptRoot "Universal-PDF-OCR-Processor.ps1"
    $arguments = @(
        "-TargetFolder", "`"$targetFolder`"",
        "-DocumentType", $documentType,
        "-OCRLanguage", $ocrLanguage
    )
    
    if ($whatIf) { $arguments += "-WhatIf" }
    if ($detailed) { $arguments += "-DetailedOutput" }
    
    # Create a new PowerShell process to run the script
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "powershell.exe"
    $processInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $arguments"
    $processInfo.UseShellExecute = $false
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    
    # Start async processing
    $statusLabel.Text = "Processing PDFs... Check PowerShell window for details"
    
    # For now, just launch in a new window for visibility
    Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`"", $arguments
    
    # Simulate completion
    Start-Sleep -Seconds 2
    
    # Re-enable controls
    $processButton.Enabled = $true
    $browseButton.Enabled = $true
    $cancelButton.Text = "Close"
    $statusLabel.Text = "Processing launched in new window"
    $progressBar.Value = 100
})
$form.Controls.Add($processButton)

$helpButton = New-Object System.Windows.Forms.Button
$helpButton.Location = New-Object System.Drawing.Point(280, 390)
$helpButton.Size = New-Object System.Drawing.Size(80, 35)
$helpButton.Text = "Help"
$helpButton.Add_Click({
    $helpText = @"
PDF OCR Automation Suite - Help

1. SELECT FOLDER: Choose the folder containing your PDF files
2. DOCUMENT TYPE: Select the type of documents or use Auto-Detect
3. OCR LANGUAGE: Choose the language for text recognition
4. PREVIEW MODE: Keep checked to see what would happen without making changes
5. Click PROCESS PDFS to start

Requirements:
- Adobe Acrobat Pro must be installed
- PowerShell 5.1 or higher

For detailed help, see README.md in the installation folder.
"@
    [System.Windows.Forms.MessageBox]::Show($helpText, "Help", "OK", "Information")
})
$form.Controls.Add($helpButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(370, 390)
$cancelButton.Size = New-Object System.Drawing.Size(80, 35)
$cancelButton.Text = "Close"
$cancelButton.Add_Click({ $form.Close() })
$form.Controls.Add($cancelButton)

# Add icon if available
try {
    $iconPath = Join-Path $PSScriptRoot "icon.ico"
    if (Test-Path $iconPath) {
        $form.Icon = New-Object System.Drawing.Icon($iconPath)
    }
} catch {}

# Show Adobe status in footer
$footerLabel = New-Object System.Windows.Forms.Label
$footerLabel.Location = New-Object System.Drawing.Point(20, 440)
$footerLabel.Size = New-Object System.Drawing.Size(560, 20)
$footerLabel.TextAlign = "MiddleCenter"
$footerLabel.ForeColor = [System.Drawing.Color]::DimGray
$footerLabel.Font = New-Object System.Drawing.Font("Arial", 8)

# Check Adobe status
$adobeStatus = if (Get-Command acrobat.exe -ErrorAction SilentlyContinue) {
    "✓ Adobe Acrobat Pro detected"
} else {
    "⚠ Adobe Acrobat Pro not found - OCR will not work"
}
$footerLabel.Text = $adobeStatus
$form.Controls.Add($footerLabel)

# Show the form
[void]$form.ShowDialog()