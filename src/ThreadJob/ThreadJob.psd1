#
# Module manifest for module 'ThreadJob'
#

@{

# Script module or binary module file associated with this manifest.
RootModule = '.\ThreadJob.psm1'

# Version number of this module.
ModuleVersion = '2.0.4'

# ID used to uniquely identify this module
GUID = '0e7b895d-2fec-43f7-8cae-11e8d16f6e40'

Author = 'Microsoft Corporation'
CompanyName = 'Microsoft Corporation'
Copyright = '(c) Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'ThreadJob module has been renamed to Microsoft.PowerShell.ThreadJob.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.1'

RequiredModules = @('Microsoft.PowerShell.ThreadJob')
FunctionsToExport = @()

# Cmdlets to export from this module
CmdletsToExport = @()
AliasesToExport = @('Start-ThreadJob', 'ThreadJob\Start-ThreadJob')

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{
    PSData = @{
      LicenseUri = 'https://github.com/PowerShell/ThreadJob/blob/master/LICENSE'
      ProjectUri = 'https://github.com/PowerShell/ThreadJob'
    }
} # End of PrivateData hashtable

}