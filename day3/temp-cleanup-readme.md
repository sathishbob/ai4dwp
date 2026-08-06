# Temp Cleanup Script (PowerShell 5.1)

This document explains how to use `temp-cleanup.ps1` for safe temp-file cleanup on Windows endpoints.

## Script Location

- `day3/temp-cleanup.ps1`

## What the Script Does

- Scans one or more temp folders.
- Targets only files older than a configurable number of days (`-OlderThanDays`).
- Supports a dry-run mode (`-DryRun`) that prints files it would remove.
- Handles errors per file with `try/catch` and continues processing.
- Skips locked files and logs the reason.
- Logs every action to a timestamped log file.
- Prints an execution summary at the end.
- Supports rollback by moving files to a rollback store and generating a manifest.
- Is idempotent: rerunning will not break state; already removed files are simply not found in later runs.

## Parameters

- `-Paths <string[]>`
  - Folders to scan.
  - Default: user temp and Windows temp.

- `-OlderThanDays <int>`
  - Only files with `LastWriteTime` older than this value are processed.
  - Default: `0`

- `-DryRun`
  - No deletion/move occurs.
  - Prints and logs the files that would be removed.

- `-EnableRollback`
  - Instead of direct delete, files are moved to rollback storage.
  - A rollback manifest CSV is generated.

- `-RollbackRoot <string>`
  - Root folder for rollback sessions.
  - Default: `%ProgramData%\DwpTempCleanup\Rollback`

- `-LogRoot <string>`
  - Root folder for log files.
  - Default: `%ProgramData%\DwpTempCleanup\Logs`

- `-RollbackFromManifest <string>`
  - Switches script to rollback mode.
  - Restores files listed in the provided manifest CSV.
  - Can be combined with `-DryRun` to preview restoration.

## Usage Examples

### 1) Dry run with defaults

```powershell
.\day3\temp-cleanup.ps1 -DryRun
```

### 2) Delete files older than 7 days from defaults

```powershell
.\day3\temp-cleanup.ps1 -OlderThanDays 7
```

### 3) Cleanup with rollback enabled

```powershell
.\day3\temp-cleanup.ps1 -OlderThanDays 3 -EnableRollback
```

After this run, note the printed `Rollback manifest` path.

### 4) Restore from a rollback manifest

```powershell
.\day3\temp-cleanup.ps1 -RollbackFromManifest "C:\ProgramData\DwpTempCleanup\Rollback\session_20260805_101500_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx\rollback-manifest.csv"
```

### 5) Preview rollback without restoring

```powershell
.\day3\temp-cleanup.ps1 -RollbackFromManifest "C:\ProgramData\DwpTempCleanup\Rollback\session_...\rollback-manifest.csv" -DryRun
```

## Logging and Output

- Every run creates a log file with date/time and run id in the name.
- The script prints:
  - Per-file actions (or dry-run candidates)
  - End summary counts
  - Log file location
  - Rollback manifest location (when rollback is enabled)

## Safety Notes

- The script skips drive-root paths if accidentally provided (for example `C:\`).
- Locked files are skipped and logged.
- Errors on one file do not stop processing of other files.
