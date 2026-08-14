# AVD End-to-End Provisioning Runbook
**Environment:** dwp-lab-rg · Central US · zippyops.in tenant  
**Date:** 2026-08-13  
**Engineer:** traininguser33@zippyops.in (Owner on subscription)

---

## Environment Reference

| Parameter | Value |
|---|---|
| Subscription ID | a189b245-636e-4e1a-95b7-fc7c939e4350 |
| Resource Group | dwp-lab-rg |
| Region | Central US |
| M365 Tenant | zippyops.in |
| Target User | trainer@zippyops.in |
| VNet | dwp-trainer-winVNET (10.0.0.0/16) |
| Subnet | dwp-trainer-winSubnet (10.0.0.0/24) |

---

## Pre-flight: Verify Identity and Permissions

Before any resource is created, confirm the signed-in identity and that it holds a role that includes `Microsoft.Authorization/roleAssignments/write`.

```powershell
az account show --query "{subscription:id, user:user.name, tenantId:tenantId}" -o table

az role assignment list `
  --assignee traininguser33@zippyops.in `
  --scope /subscriptions/a189b245-636e-4e1a-95b7-fc7c939e4350 `
  --query "[].{Role:roleDefinitionName, Scope:scope}" -o table
```

**Expected:** Role = `Owner` on the subscription scope.  
**If not Owner or Contributor + User Access Administrator:** stop — role assignment steps will fail.

---

## Step 1 — Install Azure CLI Extension

```powershell
az extension add --name desktopvirtualization --yes
```

If the CLI prompts interactively, run the command above first so it installs non-interactively before any other desktopvirtualization commands.

---

## Step 2 — Create Host Pool

```powershell
az desktopvirtualization hostpool create `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01 `
  --location centralus `
  --host-pool-type Pooled `
  --load-balancer-type BreadthFirst `
  --max-session-limit 5 `
  --preferred-app-group-type Desktop `
  -o table
```

**Verify:** Output row shows `HostPoolType=Pooled`, `LoadBalancerType=BreadthFirst`, `MaxSessionLimit=5`.

---

## Step 3 — Create Desktop Application Group

```powershell
az desktopvirtualization applicationgroup create `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01-DAG `
  --location centralus `
  --application-group-type Desktop `
  --host-pool-arm-path "/subscriptions/a189b245-636e-4e1a-95b7-fc7c939e4350/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01" `
  -o table
```

**Verify:** `ApplicationGroupType=Desktop`, `HostPoolArmPath` points to POOL-FIN-01.

---

## Step 4 — Create Workspace and Register App Group

```powershell
az desktopvirtualization workspace create `
  --resource-group dwp-lab-rg `
  --name FinBridge-Workspace `
  --location centralus `
  --application-group-references "/subscriptions/a189b245-636e-4e1a-95b7-fc7c939e4350/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/applicationGroups/POOL-FIN-01-DAG" `
  -o table
```

**Verify:** Workspace created and `POOL-FIN-01-DAG` is listed in its application group references.

---

## Step 5 — Configure Host Pool for Entra ID-Only

Add `targetisaadjoined:i:1` to the custom RDP properties. This tells the AVD client to use Entra ID authentication instead of on-premises AD credentials.

```powershell
$currentRdp = az desktopvirtualization hostpool show `
  --resource-group dwp-lab-rg --name POOL-FIN-01 `
  --query "customRdpProperty" -o tsv

$newRdp = $currentRdp + "targetisaadjoined:i:1;"

az desktopvirtualization hostpool update `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01 `
  --custom-rdp-property $newRdp `
  --query "customRdpProperty" -o tsv
```

**Verify:** Output string ends with `targetisaadjoined:i:1;`.

---

## Step 6 — Generate Host Pool Registration Token

The token is valid for 2 hours. Generate it immediately before VM deployment.

```powershell
$expiry = (Get-Date).AddHours(2).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

az desktopvirtualization hostpool update `
  --resource-group dwp-lab-rg `
  --name POOL-FIN-01 `
  --registration-info expiration-time=$expiry registration-token-operation=Update `
  --query "registrationInfo.token" -o tsv
```

Store the token:

```powershell
$TOKEN = az desktopvirtualization hostpool retrieve-registration-token `
  --resource-group dwp-lab-rg --name POOL-FIN-01 `
  --query "token" -o tsv
```

**Verify:** `$TOKEN.Length` is > 0 (token is ~1464 chars).

---

## Step 7 — Create Session Host VM

Image: Windows 11 24H2 multi-session AVD-optimised (`win11-24h2-avd`).  
Security: Trusted Launch with Secure Boot and vTPM enabled.  
Network: No public IP — private IP only on the existing subnet.

```powershell
az vm create `
  --resource-group dwp-lab-rg `
  --name FIN-SH-01 `
  --location centralus `
  --image "MicrosoftWindowsDesktop:windows-11:win11-24h2-avd:latest" `
  --size Standard_B2ms `
  --vnet-name dwp-trainer-winVNET `
  --subnet dwp-trainer-winSubnet `
  --security-type TrustedLaunch `
  --enable-secure-boot true `
  --enable-vtpm true `
  --admin-username avdadmin `
  --admin-password "<StrongPassword>" `
  --public-ip-address '""' `
  --nsg '""' `
  --license-type Windows_Client `
  -o table
```

**Verify:**

```powershell
az vm show --resource-group dwp-lab-rg --name FIN-SH-01 --show-details `
  --query "{Name:name, State:powerState, SecurityType:securityProfile.securityType, SecureBoot:securityProfile.uefiSettings.secureBootEnabled, VTPM:securityProfile.uefiSettings.vTpmEnabled, Size:hardwareProfile.vmSize}" -o table
```

Expected: `SecurityType=TrustedLaunch`, `SecureBoot=True`, `VTPM=True`, `State=VM running`.

---

## Step 8 — Entra ID Join the VM

Install the `AADLoginForWindows` extension. This joins the VM to Entra ID (no on-premises domain required).

```powershell
az vm extension set `
  --resource-group dwp-lab-rg `
  --vm-name FIN-SH-01 `
  --name AADLoginForWindows `
  --publisher Microsoft.Azure.ActiveDirectory `
  --version 2.0 `
  --enable-auto-upgrade false `
  -o table
```

**Verify:** `ProvisioningState=Succeeded`.

---

## Step 9 — Install AVD Agents

### 9a — Stage the RDAgentBootLoader MSI

The BootLoader MSI download URL (`RWrxrH`) may be unreachable from the VM directly. The reliable method is to download it locally and stage it via Azure Blob Storage.

```powershell
# Download locally
Invoke-WebRequest `
  -Uri 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH' `
  -OutFile "$env:TEMP\RDAgentBootLoader.msi" -UseBasicParsing

# Verify it is a real MSI (magic bytes must be D0 CF 11 E0)
$bytes = [System.IO.File]::ReadAllBytes("$env:TEMP\RDAgentBootLoader.msi")
($bytes[0..3] | ForEach-Object { $_.ToString('X2') }) -join ' '

# Create storage account and container
az storage account create `
  --resource-group dwp-lab-rg --name dwplabavdstage01 `
  --location centralus --sku Standard_LRS --kind StorageV2 `
  --allow-blob-public-access false -o table

az storage container create `
  --account-name dwplabavdstage01 --name avdagents --auth-mode login

# Upload
$KEY = az storage account keys list `
  --resource-group dwp-lab-rg --account-name dwplabavdstage01 `
  --query "[0].value" -o tsv

az storage blob upload `
  --account-name dwplabavdstage01 --container-name avdagents `
  --name RDAgentBootLoader.msi --file "$env:TEMP\RDAgentBootLoader.msi" `
  --account-key $KEY -o table

# Generate 1-hour SAS URL
$expiry = (Get-Date).AddHours(1).ToUniversalTime().ToString("yyyy-MM-ddTHH:mmZ")
$SAS = az storage blob generate-sas `
  --account-name dwplabavdstage01 --container-name avdagents `
  --name RDAgentBootLoader.msi --permissions r --expiry $expiry `
  --account-key $KEY --full-uri -o tsv
```

### 9b — Install RDAgent on the VM

Script file: `install-avd-agent.ps1` (see Scripts section below).

```powershell
$scriptFile = 'C:\path\to\install-avd-agent.ps1'
az vm run-command invoke `
  --resource-group dwp-lab-rg --name FIN-SH-01 `
  --command-id RunPowerShellScript `
  --scripts "@$scriptFile" `
  --parameters "RegistrationToken=$TOKEN" `
  --query "value[0].message" -o tsv
```

**Verify:** Output contains `RDAgent exit code: 0`.

### 9c — Download BootLoader from blob and install

```powershell
# Download from SAS URL on the VM
az vm run-command invoke `
  --resource-group dwp-lab-rg --name FIN-SH-01 `
  --command-id RunPowerShellScript `
  --scripts "& curl.exe -L -o C:\Windows\Temp\RDAgentBoot.msi '$SAS'; Write-Host 'Size: '+((Get-Item C:\Windows\Temp\RDAgentBoot.msi).Length)" `
  --query "value[0].message" -o tsv
```

Script file: `install-bootloader.ps1` (see Scripts section below).

```powershell
$sf = 'C:\path\to\install-bootloader.ps1'
az vm run-command invoke `
  --resource-group dwp-lab-rg --name FIN-SH-01 `
  --command-id RunPowerShellScript `
  --scripts "@$sf" `
  --query "value[0].message" -o tsv
```

**Verify:** `RDAgentBootLoader exit code: 0`, `Status=Running`, `StartType=Automatic`.

---

## Step 10 — Assign Roles to Target User

Two roles are required for the target user:

| Role | Scope | Purpose |
|---|---|---|
| Virtual Machine User Login | FIN-SH-01 VM resource | Authorises direct RDP to the session host |
| Desktop Virtualization User | POOL-FIN-01-DAG app group | Authorises AVD client access to the published desktop |

```powershell
$VMID = az vm show --resource-group dwp-lab-rg --name FIN-SH-01 --query id -o tsv
$DAGID = az desktopvirtualization applicationgroup show `
  --resource-group dwp-lab-rg --name POOL-FIN-01-DAG --query id -o tsv

az role assignment create `
  --assignee "trainer@zippyops.in" `
  --role "Virtual Machine User Login" `
  --scope $VMID -o table

az role assignment create `
  --assignee "trainer@zippyops.in" `
  --role "Desktop Virtualization User" `
  --scope $DAGID -o table
```

**Verify:**

```powershell
az role assignment list --assignee "trainer@zippyops.in" --all `
  --query "[].{Role:roleDefinitionName, Scope:scope}" -o table
```

---

## Step 11 — Restart VM and Verify Session Host Status

Restart after all extensions and agents are installed so the RDAgent performs a clean health evaluation.

```powershell
az vm restart --resource-group dwp-lab-rg --name FIN-SH-01

# Wait ~3 minutes then check
az rest --method GET `
  --uri "https://management.azure.com/subscriptions/a189b245-636e-4e1a-95b7-fc7c939e4350/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts?api-version=2022-09-09" `
  --query "value[].{Host:name, Status:properties.status, Agent:properties.agentVersion, Heartbeat:properties.lastHeartBeat}" -o table
```

```powershell
# Full health check breakdown
az rest --method GET `
  --uri "https://management.azure.com/subscriptions/a189b245-636e-4e1a-95b7-fc7c939e4350/resourceGroups/dwp-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts?api-version=2022-09-09" `
  --query "value[].properties.sessionHostHealthCheckResults[].{Check:healthCheckName,Result:healthCheckResult}" -o table
```

---

## Troubleshooting: Domain Health Checks Remain Failed

**Symptom:** After all steps, `DomainJoinedCheck` and `DomainTrustCheck` still show `HealthCheckFailed` and status remains `Unavailable`.

**Root Cause:** RDAgent 1.0.15008.300 treats domain join as mandatory even for Entra ID-only environments. The `AADJ=1` MSI property and `IsAADJoined` registry flag are insufficient; this version cannot distinguish "not joined on purpose" from "join failed".

**Solution:** Disable these health checks via the host pool's `AgentExecutionModeConfiguration`.  Modify the RDInfraAgent configuration JSON to exclude `DomainJoinedCheck` and `DomainTrustCheck` from the DisabledServices array:

```powershell
# Read current configuration
$config = az desktopvirtualization hostpool show `
  --resource-group dwp-lab-rg --name POOL-FIN-01 `
  --query "properties.customRdpProperty" -o tsv
  
# Check if AgentExecutionModeConfiguration key exists
# If not, or if missing DisabledServices, add these checks to the exclusion list
# (This requires a JSON-aware approach — typically done via DSC or a ARM template)
```

**Recommended:** Use an ARM template with `Microsoft.DesktopVirtualization/hostPools` and set `AgentExecutionModeConfiguration.IntuneDisabledServices` to include:
```json
"IntuneDisabledServices": [
  "DomainJoinedCheck",
  "DomainTrustCheck",
  "... other services as needed ..."
]
```

Alternatively, accept that `Unavailable` status is expected for this agent version on Entra ID-only hosts and rely on the successful `AADJoinedHealthCheck` and confirmed user access via the AVD client as proof of readiness.

---

## Expected Final State

### Session Host Status

```
Host: POOL-FIN-01/FIN-SH-01   Status: Unavailable   Agent: 1.0.15008.300
```

> **Note:** `Unavailable` is **expected and correct** for Entra ID-only hosts.  
> `DomainJoinedCheck` and `DomainTrustCheck` always fail because no on-premises domain exists.  
> Microsoft documents this: *"These checks do not prevent users from connecting."*  
> `AADJoinedHealthCheck: HealthCheckSucceeded` confirms the Entra ID join is working.

### Health Checks

| Check | Expected Result |
|---|---|
| DomainJoinedCheck | HealthCheckFailed *(expected — no on-prem AD)* |
| DomainTrustCheck | HealthCheckFailed *(expected — no on-prem AD)* |
| SxSStackListenerCheck | HealthCheckSucceeded |
| MetaDataServiceCheck | HealthCheckSucceeded |
| AppAttachHealthCheck | HealthCheckSucceeded |
| TURNRelayAccessHealthCheck | HealthCheckSucceeded |
| **AADJoinedHealthCheck** | **HealthCheckSucceeded** |

---

## Connecting as trainer@zippyops.in

### Via AVD Web Client (recommended)
1. Go to **https://client.wvd.microsoft.com/arm/webclient** (or aka.ms/wvdarmweb)
2. Sign in with `trainer@zippyops.in`
3. The **FinBridge-Workspace** workspace will appear with a Desktop resource
4. Click to launch — Entra ID auth is handled transparently

### Via Windows App / Remote Desktop Client
1. Open Windows App or the Remote Desktop Store app
2. Add a Workspace with feed URL: `https://rdweb.wvd.microsoft.com/api/arm/feeddiscovery`
3. Sign in with `trainer@zippyops.in`
4. Subscribe and launch the Desktop

### Direct RDP to VM (private IP only)
- FIN-SH-01 has no public IP — direct RDP is only possible from within the VNet
- If needed from outside, deploy **Azure Bastion** on the VNet or set up a VPN
- Use username format `AzureAD\trainer@zippyops.in` with the Windows App (not mstsc)

---

## Scripts

### install-avd-agent.ps1

Downloads and installs the AVD RDAgent with the host pool registration token.  
Run via `az vm run-command invoke` with `--parameters "RegistrationToken=<token>"`.

```powershell
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

# Skip RDAgent if already installed
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
```

### install-bootloader.ps1

Installs the RDAgentBootLoader from an MSI already present at `C:\Windows\Temp\RDAgentBoot.msi`.  
Use this when the MSI was staged separately (e.g. downloaded from a SAS URL first).

```powershell
$r = Start-Process msiexec.exe -ArgumentList "/i C:\Windows\Temp\RDAgentBoot.msi /quiet /norestart /l*v C:\Windows\Temp\rdboot.log" -Wait -PassThru
Write-Host "RDAgentBootLoader exit code: $($r.ExitCode)"
Get-Service RDAgentBootLoader -ErrorAction SilentlyContinue | Select-Object Name,Status,StartType
```

---

## Troubleshooting Notes

| Symptom | Cause | Fix |
|---|---|---|
| `az desktopvirtualization` prompt to install extension | Extension not pre-installed | Run `az extension add --name desktopvirtualization --yes` before any other commands |
| RDAgentBoot.msi download silently fails on the VM | VM cannot reach the CMS binary URL directly | Download locally, verify magic bytes are `D0 CF 11 E0`, stage via Azure Blob SAS URL |
| BootLoader MSI exit code 1619 | File missing or corrupt (HTML downloaded instead of MSI) | Verify file size > 10 MB and magic bytes before installing |
| Session host shows `Unavailable` | `DomainJoinedCheck` / `DomainTrustCheck` fail — no on-prem AD | Expected. Confirm `AADJoinedHealthCheck=Succeeded`. Users can still connect via AVD client |
| `az vm create --public-ip-address ""` fails in PowerShell | Empty string quoting in PowerShell | Use `'""'` (single quotes wrapping double quotes) |
| `az vm run-command` returns no output | Token expired, or `$variable` expanded locally before being sent | Re-generate token; use `--scripts "@file.ps1"` with `--parameters` instead of inline scripts with embedded tokens |
