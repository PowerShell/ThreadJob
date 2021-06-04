---
external help file: Microsoft.PowerShell.ThreadJob.dll-Help.xml
Module Name: Microsoft.PowerShell.ThreadJob
online version:
schema: 2.0.0
---

# Start-ThreadJob

## SYNOPSIS
Starts a PowerShell job in a separate thread

## SYNTAX

### ScriptBlock
```
Start-ThreadJob [-ScriptBlock] <ScriptBlock> [-Name <String>] [-InitializationScript <ScriptBlock>]
 [-InputObject <PSObject>] [-ArgumentList <Object[]>] [-ThrottleLimit <Int32>] [-StreamingHost <PSHost>]
 [<CommonParameters>]
```

### FilePath
```
Start-ThreadJob [-FilePath] <String> [-Name <String>] [-InitializationScript <ScriptBlock>]
 [-InputObject <PSObject>] [-ArgumentList <Object[]>] [-ThrottleLimit <Int32>] [-StreamingHost <PSHost>]
 [<CommonParameters>]
```

## DESCRIPTION
This command starts a PowerShell job running in a separate thread.
It is similar to the 'Start-Job' command, except that it runs the job in a different thread
instead of a child process. Consequently, it uses fewer resources for each job.

## EXAMPLES

### Example 1
```powershell
PS C:\> $job = Start-ThreadJob -ScriptBlock { 1..5 | foreach { "Output: $_"; sleep 1 }}
PS C:\> $job

Id     Name            PSJobTypeName   State         HasMoreData     Location             Command
--     ----            -------------   -----         -----------     --------             -------
1      Job1            ThreadJob       Running       False           PowerShell            1..5 | foreach {

$job | Wait-Job | Receive-Job
Output: 1
Output: 2
Output: 3
Output: 4
Output: 5

PS C:\> $job

Id     Name            PSJobTypeName   State         HasMoreData     Location             Command
--     ----            -------------   -----         -----------     --------             -------
1      Job1            ThreadJob       Completed     False           PowerShell            1..5 | foreach {
```

This example starts a simple job script running in a separate thread. It then uses the 'Wait-Job'
and 'Receive-Job' commands to wait for the job to complete and then return output.

### Example 2
```powershell
PS C:\> $jobs = 1..5 | foreach { Start-ThreadJob -ScriptBlock { 1..10 | foreach { sleep 1; "Job Done" } } -ThrottleLimit 3 }
PS C:\> $jobs

Id     Name            PSJobTypeName   State         HasMoreData     Location             Command
--     ----            -------------   -----         -----------     --------             -------
1      Job19           ThreadJob       Running       True            PowerShell            1..10 | foreach { sleep…
2      Job20           ThreadJob       Running       True            PowerShell            1..10 | foreach { sleep…
3      Job21           ThreadJob       Running       True            PowerShell            1..10 | foreach { sleep…
4      Job22           ThreadJob       NotStarted    False           PowerShell            1..10 | foreach { sleep…
5      Job23           ThreadJob       NotStarted    False           PowerShell            1..10 | foreach { sleep…
```

This example runs 'Start-ThreadJob' five times to start five job instances, but with a throttle
limit value of 3. Consequently, only three of the five jobs are initially running and the other two
are not started but queued to run after one or more of the currently running jobs complete.

## PARAMETERS

### -ArgumentList
Provides an optional list of arguments to be used in the job script.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilePath
Specifies an optional filepath to script for the job to run.

```yaml
Type: String
Parameter Sets: FilePath
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InitializationScript
Optional script block for script to be run before the job script or file is run.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Optional pipeline input to be processed in the running job.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
Optional of the job created to run the script.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptBlock
Script block that is run in the thread job.

```yaml
Type: ScriptBlock
Parameter Sets: ScriptBlock
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StreamingHost
Optional host object to which job output can directed.

```yaml
Type: PSHost
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThrottleLimit
Optional value that determines the maximum number of thread jobs that can run at one time.
If jobs are created that exceed this value, then those jobs are save in a queue until one
or more running jobs complete, after which a new job will be started running.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

## OUTPUTS

### Microsoft.PowerShell.ThreadJob.ThreadJob

## NOTES

## RELATED LINKS
