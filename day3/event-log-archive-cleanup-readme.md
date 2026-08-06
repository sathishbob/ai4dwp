# Event Log Archive and Cleanup Script (PowerShell 5.1)

This document explains how to use `event-log-archive-cleanup.ps1` for safe archival and cleanup of stale Windows Event Logs on endpoint devices.

## Script Location

- `day3/event-log-archive-cleanup.ps1`

## What the Script Does

- Checks one or more event log channels (default: `Application`, `System`, `Security`).
- Targets only logs whose `LastWriteTime` is older than `-OlderThanDays` (default: `3`).
- Archives each eligible log to `.evtx` before cleanup.
- Clears the live log only after successful archive.
- Supports dry-run mode (`-DryRun`) and reports the count of records it would delete.
- Uses `try/catch` around each operation and continues safely on per-log errors.
- Logs every action to a timestamped log file.
- Writes a manifest CSV for rollback workflow.
- Is idempotent for archival: if today's archive file for a log already exists, that log is skipped.

## Important Rollback Note

Windows Event Log channels cannot be directly repopulated from `.evtx` archives into the original live channel.

Rollback mode in this script restores archive files into a dedicated restore folder for investigation/recovery workflow:

- It reads a previously generated manifest CSV.
- It copies archived `.evtx` files into a timestamped restore session folder.
- It supports `-DryRun` preview mode.

## Parameters

- `-LogNames <string[]>`
  - Event log channels to process.
  - Default: `Application`, `System`, `Security`.

- `-OlderThanDays <int>`
  - Process only logs older than this many days by `LastWriteTime`.
  - Default: `3`.

- `-DryRun`
  - Preview mode.
  - No archive/clear actions happen.
  - Prints and logs how many records would be deleted.

- `-ArchiveRoot <string>`
  - Root folder for `.evtx` archives.
  - Default: `%ProgramData%\DwpEventLogCleanup\Archive`.

- `-LogRoot <string>`
  - Root folder for run log files.
  - Default: `%ProgramData%\DwpEventLogCleanup\Logs`.

- `-ManifestRoot <string>`
  - Root folder for cleanup manifest CSV files.
  - Default: `%ProgramData%\DwpEventLogCleanup\Manifest`.

- `-RollbackRestoreRoot <string>`
  - Root folder used by rollback mode to place restored archive copies.
  - Default: `%ProgramData%\DwpEventLogCleanup\RollbackRestore`.

- `-RollbackFromManifest <string>`
  - Switches to rollback mode.
  - Uses the specified manifest CSV to stage archive copies for recovery.
  - Can be combined with `-DryRun`.

## Usage Examples

### 1) Dry run with defaults (shows records that would be deleted)

```powershell
.\day3\event-log-archive-cleanup.ps1 -DryRun
```

### 2) Cleanup logs older than 7 days

```powershell
.\day3\event-log-archive-cleanup.ps1 -OlderThanDays 7
```

### 3) Target specific logs only

```powershell
.\day3\event-log-archive-cleanup.ps1 -LogNames Application,System -OlderThanDays 5
```

### 4) Rollback preview from manifest

```powershell
.\day3\event-log-archive-cleanup.ps1 -RollbackFromManifest "C:\ProgramData\DwpEventLogCleanup\Manifest\event-log-cleanup-manifest_20260805_101500_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.csv" -DryRun
```

### 5) Rollback execution from manifest

```powershell
.\day3\event-log-archive-cleanup.ps1 -RollbackFromManifest "C:\ProgramData\DwpEventLogCleanup\Manifest\event-log-cleanup-manifest_20260805_101500_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.csv"
```

## Summary Output

At the end of each run, the script prints:

- Number of logs checked and eligible
- Number of logs archived and cleared
- Number of logs skipped (disabled/recent/empty/idempotent skip)
- `Records would delete` (important for dry-run)
- `Records deleted` (actual cleanup)
- Error count
- Log file path
- Manifest path (when created)

## Safety Notes

- Archive happens before clear; if archive fails, clear is skipped.
- Every operation is wrapped with `try/catch`.
- Per-log failure does not stop the whole run.
- Script is safe to rerun on the same day due to archive idempotency checks.
- Run with admin rights to avoid access errors on protected channels (for example, `Security`).
