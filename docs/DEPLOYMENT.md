# Deployment Guide

**Last Updated:** 2025-08-10  
**Version:** 2.0.0  
**Description:** Step-by-step deployment instructions for production environments

## Table of Contents

- [Overview](#overview)
- [System Requirements](#system-requirements)
- [Production Environment Setup](#production-environment-setup)
- [Installation Methods](#installation-methods)
- [Configuration Management](#configuration-management)
- [Service Deployment](#service-deployment)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)

## Overview

This guide covers deploying PDF-OCR-Automation in production environments, including server setup, configuration management, and operational procedures.

## System Requirements

### Minimum System Requirements
- **CPU:** 2+ cores (4+ cores recommended for batch processing)
- **RAM:** 4GB minimum (8GB+ recommended)
- **Disk:** 10GB free space (more for high-volume processing)
- **OS:** Windows Server 2016+, Windows 10+, Ubuntu 18.04+, CentOS 7+

### Software Dependencies
- **Python:** 3.8 or higher
- **Tesseract OCR:** 4.1.0 or higher
- **Ghostscript:** 9.50 or higher
- **OCRmyPDF:** 16.0.0 or higher

## Production Environment Setup

### 1. Server Preparation

#### Windows Server
```powershell
# Enable PowerShell execution
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine

# Install Chocolatey package manager
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh environment
refreshenv
```

#### Linux Server (Ubuntu/Debian)
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install system dependencies
sudo apt install -y python3 python3-pip tesseract-ocr ghostscript

# Install additional OCR languages (optional)
sudo apt install -y tesseract-ocr-deu tesseract-ocr-fra tesseract-ocr-spa
```

#### Linux Server (RHEL/CentOS)
```bash
# Enable EPEL repository
sudo yum install -y epel-release

# Install system dependencies
sudo yum install -y python3 python3-pip tesseract ghostscript

# Install additional languages
sudo yum install -y tesseract-langpack-deu tesseract-langpack-fra tesseract-langpack-spa
```

### 2. Application Installation

#### Method 1: Automated Installation (Recommended)
```bash
# Clone repository
git clone https://github.com/yourusername/PDF-OCR-Automation.git
cd PDF-OCR-Automation

# Windows
.\scripts\install\install_ocr_tools.ps1

# Linux/macOS
chmod +x scripts/install/install_ocr_tools.sh
sudo ./scripts/install/install_ocr_tools.sh
```

#### Method 2: Manual Installation
```bash
# Install Python dependencies
pip3 install -r requirements.txt

# Verify installation
python3 -c "import ocrmypdf; print('OCRmyPDF installed successfully')"
tesseract --version
gs --version
```

## Configuration Management

### 1. Environment Configuration

#### Production Environment File
Create `/etc/pdf-ocr-automation/production.env`:
```env
# OCR Settings
OCR_LANGUAGE=eng
OCR_DPI=300
OCR_OPTIMIZE_LEVEL=3

# Processing
PARALLEL_JOBS=4
BATCH_SIZE=20
MAX_PROCESSING_TIME=1800

# Paths
INPUT_PATH=/var/ocr/input
OUTPUT_PATH=/var/ocr/output
TEMP_PATH=/tmp/ocr-processing
LOG_PATH=/var/log/pdf-ocr-automation

# Performance
ENABLE_CLEANUP=true
BACKUP_PROCESSED_FILES=true
DELETE_TEMP_FILES=true
```

#### Directory Structure Setup
```bash
# Create processing directories
sudo mkdir -p /var/ocr/{input,output,backup,logs}
sudo mkdir -p /tmp/ocr-processing

# Set permissions
sudo chown -R ocr-user:ocr-group /var/ocr
sudo chmod -R 755 /var/ocr
```

### 2. Configuration Validation
```bash
# Test configuration
python3 -c "
import os
from src.processors.ocr_processor import check_requirements
if check_requirements():
    print('✓ Configuration valid')
else:
    print('✗ Configuration issues detected')
"
```

## Service Deployment

### 1. Systemd Service (Linux)

#### Service File: `/etc/systemd/system/pdf-ocr-automation.service`
```ini
[Unit]
Description=PDF OCR Automation Service
After=network.target

[Service]
Type=simple
User=ocr-user
Group=ocr-group
WorkingDirectory=/opt/pdf-ocr-automation
Environment=PATH=/usr/local/bin:/usr/bin:/bin
EnvironmentFile=/etc/pdf-ocr-automation/production.env
ExecStart=/usr/bin/python3 /opt/pdf-ocr-automation/ocr_pdfs.py --daemon
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

#### Enable and Start Service
```bash
sudo systemctl daemon-reload
sudo systemctl enable pdf-ocr-automation.service
sudo systemctl start pdf-ocr-automation.service
sudo systemctl status pdf-ocr-automation.service
```

### 2. Windows Service

#### Using NSSM (Non-Sucking Service Manager)
```powershell
# Install NSSM
choco install nssm -y

# Create service
nssm install "PDF-OCR-Automation" "C:\Python39\python.exe" "C:\opt\PDF-OCR-Automation\ocr_pdfs.py --daemon"
nssm set "PDF-OCR-Automation" AppDirectory "C:\opt\PDF-OCR-Automation"
nssm set "PDF-OCR-Automation" AppEnvironmentExtra "PYTHONPATH=C:\opt\PDF-OCR-Automation"

# Start service
nssm start "PDF-OCR-Automation"
```

### 3. Docker Deployment (Optional)

#### Dockerfile
```dockerfile
FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    ghostscript \
    && rm -rf /var/lib/apt/lists/*

# Create application directory
WORKDIR /app

# Copy application files
COPY requirements.txt .
COPY src/ ./src/
COPY config/ ./config/
COPY ocr_pdfs.py .

# Install Python dependencies
RUN pip install -r requirements.txt

# Create processing directories
RUN mkdir -p /app/{input,output,logs}

# Create non-root user
RUN useradd -m -u 1000 ocruser
USER ocruser

# Set environment variables
ENV PYTHONPATH=/app
ENV OCR_INPUT_PATH=/app/input
ENV OCR_OUTPUT_PATH=/app/output

# Expose volume mount points
VOLUME ["/app/input", "/app/output", "/app/logs"]

# Start application
CMD ["python", "ocr_pdfs.py", "--daemon"]
```

#### Docker Compose
```yaml
version: '3.8'
services:
  pdf-ocr-automation:
    build: .
    restart: unless-stopped
    volumes:
      - ./input:/app/input
      - ./output:/app/output
      - ./logs:/app/logs
    environment:
      - OCR_LANGUAGE=eng
      - PARALLEL_JOBS=4
      - BATCH_SIZE=20
```

## Monitoring and Maintenance

### 1. Log Management

#### Log Rotation Configuration (`/etc/logrotate.d/pdf-ocr-automation`)
```
/var/log/pdf-ocr-automation/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

### 2. Health Checks

#### Health Check Script (`scripts/health-check.py`)
```python
#!/usr/bin/env python3
import sys
import subprocess
from pathlib import Path

def health_check():
    """Basic health check for OCR service"""
    try:
        # Check OCRmyPDF availability
        subprocess.run(['ocrmypdf', '--version'], 
                      capture_output=True, check=True)
        
        # Check Tesseract availability
        subprocess.run(['tesseract', '--version'], 
                      capture_output=True, check=True)
        
        # Check disk space (minimum 1GB)
        stat = Path('/var/ocr').stat()
        if stat.st_size < 1024**3:  # 1GB
            print("WARNING: Low disk space")
            return 1
            
        print("✓ All systems operational")
        return 0
        
    except Exception as e:
        print(f"✗ Health check failed: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(health_check())
```

### 3. Performance Monitoring

#### Basic Metrics Collection
```bash
# CPU and Memory usage
ps aux | grep ocr_pdfs

# Disk usage
df -h /var/ocr

# Processing queue size
ls -la /var/ocr/input | wc -l

# Recent processing activity
tail -f /var/log/pdf-ocr-automation/processing.log
```

## Security Considerations

### 1. User Permissions
```bash
# Create dedicated user
sudo useradd -r -s /bin/false ocr-user

# Set directory permissions
sudo chown -R ocr-user:ocr-user /var/ocr
sudo chmod 750 /var/ocr
```

### 2. File Security
```bash
# Secure configuration files
sudo chmod 640 /etc/pdf-ocr-automation/production.env
sudo chown root:ocr-group /etc/pdf-ocr-automation/production.env
```

### 3. Network Security
- **Firewall:** Block unnecessary ports
- **Access Control:** Limit SSH access to admin users
- **VPN:** Use VPN for remote administration

## Troubleshooting

### Common Deployment Issues

#### Issue: OCRmyPDF not found
**Solution:**
```bash
# Verify OCRmyPDF installation
python3 -c "import ocrmypdf; print(ocrmypdf.__version__)"

# Reinstall if needed
pip3 install --upgrade ocrmypdf
```

#### Issue: Tesseract language packs missing
**Solution:**
```bash
# Ubuntu/Debian
sudo apt install tesseract-ocr-[language-code]

# CentOS/RHEL
sudo yum install tesseract-langpack-[language-code]
```

#### Issue: Permission denied errors
**Solution:**
```bash
# Check directory permissions
ls -la /var/ocr

# Fix permissions
sudo chown -R ocr-user:ocr-user /var/ocr
sudo chmod -R 755 /var/ocr
```

### Log Analysis

#### Check Service Status
```bash
# Systemd service
sudo journalctl -u pdf-ocr-automation.service -f

# Application logs
tail -f /var/log/pdf-ocr-automation/processing.log
```

#### Debug Mode
```bash
# Enable debug logging
export OCR_DEBUG=true
python3 ocr_pdfs.py /path/to/pdfs --verbose
```

## Backup and Recovery

### 1. Configuration Backup
```bash
# Backup configuration
tar -czf /backup/pdf-ocr-config-$(date +%Y%m%d).tar.gz \
    /etc/pdf-ocr-automation/ \
    /opt/pdf-ocr-automation/config/
```

### 2. Data Backup
```bash
# Backup processed files
rsync -av /var/ocr/output/ /backup/ocr-output/

# Backup logs
tar -czf /backup/ocr-logs-$(date +%Y%m%d).tar.gz /var/log/pdf-ocr-automation/
```

---

**For additional support, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or [ARCHITECTURE.md](ARCHITECTURE.md).**