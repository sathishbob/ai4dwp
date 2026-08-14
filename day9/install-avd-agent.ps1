param([string]$RegistrationToken)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Download-File($url, $dest) {
    Write-Host "Downloading $url -> $dest"
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host "Invoke-WebRequest failed: $_  — trying curl.exe"
        & curl.exe -L -o $dest $url
    }
    if (Test-Path $dest) {
        Write-Host "  OK: $((Get-Item $dest).Length) bytes"
    } else {
        Write-Error "  FAILED: $dest not created"
    }
}

# Skip RDAgent if already installed (exit code 0 from previous run)
if (-not (Get-Service -Name RDAgent -ErrorAction SilentlyContinue)) {
    Download-File 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv' 'C:\Windows\Temp\RDAgent.msi'
    $r1 = Start-Process msiexec.exe -ArgumentList "/i C:\Windows\Temp\RDAgent.msi REGISTRATIONTOKEN=$RegistrationToken /quiet /norestart /l*v C:\Windows\Temp\rdagent.log" -Wait -PassThru
    Write-Host "RDAgent exit code: $($r1.ExitCode)"
} else {
    Write-Host "RDAgent service already present — skipping agent MSI"
}

# BootLoader — try primary URL then fwlink fallback
$bootDest = 'C:\Windows\Temp\RDAgentBoot.msi'
Download-File 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH' $bootDest
if (-not (Test-Path $bootDest) -or (Get-Item $bootDest).Length -lt 1MB) {
    Remove-Item $bootDest -Force -ErrorAction SilentlyContinue
    Download-File 'https://go.microsoft.com/fwlink/?linkid=2159459' $bootDest
}

$r2 = Start-Process msiexec.exe -ArgumentList "/i $bootDest /quiet /norestart /l*v C:\Windows\Temp\rdboot.log" -Wait -PassThru
Write-Host "RDAgentBootLoader exit code: $($r2.ExitCode)"
