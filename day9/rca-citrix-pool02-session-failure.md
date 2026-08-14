# Root Cause Analysis — Citrix VDI Session Launch Failure
## FinBridge-VDI-Pool-02 | 2026-08-13

**RCA Reference:** INC-2026-0813-CITRIX-P02
**Date of Incident:** 2026-08-13
**Date of RCA:** 2026-08-13
**Analyst:** DWP Analyst
**Status:** CLOSED — Root Cause Confirmed, Remediation Defined

---

## 1. Incident Statement

From approximately 06:15 on 2026-08-13, 22 of 30 users on FinBridge-VDI-Pool-02 were unable to launch Citrix virtual desktop sessions. Session launch failed with broker error 1030. FinBridge-VDI-Pool-01 (same Citrix site, different Delivery Controller) was unaffected throughout.

---

## 2. Impact Summary

| Metric | Value |
|---|---|
| Users impacted | 22 of 30 (Pool-02) |
| Users unaffected | 8 (Pool-02) + all Pool-01 users |
| Start of impact | ~06:15 (first failed VDA registration) |
| User-facing failure observed | 08:58 (first logged broker error) |
| Business function affected | Remote desktop access for FinBridge Pool-02 users |

---

## 3. Timeline

| Time | Event | Source |
|---|---|---|
| Yesterday 23:40 | Citrix Broker Service last confirmed running on dc-vdi-02 | DC health log |
| Today 00:15 | Windows Update installed on dc-vdi-02; reboot-required flag set; host **not** rebooted | DC health log |
| 00:15–06:15 | Citrix Broker Service stopped (exact stop time between 23:40 and 06:15) | Inferred from service state + update time |
| 06:15:22 | VDI-P02-014 registration attempt fails: `connection refused` on dc-vdi-02:80 | VDA registration log |
| 06:16:01 | VDI-P02-017 registration attempt fails: `connection refused` on dc-vdi-02:80 | VDA registration log |
| 06:15–06:30 (est.) | All 22 Pool-02 VDAs exhaust retries; move to Unregistered state | Machine catalog status |
| 08:58:03 | User jsmith attempts session launch, Pool-02 | Broker log |
| 08:58:04 | Broker queries Pool-02 for available registered machines | Broker log |
| 08:58:34 | Broker timeout at 30,000 ms — no machines respond | Broker log |
| 08:58:34 | Session launch FAILED — Error 1030: `No machines available in the desktop group` | Broker log |

---

## 4. Supporting Evidence

### 4.1 Broker Error
```
[08:58:34] Session launch FAILED: error 1030
           'No machines available in the desktop group'
```
Error 1030 is the standard Citrix broker response when a desktop group has zero registered machines available for assignment.

### 4.2 Machine Catalog State at Time of Incident

| Pool | Provisioned | Registered | Unregistered | Maintenance |
|---|---|---|---|---|
| FinBridge-VDI-Pool-02 | 25 | 3 | **22** | 0 |
| FinBridge-VDI-Pool-01 | 20 | 19 | 1 | 0 |

Pool-01's single unregistered machine is within normal tolerance and unrelated to this incident.

### 4.3 VDA Registration Failures (Pool-02 sample)

```
VDI-P02-014 | 06:15:22 | FAILED
  Unable to contact Delivery Controller
  dc-vdi-02.finbridge.local:80 — connection refused

VDI-P02-017 | 06:16:01 | FAILED
  Unable to contact Delivery Controller
  dc-vdi-02.finbridge.local:80 — connection refused
```

`Connection refused` (as opposed to `timed out`) confirms the port was not listening — the service was not running, not blocked by a firewall.

### 4.4 Delivery Controller Health at Time of Investigation

| Controller | Serves | Broker Service | Last Running | Notes |
|---|---|---|---|---|
| dc-vdi-02 | Pool-02 | **STOPPED** | Yesterday 23:40 | Windows Update 00:15; reboot flag set; not rebooted |
| dc-vdi-01 | Pool-01 | RUNNING | — | 14-day uptime, no anomaly |

---

## 5. Root Cause

**Primary root cause:**
Windows Update installed on `dc-vdi-02.finbridge.local` at 00:15 on 2026-08-13 stopped the Citrix Broker Service as part of the update process. Because the host was not rebooted after the update (reboot-required flag was set but not acted upon), the Broker Service was never restarted. From that point, all Pool-02 VDAs attempting to register with dc-vdi-02 received `connection refused` on port 80 and transitioned to Unregistered state, making them unavailable for session brokering.

**Contributing factor:**
No automated monitoring alert existed for the Citrix Broker Service stopped state, meaning the condition went undetected from ~00:15 until users reported failures at ~09:00 — approximately 9 hours.

---

## 6. Five Whys Analysis

| Why | Answer |
|---|---|
| **Why** did users fail to launch sessions? | The broker returned error 1030 — no machines were registered in Pool-02 |
| **Why** were no machines registered in Pool-02? | All 22 VDAs could not contact their Delivery Controller, dc-vdi-02, and moved to Unregistered state |
| **Why** could VDAs not contact dc-vdi-02? | The Citrix Broker Service on dc-vdi-02 was stopped, so port 80 was not listening (`connection refused`) |
| **Why** was the Citrix Broker Service stopped? | Windows Update installed at 00:15 stopped the service as part of its installation process and the host was not rebooted to restart it |
| **Why** was the host not rebooted after the update? | No enforced reboot policy existed for Delivery Controllers; the update set a reboot-required flag but left the actual reboot to manual action, which did not occur during the maintenance window |

**Root cause statement:** The absence of an enforced post-update reboot policy for Delivery Controllers allowed Windows Update to leave the Citrix Broker Service in a stopped state indefinitely, with no monitoring alert to detect or escalate the condition.

---

## 7. Remediation Steps

### 7.1 Immediate Fix (in order)

1. Notify affected users of planned 5-minute outage
2. RDP to `dc-vdi-02.finbridge.local` as domain admin
3. Confirm: `Get-Service "CitrixBrokerService"` — expected `Status: Stopped`
4. Attempt start: `Start-Service "CitrixBrokerService"`
5. If start fails (pending reboot): `Restart-Computer -Force` (coordinate 5-min maintenance window)
6. Post-start/reboot: confirm `Get-Service "CitrixBrokerService"` shows `Running`
7. Wait 5–10 minutes for Pool-02 VDAs to auto-re-register
8. Validate in Citrix Studio: Registered count returns to ~25
9. Test end-to-end session launch on Pool-02 as a test account

### 7.2 Verification Commands

```powershell
# On dc-vdi-02 — service state
Get-Service "CitrixBrokerService" | Select-Object Status, StartType

# Citrix PowerShell — Pool-02 registration
Get-BrokerMachine -DesktopGroupName "FinBridge-VDI-Pool-02" |
  Group-Object RegistrationState | Select-Object Name, Count
```

**Pass criteria:** Registered ≈ 25, Unregistered ≤ 1, test session launches successfully within 30 seconds.

---

## 8. Preventive Actions

### 8.1 Enforced Reboot Policy for Delivery Controllers

**Action:** Configure Windows Update policy (via GPO or Intune) for all Delivery Controllers to:
- Install updates during defined maintenance window (recommended: 02:00–04:00 Saturday)
- Force automatic reboot immediately after install completion (no indefinite deferral)
- Retry reboot if first attempt fails

**Owner:** Endpoint/Infrastructure team
**Target:** Within 2 weeks
**Rationale:** Directly eliminates the gap that allowed the service to remain stopped for 9 hours

### 8.2 Citrix Broker Service Monitoring Alert

**Action:** Add the Citrix Broker Service state on all Delivery Controllers to the monitoring platform. Configure a P1 alert if the service is not in `Running` state for more than 5 minutes after boot, or transitions to `Stopped` at any time.

**Owner:** NOC/Monitoring team
**Target:** Within 1 week
**Rationale:** Would have triggered an alert at ~00:20 rather than allowing a 9-hour silent failure

### 8.3 Post-Reboot Startup Validation Script

**Action:** Deploy a scheduled task on each Delivery Controller that runs 5 minutes after system boot, checks `CitrixBrokerService` status, and pages on-call if the service is not `Running`.

```powershell
# Example check (to be wrapped in a scheduled task)
$svc = Get-Service "CitrixBrokerService"
if ($svc.Status -ne "Running") {
    # Send alert to on-call channel / ITSM
    Write-EventLog -LogName Application -Source "CitrixHealthCheck" `
        -EventId 9001 -EntryType Error `
        -Message "CitrixBrokerService is NOT running on $env:COMPUTERNAME after reboot."
}
```

**Owner:** Monitoring/Infra team
**Target:** Within 2 weeks

### 8.4 CMDB Dependency Mapping

**Action:** Document that dc-vdi-01 serves Pool-01 and dc-vdi-02 serves Pool-02 as explicit CMDB service dependencies. Ensure any change affecting either DC triggers an impact assessment for its associated pool.

**Owner:** CMDB / Change Management
**Target:** Within 1 month

---

## 9. Lessons Learned

- Delivery Controllers are single points of failure for their associated pools. This site has two controllers but no cross-registration or failover configured for Pool-02; if dc-vdi-02 is unavailable, all Pool-02 VDAs become unreachable.
- Windows Update on infrastructure components requires a tested, enforced restart policy — not a deferred flag.
- Silent service failures at 00:15 went undetected for ~9 hours because no monitoring alert existed. Detection relied entirely on user-reported failures.

---

*RCA completed by DWP Analyst — 2026-08-13*
*Reference: INC-2026-0813-CITRIX-P02*
