---
# ---------------------------------------------------------------------------
# intent.md — Stage 1 (Plan) artifact
# Copy to: work/<ID>-<slug>/intent.md in the product repo.
# Owner: the originator (anyone — engineer or not). Approver: product owner.
# Approval = merge of the PR that adds this file. Rejection = closed PR.
# ---------------------------------------------------------------------------
id: INT-YYYY-NNN            # repo-local ID, stable for the life of the idea
title: "<Short outcome-oriented title>"
author: "<Name <email>>"    # the person who owns the idea, not the tool that wrote it
created: YYYY-MM-DD
status: draft               # draft | proposed | accepted | rejected | superseded
product_owner: "<Name>"     # who merges (approves) this intent
legacy_record: ""           # e.g. JIRA-1234 / ServiceNow RITM0012345 — REQUIRED if the legacy tool is authoritative
source_of_truth: repo       # repo | legacy  (pick ONE authoritative system; see README "Source of truth")
links:
  spec: ""                  # filled in at Stage 2, e.g. work/<ID>-<slug>/spec.md
  plan: ""                  # filled in at Stage 3
  origin: ""                # optional: monitoring alert, incident, customer ticket, scan finding
---

# <Title>

<!--
HOW TO USE THIS TEMPLATE
- Write it in a conversation with Claude: describe the problem in plain language,
  let Claude ask questions until scope, users, constraints and success metrics
  are concrete, then ask it to fill this template. Correct anything it got wrong.
- Keep it to one page. This is a proto-spec, not a design. No solutioning in
  "Problem"; no implementation detail anywhere.
- Every statement should be checkable by the product owner without reading code.
- Delete these comments before opening the PR (or leave them — they render invisibly).
-->

## Problem

<!--
Who is hurting, how, and how do we know? Include at least one number
(volume, time, cost, error rate). Cite where the number came from.
-->

## Proposed outcome

<!--
What is true for users when this is done? Phrase as observable outcomes,
not features. Include the success metric and its target, e.g.
"Status-related call minutes fall by 40% within 90 days of launch."
-->

- Outcome:
- Success metric (leading):
- Success metric (lagging):

## Affected users and systems

<!--
List user groups and every system that will be read or changed.
Name owning teams where known — Stage 2 will route questions to them.
-->

| Users / system | How affected | Owning team |
|---|---|---|
|  |  |  |

## Constraints

<!--
Non-negotiables: policy (privacy, security, regulatory), technical limits
(rate limits, frozen APIs), budget, deadlines. Each constraint should name
its source (policy doc, owner) so the spec can cite it.
-->

-

## Out of scope

<!-- What this intent deliberately does NOT cover. Prevents scope creep in Stage 2. -->

-

## Open questions

<!--
Things the originator cannot answer. Each should name who could answer it.
Stage 2 must resolve or explicitly defer every item here.
-->

- [ ] Question — *who can answer:*

## Revision log

<!-- Git holds the full history; this is a human summary of material changes after acceptance. -->

| Date | Author | Change |
|---|---|---|
| YYYY-MM-DD | | Initial draft |
