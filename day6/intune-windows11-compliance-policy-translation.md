Title: Windows 11 Baseline to Intune Compliance Policy Translation
Date: 2026-08-10
Author: DWP Engineering
Status: Draft

# Windows 11 Intune Compliance Policy Translation

Policy scope: Intune device compliance policy for platform Windows 10 and later (applies to Windows 11).

Baseline assumptions:
- Security baseline requirements were provided by DWP.
- Minimum accepted Windows 11 build provided as N-1 = 22621.2861.

## Latest UI path (validated against tenant UI on 2026-08-11)

Use this path to create/edit the policy:
- Intune admin center > Devices > Compliance > Policies > Create policy

Create policy selections:
- Platform: Windows 10 and later
- Profile type: Windows 10/11 compliance policy

Wizard tabs shown in current UI:
- Basics
- Compliance settings
- Actions for noncompliance
- Assignments
- Review + create

Basics tab entries (recommended):
- Name: DWP - Windows 10/11 Compliance Baseline - Core Security - N-1 (22621.2861)
- Description: Enforces DWP Windows 11 endpoint compliance baseline: BitLocker, Secure Boot, minimum OS version 10.0.22621.2861, Defender real-time protection, Firewall, password/PIN requirement, and 7-day noncompliance grace period.

Then configure required controls in:
- Compliance settings > Device health
- Compliance settings > Device properties
- Compliance settings > System security
- Actions for noncompliance

UI drift flag:
- High. Older documentation and some tenants show Devices > Manage devices > Compliance or older compliance policy entry points. Your tenant uses the newer Devices > Compliance route and requires explicit Profile type selection.

## Requirement mapping

### Requirement 1: BitLocker must be enabled on the OS drive

- Settings name: Require BitLocker
- Value: Require
- Effect: Device is compliant only if OS-drive BitLocker state is attested as enabled.
- False-positive risk: BitLocker can be enabled but still show noncompliant until next reboot, because attestation is boot-time based.
- Recommendation: Keep this as Require, and add user comms/automation to force a reboot after encryption completion to reduce temporary false noncompliance.
- Latest UI path: Compliance settings > Device health > Require BitLocker
- UI-path change risk: Low

### Requirement 2: Secure Boot must be enabled

- Settings name: Require Secure Boot to be enabled on the device
- Value: Require
- Effect: Device is compliant only if Secure Boot is on and attested by device health services.
- False-positive risk: Legacy BIOS devices or devices without compatible TPM/UEFI support can appear noncompliant even if otherwise healthy for their hardware class.
- Recommendation: Keep as Require, and scope policy to supported Windows 11 hardware (UEFI + TPM 2.0) using assignment filters/dynamic groups.
- Latest UI path: Compliance settings > Device health > Require Secure Boot to be enabled on the device
- UI-path change risk: Low

### Requirement 3: Minimum OS build (N-1)

- Settings name: Minimum OS version
- Value: 10.0.22621.2861
- Effect: Devices below build 22621.2861 are marked noncompliant.
- False-positive risk: Build parsing issues can occur if administrators enter only build numbers (for example 22621.2861) without the full major.minor prefix required by Intune.
- Recommendation: Use full format 10.0.22621.2861, and review update rings so eligible devices can remediate quickly.
- Latest UI path: Compliance settings > Device properties > Operating system version > Minimum OS version
- UI-path change risk: Medium (some tenants now also use Valid operating system builds for finer control)

### Requirement 4: Windows Defender real-time protection must be on

- Settings name: Real-time protection
- Value: Require
- Effect: Device is compliant only when real-time protection is enabled.
- False-positive risk: Coexistence with third-party AV or Defender passive mode can produce unexpected noncompliance if Defender RTP is not actively on.
- Recommendation: Keep as Require, and standardize endpoint AV posture (Defender active mode where required). If third-party AV is allowed, validate with pilot devices first.
- Latest UI path: Compliance settings > System security > Defender > Real-time protection
- UI-path change risk: Medium (Defender section labels can vary slightly between portal builds)

### Requirement 5: Firewall must be enabled for all profiles

- Settings name: Firewall
- Value: Require
- Effect: Device is compliant only when Windows Firewall is enabled and users cannot disable it.
- False-positive risk: Conflicting GPO or local firewall configuration can cause noncompliance even when an Intune configuration attempts to enable firewall.
- Recommendation: Keep as Require. Remove conflicting GPO firewall controls and manage firewall centrally via Intune Endpoint security > Firewall to enforce per-profile detail.
- Latest UI path: Compliance settings > System security > Device security > Firewall
- UI-path change risk: Low

### Requirement 6: A PIN or password must be configured

- Settings name: Require a password to unlock mobile devices
- Value: Require
- Effect: Device requires user authentication (PIN/password) before access.
- False-positive risk: Shared/kiosk scenarios, unusual sign-in models, or conflicting local policy can report noncompliant despite intentional access design.
- Recommendation: Keep as Require for user-assigned endpoints; exclude kiosk/shared exceptions into a separate compliance policy with compensating controls.
- Latest UI path: Compliance settings > System security > Password > Require a password to unlock mobile devices
- UI-path change risk: Medium (label is legacy worded but is still the active Windows compliance setting name)

### Requirement 7: Device must not be jailbroken or rooted

- Settings name: No direct built-in Windows 10 and later compliance setting
- Value: Not applicable in Windows compliance profile
- Effect: Intune Windows compliance does not expose a jailbreak/root toggle like mobile platforms.
- False-positive risk: None from this specific setting because it does not exist for Windows.
- Recommendation: Use compensating controls without weakening security:
  - Add Device health attestation controls already listed (BitLocker, Secure Boot, Code integrity if required).
  - Add Microsoft Defender for Endpoint compliance integration: Require the device to be at or under the machine risk score (for example Low).
  - Consider custom compliance script only if you have a defined root-compromise signal and a low-noise detection method.
- Latest UI path: N/A (no native setting in Windows compliance)
- UI-path change risk: N/A

## Grace period requirement (7 days for all settings)

Configure this once at policy level:
- Tab: Actions for noncompliance
- Default action: Mark device noncompliant
- Schedule (days after noncompliance): 7

Effect:
- A device that fails any setting enters InGracePeriod for 7 days before final noncompliant enforcement.

False-positive risk:
- Not a detection false positive, but delayed enforcement can hide genuine risk during grace window.

Recommendation:
- Keep 7 days per requirement, but pair with immediate user notification (email or Company Portal messaging) on day 0 so remediation starts immediately.

Latest UI path:
- Wizard tab: Actions for noncompliance > Mark device noncompliant > Schedule (days after noncompliance)

UI-path change risk:
- Low

## Implementation notes for policy authors

- Requirement 5 says all firewall profiles; compliance validates firewall state but does not replace profile-level firewall rule management. Enforce profile specifics in Endpoint security firewall policy.
- Requirement 7 is a platform terminology mismatch for Windows; treat it as "no evidence of system compromise" and enforce through Defender for Endpoint risk and device health attestation.
- Run a pilot assignment first to identify hardware/model cohorts that fail attestation due to firmware/TPM state rather than true security drift.

## Post-assignment validation steps (after device sync)

Use this section when the policy is already assigned and a test device has just synced.

### 1) Where to check this specific policy result in Intune

Primary path (policy-centric):
- Intune admin center > Devices > Compliance > Policies
- Open policy: Windows 10/11 compliance policy (or your named policy)
- Open: Device status
- Search/select the test device
- Open per-setting details and verify each control (for example, Require BitLocker)

Alternative path (device-centric):
- Intune admin center > Devices > All devices
- Select the test device
- Open: Device compliance
- Select this Windows 10/11 compliance policy to view setting-level results

### 2) Compliance state meaning and Conditional Access impact

Assumption: A Conditional Access policy is configured with grant control "Require device to be marked as compliant".

- Compliant:
  - Device satisfies required compliance settings.
  - Conditional Access permits access (subject to other CA controls).

- Not compliant:
  - Device failed one or more required settings, and grace is expired (or no grace exists).
  - Conditional Access blocks access to resources requiring compliant device.

- In grace period:
  - Device currently fails one or more required settings, but the noncompliance schedule delay is still active.
  - With this policy design (7 days), device is temporarily allowed remediation time before full noncompliant enforcement.
  - After day 7, unresolved failures become Not compliant and are blocked by CA where compliant device is required.

### 3) BitLocker false positive triage (device shows noncompliant but BitLocker is enabled)

Most common cause A: Boot-time attestation not refreshed yet
- Why it happens: Device Health Attestation values are commonly refreshed at boot.
- Fastest check:
  - Check whether device rebooted after encryption completion, feature update, or recent policy change.
  - If not, reboot once, sync from Company Portal/Settings, then recheck compliance.

Most common cause B: BitLocker protection is suspended
- Why it happens: Upgrade/firmware workflows can suspend protection while drive remains encrypted.
- Fastest check:
  - Run: manage-bde -status C:
  - Confirm Protection Status = Protection On.
  - If suspended/off, resume protection, reboot, sync, and re-evaluate.

Most common cause C: Encryption not fully completed on OS drive at evaluation time
- Why it happens: Device reports encrypted state inconsistently while conversion is still in progress.
- Fastest check:
  - Run: manage-bde -status C:
  - Confirm Conversion Status = Fully Encrypted and Percentage Encrypted = 100%.
  - If incomplete, wait for completion, reboot, sync, then recheck compliance.

### First 24-hour monitoring checks after assignment

- In policy Device status, track counts of Compliant, In grace period, and Not compliant hourly.
- In per-setting reports, isolate failures for Require BitLocker and watch trendline after reboot waves.
- Slice failures by OS build, device model, and manufacturer to identify cohort-specific drift.
- Validate a sample of flagged devices using manage-bde output to confirm whether failures are attestation lag versus true control failure.
- Escalate if Not compliant trend does not decline after one reboot cycle and two sync cycles.
