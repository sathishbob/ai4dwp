# Microsoft 365 Copilot Readiness — Three-Tier Ranking for Finance
**Organisation:** Financial Services  
**Department:** Finance (~200 users)  
**Prepared by:** DWP Engineering  
**Date:** 2026-08-12  
**Related document:** m365-copilot-readiness-checklist-finance.md

---

## Tier 1 — MUST complete before rollout (blocking)

These items are hard blockers. Rolling out Copilot without them creates either a technical failure or a live data exposure risk.

| Checklist item | Why it blocks rollout |
|---|---|
| **2A.1–2A.7** — Full audit of 2019 inherited permissions | See detailed justification below |
| **2B.1–2B.5** — High-risk content access checks (payroll, board packs, M&A, client data) | See detailed justification below |
| **2C.1–2C.3** — OneDrive oversharing controls | "Anyone with the link" files are indexed by Copilot; one Finance user prompting "summarise all payroll files I can access" could surface data across the whole department |
| **2D.2** — Restricted SharePoint Search configured | Acts as a safety net during initial rollout; limits Copilot's index scope to sites you've already audited |
| **3.1–3.4** — MFA registered and enforced via CA for all 200 users | Copilot licences attached to accounts without MFA enforcement are a direct identity compromise risk — the account becomes a high-value target with broad content access |
| **3.5–3.6** — No on-prem-only or stale accounts in Finance | Assigning Copilot to a dormant or on-prem-only account is both a licence waste and a security gap |
| **1.1–1.2** — E5 confirmed, Copilot SKU procured | Purely technical blocker — Copilot simply won't activate without the correct licence |
| **4.1–4.2** — M365 Apps for Enterprise at build 2302+ | Copilot features will not surface in the client below this build; rollout will fail silently |

---

## Tier 2 — SHOULD complete before rollout (high risk if skipped)

These items don't prevent Copilot from working but leave meaningful compliance or operational gaps that are much harder to remediate after users are already active.

| Checklist item | Risk if skipped |
|---|---|
| **5.1–5.2** — Purview labels published and Finance labels configured | Users will generate Copilot outputs with no classification applied; those outputs containing confidential content can be forwarded or stored without any DLP trigger |
| **5.5** — Encryption enforced on Highly Confidential labels | Labels without encryption are advisory only — Copilot-generated content summarising M&A data can leave the tenant with no technical control |
| **5.6** — Unlabelled content scan and remediation sprint | Copilot will summarise and cite unlabelled documents; large volumes of unclassified Finance data undermine any labelling policy in practice |
| **2D.1** — SharePoint Advanced Management reports enabled | Without ongoing oversharing reporting, permissions drift will immediately resume post-audit; you need the monitoring in place before users start prompting |
| **2D.3** — Quarterly site access reviews scheduled | One-time audit without a recurring mechanism is not a control, it's a snapshot |
| **4.3–4.4** — Update channel set to Current or Monthly Enterprise | Semi-Annual Channel users will fall behind on Copilot features within weeks; creates a two-tier experience and support overhead |
| **4.5** — New Teams client deployed | Classic Teams has materially reduced Copilot feature parity (meeting recap, chat summarisation); Finance users will have an incomplete experience |
| **1.3** — Legacy per-app plan conflicts checked | Rare but can cause silent licence assignment failures |

---

## Tier 3 — CAN complete during or after rollout (lower risk)

These items improve the experience and reduce longer-term risk, but their absence does not expose data or break functionality at go-live.

| Checklist item | Notes |
|---|---|
| **5.3** — Auto-labelling policies for Finance content types | Valuable but complex to configure correctly without false positives; can be tuned post-launch in simulation mode |
| **5.4** — Purview label for Copilot interaction data | Important for longer-term compliance logging, but not a day-one blocker if base labelling is in place |
| **5.7** — User briefing on labelling obligations | Covered adequately by Section 6 comms; reinforcement is iterative |
| **6.1** — Pre-launch awareness email | Should go out 1–2 weeks before rollout, so technically pre-launch, but authoring it is low-risk to defer until Tier 1 and 2 are clear |
| **6.2** — 30-minute orientation session | Can be delivered on day of rollout or week 1 |
| **6.3** — Finance-specific prompt guide | Adoption accelerator, not a safety control |
| **6.4** — Data responsibility comms | Important, but Tier 1 controls provide the technical backstop if users initially ignore guidance |
| **6.5–6.7** — Champions, feedback channel, 2-week review | Post-launch adoption and iteration activities by design |

---

## Why permissions/oversharing belongs in Tier 1 — not licensing or client version

**Licensing and client version are reversible, bounded failures.** If you assign Copilot before the build is at 2302, the feature doesn't appear — you update the client and it works. If the SKU isn't procured, assignment fails with a clear error. The blast radius of getting those wrong is zero data exposure and a support ticket.

**A permissions failure is irreversible and unbounded in this specific environment.** Here is why this Finance estate is materially different from a standard rollout:

**1. The 2019 migration permissions have never been audited.**
This is not theoretical risk — it is confirmed unknown state. In SharePoint migrations, group memberships, unique permissions, and broad "Everyone except external users" grants are routinely carried over verbatim from the source. Seven years of joiners, movers, and leavers have accumulated on top of that baseline with no review. The current access state for payroll, board packs, and M&A libraries is genuinely unknown.

**2. Copilot does not respect intended access — it respects actual access.**
A Finance analyst who has been silently sitting in a legacy SharePoint group from 2019 that grants read access to the board packs library has never used that access, has no idea they have it, and would never navigate there manually. The moment Copilot is enabled, a prompt like *"summarise last quarter's board discussion on the acquisition"* will return results — because the permissions say that user can read those files.

**3. The data categories are not recoverable if exposed.**
Payroll data, M&A documents, and client financial data are subject to regulatory obligations (GDPR, FCA principles, client NDAs). An internal oversharing incident — even one that doesn't leave the tenant — can trigger notification obligations, regulatory scrutiny, and reputational damage with the client counterparties whose data is held. You cannot un-surface a Copilot response that was seen.

**4. Licensing and client version have a clear remediation path post-error. Oversharing does not.**
Once a user has received a Copilot summary of a document they should not have accessed, the disclosure has occurred. Revoking the permission afterwards does not undo it.

**5. Restricted SharePoint Search (2D.2) is also Tier 1 for this reason.**
It acts as a second line of defence — limiting Copilot's index to a pre-approved site list — while the full permissions audit is completed. The combination of running the audit *and* enabling RSS means you are not relying on a single control in an environment where the baseline is unknown.

---

> **Summary:** Licensing and client version are pass/fail technical prerequisites with no data risk on failure. Permissions in this estate are a live, unquantified exposure risk that Copilot will actively exploit on day one if not remediated first.

---

*Prepared by DWP Engineering. Reviewed against: m365-copilot-readiness-checklist-finance.md*
