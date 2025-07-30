# Create test content files that can be converted to PDFs
# These HTML files can be printed to PDF using any browser

Write-Host "Creating test content files..." -ForegroundColor Cyan

# Test 1: Invoice HTML
$invoiceHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Invoice #2024-001</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .total { font-weight: bold; }
    </style>
</head>
<body>
    <h1>INVOICE #2024-001</h1>
    <p>Date: $(Get-Date -Format 'MMMM dd, yyyy')</p>
    <p>Customer: Test Company LLC<br>
    Address: 123 Main Street, Anytown, ST 12345</p>
    
    <table>
        <tr>
            <th>Item</th>
            <th>Quantity</th>
            <th>Price</th>
            <th>Total</th>
        </tr>
        <tr>
            <td>Widget A</td>
            <td>10</td>
            <td>$25.00</td>
            <td>$250.00</td>
        </tr>
        <tr>
            <td>Service B</td>
            <td>5</td>
            <td>$100.00</td>
            <td>$500.00</td>
        </tr>
        <tr class="total">
            <td colspan="3">TOTAL</td>
            <td>$750.00</td>
        </tr>
    </table>
</body>
</html>
"@
$invoiceHTML | Out-File "Test-PDFs\Test-Invoice.html" -Encoding UTF8
Write-Host "  Created: Test-Invoice.html" -ForegroundColor Green

# Test 2: Technical Report HTML
$reportHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Technical Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
        h1 { color: #2c3e50; }
        h2 { color: #34495e; }
        ul { margin-left: 20px; }
        .metric { margin: 10px 0; }
    </style>
</head>
<body>
    <h1>Technical Analysis Report</h1>
    <h2>System Performance Metrics</h2>
    
    <h3>Executive Summary:</h3>
    <p>This report analyzes system performance over the past quarter. Key findings include improved response times and reduced error rates.</p>
    
    <h3>Performance Metrics:</h3>
    <ul>
        <li class="metric">Average Response Time: <strong>125ms</strong></li>
        <li class="metric">Error Rate: <strong>0.02%</strong></li>
        <li class="metric">Uptime: <strong>99.98%</strong></li>
        <li class="metric">Throughput: <strong>10,000 requests/second</strong></li>
    </ul>
    
    <h3>Recommendations:</h3>
    <p>Continue monitoring system performance and implement automated scaling based on load patterns.</p>
</body>
</html>
"@
$reportHTML | Out-File "Test-PDFs\Test-TechnicalReport.html" -Encoding UTF8
Write-Host "  Created: Test-TechnicalReport.html" -ForegroundColor Green

# Test 3: Legal Document HTML
$legalHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Confidentiality Agreement</title>
    <style>
        body { font-family: 'Times New Roman', serif; margin: 50px; line-height: 1.8; }
        h1 { text-align: center; font-size: 18px; margin-bottom: 30px; }
        h2 { font-size: 14px; margin-top: 20px; }
        p { text-align: justify; }
        .section { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>CONFIDENTIALITY AGREEMENT</h1>
    
    <p>This Agreement is entered into as of $(Get-Date -Format 'MMMM dd, yyyy') between Party A and Party B.</p>
    
    <div class="section">
        <h2>1. CONFIDENTIAL INFORMATION</h2>
        <p>The parties acknowledge that they may disclose certain confidential and proprietary information to each other in connection with their business relationship.</p>
    </div>
    
    <div class="section">
        <h2>2. OBLIGATIONS</h2>
        <p>Each party agrees to maintain the confidentiality of all information received from the other party and to use such information solely for the purposes set forth in this Agreement.</p>
    </div>
    
    <div class="section">
        <h2>3. TERM</h2>
        <p>This Agreement shall remain in effect for a period of five (5) years from the date first written above.</p>
    </div>
</body>
</html>
"@
$legalHTML | Out-File "Test-PDFs\Test-LegalDocument.html" -Encoding UTF8
Write-Host "  Created: Test-LegalDocument.html" -ForegroundColor Green

# Test 4: Simple text files for scanned document simulation
@"
SCANNED DOCUMENT EXAMPLE
=======================

This text represents a scanned document.
It may have some OCR challenges:

1) Numbers: 1234567890
2) Special chars: @#$%^&*()
3) Mixed case: aBcDeFgHiJkLmNoP
4) Dates: 01/15/2024, 2024-01-15
5) Currency: $1,234.56

Common OCR errors to test:
- l vs 1 (lowercase L vs one)
- 0 vs O (zero vs letter O)
- rn vs m
"@ | Out-File "Test-PDFs\Test-ScannedDoc.txt" -Encoding UTF8
Write-Host "  Created: Test-ScannedDoc.txt" -ForegroundColor Green

Write-Host "`nTest content files created!" -ForegroundColor Green
Write-Host "To convert to PDF:" -ForegroundColor Yellow
Write-Host "1. Open HTML files in a browser" -ForegroundColor Yellow
Write-Host "2. Print to PDF (Ctrl+P, select 'Save as PDF')" -ForegroundColor Yellow
Write-Host "3. Or use the provided text files with any PDF creator" -ForegroundColor Yellow