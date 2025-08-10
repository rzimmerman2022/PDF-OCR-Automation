# Contributing to PDF-OCR-Automation

**Last Updated:** 2025-08-10  
**Version:** 2.0.0  

Thank you for your interest in contributing to PDF-OCR-Automation! This document provides guidelines for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contribution Process](#contribution-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project adheres to a code of conduct adapted from the [Contributor Covenant](https://www.contributor-covenant.org/). By participating, you are expected to uphold this code.

### Our Standards

- **Be respectful** and inclusive
- **Be constructive** in discussions and feedback
- **Focus on what is best** for the community
- **Show empathy** towards other community members

## Getting Started

### Prerequisites

- Python 3.8 or higher
- Git
- Basic understanding of OCR and PDF processing
- Familiarity with OCRmyPDF and Tesseract

### Areas for Contribution

- **Bug fixes** and issue resolution
- **Feature enhancements** and new functionality
- **Documentation** improvements
- **Performance optimizations**
- **Test coverage** expansion
- **Example scripts** and use cases

## Development Setup

### 1. Fork and Clone Repository

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR-USERNAME/PDF-OCR-Automation.git
cd PDF-OCR-Automation

# Add upstream remote
git remote add upstream https://github.com/original-owner/PDF-OCR-Automation.git
```

### 2. Set Up Development Environment

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/macOS:
source venv/bin/activate

# Install development dependencies
pip install -r requirements.txt
pip install -e .

# Install development tools
pip install pytest pytest-cov black flake8 mypy pre-commit
```

### 3. Install Pre-commit Hooks

```bash
pre-commit install
```

### 4. Verify Setup

```bash
# Run tests
pytest tests/ -v

# Check code style
black --check src/
flake8 src/
mypy src/

# Test OCR functionality
python src/processors/ocr_processor.py --help
```

## Contribution Process

### 1. Planning Your Contribution

- **Check existing issues** on GitHub
- **Open a new issue** if your feature/bug isn't already tracked
- **Discuss your approach** in the issue before starting work
- **Keep contributions focused** - one feature/fix per PR

### 2. Branch Strategy

```bash
# Create feature branch from main
git checkout main
git pull upstream main
git checkout -b feature/your-feature-name

# For bug fixes:
git checkout -b fix/issue-description

# For documentation:
git checkout -b docs/topic-description
```

## Coding Standards

### Python Code Style

We use **Black** for code formatting and **flake8** for linting:

```bash
# Format code
black src/ tests/

# Check linting
flake8 src/ tests/
```

### Code Quality Guidelines

1. **Follow PEP 8** Python style guidelines
2. **Use descriptive variable names**
3. **Add docstrings** to functions and classes
4. **Include type hints** where appropriate
5. **Keep functions focused** and single-purpose
6. **Handle errors gracefully** with proper exception handling

### Example Function Structure

```python
def process_pdf_file(pdf_path: Path, language: str = "eng") -> bool:
    """
    Process a single PDF file with OCR.
    
    Args:
        pdf_path: Path to the PDF file to process
        language: OCR language code (default: "eng")
        
    Returns:
        True if processing succeeded, False otherwise
        
    Raises:
        FileNotFoundError: If the PDF file doesn't exist
        PermissionError: If insufficient permissions for file access
    """
    try:
        # Implementation here
        return True
    except Exception as e:
        logger.error(f"Failed to process {pdf_path}: {e}")
        return False
```

### PowerShell Code Style

For PowerShell scripts:
- Use **approved verbs** (Get, Set, New, etc.)
- Include **parameter validation**
- Add **comprehensive help** with examples
- Use **proper error handling**

## Testing Guidelines

### Test Structure

```
tests/
├── unit/           # Unit tests for individual functions
├── integration/    # End-to-end workflow tests
├── fixtures/       # Test data and sample files
└── mocks/          # Mock objects and responses
```

### Writing Tests

1. **Write tests first** (TDD approach recommended)
2. **Test both success and failure cases**
3. **Use descriptive test names**
4. **Keep tests isolated** and independent
5. **Mock external dependencies** (OCRmyPDF, file system)

### Test Example

```python
def test_has_text_detects_searchable_pdf():
    """Test that has_text() correctly identifies PDFs with searchable text."""
    # Arrange
    pdf_path = Path("tests/fixtures/searchable.pdf")
    
    # Act
    result = has_text(pdf_path)
    
    # Assert
    assert result is True

def test_has_text_detects_scanned_pdf():
    """Test that has_text() correctly identifies scanned PDFs needing OCR."""
    # Arrange
    pdf_path = Path("tests/fixtures/scanned.pdf")
    
    # Act
    result = has_text(pdf_path)
    
    # Assert
    assert result is False
```

### Running Tests

```bash
# Run all tests
pytest tests/ -v

# Run specific test file
pytest tests/unit/test_ocr_processor.py -v

# Run with coverage
pytest tests/ -v --cov=src --cov-report=html

# Run integration tests only
pytest tests/integration/ -v
```

## Documentation Standards

### Documentation Requirements

1. **Update README.md** if adding new features
2. **Add docstrings** to new functions and classes
3. **Create/update relevant documentation** in `docs/`
4. **Include code examples** in documentation
5. **Test documentation examples** to ensure they work

### Documentation Format

- Use **Markdown** for all documentation
- Include **metadata headers** with last updated date and version
- Add **table of contents** for longer documents
- Use **code blocks** with language specification
- Include **links** to related documentation

## Commit Guidelines

### Commit Message Format

Use conventional commits format:

```
<type>(<scope>): <description>

<body>

<footer>
```

### Types

- **feat:** New feature
- **fix:** Bug fix
- **docs:** Documentation changes
- **style:** Code style changes (formatting, no logic changes)
- **refactor:** Code refactoring
- **test:** Adding or updating tests
- **chore:** Maintenance tasks

### Examples

```bash
feat(ocr): add support for multiple language OCR
fix(processor): handle corrupted PDF files gracefully
docs(api): add examples for batch processing
test(integration): add end-to-end OCR workflow tests
```

## Pull Request Process

### Before Submitting

1. **Ensure tests pass**: `pytest tests/ -v`
2. **Check code style**: `black --check src/ && flake8 src/`
3. **Update documentation** as needed
4. **Add changelog entry** if significant change
5. **Rebase on latest main** to avoid merge conflicts

### Pull Request Template

When creating a PR, include:

- **Description** of changes made
- **Motivation** and context
- **Testing** performed
- **Screenshots** if UI changes
- **Breaking changes** if any
- **Checklist** completion

### Review Process

1. **Automated checks** must pass (CI/CD)
2. **Code review** by maintainers
3. **Testing** in development environment
4. **Documentation review** if applicable
5. **Approval** and merge by maintainers

### After Merge

- **Delete feature branch**
- **Update local main branch**
- **Close related issues** if applicable

## Getting Help

### Communication Channels

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - General questions and community discussion
- **Documentation** - Check existing docs first

### Asking for Help

When asking for help:

1. **Search existing issues** first
2. **Provide specific details** about your problem
3. **Include error messages** and logs
4. **Describe your environment** (OS, Python version, etc.)
5. **Show what you've tried** already

## Recognition

Contributors will be recognized in:

- **README.md** contributors section
- **CHANGELOG.md** for significant contributions
- **Release notes** for major features

Thank you for contributing to PDF-OCR-Automation! 🎉

---

**Questions?** Open an issue or discussion on GitHub.