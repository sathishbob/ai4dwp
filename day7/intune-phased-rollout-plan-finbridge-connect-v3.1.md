Title: Phased Intune Deployment Plan - FinBridge Connect v3.1
Date: 2026-08-11
Author: DWP Engineering
Status: Draft

Scope:
- Application: FinBridge Connect v3.1 (.intunewin, already in Intune catalog)
- Fleet: 10,000 Windows 11 endpoints
- Deadline: Complete deployment by 2026-09-01 (3 weeks from 2026-08-11)
- Constraint: Finance (500 users) must be completed by end of week 1
- Risk cohort: 5% of devices with 4 GB RAM (about 500 devices)
- Rollback version: FinBridge Connect v3.0 (already in app catalog)

## 1. RING STRUCTURE

1. Ring 1 (Pilot)
- Size: 400 devices (4% of fleet).
- Duration: 4 calendar days.
- Who to include:
  - 150 IT and service-desk managed endpoints.
  - 150 business power users from non-finance departments.
  - 100 devices from the 4 GB RAM at-risk cohort.
- Purpose:
  - Validate install/uninstall commands, detection rule accuracy, and basic user experience.
  - Prove behavior on constrained hardware before scaling.
- Intune assignment group type:
  - Microsoft Entra ID security group (device-based), static membership for strict control.
  - Example group: GRP-APP-FINBRIDGE-V31-RING1-PILOT-DEVICES.

2. Ring 2 (Early)
- Size: 2,100 devices (21% of fleet).
- Duration: 6 calendar days.
- Who to include:
  - Early-adopter departments and business-critical but non-peak users.
  - Remaining medium-risk hardware not yet in Ring 1.
  - Exclude the unapproved 4 GB subset if Ring 1 shows degradation.
- Purpose:
  - Confirm operational stability at moderate scale and real support load.
  - Validate reporting quality (Installed/Failed/Not applicable trends) under larger assignment volume.
- Intune assignment group type:
  - Microsoft Entra ID dynamic device group for scalable targeting by department/device tags.
  - Example group: GRP-APP-FINBRIDGE-V31-RING2-EARLY-DEVICES.

3. Ring 3 (Broad)
- Size: 7,500 devices (75% of fleet).
- Duration: 8 calendar days.
- Who to include:
  - All remaining eligible Windows 11 endpoints.
  - Keep any quarantined 4 GB devices isolated until explicitly approved.
- Purpose:
  - Complete estate rollout within deadline with controlled monitoring checkpoints.
  - Finalize transition from v3.0 to v3.1 for standard estate.
- Intune assignment group type:
  - Microsoft Entra ID dynamic device group for all remaining eligible Win11 devices.
  - Example group: GRP-APP-FINBRIDGE-V31-RING3-BROAD-DEVICES.

4. Assignment mode for all three rings
- Use Required assignment for rollout enforcement.
- Use Available only for break-fix self-service testing, not as primary rollout control.
- Keep a dedicated exclusion group for devices on approved hold.

## 2. ADVANCE CRITERIA

1. Ring 1 to Ring 2 advance criteria (all must pass)
- Install success rate:
  - Minimum 97.0% within Ring 1.
  - Measured as Installed / (Installed + Failed) from Intune app device install status.
- Error rate threshold:
  - Maximum 3.0% Failed status in Ring 1.
- User-reported issue rate:
  - Maximum 2.0 tickets per 100 deployed devices in Ring 1.
  - Count only tickets tagged FinBridge-v3.1 and opened within the monitoring window.
- Monitoring period:
  - Minimum 48 hours after the last Ring 1 device reports first check-in post-assignment.
- Time-bound decision:
  - Go/No-Go decision held within 4 business hours after the 48-hour window closes.

2. Ring 2 to Ring 3 advance criteria (all must pass)
- Install success rate:
  - Minimum 98.0% within Ring 2.
  - Measured as Installed / (Installed + Failed) from Intune app device install status.
- Error rate threshold:
  - Maximum 2.0% Failed status in Ring 2.
- User-reported issue rate:
  - Maximum 1.5 tickets per 100 deployed devices in Ring 2.
- Monitoring period:
  - Minimum 72 hours after the last Ring 2 device reports first check-in post-assignment.
- Time-bound decision:
  - Go/No-Go decision held within 4 business hours after the 72-hour window closes.

3. Hold condition (pause without full rollback)
- Trigger:
  - Success rate between 95.0% and 97.0% in the active ring, with no business-critical failure and no crash trigger breach.
- Action:
  - Pause the next ring for 24 hours, keep current assignments in place, investigate root cause, and remediate packaging/detection or device targeting.
- Specific example:
  - 6% of devices show Failed but local checks confirm app installed; investigation finds detection value mismatch (3.1 vs 3.1.0). Update detection rule, force device sync, and re-evaluate before advancing.

## 3. ROLLBACK TRIGGERS

1. Install failure rate trigger (automatic halt)
- Condition:
  - Failed status reaches 8.0% or higher in any active ring over a rolling 4-hour window after assignment.
- Decision owner:
  - DWP Endpoint Duty Manager (primary) with App Platform Lead (secondary approval).
- Decision window:
  - 60 minutes from threshold breach alert.
- Exact Intune action:
  - Remove Required assignment of FinBridge Connect v3.1 from current and pending ring groups.
  - Add those same groups to FinBridge Connect v3.0 as Required.
  - Assign FinBridge Connect v3.1 as Uninstall to the impacted ring group if side-by-side is unsupported.

2. Application crash rate trigger (rollback consideration)
- Condition:
  - 2.0% or more of installed devices report 2 or more FinBridge app crashes per device within 24 hours.
- Data source:
  - Endpoint analytics/crash telemetry plus correlated service tickets.
- Decision owner:
  - DWP Endpoint Duty Manager, App Owner, and Major Incident Manager jointly.
- Decision window:
  - 2 hours from confirmed threshold breach.
- Exact Intune action if rollback approved:
  - Freeze further v3.1 assignments (remove Required from not-yet-started ring groups).
  - For impacted groups, set v3.1 assignment to Uninstall and set v3.0 to Required.

3. Business-critical failure trigger (immediate rollback regardless of percentage)
- Condition:
  - Finance cannot complete payment-run submission in production due to FinBridge v3.1 defect.
- Decision owner:
  - Major Incident Manager can authorize immediate rollback, with Finance Service Owner notified.
- Decision window:
  - Immediate execution, target start within 15 minutes of confirmation.
- Exact Intune action:
  - Remove Finance-targeted v3.1 Required assignments immediately.
  - Assign Finance group to v3.0 as Required.
  - If needed, assign v3.1 as Uninstall for the Finance rollback scope.

4. 4 GB RAM cohort trigger (ring isolation)
- Condition:
  - 4 GB RAM cohort shows 12.0% or higher Failed status within 24 hours, or ticket rate exceeds 5 per 100 devices in that cohort.
- Decision owner:
  - DWP Endpoint Engineering Lead.
- Decision window:
  - 4 business hours after threshold breach.
- Exact Intune action:
  - Move affected devices to exclusion group GRP-APP-FINBRIDGE-V31-HOLD-4GB.
  - Exclude that group from all v3.1 Required assignments.
  - Assign that group to v3.0 as Required until performance remediation is validated.

## 4. FINANCE DEADLINE RESOLUTION

1. Option A - Compress pilot to place Finance in Ring 2 by end of week 1
- Minimum safe pilot duration:
  - 72 hours (3 days) for Ring 1 with accelerated monitoring checkpoints every 12 hours.
- Risk introduced:
  - Reduced soak time may miss slower-burn issues (memory pressure, crash accumulation, delayed detection drift).
- Compensating control:
  - Add a Finance canary subgroup of 50 users first, hold 24 hours, then expand to remaining 450 only if canary meets Ring 1 thresholds.

2. Option B - Create a separate Finance priority Ring 0 before Ring 1
- Ring 0 structure:
  - 500 Finance users split into two waves: Wave A 100 users (day 1), Wave B 400 users (day 3-4 after pass).
  - Required assignment to static Finance device group.
- Ring 0 advance conditions:
  - Success rate at least 98.0% after 24 hours of Wave A.
  - Failed status no more than 2.0%.
  - No business-critical payment workflow failure.
- Ring 0 rollback plan:
  - If threshold breached, stop Wave B immediately.
  - Remove v3.1 Required from Finance group.
  - Assign v3.0 as Required to Finance group and, if required, set v3.1 as Uninstall.

3. Recommendation
- Choose Option B (Finance Ring 0) as the deployment strategy.
- Justification:
  - It meets the hard Finance deadline by end of week 1 without forcing the whole estate pilot to run too short.
  - It isolates highest-priority business users with dedicated monitoring and rollback.
  - It preserves full Ring 1 to Ring 3 control for the remaining 9,500 devices, reducing estate-wide risk while still meeting the 3-week deadline.
