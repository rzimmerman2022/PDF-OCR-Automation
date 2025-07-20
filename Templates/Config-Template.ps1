# Configuration file for PDF OCR Automation
# Modify these settings for your specific needs

# Document Types and Patterns
$DocumentTypes = @{
    "Medical" = @{
        FolderPattern = "02_LabResults"
        FilePattern = "*_LabResults_TestDetails_*.pdf"
        ContentPatterns = @(
            @{ Pattern = '(?i)(CBC|Complete Blood Count)'; Name = "CBC-Complete-Blood-Count" }
            @{ Pattern = '(?i)(Lipid Panel|Cholesterol)'; Name = "Lipid-Panel-Cholesterol" }
            @{ Pattern = '(?i)(HbA1c|Hemoglobin A1c)'; Name = "HbA1c-Diabetes-Monitoring" }
        )
        NamingFormat = "{Date}_LabResults_{Content}.pdf"
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
