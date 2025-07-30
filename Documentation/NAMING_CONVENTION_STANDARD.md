# PDF-OCR-Automation Naming Convention Standard

## ISO 8601 Compliant File Naming Convention

This document defines the standardized file naming convention used by the PDF-OCR-Automation system, following ISO 8601 and industry best practices.

## Standard Format

All files are renamed following this exact pattern:
```
YYYYMMDD_DocType_Entity_Identifier_v01.pdf
```

## Components

### 1. Date Prefix (MANDATORY)
- **Format**: `YYYYMMDD` (ISO 8601)
- **Example**: `20240722`
- **Rules**:
  - Always start filename with date
  - Use document date if found in content
  - Use today's date if no date found
  - No hyphens or separators in date

### 2. Document Type Code (MANDATORY)
- **Format**: 3-letter uppercase code
- **Common Types**:
  - `INV` = Invoice
  - `CTR` = Contract
  - `RPT` = Report
  - `LTR` = Letter
  - `POL` = Policy
  - `AGR` = Agreement
  - `MEM` = Memo
  - `MIN` = Minutes
  - `PRO` = Proposal
  - `REQ` = Request/Requisition
  - `CRT` = Certificate
  - `LGL` = Legal Document
  - `FIN` = Financial Document
  - `MED` = Medical Record
  - `GOV` = Government Form
  - `DOC` = Generic Document (fallback)

### 3. Entity (MANDATORY)
- **Format**: TitleCase, no spaces
- **Max Length**: 15 characters
- **Examples**:
  - `AcmeCorp`
  - `SmithJohn`
  - `RoganEstate`
  - `TestCompanyLLC`

### 4. Identifier (OPTIONAL)
- **Format**: Alphanumeric, no spaces
- **Max Length**: 10 characters
- **Examples**:
  - `2024001` (invoice number)
  - `24PR371` (case ID)
  - `Q4Results` (report identifier)
  - `SALE2024` (project code)

### 5. Version (MANDATORY)
- **Format**: `v##` (always 2 digits)
- **Examples**: `v01`, `v02`, `v10`
- **Rules**:
  - Start with `v01`
  - Increment for revisions
  - Always pad single digits with zero

## Technical Rules

1. **Separators**: Use ONLY underscores (`_`)
2. **Length**: Maximum 60 characters total
3. **Characters**: Only alphanumeric and underscore
4. **Case**: 
   - Uppercase for type codes
   - TitleCase for entities
   - Numbers padded with zeros

## Examples

### Legal Documents
```
20241119_LGL_RoganEstate_24PR371_v01.pdf
20240422_LGL_SmithVJones_CIV2024_v01.pdf
```

### Financial Documents
```
20240720_INV_TestCompanyLLC_2024001_v01.pdf
20240331_RPT_Finance_Q1Summary_v01.pdf
```

### Business Documents
```
20240115_CTR_AcmeCorp_SALE2024_v01.pdf
20240722_RPT_SysPerf_PerfQtr_v01.pdf
```

### Government Documents
```
20240415_GOV_IRS_1040_v01.pdf
20240201_GOV_StateDept_Passport_v01.pdf
```

## Benefits

1. **Chronological Sorting**: Files automatically sort by date
2. **Quick Identification**: Document type immediately visible
3. **Search Friendly**: Easy to find by entity or identifier
4. **Version Control**: Clear revision tracking
5. **ISO Compliant**: Follows international standards
6. **System Agnostic**: Works across all operating systems

## Implementation

The system uses Google Gemini 2.5 Flash AI to:
1. Extract text from PDFs (with OCR if needed)
2. Identify document type, date, and key entities
3. Generate standardized filename
4. Rename file following this convention

## Fallback Naming

If AI analysis fails, the system uses:
```
YYYYMMDD_DOC_Unknown_v01.pdf
```
Where YYYYMMDD is today's date.