# Known Error Record - FINBRIDGE\cthompson Login Lockout

Symptom: The affected user, FINBRIDGE\cthompson, could not log in interactively starting around 08:40. The user experienced authentication failure until recovery was completed.

Cause: Verified root cause was repeated incorrect password submissions that triggered account lockout (Event 4740). A contributing factor was continued stale credential replay from secondary source IP 10.10.8.112 (Event 4771 with wrong-password failure code 0x18).

Scope: Impact was limited to one user account, FINBRIDGE\cthompson. The primary observed endpoint/source was DESKTOP-FB022, with additional authentication failures from 10.10.8.112; no broader outage was observed.

Workaround: Restore service by running lockout triage, resetting credentials, clearing stale saved credentials on the involved source systems, and then re-enabling/unlocking the account. In this incident, recovery was verified by Event 4722 at 09:08:14 and successful interactive logon Event 4624 at 09:09:01.

Permanent fix: The incident was resolved by completing the credential remediation workflow across identified sources and validating successful sign-in from DESKTOP-FB022. The required lasting control from RCA is to correlate lockout-related events across all sources before unlock and complete mandatory stale-credential cleanup with a 15-minute clean-auth verification window.

How to spot it: Look for the sequence of Event 4776 wrong password (0xC000006A), repeated Event 4625 bad password (including lockout reason), Event 4740 account lockout, and post-lockout Event 4771 pre-auth failures with code 0x18 from a secondary source. In this case, key identifiers were DESKTOP-FB022 as caller/source workstation and secondary source IP 10.10.8.112.
