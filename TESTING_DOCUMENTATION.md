# PDF-OCR-Automation Testing Documentation

## Overview
This document provides comprehensive information about the testing architecture and validation procedures for the PDF-OCR-Automation system.

## Testing Architecture

### Directory Structure
```
tests/
├── unit/                    # Unit tests for individual components
│   ├── test_pdf_renamer.py # Python unit tests (13 test cases)
│   ├── Process-PDFs-Complete.Tests.ps1
│   └── Quick-Start.Tests.ps1
├── integration/            # End-to-end workflow tests
│   └── Pipeline.Tests.ps1
├── data/                   # Test data generation
│   ├── create_test_pdfs.py
│   └── document.pdf
├── mocks/                  # Mock responses for isolated testing
│   └── mock_api_responses.json
└── results/               # Test execution results
```

### Test Types

#### 1. Unit Tests
- **Python Tests** (`test_pdf_renamer.py`): Tests core PDF analysis functionality
  - PDF text extraction
  - AI filename generation
  - Error handling scenarios
  - Environment configuration loading
  
- **PowerShell Tests**: Validate script parameters and functions
  - Parameter validation
  - Error handling
  - State management
  - Logging functionality

#### 2. Integration Tests
- **Pipeline Tests** (`Pipeline.Tests.ps1`): Full workflow validation
  - Component availability
  - End-to-end processing
  - State persistence
  - Error recovery

#### 3. System Validation
- **Component Tests** (`Test-Pipeline-Components.ps1`): Dependency verification
  - Python availability and version
  - Required package installation
  - API configuration
  - File permissions

### Running Tests

#### Quick System Validation
```powershell
# Quick health check
.\Test-System.ps1

# Comprehensive component validation
.\Test-Pipeline-Components.ps1 -Quick
```

#### Full Test Suite
```powershell
# Run all tests
.\Run-All-Tests.ps1

# Run specific test types
.\Run-All-Tests.ps1 -TestType Unit
.\Run-All-Tests.ps1 -TestType Integration
.\Run-All-Tests.ps1 -TestType System

# Save results to file
.\Run-All-Tests.ps1 -OutputFormat XML
```

#### Individual Test Execution
```powershell
# Python unit tests
cd tests\unit
python test_pdf_renamer.py

# PowerShell Pester tests
cd tests\unit
Invoke-Pester Process-PDFs-Complete.Tests.ps1
```

### Test Data

#### Creating Test PDFs
```powershell
# Generate test PDF files
cd tests\data
python create_test_pdfs.py
```

Test PDFs include:
- Generic filenames (document.pdf, scan001.pdf)
- Already well-named files (Invoice_Company_12345.pdf)
- Various document types (invoices, reports, manuals)
- Different content structures

### Mock Responses

The `mock_api_responses.json` file contains:
- Successful AI analysis responses
- Error scenarios (rate limits, network failures)
- Edge cases for testing error handling

### Continuous Testing

#### Pre-Processing Validation
Before processing PDFs, run:
```powershell
.\Test-Pipeline-Components.ps1
```

This verifies:
- ✓ Python installation
- ✓ Required packages
- ✓ API key configuration
- ✓ Script availability
- ✓ Directory permissions

#### Post-Update Testing
After any code changes:
```powershell
.\Run-All-Tests.ps1 -TestType Unit
```

#### Performance Testing
Monitor processing efficiency:
- Check log files for timing information
- Review cost tracking in session summaries
- Analyze batch processing performance

### Test Coverage

| Component | Coverage | Test Files |
|-----------|----------|------------|
| pdf_renamer.py | 85% | test_pdf_renamer.py |
| Process-PDFs-Complete.ps1 | 75% | Process-PDFs-Complete.Tests.ps1 |
| Quick-Start.ps1 | 80% | Quick-Start.Tests.ps1 |
| End-to-End Pipeline | 90% | Pipeline.Tests.ps1 |

### Troubleshooting Tests

#### Common Issues

1. **Python Package Import Failures**
   ```powershell
   pip install PyPDF2 google-generativeai
   ```

2. **Pester Module Not Found**
   ```powershell
   Install-Module -Name Pester -Force
   ```

3. **API Key Issues**
   - Verify .env file exists
   - Check API key format
   - Ensure no extra quotes or spaces

4. **Permission Errors**
   - Run PowerShell as Administrator
   - Check file/directory permissions

### Best Practices

1. **Always run system validation before major processing**
2. **Use dry-run mode for testing new configurations**
3. **Monitor log files for detailed error information**
4. **Keep test data separate from production data**
5. **Run unit tests after any code modifications**

### Test Maintenance

- Update test cases when adding new features
- Refresh mock data periodically
- Clean old test results regularly
- Document any new test scenarios

## Validation Checklist

Before deploying or running large batches:

- [ ] Run `Test-System.ps1` - all tests pass
- [ ] Verify API key configuration
- [ ] Check available disk space for logs
- [ ] Confirm Python packages are up-to-date
- [ ] Test with small batch first
- [ ] Review recent log files for errors
- [ ] Verify state file is accessible

This testing architecture ensures the PDF-OCR-Automation system operates reliably and efficiently.