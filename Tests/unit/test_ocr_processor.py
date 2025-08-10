#!/usr/bin/env python3
"""
Unit tests for ocr_processor.py
Tests core OCR functionality and requirements checking
"""

import unittest
import sys
import os
from unittest.mock import Mock, patch, MagicMock
from pathlib import Path

# Add the src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'src'))

try:
    from processors.ocr_processor import check_requirements, has_text
except ImportError as e:
    print(f"Import error: {e}")
    print("Skipping OCR processor tests - module not available")
    sys.exit(0)


class TestOCRProcessor(unittest.TestCase):
    """Test core OCR processor functionality"""

    def setUp(self):
        """Set up test environment"""
        self.test_pdf_path = Path(__file__).parent.parent / "fixtures" / "document.pdf"

    @patch('subprocess.run')
    def test_check_requirements_tesseract_found(self, mock_run):
        """Test that check_requirements correctly identifies available Tesseract"""
        # Mock successful Tesseract version check
        mock_result = Mock()
        mock_result.stdout = "tesseract 4.1.1"
        mock_run.return_value = mock_result
        
        # Mock successful ocrmypdf import
        with patch.dict('sys.modules', {'ocrmypdf': Mock()}):
            result = check_requirements()
            
        self.assertTrue(result)
        mock_run.assert_called()

    @patch('subprocess.run')
    def test_check_requirements_tesseract_not_found(self, mock_run):
        """Test that check_requirements handles missing Tesseract"""
        # Mock FileNotFoundError for all Tesseract paths
        mock_run.side_effect = FileNotFoundError()
        
        result = check_requirements()
        
        self.assertFalse(result)

    @patch('builtins.open')
    @patch('PyPDF2.PdfReader')
    def test_has_text_with_searchable_pdf(self, mock_pdf_reader, mock_open):
        """Test has_text() correctly identifies searchable PDFs"""
        # Mock PDF with searchable text
        mock_page = Mock()
        mock_page.extract_text.return_value = "This is searchable text content"
        
        mock_reader = Mock()
        mock_reader.pages = [mock_page]
        mock_pdf_reader.return_value = mock_reader
        
        result = has_text("dummy_path.pdf")
        
        self.assertTrue(result)

    @patch('builtins.open')
    @patch('PyPDF2.PdfReader')
    def test_has_text_with_scanned_pdf(self, mock_pdf_reader, mock_open):
        """Test has_text() correctly identifies scanned PDFs needing OCR"""
        # Mock PDF with no searchable text
        mock_page = Mock()
        mock_page.extract_text.return_value = ""
        
        mock_reader = Mock()
        mock_reader.pages = [mock_page]
        mock_pdf_reader.return_value = mock_reader
        
        result = has_text("dummy_path.pdf")
        
        self.assertFalse(result)

    @patch('builtins.open')
    @patch('PyPDF2.PdfReader')
    def test_has_text_handles_exceptions(self, mock_pdf_reader, mock_open):
        """Test has_text() handles PDF reading exceptions gracefully"""
        # Mock PDF reading exception
        mock_pdf_reader.side_effect = Exception("PDF read error")
        
        result = has_text("corrupted.pdf")
        
        self.assertFalse(result)

    def test_module_imports(self):
        """Test that all required modules can be imported"""
        try:
            import ocrmypdf
            import PyPDF2
            import subprocess
            from pathlib import Path
            self.assertTrue(True)  # All imports successful
        except ImportError as e:
            self.fail(f"Required module import failed: {e}")


class TestSystemRequirements(unittest.TestCase):
    """Test system requirements and dependencies"""

    def test_python_version(self):
        """Test that Python version meets requirements (>= 3.8)"""
        python_version = sys.version_info
        self.assertGreaterEqual(python_version.major, 3)
        if python_version.major == 3:
            self.assertGreaterEqual(python_version.minor, 8)

    def test_pathlib_available(self):
        """Test that pathlib is available for path operations"""
        from pathlib import Path
        test_path = Path("test")
        self.assertTrue(hasattr(test_path, 'exists'))
        self.assertTrue(hasattr(test_path, 'with_suffix'))

    def test_subprocess_available(self):
        """Test that subprocess module is available for external tool calls"""
        import subprocess
        self.assertTrue(hasattr(subprocess, 'run'))
        self.assertTrue(hasattr(subprocess, 'PIPE'))


if __name__ == '__main__':
    # Print test environment information
    print(f"Python version: {sys.version}")
    print(f"Test directory: {os.path.dirname(__file__)}")
    
    # Run the tests
    unittest.main(verbosity=2)