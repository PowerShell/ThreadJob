# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

<#
.DESCRIPTION
Implement build and packaging of the package and place the output $OutDirectory/$ModuleName
#>
function DoBuild
{
    Write-Verbose -Verbose -Message "Starting DoBuild with configuration: $BuildConfiguration, framework: $BuildFramework"

    # Module build out path
    $BuildOutPath = "${OutDirectory}/${ModuleName}"
    Write-Verbose -Verbose -Message "Module output file path: '$BuildOutPath'"

    # Proxy module out path
    $ProxyOutPath = "${OutDirectory}/${ProxyModuleName}"
    Write-Verbose -Verbose -Message "Module output file path: '$ProxyOutPath'"

    # Module build source path
    $BuildSrcPath = "bin/${BuildConfiguration}/${BuildFramework}/publish"
    Write-Verbose -Verbose -Message "Module build source path: '$BuildSrcPath'"

    # Copy psd1 file
    Write-Verbose -Verbose "Copy-Item ${SrcPath}/${ModuleName}.psd1 to $BuildOutPath"
    Copy-Item "${SrcPath}/${ModuleName}.psd1" "$BuildOutPath"

    # Copy Proxy psd1 and psm1 file
    Write-Verbose -Verbose -Message "Copying proxy module files to '$ProxyOutPath'"
    Copy-Item "${SrcPath}/${ProxyModuleName}/${ProxyModuleName}.psd1" "$ProxyOutPath"
    Copy-Item "${SrcPath}/${ProxyModuleName}/${ProxyModuleName}.psm1" "$ProxyOutPath"

    # Copy help
    Write-Verbose -Verbose -Message "Copying help files to '$BuildOutPath'"
    copy-item -Recurse "${HelpPath}/${Culture}" "$BuildOutPath"

    # Copy license
    Write-Verbose -Verbose -Message "Copying LICENSE file to '$BuildOutPath'"
    Copy-Item -Path "./LICENSE" -Dest "$BuildOutPath"

    # Copy notice
    Write-Verbose -Verbose -Message "Copying ThirdPartyNotices.txt to '$BuildOutPath'"
    Copy-Item -Path "./ThirdPartyNotices.txt" -Dest "$BuildOutPath"

    if ( Test-Path "${SrcPath}/code" ) {
        Write-Verbose -Verbose -Message "Building assembly and copying to '$BuildOutPath'"
        # build code and place it in the staging location
        Push-Location "${SrcPath}/code"
        try {
            # Get dotnet.exe command path.
            $dotnetCommand = Get-Command -Name 'dotnet' -ErrorAction Ignore

            # Check for dotnet for Windows (we only build on Windows platforms).
            if ($null -eq $dotnetCommand) {
                if ($IsWindows) {
                    Write-Verbose -Verbose -Message "dotnet.exe cannot be found in current path. Looking in ProgramFiles path."
                    $dotnetCommandPath = Join-Path -Path $env:ProgramFiles -ChildPath "dotnet\dotnet.exe"
                } elseif ($IsLinux) {
                    Write-Verbose -Verbose -Message "dotnet cannot be found in current path. Looking in /usr/share/dotnet path."
                    $dotnetCommandPath = "/usr/share/dotnet/dotnet"
                } elseif ($IsMaxOS) {
                    Write-Verbose -Verbose -Message "dotnet cannot be found in current path. Looking in /usr/local/share/dotnet path."
                    $dotnetCommandPath = "/usr/local/share/dotnet/dotnet"
                } else {
                    throw "Unsupported operating system."
                }

                $dotnetCommand = Get-Command -Name $dotnetCommandPath -ErrorAction Ignore
                if ($null -eq $dotnetCommand) {
                    throw "Dotnet.exe cannot be found: $dotnetCommandPath is unavailable for build."
                }
            }

            Write-Verbose -Verbose -Message "dotnet.exe command found in path: $($dotnetCommand.Path)"

            # Check dotnet version
            Write-Verbose -Verbose -Message "DotNet version: $(& ($dotnetCommand) --version)"

            # Build source
            Write-Verbose -Verbose -Message "Building location: PSScriptRoot: $PSScriptRoot, PWD: $pwd"
            $buildCommand = "$($dotnetCommand.Name) publish --configuration $BuildConfiguration --framework $BuildFramework --output $BuildSrcPath"
            Write-Verbose -Verbose -Message "Starting dotnet build command: $buildCommand"
            # Capture the output and error streams
            $output = Invoke-Expression -Command $buildCommand 2>&1
            Write-Verbose -Verbose -Message "Build output: $output"

            #Dump build source output directory
            $outResultsPath = (Resolve-Path -Path ".").ProviderPath
            Write-Verbose -Verbose -Message "Dumping expected results output path: $outResultsPath"
            $outResults = Get-ChildItem -Path $outResultsPath -Recurse | Out-String
            Write-Verbose -Verbose -Message $outResults

            # Place build results
            if (! (Test-Path -Path "$BuildSrcPath/${ModuleName}.dll"))
            {
                # throw "Expected binary was not created: $BuildSrcPath/${ModuleName}.dll"
            }

            Write-Verbose -Verbose -Message "Copying implementation assembly $BuildSrcPath/${ModuleName}.dll to $BuildOutPath"
            Copy-Item "$BuildSrcPath/${ModuleName}.dll" -Dest "$BuildOutPath"
            
            if ((Test-Path -Path "$BuildSrcPath/${ModuleName}.pdb") -and ($script:BuildConfiguration -ne 'Release'))
            {
                Write-Verbose -Verbose -Message "Copying implementation pdb $BuildSrcPath/${ModuleName}.pdb to $BuildOutPath"
                Copy-Item -Path "$BuildSrcPath/${ModuleName}.pdb" -Dest "$BuildOutPath"
            }
        }
        catch {
            Write-Verbose -Verbose -Message "dotnet build failed with error: $_"
            Write-Error "dotnet build failed with error: $_"
        }
        finally {
            Pop-Location
        }
    }
    else {
        Write-Verbose -Verbose -Message "No code to build in '${SrcPath}/code'"
    }

    ## Add build and packaging here
    Write-Verbose -Verbose -Message "Ending DoBuild"
}
