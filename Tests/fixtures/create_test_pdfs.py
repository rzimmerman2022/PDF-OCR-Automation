#!/usr/bin/env python3
"""
Create test PDF files for testing the PDF processing pipeline
"""

import os
import sys
from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter

def create_test_pdf(filename, content, output_dir):
    """Create a simple PDF with the given content"""
    filepath = Path(output_dir) / filename
    
    # Create PDF with reportlab
    c = canvas.Canvas(str(filepath), pagesize=letter)
    
    # Add content
    y_position = 750
    for line in content.split('\n'):
        if line.strip():
            c.drawString(72, y_position, line.strip())
            y_position -= 20
    
    c.save()
    return filepath

def create_mock_invoice():
    """Create a mock invoice PDF"""
    content = """
INVOICE

Invoice Number: INV-2024-001
Date: January 15, 2024
Due Date: February 15, 2024

Bill To:
Acme Corporation
123 Business Street
City, State 12345

Description                 Amount
Web Development Services    $2,500.00
Hosting Setup              $150.00
Domain Registration        $25.00

Total: $2,675.00

Thank you for your business!
"""
    return create_test_pdf("document.pdf", content, Path(__file__).parent)

def create_mock_report():
    """Create a mock technical report PDF"""
    content = """
TECHNICAL REPORT

Title: System Performance Analysis
Date: January 2024
Author: Technical Team

Executive Summary:
This report analyzes the performance characteristics of our 
current system infrastructure and provides recommendations
for optimization.

Key Findings:
- CPU utilization averages 45%
- Memory usage peaks at 78%
- Network latency is within acceptable ranges
- Storage I/O shows room for improvement

Recommendations:
1. Upgrade memory modules
2. Implement caching layer
3. Optimize database queries
4. Consider SSD migration

Conclusion:
The system performs adequately but would benefit from
targeted improvements in memory and storage subsystems.
"""
    return create_test_pdf("scan001.pdf", content, Path(__file__).parent)

def create_mock_contract():
    """Create a mock contract PDF"""
    content = """
SERVICE AGREEMENT

Contract Number: SA-2024-042
Effective Date: January 1, 2024
Expiration Date: December 31, 2024

Parties:
Service Provider: TechSolutions Inc.
Client: Business Enterprises LLC

Services:
- Software maintenance and support
- 24/7 system monitoring
- Monthly performance reports
- Security updates and patches

Terms:
- Monthly fee: $5,000
- Response time: 4 hours for critical issues
- Uptime guarantee: 99.5%
- Data backup included

This agreement governs the provision of technical services
as outlined in the attached Statement of Work.
"""
    return create_test_pdf("file_20240115.pdf", content, Path(__file__).parent)

def create_mock_manual():
    """Create a mock user manual PDF"""
    content = """
USER MANUAL

Product: SuperWidget Pro 3000
Version: 3.1.2
Date: January 2024

Table of Contents:
1. Introduction
2. Installation
3. Configuration
4. Usage
5. Troubleshooting

Chapter 1: Introduction
Welcome to SuperWidget Pro 3000, the ultimate solution
for widget management and optimization.

Key Features:
- Advanced widget analytics
- Real-time monitoring
- Automated optimization
- Comprehensive reporting

System Requirements:
- Windows 10 or later
- 4GB RAM minimum
- 1GB disk space
- Internet connection

For technical support, contact:
support@superwidget.com
"""
    return create_test_pdf("manual_v3.pdf", content, Path(__file__).parent)

def create_already_named_file():
    """Create a file that should not need renaming"""
    content = """
INVOICE

Invoice Number: INV-2024-002
Date: January 20, 2024

This is an invoice that already has a good filename
and should not need renaming during processing.
"""
    return create_test_pdf("Invoice_AcmeCorp_INV2024002_2024-01-20.pdf", content, Path(__file__).parent)

def main():
    """Create all test PDF files"""
    output_dir = Path(__file__).parent
    print(f"Creating test PDF files in: {output_dir}")
    
    test_functions = [
        ("Generic document", create_mock_invoice),
        ("Generic scan", create_mock_report),
        ("Generic file", create_mock_contract),
        ("Generic manual", create_mock_manual),
        ("Already well-named file", create_already_named_file)
    ]
    
    created_files = []
    
    for description, func in test_functions:
        try:
            filepath = func()
            created_files.append(filepath)
            print(f"✓ Created {description}: {filepath.name}")
        except Exception as e:
            print(f"✗ Failed to create {description}: {e}")
    
    print(f"\nSummary: Created {len(created_files)} test PDF files")
    print("\nTest files:")
    for filepath in created_files:
        print(f"  - {filepath.name}")
    
    print("\nThese files can be used to test:")
    print("  - AI renaming functionality")
    print("  - Generic vs specific filename detection")
    print("  - Batch processing")
    print("  - Error handling")

if __name__ == "__main__":
    try:
        main()
    except ImportError as e:
        print(f"Error: Missing required package: {e}")
        print("Install with: pip install reportlab")
        sys.exit(1)
    except Exception as e:
        print(f"Error creating test files: {e}")
        sys.exit(1)