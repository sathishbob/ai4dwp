# AVD Incident Analysis - Black Screen Post-Login

Date: 2026-08-06
Scope: POOL-FIN-01 affected, POOL-FIN-02 unaffected

## Scope Facts
- Symptom: Black screen after login; clears after ~30s for some users, persists for others.
- Who: ~40% of users on POOL-FIN-01.
- Control group: POOL-FIN-02 completely unaffected.
- Since: ~07:00 this morning.
- Change: Overnight image update to POOL-FIN-01 at 02:00. POOL-FIN-02 was not updated.

## Key Weighting Logic (Timing + Blast Radius)
The strongest clue is the pool split after the 02:00 change:
- Updated pool impacted (FIN-01)
- Non-updated pool clean (FIN-02)

This heavily favors causes introduced by, or tightly coupled to, the FIN-01 image update. It weakens causes that should hit both pools equally.

## Re-Ranked Most Likely Causes (Most Probable First)

1) Shell/AppReadiness/AppX startup regression in the FIN-01 image
- Why this fits:
  - Directly image-bound and consistent with pool-specific impact.
  - Explains black screen immediately post-login.
  - Mixed outcomes (clears for some, persists for others) can vary by user/profile state.
- Fastest single check:
  - Compare sign-in-time AppReadiness/Shell events on FIN-01 vs FIN-02 for errors/timeouts.

2) AVD agent/graphics stack regression introduced by updated image
- Why this fits:
  - Black screen is directly compatible with graphics/session init issues.
  - Driver/agent differences are commonly image-specific.
  - Unchanged pool unaffected supports this strongly.
- Fastest single check:
  - Version diff AVD agent + display/GPU drivers between pools; check FIN-01 sign-in display reset/timeouts.

3) FSLogix attach behavior changed via FIN-01 image/config drift
- Why this fits:
  - Symptom pattern matches delayed or failed profile attach (temporary vs persistent black screen).
  - Pool-specific if FIN-01 image changed FSLogix version/settings.
- Fastest single check:
  - Review FSLogix logs at sign-in on FIN-01 for attach delays/failures and compare against FIN-02.

4) Security/EDR startup contention introduced by updated image
- Why this fits:
  - New/changed endpoint controls in image can block userinit/explorer startup.
  - Pool-specific behavior aligns with update boundary.
- Fastest single check:
  - Inspect EDR/AV startup telemetry on FIN-01 for userinit/explorer delay compared to FIN-02.

5) Logon policy/script processing issue
- Why this fits less with timing clue:
  - Typical domain policy/script regressions often affect both pools.
  - FIN-02 being clean reduces likelihood unless targeting is host/image-specific.
- Fastest single check:
  - gpresult and logon-script runtime comparison for same user on FIN-01 vs FIN-02.

## Working Hypothesis (Non-Committal)
Primary hypothesis: the 02:00 image update introduced a post-login shell initialization regression on FIN-01, with user-state variability producing transient (~30s) versus persistent black screens.

Secondary hypotheses: graphics stack regression, FSLogix behavior drift, and security startup contention.

Status: Hypothesis only. No single root cause confirmed yet.

## Incident Evidence Addendum (Event Log-Based)

Date: 2026-08-06
Host evidence window: 07:00-07:30

### Event Details Used

Affected host: SHFIN-01-A (POOL-FIN-01)
- 07:02:10 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded (FINBRIDGE\mlopez, Session 3).
- 07:02:14 - Kernel-General Event 1: Host boot time 02:03:11 (post overnight update restart).
- 07:02:16 - Application Error Event 1000: `dwm.exe` faulting in `igdumd64.dll`, exception 0xc0000005.
- 07:02:17 - TerminalServices-LocalSessionManager Event 40: Session disconnected.
- 07:02:18 - Desktop Window Manager Event 9009: DWM exited with code 0x40010004.
- 07:02:44 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded (reconnect).
- 07:02:46 - Application Error Event 1000: `dwm.exe` faulting in `igdumd64.dll`, exception 0xc0000005.
- 07:02:47 - TerminalServices-LocalSessionManager Event 40: Session disconnected.
- 07:03:01 - Desktop Window Manager Event 9009: DWM exited with code 0x40010004.
- 07:03:10 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded (second reconnect, Session 4).
- 07:08:22 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded (FINBRIDGE\akapoor, Session 5).
- 07:08:24 - Application Error Event 1000: `dwm.exe` faulting in `igdumd64.dll`, exception 0xc0000005.

Comparison host: SHFIN-02-A (POOL-FIN-02, unaffected)
- 07:01:44 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded.
- 07:01:46 - Desktop Window Manager Event 9011: DWM started successfully.
- No Application Error Event 1000 entries in the same window.

### Hypothesis-by-Hypothesis Evidence Judgement

1) Shell/AppReadiness/AppX startup regression in FIN-01 image
- Judgement: Neutral to mildly contradicted.
- Determining events:
  - 07:02:16 and 07:02:46 - Event 1000 (`dwm.exe` crash in `igdumd64.dll`).
  - 07:02:18 and 07:03:01 - Event 9009 (DWM exit).
  - 07:01:46 on unaffected host - Event 9011 (DWM start success).

2) AVD agent/graphics stack regression introduced by updated image
- Judgement: Strongly supports.
- Determining events:
  - 07:02:16, 07:02:46, 07:08:24 - Event 1000 (`dwm.exe` faulting module `igdumd64.dll`, 0xc0000005).
  - 07:02:18 and 07:03:01 - Event 9009 (DWM exit after crash).
  - 07:02:17 and 07:02:47 - Event 40 (session disconnects).
  - 07:01:46 on unaffected host - Event 9011 and no Event 1000 in comparison window.

3) FSLogix attach behavior changed via FIN-01 image/config drift
- Judgement: Neutral.
- Determining events:
  - No FSLogix-specific event source in provided evidence set.
  - Present sequence is dominated by DWM crash signatures (Event 1000 + 9009 + Event 40).

4) Security/EDR startup contention introduced by updated image
- Judgement: Neutral to mildly contradicted.
- Determining events:
  - Repeated hard crash signature in graphics module (Event 1000 at 07:02:16/07:02:46/07:08:24).
  - No EDR/AV telemetry events included in this export window.

5) Logon policy/script processing issue
- Judgement: Contradicts.
- Determining events:
  - 07:02:10, 07:02:44, 07:03:10, 07:08:22 - Event 21 confirms logon success repeatedly.
  - Failures occur after logon as DWM/application crashes (Event 1000, Event 9009), then disconnects (Event 40).

## Surviving Hypothesis

Graphics stack regression introduced by the updated POOL-FIN-01 image, with `dwm.exe` crashing in Intel display driver module `igdumd64.dll`.

## Detailed Resolution Steps

### 1) Immediate Containment
1. Put POOL-FIN-01 session hosts in drain mode to stop new logons.
2. Route new sessions to POOL-FIN-02 while mitigation is in progress.
3. Publish user-facing advisory for intermittent black-screen/disconnects on FIN-01.

### 2) Rapid Service Restoration (Preferred)
1. Roll POOL-FIN-01 image reference back to the known-good pre-update image baseline.
2. Reimage/redeploy FIN-01 hosts from the known-good image.
3. Reboot redeployed hosts and verify host registration/heartbeat in AVD.

### 3) If Rollback Timing Is Constrained
1. On FIN-01 hosts, replace Intel graphics driver 31.0.101.4146 with known-good driver version aligned to FIN-02 baseline.
2. Reboot host after driver replacement.
3. Keep host in drain mode until validation checks pass.

### 4) Validation Gate Before Reopening FIN-01
1. Run controlled logon tests with representative user set.
2. Confirm no new Event 1000 where `dwm.exe` faults in `igdumd64.dll`.
3. Confirm no new Event 9009 during login/reconnect attempts.
4. Confirm expected DWM startup success (Event 9011) and no immediate Event 40 disconnect chain.

### 5) Controlled Return to Service
1. Remove drain mode from one FIN-01 host first.
2. Monitor for 30-60 minutes.
3. If stable, progressively return remaining FIN-01 hosts.

### 6) Preventive Hardening
1. Pin approved GPU driver + AVD agent versions in image standards.
2. Introduce canary ring deployment (single-host validation before broad rollout).
3. Add alerting for Event 1000 (`dwm.exe` + `igdumd64.dll`) and correlated Event 9009/Event 40 chain.
4. Add a post-image-update health gate that blocks wider rollout on DWM crash signature.
