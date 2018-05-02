#
# Module manifest for module 'HCSharepoint'
#
# Generated by: JB Lewis
#
# Generated on: 10/29/2014
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'hcsharepoint.psm1'

# Version number of this module.
ModuleVersion = '1.1.5.0'

# ID used to uniquely identify this module
GUID = 'e381041c-4df3-4482-9419-a6b80a816434'

# Author of this module
Author = 'JB Lewis'

# Company or vendor of this module
CompanyName = 'Hennepin County'

# Copyright statement for this module
Copyright = '(c) 2014 Hennepin County. All rights reserved. MIT License'

# Description of the functionality provided by this module
Description = 'Enables interaction with SharePoint Lists'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @('bin\Microsoft.SharePoint.Client.dll','bin\Microsoft.SharePoint.Client.Runtime.dll')

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
#ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @('hcsharepoint.Format.ps1xml')

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = 'Get-SPListItem','Update-SPListItem','Remove-SPListItem','New-SPListItem','Get-SPListField'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

