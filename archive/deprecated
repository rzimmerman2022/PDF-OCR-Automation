#!/usr/bin/env python3
"""
Unit tests for pdf_renamer.py
Tests core functionality without requiring actual API calls
"""

import unittest
import sys
import os
import tempfile
import json
from unittest.mock import Mock, patch, MagicMock
from pathlib import Path

# Add the parent directory to Python path to import pdf_renamer
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

try:
    from pdf_renamer import PDFAnalyzer, load_env
except ImportError as e:
    print(f"Warning: Could not import pdf_renamer: {e}")
    print("This is expected if running tests without all dependencies")
    PDFAnalyzer = None

class TestPDFRenamer(unittest.TestCase):
    """Test cases for PDFAnalyzer class"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_api_key = "test_api_key_12345"
        self.temp_dir = tempfile.mkdtemp()
        
    def tearDown(self):
        """Clean up test environment"""
        # Clean up temp directory
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    @unittest.skipIf(PDFAnalyzer is None, "PDFAnalyzer not available")
    def test_init_with_api_key(self):
        """Test PDFAnalyzer initialization with API key"""
        analyzer = PDFAnalyzer(api_key=self.test_api_key, dry_run=True)
        self.assertEqual(analyzer.api_key, self.test_api_key)
        self.assertTrue(analyzer.dry_run)
        self.assertEqual(analyzer.files_processed, 0)
        self.assertEqual(analyzer.total_cost, 0.0)
    
    @unittest.skipIf(PDFAnalyzer is None, "PDFAnalyzer not available")
    def test_init_without_api_key(self):
        """Test PDFAnalyzer initialization without API key"""
        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(ValueError):
                PDFAnalyzer()
    
    @unittest.skipIf(PDFAnalyzer is None, "PDFAnalyzer not available")
    @patch('pdf_renamer.PyPDF2.PdfReader')
    def test_extract_text_success(self, mock_pdf_reader):
        """Test successful text extraction"""
        # Mock PDF reader
        mock_page = Mock()
        mock_page.extract_text.return_value = "Test document content"
        
        mock_reader_instance = Mock()
        mock_reader_instance.pages = [mock_page]
        mock_pdf_reader.return_value = mock_reader_instance
        
        analyzer = PDFAnalyzer(api_key=self.test_api_key, dry_run=True)
        
        # Create a temporary PDF file
        test_pdf = os.path.join(self.temp_dir, "test.pdf")
        with open(test_pdf, 'wb') as f:
            f.write(b"fake pdf content")
        
        text = analyzer.extract_text(test_pdf)
        self.assertEqual(text, "Test document content\n")
    
    @unittest.skipIf(PDFAnalyzer is None, "PDFAnalyzer not available")
    def test_extract_text_failure(self):
        """Test text extraction failure"""
        analyzer = PDFAnalyzer(api_key=self.test_api_key, dry_run=True)
        
        # Test with non-existent file
        text = analyzer.extract_text("nonexistent.pdf")
        self.assertEqual(text, "")
    
    @unittest.skipIf(PDFAnalyzer is None, "PDFAnalyzer not available")
    @patch('pdf_renamer.genai')
    def test_generate_filename_success(self, mock_genai):
        """Test successful filename generation"""
        # Mock AI response
        mock_response = Mock()
        mock_response.text = json.dumps({
            "filename": "Invoice_CompanyABC_12345_2024-01-15",
            "document_type": "Invoice",
            "key_info": "Invoice from Company ABC",
            "confidence": "high"
        })
        
        mock_model = Mock()
        mock_model.generate_content.return_value = mock_response
        mock_genai.GenerativeModel.return_value = mock_model
        
        analyzer = PDFAnalyzer(api_key=self.test_api_key, dry_run=True)
        
        filename, analysis = analyzer.generate_filename("Sample invoice text", "document.pdf")
        
        self.assertEqual(filename, "Invoice_CompanyABC_12345_2024-01-15")
        self.assertEqual(analysis["document_type"], "Invoice")
        self.assertEqual(analysis["confidence"], "high")
    
    @unittest.skipIf(PDFAnalyzer is None, "PDFAnalyzer not available")
    @patch('pdf_renamer.genai')
    def test_generate_filename_failure(self, mock_genai):
        """Test filename generation failure"""
        # Mock AI failure
        mock_model = Mock()
        mock_model.generate_content.side_effect = Exception("API Error")
        mock_genai.GenerativeModel.return_value = mock_model
        
        analyzer = PDFAnalyzer(api_key=self.test_api_key, dry_run=True)
        
        filename, analysis = analyzer.generate_filename("Sample text", "document.pdf")
        
        self.assertTrue(filename.startswith("Document_"))
        self.assertEqual(analysis["document_type"], "Unknown")
        self.assertEqual(analysis["confidence"], "low")
    
    @unittest.skipIf(PDFAnalyzer is None, "PDFAnalyzer not available")
    @patch('pdf_renamer.PDFAnalyzer.extract_text')
    @patch('pdf_renamer.PDFAnalyzer.generate_filename')
    def test_process_pdf_dry_run(self, mock_generate, mock_extract):
        """Test PDF processing in dry run mode"""
        mock_extract.return_value = "Sample document content"
        mock_generate.return_value = ("New_Document_Name", {
            "document_type": "Report",
            "confidence": "high"
        })
        
        analyzer = PDFAnalyzer(api_key=self.test_api_key, dry_run=True)
        
        # Create a temporary PDF file
        test_pdf = os.path.join(self.temp_dir, "test_document.pdf")
        with open(test_pdf, 'wb') as f:
            f.write(b"fake pdf content")
        
        result = analyzer.process_pdf(test_pdf)
        
        self.assertEqual(result["status"], "dry_run")
        self.assertEqual(result["new_name"], "New_Document_Name.pdf")
        self.assertEqual(result["original_name"], "test_document.pdf")

class TestUtilityFunctions(unittest.TestCase):
    """Test utility functions"""
    
    def test_load_env_with_file(self):
        """Test loading environment variables from .env file"""
        with tempfile.TemporaryDirectory() as temp_dir:
            env_file = os.path.join(temp_dir, '.env')
            with open(env_file, 'w') as f:
                f.write('GEMINI_API_KEY=test_key_123\n')
                f.write('OTHER_VAR=test_value\n')
                f.write('# Comment line\n')
                f.write('QUOTED_VAR="quoted_value"\n')
            
            # Change to temp directory
            old_cwd = os.getcwd()
            try:
                os.chdir(temp_dir)
                
                # Clear environment
                if 'GEMINI_API_KEY' in os.environ:
                    del os.environ['GEMINI_API_KEY']
                
                load_env()
                
                self.assertEqual(os.environ.get('GEMINI_API_KEY'), 'test_key_123')
                self.assertEqual(os.environ.get('OTHER_VAR'), 'test_value')
                self.assertEqual(os.environ.get('QUOTED_VAR'), 'quoted_value')
                
            finally:
                os.chdir(old_cwd)
    
    def test_load_env_without_file(self):
        """Test loading environment when .env file doesn't exist"""
        with tempfile.TemporaryDirectory() as temp_dir:
            old_cwd = os.getcwd()
            try:
                os.chdir(temp_dir)
                # Should not raise an exception
                load_env()
            finally:
                os.chdir(old_cwd)

class TestCommandLineInterface(unittest.TestCase):
    """Test command line interface functionality"""
    
    @patch('sys.argv', ['pdf_renamer.py', '--help'])
    def test_help_argument(self):
        """Test help argument parsing"""
        try:
            from pdf_renamer import main
            with self.assertRaises(SystemExit):
                main()
        except ImportError:
            self.skipTest("pdf_renamer module not available")
    
    @patch('sys.argv', ['pdf_renamer.py', 'test1.pdf', 'test2.pdf', '--dry-run'])
    @patch('pdf_renamer.PDFAnalyzer')
    def test_dry_run_argument(self, mock_analyzer_class):
        """Test dry run argument parsing"""
        try:
            from pdf_renamer import main
            
            # Mock analyzer
            mock_analyzer = Mock()
            mock_analyzer.process_files.return_value = []
            mock_analyzer.total_cost = 0.0
            mock_analyzer_class.return_value = mock_analyzer
            
            with self.assertRaises(SystemExit) as cm:
                main()
            
            # Should exit with code 0 (success)
            self.assertEqual(cm.exception.code, 0)
            
            # Verify analyzer was created with dry_run=True
            mock_analyzer_class.assert_called_once()
            call_kwargs = mock_analyzer_class.call_args[1]
            self.assertTrue(call_kwargs.get('dry_run', False))
            
        except ImportError:
            self.skipTest("pdf_renamer module not available")

class TestErrorHandling(unittest.TestCase):
    """Test error handling scenarios"""
    
    @unittest.skipIf(PDFAnalyzer is None, "PDFAnalyzer not available")
    def test_invalid_pdf_file(self):
        """Test handling of invalid PDF files"""
        analyzer = PDFAnalyzer(api_key="test_key", dry_run=True)
        
        # Create invalid PDF file
        with tempfile.NamedTemporaryFile(suffix='.pdf', delete=False) as f:
            f.write(b"This is not a valid PDF file")
            invalid_pdf = f.name
        
        try:
            result = analyzer.process_pdf(invalid_pdf)
            # Should handle the error gracefully
            self.assertIn(result["status"], ["error", "skip"])
        finally:
            os.unlink(invalid_pdf)
    
    @unittest.skipIf(PDFAnalyzer is None, "PDFAnalyzer not available")
    def test_nonexistent_file(self):
        """Test handling of non-existent files"""
        analyzer = PDFAnalyzer(api_key="test_key", dry_run=True)
        
        result = analyzer.process_pdf("nonexistent_file.pdf")
        self.assertEqual(result["status"], "error")
        self.assertIn("not found", result["error"].lower())

def run_tests():
    """Run all tests and return results"""
    # Create test suite
    test_suite = unittest.TestSuite()
    
    # Add test cases
    test_classes = [
        TestPDFRenamer,
        TestUtilityFunctions,
        TestCommandLineInterface,
        TestErrorHandling
    ]
    
    for test_class in test_classes:
        tests = unittest.TestLoader().loadTestsFromTestCase(test_class)
        test_suite.addTests(tests)
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2, buffer=True)
    result = runner.run(test_suite)
    
    return result

if __name__ == "__main__":
    print("Running PDF Renamer Unit Tests")
    print("=" * 50)
    
    result = run_tests()
    
    print(f"\nTest Summary:")
    print(f"Tests run: {result.testsRun}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    print(f"Skipped: {len(result.skipped)}")
    
    if result.failures:
        print("\nFailures:")
        for test, traceback in result.failures:
            print(f"  {test}: {traceback}")
    
    if result.errors:
        print("\nErrors:")
        for test, traceback in result.errors:
            print(f"  {test}: {traceback}")
    
    # Exit with appropriate code
    sys.exit(0 if result.wasSuccessful() else 1)