# Triage Summary – T-1003 AVD Session Disconnects After ~10 Minutes

## Summary (one line)
AVD session disconnects after about 10 minutes and then reconnects.

## Impact (who/how many/business urgency)
- **Who:** Reporting AVD user (identity to-verify), possible wider user set to-verify
- **How many:** 1 reported user; tenant/pool-wide impact to-verify
- **Business urgency:** Repeated interruptions reduce productivity and may risk unsaved work; urgency to-verify

## Known Facts
- Ticket reference: T-1003
- Service: AVD
- Symptom: Session disconnects after roughly 10 minutes
- Behavior: Session reconnects afterward

## Missing Information to Gather
- Affected user identity, host pool, and AVD client type/version
- Whether disconnect timing is consistent (always near 10 minutes) or variable
- Whether issue happens on home, office, and hotspot networks
- Whether multiple users in same host pool report similar behavior
- Exact user-visible message during disconnect/reconnect
- Whether local device sleep/power/network adapter settings might align with timing (to-verify)
- Whether issue occurs in full desktop, specific remote app, or both
- Time window and recurrence pattern for correlation with platform events (to-verify)

## Likely Category
**Virtual Desktop / Connectivity – Intermittent AVD Session Stability** (to-verify)

## First Diagnostic Step
Reproduce once while capturing exact timestamps and user-visible message, then check whether the same user disconnects on an alternate network (for example hotspot) to quickly isolate local network path versus AVD/session-host factors.