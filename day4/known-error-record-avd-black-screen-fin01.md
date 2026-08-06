# Known Error Record - AVD Black Screen (POOL-FIN-01)

Symptom: Users see a black screen immediately after sign-in on POOL-FIN-01. For some users it clears after about 30 seconds, while for others sessions disconnect and reconnect.

Cause: Verified root cause was a graphics stack regression introduced by the updated POOL-FIN-01 image. The failure manifested as dwm.exe crashing in Intel graphics module igdumd64.dll with exception 0xc0000005.

Scope: Approximately 40% of users on POOL-FIN-01 were affected during the incident window. POOL-FIN-02 was unaffected.

Workaround: Route new user sessions to unaffected POOL-FIN-02 to restore access while remediation is performed on POOL-FIN-01. Keep affected POOL-FIN-01 hosts out of new-session intake until validation is complete.

Permanent fix: Restore POOL-FIN-01 to a known-good baseline by image rollback and graphics driver alignment to the known-good baseline, then reboot and validate hosts before returning them to service. This was applied and service was verified recovered at 10:00.

How to spot it: Look for Event 1000 (Application Error) showing dwm.exe faulting module igdumd64.dll with exception 0xc0000005, followed by Event 9009 (Desktop Window Manager exited) and Event 40 (session disconnected). On unaffected hosts, Event 9011 shows Desktop Window Manager started successfully and no matching Event 1000 entries in the same window.
