# Source Code Structure

**Last Updated:** 2025-08-10  
**Version:** 2.0.0  
**Description:** Navigation guide for the PDF-OCR-Automation source code

## Overview

This directory contains the core source code for PDF-OCR-Automation. The code is organized into modular components that work together to provide OCR processing capabilities.

## Directory Structure

```
src/
├── __init__.py                 # Python package initialization
├── README.md                   # This file - source code navigation
├── processors/                 # OCR processing engines
│   ├── OCRmyPDF-Processor.ps1 # PowerShell OCR processor
│   └── ocr_processor.py       # Python OCR processing engine
├── validators/                 # Quality assurance and verification
│   └── verify_ai_readable.py  # PDF text validation utility
├── core/                      # Core functionality (future expansion)
└── utils/                     # Utility functions (future expansion)
```

## Entry Points

### Primary Entry Points

#### 1. Main CLI Utility (Root Level)
**File:** `../ocr_pdfs.py`  
**Purpose:** Main command-line interface for end users  
**Usage:** `python ocr_pdfs.py <folder_path>`  
**Dependencies:** `src.processors.ocr_processor`

```python
# Example usage from root directory
python ocr_pdfs.py "C:\Path\To\PDFs"
```

#### 2. Python OCR Processor 
**File:** `processors/ocr_processor.py`  
**Purpose:** Core OCR processing engine with Adobe-style functionality  
**Usage:** Can be imported or run directly  
**Dependencies:** ocrmypdf, PyPDF2, pathlib

```python
# Import usage
from src.processors.ocr_processor import ocr_pdf_like_adobe, has_text

# Direct usage
python src/processors/ocr_processor.py "input.pdf"
```

#### 3. PowerShell OCR Processor
**File:** `processors/OCRmyPDF-Processor.ps1`  
**Purpose:** Windows PowerShell interface for OCR processing  
**Usage:** PowerShell automation and Windows integration  
**Dependencies:** OCRmyPDF CLI, Tesseract CLI

```powershell
# Example usage
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath "input.pdf" -Language eng
```

### Secondary Entry Points

#### PDF Validation Utility
**File:** `validators/verify_ai_readable.py`  
**Purpose:** Validate OCR output quality and AI readability  
**Usage:** Quality assurance and testing  

```python
# Example usage
python src/validators/verify_ai_readable.py "processed.pdf"
```

## Key Components

### OCR Processing (`processors/`)

The processors directory contains the core OCR functionality:

#### `ocr_processor.py` - Main Processing Engine
**Key Functions:**
- `check_requirements()` - Validates OCR toolchain availability
- `has_text(pdf_path)` - Detects if PDF already has searchable text
- `ocr_pdf_like_adobe()` - Main OCR processing with Adobe-style output
- `process_directory()` - Batch processing for multiple files

**Features:**
- Adobe Acrobat-style OCR processing
- Automatic backup and recovery
- Comprehensive error handling
- Multi-language support
- Performance optimization

#### `OCRmyPDF-Processor.ps1` - PowerShell Interface
**Key Parameters:**
- `-InputPath` - PDF file or directory path
- `-Language` - OCR language code
- `-OutputPath` - Optional output directory
- `-ForceOCR` - Force OCR even if text exists
- `-DPI` - Image resolution setting

### Validation (`validators/`)

Quality assurance tools for OCR output:

#### `verify_ai_readable.py` - PDF Text Validation
**Purpose:**
- Verify OCR processing success
- Validate AI readability
- Quality assurance testing

### Future Expansion Areas

#### `core/` Directory (Placeholder)
**Intended Purpose:**
- Shared core functionality
- Configuration management
- Common utilities
- Plugin architecture

#### `utils/` Directory (Placeholder)  
**Intended Purpose:**
- Utility functions
- Helper classes
- File system operations
- Logging utilities

## Usage Patterns

### Programmatic Usage

```python
# Import the processing engine
from src.processors.ocr_processor import check_requirements, ocr_pdf_like_adobe

# Check system requirements
if check_requirements():
    # Process a PDF file
    success = ocr_pdf_like_adobe("input.pdf", language="eng")
    if success:
        print("OCR processing completed successfully")
```

### Command Line Usage

```bash
# Main utility (recommended for end users)
python ocr_pdfs.py "C:\MyDocuments\PDFs"

# Direct processor usage
python src/processors/ocr_processor.py "single_file.pdf"

# PowerShell usage (Windows)
.\src\processors\OCRmyPDF-Processor.ps1 -InputPath "C:\PDFs" -Language eng
```

## Development Guidelines

### Adding New Processors
1. Create new file in `processors/` directory
2. Follow existing error handling patterns
3. Import and use `check_requirements()` for validation
4. Add comprehensive docstrings and type hints
5. Update this README with new entry points

### Adding New Validators
1. Create new file in `validators/` directory
2. Follow single-responsibility principle
3. Include both success and failure test cases
4. Document expected input/output formats

### Code Organization Principles
- **Separation of Concerns**: Each module has a specific purpose
- **Dependency Injection**: Pass dependencies rather than hard-coding
- **Error Handling**: Graceful degradation and helpful error messages
- **Documentation**: Clear docstrings and type hints
- **Testing**: Unit and integration test coverage

## Import Patterns

### Recommended Imports
```python
# From root directory (typical usage)
from src.processors.ocr_processor import ocr_pdf_like_adobe

# From within src/ (internal usage)
from processors.ocr_processor import check_requirements

# For validation
from validators.verify_ai_readable import validate_pdf_text
```

### Path Configuration
The main entry point (`../ocr_pdfs.py`) automatically configures the Python path:
```python
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))
```

## Dependencies

### External Dependencies
- **ocrmypdf** - OCR processing engine
- **PyPDF2** - PDF manipulation and text extraction
- **pathlib** - Modern file path handling
- **subprocess** - External tool integration

### Internal Dependencies
```
ocr_pdfs.py → processors/ocr_processor.py → [external tools]
             ↓
validators/verify_ai_readable.py
```

## Testing

### Test Organization
```
../tests/
├── unit/                      # Unit tests for individual functions
│   └── test_ocr_processor.py # Tests for ocr_processor.py
├── integration/               # End-to-end tests
│   └── Pipeline.Tests.ps1    # PowerShell integration tests
└── fixtures/                 # Test data
    └── document.pdf          # Sample test PDF
```

### Running Tests
```bash
# From root directory
pytest tests/ -v

# Test specific component
pytest tests/unit/test_ocr_processor.py -v
```

---

**Need help navigating the code?** Check the main [README.md](../README.md) or [ARCHITECTURE.md](../docs/ARCHITECTURE.md) for more detailed information.