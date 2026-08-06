# User Logon Incident Analysis - cthompson

Date: 2026-08-06  
Scope basis: facts only (no deep-dive evidence yet)

## Scope Facts
- Symptom: user cthompson not able to login
- Who: cthompson only one user
- Since: ~08:40 this morning
- Change: Nil

## Ranked Hypotheses (Most Probable First)

### 1) Account lockout for cthompson (bad password attempts/MFA retries)
Why this fits the scope facts:
- Single-user impact strongly indicates an identity issue on one account.
- Lockouts can begin suddenly at a clear timestamp without a known change.

Single fastest check:
- Check AD/Entra sign-in logs for cthompson lockout or invalid credential events around 08:40.

### 2) Password expired or forced password change state
Why this fits the scope facts:
- User-specific authentication failures commonly present as sudden login failure.
- If password change flow is blocked or not surfaced, user reports this as "cannot login".

Single fastest check:
- Verify password status (expiry, must-change-at-next-logon, pwdLastSet) and test unlock/reset path.

### 3) Conditional Access or MFA challenge failure for this user
Why this fits the scope facts:
- Can affect one user only due to per-user MFA setup, risk posture, device compliance, or session token state.
- No global change is required for this to occur.

Single fastest check:
- Review latest Entra sign-in failure details for cthompson (CA decision and MFA step failure reason).

### 4) Disabled or restricted account state (manual/automated action or licensing edge case)
Why this fits the scope facts:
- Abrupt single-user login loss is consistent with account disablement/sign-in block.
- Licensing or access entitlement mismatch can deny sign-in for one identity.

Single fastest check:
- Confirm accountEnabled/sign-in block and required license assignments for cthompson.

### 5) Endpoint-side credential/profile issue (cached creds, profile corruption, wrong domain/UPN)
Why this fits the scope facts:
- "One user only" may still be isolated to that user’s device/session context.
- Sudden onset can occur with cached credential corruption and no known upstream change.

Single fastest check:
- Attempt cthompson login on a known-good alternate device/session (or another user on cthompson device) to isolate account vs endpoint.

## Note
- This is a hypothesis ranking from scope facts only.
- No single root cause is confirmed at this stage.

## Evidence Review During Incident Window (2024-03-15 08:44-09:12)

### Hypothesis 1) Account lockout for cthompson (bad password attempts/MFA retries)
Judgement: Supports

Evidence used:
- Event 4776 at 08:44:01 shows validation failure with error 0xC000006A (wrong password).
- Event 4625 at 08:44:03, 08:44:28, and 08:44:55 shows repeated bad password interactive failures.
- Event 4740 at 08:44:56 confirms account lockout.
- Event 4625 at 08:45:10 confirms continued failure due to locked-out status.

### Hypothesis 2) Password expired or forced password change state
Judgement: Contradicts

Evidence used:
- Event 4776 at 08:44:01 indicates wrong password (0xC000006A), not password-expired state.
- Event 4625 at 08:44:03, 08:44:28, and 08:44:55 indicates bad password pattern.
- Event 4740 at 08:44:56 indicates lockout due to failed attempts rather than expiry flow.

### Hypothesis 3) Conditional Access or MFA challenge failure for this user
Judgement: Contradicts

Evidence used:
- Event 4776 at 08:44:01 and Event 4771 at 08:45:44, 08:46:01, and 08:46:33 all indicate wrong-password or Kerberos pre-auth failure.
- These failures occur at primary credential validation stage, not MFA challenge success/fail stage in this log set.

### Hypothesis 4) Disabled or restricted account state (manual/automated action or licensing edge case)
Judgement: Contradicts

Evidence used:
- Event 4776 at 08:44:01 indicates wrong password.
- Event 4625 at 08:44:03, 08:44:28, and 08:44:55 followed by Event 4740 at 08:44:56 indicates lockout after failed attempts, not pre-disabled account behavior.

### Hypothesis 5) Endpoint-side credential/profile issue (cached creds, profile corruption, wrong domain/UPN)
Judgement: Supports

Evidence used:
- Event 4625 at 08:44:03, 08:44:28, and 08:44:55 from DESKTOP-FB022 indicates local interactive failures.
- Event 4740 at 08:44:56 caller computer DESKTOP-FB022 links lockout trigger to that endpoint.
- Event 4771 at 08:45:44, 08:46:01, and 08:46:33 from source IP 10.10.8.112 (different source) indicates an additional credential replay source.

## Surviving Hypothesis After Elimination

Account lockout caused by repeated bad password attempts, with at least one stale credential source continuing to replay old credentials.

Reason this survives:
- Wrong-password failures occur before lockout (4776 at 08:44:01; 4625 at 08:44:03, 08:44:28, 08:44:55).
- Lockout is explicitly confirmed (4740 at 08:44:56).
- Post-lockout attempts continue (4625 at 08:45:10).
- Additional wrong-password pre-auth events continue from a different source (4771 at 08:45:44, 08:46:01, 08:46:33 from 10.10.8.112).

## Detailed Resolution Steps

1. Contain active retries
- Disconnect or sign out the user session on DESKTOP-FB022 to stop immediate retry loops.
- Temporarily isolate any secondary session/device suspected to be 10.10.8.112.

2. Identify all authentication sources
- Pull Event 4740, 4776, and 4771 for cthompson across all domain controllers for the full window.
- Record each Caller Computer and Source IP to build a complete retry-source list.
- Resolve 10.10.8.112 to host/device owner via DHCP, DNS, or endpoint inventory.

3. Reset account credentials
- Perform admin reset of cthompson password.
- Require password change at next successful sign-in.
- If hybrid identity is in use, verify password hash sync completion before retry.

4. Remove stale stored credentials on each source
- On DESKTOP-FB022: clear saved credentials in Credential Manager for domain and M365 apps; re-authenticate with the new password.
- On host mapped to 10.10.8.112: find services, scheduled tasks, scripts, drive mappings, or apps using cthompson credentials and update/remove old credentials.

5. Unlock and validate
- Unlock cthompson only after stale credential sources are remediated.
- Test one clean interactive sign-in from DESKTOP-FB022.
- Monitor for new 4625/4771/4776 failures for at least 15 minutes.

6. Confirm service restoration
- Verify successful sign-in events and normal access to email, Teams, file shares, and line-of-business apps.

7. Prevent recurrence
- Document the secondary source and owning team.
- Remove dependency on user credentials in scheduled/service contexts where possible.
- Add runbook step: after lockout, always trace and remediate secondary source IPs before unlock.
