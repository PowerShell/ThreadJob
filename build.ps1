# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
param (
    [Parameter(ParameterSetName="build")]
    [switch]
    $Clean,

    [Parameter(ParameterSetName="build")]
    [switch]
    $Build,

    [Parameter(ParameterSetName="publish")]
    [switch]
    $Publish,

    [ValidateSet("Debug", "Release")]
    [string] $BuildConfiguration = "Debug",

    [ValidateSet("netstandard2.0")]
    [string] $BuildFramework = "netstandard2.0"
)

Import-Module -Name "$PSScriptRoot/buildtools.psd1" -Force

$config = Get-BuildConfiguration -ConfigPath $PSScriptRoot

$script:ModuleName = $config.ModuleName
$script:ProxyModuleName = $config.ProxyModuleName
$script:SrcPath = $config.SourcePath
$script:OutDirectory = $config.BuildOutputPath
$script:TestPath = $config.TestPath

$script:ModuleRoot = $PSScriptRoot
$script:Culture = $config.Culture
$script:HelpPath = $config.HelpPath

$script:BuildConfiguration = $BuildConfiguration
$script:BuildFramework = $BuildFramework

if ($env:TF_BUILD) {
    $vstsCommandString = "vso[task.setvariable variable=BUILD_OUTPUT_PATH]$OutDirectory"
    Write-Host ("sending " + $vstsCommandString)
    Write-Host "##$vstsCommandString"
}

. $PSScriptRoot/doBuild.ps1

if ($Clean -and (Test-Path $OutDirectory))
{
    Remove-Item -Path $OutDirectory -Force -Recurse -ErrorAction Stop -Verbose

    if (Test-Path "${SrcPath}/code/bin")
    {
        Remove-Item -Path "${SrcPath}/code/bin" -Recurse -Force -ErrorAction Stop -Verbose
    }

    if (Test-Path "${SrcPath}/code/obj")
    {
        Remove-Item -Path "${SrcPath}/code/obj" -Recurse -Force -ErrorAction Stop -Verbose
    }
}

if (-not (Test-Path $OutDirectory))
{
    $script:OutModule = New-Item -ItemType Directory -Path (Join-Path $OutDirectory $ModuleName)
    $script:ProxyOutModule = New-Item -itemType Directory -Path (Join-Path $OutDirectory $ProxyModuleName)
}
else
{
    $script:OutModule = Join-Path $OutDirectory $ModuleName
}

if ($Build.IsPresent)
{
    $sb = (Get-Item Function:DoBuild).ScriptBlock
    Invoke-ModuleBuild -BuildScript $sb
}

if ($Publish.IsPresent)
{
    Publish-ModulePackage
}

