# Copilot Support — End-User Communications

**Date:** 2026-08-12  
**From:** DWP IT Support  
**Audience:** Individual ticket owners

---

## Ticket 1 — Finance lead (Q3 board pack won't summarise)

**Subject: Copilot and your Q3 board pack**

Hi,

Thanks for getting in touch. We understand Copilot isn't summarising the Q3 board pack even though you can open it yourself — this is a common source of confusion, so we want to explain what's happening.

Copilot follows the sensitivity label applied to a document. Board packs are often labelled **Confidential** or **Highly Confidential**, and our organisation's policy may restrict Copilot from processing content at that label tier, even for users who have full read access.

**Your next steps:**

1. Open the document in SharePoint and check the coloured sensitivity label banner at the top of the file.
2. If it shows Confidential or above, please raise a request with IT to review whether your role qualifies for Copilot access to content at that classification.
3. In the meantime, you can open the document directly and use Copilot **inside Word** once the file is open — this path may have different label handling depending on your policy.

We'll update you once we've confirmed the label policy in place for Finance documents.

---

## Ticket 2 — New hire (Copilot doesn't know about recent emails)

**Subject: Copilot in Outlook — what to expect in your first few days**

Hi and welcome to the team!

Good news: there's nothing wrong with your account. When a new mailbox is created, Microsoft needs 24–72 hours to index your emails so that Copilot can reference them. Until that indexing completes, Copilot will appear to have very limited awareness of your recent messages — this is completely normal.

**Your next steps:**

1. Wait until the end of your second or third working day and try Copilot again — it should start showing awareness of your emails by then.
2. If Copilot still doesn't reference your emails after 3 full working days, please reply to this message and we'll check whether your Copilot licence has been fully activated.
3. In the meantime, Copilot can still help you draft emails, rewrite text, and answer general questions — it just won't yet reference your specific inbox history.

No action needed right now — just give it a little time.

---

## Ticket 3 — HR manager (salary review spreadsheet access denied)

**Subject: Why Copilot can't access your salary review file**

Hi,

The message "I don't have access to that content" is Copilot telling you that the file is protected in a way that prevents it from reading it — this is intentional and a sign the data protection controls are working correctly.

Salary and HR data typically carries a **Restricted** or **Highly Confidential** sensitivity label, which blocks Copilot from grounding against it by policy. This protects sensitive personal data even from AI-assisted processing.

**Your next steps:**

1. Check the sensitivity label on the spreadsheet (visible in the banner when you open the file in Excel or SharePoint).
2. If you genuinely need Copilot to help you work with this data, please raise a formal request through your HR data governance contact — they can review whether an exception or alternative workflow is appropriate.
3. As an immediate workaround, you can open the file directly, copy the specific data you need to a new unlabelled document, and work with Copilot there — but please only do this in line with your data handling policy.

We cannot override sensitivity label restrictions without a governance approval. We'll support you through that process if needed.

---

## Ticket 4 — Sales rep (can't find contract shared via guest link)

**Subject: Copilot and files shared from external organisations**

Hi,

We've looked into this and the limitation here isn't a fault — it's a boundary in how Copilot works with external content.

When a file is shared with you via a **guest link from another organisation**, it lives in their Microsoft 365 environment, not ours. Copilot can only search and reference content that is stored and indexed within our own tenant. It has no visibility into files held externally, even if you can open them in your browser.

**Your next steps:**

1. Ask the external organisation to share the contract document directly (e.g. email attachment or a copy uploaded to our own SharePoint) so it lives within our tenant.
2. Once the file is in our SharePoint, Copilot will be able to find and reference it — allow up to an hour for indexing after upload.
3. If you need to regularly collaborate on documents with this client, speak to your manager about setting up a **shared Teams channel** — this brings external content into a structure Copilot can work with more reliably.

This is a known limitation and there's no workaround that keeps the file external — the document needs to be in our environment.

---

## Ticket 5 — Finance team (Copilot stopped working this morning)

**Subject: Copilot outage for Finance team — we're investigating**

Hi Finance team,

We're aware that Copilot stopped working for the team this morning and are actively investigating. We apologise for the disruption.

Our initial checks suggest this may be related to a configuration or licence change that was applied to the Finance group. We are reviewing admin logs and the Microsoft 365 service health dashboard to confirm the cause.

**What you should do now:**

1. Please do not log individual tickets — we're treating this as a single team-wide incident and working on it centrally.
2. If you have urgent work that depends on Copilot, please let your line manager know so they can prioritise accordingly while the issue is resolved.
3. We will send an update within **2 hours** with either a resolution or a confirmed timeline.

We'll keep you posted — thank you for your patience.

---

## Ticket 6 — Manager (Copilot found a file I didn't remember)

**Subject: Re your query about Copilot surfacing an unexpected file**

Hi,

Thanks for flagging this — we want to reassure you that what you experienced is expected behaviour, not a security issue.

Copilot surfaces content based on your existing permissions. If you have access to a folder (even one you haven't visited recently), Copilot may include files from that folder in its responses. It does **not** access anything beyond what your account is already authorised to see.

**What this means for you:**

1. The file Copilot found is one you legitimately have access to — it hasn't surfaced anything private or outside your permissions.
2. If you'd like to review which folders and sites your account has access to, we can run a permissions report for you — just reply to this message to request one.
3. If you believe you should **not** have access to that folder, please let us know and we can work with the site owner to review your permissions.

There is no security concern here, but we're happy to review your access if you'd like peace of mind.

---

## Ticket 7 — Analyst (Copilot gives generic answers, ignores internal content)

**Subject: Copilot not using internal SharePoint content — what we're checking**

Hi,

If Copilot is giving you generic answers and not drawing on your internal SharePoint documents, the most likely cause is that the content hasn't been fully indexed yet, or that Microsoft Search isn't finding it either.

Copilot relies on the same search index as Microsoft Search — if Search can't find something, neither can Copilot.

**Your next steps:**

1. Go to [SharePoint home](https://yourtenant.sharepoint.com) and use the search bar to look for a document you'd expect Copilot to know about. If Search can't find it either, the issue is upstream of Copilot and we need to investigate indexing.
2. If Search finds the document but Copilot doesn't, please send us the document name and site URL and we'll dig deeper.
3. Also confirm you have at least **read** permissions on the SharePoint sites in question — Copilot cannot reference content you don't have access to.

Please reply with the results of the Search test and we'll take it from there.

---

## Ticket 8 — Executive assistant (Copilot can't see the shared mailbox calendar)

**Subject: Copilot and your director's shared mailbox calendar**

Hi,

Thanks for raising this. The reason Copilot can't see the shared mailbox calendar is a current limitation in how Copilot for Outlook handles **delegate and shared mailbox access**.

Even though you have full delegate permissions to manage the calendar, Copilot currently grounds against your own mailbox and calendar only. Delegate access and shared mailbox content are not automatically included in Copilot's view.

**Your next steps:**

1. For calendar queries relating to your director, you'll need to open their calendar directly in Outlook and use Copilot from within that context where supported — check whether Copilot appears when you have the shared mailbox open in a separate window.
2. We will check whether the shared mailbox has an M365 Copilot licence assigned — this can sometimes extend Copilot's awareness to delegates. We'll update you on this shortly.
3. In the meantime, please continue managing the calendar manually as normal. We'll confirm whether a supported path exists for your use case.

We know this is frustrating given the nature of your role, and we'll work to find the best available option for you.

---

*These communications were prepared by DWP IT Support. For urgent issues, contact the IT helpdesk directly.*
