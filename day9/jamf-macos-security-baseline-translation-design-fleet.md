Title: macOS Baseline to JAMF Configuration Profile Translation
Date: 2026-08-13
Author: DWP Engineering
Status: Draft

# macOS Security Baseline to JAMF Translation

Policy scope: JAMF Pro configuration profiles and related update/compliance workflows for a 25-device Design team fleet.

Baseline assumptions:
- Security baseline requirements were provided by DWP.
- Fleet type is user-assigned corporate macOS devices (not kiosk/shared lab devices).
- "Minimum macOS version" target is current stable minus one point release (N-1), maintained operationally each Apple release cycle.

## Important verification note (same discipline as Day 6 Intune labs)

JAMF Pro UI labels, payload naming, and control placement can vary by JAMF Pro version and by Apple platform changes. Do not trust any exact label here without verifying in your own tenant UI.

For every setting flagged as Verify label in JAMF, validate in your own instance:
- Exact payload path and display name
- Whether the setting is under a native payload, Custom Settings, Smart Group criteria, or Software Update/Policy workflow
- Whether the setting applies consistently to your target macOS version set

## Likely UI path (verify in your tenant)

Use this common path for profile creation/editing:
- JAMF Pro > Computers > Configuration Profiles > New

Typical profile workflow sections:
- General
- Scope
- Payloads
- Distribution Method / User Level (if shown in your UI)
- Save / Deploy

UI drift flag:
- High. Several controls below can move between payload families or become partially managed by declarative/software update workflows depending on JAMF/macOS versions.

---

## Requirement mapping (summary table)

| # | Requirement | Payload type | Value | Effect | False-positive risk | Naming drift flag |
|---|---|---|---|---|---|---|
| 1 | FileVault disk encryption must be enabled | Security & Privacy (FileVault payload) | Enable FileVault and escrow recovery key to JAMF | Encrypts data at rest and supports secure recovery operations | Encryption in progress, deferred enablement at logout, escrow not yet reported in inventory | Verify label in JAMF |
| 2 | Gatekeeper must be enabled (identified developers only) | Restrictions or Security & Privacy (Gatekeeper controls) | Allow App Store and identified developers only | Prevents unsigned/untrusted app execution by default | Temporary local override, notarization delay, stale inventory | Verify label in JAMF |
| 3 | Minimum macOS version: stable N-1 | Smart Group compliance logic + remediation policy/software update workflow | Dynamic version check and remediation for versions below N-1 | Keeps endpoints inside supported security patch window | OS inventory lag, beta/RC version strings, parsing mismatch | Verify label in JAMF |
| 4 | Firewall must be enabled | Security & Privacy (Firewall payload) | Enable macOS Application Firewall | Reduces exposure to unsolicited inbound traffic | Third-party firewall overlap, exceptions interpreted as disabled by custom checks | Verify label in JAMF |
| 5 | Password required after sleep/screen saver | Security & Privacy or Login Window related keys | Require password immediately after sleep or screen saver | Stops unattended access after idle/sleep | Grace-period key conflict, session handoff edge cases, local cache delay | Verify label in JAMF |
| 6 | Automatic security updates enabled | Software Update payload and/or managed update workflow | Enable automatic security updates and system data updates | Reduces patch latency and human dependency | Device offline, update deferral/reboot pending, Apple catalog delay | Verify label in JAMF |

---

## Detailed requirement translation

### Requirement 1: FileVault disk encryption must be enabled

- Payload type: Security & Privacy > FileVault
- Value:
	- Enable FileVault
	- Escrow personal recovery key to JAMF
	- Institutional recovery key optional per organization policy
- Effect: Device data remains unreadable if the endpoint is lost or stolen, and support can recover access through approved recovery workflows.
- False-positive risk:
	- Device is compliant-in-progress while full disk encryption is still converting.
	- User postpones required logout/restart prompt.
	- Recovery key escrow succeeds locally but inventory has not updated yet.
- Verify label in JAMF: Yes (high)
- Operational recommendation:
	- Enforce deadline messaging for enablement.
	- Track three states in reporting: enabled, in progress, pending user action.

### Requirement 2: Gatekeeper must be enabled (identified developers only)

- Payload type: Restrictions or Security & Privacy (location depends on JAMF/macOS version)
- Value: Set app execution policy to App Store and identified developers only.
- Effect: Only trusted and signed software runs by default, reducing malware and unsigned tooling risk.
- False-positive risk:
	- Admin-approved one-time overrides (context menu Open) can look like a policy bypass in some audits.
	- Developer or design software may be newly signed/notarized, causing temporary launch frictions and inconsistent telemetry.
	- Inventory collection delay can show older Gatekeeper state.
- Verify label in JAMF: Yes (high)
- Operational recommendation:
	- Maintain an exception review process for legitimate creative tools.
	- Record exception owner, expiration date, and compensating controls.

### Requirement 3: Minimum macOS version equals current stable minus one point release

- Payload type: Typically not a single payload checkbox. Implement through:
	- Smart Group criteria for minimum OS version
	- Remediation policy/software update workflow scoped to out-of-date devices
- Value: Define N-1 minimum version and update each Apple stable release cycle.
- Effect: Devices behind the supported patch window are identified and remediated.
- False-positive risk:
	- Device upgraded but inventory has not refreshed.
	- Beta/RC builds return version strings that fail exact match logic.
	- Strict string comparisons miss build variants if criteria are not normalized.
- Verify label in JAMF: Yes (high)
- Operational recommendation:
	- Use normalized version comparison logic where possible.
	- Maintain release cadence runbook to update N-1 threshold quickly.

### Requirement 4: Firewall must be enabled

- Payload type: Security & Privacy > Firewall
- Value: Enable Application Firewall. Optionally enforce stealth mode if required by your baseline.
- Effect: Inbound connection surface is reduced, lowering lateral-movement and unsolicited access risk.
- False-positive risk:
	- Third-party security tooling can alter expected local firewall keys.
	- Service-specific allow rules may be interpreted as firewall disabled by simplistic checks.
	- Telemetry lag between local state and JAMF inventory snapshot.
- Verify label in JAMF: Yes (medium)
- Operational recommendation:
	- Standardize one source of truth for host firewall state reporting.
	- Validate with both profile status and local command output during pilot.

### Requirement 5: Login password required after sleep/screen saver

- Payload type: Security & Privacy (General/password-related keys) and in some builds Login Window related controls
- Value: Require password immediately after sleep or screen saver starts (no delay).
- Effect: A user must authenticate after idle/sleep transitions, preventing walk-up access to unlocked sessions.
- False-positive risk:
	- Local delay values (for example non-zero grace seconds) conflict with strict compliance checks.
	- Fast User Switching/session handoff behaviors can temporarily mask effective policy.
	- Cached preference states can appear stale until next login cycle.
- Verify label in JAMF: Yes (high)
- Operational recommendation:
	- Enforce zero-delay where baseline requires strict interpretation.
	- Pilot with design users who dock/undock frequently to catch workflow edge cases.

### Requirement 6: Automatic security updates enabled

- Payload type: Software Update payload and/or managed software update controls
- Value:
	- Enable automatic check/download/install for security updates
	- Enable background system data/security response updates
- Effect: Security fixes land with less user dependency and lower mean time to patch.
- False-positive risk:
	- Device is offline during maintenance window.
	- Update downloaded but pending reboot appears non-compliant.
	- Apple update catalog timing means update is not yet visible locally.
- Verify label in JAMF: Yes (high)
- Operational recommendation:
	- Pair automatic update settings with restart communication and deadline strategy.
	- Report pending-restart separately from missing-update state.

---

## Implementation notes for JAMF policy authors

- Keep detection separate from remediation:
	- Detection via smart groups/compliance views
	- Remediation via scoped policies and update workflows
- For a 25-device design fleet, use phased rollout:
	- Wave 1: 3-5 pilot devices
	- Wave 2: remaining devices after 48-72 hours of stable telemetry
- Protect creative productivity:
	- Coordinate update windows around rendering or large export cycles.
	- Pre-test any Gatekeeper-sensitive creative tooling.
- Prefer explicit state categories in dashboards:
	- Compliant
	- Non-compliant
	- Pending (encrypting, updating, reboot required, inventory stale)

## Post-deployment validation steps

Use this after profile deployment and at least one inventory cycle.

### 1) Where to validate in JAMF

- Profile-centric view:
	- JAMF Pro > Computers > Configuration Profiles
	- Open the baseline profile
	- Review deployment and per-device status
- Device-centric view:
	- JAMF Pro > Computers > Search Inventory
	- Open a test device
	- Review Security, Operating System, and profile status fields relevant to each control

### 2) Local command checks on a test Mac

Use these to validate effective local state when JAMF inventory seems inconsistent.

- FileVault:
	- fdesetup status
- Gatekeeper:
	- spctl --status
- macOS version:
	- sw_vers -productVersion
- Firewall:
	- /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
- Password after sleep/screensaver (key presence and values):
	- defaults read /Library/Preferences/com.apple.screensaver askForPassword
	- defaults read /Library/Preferences/com.apple.screensaver askForPasswordDelay
- Software update automation keys:
	- defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled
	- defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload
	- defaults read /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall
	- defaults read /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall

### 3) Common triage patterns

FileVault looks non-compliant but appears enabled:
- Confirm encryption completion and not just encryption started.
- Confirm user completed logout/restart step.
- Confirm recovery key escrow arrived in JAMF inventory.

OS version looks stale after update:
- Trigger inventory update/check-in.
- Re-check Smart Group criteria logic for semantic version comparison.
- Verify device is not on beta/RC branch excluded from your production criteria.

Auto updates enabled but patch missing:
- Confirm device online time during update window.
- Check for pending reboot blocking final state.
- Validate update catalog availability for that hardware/region.

## Suggested evidence fields for audit reporting

- FileVault enabled state and escrow timestamp
- Gatekeeper state and exception records (if any)
- macOS version plus build number
- Firewall state and managed exceptions summary
- Password-after-sleep keys and effective delay value
- Last security update install time and pending reboot marker
