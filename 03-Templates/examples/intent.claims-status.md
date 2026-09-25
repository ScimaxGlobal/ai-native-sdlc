---
id: INT-2026-014
title: "Claims status self-service in the customer portal"
author: "Dana Okafor <dana.okafor@example-insurer.com>"   # contact-center operations lead (non-engineer)
created: 2026-09-08
status: accepted
product_owner: "Priya Raman"
legacy_record: "JIRA CLM-1427"
source_of_truth: repo
links:
  spec: work/CLM-1427-claims-status-self-service/spec.md
  plan: work/CLM-1427-claims-status-self-service/plan.md
  origin: "Contact-center Q3 call-reason report"
---

# Claims status self-service in the customer portal

## Problem

Policyholders who have filed a claim cannot see where it stands, so they call.
In the Q3 call-reason report, **about one third of contact-center call time
(34% of handled minutes)** was spent answering "what is the status of my
claim?" These calls are short to answer but long to wait for, they tie up
agents who are needed for first-notice-of-loss and complex cases, and they
generate repeat calls when the answer is "still being reviewed".

## Proposed outcome

Policyholders signed in to the existing customer portal can see the current
status of each of their open claims, what that status means, and what (if
anything) they need to do next — without calling.

- Outcome: a claims-status panel on the portal's "My claims" page.
- Success metric (leading): share of portal sessions with an open claim that view the panel (target ≥ 60% in first 30 days).
- Success metric (lagging): status-related call minutes fall by 40% within 90 days of launch, with no rise in complaints about status accuracy.

## Affected users and systems

| Users / system | How affected | Owning team |
|---|---|---|
| Policyholders with an open claim | New read-only view in portal | Digital (portal) |
| Contact-center agents | Fewer status calls; may point callers to the panel | Contact-center ops |
| Customer portal (`portal/`) | New UI panel on "My claims" | Digital (portal) |
| Claims API (`claims-api/`) | New read-only status route | Claims platform |
| claims-core (system of record) | Read load increases; no writes | Claims platform |

## Constraints

- **No new PII in the portal session.** The panel may show only what the portal already displays (claim number, loss date, status). Source: Privacy standard PS-4, owner Privacy Office.
- **Existing authentication only.** Use the portal's current sign-in and session; no new login flow, no new identity provider. Source: Security architecture, owner AppSec.
- **claims-core is rate-limited.** Downstream reads must respect its published limit (see spec for the figure); a portal-driven traffic spike must not degrade adjuster tools.
- Status wording must match the language adjusters already use in letters, so customers do not see two different descriptions of the same state.

## Out of scope

- Uploading documents or changing claim details from the portal.
- Notifications (email/SMS) on status change — candidate for a follow-up intent.
- Commercial-lines claims.

## Open questions

- [ ] Do third-party loss adjusters (external firms working a claim) need to see this panel, or only the policyholder? — *who can answer:* Claims operations director
- [ ] Should closed claims remain visible, and for how long? — *who can answer:* Records management

## Revision log

| Date | Author | Change |
|---|---|---|
| 2026-09-08 | Dana Okafor | Initial draft written with Claude from call-reason data |
| 2026-09-10 | Priya Raman | Added success-metric targets; accepted (merged) |
