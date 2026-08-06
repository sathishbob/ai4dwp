# RCA: User Login Failure - FINBRIDGE\cthompson

Date: 2026-08-06
Incident date: 2024-03-15
Incident window: 08:40-09:09
Status: Resolved at 09:09
Service area: End-user authentication (AD/Kerberos interactive logon)

## 1) Executive Summary
On 2024-03-15, user FINBRIDGE\cthompson was unable to log in starting around 08:40. Initial triage identified a single-user impact with no reported change. Event evidence confirmed repeated wrong-password attempts from DESKTOP-FB022, followed by account lockout, then continued Kerberos pre-authentication failures from a second source IP (10.10.8.112), indicating stale credentials were still being replayed.

The remediation sequence (credential reset, stale credential source cleanup, account re-enable/unlock, and validation) restored service. Recovery was verified at 09:09 with successful interactive logon and no further user-reported issues.

## 2) Impact Assessment
- User impact: One user (FINBRIDGE\cthompson).
- Symptom: Unable to log in (interactive access failure).
- Scope: User-specific authentication failure; no broader outage observed.
- Business effect: Temporary loss of endpoint access for affected user.

## 3) Supporting Evidence

### 3.1 Scope Facts (Initial)
- Symptom: User cthompson not able to login.
- Who: cthompson only one user.
- Since: Approximately 08:40.
- Change: Nil reported.

### 3.2 Security Event Log Evidence (DESKTOP-FB022 and AD/Kerberos)
- 08:44:01 - Security Event 4776 (Audit Failure)
  - Domain controller credential validation failed for FINBRIDGE\cthompson.
  - Error: 0xC000006A (wrong password).
  - Source workstation: DESKTOP-FB022.

- 08:44:03 - Security Event 4625 (Audit Failure)
  - Account: FINBRIDGE\cthompson.
  - Failure: Unknown user name or bad password.
  - Logon type: 2 (Interactive).
  - Source: DESKTOP-FB022.

- 08:44:28 - Security Event 4625 (Audit Failure)
  - Same failure pattern, interactive, DESKTOP-FB022.

- 08:44:55 - Security Event 4625 (Audit Failure)
  - Same failure pattern, interactive, DESKTOP-FB022.

- 08:44:56 - Security Event 4740 (Audit Failure)
  - User account locked out.
  - Account: FINBRIDGE\cthompson.
  - Caller computer: DESKTOP-FB022.

- 08:45:10 - Security Event 4625 (Audit Failure)
  - Failure reason: Account locked out.
  - Logon type: 7 (Unlock attempt).
  - Source: DESKTOP-FB022.

- 08:45:44 - Security Event 4771 (Audit Failure)
  - Kerberos pre-authentication failed.
  - Account: FINBRIDGE\cthompson.
  - Failure code: 0x18 (wrong password).
  - Source IP: 10.10.8.112.

- 08:46:01 - Security Event 4771 (Audit Failure)
  - Same failure code and source IP: 10.10.8.112.

- 08:46:33 - Security Event 4771 (Audit Failure)
  - Same failure code and source IP: 10.10.8.112.

### 3.3 Recovery Verification Evidence
- 09:08:14 - Security Event 4722 (Audit Success)
  - User account enabled.
  - Account: FINBRIDGE\cthompson.
  - Action by: FINBRIDGE\helpdesk-admin.

- 09:09:01 - Security Event 4624 (Audit Success)
  - Successful logon for FINBRIDGE\cthompson.
  - Logon type: 2 (Interactive).
  - Source: DESKTOP-FB022.

### 3.4 Evidence Conclusion
The sequence clearly shows wrong-password attempts causing lockout, followed by continued bad pre-auth attempts from a separate source, then successful account re-enable and successful interactive logon after remediation. Evidence supports an account lockout incident driven by incorrect/stale credentials rather than platform-wide authentication outage.

## 4) Incident Timeline
- ~08:40 - User first reports inability to log in.
- 08:44:01 - Event 4776 wrong-password validation failure (DESKTOP-FB022).
- 08:44:03 - Event 4625 bad password (interactive) from DESKTOP-FB022.
- 08:44:28 - Event 4625 bad password repeat.
- 08:44:55 - Event 4625 bad password repeat.
- 08:44:56 - Event 4740 account lockout for FINBRIDGE\cthompson.
- 08:45:10 - Event 4625 account locked out (unlock attempt).
- 08:45:44 - Event 4771 wrong password from 10.10.8.112.
- 08:46:01 - Event 4771 wrong password from 10.10.8.112.
- 08:46:33 - Event 4771 wrong password from 10.10.8.112.
- 09:08:14 - Event 4722 account enabled by FINBRIDGE\helpdesk-admin.
- 09:09:01 - Event 4624 successful interactive logon from DESKTOP-FB022.
- 09:09 - Incident confirmed resolved; user verified working and no further issues reported.

## 5) Root Cause Statement
Primary root cause: Repeated incorrect password submissions for FINBRIDGE\cthompson triggered account lockout (Event 4740), with continued stale credential replay from at least one additional source (10.10.8.112) extending the failure condition until remediation.

Contributing factor:
- Secondary credential source retained outdated credentials and continued Kerberos pre-auth attempts after lockout.

## 6) 5-Why Analysis
1. Why could the user not log in?
- Because the account became locked and authentication attempts were denied.

2. Why did the account become locked?
- Because multiple wrong-password attempts were submitted in a short interval from DESKTOP-FB022.

3. Why were repeated wrong-password attempts occurring?
- Either user/device entered stale credentials repeatedly, and/or saved credentials were replayed automatically.

4. Why did failures continue after lockout?
- A second source (10.10.8.112) continued sending wrong Kerberos pre-authentication attempts with stale credentials.

5. Why was stale credential replay possible from multiple sources?
- Credential hygiene/control gaps existed across endpoint and secondary execution contexts (saved credentials, tasks/services, or app sessions) without immediate detection/cleanup automation.

## 7) Resolution Actions Implemented
1. Investigated DC and endpoint-linked security events for cthompson to establish failure pattern and source(s).
2. Confirmed lockout condition and secondary wrong-password source activity.
3. Applied credential remediation workflow:
- Account re-enable/unlock sequence via helpdesk-admin.
- Password reset and stale credential cleanup on relevant source(s).
4. Retested interactive sign-in from DESKTOP-FB022.
5. Verified successful logon and user confirmation of restored service.

## 8) Verification of Recovery
- Recovery marker 1: Event 4722 at 09:08:14 (account enabled).
- Recovery marker 2: Event 4624 at 09:09:01 (successful interactive login).
- User validation: User able to log in to host; no issues reported after fix.
- Incident closure time: 09:09.

## 9) Preventive and Corrective Actions (CAPA)

### 9.1 Immediate Preventive Controls
1. For lockout incidents, always trace all source hosts/IPs from Event 4740, 4776, and 4771 before final unlock.
2. Enforce stale credential cleanup checklist on affected endpoint:
- Credential Manager entries
- M365 app sessions (Outlook/Teams/OneDrive)
- Mapped drives and VPN profiles
3. Validate no new failed auth events for 15 minutes before closing incident.

### 9.2 Process Improvements
1. Add lockout triage runbook step to resolve unknown source IP/device (for example 10.10.8.112) via DHCP/DNS/asset inventory.
2. Standardize service/task credential reviews where user credentials are used in scheduled/background contexts.
3. Require incident notes to capture exact event IDs and timestamps for failure and recovery points.

### 9.3 Monitoring and Alerting
1. Create alert for repeated Event 4771/4776 failures followed by Event 4740 for same account within a short window.
2. Add correlation alert when post-lockout failures continue from a different source IP.
3. Dashboard metric: top accounts by lockout frequency and repeated-source offenders.

## 10) Residual Risk and Follow-Up
- Residual risk: Reoccurrence if secondary devices/services keep stale credentials.
- Follow-up actions:
1. Identify and document ownership of source 10.10.8.112 and confirm credential remediation there.
2. Audit recurring lockout patterns for cthompson over the next 7 days.
3. Review and harden endpoint credential storage practices in user support playbooks.

## 11) Closure
Incident closed as resolved at 09:09 after successful account recovery and verified interactive logon (Event 4624), with no further user issues reported.