# Triage Summary – T-1008 VPN Connects but No Internal Resources Reachable After Win11 Upgrade

## Summary (one line)
VPN reports connected, but internal resources are unreachable after Windows 11 upgrade.

## Impact (who/how many/business urgency)
- **Who:** Reporting user/device after upgrade; wider upgraded user impact to-verify
- **How many:** 1 reported user/device; broader scope to-verify
- **Business urgency:** User cannot access internal business resources remotely; urgency to-verify

## Known Facts
- Ticket reference: T-1008
- Device state: Upgraded to Windows 11
- Symptom: VPN connects successfully
- Symptom: Internal resources are not reachable while connected

## Missing Information to Gather
- Affected user/device details and VPN client/profile used
- Which internal resources fail (file shares, intranet, remote apps, DNS names, IP-based resources)
- Whether any internal resources are reachable at all or none
- Whether issue began immediately after upgrade or later
- Whether DNS resolution differs on/off VPN (to-verify)
- Whether same user can access resources from another device on same network
- Whether split-tunnel/full-tunnel behavior is expected for this profile (to-verify)
- Whether multiple Win11-upgraded users show same pattern

## Likely Category
**Remote Access / Network – VPN Connected but Internal Reachability Failure** (to-verify)

## First Diagnostic Step
While VPN is connected, test one known internal resource by both hostname and IP (where available) and record results; this quickly indicates whether the failure is likely name-resolution/pathing versus broader tunnel reachability.