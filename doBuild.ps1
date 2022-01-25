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

    # Module build source path
    $BuildSrcPath = "bin/${BuildConfiguration}/${BuildFramework}/publish"
    Write-Verbose -Verbose -Message "Module build source path: '$BuildSrcPath'"

    # Copy psd1 file
    Write-Verbose -Verbose "Copy-Item ${SrcPath}/${ModuleName}.psd1 to $BuildOutPath"
    Copy-Item "${SrcPath}/${ModuleName}.psd1" "$BuildOutPath"

    # Copy help
    Write-Verbose -Verbose -Message "Copying help files to '$BuildOutPath'"
    copy-item -Recurse "${HelpPath}/${Culture}" "$BuildOutPath"

    if ( Test-Path "${SrcPath}/code" ) {
        Write-Verbose -Verbose -Message "Building assembly and copying to '$BuildOutPath'"
        # build code and place it in the staging location
        Push-Location "${SrcPath}/code"
        try {
            # Check for dotnet for Windows (we only build on Windows platforms).
            if ($null -eq (Get-Command -Name 'dotnet.exe' -ErrorAction Ignore)) {
                Write-Verbose -Verbose -Message "dotnet.exe cannot be found in current path."
                $dotnetCommandPath = Join-Path -Path $env:ProgramFiles -ChildPath "dotnet"
                $dotnetCommand = Join-Path -Path $dotnetCommandPath -ChildPath "dotnet.exe"
                if ($null -eq (Get-Command -Name $dotnetCommand -ErrorAction Ignore)) {
                    throw "Dotnet.exe cannot be found: $dotnetCommand is unavailable for build."
                }

                Write-Verbose -Verbose -Message "Adding dotnet.exe path to PATH variable: $dotnetCommandPath"
                $env:PATH = $dotnetCommandPath + [IO.Path]::PathSeparator + $env:PATH
            }

            # Check dotnet version
            Write-Verbose -Verbose -Message "DotNet version: $(dotnet --version)"

            # Build source
            Write-Verbose -Verbose -Message "Building with configuration: $BuildConfiguration, framework: $BuildFramework"
            Write-Verbose -Verbose -Message "Building location: PSScriptRoot: $PSScriptRoot, PWD: $pwd"
            dotnet publish --configuration $BuildConfiguration --framework $BuildFramework --output $BuildSrcPath

            # Dump build source output directory
            # $outResults = Get-ChildItem -Path "bin/${BuildConfiguration}/${BuildFramework}" -Recurse | Out-String
            # Write-Verbose -Verbose -Message $outResults

            # Place build results
            if (! (Test-Path -Path "$BuildSrcPath/${ModuleName}.dll"))
            {
                throw "Expected binary was not created: $BuildSrcPath/${ModuleName}.dll"
            }

            Write-Verbose -Verbose -Message "Copying implementation assembly $BuildSrcPath/${ModuleName}.dll to $BuildOutPath"
            Copy-Item "$BuildSrcPath/${ModuleName}.dll" -Dest "$BuildOutPath"
            
            if (Test-Path -Path "$BuildSrcPath/${ModuleName}.pdb")
            {
                Write-Verbose -Verbose -Message "Copying implementation pdb $BuildSrcPath/${ModuleName}.pdb to $BuildOutPath"
                Copy-Item -Path "$BuildSrcPath/${ModuleName}.pdb" -Dest "$BuildOutPath"
            }
        }
        catch {
            # Write-Error "dotnet build failed with error: $_"
            Write-Verbose -Verbose -Message "dotnet build failed with error: $_"
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
