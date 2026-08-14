param([string]$RegistrationToken)

# Stop BootLoader first so it cannot restart RdAgent during uninstall/reinstall
Write-Host "Stopping services..."
Stop-Service RDAgentBootLoader -Force -ErrorAction SilentlyContinue
Stop-Service RdAgent           -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 8

# Uninstall current RDAgent via msiexec /x (more reliable than WMI for services)
$agentProductCode = (Get-WmiObject -Class Win32_Product |
    Where-Object { $_.Name -like 'Remote Desktop Services Infrastructure Agent*' }).IdentifyingNumber
if ($agentProductCode) {
    Write-Host "Uninstalling product $agentProductCode"
    $u = Start-Process msiexec.exe -ArgumentList "/x $agentProductCode /quiet /norestart" -Wait -PassThru
    Write-Host "Uninstall exit code: $($u.ExitCode)"
} else {
    Write-Host "No RDAgent MSI product found — proceeding to install"
}
Start-Sleep -Seconds 10

# Download a fresh RDAgent MSI
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$msi = 'C:\Windows\Temp\RDAgent-fresh.msi'
Write-Host "Downloading RDAgent MSI..."
Invoke-WebRequest -Uri 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv' -OutFile $msi -UseBasicParsing
Write-Host "MSI size: $((Get-Item $msi).Length) bytes"

# Install with AADJ=1 — this makes the agent skip domain join health checks
Write-Host "Installing with AADJ=1..."
$r = Start-Process msiexec.exe -ArgumentList "/i `"$msi`" REGISTRATIONTOKEN=`"$RegistrationToken`" AADJ=1 /quiet /norestart /l*v C:\Windows\Temp\rdagent-aadj.log" -Wait -PassThru
Write-Host "Install exit code: $($r.ExitCode)"

Start-Sleep -Seconds 15
Get-Service RdAgent, RDAgentBootLoader -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType | Format-Table -AutoSize
