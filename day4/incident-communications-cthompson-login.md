# End-User Communications - cthompson Login Incident

Date prepared: 2026-08-06
Source of truth: incident analysis and RCA for FINBRIDGE\cthompson login lockout

## Audience 1 - Non-technical executive
Your access and data are safe. One user (cthompson) could not sign in from about 08:40, and no wider service issue was found. Repeated incorrect sign-in attempts locked the account, and an additional saved sign-in on another device kept retrying old details. We reset sign-in details, cleared old saved sign-ins, re-enabled the account at 09:08, and confirmed successful sign-in at 09:09. No further issues were reported. No action needed from you.

## Audience 2 - Affected end-user team (10 people, non-technical)
Hi team, one user (cthompson) could not sign in from about 08:40 because repeated incorrect sign-in attempts locked the account, and another device was still trying old saved sign-in details; we reset sign-in details, cleared the old saved sign-ins, re-enabled the account at 09:08, confirmed successful sign-in at 09:09, and there is no wider service issue and no further problems reported. If you see this, stop retrying sign-in and contact the Service Desk (ask for identity lockout triage).

## Audience 3 - Engineer-to-engineer internal note
Incident: FINBRIDGE\cthompson login failure (single-user scope), first reported ~08:40, resolved 09:09.

Root cause:
- Repeated incorrect password submissions triggered AD lockout for FINBRIDGE\cthompson (Event 4740 at 08:44:56, caller DESKTOP-FB022).
- Stale credential replay from a secondary source extended failure condition (Event 4771 failures from 10.10.8.112 at 08:45:44, 08:46:01, 08:46:33).

Supporting event chain:
- 08:44:01 Event 4776 - 0xC000006A wrong password (source workstation DESKTOP-FB022).
- 08:44:03 / 08:44:28 / 08:44:55 Event 4625 - bad password, logon type 2, source DESKTOP-FB022.
- 08:44:56 Event 4740 - account locked out (caller DESKTOP-FB022).
- 08:45:10 Event 4625 - account locked out, logon type 7, source DESKTOP-FB022.
- 08:45:44 / 08:46:01 / 08:46:33 Event 4771 - failure code 0x18 wrong password, source IP 10.10.8.112.

Exact action taken:
1. Investigated lockout pattern and source attribution via Security events.
2. Confirmed primary source DESKTOP-FB022 and secondary source 10.10.8.112.
3. Executed credential remediation workflow:
- Account re-enable/unlock by FINBRIDGE\helpdesk-admin.
- Password reset.
- Stale credential cleanup on relevant source(s), including endpoint/app saved credentials.
4. Retested interactive sign-in from DESKTOP-FB022.

Config/environment detail:
- User account: FINBRIDGE\cthompson.
- Primary endpoint/source workstation: DESKTOP-FB022.
- Secondary auth source IP: 10.10.8.112.
- No broader outage observed; impact remained single-user.

Verification:
- 09:08:14 Event 4722 Audit Success - account enabled by FINBRIDGE\helpdesk-admin.
- 09:09:01 Event 4624 Audit Success - successful interactive logon (type 2) from DESKTOP-FB022.
- User validated working access; no further issues reported.

Preventive action required:
1. For lockouts, correlate Event 4740 with Event 4776/4771 across DCs before final unlock.
2. Add mandatory stale-credential cleanup checklist (Credential Manager, M365 app sessions, mapped drives, VPN profiles).
3. Resolve and document secondary source ownership (10.10.8.112) via DHCP/DNS/asset inventory.
4. Add monitoring rule for repeated 4771/4776 followed by 4740, plus post-lockout cross-source retries.
5. Hold incident open until 15-minute clean auth window after unlock/reset.
