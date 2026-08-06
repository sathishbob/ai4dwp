# Triage Summary – T-1001 BitLocker Recovery Key Prompt Every Boot (New Win11 Laptop)

## Summary (one line)
New Windows 11 laptop is prompting for a BitLocker recovery key at every startup.

## Impact (who/how many/business urgency)
- **Who:** Assigned end user of the new laptop (user identity to-verify)
- **How many:** 1 reported device/user so far; wider scope to-verify
- **Business urgency:** Repeated boot interruption blocks or delays user access to work; urgency level to-verify

## Known Facts
- Ticket reference: T-1001
- Device type: New Windows 11 laptop
- Symptom: BitLocker recovery key prompt appears on every boot
- Frequency: Reported as every boot

## Missing Information to Gather
- Affected user details and device asset/serial reference
- Whether the user can successfully enter the recovery key and reach Windows each time
- When the issue started (first boot only or after updates/changes)
- Whether any firmware/BIOS/UEFI, boot order, TPM, or security setting changes were made before issue began (to-verify)
- Whether the device is domain/Azure AD joined and BitLocker key escrow location
- Exact recovery prompt screen details (for example, recovery reason text) and any event timing
- Whether multiple newly built laptops show the same behavior (build/image pattern check)
- Whether docking/USB/peripheral changes are present between successful/failed boots (to-verify)

## Likely Category
**Endpoint Security / Encryption – BitLocker Repeated Recovery Prompt** (to-verify)

## First Diagnostic Step
Validate access and key path first: confirm the user can enter the recovery key and sign in, then verify the correct recovery key is available in the approved key escrow source for that specific device before further troubleshooting.