# Startup Performance Drop: Likely Cause Analysis (Ranked)

## Scope signals used
- Affected group only: Finance-Win11 (215 devices).
- Change point: 2026-08-04 02:00, security baseline deployed to Finance-Win11 only.
- Immediate shift after change: startup score 84 -> 61 (minus 23) on 2026-08-04; lowest 59 (minus 25) on 2026-08-05.
- Clean comparison: IT-Win11 (40 devices, no config change) stayed stable.

## 1) Startup compliance logging script added in the new baseline
- Why it fits:
  - The degradation starts immediately after the exact deployment window.
  - The script was introduced in the same change set and runs in startup flow, which directly matches the impacted metric.
  - IT-Win11 stayed stable and did not receive the change, which strongly supports a change-scoped effect.
- Fastest check:
  - Temporarily remove or disable the startup script for a small Finance pilot group (for example 15-20 devices) and compare next-login startup time and score within the same day.

## 2) Additional Defender scan policy increasing boot/login overhead
- Why it fits:
  - The same 02:00 deployment introduced an additional Defender scan policy to the affected group.
  - A sustained multi-day slowdown (not a one-time spike) is consistent with recurring scan load at startup/login.
  - The unaffected IT group had no new policy and no similar score drop.
- Fastest check:
  - On a small Finance pilot subset, set the new scan behavior to a delayed/off-hours schedule and compare startup metrics over the next 24 hours.

## 3) Combined effect of script + scan in one baseline causing compounded startup delay
- Why it fits:
  - Two startup-relevant controls were introduced together at one timestamp, and the impact appears immediately and persists.
  - The clean control group suggests the package deployed only to Finance is the differentiator, not a platform-wide event.
  - A combined load can produce larger drops than either control alone, matching a 23-25 point score decrease.
- Fastest check:
  - Run a short A/B split in Finance: one subset with script only, one with scan only, one with both; compare median startup within 1 business day to isolate additive impact.
