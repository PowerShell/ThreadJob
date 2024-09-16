Write-Warning -Message "The ThreadJob has been renamed to Microsoft.PowerShell.ThreadJob. ThreadJob module will no longer be included with PowerShell as of 7.x"

Set-Alias -Name Start-ThreadJob -Value Microsoft.PowerShell.ThreadJob\Start-ThreadJob
Set-Alias -Name ThreadJob\Start-ThreadJob -Value Microsoft.PowerShell.ThreadJob\Start-ThreadJob

Export-ModuleMember -Alias Start-ThreadJob, ThreadJob\Start-ThreadJob