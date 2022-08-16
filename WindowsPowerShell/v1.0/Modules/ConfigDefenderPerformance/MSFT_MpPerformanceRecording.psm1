## Copyright (c) Microsoft Corporation. All rights reserved.

<#
.SYNOPSIS
This cmdlet collects a performance recording of Microsoft Defender Antivirus
scans.

.DESCRIPTION
This cmdlet collects a performance recording of Microsoft Defender Antivirus
scans. These performance recordings contain Microsoft-Antimalware-Engine
and NT kernel process events and can be analyzed after collection using the
Get-MpPerformanceReport cmdlet.

This cmdlet requires elevated administrator privileges.

The performance analyzer provides insight into problematic files that could
cause performance degradation of Microsoft Defender Antivirus. This tool is
provided "AS IS", and is not intended to provide suggestions on exclusions.
Exclusions can reduce the level of protection on your endpoints. Exclusions,
if any, should be defined with caution.

.EXAMPLE
New-MpPerformanceRecording -RecordTo:.\Defender-scans.etl

#>
function New-MpPerformanceRecording {
    [CmdletBinding(DefaultParameterSetName='Interactive')]
    param(

        # Specifies the location where to save the Microsoft Defender Antivirus
        # performance recording.
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$RecordTo,

        # Specifies the duration of the performance recording in seconds.
        [Parameter(Mandatory=$true, ParameterSetName='Timed')]
        [ValidateRange(0,2147483)]
        [int]$Seconds,

        # Specifies the PSSession object in which to create and save the Microsoft
        # Defender Antivirus performance recording. When you use this parameter,
        # the RecordTo parameter refers to the local path on the remote machine.
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session
    )

    [bool]$interactiveMode = ($PSCmdlet.ParameterSetName -eq 'Interactive')
    [bool]$timedMode = ($PSCmdlet.ParameterSetName -eq 'Timed')

    # Hosts
    [string]$powerShellHostConsole = 'ConsoleHost'
    [string]$powerShellHostISE = 'Windows PowerShell ISE Host'
    [string]$powerShellHostRemote = 'ServerRemoteHost'

    if ($interactiveMode -and ($Host.Name -notin @($powerShellHostConsole, $powerShellHostISE, $powerShellHostRemote))) {
        $ex = New-Object System.Management.Automation.ItemNotFoundException 'Cmdlet supported only on local PowerShell console, Windows PowerShell ISE and remote PowerShell console.'
        $category = [System.Management.Automation.ErrorCategory]::NotImplemented
        $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'NotImplemented',$category,$Host.Name
        $psCmdlet.WriteError($errRecord)
        return
    }

    if ($null -ne $Session) {
        [int]$RemotedSeconds = if ($timedMode) { $Seconds } else { -1 }

        Invoke-Command -Session:$session -ArgumentList:@($RecordTo, $RemotedSeconds) -ScriptBlock:{
            param(
                [Parameter(Mandatory=$true)]
                [ValidateNotNullOrEmpty()]
                [string]$RecordTo,

                [Parameter(Mandatory=$true)]
                [ValidateRange(-1,2147483)]
                [int]$RemotedSeconds
            )

            if ($RemotedSeconds -eq -1) {
                New-MpPerformanceRecording -RecordTo:$RecordTo
            } else {
                New-MpPerformanceRecording -RecordTo:$RecordTo -Seconds:$RemotedSeconds
            }
        }

        return
    }

    # Dependencies
    [string]$wprProfile = "$PSScriptRoot\MSFT_MpPerformanceRecording.wprp"
    [string]$wprCommand = 'wpr.exe'

    if (-not (Test-Path -LiteralPath:$RecordTo -IsValid)) {
        $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot record Microsoft Defender Antivirus performance recording to path '$RecordTo' because the location does not exist."
        $category = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'InvalidPath',$category,$RecordTo
        $psCmdlet.WriteError($errRecord)
        return
    }

    # Resolve any relative paths
    $RecordTo = $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RecordTo)

    #
    # Test dependency presence
    #

    if (-not (Test-Path -LiteralPath:$wprProfile -PathType:Leaf)) {
        $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find dependency file '$wprProfile' because it does not exist."
        $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
        $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$wprProfile
        $psCmdlet.WriteError($errRecord)
        return
    }

    if (-not (Get-Command $wprCommand -ErrorAction:SilentlyContinue)) {
        $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find dependency command '$wprCommand' because it does not exist."
        $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
        $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$wprCommand
        $psCmdlet.WriteError($errRecord)
        return
    }

    function CancelPerformanceRecording {
        Write-Host "`n`nCancelling Microsoft Defender Antivirus performance recording... " -NoNewline

        & $wprCommand -cancel -instancename MSFT_MpPerformanceRecording
        $wprCommandExitCode = $LASTEXITCODE

        switch ($wprCommandExitCode) {
            0 {}
            0xc5583000 {
                Write-Error "Cannot cancel performance recording because currently Windows Performance Recorder is not recording."
                return
            }
            default {
                Write-Error ("Cannot cancel performance recording: 0x{0:x08}." -f $wprCommandExitCode)
                return
            }
        }

        Write-Host "ok.`n`nRecording has been cancelled."
    }

    #
    # Ensure Ctrl-C doesn't abort the app without cleanup
    #

    # - local PowerShell consoles: use [Console]::TreatControlCAsInput; cleanup performed and output preserved
    # - PowerShell ISE: use try { ... } catch { throw } finally; cleanup performed and output preserved
    # - remote PowerShell: use try { ... } catch { throw } finally; cleanup performed but output truncated

    [bool]$canTreatControlCAsInput = $interactiveMode -and ($Host.Name -eq $powerShellHostConsole)
    $savedControlCAsInput = $null

    $shouldCancelRecordingOnTerminatingError = $false

    try
    {
        if ($canTreatControlCAsInput) {
            $savedControlCAsInput = [Console]::TreatControlCAsInput
            [Console]::TreatControlCAsInput = $true
        }

        #
        # Start recording
        #

        Write-Host "Starting Microsoft Defender Antivirus performance recording... " -NoNewline

        $shouldCancelRecordingOnTerminatingError = $true

        & $wprCommand -start "$wprProfile!Scans.Light" -filemode -instancename MSFT_MpPerformanceRecording
        $wprCommandExitCode = $LASTEXITCODE

        switch ($wprCommandExitCode) {
            0 {}
            0xc5583001 {
                $shouldCancelRecordingOnTerminatingError = $false
                Write-Error "Cannot start performance recording because Windows Performance Recorder is already recording."
                return
            }
            default {
                $shouldCancelRecordingOnTerminatingError = $false
                Write-Error ("Cannot start performance recording: 0x{0:x08}." -f $wprCommandExitCode)
                return
            }
        }

        Write-Host "ok.`n`nRecording has started." -NoNewline

        if ($timedMode) {
            Write-Host "`n`n   Recording for $Seconds seconds... " -NoNewline

            Start-Sleep -Seconds:$Seconds
            
            Write-Host "ok." -NoNewline
        } elseif ($interactiveMode) {
            $stopPrompt = "`n`n=> Reproduce the scenario that is impacting the performance on your device.`n`n   Press <ENTER> to stop and save recording or <Ctrl-C> to cancel recording"

            if ($canTreatControlCAsInput) {
                Write-Host "${stopPrompt}: "

                do {
                    $key = [Console]::ReadKey($true)
                    if (($key.Modifiers -eq [ConsoleModifiers]::Control) -and (($key.Key -eq [ConsoleKey]::C))) {

                        CancelPerformanceRecording

                        $shouldCancelRecordingOnTerminatingError = $false

                        #
                        # Restore Ctrl-C behavior
                        #

                        [Console]::TreatControlCAsInput = $savedControlCAsInput

                        return
                    }

                } while (($key.Modifiers -band ([ConsoleModifiers]::Alt -bor [ConsoleModifiers]::Control -bor [ConsoleModifiers]::Shift)) -or ($key.Key -ne [ConsoleKey]::Enter))

            } else {
                Read-Host -Prompt:$stopPrompt
            }
        }

        #
        # Stop recording
        #

        Write-Host "`n`nStopping Microsoft Defender Antivirus performance recording... "

        & $wprCommand -stop $RecordTo -instancename MSFT_MpPerformanceRecording
        $wprCommandExitCode = $LASTEXITCODE

        switch ($wprCommandExitCode) {
            0 {
                $shouldCancelRecordingOnTerminatingError = $false
            }
            0xc5583000 {
                $shouldCancelRecordingOnTerminatingError = $false
                Write-Error "Cannot stop performance recording because Windows Performance Recorder is not recording a trace."
                return
            }
            default {
                Write-Error ("Cannot stop performance recording: 0x{0:x08}." -f $wprCommandExitCode)
                return
            }
        }

        Write-Host "ok.`n`nRecording has been saved to '$RecordTo'."

        Write-Host `
'
The performance analyzer provides insight into problematic files that could
cause performance degradation of Microsoft Defender Antivirus. This tool is
provided "AS IS", and is not intended to provide suggestions on exclusions.
Exclusions can reduce the level of protection on your endpoints. Exclusions,
if any, should be defined with caution.
'
Write-Host `
'
The trace you have just captured may contain personally identifiable information,
including but not necessarily limited to paths to files accessed, paths to
registry accessed and process names. Exact information depends on the events that
were logged. Please be aware of this when sharing this trace with other people.
'
    } catch {
        throw
    } finally {
        if ($shouldCancelRecordingOnTerminatingError) {
            CancelPerformanceRecording
        }

        if ($null -ne $savedControlCAsInput) {
            #
            # Restore Ctrl-C behavior
            #

            [Console]::TreatControlCAsInput = $savedControlCAsInput
        }
    }
}

function ParseFriendlyDuration
{
    [OutputType([TimeSpan])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $FriendlyDuration
    )

    if ($FriendlyDuration -match '^(\d+)(?:\.(\d+))?(sec|ms|us)$')
    {
        [string]$seconds = $Matches[1]
        [string]$decimals = $Matches[2]
        [string]$unit = $Matches[3]

        [uint32]$magnitude =
            switch ($unit)
            {
                'sec' {7}
                'ms' {4}
                'us' {1}
            }

        if ($decimals.Length -gt $magnitude)
        {
            throw [System.ArgumentException]::new("String '$FriendlyDuration' was not recognized as a valid Duration: $($decimals.Length) decimals specified for time unit '$unit'; at most $magnitude expected.")
        }

        return [timespan]::FromTicks([int64]::Parse($seconds + $decimals.PadRight($magnitude, '0')))
    }

    [timespan]$result = [timespan]::FromTicks(0)
    if ([timespan]::TryParse($FriendlyDuration, [ref]$result))
    {
        return $result
    }

    throw [System.ArgumentException]::new("String '$FriendlyDuration' was not recognized as a valid Duration; expected a value like '0.1234567sec' or '0.1234ms' or '0.1us' or a valid TimeSpan.")
}

[scriptblock]$FriendlyTimeSpanToString = { '{0:0.0000}ms' -f ($this.Ticks / 10000.0) }

function New-FriendlyTimeSpan
{
    param(
        [Parameter(Mandatory = $true)]
        [uint64]$Ticks,

        [bool]$Raw = $false
    )

    if ($Raw) {
        return $Ticks
    }

    $result = [TimeSpan]::FromTicks($Ticks)
    $result.PsTypeNames.Insert(0, 'MpPerformanceReport.TimeSpan')
    $result | Add-Member -Force -MemberType:ScriptMethod -Name:'ToString' -Value:$FriendlyTimeSpanToString
    $result
}

function New-FriendlyDateTime
{
    param(
        [Parameter(Mandatory = $true)]
        [uint64]$FileTime,

        [bool]$Raw = $false
    )

    if ($Raw) {
        return $FileTime
    }

    [DateTime]::FromFileTime($FileTime)
}

function Add-DefenderCollectionType
{
    param(
        [Parameter(Mandatory = $true)]
        [ref]$CollectionRef
    )

    if ($CollectionRef.Value | Get-Member -Name:'Processes','Files','Extensions','Scans')
    {
        $CollectionRef.Value.PSTypeNames.Insert(0, 'MpPerformanceReport.NestedCollection')
    }
}

filter ConvertTo-DefenderScanInfo
{
    param(
        [bool]$Raw = $false
    )

    $result = [PSCustomObject]@{
        ScanType = [string]$_.ScanType
        StartTime = New-FriendlyDateTime -FileTime:$_.StartTime -Raw:$Raw
        EndTime = New-FriendlyDateTime -FileTime:$_.EndTime -Raw:$Raw
        Duration = New-FriendlyTimeSpan -Ticks:$_.Duration -Raw:$Raw
        Reason = [string]$_.Reason
        Path = [string]$_.Path
        ProcessPath = [string]$_.ProcessPath
        ProcessId = if ($_.ProcessId -gt 0) { [int]$_.ProcessId } else { $null }
    }

    if (-not $Raw) {
        $result.PSTypeNames.Insert(0, 'MpPerformanceReport.ScanInfo')
    }

    $result
}

filter ConvertTo-DefenderScanStats
{
    param(
        [bool]$Raw = $false
    )

    $result = [PSCustomObject]@{
        Count = $_.Count
        TotalDuration = New-FriendlyTimeSpan -Ticks:$_.TotalDuration -Raw:$Raw
        MinDuration = New-FriendlyTimeSpan -Ticks:$_.MinDuration -Raw:$Raw
        AverageDuration = New-FriendlyTimeSpan -Ticks:$_.AverageDuration -Raw:$Raw
        MaxDuration = New-FriendlyTimeSpan -Ticks:$_.MaxDuration -Raw:$Raw
        MedianDuration = New-FriendlyTimeSpan -Ticks:$_.MedianDuration -Raw:$Raw
    }

    if (-not $Raw) {
        $result.PSTypeNames.Insert(0, 'MpPerformanceReport.ScanStats')
    }

    $result
}

filter ConvertTo-DefenderScannedFilePathStats
{
    param(
        [bool]$Raw = $false
    )

    $result = $_ | ConvertTo-DefenderScanStats -Raw:$Raw

    if (-not $Raw) {
        $result.PSTypeNames.Insert(0, 'MpPerformanceReport.ScannedFilePathStats')
    }

    $result | Add-Member -NotePropertyName:'Path' -NotePropertyValue:($_.Path)

    if ($null -ne $_.Scans)
    {
        $result | Add-Member -NotePropertyName:'Scans' -NotePropertyValue:@(
            $_.Scans | ConvertTo-DefenderScanInfo -Raw:$Raw
        )

        if (-not $Raw) {
            Add-DefenderCollectionType -CollectionRef:([ref]$result.Scans)
        }
    }

    if ($null -ne $_.Processes)
    {
        $result | Add-Member -NotePropertyName:'Processes' -NotePropertyValue:@(
            $_.Processes | ConvertTo-DefenderScannedProcessStats -Raw:$Raw
        )

        if (-not $Raw) {
            Add-DefenderCollectionType -CollectionRef:([ref]$result.Processes)
        }
    }

    $result
}

filter ConvertTo-DefenderScannedFileExtensionStats
{
    param(
        [bool]$Raw = $false
    )

    $result = $_ | ConvertTo-DefenderScanStats -Raw:$Raw

    if (-not $Raw) {
        $result.PSTypeNames.Insert(0, 'MpPerformanceReport.ScannedFileExtensionStats')
    }

    $result | Add-Member -NotePropertyName:'Extension' -NotePropertyValue:($_.Extension)

    if ($null -ne $_.Scans)
    {
        $result | Add-Member -NotePropertyName:'Scans' -NotePropertyValue:@(
            $_.Scans | ConvertTo-DefenderScanInfo -Raw:$Raw
        )

        if (-not $Raw) {
            Add-DefenderCollectionType -CollectionRef:([ref]$result.Scans)
        }
    }

    if ($null -ne $_.Files)
    {
        $result | Add-Member -NotePropertyName:'Files' -NotePropertyValue:@(
            $_.Files | ConvertTo-DefenderScannedFilePathStats -Raw:$Raw
        )

        if (-not $Raw) {
            Add-DefenderCollectionType -CollectionRef:([ref]$result.Files)
        }
    }

    if ($null -ne $_.Processes)
    {
        $result | Add-Member -NotePropertyName:'Processes' -NotePropertyValue:@(
            $_.Processes | ConvertTo-DefenderScannedProcessStats -Raw:$Raw
        )

        if (-not $Raw) {
            Add-DefenderCollectionType -CollectionRef:([ref]$result.Processes)
        }
    }

    $result
}

filter ConvertTo-DefenderScannedProcessStats
{
    param(
        [bool]$Raw
    )

    $result = $_ | ConvertTo-DefenderScanStats -Raw:$Raw

    if (-not $Raw) {
        $result.PSTypeNames.Insert(0, 'MpPerformanceReport.ScannedProcessStats')
    }

    $result | Add-Member -NotePropertyName:'ProcessPath' -NotePropertyValue:($_.Process)

    if ($null -ne $_.Scans)
    {
        $result | Add-Member -NotePropertyName:'Scans' -NotePropertyValue:@(
            $_.Scans | ConvertTo-DefenderScanInfo -Raw:$Raw
        )

        if (-not $Raw) {
            Add-DefenderCollectionType -CollectionRef:([ref]$result.Scans)
        }
    }

    if ($null -ne $_.Files)
    {
        $result | Add-Member -NotePropertyName:'Files' -NotePropertyValue:@(
            $_.Files | ConvertTo-DefenderScannedFilePathStats -Raw:$Raw
        )

        if (-not $Raw) {
            Add-DefenderCollectionType -CollectionRef:([ref]$result.Files)
        }
    }

    if ($null -ne $_.Extensions)
    {
        $result | Add-Member -NotePropertyName:'Extensions' -NotePropertyValue:@(
            $_.Extensions | ConvertTo-DefenderScannedFileExtensionStats -Raw:$Raw
        )

        if (-not $Raw) {
            Add-DefenderCollectionType -CollectionRef:([ref]$result.Extensions)
        }
    }

    $result
}

<#
.SYNOPSIS
This cmdlet reports the file paths, file extensions, and processes that cause
the highest impact to Microsoft Defender Antivirus scans.

.DESCRIPTION
This cmdlet analyzes a previously collected Microsoft Defender Antivirus
performance recording and reports the file paths, file extensions and processes
that cause the highest impact to Microsoft Defender Antivirus scans.

The performance analyzer provides insight into problematic files that could
cause performance degradation of Microsoft Defender Antivirus. This tool is
provided "AS IS", and is not intended to provide suggestions on exclusions.
Exclusions can reduce the level of protection on your endpoints. Exclusions,
if any, should be defined with caution.

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopFiles:10 -TopExtensions:10 -TopProcesses:10 -TopScans:10

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopFiles:10 -TopExtensions:10 -TopProcesses:10 -TopScans:10 -Raw | ConvertTo-Json

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopScans:10

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopFiles:10

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopFiles:10 -TopScansPerFile:3

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopFiles:10 -TopProcessesPerFile:3

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopFiles:10 -TopProcessesPerFile:3 -TopScansPerProcessPerFile:3

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopExtensions:10

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopExtensions:10 -TopScansPerExtension:3

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopExtensions:10 -TopFilesPerExtension:3

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopExtensions:10 -TopFilesPerExtension:3 -TopScansPerFilePerExtension:3

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopExtensions:10 -TopProcessesPerExtension:3

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopExtensions:10 -TopProcessesPerExtension:3 -TopScansPerProcessPerExtension:3

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopProcesses:10

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopProcesses:10 -TopScansPerProcess:3

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopProcesses:10 -TopExtensionsPerProcess:3

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopProcesses:10 -TopExtensionsPerProcess:3 -TopScansPerExtensionPerProcess:3

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopProcesses:10 -TopFilesPerProcess:3

.EXAMPLE
Get-MpPerformanceReport -Path:.\Defender-scans.etl -TopProcesses:10 -TopFilesPerProcess:3 -TopScansPerFilePerProcess:3

#>

function Get-MpPerformanceReport {
    [CmdletBinding()]
    param(
        # Specifies the location of Microsoft Defender Antivirus performance recording to analyze.
        [Parameter(Mandatory=$true,
                Position=0,
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true,
                HelpMessage="Location of Microsoft Defender Antivirus performance recording.")]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        # Requests a top files report and specifies how many top files to output, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopFiles = 0,

        # Specifies how many top scans to output for each top file, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopScansPerFile = 0,

        # Specifies how many top processes to output for each top file, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopProcessesPerFile = 0,

        # Specifies how many top scans for output for each top process for each top file, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopScansPerProcessPerFile = 0,


        # Requests a top extensions report and specifies how many top extensions to output, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopExtensions = 0,

        # Specifies how many top scans to output for each top extension, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopScansPerExtension = 0,

        # Specifies how many top files to output for each top extension, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopFilesPerExtension = 0,

        # Specifies how many top scans for output for each top file for each top extension, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopScansPerFilePerExtension = 0,

        # Specifies how many top processes to output for each top extension, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopProcessesPerExtension = 0,

        # Specifies how many top scans for output for each top process for each top extension, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopScansPerProcessPerExtension = 0,


        # Requests a top processes report and specifies how many top processes to output, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopProcesses = 0,

        # Specifies how many top scans to output for each top process in the Top Processes report, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopScansPerProcess = 0,

        # Specifies how many top files to output for each top process, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopFilesPerProcess = 0,

        # Specifies how many top scans for output for each top file for each top process, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopScansPerFilePerProcess = 0,

        # Specifies how many top extensions to output for each top process, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopExtensionsPerProcess = 0,

        # Specifies how many top scans for output for each top extension for each top process, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopScansPerExtensionPerProcess = 0,


        # Requests a top scans report and specifies how many top scans to output, sorted by "Duration".
        [ValidateRange(0,([int]::MaxValue))]
        [int]$TopScans = 0,

        ## TimeSpan format: d | h:m | h:m:s | d.h:m | h:m:.f | h:m:s.f | d.h:m:s | d.h:m:.f | d.h:m:s.f => d | (d.)?h:m(:s(.f)?)? | ((d.)?h:m:.f)

        # Specifies the minimum duration of any scans or total scan durations of files, extensions and processes included in the report.
        # Accepts values like  '0.1234567sec' or '0.1234ms' or '0.1us' or a valid TimeSpan.
        [ValidatePattern('^(?:(?:(\d+)(?:\.(\d+))?(sec|ms|us))|(?:\d+)|(?:(\d+\.)?\d+:\d+(?::\d+(?:\.\d+)?)?)|(?:(\d+\.)?\d+:\d+:\.\d+))$')]
        [string]$MinDuration = '0us',

        # Specifies that the output should be machine readable and readily convertible to serialization formats like JSON.
        # - Collections and elements are not be formatted.
        # - TimeSpan values are represented as number of 100-nanosecond intervals.
        # - DateTime values are represented as number of 100-nanosecond intervals since January 1, 1601 (UTC).
        [switch]$Raw
    )

    #
    # Validate performance recording presence
    #

    if (-not (Test-Path -Path:$Path -PathType:Leaf)) {
        $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$Path'."
        $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
        $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$Path
        $psCmdlet.WriteError($errRecord)
        return
    }

    function ParameterValidationError {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [string]
            $ParameterName,

            [Parameter(Mandatory)]
            [string]
            $ParentParameterName
        )

        $ex = New-Object System.Management.Automation.ValidationMetadataException "Parameter '$ParameterName' requires parameter '$ParentParameterName'."
        $category = [System.Management.Automation.ErrorCategory]::MetadataError
        $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'InvalidParameter',$category,$ParameterName
        $psCmdlet.WriteError($errRecord)
    }

    #
    # Additional parameter validation
    #

    if ($TopFiles -eq 0)
    {
        if ($TopScansPerFile -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopScansPerFile' -ParentParameterName:'TopFiles'
        }

        if ($TopProcessesPerFile -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopProcessesPerFile' -ParentParameterName:'TopFiles'
        }
    }

    if ($TopProcessesPerFile -eq 0)
    {
        if ($TopScansPerProcessPerFile -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopScansPerProcessPerFile' -ParentParameterName:'TopProcessesPerFile'
        }
    }

    if ($TopExtensions -eq 0)
    {
        if ($TopScansPerExtension -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopScansPerExtension' -ParentParameterName:'TopExtensions'
        }

        if ($TopFilesPerExtension -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopFilesPerExtension' -ParentParameterName:'TopExtensions'
        }

        if ($TopProcessesPerExtension -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopProcessesPerExtension' -ParentParameterName:'TopExtensions'
        }
    }

    if ($TopFilesPerExtension -eq 0)
    {
        if ($TopScansPerFilePerExtension -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopScansPerFilePerExtension' -ParentParameterName:'TopFilesPerExtension'
        }
    }

    if ($TopProcessesPerExtension -eq 0)
    {
        if ($TopScansPerProcessPerExtension -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopScansPerProcessPerExtension' -ParentParameterName:'TopProcessesPerExtension'
        }
    }

    if ($TopProcesses -eq 0)
    {
        if ($TopScansPerProcess -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopScansPerProcess' -ParentParameterName:'TopProcesses'
        }

        if ($TopFilesPerProcess -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopFilesPerProcess' -ParentParameterName:'TopProcesses'
        }

        if ($TopExtensionsPerProcess -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopExtensionsPerProcess' -ParentParameterName:'TopProcesses'
        }
    }

    if ($TopFilesPerProcess -eq 0)
    {
        if ($TopScansPerFilePerProcess -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopScansPerFilePerProcess' -ParentParameterName:'TopFilesPerProcess'
        }
    }

    if ($TopExtensionsPerProcess -eq 0)
    {
        if ($TopScansPerExtensionPerProcess -gt 0)
        {
            ParameterValidationError -ErrorAction:Stop -ParameterName:'TopScansPerExtensionPerProcess' -ParentParameterName:'TopExtensionsPerProcess'
        }
    }

    if (($TopFiles -eq 0) -and ($TopExtensions -eq 0) -and ($TopProcesses -eq 0) -and ($TopScans -eq 0)) {
        $ex = New-Object System.Management.Automation.ItemNotFoundException "At least one of the parameters 'TopFiles', 'TopExtensions', 'TopProcesses' or 'TopScans' must be present."
        $category = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'InvalidArgument',$category,$wprProfile
        $psCmdlet.WriteError($errRecord)
        return
    }

    # Dependencies
    [string]$PlatformPath = (Get-ItemProperty -Path:'HKLM:\Software\Microsoft\Windows Defender' -Name:'InstallLocation' -ErrorAction:Stop).InstallLocation

    #
    # Test dependency presence
    #

    [string]$mpCmdRunCommand = "${PlatformPath}MpCmdRun.exe"

    if (-not (Get-Command $mpCmdRunCommand -ErrorAction:SilentlyContinue)) {
        $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find '$mpCmdRunCommand'."
        $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
        $errRecord = New-Object System.Management.Automation.ErrorRecord $ex,'PathNotFound',$category,$mpCmdRunCommand
        $psCmdlet.WriteError($errRecord)
        return
    }

    # assemble report arguments

    [string[]]$reportArguments = @(
        $PSBoundParameters.GetEnumerator() |
            Where-Object { $_.Key.ToString().StartsWith("Top") -and ($_.Value -gt 0) } |
            ForEach-Object { "-$($_.Key)"; "$($_.Value)"; }
        )

    [timespan]$MinDurationTimeSpan = ParseFriendlyDuration -FriendlyDuration:$MinDuration

    if ($MinDurationTimeSpan -gt [TimeSpan]::FromTicks(0))
    {
        $reportArguments += @('-MinDuration', ($MinDurationTimeSpan.Ticks))
    }

    $report = & $mpCmdRunCommand -PerformanceReport -RecordingPath $Path @reportArguments | ConvertFrom-Json

    $result = [PSCustomObject]@{}

    if (-not $Raw) {
        $result.PSTypeNames.Insert(0, 'MpPerformanceReport.Result')
    }

    if ($TopFiles -gt 0)
    {
        $result | Add-Member -NotePropertyName:'TopFiles' -NotePropertyValue:@($report.TopFiles | ConvertTo-DefenderScannedFilePathStats -Raw:$Raw)

        if (-not $Raw) {
            Add-DefenderCollectionType -CollectionRef:([ref]$result.TopFiles)
        }
    }

    if ($TopExtensions -gt 0)
    {
        $result | Add-Member -NotePropertyName:'TopExtensions' -NotePropertyValue:@($report.TopExtensions | ConvertTo-DefenderScannedFileExtensionStats -Raw:$Raw)

        if (-not $Raw) {
            Add-DefenderCollectionType -CollectionRef:([ref]$result.TopExtensions)
        }
    }

    if ($TopProcesses -gt 0)
    {
        $result | Add-Member -NotePropertyName:'TopProcesses' -NotePropertyValue:@($report.TopProcesses | ConvertTo-DefenderScannedProcessStats -Raw:$Raw)

        if (-not $Raw) {
            Add-DefenderCollectionType -CollectionRef:([ref]$result.TopProcesses)
        }
    }

    if ($TopScans -gt 0)
    {
        $result | Add-Member -NotePropertyName:'TopScans' -NotePropertyValue:@($report.TopScans | ConvertTo-DefenderScanInfo -Raw:$Raw)

        if (-not $Raw) {
            Add-DefenderCollectionType -CollectionRef:([ref]$result.TopScans)
        }
    }

    $result
}

$exportModuleMemberParam = @{
    Function = @(
        'New-MpPerformanceRecording'
        'Get-MpPerformanceReport'
        )
}

Export-ModuleMember @exportModuleMemberParam

# SIG # Begin signature block
# MIIlhQYJKoZIhvcNAQcCoIIldjCCJXICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDaYv4FAZ8e0WXa
# drgWCSDoyEZAAidsndvXk93QxIVO4KCCC14wggTrMIID06ADAgECAhMzAAAI/yN0
# 5bNiDD7eAAAAAAj/MA0GCSqGSIb3DQEBCwUAMHkxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xIzAhBgNVBAMTGk1pY3Jvc29mdCBXaW5kb3dzIFBD
# QSAyMDEwMB4XDTIxMDkwOTE5MDUxNloXDTIyMDkwMTE5MDUxNlowcDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEaMBgGA1UEAxMRTWljcm9zb2Z0
# IFdpbmRvd3MwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC7XnnM3dQr
# TkdEfd2ofYS42n2ZaluJCuT4F9PWFdlYA482HzK5e+7TSWW4AWxdYIM1qGM4fDRr
# 7tFBF+T6sChm9RFlnHsYEOovf0T62DEQuOUIleyAuq8MgtrV4X2GOiMvIYsoYFIQ
# cQpCbeHAXFFniWwJOG7sEZe0wWvxImHKot1//FPG/dR3HMZhXnAFWlXuJ6SAQOqY
# E4wF9x5Yl/1nAxjp+QbwR75w2vHYgrdZhvGMF5jrLJJOr+UtrrINYi2/Hs50XFHN
# 6nmh4iGjjUlRaFR93M9OepSDVIM6gEBZYiO0X/iR1w/B6s0tYs8fQgkc+jAcGVTt
# IRfNEydMVtBRAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEEAYI3CgMGBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUNBYlRvj/2BU45L0EYOW4Irw3QbowUAYDVR0RBEkw
# R6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNv
# MRYwFAYDVQQFEw0yMzAwMjgrNDY3NjAwMB8GA1UdIwQYMBaAFNFPqYoHCM70JBiY
# 5QD/89Z5HTe8MFMGA1UdHwRMMEowSKBGoESGQmh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1dpblBDQV8yMDEwLTA3LTA2LmNybDBX
# BggrBgEFBQcBAQRLMEkwRwYIKwYBBQUHMAKGO2h0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljV2luUENBXzIwMTAtMDctMDYuY3J0MAwGA1UdEwEB
# /wQCMAAwDQYJKoZIhvcNAQELBQADggEBADGfbGe9r+UZf8Qyfwku39aesTNARnzn
# wh17YDoFuqmdLT1A4SYEqnvl7xE4iGjvbV+jQjnkkyIA1B2ZOuhMEFIfdmtFkD0p
# ENenaq3Kx5EBQ3bb5jOmckp8UmcJ2Ej2XF7ZwYv2qcxNUZLE2fcl0B3INjXGGYP1
# nNYdheBa9z9tbOv/KRYxUQ1/od+vzHGPuypV/RQKIq6GnO0m7GkYe5HEn4ROn2KC
# 7xHnTIYH69EjONUt0zBtjgTb6l66TxcuORzOffGpkdmnY3TOwkJQGuPNIRGsUZpS
# KrA6s9EGC9wXYQwZqsNt5Hdawzx92CLMVjfkNP4BjJ26+1ovK6/P2xMwggZrMIIE
# U6ADAgECAgphDGoZAAAAAAAEMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9v
# dCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0xMDA3MDYyMDQwMjNaFw0y
# NTA3MDYyMDUwMjNaMHkxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xIzAhBgNVBAMTGk1pY3Jvc29mdCBXaW5kb3dzIFBDQSAyMDEwMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwHm7OrHwD4S4rWQqdRZz0LsH9j4NnRTk
# sZ/ByJSwOHwf0DNV9bojZvUuKEhTxxaDuvVRrH6s4CZ/D3T8WZXcycai91JwWiwd
# lKsZv6+Vfa9moW+bYm5tS7wvNWzepGpjWl/78w1NYcwKfjHrbArQTZcP/X84RuaK
# x3NpdlVplkzk2PA067qxH84pfsRPnRMVqxMbclhiVmyKgaNkd5hGZSmdgxSlTAig
# g9cjH/Nf328sz9oW2A5yBCjYaz74E7F8ohd5T37cOuSdcCdrv9v8HscH2MC+C5Me
# KOBzbdJU6ShMv2tdn/9dMxI3lSVhNGpCy3ydOruIWeGjQm06UFtI0QIDAQABo4IB
# 4zCCAd8wEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFNFPqYoHCM70JBiY5QD/
# 89Z5HTe8MBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAP
# BgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjE
# MFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kv
# Y3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEF
# BQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MIGdBgNVHSAEgZUw
# gZIwgY8GCSsGAQQBgjcuAzCBgTA9BggrBgEFBQcCARYxaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL1BLSS9kb2NzL0NQUy9kZWZhdWx0Lmh0bTBABggrBgEFBQcCAjA0
# HjIgHQBMAGUAZwBhAGwAXwBQAG8AbABpAGMAeQBfAFMAdABhAHQAZQBtAGUAbgB0
# AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEALkGmhrUGb/CAhfo7yhfpyfrkOcKUcMNk
# lMPYVqaQjv7kmvRt9W+OU41aqPOu20Zsvn8dVFYbPB1xxFEVVH6/7qWVQjP9DZAk
# JOP53JbK/Lisv/TCOVa4u+1zsxfdfoZQI4tWJMq7ph2ahy8nheehtgqcDRuM8wBi
# QbpIdIeC/VDJ9IcpwwOqK98aKXnoEiSahu3QLtNAgfUHXzMGVF1AtfexYv1NSPdu
# QUdSHLsbwlc6qJlWk9TG3iaoYHWGu+xipvAdBEXfPqeE0VtEI2MlNndvrlvcItUU
# I2pBf9BCptvvJXsE49KWN2IGr/gbD46zOZq7ifU1BuWkW8OMnjdfU9GjN/2kT+gb
# Dmt25LiPsMLq/XX3LEG3nKPhHgX+l5LLf1kDbahOjU6AF9TVcvZW5EifoyO6BqDA
# jtGIT5Mg8nBf2GtyoyBJ/HcMXcXH4QIPOEIQDtsCrpo3HVCAKR6kp9nGmiVV/UDK
# rWQQ6DH5ElR5GvIO2NarHjP+AucmbWFJj/Elwot0md/5kxqQHO7dlDMOQlDbf1D4
# n2KC7KaCFnxmvOyZsMFYXaiwmmEUkdGZL0nkPoGZ1ubvyuP9Pu7sCYYDBw0bDXzr
# 9FrJlc+HEgpd7MUCks0FmXLKffEqEBg45DGjKLTmTMVSo5xqx33AcQkEDXDeAj+H
# 7lah7Ou1TIUxghl9MIIZeQIBATCBkDB5MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSMwIQYDVQQDExpNaWNyb3NvZnQgV2luZG93cyBQQ0EgMjAx
# MAITMwAACP8jdOWzYgw+3gAAAAAI/zANBglghkgBZQMEAgEFAKCBrjAZBgkqhkiG
# 9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIB
# FTAvBgkqhkiG9w0BCQQxIgQg/sXrgfqY3Dfn8CmDeQUnrePWJGB90RYdAhd3zsuB
# E00wQgYKKwYBBAGCNwIBDDE0MDKgFIASAE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0
# dHA6Ly93d3cubWljcm9zb2Z0LmNvbTANBgkqhkiG9w0BAQEFAASCAQCmb0HQP/QO
# nIlrWthIAZm5YDUqyKm8j9/QKXkpedpP1tO2zqWj1F8GkgoWz0WB+oVC1SQ1PPBl
# ZI4ufbX0Slhx3Zn33tVvjtIuUDRJ3wiIKJmJTv4T2hbSm6Qil0UCHwd9A22V6PPv
# Pvs7hO1e2EU6KCYmth/VxmYj1Sdd3bVDiTb3Vy/SZLPSyggZc7FpULixvgtMhBRT
# ygHwpMKIgNp+4d2Ffp5jEX8jhtYjhi9MdP4/ym4rYgn1sU4cm22BYquZ65hWhZA6
# hVJ28OOdqqYNATwWNFt8OMAxr3kK4sydV0/iZhJbPFcspjz06rZmqErPhhSXrPen
# o2RmbKCX/x/BoYIXDDCCFwgGCisGAQQBgjcDAwExghb4MIIW9AYJKoZIhvcNAQcC
# oIIW5TCCFuECAQMxDzANBglghkgBZQMEAgEFADCCAVUGCyqGSIb3DQEJEAEEoIIB
# RASCAUAwggE8AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIDyTbeH2
# 4NapUFbFh9qsVvgejbw8a+BFA9/MCWJ7eLkWAgZihMBxofgYEzIwMjIwNjIwMDQw
# NTAyLjgzNVowBIACAfSggdSkgdEwgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0
# byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjowQTU2LUUzMjktNEQ0RDEl
# MCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEV8wggcQMIIE
# +KADAgECAhMzAAABpzW7LsJkhVApAAEAAAGnMA0GCSqGSIb3DQEBCwUAMHwxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
# c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIyMDMwMjE4NTEyMloXDTIzMDUx
# MTE4NTEyMlowgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# KTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYD
# VQQLEx1UaGFsZXMgVFNTIEVTTjowQTU2LUUzMjktNEQ0RDElMCMGA1UEAxMcTWlj
# cm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAO0jOMYdUAXecCWm5V6TRoQZ4hsPLe0Vp6CwxFiTA5l867fAbDyx
# nKzdfBsf/0XJVXzIkcvzCESXoklvMDBDa97SEv+CuLEIooMbFBH1WeYgmLVO9Tbb
# LStJilNITmQQQ4FB5qzMEsDfpmaZZMWWgdOjoSQed9UrjjmcuWsSskntiaUD/VQd
# QcLMnpeUGc7CQsAYo9HcIMb1H8DTcZ7yAe3aOYf766P2OT553/4hdnJ9Kbp/FfDe
# UAVYuEc1wZlmbPdRa/uCx4iKXpt80/5woAGSDl8vSNFxi4umXKCkwWHm8GeDZ3tO
# KzMIcIY/64FtpdqpNwbqGa3GkJToEFPR6D6XJ0WyqebZvOZjMQEeLCJIrSnF4Lbk
# kfkX4D4scjKz92lI9LRurhMPTBEQ6pw3iGsEPY+Jrcx/DJmyQWqbpN3FskWu9xhg
# zYoYsRuisCb5FIMShiallzEzum5xLE4U5fuxEbwk0uY9ZVDNVfEhgiQedcSAd3GW
# vVM36gtYy6QJfixD7ltwjSm5sVa1voBf2WZgCC3r4RE7VnovlqbCd3nHyXv5+8UG
# TLq7qRdRQQaBQXekT9UjUubcNS8ZYeZwK8d2etD98mSI4MqXcMySRKUJ9OZVQNWz
# I3LyS5+CjIssBHdv19aM6CjXQuZkkmlZOtMqkLRg1tmhgI61yFC+jxB3AgMBAAGj
# ggE2MIIBMjAdBgNVHQ4EFgQUH2y4fwWYLjCFb+EOQgPz9PpaRYMwHwYDVR0jBBgw
# FoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKgUIZOaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwVGltZS1T
# dGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAwXjBcBggrBgEF
# BQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNy
# b3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQwDAYDVR0TAQH/
# BAIwADATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQsFAAOCAgEATxL6
# MfPZOhR91DHShlzal7B8vOCUvzlvbVha0UzhZfvIcZA/bT3XTXbQPLnIDWlRdjQX
# 7PGkORhX/mpjZCC5J7fD3TJMn9ZQQ8MXnJ0sx3/QJIlNgPVaOpk9Yk1YEqyItOyP
# Hr3Om3v/q9h5f5qDk0IMV2taosze0JGlM3M5z7bGkDly+TfhH9lI03D/FzLjjzW8
# EtvcqmmH68QHdTsl84NWGkd2dUlVF2aBWMUprb8H9EhPUQcBcpf11IAj+f04yB3n
# cQLh+P+PSS2kxNLLeRg9CWbmsugplYP1D5wW+aH2mdyBlPXZMIaERJFvZUZyD8Rf
# J8AsE3uU3JSd408QBDaXDUf94Ki3wEXTtl8JQItGc3ixRYWNIghraI4h3d/+266O
# B6d0UM2iBXSqwz8tdj+xSST6G7ZYqxatEzt806T1BBHe9tZ/mr2S52UjJgAVQBgC
# QiiiixNO27g5Qy4CDS94vT4nfC2lXwLlhrAcNqnAJKmRqK8ehI50TTIZGONhdhGc
# M5xUVeHmeRy9G6ufU6B6Ob0rW6LXY2qTLXvgt9/x/XEh1CrnuWeBWa9E307AbePa
# Bopu8+WnXjXy6N01j/AVBq1TyKnQX1nSMjU9gZ3EaG8oS/zNM59HK/IhnAzWeVcd
# BYrq/hsu9JMvBpF+ZEQY2ZWpbEJm7ELl/CuRIPAwggdxMIIFWaADAgECAhMzAAAA
# FcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBD
# ZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5MzAxODIyMjVaFw0zMDA5
# MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIICIjANBgkq
# hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA5OGmTOe0ciELeaLL1yR5vQ7VgtP97pwH
# B9KpbE51yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa4n5KWv64NmeFRiMMtY0T
# z3cywBAY6GB9alKDRLemjkZrBxTzxXb1hlDcwUTIcVxRMTegCjhuje3XD9gmU3w5
# YQJ6xKr9cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEBydUv626GIl3GoPz130/o5T
# z9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi947SHJMPgyY9+tVSP3PoF
# VZhtaDuaRr3tpK56KTesy+uDRedGbsoy1cCGMFxPLOJiss254o2I5JasAUq7vnGp
# F1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+/NmeRd+2ci/bfV+Autuq
# fjbsNkz2K26oElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY7afomXw/TNuvXsLz1dhz
# PUNOwTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtcodgLiMxhy16cg8ML6EgrX
# Y28MyTZki1ugpoMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH29wb0f2y1BzFa/ZcUlFd
# Etsluq9QBXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94q0W29R6HXtqPnhZyacau
# e7e3PmriLq0CAwEAAaOCAd0wggHZMBIGCSsGAQQBgjcVAQQFAgMBAAEwIwYJKwYB
# BAGCNxUCBBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0GA1UdDgQWBBSfpxVdAF5i
# XYP05dJlpxtTNRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQBgjdMg30BATBBMD8GCCsG
# AQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL0RvY3MvUmVw
# b3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgwGQYJKwYBBAGCNxQCBAwe
# CgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0j
# BBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0
# cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2Vy
# QXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRf
# MjAxMC0wNi0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIBAJ1VffwqreEsH2cBMSRb
# 4Z5yS/ypb+pcFLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRsfNB1OW27DzHkwo/7bNGh
# lBgi7ulmZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6Ce5732pvvinLbtg/SHUB
# 2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbzaN9l9qRWqveVtihVJ9AkvUCgvxm2EhIR
# XT0n4ECWOKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKBGUIZUnWKNsIdw2FzLixr
# e24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7hvoyGtmW9I/2kQH2zsZ0/fZM
# cm8Qq3UwxTSwethQ/gpY3UA8x1RtnWN0SCyxTkctwRQEcb9k+SS+c23Kjgm9swFX
# SVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFUa2pFEUep8beuyOiJXk+d
# 0tBMdrVXVAmxaQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+k77L+DvktxW/tM4+pTFR
# hLy/AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0+CQ1ZyvgDbjmjJnW4SLq
# 8CdCPSWU5nR0W2rRnj7tfqAxM328y+l7vzhwRNGQ8cirOoo6CGJ/2XBjU02N7oJt
# pQUQwXEGahC0HVUzWLOhcGbyoYIC0jCCAjsCAQEwgfyhgdSkgdEwgc4xCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29m
# dCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVT
# TjowQTU2LUUzMjktNEQ0RDElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# U2VydmljZaIjCgEBMAcGBSsOAwIaAxUAwH7vHimSAzeDLN0qzWNb2p2vRH+ggYMw
# gYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUF
# AAIFAOZaFnQwIhgPMjAyMjA2MjAwMTQxMDhaGA8yMDIyMDYyMTAxNDEwOFowdzA9
# BgorBgEEAYRZCgQBMS8wLTAKAgUA5loWdAIBADAKAgEAAgIVVgIB/zAHAgEAAgIR
# YjAKAgUA5ltn9AIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAow
# CAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAF0H5/30A5wz
# nQk9ZWEWzzCF+/Cub2ovBtEtnCSQH+GaTV0oPRbMyg8DqiFQqvbESR13Lwrnc7YU
# c7C91pU0asp612qGT36wnb0fi3tuWzVgD8IxM6ZhxDbfwFYenZWMaPA7Xea7hI8l
# c/+7urpzEcqlO/g6Bj/dUbg+TeRokBaYMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGnNbsuwmSFUCkAAQAAAacwDQYJYIZI
# AWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG
# 9w0BCQQxIgQg8l0sm9zhelKc/v4YJNIniwkp0YMf8/LiXnzMXn+PercwgfoGCyqG
# SIb3DQEJEAIvMYHqMIHnMIHkMIG9BCBH8H/nCZUC4L0Yqbz3sH3w5kzhwJ4RqCkX
# XKxNPtqOGzCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
# AAABpzW7LsJkhVApAAEAAAGnMCIEIGx/uxHV6N+3Y/vYeJ+HAAk8fMHIcLlGaBNh
# LrXMy/j8MA0GCSqGSIb3DQEBCwUABIICAIDCatBQvzchUjyRXi5nebK2hUxjzoOm
# ByJlSD7mT0Kbyo61vIOxMrpyC2jJ2aAGifoAUAMYA0mYh6JmE2UTzerLpFPVHSJ9
# Ub5YOhBRR1J3AeFMjWE6inSuAluXkafw8t9tUcBSx12kBHW1NHvOrCjOE+Yu2qlf
# 9zIm1uqv2TbF3h5vzRvGwyU0IzVFuarNQv3sm8RxPAhrSYGKxFNwywiBPPl/9lvb
# 4XEuyTeWkHMld20zFbm+9YaldtP3rSEqK/Okk0RbbFv941LZpTLECuMM+BXa/fr2
# Po9QyL+DVkFytZak/4+nFHHPsqcFBX8drYC9PoG4NrUhSffD+Plh6PG6hY1u4aXD
# h0fTVzERIjwMMXIsKDe49DwRs+cdHJjkNdVuH9UcFFYxxt+uHwWepVvy4Urb8O4L
# 6OpnbLpF+wWPik6UMz9exFxx5wYtZz2k27WjICCnDjo0Z+9uHhzw/TIR2Vf8xA2Z
# 0vVaYM6PmRWeGkhSiSX70sOGMfSwdtWFrUooD0bPbRpxWUOr+5SJ8R1rlmadl4LX
# BISMxP8uAI4eexjpjIPt+UGTrX5iAD7bhJcVsm5jHr6xlcHCpHdpdrhJ3ekIqjva
# fODL8bWFFWcsvOMRE1y1c2YVePzc9KLzjV4N1GLuj8OLstT8k4WUMm3TD/TKAQab
# StIjJrdEy56u
# SIG # End signature block
