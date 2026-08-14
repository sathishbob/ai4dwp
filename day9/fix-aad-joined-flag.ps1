$regPath = 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent'

# Set both flag variants — key name differs across agent versions
New-ItemProperty -Path $regPath -Name 'IsAADJoined'     -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'IsEntraIDJoined' -Value 1 -PropertyType DWord -Force | Out-Null
Write-Host "IsAADJoined     = $((Get-ItemProperty $regPath -Name IsAADJoined).IsAADJoined)"
Write-Host "IsEntraIDJoined = $((Get-ItemProperty $regPath -Name IsEntraIDJoined).IsEntraIDJoined)"

# Ordered restart: stop inner service first, then the manager, then start in reverse
Stop-Service -Name RdAgent           -Force -ErrorAction SilentlyContinue
Stop-Service -Name RDAgentBootLoader -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5
Start-Service -Name RDAgentBootLoader
Start-Sleep -Seconds 10
Start-Service -Name RdAgent
Start-Sleep -Seconds 5

Get-Service RdAgent, RDAgentBootLoader | Select-Object Name, Status, StartType | Format-Table -AutoSize
