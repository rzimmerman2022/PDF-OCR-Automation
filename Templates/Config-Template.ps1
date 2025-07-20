# Configuration file for PDF OCR Automation
# Modify these settings for your specific needs

# Document Types and Patterns
$DocumentTypes = @{
    "Business" = @{
        FolderPattern = "Reports"
        FilePattern = "*.pdf"
        ContentPatterns = @(
            @{ Pattern = '(?i)(Annual Report|Quarterly Report)'; Name = "Business-Report" }
            @{ Pattern = '(?i)(Meeting Minutes|Board Minutes)'; Name = "Meeting-Minutes" }
            @{ Pattern = '(?i)(Business Plan|Strategic Plan)'; Name = "Business-Plan" }
        )
        NamingFormat = "{Date}_Business_{Content}.pdf"
    }
    
    "Technical" = @{
        FolderPattern = "Technical"
        FilePattern = "*.pdf"
        ContentPatterns = @(
            @{ Pattern = '(?i)(User Manual|Installation Guide)'; Name = "User-Manual" }
            @{ Pattern = '(?i)(Technical Specification|Design Spec)'; Name = "Technical-Specification" }
            @{ Pattern = '(?i)(API Documentation|Developer Guide)'; Name = "API-Documentation" }
        )
        NamingFormat = "{Date}_Technical_{Content}.pdf"
    }
    
    "Invoice" = @{
        FolderPattern = "Invoices"
        FilePattern = "*.pdf"
        ContentPatterns = @(
            @{ Pattern = '(?i)(Invoice|Bill)'; Name = "Invoice" }
            @{ Pattern = '(?i)(Purchase Order|PO)'; Name = "PurchaseOrder" }
        )
        NamingFormat = "{Date}_Invoice_{Vendor}_{Number}.pdf"
    }
    
    "Legal" = @{
        FolderPattern = "Legal"
        FilePattern = "*.pdf"
        ContentPatterns = @(
            @{ Pattern = '(?i)(Contract|Agreement)'; Name = "Contract" }
            @{ Pattern = '(?i)(Motion|Brief)'; Name = "Legal-Motion" }
            @{ Pattern = '(?i)(Settlement)'; Name = "Settlement" }
        )
        NamingFormat = "{Date}_Legal_{Content}_{CaseNumber}.pdf"
    }
}

# Date Patterns (Universal)
$DatePatterns = @(
    '(\d{4}-\d{2}-\d{2})'                        # YYYY-MM-DD
    '(\d{1,2}/\d{1,2}/\d{4})'                    # M/D/YYYY or MM/DD/YYYY
    '(\d{1,2}-\d{1,2}-\d{4})'                    # M-D-YYYY or MM-DD-YYYY
    '([A-Za-z]+ \d{1,2}, \d{4})'                 # Month DD, YYYY
    '(\d{1,2} [A-Za-z]+ \d{4})'                  # DD Month YYYY
    'Date.*?(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'    # "Date: MM/DD/YYYY" variations
)

# OCR Settings
$OCRSettings = @{
    MaxRetries = 2
    TimeoutSeconds = 30
    QualityLevel = "High"
    BackgroundProcessing = $false
}

# Export this configuration
Export-ModuleMember -Variable DocumentTypes, DatePatterns, OCRSettings
