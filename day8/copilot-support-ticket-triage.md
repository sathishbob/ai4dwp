# Copilot Support Ticket Triage

**Date:** 2026-08-12  
**Engineer role:** DWP Copilot Support

---

## Ticket 1 — Finance lead: Copilot won't summarise the Q3 board pack in SharePoint

> "It's right there, I can see it myself."

| Field | Detail |
|---|---|
| **Likely cause** | 1. Sensitivity label restriction — board packs are commonly labelled Confidential/Highly Confidential, blocking Copilot grounding<br>2. Permissions/access boundary — Copilot respects item-level permissions which may differ from the user's browse rights<br>3. Data indexing lag — file recently uploaded and not yet indexed for Copilot grounding<br>4. Genuine Copilot fault |
| **Fastest check** | Open the file in SharePoint and check the sensitivity label banner; if labelled Confidential or higher, confirm whether the tenant policy permits Copilot to process that label tier. |
| **Is this actually a Copilot bug?** | No — the user can see the file, but Copilot grounding honours sensitivity labels and permission boundaries independently of browse access. These non-Copilot causes should be exhausted first. |

---

## Ticket 2 — New hire: Copilot in Outlook seems to know nothing about recent emails

> Started yesterday.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Data indexing lag — mailbox content for new accounts takes 24–72 hours to be indexed by Microsoft Search / Copilot grounding<br>2. License/client prerequisite issue — M365 Copilot license may not yet be fully provisioned or activated for a brand-new account<br>3. Genuine Copilot fault |
| **Fastest check** | Confirm the Copilot license is assigned and the service plan shows as active in the M365 admin center for this user. |
| **Is this actually a Copilot bug?** | No — new mailboxes have a well-documented indexing warm-up period; combined with potential license provisioning delay, both are expected non-bug causes. |

---

## Ticket 3 — HR manager: Got "I don't have access to that content" for a salary review spreadsheet

| Field | Detail |
|---|---|
| **Likely cause** | 1. Sensitivity label restriction — salary/HR data is almost always labelled at a tier that restricts Copilot grounding<br>2. Permissions/access boundary — file may be stored in a restricted HR site with item-level permissions the Copilot service principal cannot traverse<br>3. Genuine Copilot fault |
| **Fastest check** | Check the sensitivity label on the spreadsheet; also verify the user has direct (not inherited) edit/read permissions on the file itself, not just the parent site. |
| **Is this actually a Copilot bug?** | No — the explicit "I don't have access to that content" message is the expected Copilot response when a sensitivity label or permission boundary blocks grounding; this is by-design behaviour. |

---

## Ticket 4 — Sales rep: Copilot can't find a client contract shared via a guest link from another org

| Field | Detail |
|---|---|
| **Likely cause** | 1. Guest/external sharing limitation — content shared via an external guest link lives outside the user's own tenant index; Copilot only grounds against the user's home-tenant indexed content<br>2. Permissions/access boundary — guest-shared content does not flow into Microsoft Search indexing for the receiving user<br>3. Genuine Copilot fault |
| **Fastest check** | Confirm whether the file resides in the user's own tenant or in an external tenant; if external, Copilot grounding does not cover cross-tenant guest links by design. |
| **Is this actually a Copilot bug?** | No — cross-tenant guest link content is explicitly out of scope for Copilot grounding in the user's home tenant. This is a documented limitation, not a fault. |

---

## Ticket 5 — IT admin: Copilot stopped working for the whole Finance team this morning

> Was fine yesterday.

| Field | Detail |
|---|---|
| **Likely cause** | 1. License/client prerequisite issue — bulk license change, policy assignment update, or a conditional access / DLP policy applied to the Finance group overnight<br>2. Permissions/access boundary — a SharePoint or Entra group policy change affecting the Finance team<br>3. Genuine Copilot fault |
| **Fastest check** | Check the M365 admin center message center and audit log for any license, policy, or group changes applied to the Finance team in the last 24 hours. |
| **Is this actually a Copilot bug?** | Unclear — a team-wide simultaneous failure is unusual and warrants checking the Microsoft 365 service health dashboard for a Copilot service incident, but a group-level policy/license change is statistically more likely and should be checked first. |

---

## Ticket 6 — Manager: Copilot found and summarised a file I don't remember opening, from a folder I forgot I had access to

| Field | Detail |
|---|---|
| **Likely cause** | 1. Permissions/access boundary — Copilot correctly surfaced a file the user has legitimate permissions to; this is expected behaviour, not a fault |
| **Fastest check** | Confirm the user does in fact have read permissions on the folder/file in question (via SharePoint permissions or group membership). |
| **Is this actually a Copilot bug?** | No — Copilot respects existing permissions and can surface any content the user is authorised to access, regardless of whether they have navigated to it manually. This is working as designed. |

---

## Ticket 7 — Analyst: Copilot gives generic answers, doesn't use internal SharePoint content

| Field | Detail |
|---|---|
| **Likely cause** | 1. Data indexing lag — SharePoint content not yet indexed or crawl is behind<br>2. License/client prerequisite issue — Copilot license assigned but SharePoint/Graph connector prerequisites not fully configured<br>3. Permissions/access boundary — analyst may lack sufficient permissions on the SharePoint sites Copilot would need to ground against<br>4. Genuine Copilot fault |
| **Fastest check** | Run a Microsoft Search query in SharePoint for a known internal document; if Search also returns nothing, the issue is indexing/configuration rather than Copilot itself. |
| **Is this actually a Copilot bug?** | No — if Microsoft Search cannot find the content either, Copilot cannot ground against it. Copilot is dependent on the same index, so a search test quickly isolates whether the fault is upstream of Copilot. |

---

## Ticket 8 — Executive assistant: Copilot in Outlook can't see a shared mailbox calendar

> Manages calendar on behalf of the director.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Permissions/access boundary — Copilot grounds against the signed-in user's own mailbox/calendar index; delegate/shared mailbox access is not automatically included in Copilot grounding even with full mailbox permissions<br>2. License/client prerequisite issue — the shared mailbox itself does not hold a Copilot license, which may restrict grounding for delegates<br>3. Genuine Copilot fault |
| **Fastest check** | Confirm whether the shared mailbox has its own M365 Copilot license assigned; then check Microsoft's current documentation on delegate/shared mailbox support scope for Copilot in Outlook. |
| **Is this actually a Copilot bug?** | No — delegate and shared mailbox grounding has documented limitations in Copilot for Outlook. The assistant having "access" via delegation does not guarantee that content is included in Copilot's grounding scope for that user. |

---

*Triage principle applied: non-Copilot causes (permissions, labels, indexing, licensing, guest limitations) were ranked before genuine Copilot fault in every case. A genuine fault was only listed where no other cause was suggested by the ticket text.*
