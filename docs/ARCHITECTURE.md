# Architecture Documentation

**Last Updated:** 2025-08-10  
**Version:** 2.0.0  
**Description:** System design and component interactions for PDF-OCR-Automation

## System Overview

PDF-OCR-Automation is a modular OCR processing system built around industry-standard OCR engines (OCRmyPDF, Tesseract) with multiple entry points and processing modes.

## High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Entry Points  │    │  Core Modules   │    │ External Tools  │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ ocr_pdfs.py     │───→│ ocr_processor   │───→│ OCRmyPDF        │
│ PowerShell      │    │                 │    │ Tesseract       │
│ CLI Scripts     │    │ validators      │    │ Ghostscript     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Component Architecture

### 1. Entry Points Layer

#### Primary Entry Points
- **`ocr_pdfs.py`** - Main CLI utility for end users
  - **Purpose:** Batch processing interface
  - **Dependencies:** src.processors.ocr_processor
  - **Usage:** `python ocr_pdfs.py <folder_path>`

- **`src/processors/OCRmyPDF-Processor.ps1`** - PowerShell interface
  - **Purpose:** Windows-native automation wrapper
  - **Dependencies:** OCRmyPDF CLI, Tesseract CLI
  - **Usage:** PowerShell automation scenarios

#### Secondary Entry Points
- **Direct OCRmyPDF CLI** - Expert/scripting interface
- **Python module imports** - Programmatic usage

### 2. Core Processing Layer

#### OCR Processor (`src/processors/ocr_processor.py`)
**Responsibilities:**
- Core OCR logic implementation
- Adobe-style OCR processing
- Error handling and diagnostics
- Backup and recovery management

**Key Functions:**
```python
check_requirements()     # Validate OCR toolchain
has_text(pdf_path)      # Check if PDF needs OCR
ocr_pdf_like_adobe()    # Main OCR processing
process_directory()     # Batch processing
```

**Dependencies:**
- `ocrmypdf` - Core OCR engine
- `PyPDF2` - PDF text extraction and validation
- `pathlib` - File system operations
- `subprocess` - External tool interaction

#### Validators (`src/validators/`)
**Purpose:** Quality assurance and verification

- **`verify_ai_readable.py`** - Validates OCR output quality

### 3. Configuration Layer

#### Configuration Management
- **`config/default.json`** - System defaults
- **`config/env.example`** - Environment template
- **Environment variables** - Runtime configuration

#### Configuration Schema
```json
{
  "ocr": {
    "language": "eng",
    "dpi": 300,
    "optimize": 3
  },
  "processing": {
    "parallelJobs": 4,
    "batchSize": 10
  }
}
```

### 4. External Dependencies

#### OCR Toolchain
- **OCRmyPDF** - Primary OCR processing engine
- **Tesseract** - Text recognition engine  
- **Ghostscript** - PDF manipulation backend

#### Python Dependencies
- **Core:** ocrmypdf, pikepdf, Pillow, PyPDF2
- **Utilities:** python-dotenv, click, tqdm, colorama
- **Development:** pytest, black, flake8, mypy

## Data Flow

### Single File Processing Flow
```
Input PDF → Text Detection → OCR Processing → Quality Validation → Output PDF
     ↓             ↓              ↓                ↓               ↓
File Path → has_text() → ocr_pdf_like_adobe() → verify_readable() → Searchable PDF
```

### Batch Processing Flow
```
Input Directory → PDF Discovery → Filtering → Parallel Processing → Results Summary
       ↓               ↓            ↓              ↓                ↓
   Folder Path → glob("*.pdf") → Skip existing → Process queue → Success/failure count
```

## Error Handling Strategy

### Hierarchical Error Handling
1. **External Tool Errors** - OCRmyPDF/Tesseract failure codes
2. **File System Errors** - Permissions, space, corruption
3. **Processing Errors** - Invalid PDFs, encrypted files
4. **Configuration Errors** - Missing dependencies, invalid settings

### Recovery Mechanisms
- **Backup Creation** - Automatic backup before processing
- **Rollback on Failure** - Restore original on error
- **Graceful Degradation** - Continue batch processing on single failures
- **Diagnostic Logging** - Detailed error information capture

## Performance Characteristics

### Processing Performance
- **Single File:** ~5-30 seconds per PDF (depends on size/quality)
- **Batch Processing:** Parallel processing up to CPU core count
- **Memory Usage:** ~100-500MB per concurrent process

### Optimization Features
- **Text Detection** - Skip already-processed PDFs
- **File Size Optimization** - Reduce output size with `--optimize 3`
- **Quality Settings** - Balance speed vs. accuracy (DPI, noise removal)

## Extension Points

### Adding New Entry Points
1. Import `src.processors.ocr_processor` 
2. Call `check_requirements()` for validation
3. Use `ocr_pdf_like_adobe()` for processing

### Adding New Processors
1. Implement in `src/processors/`
2. Follow existing error handling patterns
3. Update configuration schema if needed

### Adding New Validators
1. Add to `src/validators/`
2. Integrate with main processing flow
3. Add to test suite

## Security Considerations

### Input Validation
- **Path Traversal Prevention** - Validate file paths
- **File Type Validation** - Ensure PDF input
- **Permission Checks** - Verify read/write access

### External Tool Security
- **Path Injection Prevention** - Sanitize command arguments
- **Resource Limits** - Prevent resource exhaustion
- **Temporary File Management** - Secure cleanup

## Testing Architecture

### Test Structure
```
tests/
├── unit/           # Unit tests for individual components
├── integration/    # End-to-end workflow tests
├── fixtures/       # Test PDF samples
└── mocks/          # Mock external dependencies
```

### Test Categories
- **Unit Tests** - Individual function testing
- **Integration Tests** - Full pipeline testing  
- **Performance Tests** - Timing and resource usage
- **Compatibility Tests** - Different PDF types and languages

## Deployment Considerations

### System Requirements
- **Operating System:** Windows (PowerShell), Linux/macOS (Python)
- **Python:** 3.8+ with pip
- **External Tools:** Tesseract OCR, Ghostscript
- **Disk Space:** 100MB+ free for processing

### Installation Methods
1. **Automated Install** - `scripts/install/install_ocr_tools.ps1`
2. **Manual Install** - Individual dependency installation
3. **Container Deployment** - Future Docker support

---
*This architecture documentation is maintained as part of the repository cleanup and standardization process.*