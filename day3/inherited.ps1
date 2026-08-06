# ============================================================================
# Purpose : Gather a quick endpoint health snapshot (host, disk, process, event,
#           and stale profile indicators) and print a simple console summary.
# Author  : Unknown (refactored for readability)
# Run     : Open PowerShell and run:
#           .\day3\inherited.ps1
# Notes   : Read-only reporting script; does not intentionally change system
#           configuration or state.
# ============================================================================

# Get core computer details (such as machine name and total physical memory).
$computerSystemInfo = Get-CimInstance Win32_ComputerSystem

# Get free space (in bytes) from drive C.
$freeBytesOnCDrive = Get-PSDrive C | Select-Object -ExpandProperty Free

# Get the top 5 running processes by working set memory usage (highest first).
$topMemoryProcesses = Get-Process | Sort-Object WS -Descending | Select-Object -First 5

# Get the newest 10 System log events and keep only error-level entries.
$recentSystemErrorEvents = Get-WinEvent -LogName System -MaxEvents 10 | Where-Object { $_.Level -eq 2 }

# Get user profiles and keep only non-special profiles unused for more than 90 days.
$staleUserProfiles = Get-CimInstance Win32_UserProfile | Where-Object {
     # Exclude special system profiles and match profiles older than 90 days.
     -not $_.Special -and $_.LastUseTime -lt (Get-Date).AddDays(-90)
}

# Print computer name and total physical memory.
Write-Host $computerSystemInfo.Name $computerSystemInfo.TotalPhysicalMemory

# Print rounded free space on C: in GB.
Write-Host ([math]::Round($freeBytesOnCDrive / 1GB, 2)) 'GB free'

# Print each top process name with its working set memory value.
$topMemoryProcesses | ForEach-Object { Write-Host $_.Name $_.WS }

# Print each error event timestamp with its message.
$recentSystemErrorEvents | ForEach-Object { Write-Host $_.TimeCreated $_.Message }

# If any stale profiles were found, print their count.
if ($staleUserProfiles.Count -gt 0) { Write-Host 'Stale profiles:' $staleUserProfiles.Count }