# Triage Summary – T-1007 OneDrive Stuck Processing Changes Since Migration

## Summary (one line)
OneDrive has been stuck on "processing changes" since migration and some files are missing locally.

## Impact (who/how many/business urgency)
- **Who:** Reporting user (identity to-verify), potentially others migrated in same wave to-verify
- **How many:** 1 reported user; migration cohort impact to-verify
- **Business urgency:** Local file availability and productivity impacted; potential risk to user confidence in sync state

## Known Facts
- Ticket reference: T-1007
- Service: OneDrive sync client
- Symptom: Stuck on "processing changes"
- Additional symptom: Files reported missing locally
- Context: Issue reported since migration

## Missing Information to Gather
- User identity, device details, and migration wave/timing
- Whether files are visible in OneDrive web but missing only locally
- Approximate number/type/size of missing files and folders
- Whether OneDrive client is signed in correctly and account matches expected tenant (to-verify)
- Available local disk space and path constraints (to-verify)
- Whether sync pauses/errors are shown in client status details
- Whether issue affects a specific library/folder or all synced content
- Whether this is isolated or seen by multiple recently migrated users

## Likely Category
**File Sync / Data Access – OneDrive Post-Migration Sync Degradation** (to-verify)

## First Diagnostic Step
Verify data location first by checking whether the "missing" files are present in OneDrive on the web for the same account; this distinguishes local sync-client issues from potential data-location/migration issues.