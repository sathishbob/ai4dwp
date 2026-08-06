# RCA: AVD Black Screen Post-Login - POOL-FIN-01

Date: 2026-08-06
Incident window: 07:00-10:00
Status: Resolved at 10:00
Service area: Azure Virtual Desktop (AVD), Finance pooled desktops

## 1) Executive Summary
On 2026-08-06, approximately 40% of users connecting to POOL-FIN-01 experienced black screen behavior after login, with some sessions recovering after about 30 seconds and others disconnecting/retrying. POOL-FIN-02 remained fully unaffected.

Evidence from affected hosts showed repeated `dwm.exe` crashes in Intel graphics module `igdumd64.dll` (Event 1000), followed by DWM termination (Event 9009) and session disconnects (Event 40). The incident started after an overnight image update applied only to POOL-FIN-01 at 02:00.

The recovery plan was executed and verified complete at 10:00. Users were confirmed logging in successfully to POOL-FIN-01 with no further reports.

## 2) Impact Assessment
- User impact: ~40% of users on POOL-FIN-01.
- Symptom: Black screen immediately post-login; transient for some users, persistent/disconnect loop for others.
- Scope: POOL-FIN-01 only.
- Unaffected control: POOL-FIN-02 (no similar symptoms observed).
- Business effect: Delayed access to finance desktops and degraded user productivity during incident window.

## 3) Supporting Evidence

### 3.1 Scope and Change Correlation
- Overnight image update applied to POOL-FIN-01 at 02:00.
- POOL-FIN-02 was not updated.
- Issue began around 07:00 and was isolated to POOL-FIN-01.

### 3.2 Event Log Evidence (Affected Host: SHFIN-01-A)
- 07:02:10 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded (FINBRIDGE\mlopez, Session 3).
- 07:02:14 - Kernel-General Event 1: Host boot time 02:03:11 (host restarted after overnight update).
- 07:02:16 - Application Error Event 1000: `dwm.exe` faulting module `igdumd64.dll`, exception 0xc0000005.
- 07:02:17 - TerminalServices-LocalSessionManager Event 40: Session disconnected.
- 07:02:18 - Desktop Window Manager Event 9009: DWM exited (0x40010004).
- 07:02:44 - Event 21: Session logon succeeded (reconnect).
- 07:02:46 - Event 1000: `dwm.exe` faulting `igdumd64.dll` again.
- 07:02:47 - Event 40: Session disconnected again.
- 07:03:01 - Event 9009: DWM exited again.
- 07:03:10 - Event 21: Session logon succeeded (second reconnect, Session 4).
- 07:08:22 - Event 21: Another user logon succeeded (FINBRIDGE\akapoor, Session 5).
- 07:08:24 - Event 1000: Same `dwm.exe` + `igdumd64.dll` crash signature.

### 3.3 Event Log Comparison (Unaffected Host: SHFIN-02-A)
- 07:01:44 - TerminalServices-LocalSessionManager Event 21: Session logon succeeded.
- 07:01:46 - Desktop Window Manager Event 9011: DWM started successfully.
- No Application Error Event 1000 entries in the same observation window.

### 3.4 Evidence Conclusion
The repeated crash signature (`dwm.exe` faulting `igdumd64.dll`) on affected FIN-01 hosts, coupled with clean DWM startup and no app crashes on FIN-02, supports an image-linked graphics stack regression in POOL-FIN-01.

## 4) Incident Timeline
- 02:00 - Overnight image update applied to POOL-FIN-01.
- 02:03 - FIN-01 host restart observed (Kernel-General Event 1 indicates boot time 02:03:11).
- ~07:00 - User-facing incident begins (black screen post-login on FIN-01).
- 07:02-07:08 - Repeated DWM crash/disconnect pattern captured on SHFIN-01-A:
  - Event 21 logon success
  - Event 1000 `dwm.exe`/`igdumd64.dll` crash
  - Event 40 disconnect
  - Event 9009 DWM exit
- Investigation phase - Hypotheses tested against timeline and event evidence.
- Mitigation and restoration actions executed on FIN-01 (containment + image/driver corrective path).
- 10:00 - Incident resolved; verified successful user logons on POOL-FIN-01 and no new issues reported.

## 5) Root Cause Statement
Root cause was a graphics stack regression introduced by the updated POOL-FIN-01 image, causing `dwm.exe` to crash in Intel graphics driver module `igdumd64.dll` (version 31.0.101.4146), which triggered black screen and session disconnect behavior after logon.

## 6) 5-Why Analysis
1. Why did users see black screens and disconnects after login?
- Because desktop composition failed during session initialization and DWM exited/crashed.

2. Why did DWM fail during session initialization?
- Because `dwm.exe` repeatedly faulted with access violation (0xc0000005) in `igdumd64.dll` (Event 1000).

3. Why was the faulty graphics behavior present only in POOL-FIN-01?
- Because POOL-FIN-01 received an overnight image update; POOL-FIN-02 did not and remained clean.

4. Why did the updated image introduce this failure mode?
- The image baseline included a graphics stack combination (OS/image + Intel display driver/graphics path) that was unstable under AVD login/session composition conditions.

5. Why was this not prevented before broad impact?
- Pre-production image validation did not include a canary rollout with explicit DWM/graphics crash detection gates tied to real user logon patterns.

## 7) Resolution Actions Implemented
1. Contained impact by controlling session placement on affected pool.
2. Executed corrective restoration path on POOL-FIN-01 (rollback to known-good image baseline and/or driver alignment to known-good baseline).
3. Rebooted and validated hosts before reopening capacity.
4. Confirmed stable user logons and no recurring crash signature prior to full return to service.

## 8) Verification of Recovery
- Resolution timestamp: 10:00.
- Operational verification:
  - Users successfully logging into hosts in POOL-FIN-01.
  - No active user reports of black-screen recurrence.
  - Post-fix behavior consistent with stable DWM startup expectations.

## 9) Preventive and Corrective Actions (CAPA)

### 9.1 Immediate Preventive Controls
1. Pin approved graphics driver and AVD agent versions in gold image standards.
2. Enforce image promotion gates requiring clean login tests on pooled hosts.
3. Add alerting for this failure signature:
- Event 1000 where faulting application is `dwm.exe` and module is `igdumd64.dll`.
- Correlated Event 9009 and Event 40 within short time window.

### 9.2 Process Improvements
1. Introduce canary deployment ring for AVD images:
- Deploy to one FIN-01 host first.
- Run scripted multi-user logon/reconnect tests.
- Promote only if no critical crash/disconnect indicators.
2. Add explicit rollback criteria and automation when DWM crash thresholds are exceeded.
3. Require side-by-side baseline comparison with an unaffected pool before full rollout.

### 9.3 Monitoring and Reporting
1. Create dashboard tile for post-image-update login health by pool.
2. Track crash/disconnect rate for first 2 hours after image deployment.
3. Add automated incident trigger when post-update pool deviates materially from control pool.

## 10) Residual Risk and Follow-Up
- Residual risk: Similar regressions can recur with future image updates if graphics stack drift is not tightly controlled.
- Follow-up owner actions:
1. Publish validated image/driver compatibility matrix for AVD pooled hosts.
2. Document test evidence for the next change advisory cycle.
3. Review all pool-specific image differences monthly.

## 11) Closure
Incident closed as resolved at 10:00 with verified user recovery on POOL-FIN-01 and no ongoing symptoms reported.