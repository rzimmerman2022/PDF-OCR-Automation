# Generate Test PDFs for OCR Testing
# This script creates sample PDFs with various content types to test OCR functionality

Write-Host "Generating Test PDFs..." -ForegroundColor Cyan

# Create Word COM object for PDF generation
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    
    # Test PDF 1: Simple Invoice
    Write-Host "Creating Invoice test PDF..." -ForegroundColor Yellow
    $doc1 = $word.Documents.Add()
    $selection = $word.Selection
    
    $selection.Font.Size = 18
    $selection.Font.Bold = $true
    $selection.TypeText("INVOICE #2024-001")
    $selection.TypeParagraph()
    $selection.TypeParagraph()
    
    $selection.Font.Size = 12
    $selection.Font.Bold = $false
    $selection.TypeText("Date: $(Get-Date -Format 'MMMM dd, yyyy')")
    $selection.TypeParagraph()
    $selection.TypeText("Customer: Test Company LLC")
    $selection.TypeParagraph()
    $selection.TypeText("Address: 123 Main Street, Anytown, ST 12345")
    $selection.TypeParagraph()
    $selection.TypeParagraph()
    
    # Add table
    $range = $selection.Range
    $table = $doc1.Tables.Add($range, 4, 4)
    $table.Cell(1,1).Range.Text = "Item"
    $table.Cell(1,2).Range.Text = "Quantity"
    $table.Cell(1,3).Range.Text = "Price"
    $table.Cell(1,4).Range.Text = "Total"
    
    $table.Cell(2,1).Range.Text = "Widget A"
    $table.Cell(2,2).Range.Text = "10"
    $table.Cell(2,3).Range.Text = "$25.00"
    $table.Cell(2,4).Range.Text = "$250.00"
    
    $table.Cell(3,1).Range.Text = "Service B"
    $table.Cell(3,2).Range.Text = "5"
    $table.Cell(3,3).Range.Text = "$100.00"
    $table.Cell(3,4).Range.Text = "$500.00"
    
    $table.Cell(4,1).Range.Text = "TOTAL"
    $table.Cell(4,2).Range.Text = ""
    $table.Cell(4,3).Range.Text = ""
    $table.Cell(4,4).Range.Text = "$750.00"
    
    $table.Borders.Enable = $true
    
    $doc1.SaveAs([System.IO.Path]::GetFullPath("Test-PDFs\Test-Invoice.pdf"), 17)
    $doc1.Close()
    Write-Host "  Created: Test-Invoice.pdf" -ForegroundColor Green
    
    # Test PDF 2: Technical Report
    Write-Host "Creating Technical Report test PDF..." -ForegroundColor Yellow
    $doc2 = $word.Documents.Add()
    $selection = $word.Selection
    
    $selection.Font.Size = 16
    $selection.Font.Bold = $true
    $selection.TypeText("Technical Analysis Report")
    $selection.TypeParagraph()
    
    $selection.Font.Size = 14
    $selection.TypeText("System Performance Metrics")
    $selection.TypeParagraph()
    $selection.TypeParagraph()
    
    $selection.Font.Size = 12
    $selection.Font.Bold = $false
    $selection.TypeText("Executive Summary:")
    $selection.TypeParagraph()
    $selection.TypeText("This report analyzes system performance over the past quarter. Key findings include improved response times and reduced error rates.")
    $selection.TypeParagraph()
    $selection.TypeParagraph()
    
    $selection.TypeText("Performance Metrics:")
    $selection.TypeParagraph()
    $selection.TypeText("- Average Response Time: 125ms")
    $selection.TypeParagraph()
    $selection.TypeText("- Error Rate: 0.02%")
    $selection.TypeParagraph()
    $selection.TypeText("- Uptime: 99.98%")
    $selection.TypeParagraph()
    $selection.TypeText("- Throughput: 10,000 requests/second")
    $selection.TypeParagraph()
    
    $doc2.SaveAs([System.IO.Path]::GetFullPath("Test-PDFs\Test-TechnicalReport.pdf"), 17)
    $doc2.Close()
    Write-Host "  Created: Test-TechnicalReport.pdf" -ForegroundColor Green
    
    # Test PDF 3: Legal Document
    Write-Host "Creating Legal Document test PDF..." -ForegroundColor Yellow
    $doc3 = $word.Documents.Add()
    $selection = $word.Selection
    
    $selection.Font.Size = 14
    $selection.Font.Bold = $true
    $selection.ParagraphFormat.Alignment = 1  # Center
    $selection.TypeText("CONFIDENTIALITY AGREEMENT")
    $selection.TypeParagraph()
    $selection.TypeParagraph()
    
    $selection.ParagraphFormat.Alignment = 0  # Left
    $selection.Font.Size = 12
    $selection.Font.Bold = $false
    $selection.TypeText("This Agreement is entered into as of $(Get-Date -Format 'MMMM dd, yyyy') between Party A and Party B.")
    $selection.TypeParagraph()
    $selection.TypeParagraph()
    
    $selection.Font.Bold = $true
    $selection.TypeText("1. CONFIDENTIAL INFORMATION")
    $selection.TypeParagraph()
    $selection.Font.Bold = $false
    $selection.TypeText("The parties acknowledge that they may disclose certain confidential and proprietary information.")
    $selection.TypeParagraph()
    $selection.TypeParagraph()
    
    $selection.Font.Bold = $true
    $selection.TypeText("2. OBLIGATIONS")
    $selection.TypeParagraph()
    $selection.Font.Bold = $false
    $selection.TypeText("Each party agrees to maintain the confidentiality of all information received.")
    $selection.TypeParagraph()
    
    $doc3.SaveAs([System.IO.Path]::GetFullPath("Test-PDFs\Test-LegalDocument.pdf"), 17)
    $doc3.Close()
    Write-Host "  Created: Test-LegalDocument.pdf" -ForegroundColor Green
    
    # Test PDF 4: Multi-page Manual
    Write-Host "Creating Multi-page Manual test PDF..." -ForegroundColor Yellow
    $doc4 = $word.Documents.Add()
    $selection = $word.Selection
    
    $selection.Font.Size = 20
    $selection.Font.Bold = $true
    $selection.TypeText("User Manual")
    $selection.TypeParagraph()
    $selection.Font.Size = 16
    $selection.TypeText("Product Guide v2.0")
    $selection.TypeParagraph()
    $selection.InsertBreak(7)  # Page break
    
    $selection.Font.Size = 14
    $selection.TypeText("Table of Contents")
    $selection.TypeParagraph()
    $selection.Font.Size = 12
    $selection.Font.Bold = $false
    $selection.TypeText("1. Introduction ................... 3")
    $selection.TypeParagraph()
    $selection.TypeText("2. Getting Started ................ 5")
    $selection.TypeParagraph()
    $selection.TypeText("3. Advanced Features .............. 8")
    $selection.TypeParagraph()
    $selection.InsertBreak(7)
    
    $selection.Font.Size = 14
    $selection.Font.Bold = $true
    $selection.TypeText("1. Introduction")
    $selection.TypeParagraph()
    $selection.Font.Size = 12
    $selection.Font.Bold = $false
    $selection.TypeText("Welcome to our product. This manual will guide you through all features.")
    $selection.TypeParagraph()
    
    $doc4.SaveAs([System.IO.Path]::GetFullPath("Test-PDFs\Test-Manual.pdf"), 17)
    $doc4.Close()
    Write-Host "  Created: Test-Manual.pdf" -ForegroundColor Green
    
    # Clean up
    $word.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    
    Write-Host "`nTest PDFs created successfully!" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to create test PDFs. Ensure Microsoft Word is installed."
    Write-Host "Error: $_" -ForegroundColor Red
    
    # Try alternative method using .NET if Word fails
    Write-Host "`nAttempting alternative method..." -ForegroundColor Yellow
    
    # Create simple text files as placeholders
    @"
INVOICE #2024-001
Date: $(Get-Date -Format 'MMMM dd, yyyy')
Customer: Test Company LLC

Item         Quantity    Price      Total
Widget A     10          $25.00     $250.00
Service B    5           $100.00    $500.00
TOTAL                               $750.00
"@ | Out-File "Test-PDFs\Test-Invoice.txt"
    
    @"
TECHNICAL ANALYSIS REPORT
System Performance Metrics

Executive Summary:
This report analyzes system performance over the past quarter.

Performance Metrics:
- Average Response Time: 125ms
- Error Rate: 0.02%
- Uptime: 99.98%
"@ | Out-File "Test-PDFs\Test-TechnicalReport.txt"
    
    Write-Host "Created text file alternatives. Please convert to PDF manually or use online tools." -ForegroundColor Yellow
}