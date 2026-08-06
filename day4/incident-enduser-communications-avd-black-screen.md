# End-User Communications - AVD Black Screen Incident

## Audience 1 - Non-technical executive

Your access and data are safe. This morning, about 40% of users in POOL-FIN-01 saw a black screen after sign-in; for some it cleared in about 30 seconds, while others were briefly disconnected and reconnected. The issue began after a 02:00 overnight update to POOL-FIN-01; POOL-FIN-02 (not updated) was unaffected. We moved users to the unaffected group, restored POOL-FIN-01 to the prior known-good setup, rebooted, and verified recovery at 10:00. No action is needed unless it happens again.

## Audience 2 - Affected end-user team (non-technical)

Team, this morning about 40% of people using POOL-FIN-01 saw a black screen right after sign-in (it cleared in about 30 seconds for some people, while others were briefly disconnected) because an overnight 02:00 update changed that desktop group; POOL-FIN-02 was not updated and had no issues. We moved sessions to the unaffected group, restored POOL-FIN-01 to the prior known-good setup, rebooted, and confirmed normal logins by 10:00. If you see this again, sign out and back in, then contact the Service Desk.

## Audience 3 - Engineer-to-engineer internal note

Incident summary:
- Scope: ~40% users on POOL-FIN-01 impacted; POOL-FIN-02 unaffected.
- Symptom: black screen post-logon; some clear in ~30s, others enter disconnect/reconnect behavior.
- Timing: started ~07:00, after 02:00 overnight image update to POOL-FIN-01 only.

Root cause:
- Image-introduced graphics stack regression on FIN-01.
- DWM crash signature: dwm.exe faulting in igdumd64.dll (Intel), module version 31.0.101.4146, exception 0xc0000005.

Supporting evidence:
- SHFIN-01-A:
  - 07:02:10 Event 21 (LSM): logon success.
  - 07:02:16 Event 1000 (App Error): dwm.exe -> igdumd64.dll, 0xc0000005.
  - 07:02:17 Event 40 (LSM): disconnect.
  - 07:02:18 Event 9009 (DWM): DWM exited.
  - Repeats at 07:02:46 (Event 1000), 07:02:47 (Event 40), 07:03:01 (Event 9009), and 07:08:24 (Event 1000).
  - 07:02:14 Event 1 (Kernel-General): boot time 02:03:11 post-update restart.
- SHFIN-02-A (control, pre-update image):
  - 07:01:46 Event 9011 (DWM): started successfully.
  - No Event 1000 in same window.

Exact action taken:
- Contained by stopping new sessions on FIN-01 and routing to unaffected FIN-02.
- Restored FIN-01 via known-good baseline path (rollback to pre-update image baseline and driver alignment to known-good baseline).
- Rebooted FIN-01 hosts and validated before reopening.

Verification:
- Resolved at 10:00.
- Verified users successfully logging into POOL-FIN-01.
- No further issue reports.

Preventive action required:
- Pin approved GPU driver + AVD agent versions in image standard.
- Enforce canary rollout (single-host promotion gate with multi-user logon/reconnect tests).
- Alert on Event 1000 (dwm.exe + igdumd64.dll) with correlated Event 9009 and Event 40 chain.
- Add post-image-update health gate to block broad rollout when DWM crash signature appears.
