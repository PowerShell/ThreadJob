# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

$ConfigurationFileName = 'package.config.json'
Import-Module -Name Microsoft.PowerShell.PSResourceGet -Force

function Get-BuildConfiguration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $ConfigPath = '.'
    )

    $resolvedPath = Resolve-Path $ConfigPath

    if (Test-Path $resolvedPath -PathType Container) {
        $fileNamePath = Join-Path -Path $resolvedPath -ChildPath $ConfigurationFileName
    }
    else {
        $fileName = Split-Path -Path $resolvedPath -Leaf
        if ($fileName -ne $ConfigurationFileName) {
            throw "$ConfigurationFileName not found in provided pathname: $resolvedPath"
        }
        $fileNamePath = $resolvedPath
    }

    if (! (Test-Path -Path $fileNamePath -PathType Leaf)) {
        throw "$ConfigurationFileName not found at path: $resolvedPath"
    }

    $configObj = Get-Content -Path $fileNamePath | ConvertFrom-Json

    # Expand config paths to full paths
    $projectRoot = Split-Path $fileNamePath
    $configObj.SourcePath = Join-Path $projectRoot -ChildPath $configObj.SourcePath
    $configObj.TestPath = Join-Path $projectRoot -ChildPath $configObj.TestPath
    $configObj.HelpPath = Join-Path $projectRoot -ChildPath $configObj.HelpPath
    $configObj.BuildOutputPath = Join-Path $projectRoot -ChildPath $configObj.BuildOutputPath

    return $configObj
}

function Invoke-ModuleBuild {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ScriptBlock] $BuildScript
    )

    Write-Verbose -Verbose -Message "Invoking build script"

    $BuildScript.Invoke()

    Write-Verbose -Verbose -Message "Finished invoking build script"
}

function Publish-ModulePackage
{
    Write-Verbose -Verbose -Message "Creating new local package repo"
    $config = Get-BuildConfiguration
    $localRepoName = 'packagebuild-local-repo'
    $localRepoLocation = $config.BuildOutputPath

    Write-Verbose -Verbose -Message "Registering local package repo: $localRepoName"
    Register-PSResourceRepository -Name $localRepoName -Uri $localRepoLocation -Trusted -Force

    Write-Verbose -Verbose -Message "Publishing package to local repo: $localRepoName"
    $modulePath = Join-Path -Path $config.BuildOutputPath -ChildPath $config.ModuleName

    # Proxy module
    Write-Verbose -Verbose -Message "Publishing proxy module to local repo: $localRepoName"
    $proxyModulePath = Join-Path -Path $config.BuildOutputPath -ChildPath $config.ProxyModuleName
    Publish-PSResource -Path $proxyModulePath -Repository $localRepoName -SkipDependenciesCheck -Confirm:$false -Verbose

    # Official module
    Write-Verbose -Verbose -Message "Publishing official module to local repo: $localRepoName"
    Publish-PSResource -Path $modulePath -Repository $localRepoName -SkipDependenciesCheck -Confirm:$false -Verbose

    $artifactPath = (Get-ChildItem -Path $localRepoLocation -Filter "$($config.ModuleName)*.nupkg").FullName
    $artifactPath = Resolve-Path -Path $artifactPath
    Write-Verbose -Verbose -Message "ArtifactPath: $artifactPath"

    Write-Verbose -Verbose -Message "Unregistering local package repo: $localRepoName"
    Unregister-PSResourceRepository -Name $localRepoName -Confirm:$false
}

function Install-ModulePackageForTest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $PackagePath
    )

    $config = Get-BuildConfiguration

    $localRepoName = 'packagebuild-local-repo'
    Write-Verbose -Verbose -Message "Registering local package repo: $localRepoName to path: $PackagePath"
    Register-PSResourceRepository -Name $localRepoName -Uri $PackagePath -Trusted -Force

    $installationPath = $config.BuildOutputPath
    if ( !(Test-Path $installationPath)) {
        Write-Verbose -Verbose -Message "Creating module directory location for tests: $installationPath"
        $null = New-Item -Path $installationPath -ItemType Directory -Verbose
    }
    Write-Verbose -Verbose -Message "Installing module $($config.ModuleName) to build output path $installationPath"
    Save-PSResource -Name $config.ModuleName -Repository $localRepoName -Path $installationPath -SkipDependencyCheck -Prerelease -Confirm:$false

    Write-Verbose -Verbose -Message "Unregistering local package repo: $localRepoName"
    Unregister-PSResourceRepository -Name $localRepoName -Confirm:$false
}

function Invoke-ModuleTests {
    [CmdletBinding()]
    param (
       [ValidateSet("Functional", "StaticAnalysis")]
       [string[]] $Type = "Functional"
    )

    Write-Verbose -Verbose -Message "Starting module Pester tests..."

    # Run module Pester tests.
    $config = Get-BuildConfiguration
    $tags = 'CI'
    $testResultFileName = 'result.pester.xml'
    $testPath = $config.TestPath
    $moduleToTest = Join-Path -Path $config.BuildOutputPath -ChildPath $config.ModuleName
    $command = "Import-Module -Name ${moduleToTest} -Force -Verbose; Set-Location -Path ${testPath}; Invoke-Pester -Path . -OutputFile ${testResultFileName} -Tags '${tags}'"
    $pwshExePath = (Get-Process -Id $pid).Path
    try {
        $output = & $pwshExePath -NoProfile -NoLogo -Command $command
    }
    catch {
        Write-Error -Message "Error invoking module Pester tests."
    }
    $output | Foreach-Object { Write-Warning -Message "$_" }
    $testResultsFilePath = Join-Path -Path $testPath -ChildPath $testResultFileName

    # Examine Pester test results.
    if (! (Test-Path -Path $testResultsFilePath)) {
        throw "Module test result file not found: '$testResultsFilePath'"
    }
    $xmlDoc = [xml] (Get-Content -Path $testResultsFilePath -Raw)
    if ([int] ($xmlDoc.'test-results'.failures) -gt 0) {
        $failures = [System.Xml.XmlDocumentXPathExtensions]::SelectNodes($xmlDoc."test-results", './/test-case[@result = "Failure"]')
    }
    else {
        $failures = $xmlDoc.SelectNodes('.//test-case[@result = "Failure"]')
    }
    foreach ($testfailure in $failures) {
        Show-PSPesterError -TestFailure $testfailure
    }

    # Publish test results to AzDevOps
    if ($env:TF_BUILD) {
        Write-Verbose -Verbose -Message "Uploading test results to AzDevOps"
        $powerShellName = if ($PSVersionTable.PSEdition -eq 'Core') { 'PowerShell Core' } else { 'Windows PowerShell' }
        $TestType = 'NUnit'
        $Title = "Functional Tests -  $env:AGENT_OS - $powershellName Results"
        $ArtifactPath = (Resolve-Path -Path $testResultsFilePath).ProviderPath
        $FailTaskOnFailedTests = 'true'
        $message = "vso[results.publish type=$TestType;mergeResults=true;runTitle=$Title;publishRunAttachments=true;resultFiles=$ArtifactPath;failTaskOnFailedTests=$FailTaskOnFailedTests;]"
        Write-Host "##$message"
    }

    Write-Verbose -Verbose -Message "Module Pester tests complete."
}

function Show-PSPesterError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Xml.XmlElement]$testFailure
    )

    $description = $testFailure.description
    $name = $testFailure.name
    $message = $testFailure.failure.message
    $stackTrace = $testFailure.failure."stack-trace"

    $fullMsg = "`n{0}`n{1}`n{2}`n{3}`{4}" -f ("Description: " + $description), ("Name:        " + $name), "message:", $message, "stack-trace:", $stackTrace

    Write-Error $fullMsg
}
