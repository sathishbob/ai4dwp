$r = Start-Process msiexec.exe -ArgumentList "/i C:\Windows\Temp\RDAgentBoot.msi /quiet /norestart /l*v C:\Windows\Temp\rdboot.log" -Wait -PassThru
Write-Host "RDAgentBootLoader exit code: $($r.ExitCode)"
Get-Service RDAgentBootLoader -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType
