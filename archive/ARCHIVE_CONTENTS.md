# ARCHIVE CONTENTS

**Created:** 2025-08-10  
**Purpose:** Documents archived files during repository cleanup  

This directory contains files that have been archived during the repository standardization process. Files are organized by reason for archiving.

## Directory Structure

### `/deprecated/` - Legacy and superseded files
Contains old scripts and files that have been replaced by the current implementation:

- **Legacy PowerShell scripts**: Old OCR processors, setup scripts, and utilities that have been superseded by the current `src/` implementation
- **Old test scripts**: Previous testing approach replaced by the structured `Tests/` directory  
- **Previous documentation**: `README-OLD.md` - replaced by current README.md
- **Legacy Python scripts**: Various OCR implementations that were consolidated into the current architecture
- **Old project cleanup scripts**: Historical maintenance scripts
- **Empty folder structures**: Previous directory organization attempts

**Note:** These files represent the evolution of the project and may contain useful historical context or alternative approaches.

### `/experimental/` - Domain-specific and unfinished features
Contains experimental or highly specialized functionality:

- **Estate research scripts**: Domain-specific processing scripts for estate document workflows
- **Specialized renaming utilities**: Custom document processing for specific use cases

**Note:** These files were domain-specific implementations that aren't part of the core OCR utility but may be useful for specialized workflows.

### `/logs/` - Historical processing logs
Contains extensive historical logs from development and testing phases:

- **Rename logs**: ~80+ JSON files tracking file renaming operations from development
- **Processing logs**: System processing logs from various testing phases
- **Collision logs**: Duplicate file handling logs

**Note:** These logs provide historical context for development decisions and testing phases but aren't needed for current operations.

## Restoration Process

If you need to restore any archived files:

1. **Identify the file** in the appropriate subdirectory
2. **Copy (don't move)** to avoid losing the archive
3. **Update any path references** in the restored file
4. **Test thoroughly** as dependencies may have changed

## Cleanup Rationale

Files were archived rather than deleted to:
- **Preserve development history** and alternative approaches
- **Enable restoration** if current implementation has limitations  
- **Maintain audit trail** of project evolution
- **Keep specialized functionality** available for future reference

## Archive Maintenance

- **Review periodically** (e.g., annually) for files that can be permanently removed
- **Keep permanently**: Any files containing unique algorithms or approaches
- **Consider removing**: Routine logs older than 1 year, duplicate implementations

---
*Generated during Phase 3 of repository cleanup on 2025-08-10*