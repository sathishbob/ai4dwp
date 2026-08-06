# Triage Summary – T-1004 Company App Install Fails in Company Portal

## Summary (one line)
Company app installation fails from Company Portal with reported error 0x87D1041C.

## Impact (who/how many/business urgency)
- **Who:** Reporting end user/device (identity to-verify), potentially others assigned same app to-verify
- **How many:** 1 reported device/user; assignment-wide impact to-verify
- **Business urgency:** User cannot obtain required business application; urgency to-verify

## Known Facts
- Ticket reference: T-1004
- Channel: Company Portal
- Symptom: Company app fails to install
- Reported error: 0x87D1041C

## Missing Information to Gather
- Affected user, device name, and OS build details
- Exact app name/package and assignment type (required/available) (to-verify)
- Whether failure occurs on one device only or multiple assigned devices
- Whether device is compliant/managed and recently synced with management service
- Exact timestamp of failure and whether repeated retries show same result
- Available free disk space and network state during install attempt
- Whether other Company Portal apps install successfully on same device
- Whether recent policy/app deployment changes coincide with issue (to-verify)

## Likely Category
**Endpoint Management / Application Deployment – Company Portal Install Failure** (to-verify)

## First Diagnostic Step
Trigger a manual device sync from Company Portal/management settings, retry the install, and capture the retry timestamp to support correlation against deployment and device-management logs.