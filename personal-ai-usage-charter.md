# Personal AI Usage Charter for a DWP Desktop/Endpoint Engineer

This charter sets my personal rules for using public AI assistants in day-to-day desktop and endpoint engineering work. It is intended to improve speed and quality without weakening security, privacy, or professional judgement. It does not replace DWP policy, security guidance, or line-management direction.

## 1. Appropriate Uses of Public AI Assistance

I will use public AI assistants for low-risk support work where the value is in structure, explanation, or draft technical output rather than access to DWP information.

Appropriate examples for desktop and endpoint work:

- Drafting PowerShell, Bash, batch, or command-line snippets from generic requirements.
- Explaining how Windows features, Intune concepts, Group Policy behavior, registry settings, event logs, services, certificates, scheduled tasks, or endpoint security controls generally work.
- Troubleshooting generic error patterns when I can describe the issue without exposing DWP-specific details.
- Rewriting or improving documentation, change notes, admin guides, SOPs, or communications in neutral terms.
- Producing checklists for endpoint rollout, device build validation, patch verification, software packaging, or incident triage.
- Generating test ideas, rollback steps, validation steps, or risk prompts for a desktop change.
- Summarising public vendor documentation or comparing public tools, protocols, or Windows management approaches.
- Converting rough logic into a draft script template using placeholder names and dummy values only.

## 2. Inappropriate Uses of Public AI Assistance

I will not use public AI assistants for any task that requires disclosure of DWP-sensitive material or where the assistant would be making decisions on production-impacting changes without proper review.

Not appropriate:

- Entering live incident details, internal tickets, asset lists, hostname conventions, tenant details, architecture, network information, security tooling configuration, or unpublished vulnerabilities.
- Sharing screenshots, logs, registry exports, config files, email content, or scripts that contain internal identifiers, usernames, device names, IP addresses, paths, URLs, or operational details.
- Asking for advice using production data, real user cases, or internal problem records.
- Uploading endpoint management exports, compliance reports, software inventories, detection rules, or policy settings from DWP environments.
- Using AI output as authority for security, legal, privacy, or operational decisions.
- Allowing AI to approve firewall, privilege, deployment, or remediation actions on my behalf.
- Using AI to generate content that bypasses controls, weakens security, or circumvents official process.

## 3. Data-Handling Rule for PII and Credentials

I will never place end-user PII, credentials, secrets, or any DWP internal operational data into a public AI assistant.

This includes:

- Names, usernames, email addresses, phone numbers, National Insurance numbers, dates of birth, addresses, case references, device identifiers linked to individuals, and any user-support narrative that could identify a person.
- Passwords, passphrases, MFA codes, API keys, tokens, certificates, private keys, recovery keys, connection strings, or privileged command output.
- If a prompt needs context, I will abstract it first: replace real values with placeholders, strip identifiers, remove metadata, and describe the pattern rather than the real record.

My default rule is simple: if I would not paste it into a public forum, I will not paste it into a public AI tool.

## 4. Generate Then Verify Rule for Scripts and System Changes

I may use AI to generate a first draft, but I own verification before any use on a device or in an environment.

My verification standard:

- I will read the full output and understand what every command or major step does.
- I will check for destructive actions, privilege requirements, external calls, hidden assumptions, and rollback impact.
- I will test in a safe environment first, using non-production devices or a controlled lab where possible.
- I will validate syntax, parameters, logging, error handling, and expected outcomes.
- I will compare the draft against official Microsoft, vendor, and DWP-approved guidance before use.
- I will not run AI-generated scripts blindly, especially where they change registry settings, local policy, services, drivers, startup items, security controls, or device management state.
- For system changes, I will keep a manual verification step and a rollback plan.

## Working Principle

Public AI can help me think, draft, and check, but it must never become a channel for DWP data leakage or a substitute for engineering judgement. I will use it for generic assistance, keep DWP data out, and treat every generated script or change as untrusted until verified.
