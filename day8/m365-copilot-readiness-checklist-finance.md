# Microsoft 365 Copilot Readiness Checklist — Finance Department
**Organisation:** Financial Services  
**Department:** Finance (~200 users)  
**Prepared by:** DWP Engineering  
**Date:** 2026-08-12  
**Licence baseline:** M365 E5 — Copilot add-on not yet assigned

---

> **Risk flag — inherited permissions.**  
> SharePoint permissions for this department were migrated in 2019 and have never been audited. Finance data includes payroll, board packs, M&A documents, and client financial data. Copilot surfaces content the user has access to — regardless of whether that access was intentional. **Complete Section 2 (Permissions & Oversharing) before assigning any Copilot licences.**

---

## Section 1 — Licensing Prerequisites

| # | Check | Owner | Done |
|---|-------|-------|------|
| 1.1 | Confirm all ~200 Finance users hold an active M365 E5 licence in Entra ID | Licence Admin | ☐ |
| 1.2 | Confirm Microsoft 365 Copilot add-on SKU has been procured (minimum 200 seats) | Licence Admin | ☐ |
| 1.3 | Verify no users are on legacy per-app plans (Project, Visio standalone) that may conflict with Copilot assignment | Licence Admin | ☐ |
| 1.4 | Do **not** assign Copilot licences until Sections 2–4 are complete | DWP Lead | ☐ |

---

## Section 2 — SharePoint / OneDrive Permissions & Oversharing Checks ⚠️ HIGHEST PRIORITY

> This section must be completed and signed off before any Copilot licence is assigned to Finance users.  
> Rationale: Copilot indexes all content the user can reach. Unintended broad access to payroll, M&A, or client data will be surfaced by Copilot queries from users who should not have that access.

### 2A — Audit Inherited Permissions (2019 Migration Debt)

| # | Check | Owner | Done |
|---|-------|-------|------|
| 2A.1 | Run SharePoint Admin Centre → **Access reviews** report across all Finance-owned site collections | SharePoint Admin | ☐ |
| 2A.2 | Export full permissions report for every Finance SharePoint site using `Get-SPOSiteGroup` / Microsoft 365 Assessment Tool | SharePoint Admin | ☐ |
| 2A.3 | Identify all sites still carrying **migrated 2019 groups** (look for groups prefixed with legacy domain or pre-migration naming convention) | SharePoint Admin | ☐ |
| 2A.4 | For each legacy group found: validate current membership is correct and intentional; remove stale accounts, leavers, and contractor accounts | SharePoint Admin | ☐ |
| 2A.5 | Identify any site where **"Everyone"**, **"Everyone except external users"**, or **"All Company"** has been granted access — remove immediately unless explicitly justified | SharePoint Admin | ☐ |
| 2A.6 | Review and remediate any **unique permissions** broken from parent (these are the hardest to track and commonly left over from migrations) | SharePoint Admin | ☐ |
| 2A.7 | Document and obtain sign-off from Finance department head on final permission state before Copilot go-live | DWP Lead / Finance Head | ☐ |

### 2B — High-Risk Content Areas (Finance-Specific)

| # | Check | Owner | Done |
|---|-------|-------|------|
| 2B.1 | Locate all libraries/folders containing **payroll data** — confirm access is restricted to Payroll team + HR only | SharePoint Admin | ☐ |
| 2B.2 | Locate all libraries/folders containing **board packs** — confirm access is restricted to Board members + ExCo distribution | SharePoint Admin | ☐ |
| 2B.3 | Locate all libraries/folders containing **M&A documents** — confirm access is restricted to deal team only; consider dedicated site with explicit membership | SharePoint Admin | ☐ |
| 2B.4 | Locate all libraries/folders containing **client financial data** — verify access aligns with data classification and client contractual obligations | SharePoint Admin | ☐ |
| 2B.5 | Check for any **externally shared** SharePoint sites or OneDrive folders owned by Finance users — review and revoke where not actively needed | SharePoint Admin | ☐ |

### 2C — OneDrive

| # | Check | Owner | Done |
|---|-------|-------|------|
| 2C.1 | Run OneDrive sharing report for Finance users — identify files shared "Anyone with the link" and revoke | SharePoint Admin | ☐ |
| 2C.2 | Set OneDrive sharing policy for Finance to **"Only people in your organisation"** or more restrictive — block "Anyone" links at tenant or site level | SharePoint Admin | ☐ |
| 2C.3 | Validate that OneDrive default sharing scope is set to **"Specific people"** for Finance users via SharePoint Admin Centre or Intune policy | SharePoint Admin | ☐ |

### 2D — Ongoing Controls (to be in place before go-live)

| # | Check | Owner | Done |
|---|-------|-------|------|
| 2D.1 | Enable **SharePoint Advanced Management (SAM)** data access governance reports if licenced — schedule monthly oversharing report | SharePoint Admin | ☐ |
| 2D.2 | Configure **Restricted SharePoint Search** to limit Copilot to a curated list of approved sites during initial rollout period | SharePoint Admin | ☐ |
| 2D.3 | Enable **site access reviews** on a quarterly cadence for all Finance site collections | SharePoint Admin | ☐ |

---

## Section 3 — Identity & MFA Readiness

| # | Check | Owner | Done |
|---|-------|-------|------|
| 3.1 | Confirm all 200 Finance users are registered for **MFA** in Entra ID (MFA registration report → zero gaps) | Identity Admin | ☐ |
| 3.2 | Confirm MFA method is **Microsoft Authenticator** (phishing-resistant preferred) — not SMS OTP | Identity Admin | ☐ |
| 3.3 | Verify Finance users are in scope of a **Conditional Access policy** requiring MFA for all cloud apps | Identity Admin | ☐ |
| 3.4 | Check no Finance users are in a legacy **MFA exclusion group** or named CA exclusion | Identity Admin | ☐ |
| 3.5 | Confirm all Finance user accounts are **cloud-only or hybrid-synced** with no on-prem-only accounts that would lack Entra licensing | Identity Admin | ☐ |
| 3.6 | Validate sign-in logs for Finance users — flag any accounts with no sign-in in last 90 days (potential stale accounts) | Identity Admin | ☐ |

---

## Section 4 — Microsoft 365 Apps Client Version

| # | Check | Owner | Done |
|---|-------|-------|------|
| 4.1 | Confirm Finance devices are running **Microsoft 365 Apps for Enterprise** (not Office 2019/2021 perpetual) | Endpoint/DWP | ☐ |
| 4.2 | Confirm M365 Apps build is **Version 2302 (Build 16130.20306) or later** — minimum required for Copilot features | Endpoint/DWP | ☐ |
| 4.3 | Recommended: target **Current Channel** or **Monthly Enterprise Channel** for Finance devices to receive Copilot feature updates promptly | Endpoint/DWP | ☐ |
| 4.4 | Validate update channel assignment via Intune / Microsoft 365 Apps admin centre — ensure Finance devices are not pinned to Semi-Annual Channel without exception approval | Endpoint/DWP | ☐ |
| 4.5 | Confirm **Microsoft Teams** client is up to date (new Teams preferred — classic Teams has reduced Copilot feature parity) | Endpoint/DWP | ☐ |

---

## Section 5 — Sensitivity Labelling

| # | Check | Owner | Done |
|---|-------|-------|------|
| 5.1 | Confirm **Microsoft Purview sensitivity labels** are published to Finance users in Microsoft Purview compliance portal | Compliance/DWP | ☐ |
| 5.2 | Verify Finance-relevant labels exist and are appropriately configured — at minimum: `Confidential`, `Highly Confidential`, `Internal` | Compliance/DWP | ☐ |
| 5.3 | Enable **auto-labelling policies** for Finance content types (payroll, financial statements, M&A) where feasible — reduces reliance on user classification | Compliance Admin | ☐ |
| 5.4 | Confirm **Copilot interaction data** (prompts and responses) will be classified — configure Purview label for Copilot-generated content if required by policy | Compliance Admin | ☐ |
| 5.5 | Validate that sensitivity labels apply **encryption and access restrictions** for `Highly Confidential` and above — not label-only with no protection | Compliance Admin | ☐ |
| 5.6 | Run a sample content scan (Purview Content Explorer) across Finance SharePoint sites — identify unlabelled documents at volume and schedule a labelling remediation sprint | Compliance Admin | ☐ |
| 5.7 | Brief Finance users on labelling obligations as part of Copilot enablement comms (see Section 6) | DWP / Finance Manager | ☐ |

---

## Section 6 — End-User Comms & Enablement

| # | Check | Owner | Done |
|---|-------|-------|------|
| 6.1 | Draft and send **pre-launch awareness email** to Finance team — cover what Copilot is, when it is coming, and what users need to do | DWP / Comms | ☐ |
| 6.2 | Deliver a **30-minute Copilot orientation session** for Finance — include live demo of Copilot in Word, Excel, Teams, and Outlook in a Finance context | DWP / Trainer | ☐ |
| 6.3 | Publish a **Finance-specific prompt guide** — example prompts relevant to their workflows (summarise board pack, draft variance commentary, analyse budget vs actuals) | DWP / Finance Lead | ☐ |
| 6.4 | Communicate **data responsibility expectations** clearly: Copilot respects permissions but users must still apply correct sensitivity labels and not share Copilot outputs containing confidential data inappropriately | DWP / Compliance | ☐ |
| 6.5 | Identify **2–3 Finance Copilot champions** to act as peer support and feedback channel post-launch | Finance Manager | ☐ |
| 6.6 | Set up a **feedback mechanism** (Teams channel or Viva Pulse survey) to collect early adoption blockers in weeks 1–2 | DWP | ☐ |
| 6.7 | Schedule a **2-week post-launch review** — attendance: DWP lead, Finance manager, Copilot champion(s) | DWP Lead | ☐ |

---

## Sign-Off Gate — Pre-Licence Assignment

All items in Sections 2A, 2B, and 3 must be marked complete and countersigned before Copilot licences are assigned to any Finance user.

| Role | Name | Signature | Date |
|------|------|-----------|------|
| DWP Engineering Lead | | | |
| SharePoint / IAM Admin | | | |
| Finance Department Head | | | |
| Information Security / Compliance | | | |

---

*Prepared by DWP Engineering. Review cadence: re-assess permissions section quarterly post-launch.*
