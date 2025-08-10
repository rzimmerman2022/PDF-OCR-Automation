# Troubleshooting Guide - PDF OCR Automation Suite

**Last Updated:** 2025-08-10  
**Version:** 2.0.0  
**Description:** Common issues and solutions for PDF OCR automation

This guide covers common issues and their solutions when using the Universal PDF OCR Processor.

## Table of Contents
- [Adobe Acrobat Issues](#adobe-acrobat-issues)
- [OCR Processing Problems](#ocr-processing-problems)
- [File Access & Permissions](#file-access--permissions)
- [Performance Issues](#performance-issues)
- [Script Errors](#script-errors)
- [Network & Path Issues](#network--path-issues)

---

## Adobe Acrobat Issues

### Issue: "Adobe Acrobat executable not found"

**Symptoms:**
- Warning message when running Setup.ps1
- OCR functionality not available

**Solutions:**

1. **Verify Adobe Acrobat Pro Installation:**
   ```powershell
   # Check if Adobe is installed
   Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
   Where-Object {$_.DisplayName -like "*Adobe Acrobat*"} | 
   Select-Object DisplayName, InstallLocation
   ```

2. **Add Adobe to PATH:**
   ```powershell
   # Run the helper script
   .\Add-AdobeToPath.ps1
   
   # Or manually add to system PATH
   [Environment]::SetEnvironmentVariable("PATH", 
     "$env:PATH;C:\Program Files\Adobe\Acrobat DC\Acrobat", 
     [EnvironmentVariableTarget]::Machine)
   ```

3. **Verify PATH Configuration:**
   ```powershell
   # Check if acrobat.exe is accessible
   Get-Command acrobat.exe -ErrorAction SilentlyContinue
   
   # List all PATH entries
   $env:PATH -split ';' | Where-Object {$_ -like "*Adobe*"}
   ```

### Issue: "Failed to create Adobe Acrobat application object"

**Symptoms:**
- Error when attempting OCR
- COM object creation fails

**Solutions:**

1. **Run as Administrator:**
   ```powershell
   # Launch elevated PowerShell
   Start-Process powershell -Verb RunAs
   ```

2. **Re-register Adobe COM Components:**
   ```powershell
   # Navigate to Adobe installation
   cd "C:\Program Files\Adobe\Acrobat DC\Acrobat"
   
   # Re-register COM components
   .\acrobat.exe /regserver
   ```

3. **Check Adobe License:**
   - Ensure Adobe Acrobat Pro is properly licensed
   - Sign in to Adobe Creative Cloud if required
   - Verify subscription is active

---

## OCR Processing Problems

### Issue: OCR fails on certain PDFs

**Symptoms:**
- Some PDFs process successfully, others fail
- Error messages about OCR recognition

**Solutions:**

1. **Check PDF Properties:**
   ```powershell
   # Use this function to check if PDF is already searchable
   function Test-PDFSearchable {
       param([string]$Path)
       $content = Get-Content $Path -Raw -Encoding Byte
       $text = [System.Text.Encoding]::ASCII.GetString($content)
       return $text -match "/Type\s*/Page" -and $text -match "TJ|Tj"
   }
   
   Test-PDFSearchable ".\Documents\test.pdf"
   ```

2. **Process in 32-bit PowerShell:**
   ```powershell
   # For 64-bit systems, use 32-bit PowerShell
   C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe
   .\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Documents"
   ```

3. **Repair Corrupted PDFs:**
   ```powershell
   # Create a repair script
   $acrobat = New-Object -ComObject AcroExch.App
   $avDoc = New-Object -ComObject AcroExch.AVDoc
   $avDoc.Open("path\to\corrupted.pdf", "")
   $pdDoc = $avDoc.GetPDDoc()
   $pdDoc.Save(1, "path\to\repaired.pdf")
   $avDoc.Close($true)
   $acrobat.Exit()
   ```

### Issue: Poor OCR quality

**Symptoms:**
- Text recognition has many errors
- Special characters not recognized

**Solutions:**

1. **Improve PDF Quality:**
   - Scan at 300 DPI minimum
   - Use black & white for text documents
   - Ensure good contrast

2. **Configure OCR Settings:**
   ```powershell
   # Add to script for better OCR
   $jsObject = $pdDoc.GetJSObject()
   $jsObject.OCR($null, "eng", $true, 300)  # Language, searchable, DPI
   ```

---

## File Access & Permissions

### Issue: "Access to the path is denied"

**Symptoms:**
- Cannot rename files
- Cannot write to folders

**Solutions:**

1. **Check File Permissions:**
   ```powershell
   # View current permissions
   Get-Acl ".\Documents\*.pdf" | Format-List
   
   # Take ownership (run as admin)
   $acl = Get-Acl ".\Documents"
   $permission = "Everyone","FullControl","Allow"
   $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
   $acl.SetAccessRule($accessRule)
   Set-Acl ".\Documents" $acl
   ```

2. **Close Open Files:**
   ```powershell
   # Find processes using PDF files
   Get-Process | Where-Object {$_.MainWindowTitle -like "*pdf*"}
   
   # Close Adobe processes
   Get-Process Acrobat* | Stop-Process -Force
   ```

3. **Unlock Files:**
   ```powershell
   # Remove read-only attribute
   Get-ChildItem ".\Documents\*.pdf" | 
   ForEach-Object {$_.IsReadOnly = $false}
   ```

---

## Performance Issues

### Issue: Script runs very slowly

**Symptoms:**
- Processing takes minutes per PDF
- High memory usage

**Solutions:**

1. **Optimize Batch Size:**
   ```powershell
   # Process in smaller batches
   $files = Get-ChildItem ".\Documents\*.pdf"
   $batchSize = 10
   
   for ($i = 0; $i -lt $files.Count; $i += $batchSize) {
       $batch = $files | Select-Object -Skip $i -First $batchSize
       # Process batch
   }
   ```

2. **Monitor Resources:**
   ```powershell
   # Check available memory
   Get-CimInstance Win32_OperatingSystem | 
   Select-Object FreePhysicalMemory, TotalVisibleMemorySize
   
   # Monitor script memory usage
   Get-Process powershell | Select-Object WS, CPU
   ```

3. **Disable Antivirus Scanning:**
   - Temporarily exclude script folder from real-time scanning
   - Add PowerShell to antivirus exceptions

---

## Script Errors

### Issue: "The term 'X' is not recognized"

**Solutions:**

1. **Verify PowerShell Version:**
   ```powershell
   $PSVersionTable.PSVersion
   # Should be 5.1 or higher
   ```

2. **Check Execution Policy:**
   ```powershell
   Get-ExecutionPolicy
   # If restricted, run:
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### Issue: Script syntax errors

**Solutions:**

1. **Validate Script Integrity:**
   ```powershell
   # Check for syntax errors
   $errors = $null
   $null = [System.Management.Automation.PSParser]::Tokenize(
       (Get-Content ".\Universal-PDF-OCR-Processor.ps1" -Raw), 
       [ref]$errors
   )
   $errors | Format-List
   ```

2. **Re-download Scripts:**
   ```powershell
   # If files are corrupted, re-clone repository
   git status
   git checkout -- Universal-PDF-OCR-Processor.ps1
   ```

---

## Network & Path Issues

### Issue: Cannot access network folders

**Symptoms:**
- UNC paths not working
- "Path not found" errors

**Solutions:**

1. **Map Network Drive:**
   ```powershell
   # Map network location to drive letter
   New-PSDrive -Name "Z" -PSProvider FileSystem -Root "\\Server\Share" -Persist
   
   # Use mapped drive
   .\Universal-PDF-OCR-Processor.ps1 -TargetFolder "Z:\PDFs"
   ```

2. **Provide Credentials:**
   ```powershell
   # Access with credentials
   $cred = Get-Credential
   New-PSDrive -Name "Z" -PSProvider FileSystem -Root "\\Server\Share" -Credential $cred
   ```

3. **Test Network Access:**
   ```powershell
   # Verify network path is accessible
   Test-Path "\\Server\Share\PDFs"
   
   # List files to confirm access
   Get-ChildItem "\\Server\Share\PDFs\*.pdf"
   ```

---

## Getting Additional Help

### Enable Detailed Logging

```powershell
# Run with detailed output
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Documents" -DetailedOutput

# Capture all output to file
.\Universal-PDF-OCR-Processor.ps1 -TargetFolder ".\Documents" *> "debug-log.txt"
```

### Diagnostic Information

Create a diagnostic report:

```powershell
@"
DIAGNOSTIC REPORT - $(Get-Date)
=============================
PowerShell Version: $($PSVersionTable.PSVersion)
OS: $([System.Environment]::OSVersion.VersionString)
User: $env:USERNAME
Computer: $env:COMPUTERNAME
Script Path: $(Get-Location)

Adobe Check:
$(Get-Command acrobat.exe -ErrorAction SilentlyContinue | Out-String)

Folder Permissions:
$(Get-Acl "." | Out-String)

Memory Available: $([Math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)) MB
"@ | Out-File "diagnostic-report.txt"
```

### Common Warning Messages

| Warning | Meaning | Action |
|---------|---------|--------|
| "continuing in preview mode" | Adobe not found | Normal for testing |
| "No PDF files found" | Empty folder | Add PDFs to process |
| "WhatIf: Performing operation" | Preview mode | Remove -WhatIf to process |

---

## Best Practices

1. **Always test with -WhatIf first**
2. **Process copies of important documents**
3. **Maintain backups before bulk processing**
4. **Monitor first few files when processing large batches**
5. **Run performance validation for large operations**

For issues not covered here, please:
- Check the README.md for additional information
- Run the diagnostic script above
- Report issues on GitHub with diagnostic output