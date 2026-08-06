# Incident RCA: User Account Lockout (jsmith)

## Document Control
- Analyst: DWP Analyst (AI-assisted)
- Date: 2026-08-05
- Scope: 30-minute security event window
- Affected user: jsmith
- Affected endpoint: DESKTOP-FB001
- Domain actor involved: FINBRIDGE\helpdesk-admin

## Executive Summary
User account jsmith was locked out after repeated failed interactive sign-in attempts from DESKTOP-FB001. The lockout event was then followed by additional failed unlock attempt(s) while the account was in locked state. Helpdesk re-enabled/unlocked the account, after which the user successfully signed in interactively. The most likely cause is repeated incorrect password entry at the local console (human error, stale password habit, or keyboard/input issue) reaching domain lockout threshold.

## Raw Events (Provided)
1. 08:02:14 - Event ID 4625 (Audit Failure)
   - Account: jsmith
   - Failure reason: Unknown username or bad password
   - Source: DESKTOP-FB001
   - Logon type: 2 (Interactive)

2. 08:04:22 - Event ID 4625 (Audit Failure)
   - Account: jsmith
   - Failure reason: Unknown username or bad password
   - Source: DESKTOP-FB001
   - Logon type: 2 (Interactive)

3. 08:06:01 - Event ID 4740 (Account lockout event)
   - Account: jsmith
   - Account locked out
   - Caller computer: DESKTOP-FB001

4. 08:07:45 - Event ID 4625 (Audit Failure)
   - Account: jsmith
   - Failure reason: Account locked out
   - Source: DESKTOP-FB001
   - Logon type: 7 (Unlock)

5. 08:22:10 - Event ID 4722 (Audit Success)
   - Account: jsmith
   - Account enabled (administrative action)
   - Performed by: FINBRIDGE\helpdesk-admin

6. 08:23:44 - Event ID 4624 (Audit Success)
   - Account: jsmith
   - Successful logon
   - Logon type: 2 (Interactive)

## Event ID Explanation
- Event ID 4625 (An account failed to log on)
  - Records a failed authentication attempt.
  - In this incident, first two 4625 events show bad credentials during local interactive sign-in (logon type 2).
  - Later 4625 shows failure because account status was locked, not because password was necessarily wrong.

- Event ID 4740 (A user account was locked out)
  - Records that account lockout threshold was reached and the account was locked by policy.
  - Includes caller/source computer that generated the failed authentication path (DESKTOP-FB001).

- Event ID 4722 (A user account was enabled)
  - Records administrative action re-enabling an account.
  - In many environments this is part of helpdesk remediation for lockout/unlock workflows.

- Event ID 4624 (An account was successfully logged on)
  - Records successful authentication and session creation.
  - Here it confirms recovery after helpdesk action and correct credentials.

## Reconstructed Sequence (Plain English)
1. At 08:02, jsmith tried to sign in at DESKTOP-FB001 and entered credentials that were not accepted (bad password/username mismatch category).
2. At 08:04, a second local interactive sign-in attempt also failed for the same reason.
3. At 08:06, the domain/account policy lockout threshold was reached and jsmith was locked out (event 4740).
4. At 08:07, someone attempted to unlock the already locked session on the same machine (logon type 7), and it failed specifically because the account was locked.
5. At 08:22, helpdesk-admin performed an administrative account enable/unlock step.
6. At 08:23, jsmith successfully signed in interactively, indicating incident resolution.

## Most Likely Cause of Lockout
Repeated invalid credential entry at the interactive sign-in screen on DESKTOP-FB001 triggered account lockout policy.

### Evidence
- Two consecutive 4625 failures with reason bad password-like category (08:02, 08:04) from same endpoint.
- 4740 lockout event shortly after (08:06) with caller computer DESKTOP-FB001.
- Post-lock 4625 explicitly says account locked out (08:07), confirming state transition.
- Successful 4624 after helpdesk intervention implies credentials and account state were later corrected.

## Alternative Hypotheses Considered
- Stale cached credentials from background service/task: Less likely in this dataset because failed attempts are interactive (type 2) and unlock (type 7), both user-session centric.
- Brute-force attack: Less likely due to single known endpoint, narrow pattern, and immediate successful recovery after helpdesk/user correction.
- Identity store replication issue: Possible but not supported by the provided events; no contradictory success/failure pattern across multiple hosts shown.

## 5 Whys Analysis
1. Why was jsmith locked out?
   - Because the lockout threshold was reached (event 4740 at 08:06:01).
2. Why was the threshold reached?
   - Multiple failed logon attempts occurred beforehand (4625 at 08:02:14 and 08:04:22).
3. Why did those logons fail?
   - Credentials presented at interactive logon were invalid (failure reason unknown username or bad password).
4. Why were invalid credentials repeatedly entered?
   - Most probable operational cause is user-side credential entry issue (mistyped password, old password habit, keyboard layout/Caps Lock/input method issue).
5. Why did this become an incident requiring helpdesk?
   - Account lockout policy prevented further login, requiring administrative enable/unlock action (4722 by helpdesk-admin).

## Root Cause Statement
Primary root cause: Repeated incorrect interactive credential entry from DESKTOP-FB001 for account jsmith, which triggered configured account lockout controls.

Contributing factors:
- Lockout threshold policy converted repeated mistakes into account lockout.
- No immediate self-service unlock path available to user, leading to service desk dependency.

## Impact
- User unable to access workstation/session for approximately 17-22 minutes (from lockout at 08:06 to successful logon at 08:23).
- Productivity interruption and service desk effort required.

## Corrective Actions Taken
- Helpdesk-admin enabled/unlocked account at 08:22 (event 4722).
- User successfully logged in at 08:23 (event 4624).

## Preventive Actions (Recommended)
- User guidance:
  - Verify keyboard layout, Caps Lock, and domain context at sign-in.
  - Use approved password manager/secure reference to reduce mistyping.
- Policy/process:
  - Review whether lockout threshold and duration are balanced for usability vs security.
  - Implement/advertise self-service password reset/unlock if available.
- Monitoring:
  - Alert on clustered 4625 failures followed by 4740 from same endpoint.
  - Correlate with endpoint telemetry for keyboard locale flips or sign-in UX anomalies.

## Additional Data to Collect (If Full Forensic Confirmation Required)
- Full Security log around incident window (before/after 30 minutes).
- Domain controller events for exact bad password count and lockout policy values.
- User statement on password change recency and observed sign-in behavior.
- Endpoint input locale state and any credential providers in use.

## Confidence
- Confidence in root cause assessment: High (based on direct sequence coherence of 4625 -> 4740 -> locked-out 4625 -> admin enable -> 4624 success).
