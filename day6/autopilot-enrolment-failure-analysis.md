# Autopilot Enrolment Failure Analysis - Legacy MDM Conflict

Date: 2026-08-11
Status: Finalized
Scope: Windows Autopilot enrolment failure caused by a conflicting legacy MDM enrolment

## 1) Scope Facts Collected
- Enrolment failed.
- Error code: 0x80180014.
- Error description: The device is already enrolled in MDM.
- Existing MDM enrolment: Yes, previous enrolment from 2023-11-04.
- Enrolment source: Legacy manual MDM enrolment.
- Azure AD joined: Yes.
- Policy application: Failed, 0 of 4 profiles applied.
- Last error: 0x80070005 (Access denied).
- Licensing: Intune P1 Yes, Autopilot Yes.
- Network connectivity: Healthy, all endpoints reachable, no proxy.

## 2) Confirmed Root Cause
The device retained a stale legacy manual MDM enrolment record. That conflicting enrolment blocked Autopilot from completing and produced the observed 0x80180014 failure.

This is the only confirmed root cause in scope. No secondary hypothesis is needed for resolution.

## 3) Remediation Steps

### 3.1 Intune admin center actions
Admin center only unless stated otherwise.

1. Open the Intune admin center.
2. Go to Devices > All devices.
3. Search for the affected device using the device name, serial number, or user assignment.
4. Open the stale device record and confirm it matches the legacy MDM enrolment from 2023-11-04.
5. Delete the stale Intune device record.
6. If a matching device object exists in Microsoft Entra ID, delete that device object as well to remove the stale identity record.
7. Go to Devices > Windows > Windows enrollment > Devices and confirm there is no duplicate or stale Autopilot-related device entry for the same hardware.
8. If the device is still managed and reachable, issue a Wipe action from Intune so the endpoint returns to OOBE and can start clean Autopilot enrolment.

### 3.2 Device-side actions
Requires physical or remote access to the device unless Intune Wipe is used.

1. On the device, open Settings > Accounts > Access work or school.
2. Select the legacy work or school connection that corresponds to the old MDM enrolment.
3. Choose Disconnect to remove the local stale management connection.
4. Restart the device.
5. If the device was not wiped remotely from Intune, perform a full Windows reset so the device returns to the OOBE state required for Autopilot.
6. If a local reset is not available, use the Intune Wipe action instead of manual cleanup.

## 4) Correct Order of Operations
Use this order to avoid leaving conflicting identities behind.

1. Confirm the device is the affected endpoint and verify the stale enrolment details.
2. Delete the stale Intune device record.
3. Delete the matching Microsoft Entra ID device object if one exists.
4. Verify there are no duplicate or stale Autopilot device records for the same hardware.
5. Wipe or reset the device so the local stale enrolment is removed.
6. If local access is available, disconnect the legacy work or school account before or during reset.
7. Boot the device back to OOBE.
8. Start Autopilot again and allow the new enrolment to complete.

## 5) Verification Check
Confirm success only after both portal-side and device-side checks are clean.

### 5.1 Intune and identity verification
- The device appears as a fresh enrolment in Intune with no duplicate stale record.
- The previous legacy enrolment record is no longer present.
- The Microsoft Entra device object reflects the new Autopilot-managed identity state.
- Policy deployment starts normally instead of stopping at 0 of 4 profiles applied.

### 5.2 Device-side verification
- The device completes Autopilot at OOBE.
- User sign-in proceeds without the 0x80180014 enrolment conflict.
- A new MDM enrolment is created and policy sync begins successfully.

### 5.3 Recheck indicator
If you rerun the MDM diagnostic export after remediation, the expected result is:
- EnrollmentState: Succeeded
- No 0x80180014 enrolment conflict
- ProfilesApplied greater than 0
- No 0x80070005 access-denied failure during policy application

## 6) Preventive Action
Add a pre-Autopilot hygiene check for all reused or migrated devices:

1. Before assigning Autopilot or reusing a device, verify that no active legacy MDM enrolment exists in Intune or Microsoft Entra ID.
2. If a legacy enrolment exists, remove it first and return the device to a clean OOBE state before Autopilot is attempted.
3. Make this check part of the standard decommission-to-redeployment checklist so manual MDM enrolments do not flow into Autopilot again.

## 7) Final Resolution Statement
Autopilot failed because the device already had a legacy MDM enrolment record. The remediation is to remove the stale Intune and identity records, wipe or reset the device back to OOBE, then run Autopilot again so the device can create a clean enrolment and apply policy successfully.