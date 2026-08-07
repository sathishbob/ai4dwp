Title: AVD Black Screen Post-Login - POOL-FIN-01 Runbook
Version: 1.0
Date: 07/08/2026
Author: Sathishbabu
Reviewed: self
Status: draft
Change: initaila version from RCA

# Runbook: AVD Black Screen Post-Login - POOL-FIN-01

Date: 2026-08-07
Incident pattern covered: Black screen and disconnect/reconnect loop after login on POOL-FIN-01
Source incident: 2026-08-06 outage (resolved at 10:00)

## 1) Prerequisites

1. Confirm you are assigned as incident engineer for Azure Virtual Desktop finance pools.
- Expected result: You have ownership of the active incident ticket and change record.

2. Obtain Azure role access with host pool write permissions for POOL-FIN-01.
- Expected result: In Azure Portal, you can open POOL-FIN-01 and see host session host management controls.
- Permission: [ELEVATED] Azure role such as Desktop Virtualization Contributor (or equivalent with session host update rights).

3. Obtain rights to read Windows Event Logs on all FIN-01 session hosts.
- Expected result: You can open Event Viewer on each target host and read Application/System and TerminalServices logs.
- Permission: [ELEVATED] Local Administrator or delegated Event Log Readers on session hosts.

4. Obtain rights to restart session hosts in POOL-FIN-01.
- Expected result: Restart action is available in Azure Portal for each FIN-01 session host.
- Permission: [ELEVATED] Compute/session host restart rights.

5. Obtain rights to modify image assignment or host pool image baseline used by POOL-FIN-01.
- Expected result: You can select and apply the known-good image baseline in the change workflow.
- Permission: [ELEVATED] Image/compute management rights for AVD host provisioning.

6. Open these tools before starting remediation.
- Expected result: Azure Portal, Event Viewer, and ticketing/change system are open and authenticated.

7. Identify the known-good baseline image ID and approved graphics driver version from the last stable release.
- Expected result: You have exact baseline identifiers documented in the ticket before any change.

8. Identify an unaffected control pool host in POOL-FIN-02 for side-by-side comparison.
- Expected result: You have at least one FIN-02 host name recorded for validation checks.

## 2) Procedure

1. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, select all hosts, click Drain mode, and set Allow new sessions to No.
- Expected result: Each FIN-01 host shows Allow new sessions = No.
- Permission: [ELEVATED]

2. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions, select all sessions, and click Log off.
- Expected result: User sessions grid shows 0 active sessions for POOL-FIN-01.
- Permission: [ELEVATED]

3. On one affected host (example: SHFIN-01-A), open Event Viewer at Windows Logs > Application, click Filter Current Log, and set Event IDs to 1000 with Logged = Last 2 hours.
- Expected result: At least one Event 1000 entry shows Faulting application name = dwm.exe and Faulting module name = igdumd64.dll.

4. On the same host, open Event Viewer at Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational, filter Event ID 9009 for Last 2 hours.
- Expected result: At least one Event 9009 timestamp is within 60 seconds of a matching Event 1000 timestamp.

5. On the same host, open Event Viewer at Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational, filter Event ID 40 for Last 2 hours.
- Expected result: At least one Event 40 timestamp is within 60 seconds of the same crash sequence.

6. Add one evidence block to the incident ticket with host name and exact timestamps for Event 1000, Event 9009, and Event 40.
- Expected result: Ticket contains a single correlated sequence in this format: Host, Event ID, Time, Username/Session ID if present.

7. On one control host in POOL-FIN-02, open Event Viewer at Windows Logs > Application and filter Event ID 1000 for Last 2 hours.
- Expected result: 0 entries where Faulting application name = dwm.exe and Faulting module name = igdumd64.dll.

8. In Azure Portal, open the image version workflow used for POOL-FIN-01 deployment and set the source image to the recorded known-good image ID.
- Expected result: The deployment/configuration page for POOL-FIN-01 shows the exact known-good image ID value recorded in the ticket.
- Permission: [ELEVATED]

9. On each FIN-01 host, run this command in elevated PowerShell to verify driver version: Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "Intel.*Graphics" } | Select-Object DeviceName, DriverVersion.
- Expected result: Output shows Intel graphics DriverVersion exactly matches the approved version from Prerequisite 7 on every FIN-01 host.
- Permission: [ELEVATED]

10. On any host where version mismatch is found, install the approved Intel graphics driver package from the gold image artifact repository.
- Expected result: A repeat of Step 9 on that host returns the approved DriverVersion exactly.
- Permission: [ELEVATED]

11. In Azure Portal at Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, restart each host one at a time using Restart.
- Expected result: For each host, Status returns to Available before restarting the next host.
- Permission: [ELEVATED]

12. In Azure Portal at POOL-FIN-01 > Session hosts, set Allow new sessions = Yes on exactly one canary host.
- Expected result: One host shows Allow new sessions = Yes and all remaining FIN-01 hosts stay at No.
- Permission: [ELEVATED]

13. Launch Remote Desktop client, connect a standard test user to POOL-FIN-01, and complete sign-in to the canary host.
- Expected result: Desktop is fully rendered in 30 seconds, Start menu opens, and no disconnect occurs for 5 minutes.

14. On the canary host, re-run Step 3, Step 4, and Step 5 filters for Logged = Last 15 minutes.
- Expected result: 0 new Event 1000 entries with dwm.exe/igdumd64.dll and 0 new linked Event 9009 and Event 40 entries after test login time.

15. In Azure Portal at POOL-FIN-01 > Session hosts, set Allow new sessions = Yes on the remaining FIN-01 hosts.
- Expected result: Every FIN-01 host shows Allow new sessions = Yes and Status = Available.
- Permission: [ELEVATED]

16. Post a status update in the incident communication channel and ticket with the canary pass timestamp and reopen timestamp.
- Expected result: A timestamped message is visible in both systems confirming controlled reopen completed.

## 3) Verification

1. In Azure Portal, open Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions and watch new sessions for 30 minutes after Step 15.
- Expected result: At least 10 new sessions reach State = Active with no rapid disconnect/reconnect churn.

2. On each FIN-01 host, open Event Viewer > Windows Logs > Application and filter Event ID 1000 for Logged = Last 30 minutes.
- Expected result: 0 events where Faulting application name = dwm.exe and Faulting module name = igdumd64.dll.

3. On each FIN-01 host, open Event Viewer > Applications and Services Logs > Microsoft > Windows > Desktop Window Manager > Operational and filter Event ID 9009 for Last 30 minutes.
- Expected result: 0 Event 9009 entries tied to user login windows in the last 30 minutes.

4. On each FIN-01 host, open Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational and filter Event ID 40 for Last 30 minutes.
- Expected result: Event 40 count on each FIN-01 host is less than or equal to 2 in 30 minutes and no user shows 2 or more disconnects within a 5-minute window.

5. In Azure Portal, compare POOL-FIN-01 and POOL-FIN-02 session behavior using their User sessions views for the same 30-minute window.
- Expected result: FIN-01 disconnect count is not more than 2 higher than FIN-02 over the same 30-minute window.

6. In service desk and incident chat, search messages created after reopen timestamp for keywords "black screen" and "disconnect" with pool reference FIN-01.
- Expected result: 0 new confirmed user-impact reports linked to FIN-01 during the 30-minute validation window.

7. Attach evidence to the incident ticket: screenshots of User sessions, event filter result counts, hostnames checked, and validation start/end timestamps.
- Expected result: Ticket contains complete closure evidence and is ready for incident manager approval.

## 4) Rollback

Trigger this rollback immediately if black screen/disconnect behavior appears after reopening FIN-01. Complete Steps 1 to 6 within 3 minutes.

1. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts, select all hosts, click Drain mode, and set Allow new sessions = No.
- Expected result: Every FIN-01 host shows Allow new sessions = No within 30 seconds.
- Permission: [ELEVATED]

2. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions, select all sessions, and click Log off.
- Expected result: User sessions grid for POOL-FIN-01 shows 0 active sessions.
- Permission: [ELEVATED]

3. In Azure Portal, go to Azure Virtual Desktop > Host pools > POOL-FIN-02 > Session hosts, confirm at least one host shows Allow new sessions = Yes and Status = Available.
- Expected result: Users can land on FIN-02 immediately.

4. Post this exact message in incident chat and service desk major incident channel: "ROLLBACK ACTIVE  - FIN-01 blocked for new sessions. Use POOL-FIN-02 now. Next update in 15 minutes."
- Expected result: Timestamped user redirection notice is visible in both channels.

5. In Azure Portal, open Azure Virtual Desktop > Host pools > POOL-FIN-01 > User sessions and refresh once.
- Expected result: Session count remains 0 after refresh, confirming containment is holding.

6. In the incident ticket, set status to Mitigated via Rollback and add rollback start time.
- Expected result: Ticket audit trail shows rollback trigger time and containment state.

7. In Azure Portal, open the deployment/image configuration used by POOL-FIN-01 and set image source to the last known-good image ID from Prerequisite 7.
- Expected result: Configuration page shows the exact known-good image ID.
- Permission: [ELEVATED]

8. On each FIN-01 host, run this elevated PowerShell command: Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceName -match "Intel.*Graphics" } | Select-Object DeviceName, DriverVersion.
- Expected result: Any host not matching approved DriverVersion is identified for correction.
- Permission: [ELEVATED]

9. On each non-compliant host, install the approved Intel graphics driver package from the gold image artifact repository.
- Expected result: Re-running Step 8 on that host shows the approved DriverVersion exactly.
- Permission: [ELEVATED]

10. In Azure Portal, go to POOL-FIN-01 > Session hosts and restart FIN-01 hosts one at a time.
- Expected result: Each restarted host returns to Status = Available before the next restart.
- Permission: [ELEVATED]

11. Keep FIN-01 in Drain mode until Procedure Step 13 and Procedure Step 14 pass on one canary host.
- Expected result: No user traffic returns to FIN-01 until canary checks are clean.
- Permission: [ELEVATED]

## 5) Notes

- Edge case: If Event ID 1000 exists but module is not igdumd64.dll, stop this runbook and branch to a separate display stack investigation.
- Edge case: If only one host in FIN-01 shows failures, keep all other FIN-01 hosts in service and isolate just the failing host in Drain Mode.
- Warning: Do not reopen all FIN-01 hosts at once after remediation; reopen one canary host first.
- Warning: Do not close incident based only on successful reconnect attempts; require clean event logs and sustained successful logins.
- Related incidents/documents:
  - day4/incident-rca-avd-black-screen-fin01.md
  - day4/known-error-record-avd-black-screen-fin01.md
  - day4/incident-closure-note-avd-black-screen.md
  - day4/avd-incident-black-screen-analysis.md

## Quick Signature Reference

- Application Event ID 1000: Faulting application dwm.exe, faulting module igdumd64.dll, often exception 0xc0000005.
- Desktop Window Manager Event ID 9009: DWM exited.
- TerminalServices-LocalSessionManager Event ID 40: Session disconnected.
- Typical failure sequence: Event 21 (logon success) -> Event 1000 -> Event 40 -> Event 9009.
