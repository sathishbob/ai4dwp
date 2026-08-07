Version: v 1.0
Date: 07/08/2026
Status: Draft

# L2/L3 KB: AVD Black Screen Post-Login - POOL-FIN-01

## Background
Azure Virtual Desktop (AVD) provides shared finance desktops for business-critical daily work. POOL-FIN-01 and POOL-FIN-02 are comparable finance pools used to deliver user sessions. If desktop rendering fails during sign-in, users cannot reach a usable workspace, causing immediate productivity impact and service desk load.

This KB covers a known FIN-01 failure pattern where users authenticate successfully but desktop rendering fails shortly after logon.

## Symptom
Engineer observations:
- Incident concentrated in POOL-FIN-01.
- POOL-FIN-02 remains stable in the same period.
- Multiple short-lived logons and reconnect/disconnect cycles on affected FIN-01 hosts.

User reports:
- Black screen immediately after sign-in.
- Some sessions recover after about 30 seconds.
- Some sessions disconnect and reconnect repeatedly.
- Users in the other finance pool report normal behavior.

## Root Cause
Specific cause:
- Desktop Window Manager process dwm.exe crashes in Intel module igdumd64.dll on FIN-01 hosts after the updated baseline was applied to POOL-FIN-01.

Evidence that confirms cause:
- Application log Event ID 1000 on FIN-01 hosts with:
  - Faulting application name: dwm.exe
  - Faulting module name: igdumd64.dll
  - Exception code: commonly 0xc0000005
- Desktop Window Manager Event ID 9009 appears in the same incident window.
- TerminalServices-LocalSessionManager Event ID 40 appears in the same incident window.
- Typical sequence on affected host: Event ID 21 logon success -> Event ID 1000 -> Event ID 40 -> Event ID 9009.
- Control comparison: FIN-02 host shows clean startup behavior and no matching Event ID 1000 signature in the same timeframe.

## Detection
Target time: Complete detection in under 3 minutes.

Run PowerShell checks first for speed, then use Event Viewer only if command output is unclear.

1. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts and copy one affected host name (example: SHFIN-01-A).
Expected result: One FIN-01 target host is selected for event extraction.

2. Open PowerShell on the selected FIN-01 host and run this command for Application log Event 1000:
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=(Get-Date).AddHours(-2)} | Where-Object { $_.Message -match 'Faulting application name:\s*dwm.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64.dll' } | Select-Object -First 5 TimeCreated, Id, ProviderName, Message
Expected result: At least one Event 1000 record is returned showing Faulting application name dwm.exe and Faulting module name igdumd64.dll.

3. On the same FIN-01 host, run this command for Desktop Window Manager Operational Event 9009:
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=(Get-Date).AddHours(-2)} | Select-Object -First 5 TimeCreated, Id, ProviderName, Message
Expected result: At least one Event 9009 record is returned in the same incident window.

4. On the same FIN-01 host, run this command for TerminalServices-LocalSessionManager Operational Event 40:
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=40; StartTime=(Get-Date).AddHours(-2)} | Select-Object -First 5 TimeCreated, Id, ProviderName, Message
Expected result: At least one Event 40 record is returned near the Event 1000 and Event 9009 times.

5. On the same FIN-01 host, run this command for TerminalServices-LocalSessionManager Operational Event 21:
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=21; StartTime=(Get-Date).AddHours(-2)} | Select-Object -First 5 TimeCreated, Id, ProviderName, Message
Expected result: Event 21 logon success appears before the Event 1000 -> Event 40 -> Event 9009 sequence.

6. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts and copy one control host name.
Expected result: One FIN-02 control host is selected.

7. On the FIN-02 control host, run this command for healthy baseline Event 9011 in Desktop Window Manager Operational log:
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9011; StartTime=(Get-Date).AddHours(-2)} | Select-Object -First 5 TimeCreated, Id, ProviderName, Message
Expected result: Event 9011 is present, indicating normal DWM startup behavior on control pool.

8. On the FIN-02 control host, run this command for Application log Event 1000 and inspect for dwm.exe plus igdumd64.dll:
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=(Get-Date).AddHours(-2)} | Where-Object { $_.Message -match 'Faulting application name:\s*dwm.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64.dll' } | Select-Object -First 5 TimeCreated, Id, ProviderName, Message
Expected result: No matching Event 1000 records are returned on FIN-02 control host.

9. If command output is ambiguous, open Event Viewer and check exact logs directly:
- Application log: Event Viewer > Windows Logs > Application, filter Event ID 1000.
- Desktop Window Manager log: Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational, filter Event IDs 9009 and 9011.
- TerminalServices log: Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational, filter Event IDs 40 and 21.
Expected result: GUI view confirms the same signature and baseline results from PowerShell.

Diagnosis threshold:
- Confirm this incident only when FIN-01 shows Event 1000 (dwm.exe faulting module igdumd64.dll) with nearby Event 9009 and Event 40, while FIN-02 shows healthy Event 9011 and no matching Event 1000 signature.

## Resolution
Execute in order.

0. In Azure CLI, set context variables once.
Command:
az account set --subscription "<SUBSCRIPTION_NAME_OR_ID>"
$rg = "<RESOURCE_GROUP_NAME>"
$hp = "POOL-FIN-01"
Expected result: Commands in the next steps run against the intended subscription, resource group, and host pool.

1. In Azure Portal go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, select all session hosts, choose Set drain mode, set Allow new sessions = No, then Save.
CLI alternative:
az desktopvirtualization session-host list --resource-group $rg --host-pool-name $hp --query "[].name" -o tsv | ForEach-Object { az desktopvirtualization session-host update --resource-group $rg --host-pool-name $hp --name (Split-Path $_ -Leaf) --allow-new-session false }
Expected result: In Session hosts grid, every FIN-01 host shows Allow new sessions = No.

2. In Azure Portal go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions, select all, choose Log off.
CLI alternative:
az desktopvirtualization user-session list --resource-group $rg --host-pool-name $hp --query "[].{h:sessionHostName,s:id}" -o json | ConvertFrom-Json | ForEach-Object { az desktopvirtualization user-session delete --resource-group $rg --host-pool-name $hp --session-host-name $_.h --user-session-id $_.s --yes }
Expected result: User sessions list returns 0 active sessions.

3. In Azure Portal go to Resource groups > <RESOURCE_GROUP_NAME> > Deployments > <FIN01_HOST_DEPLOYMENT_NAME> > Parameters and set imageVersionId (or imageReferenceId) to the last known-good value, then run Redeploy.
CLI alternative:
az deployment group create --resource-group $rg --template-file "<FIN01_DEPLOYMENT_TEMPLATE.json>" --parameters hostPoolName="POOL-FIN-01" imageVersionId="<KNOWN_GOOD_IMAGE_VERSION_RESOURCE_ID>"
Expected result: Deployment parameters show the known-good image version/resource ID and deployment state is Succeeded.

4. In Azure Portal go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts and export/copy host names, then remotely run the driver check command from Detection on each host.
Command on host:
Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "Intel.*Graphics" } | Select-Object DeviceName, DriverVersion
Expected result: You have current Intel display driver version for each FIN-01 host.

5. On each non-compliant host, install the approved Intel package from the gold repository and rerun the command in Step 4.
Expected result: Every FIN-01 host now shows approved DriverVersion.

6. In Azure Portal go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, select each host one by one, choose Restart.
CLI alternative:
az desktopvirtualization session-host list --resource-group $rg --host-pool-name $hp --query "[].name" -o tsv | ForEach-Object { $vm=(Split-Path $_ -Leaf) -replace '\..*$',''; az vm restart --resource-group $rg --name $vm }
Expected result: Each host returns to Status = Available before the next host restart.

7. In Azure Portal go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, open one canary host, set Allow new sessions = Yes.
CLI alternative:
az desktopvirtualization session-host update --resource-group $rg --host-pool-name $hp --name "<CANARY_SESSION_HOST_NAME>" --allow-new-session true
Expected result: Only canary host shows Allow new sessions = Yes.

8. Run one standard-user sign-in test to the canary host.
Expected result: Desktop appears within 30 seconds and remains stable for 5 minutes.

9. Re-run Detection commands for Event 1000, 9009, and 40 on the canary host for Last 15 minutes.
Expected result: No new Event 1000 with dwm.exe/igdumd64.dll and no linked new 9009 or 40 events.

10. In Azure Portal go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, set all remaining hosts Allow new sessions = Yes.
CLI alternative:
az desktopvirtualization session-host list --resource-group $rg --host-pool-name $hp --query "[].name" -o tsv | ForEach-Object { az desktopvirtualization session-host update --resource-group $rg --host-pool-name $hp --name (Split-Path $_ -Leaf) --allow-new-session true }
Expected result: All FIN-01 hosts show Allow new sessions = Yes and Status = Available.

## Verification
1. In Azure Portal go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions and monitor for 30 minutes.
CLI alternative:
az desktopvirtualization user-session list --resource-group $rg --host-pool-name "POOL-FIN-01" --query "[?sessionState=='Active'] | length(@)"
Expected result: At least 10 new sessions reach State = Active with no repeated short reconnect loops.

2. On each FIN-01 host, run the Detection Event 1000 command against Application log for Last 30 minutes.
Command:
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=(Get-Date).AddMinutes(-30)} | Where-Object { $_.Message -match 'Faulting application name:\s*dwm.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64.dll' }
Expected result: Command returns no rows.

3. On each FIN-01 host, run Event 9009 query for Last 30 minutes.
Command:
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=(Get-Date).AddMinutes(-30)}
Expected result: Command returns no rows.

4. On each FIN-01 host, run Event 40 query for Last 30 minutes.
Command:
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=40; StartTime=(Get-Date).AddMinutes(-30)}
Expected result: Per host count is less than or equal to 2 and no user has 2 or more events inside 5 minutes.

5. In Azure Portal compare Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions with Azure Virtual Desktop > Host pools > POOL-FIN-02 > User sessions for same 30-minute window.
CLI alternative:
$fin01=(az desktopvirtualization user-session list --resource-group $rg --host-pool-name "POOL-FIN-01" --query "length(@)" -o tsv)
$fin02=(az desktopvirtualization user-session list --resource-group $rg --host-pool-name "POOL-FIN-02" --query "length(@)" -o tsv)
Expected result: FIN-01 disconnect behavior does not exceed FIN-02 by more than 2 events.

## Rollback
Use immediately if post-fix behavior is worse.

1. In Azure Portal go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, select all, set Allow new sessions = No.
CLI alternative:
az desktopvirtualization session-host list --resource-group $rg --host-pool-name "POOL-FIN-01" --query "[].name" -o tsv | ForEach-Object { az desktopvirtualization session-host update --resource-group $rg --host-pool-name "POOL-FIN-01" --name (Split-Path $_ -Leaf) --allow-new-session false }
Expected result: All FIN-01 hosts stop accepting new sessions.

2. In Azure Portal go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions, select all, Log off.
CLI alternative:
az desktopvirtualization user-session list --resource-group $rg --host-pool-name "POOL-FIN-01" --query "[].{h:sessionHostName,s:id}" -o json | ConvertFrom-Json | ForEach-Object { az desktopvirtualization user-session delete --resource-group $rg --host-pool-name "POOL-FIN-01" --session-host-name $_.h --user-session-id $_.s --yes }
Expected result: Active FIN-01 sessions return to 0.

3. In Azure Portal go to Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts, verify at least one host has Status = Available and Allow new sessions = Yes.
CLI alternative:
az desktopvirtualization session-host list --resource-group $rg --host-pool-name "POOL-FIN-02" --query "[?status=='Available']"
Expected result: FIN-02 is ready as alternate capacity.

4. In Azure Portal go to Resource groups > <RESOURCE_GROUP_NAME> > Deployments > <FIN01_HOST_DEPLOYMENT_NAME> > Parameters, set imageVersionId (or imageReferenceId) to known-good value, then run Redeploy.
CLI alternative:
az deployment group create --resource-group $rg --template-file "<FIN01_DEPLOYMENT_TEMPLATE.json>" --parameters hostPoolName="POOL-FIN-01" imageVersionId="<KNOWN_GOOD_IMAGE_VERSION_RESOURCE_ID>"
Expected result: Deployment completes Succeeded and parameter value reflects known-good baseline.

5. Re-run driver check and restore approved version on any non-compliant FIN-01 host.
Command:
Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "Intel.*Graphics" } | Select-Object DeviceName, DriverVersion
Expected result: Every FIN-01 host shows approved DriverVersion.

6. In Azure Portal go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts and restart hosts one by one.
CLI alternative:
az desktopvirtualization session-host list --resource-group $rg --host-pool-name "POOL-FIN-01" --query "[].name" -o tsv | ForEach-Object { $vm=(Split-Path $_ -Leaf) -replace '\..*$',''; az vm restart --resource-group $rg --name $vm }
Expected result: Each host returns to Status = Available.

7. Keep FIN-01 closed to new sessions until one canary host passes Detection criteria with no recurrence for 30 minutes.
Expected result: No repeated outage during recovery window.

## Preventive
1. Canary release policy in change workflow (existing control, strengthened).
Owner: Change manager; Timing: During deployment; Type: Manual (candidate for automation via release pipeline stage [REQUIRES: staged rollout process]).
Pass/Fail: Pass only if 30-minute canary window shows Event 1000 (dwm.exe+igdumd64.dll)=0 and Event 9009=0 and Event 40<=2; fail if any threshold breached.
If fail: Stop rollout, keep FIN-01 Allow new sessions=No, execute Rollback section, record CAB rejection reason.

2. Automated event signature alert (existing control, strengthened).
Owner: DWP engineer; Timing: During deployment and first 2 hours after deployment; Type: Automated [REQUIRES: Azure Monitor alert rules + log ingestion].
Pass/Fail: Pass if no alert where Event 1000 contains dwm.exe+igdumd64.dll and correlated Event 9009 or Event 40 occurs within 2 minutes; fail on first alert.
If fail: Auto-create incident P2, page on-call engineer, and set rollout state to hold.

3. Approved component version pinning (existing control, strengthened).
Owner: Image owner; Timing: Before deployment; Type: Manual with policy enforcement [REQUIRES: image baseline catalog/change control].
Pass/Fail: Pass if baseline manifest exactly matches approved Intel display version and AVD agent version; fail on any version drift.
If fail: Block image promotion and require change manager approval plus updated compatibility evidence.

4. FIN-01 vs FIN-02 rollout guardrail (existing control, strengthened).
Owner: Release engineer; Timing: After deployment (first 30 minutes); Type: Automated preferred, manual fallback [REQUIRES: comparative dashboard/query].
Pass/Fail: Pass if FIN-01 disconnect count minus FIN-02 disconnect count is <=2 and FIN-01 Event 1000 signature count=0; fail if delta >2 or signature >0.
If fail: Freeze rollout, keep/return FIN-01 to drain mode, trigger rollback workflow.

5. Automatic rollback trigger in release pipeline (existing control, strengthened).
Owner: Release engineer; Timing: During deployment and first 2 hours after deployment; Type: Automated [REQUIRES: pipeline integration with AVD controls].
Pass/Fail: Pass if no trigger thresholds met; fail if Event 1000 signature >=1 or Event 9009 >=3 on any FIN-01 host in 15 minutes.
If fail: Pipeline auto-sets Allow new sessions=No for FIN-01 and reverts to known-good baseline ID.

6. Pre-deployment smoke test gate (added gap control).
Owner: DWP engineer; Timing: Before deployment; Type: Manual (can be automated with scripted test logons [REQUIRES: test account + script runner]).
Pass/Fail: Pass if 3 test logons on candidate image complete with desktop render <=30s and Event 1000/9009/40 counts remain 0 in 15 minutes.
If fail: Do not deploy to production pools; return image to image owner for fix.

7. Post-deployment validation gate before change closure (added gap control).
Owner: Change manager; Timing: After deployment; Type: Manual checklist (automation via change API evidence pull is possible [REQUIRES: change system integration]).
Pass/Fail: Pass if Verification section evidence is attached: >=10 active sessions, no Event 1000 signature, no Event 9009, Event 40 within threshold.
If fail: Keep change open, maintain heightened monitoring, and execute rollback if user impact appears.

8. Knowledge and checklist update from incident learnings (added gap control).
Owner: Service desk lead; Timing: After deployment/incident closure; Type: Manual [REQUIRES: KB governance process].
Pass/Fail: Pass if runbook, L1 KB, and triage checklist are updated within 2 business days and approved by DWP engineer.
If fail: Open process-nonconformance task and block similar change templates until documents are updated.

## Related
- day4/incident-rca-avd-black-screen-fin01.md
- day4/known-error-record-avd-black-screen-fin01.md
- day4/avd-incident-black-screen-analysis.md
- day4/incident-closure-note-avd-black-screen.md
- day5/runbook-avd-black-screen-fin01.md
- day5/kb-l1-black-screen-after-login.md
