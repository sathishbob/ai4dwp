# Triage Summary – T-1005 Teams Audio Dead on Three Machines in Same Meeting Room

## Summary (one line)
Teams audio is not working on three machines in the same meeting room.

## Impact (who/how many/business urgency)
- **Who:** Meeting room users on three affected machines
- **How many:** At least 3 devices in one room; wider room/site impact to-verify
- **Business urgency:** Active collaboration and meetings disrupted for multiple users; urgency to-verify

## Known Facts
- Ticket reference: T-1005
- Application: Microsoft Teams
- Symptom: Audio is non-functional
- Scope indicator: Three machines in the same meeting room

## Missing Information to Gather
- Whether issue is mic, speaker, or both directions of audio
- Whether problem is Teams-only or affects all system audio
- Exact devices/peripherals in use (headset, dock, room audio hardware)
- Whether users changed default input/output devices before issue
- Whether Teams device settings show expected microphone/speaker selections
- Whether mute states (hardware/software) are active on any component
- Whether issue is specific to one meeting or reproducible across meetings/apps
- Recent room hardware, driver, update, or cabling changes (to-verify)

## Likely Category
**Collaboration / AV Peripherals – Meeting Room Audio Failure** (to-verify)

## First Diagnostic Step
On one affected machine, run a quick isolation check by testing system sound playback and Teams test call with confirmed input/output device selection; if both fail, treat as room/peripheral path first rather than user account issue.