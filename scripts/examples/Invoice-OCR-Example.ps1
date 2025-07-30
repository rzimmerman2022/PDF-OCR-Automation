# Invoice OCR Processor Example
# Extracts invoice numbers, dates, vendors, and amounts

param([switch]$WhatIf)

# Content patterns for invoices
$invoicePatterns = @(
    @{ Pattern = '(?i)(Invoice\s*#?\s*:?\s*)([A-Z0-9\-]+)'; Name = "Invoice"; Field = "Number" }
    @{ Pattern = '(?i)(Bill\s*#?\s*:?\s*)([A-Z0-9\-]+)'; Name = "Bill"; Field = "Number" }
    @{ Pattern = '(?i)(Purchase\s*Order\s*#?\s*:?\s*)([A-Z0-9\-]+)'; Name = "PO"; Field = "Number" }
)

$vendorPatterns = @(
    @{ Pattern = '(?i)(From|Vendor|Company):\s*(.+?)(?:\n|$)'; Field = "Vendor" }
    @{ Pattern = '(?i)(Bill\s*From):\s*(.+?)(?:\n|$)'; Field = "Vendor" }
)

$amountPatterns = @(
    @{ Pattern = '(?i)(Total|Amount\s*Due|Balance):\s*\$?([\d,]+\.?\d*)'; Field = "Amount" }
    @{ Pattern = '\$\s*([\d,]+\.\d{2})\s*(?:Total|Due|Balance)'; Field = "Amount" }
)

# Date patterns (universal)
$datePatterns = @(
    '(\d{4}-\d{2}-\d{2})'
    '(\d{1,2}/\d{1,2}/\d{4})'
    '([A-Za-z]+ \d{1,2}, \d{4})'
)

Write-Host "Invoice OCR Processor Template" -ForegroundColor Cyan
Write-Host "This is a template - implement full OCR logic from main script" -ForegroundColor Yellow

# Example naming convention for invoices:
# Format: YYYY-MM-DD_Invoice_VendorName_InvoiceNumber.pdf
# Example: 2025-07-19_Invoice_AcmeCorp_INV-12345.pdf

Write-Host "`nExample output naming:"
Write-Host "  Original: invoice_scan_001.pdf"
Write-Host "  New:      2025-07-19_Invoice_AcmeCorp_INV-12345.pdf"
