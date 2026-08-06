[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Write-SectionHeader {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host ''
    Write-Host ('=' * 80) -ForegroundColor DarkGray
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ('=' * 80) -ForegroundColor DarkGray
}

function Get-ExecutablePath {
    param(
        [Parameter(Mandatory = $true)]
        [int]$ProcessId
    )

    try {
        $process = Get-CimInstance -ClassName Win32_Process -Filter ("ProcessId = {0}" -f $ProcessId)
        if ($null -ne $process -and $process.ExecutablePath) {
            return $process.ExecutablePath
        }
    }
    catch {
    }

    return '<unavailable>'
}

Write-Host 'Endpoint Health Report' -ForegroundColor White
Write-Host ('Generated: {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -ForegroundColor DarkGray

# Section 1: System uptime.
# This section reports how long the computer has been running since the last boot.
Write-SectionHeader -Title '1. System Uptime'
$operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
$uptime = (Get-Date) - $operatingSystem.LastBootUpTime
Write-Host ('Last boot time : {0}' -f $operatingSystem.LastBootUpTime)
Write-Host ('Uptime         : {0} days {1} hours {2} minutes {3} seconds' -f $uptime.Days, $uptime.Hours, $uptime.Minutes, $uptime.Seconds)

# Section 2: Free disk space.
# This section lists fixed local drives and shows total space, free space, and free percentage.
Write-SectionHeader -Title '2. Free Disk Space'
# VERIFY: DriveType=3 limits the report to fixed local disks; change it only if you want removable or network drives included.
$diskDrives = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3' | Sort-Object DeviceID
if ($diskDrives) {
    $diskDrives |
        Select-Object `
            DeviceID,
            @{Name = 'Size(GB)'; Expression = { [math]::Round($_.Size / 1GB, 2) } },
            @{Name = 'Free(GB)'; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) } },
            @{Name = 'Free(%)'; Expression = {
                if ($_.Size -gt 0) {
                    [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
                }
                else {
                    0
                }
            } } |
        Format-Table -AutoSize | Out-String -Width 200 | Write-Host
}
else {
    Write-Host 'No fixed local disks were found.'
}

# Section 3: Pending reboot status.
# This section checks common registry locations that indicate a reboot is pending.
Write-SectionHeader -Title '3. Pending Reboot Check'
# VERIFY: These registry paths are the standard pending reboot indicators; confirm they match the scope you want to use.
$pendingRebootChecks = @(
    [pscustomobject]@{ Label = 'Component Based Servicing'; Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'; CheckType = 'Key' },
    [pscustomobject]@{ Label = 'Windows Update'; Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'; CheckType = 'Key' },
    [pscustomobject]@{ Label = 'Pending File Rename Operations'; Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'; CheckType = 'Value'; ValueName = 'PendingFileRenameOperations' }
)

$pendingReasons = foreach ($check in $pendingRebootChecks) {
    switch ($check.CheckType) {
        'Key' {
            if (Test-Path -Path $check.Path) {
                $check.Label
            }
        }
        'Value' {
            $registryValue = Get-ItemProperty -Path $check.Path -Name $check.ValueName -ErrorAction SilentlyContinue
            if ($null -ne $registryValue -and $null -ne $registryValue.$($check.ValueName)) {
                $check.Label
            }
        }
    }
}

if ($pendingReasons) {
    Write-Host 'Pending reboot : Yes'
    Write-Host 'Reasons        :'
    $pendingReasons | ForEach-Object { Write-Host ('  - {0}' -f $_) }
}
else {
    Write-Host 'Pending reboot : No'
}

# Section 4: Top 5 processes by memory.
# This section shows the processes with the highest working set, which is the physical memory currently in use.
Write-SectionHeader -Title '4. Top 5 Processes by Memory (Working Set)'
# VERIFY: Some protected processes may not expose a full executable path, so the script will show <unavailable> for those entries.
Get-Process |
    Sort-Object -Property WorkingSet64 -Descending |
    Select-Object -First 5 `
        Name,
        Id,
        @{Name = 'ExecutablePath'; Expression = { Get-ExecutablePath -ProcessId $_.Id } },
        @{Name = 'WorkingSetMB'; Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) } } |
    Format-Table -AutoSize | Out-String -Width 200 | Write-Host

# Section 5: Top 5 processes by CPU.
# This section shows the processes that have consumed the most CPU time since they started.
Write-SectionHeader -Title '5. Top 5 Processes by CPU'
# VERIFY: Some protected processes may not expose a full executable path, so the script will show <unavailable> for those entries.
Get-Process |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 5 `
        Name,
        Id,
        @{Name = 'ExecutablePath'; Expression = { Get-ExecutablePath -ProcessId $_.Id } },
        @{Name = 'CPUSeconds'; Expression = { [math]::Round($_.CPU, 2) } } |
    Format-Table -AutoSize | Out-String -Width 200 | Write-Host

# Section 6: Last 5 system log errors.
# This section reads the System event log and returns the five most recent error events.
Write-SectionHeader -Title '6. Last 5 System Log Errors'
# VERIFY: The System log and Level=2 filter return Windows error events; adjust only if you need a different log or severity.
try {
    $systemErrors = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5

    if ($systemErrors) {
        $systemErrors |
            Select-Object `
                TimeCreated,
                ProviderName,
                Id,
                LevelDisplayName,
                Message |
            Format-List | Out-String -Width 200 | Write-Host
    }
    else {
        Write-Host 'No System log errors were found.'
    }
}
catch {
    Write-Host ('Unable to read the System log: {0}' -f $_.Exception.Message)
}