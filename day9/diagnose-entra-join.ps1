Write-Host '=== EXTENSION LOGS ==='
$paths = @(
  'C:\WindowsAzure\Logs\Plugins\Microsoft.Azure.ActiveDirectory.AADLoginForWindows',
  'C:\Packages\Plugins\Microsoft.Azure.ActiveDirectory.AADLoginForWindows'
)
foreach ($path in $paths) {
  Write-Host "--- $path ---"
  Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 10 FullName,Length,LastWriteTime |
    Format-Table -AutoSize
}
$logs = Get-ChildItem $paths[0] -Recurse -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5
foreach ($log in $logs) {
  Write-Host "--- $($log.FullName) ---"
  Get-Content $log.FullName -Tail 150 -ErrorAction SilentlyContinue
}

Write-Host '=== DEVICE REGISTRATION EVENTS ==='
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-User Device Registration/Admin'; StartTime=(Get-Date).AddHours(-2)} -ErrorAction SilentlyContinue |
  Select-Object -First 30 TimeCreated,Id,LevelDisplayName,Message |
  Format-List
