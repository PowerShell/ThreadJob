#
# Module manifest for module 'Microsoft.PowerShell.ThreadJob'
#

@{

# Script module or binary module file associated with this manifest.
RootModule = '.\Microsoft.PowerShell.ThreadJob.dll'

# Version number of this module.
ModuleVersion = '2.2.0'

# ID used to uniquely identify this module
GUID = 'a84b375d-c1d6-4a1c-bcb7-8059bc28cd98'

Author = 'Microsoft Corporation'
CompanyName = 'Microsoft Corporation'
Copyright = '(c) Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = "
PowerShell's built-in BackgroundJob jobs (Start-Job) are run in separate processes on the local machine.
They provide excellent isolation but are resource heavy.  Running hundreds of BackgroundJob jobs can quickly
absorb system resources.

This module extends the existing PowerShell BackgroundJob to include a new thread based ThreadJob job.  This is a 
lighter weight solution for running concurrent PowerShell scripts that works within the existing PowerShell job 
infrastructure.

ThreadJob jobs will tend to run quicker because there is lower overhead and they do not use the remoting serialization 
system.  And they will use up fewer system resources.  In addition output objects returned from the job will be
'live' since they are not re-hydrated from the serialization system.  However, there is less isolation.  If one
ThreadJob job crashes the process then all ThreadJob jobs running in that process will be terminated.

This module exports a single cmdlet, Start-ThreadJob, which works similarly to the existing Start-Job cmdlet.
The main difference is that the jobs which are created run in separate threads within the local process.

One difference is that ThreadJob jobs support a ThrottleLimit parameter to limit the number of running jobs,
and thus active threads, at a time.  If more jobs are started then they go into a queue and wait until the current
number of jobs drops below the throttle limit.
"

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.1'

# Cmdlets to export from this module
CmdletsToExport = 'Start-ThreadJob'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = 'https://github.com/Powershell/ThreadJob/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/Powershell/ThreadJob'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()
    } # End of PSData hashtable

} # End of PrivateData hashtable

}
