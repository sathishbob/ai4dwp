<#
.SYNOPSIS
Archives and cleans stale Windows Event Logs safely on endpoint devices.

.DESCRIPTION
For each target log, the script checks whether the log is stale (last write time older
than a configurable threshold). For stale logs, it exports the log to an archive and then
clears the live log. The script supports dry-run mode, per-operation error handling,
detailed logging, end-of-run summary reporting, idempotency checks, and rollback mode.

.NOTES
PowerShell version: 5.1
Run from an elevated PowerShell session for best coverage of protected logs.
#>

[CmdletBinding()]
param(
    # Names of event logs to evaluate.
    [Parameter(Mandatory = $false)]
    [string[]]$LogNames = @(
        'Application',
        'System',
        'Security'
    ),

    # Process only logs whose LastWriteTime is older than this many days.
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 3,

    # Preview actions only; does not archive or clear logs.
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    # Root directory where .evtx archive files are stored.
    [Parameter(Mandatory = $false)]
    [string]$ArchiveRoot = "$env:ProgramData\DwpEventLogCleanup\Archive",

    # Root directory where script log files are written.
    [Parameter(Mandatory = $false)]
    [string]$LogRoot = "$env:ProgramData\DwpEventLogCleanup\Logs",

    # Root directory where cleanup manifests are written.
    [Parameter(Mandatory = $false)]
    [string]$ManifestRoot = "$env:ProgramData\DwpEventLogCleanup\Manifest",

    # Root directory used by rollback mode to stage restored archive copies.
    [Parameter(Mandatory = $false)]
    [string]$RollbackRestoreRoot = "$env:ProgramData\DwpEventLogCleanup\RollbackRestore",

    # Path to a prior manifest CSV to run rollback mode.
    [Parameter(Mandatory = $false)]
    [string]$RollbackFromManifest
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

# Section: Initialize run metadata and create the primary log file path.
$runTimestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$runDate = Get-Date -Format 'yyyyMMdd'
$runId = [guid]::NewGuid().ToString()
$logFile = $null

# Section: Ensure required folders exist, with isolated try/catch for each call.
function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
        }
    }
    catch {
        throw "Failed to ensure directory '$Path'. $($_.Exception.Message)"
    }
}

# Section: Write messages to console and timestamped log file.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Level, $Message

    try {
        if ($logFile) {
            Add-Content -LiteralPath $logFile -Value $line
        }
    }
    catch {
        Write-Host "[LOG-ERROR] Failed writing to log file: $($_.Exception.Message)"
    }

    Write-Host $line
}

# Section: Create filesystem-safe filenames from event log names.
function Get-SafeLogName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogName
    )

    return ($LogName -replace '[\\/:*?"<>| ]', '_')
}

# Section: Invoke wevtutil safely and fail on non-zero exit code.
function Invoke-Wevtutil {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$ActionDescription
    )

    try {
        $output = & wevtutil @Arguments 2>&1

        if ($output) {
            foreach ($line in $output) {
                Write-Log -Level 'INFO' -Message ("wevtutil: {0}" -f $line)
            }
        }

        if ($LASTEXITCODE -ne 0) {
            throw "wevtutil failed for action '$ActionDescription' with exit code $LASTEXITCODE."
        }
    }
    catch {
        throw "Action '$ActionDescription' failed. $($_.Exception.Message)"
    }
}

# Section: Read metadata for a given log channel.
function Get-LogMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogName
    )

    try {
        $log = Get-WinEvent -ListLog $LogName -ErrorAction Stop
        return [pscustomobject]@{
            LogName       = $log.LogName
            IsEnabled     = [bool]$log.IsEnabled
            RecordCount   = [int64]$log.RecordCount
            LastWriteTime = $log.LastWriteTime
        }
    }
    catch {
        throw "Unable to read metadata for log '$LogName'. $($_.Exception.Message)"
    }
}

# Section: Initialize required root folders before doing any work.
Ensure-Directory -Path $LogRoot
Ensure-Directory -Path $ArchiveRoot
Ensure-Directory -Path $ManifestRoot
Ensure-Directory -Path $RollbackRestoreRoot

$logFile = Join-Path -Path $LogRoot -ChildPath ("event-log-cleanup_{0}_{1}.log" -f $runTimestamp, $runId)

# Section: Handle rollback mode from manifest (restores archived files to a restore session folder).
function Invoke-Rollback {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $true)]
        [switch]$WhatIf
    )

    # Section: Validate manifest path.
    try {
        if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
            throw "Manifest not found: $ManifestPath"
        }
    }
    catch {
        Write-Log -Level 'ERROR' -Message $_.Exception.Message
        throw
    }

    # Section: Build rollback restore session folder.
    $restoreSession = Join-Path -Path $RollbackRestoreRoot -ChildPath ("restore_{0}_{1}" -f $runTimestamp, $runId)
    try {
        Ensure-Directory -Path $restoreSession
    }
    catch {
        Write-Log -Level 'ERROR' -Message $_.Exception.Message
        throw
    }

    # Section: Import manifest rows and process each entry with isolated error handling.
    $rows = @()
    try {
        $rows = Import-Csv -LiteralPath $ManifestPath -ErrorAction Stop
    }
    catch {
        Write-Log -Level 'ERROR' -Message ("Failed to import manifest '{0}'. {1}" -f $ManifestPath, $_.Exception.Message)
        throw
    }

    $restored = 0
    $skipped = 0
    $errors = 0

    foreach ($row in $rows) {
        $archivePath = $row.ArchivePath
        $logName = $row.LogName
        $safe = Get-SafeLogName -LogName $logName
        $targetPath = Join-Path -Path $restoreSession -ChildPath ("{0}.evtx" -f $safe)

        try {
            if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
                Write-Log -Level 'WARN' -Message ("Rollback skip, archive missing: {0}" -f $archivePath)
                $skipped++
                continue
            }

            if ($WhatIf) {
                Write-Host ("[DRY-RUN ROLLBACK] Would stage archive for '{0}' to '{1}'" -f $logName, $targetPath)
                Write-Log -Message ("Dry-run rollback candidate | Log={0} Source={1} Target={2}" -f $logName, $archivePath, $targetPath)
                $skipped++
                continue
            }

            Copy-Item -LiteralPath $archivePath -Destination $targetPath -Force -ErrorAction Stop
            Write-Log -Message ("Rollback staged archive | Log={0} Source={1} Target={2}" -f $logName, $archivePath, $targetPath)
            $restored++
        }
        catch {
            Write-Log -Level 'ERROR' -Message ("Rollback error for log '{0}'. {1}" -f $logName, $_.Exception.Message)
            $errors++
        }
    }

    # Section: Print rollback summary and operational note.
    Write-Host ''
    Write-Host 'Rollback Summary'
    Write-Host '----------------'
    Write-Host ("Staged archives : {0}" -f $restored)
    Write-Host ("Skipped         : {0}" -f $skipped)
    Write-Host ("Errors          : {0}" -f $errors)
    Write-Host ("Restore folder  : {0}" -f $restoreSession)
    Write-Host 'Note: Windows does not support writing archived .evtx data back into the original live channel directly.'

    Write-Log -Message ("Rollback summary | Restored={0} Skipped={1} Errors={2} RestoreFolder={3}" -f $restored, $skipped, $errors, $restoreSession)
}

# Section: Route execution to rollback mode when a manifest was provided.
if ($RollbackFromManifest) {
    Write-Log -Message ("Mode: Rollback | DryRun={0} | Manifest={1}" -f $DryRun.IsPresent, $RollbackFromManifest)

    try {
        Invoke-Rollback -ManifestPath $RollbackFromManifest -WhatIf:$DryRun
    }
    catch {
        Write-Log -Level 'ERROR' -Message ("Rollback failed. {0}" -f $_.Exception.Message)
        throw
    }

    Write-Host ("Log file: {0}" -f $logFile)
    return
}

# Section: Build threshold date and initialize summary counters.
$cutoff = (Get-Date).AddDays(-1 * $OlderThanDays)
$archiveDateFolder = Join-Path -Path $ArchiveRoot -ChildPath $runDate

try {
    Ensure-Directory -Path $archiveDateFolder
}
catch {
    Write-Log -Level 'ERROR' -Message $_.Exception.Message
    throw
}

$summary = [ordered]@{
    LogsChecked                  = 0
    LogsEligible                 = 0
    LogsArchived                 = 0
    LogsCleared                  = 0
    LogsSkippedNotEnabled        = 0
    LogsSkippedTooRecent         = 0
    LogsSkippedNoRecords         = 0
    LogsSkippedArchiveExists     = 0
    RecordsWouldDelete           = 0
    RecordsDeleted               = 0
    DryRunCandidateLogs          = 0
    Errors                       = 0
}

$manifestRows = New-Object System.Collections.Generic.List[object]

Write-Log -Message ("Mode: Cleanup | DryRun={0} | OlderThanDays={1} | Cutoff={2}" -f $DryRun.IsPresent, $OlderThanDays, $cutoff)
Write-Log -Message ("Target logs: {0}" -f ($LogNames -join '; '))

# Section: Evaluate and process each requested event log channel.
foreach ($logName in $LogNames) {
    $summary.LogsChecked++

    try {
        $meta = Get-LogMetadata -LogName $logName
    }
    catch {
        Write-Log -Level 'ERROR' -Message $_.Exception.Message
        $summary.Errors++
        continue
    }

    try {
        if (-not $meta.IsEnabled) {
            Write-Log -Level 'WARN' -Message ("Skipped disabled log: {0}" -f $meta.LogName)
            $summary.LogsSkippedNotEnabled++
            continue
        }

        if ($meta.RecordCount -le 0) {
            Write-Log -Message ("Skipped empty log: {0}" -f $meta.LogName)
            $summary.LogsSkippedNoRecords++
            continue
        }

        if (-not $meta.LastWriteTime) {
            Write-Log -Level 'WARN' -Message ("Skipped log with unknown LastWriteTime: {0}" -f $meta.LogName)
            $summary.LogsSkippedTooRecent++
            continue
        }

        if ($meta.LastWriteTime -gt $cutoff) {
            Write-Log -Message ("Skipped recent log: {0} | LastWriteTime={1}" -f $meta.LogName, $meta.LastWriteTime)
            $summary.LogsSkippedTooRecent++
            continue
        }

        $summary.LogsEligible++
        $summary.RecordsWouldDelete += $meta.RecordCount

        $safeLogName = Get-SafeLogName -LogName $meta.LogName
        $archiveFile = Join-Path -Path $archiveDateFolder -ChildPath ("{0}.evtx" -f $safeLogName)

        if (Test-Path -LiteralPath $archiveFile -PathType Leaf) {
            Write-Log -Message ("Idempotent skip: archive for today already exists for log '{0}' at '{1}'" -f $meta.LogName, $archiveFile)
            $summary.LogsSkippedArchiveExists++
            continue
        }

        if ($DryRun) {
            Write-Host ("[DRY-RUN] Would archive and clear log '{0}' with {1} records. Archive: {2}" -f $meta.LogName, $meta.RecordCount, $archiveFile)
            Write-Log -Message ("Dry-run candidate | Log={0} Records={1} Archive={2}" -f $meta.LogName, $meta.RecordCount, $archiveFile)
            $summary.DryRunCandidateLogs++
            continue
        }

        # Section: Archive the log to .evtx before clear, then clear only on successful archive.
        try {
            Invoke-Wevtutil -Arguments @('epl', $meta.LogName, $archiveFile, '/ow:false') -ActionDescription ("Export log '{0}'" -f $meta.LogName)
            Write-Log -Message ("Archived log '{0}' to '{1}'" -f $meta.LogName, $archiveFile)
            $summary.LogsArchived++
        }
        catch {
            Write-Log -Level 'ERROR' -Message ("Archive failed for log '{0}'. {1}" -f $meta.LogName, $_.Exception.Message)
            $summary.Errors++
            continue
        }

        try {
            Invoke-Wevtutil -Arguments @('cl', $meta.LogName) -ActionDescription ("Clear log '{0}'" -f $meta.LogName)
            Write-Log -Message ("Cleared log '{0}'" -f $meta.LogName)
            $summary.LogsCleared++
            $summary.RecordsDeleted += $meta.RecordCount
        }
        catch {
            Write-Log -Level 'ERROR' -Message ("Clear failed for log '{0}'. {1}" -f $meta.LogName, $_.Exception.Message)
            $summary.Errors++
            continue
        }

        try {
            $manifestRows.Add([pscustomobject]@{
                RunId         = $runId
                RunTimestamp  = (Get-Date -Format 'o')
                LogName       = $meta.LogName
                RecordCount   = $meta.RecordCount
                LastWriteTime = $meta.LastWriteTime
                ArchivePath   = $archiveFile
            }) | Out-Null
        }
        catch {
            Write-Log -Level 'ERROR' -Message ("Manifest row append failed for log '{0}'. {1}" -f $meta.LogName, $_.Exception.Message)
            $summary.Errors++
        }
    }
    catch {
        Write-Log -Level 'ERROR' -Message ("Unhandled error for log '{0}'. {1}" -f $logName, $_.Exception.Message)
        $summary.Errors++
    }
}

# Section: Persist a cleanup manifest for rollback workflows.
$manifestPath = $null
if (-not $DryRun -and $manifestRows.Count -gt 0) {
    $manifestPath = Join-Path -Path $ManifestRoot -ChildPath ("event-log-cleanup-manifest_{0}_{1}.csv" -f $runTimestamp, $runId)

    try {
        $manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
        Write-Log -Message ("Manifest created: {0}" -f $manifestPath)
    }
    catch {
        Write-Log -Level 'ERROR' -Message ("Failed writing manifest '{0}'. {1}" -f $manifestPath, $_.Exception.Message)
        $summary.Errors++
    }
}

# Section: Print final summary with dry-run delete counts and output locations.
Write-Host ''
Write-Host 'Event Log Cleanup Summary'
Write-Host '-------------------------'
Write-Host ("Logs checked               : {0}" -f $summary.LogsChecked)
Write-Host ("Logs eligible              : {0}" -f $summary.LogsEligible)
Write-Host ("Logs archived              : {0}" -f $summary.LogsArchived)
Write-Host ("Logs cleared               : {0}" -f $summary.LogsCleared)
Write-Host ("Skipped (disabled)         : {0}" -f $summary.LogsSkippedNotEnabled)
Write-Host ("Skipped (too recent/unknown): {0}" -f $summary.LogsSkippedTooRecent)
Write-Host ("Skipped (no records)       : {0}" -f $summary.LogsSkippedNoRecords)
Write-Host ("Skipped (archive exists)   : {0}" -f $summary.LogsSkippedArchiveExists)
Write-Host ("Records would delete       : {0}" -f $summary.RecordsWouldDelete)
Write-Host ("Records deleted            : {0}" -f $summary.RecordsDeleted)
Write-Host ("Dry-run candidate logs     : {0}" -f $summary.DryRunCandidateLogs)
Write-Host ("Errors                     : {0}" -f $summary.Errors)

if ($manifestPath) {
    Write-Host ("Manifest file              : {0}" -f $manifestPath)
}

Write-Host ("Log file                   : {0}" -f $logFile)

Write-Log -Message (
    "Summary | Checked={0} Eligible={1} Archived={2} Cleared={3} SkipDisabled={4} SkipRecent={5} SkipEmpty={6} SkipArchiveExists={7} WouldDelete={8} Deleted={9} DryRunLogs={10} Errors={11}" -f
    $summary.LogsChecked,
    $summary.LogsEligible,
    $summary.LogsArchived,
    $summary.LogsCleared,
    $summary.LogsSkippedNotEnabled,
    $summary.LogsSkippedTooRecent,
    $summary.LogsSkippedNoRecords,
    $summary.LogsSkippedArchiveExists,
    $summary.RecordsWouldDelete,
    $summary.RecordsDeleted,
    $summary.DryRunCandidateLogs,
    $summary.Errors
)
