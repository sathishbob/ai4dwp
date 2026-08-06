Root cause:
- Win11 upgrade uninstalled legacy VPN client.
- Intune did not auto-redeploy new client due to detection-rule gap.
- Impact: client absent/misdetected post-upgrade; internal connectivity unavailable until remediation.
- No data loss.

Exact action taken:
1. Removed stale VPN registry keys under:
- HKLM\SOFTWARE\<vendor>
2. Force-triggered Intune sync on affected endpoint.
3. Confirmed new VPN client deployment from Intune.
4. Applied split-tunnel configuration to new client profile.
5. Validated connectivity to all internal subnets.

Config detail:
- Registry cleanup scope: stale vendor VPN entries in HKLM\SOFTWARE\<vendor>.
- Deployment mechanism: Intune sync-triggered install of replacement VPN client.
- Network mode/profile: split-tunnel config applied post-install.

Verification step:
- Successful client deployment observed after sync.
- Connectivity test passed to all internal subnets.
- Outcome confirmed: service restored, no data loss.

Preventive action needed:
- Fix Intune detection rule gap so Win11-upgraded devices reliably trigger redeployment of the new VPN client when legacy client is removed.
- Add/retain post-upgrade validation for VPN client presence + split-tunnel policy application + internal subnet reachability.
