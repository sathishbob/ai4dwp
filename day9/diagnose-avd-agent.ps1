Write-Host '=== DSREG ==='
dsregcmd /status

Write-Host '=== SERVICES ==='
Get-Service RdAgent,RDAgentBootLoader -ErrorAction SilentlyContinue | Format-List Name,Status,StartType

Write-Host '=== PROCESS PATHS ==='
Get-CimInstance Win32_Service -Filter "Name='RdAgent' OR Name='RDAgentBootLoader'" | Select-Object Name,State,PathName | Format-List

Write-Host '=== INSTALLED PRODUCTS ==='
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Remote Desktop|RD Infra|Boot Loader' } | Select-Object DisplayName,DisplayVersion,PSChildName | Format-Table -AutoSize

Write-Host '=== REGISTRY ==='
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent' -ErrorAction SilentlyContinue | Select-Object HostPoolArmPath,IsAADJoined,IsEntraIDJoined,RegistrationToken | Format-List

Write-Host '=== AGENT LOGS ==='
Get-ChildItem 'C:\ProgramData\Microsoft\RDInfraAgent\Logs' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5 Name,Length,LastWriteTime | Format-Table -AutoSize
$latest = Get-ChildItem 'C:\ProgramData\Microsoft\RDInfraAgent\Logs' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 2
foreach ($log in $latest) { Write-Host "--- $($log.FullName) ---"; Get-Content $log.FullName -Tail 100 -ErrorAction SilentlyContinue }

Write-Host '=== EVENT LOGS ==='
Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=(Get-Date).AddHours(-3)} -ErrorAction SilentlyContinue | Where-Object { $_.ProviderName -match 'RD|RemoteDesktop|MsiInstaller' -or $_.Message -match 'RDAgent|RDInfra|BootLoader' } | Select-Object -First 30 TimeCreated,ProviderName,Id,LevelDisplayName,Message | Format-List
