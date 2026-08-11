# RCA: Autopilot Enrolment Failure - Legacy MDM Conflict

Date: 2026-08-11
Status: Final
Incident type: Windows Autopilot enrolment failure
Primary cause: Conflicting legacy MDM enrolment record

## 1) Executive Summary
The device failed Autopilot enrolment because it already had an existing legacy manual MDM enrolment record from 2023-11-04. The export shows `EnrollmentState: Failed` and `ErrorCode: 0x80180014`, with the error description stating the device is already enrolled in MDM. That conflict prevented Autopilot from completing and left policy application incomplete at 0 of 4 profiles applied.

Licensing and network were not the issue. The device was Azure AD joined, had Intune P1 and Autopilot licensing, and had healthy network connectivity with all endpoints reachable and no proxy.

## 2) Supporting Evidence

### 2.1 Diagnostic export evidence
- `EnrollmentState: Failed`
- `ErrorCode: 0x80180014`
- `ErrorDescription: The device is already enrolled in MDM.`
- `MDMEnrolled: Yes (previous enrolment from 2023-11-04)`
- `EnrolmentSource: Legacy manual MDM enrolment`
- `ProfilesApplied: 0 of 4`
- `LastError: 0x80070005 (Access denied)`
- `AzureADJoined: Yes`
- `IntuneP1License: Yes`
- `AutopilotLicense: Yes`
- `Network: All endpoints reachable, no proxy`

### 2.2 Evidence interpretation
- The failure is not consistent with a licensing gap because both required licences are present.
- The failure is not consistent with a network outage because endpoint reachability is healthy.
- The failure is not consistent with Azure AD join absence because the device is already Azure AD joined.
- The device already had a previous MDM enrolment, which is the direct conflict that blocks a clean Autopilot enrolment.

## 3) Timeline
This timeline is based on the order of evidence available in the export and the remediation path taken.

1. 2023-11-04 - Legacy manual MDM enrolment exists on the device.
2. Current Autopilot attempt begins on a device that is already Azure AD joined.
3. Autopilot enrolment fails.
4. The diagnostic export records `EnrollmentState: Failed` and `ErrorCode: 0x80180014`.
5. The export reports `MDMEnrolled: Yes` and identifies the enrolment source as a legacy manual MDM enrolment.
6. Policy application does not complete and remains at 0 of 4 profiles applied.
7. The export records `LastError: 0x80070005 (Access denied)` during policy application.
8. Triage rules out licensing and network as contributing causes because both are healthy.
9. Root cause is confirmed as a stale conflicting MDM enrolment.
10. Remediation is defined to remove the stale enrolment, clear the associated identity records, return the device to OOBE, and rerun Autopilot.

## 4) Root Cause Statement
Primary root cause: a stale legacy manual MDM enrolment record remained on the device and conflicted with Autopilot enrolment.

Why this is the root cause:
- The export explicitly says the device is already enrolled in MDM.
- The export identifies the existing enrolment as a previous enrolment from 2023-11-04.
- The device had no licensing or network issue that would explain the failure.
- The observed state is consistent with a conflicting management identity rather than a transient service outage.

## 5) 5 Why Analysis

1. Why did Autopilot enrolment fail?
- Because the device already had an existing MDM enrolment record.

2. Why did an existing MDM enrolment record block Autopilot?
- Because Autopilot requires a clean management state and the legacy enrolment created a conflict.

3. Why was there a conflicting legacy enrolment on the device?
- Because the device had previously been enrolled manually in MDM on 2023-11-04.

4. Why was the legacy enrolment still present when Autopilot was attempted?
- Because the stale MDM record and related identity objects were not removed before reuse.

5. Why was the stale enrolment not removed before reuse?
- Because the device retirement-to-redeployment process did not include a mandatory clean-state check for legacy MDM records prior to Autopilot.

## 6) Corrective Action Taken or Required

### 6.1 Intune admin center actions
Admin center only unless otherwise stated.

1. Open Intune admin center.
2. Go to Devices > All devices.
3. Locate the affected device.
4. Confirm it matches the stale legacy enrolment.
5. Delete the stale Intune device record.
6. Check Microsoft Entra ID for the same device and delete the stale device object if present.
7. Review Devices > Windows > Windows enrollment > Devices for duplicate or stale Autopilot records and remove any matching stale entry.
8. If the device is still accessible, issue a Wipe action so it returns to OOBE and can enroll cleanly.

### 6.2 Device-side actions
Requires physical or remote device access unless the Intune Wipe action is used.

1. Open Settings > Accounts > Access work or school.
2. Disconnect the legacy work or school connection tied to the old MDM enrolment.
3. Restart the device.
4. If the device was not wiped remotely, perform a Windows reset to return it to OOBE.
5. Start Autopilot again after the device is clean.

## 7) Verification of Recovery
Confirm recovery only after both portal-side and device-side checks succeed.

### 7.1 Portal-side verification
- The stale Intune device record is gone.
- The stale Microsoft Entra device object is gone.
- No duplicate or stale Autopilot record remains for the same hardware.
- Policy deployment begins normally instead of stopping at 0 of 4 profiles applied.

### 7.2 Device-side verification
- The device reaches Autopilot OOBE and completes enrolment.
- No `0x80180014` conflict is returned.
- A new MDM enrolment is created successfully.
- Policy sync starts and profiles are applied.

### 7.3 Expected post-remediation export result
If the export is rerun after remediation, it should show:
- `EnrollmentState: Succeeded`
- No `0x80180014` conflict
- `ProfilesApplied` greater than 0
- No `0x80070005` failure during policy application

## 8) Preventive Actions
To prevent recurrence on other devices with legacy enrolments:

1. Add a mandatory pre-Autopilot clean-state check for every reused device.
2. Confirm no active legacy MDM enrolment exists in Intune before assigning Autopilot.
3. Confirm no stale Microsoft Entra device object exists before re-enrolment.
4. Require full removal of old management artifacts before a device is returned to service.
5. Include the clean-state check in the standard decommission-to-redeployment checklist and make it a release gate for all repurposed hardware.

## 9) Closure
This RCA is closed with a confirmed root cause: a stale legacy MDM enrolment blocked Autopilot enrolment. The corrective path is to remove the stale Intune and identity records, return the device to OOBE, and rerun Autopilot on a clean endpoint.