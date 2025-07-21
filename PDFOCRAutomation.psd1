# Module manifest for PDF OCR Automation Suite

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'PDFOCRAutomation.psm1'
    
    # Version number of this module.
    ModuleVersion = '2.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'a7c4f8e2-9b3d-4e5f-8c1a-2d6e4f8a9c3b'
    
    # Author of this module
    Author = 'GitHub Copilot & Community'
    
    # Company or vendor of this module
    CompanyName = 'Open Source'
    
    # Copyright statement for this module
    Copyright = '(c) 2025. MIT License.'
    
    # Description of the functionality provided by this module
    Description = 'Universal PDF OCR Automation Suite - Process and intelligently rename PDF documents using Adobe Acrobat Pro OCR capabilities. Supports multiple languages, document types, and batch processing.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''
    
    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module
    # DotNetFrameworkVersion = '4.5'
    
    # Minimum version of the common language runtime (CLR) required by this module
    # ClrVersion = '4.0'
    
    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''
    
    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Start-PDFOCRProcessor',
        'Test-PDFOCREnvironment',
        'Add-AdobeToPath',
        'Get-PDFOCRStatistics',
        'Install-PDFOCRAutomation'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @(
        'Process-PDFs',
        'OCR-PDFs'
    )
    
    # DSC resources to export from this module
    # DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    # ModuleList = @()
    
    # List of all files packaged with this module
    FileList = @(
        'PDFOCRAutomation.psd1',
        'PDFOCRAutomation.psm1',
        'Universal-PDF-OCR-Processor.ps1',
        'Setup.ps1',
        'Add-AdobeToPath.ps1',
        'Install-PDFOCRAutomation.ps1',
        'GUI-PDFOCRProcessor.ps1',
        'README.md',
        'LICENSE'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('PDF', 'OCR', 'Automation', 'Adobe', 'Acrobat', 'Document', 'Processing', 'Batch')
            
            # A URL to the license for this module.
            LicenseUri = 'https://github.com/yourusername/PDF-OCR-Automation/blob/main/LICENSE'
            
            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/yourusername/PDF-OCR-Automation'
            
            # A URL to an icon representing this module.
            # IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 2.0.0
- Complete universal document processing
- Multi-language OCR support (13+ languages)
- Intelligent document type detection
- Progress indicators and performance metrics
- OCR quality assessment
- Comprehensive error handling
- GUI wrapper for non-technical users
- Automated test suite
- GitHub Actions integration
'@
            
            # Prerelease string of this module
            # Prerelease = ''
            
            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            # ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}