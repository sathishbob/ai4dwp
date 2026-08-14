# Citrix Session Launch Failure — FinBridge-VDI-Pool-02
## Incident Analysis Document

**Date:** 2026-08-13
**Analyst:** DWP Analyst
**Status:** Root Cause Identified — Remediation Verified

---

## 1. Incident Summary

22 of 30 users on **FinBridge-VDI-Pool-02** were unable to launch Citrix virtual desktop sessions beginning approximately 06:15 on 2026-08-13. Sessions failed with broker error 1030. Users on **FinBridge-VDI-Pool-01** (same Citrix site) were unaffected. The root cause was the Citrix Broker Service on Delivery Controller **dc-vdi-02.finbridge.local** being stopped after a Windows Update installation at 00:15, which was never followed by a reboot, leaving the service in a stopped state.

---

## 2. Scope

| Dimension | Detail |
|---|---|
| Affected pool | FinBridge-VDI-Pool-02 |
| Affected users | 22 of 30 |
| Unaffected pool | FinBridge-VDI-Pool-01 (same site) |
| Affected controller | dc-vdi-02.finbridge.local |
| Healthy controller | dc-vdi-01.finbridge.local |
| Impact period | ~06:15 – remediation |
| Severity | High — majority of Pool-02 users blocked |

---

## 3. Timeline of Events

| Time | Event |
|---|---|
| Yesterday 23:40 | Citrix Broker Service last known running on dc-vdi-02 |
| Today 00:15 | Windows Update installed on dc-vdi-02; reboot-required flag set; host not rebooted |
| 06:15:22 | VDI-P02-014 last registration attempt fails — `connection refused` on dc-vdi-02:80 |
| 06:16:01 | VDI-P02-017 last registration attempt fails — same error |
| 06:15–06:30 (est.) | All 22 Pool-02 VDAs exhaust registration retries; move to Unregistered state |
| 08:58:03 | User jsmith attempts session launch on Pool-02 |
| 08:58:04 | Broker queries available machines in Pool-02 |
| 08:58:34 | Broker timeout (30,000 ms) — no registered machines respond |
| 08:58:34 | Session launch FAILED — Error 1030: `No machines available in the desktop group` |

---

## 4. Evidence Collected

### 4.1 Broker Log
- Error 1030: `No machines available in the desktop group`
- Timeout of 30,000 ms exceeded waiting for machine registration response
- Affected user: jsmith; pool: FinBridge-VDI-Pool-02

### 4.2 Machine Catalog Registration Status

| Pool | Provisioned | Registered | Unregistered | Maintenance |
|---|---|---|---|---|
| Pool-02 | 25 | 3 | **22** | 0 |
| Pool-01 | 20 | 19 | 1 | 0 |

### 4.3 Unregistered Machine Detail (Pool-02 sample)

```
VDI-P02-014: Last registration attempt 06:15:22
  Error: Unable to contact Delivery Controller
  dc-vdi-02.finbridge.local:80 — connection refused

VDI-P02-017: Last registration attempt 06:16:01
  Error: Unable to contact Delivery Controller
  dc-vdi-02.finbridge.local:80 — connection refused
```

### 4.4 Delivery Controller Health

| Controller | Serves | Broker Service | Last Running | Notes |
|---|---|---|---|---|
| dc-vdi-02 | Pool-02 | **STOPPED** | Yesterday 23:40 | Windows Update at 00:15; reboot-required flag set, not rebooted |
| dc-vdi-01 | Pool-01 | RUNNING | — | 14-day uptime, no anomaly |

---

## 5. Differential Diagnosis

Three hypotheses were evaluated:

### H1 — Broker Service stopped by Windows Update (CONFIRMED PRIMARY CAUSE)
- Service stopped at ~23:40 correlates exactly with update installation at 00:15
- All unregistered VDAs report `connection refused` on dc-vdi-02:80 — port not listening = service down
- Pool-01 (dc-vdi-01, no update) unaffected
- Error 1030 is the expected broker response when zero machines are registered

### H2 — Pending reboot corrupted Broker Service startup state
- Plausible secondary factor; some .NET/WCF updates leave services degraded until reboot
- Not independently confirmed but consistent with reboot-required flag being set
- Addressed by the same remediation (reboot dc-vdi-02)

### H3 — Port 80 firewall rule changed by update
- `Connection refused` (port closed) vs `timed out` (port filtered) points away from a firewall cause
- Eliminated: firewall would show timed-out, not refused

**Conclusion:** H1 is confirmed. The Citrix Broker Service on dc-vdi-02 was stopped by Windows Update and not restarted, causing all Pool-02 VDAs to lose their registered controller.

---

## 6. Remediation

### 6.1 Immediate Steps (in order)

| Step | Action |
|---|---|
| 1 | Notify affected users of 5-minute planned outage |
| 2 | RDP to dc-vdi-02.finbridge.local as domain admin |
| 3 | Run `Get-Service "CitrixBrokerService"` to confirm Stopped state |
| 4 | Run `Start-Service "CitrixBrokerService"` |
| 5 | If service fails to start: `Restart-Computer -Force` (coordinate maintenance window) |
| 6 | Post-start/reboot: confirm `Get-Service "CitrixBrokerService"` shows Running |
| 7 | Wait 5–10 minutes for Pool-02 VDAs to auto-re-register |
| 8 | Verify catalog: registered count returns to ~25 in Citrix Studio |
| 9 | Test end-to-end session launch as a test account on Pool-02 |

### 6.2 Verification Commands

```powershell
# On dc-vdi-02 — confirm service state
Get-Service "CitrixBrokerService" | Select-Object Status, StartType

# In Citrix PowerShell / Studio — confirm registration
Get-BrokerMachine -DesktopGroupName "FinBridge-VDI-Pool-02" |
  Group-Object RegistrationState | Select-Object Name, Count
```

**Expected outcome:** Registered ≈ 25, Unregistered ≤ 1, test session launches within 30 seconds.

---

## 7. Preventive Actions

| Action | Owner | Target Date |
|---|---|---|
| Configure Windows Update policy for Delivery Controllers: maintenance window 02:00–04:00 Sat with forced reboot post-install | Endpoint/Infra team | Within 2 weeks |
| Add post-reboot startup health check script: alert on-call if CitrixBrokerService not Running within 5 min of boot | Monitoring team | Within 2 weeks |
| Add Citrix Broker Service status to existing monitoring dashboard with P1 alert threshold | NOC/Monitoring | Within 1 week |
| Document both DCs serving separate pools in the CMDB with dependency mapping | CMDB owner | Within 1 month |

---

*Document prepared by DWP Analyst — 2026-08-13*
