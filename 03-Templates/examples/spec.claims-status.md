---
id: SPEC-2026-014
title: "Claims status self-service in the customer portal"
author: "Priya Raman"
created: 2026-09-11
status: accepted
intent: INT-2026-014
legacy_record: "JIRA CLM-1427"
source_of_truth: repo
skills_applied:
  - name: secure-api-review
    version: "v1.4.0"
  - name: brand-voice
    version: "v2.1.0"
  - name: accessibility-wcag
    version: "v1.0.3"
policy_owners_consulted: ["Privacy Office: J. Rivera", "AppSec: A. Chen", "Claims platform: M. Silva"]
links:
  intent: work/CLM-1427-claims-status-self-service/intent.md
  plan: work/CLM-1427-claims-status-self-service/plan.md
---

# Claims status self-service — Specification

## 1. Summary

Add a read-only claims-status panel to the portal's "My claims" page, backed by
a new read-only route in `claims-api` that reads from claims-core through a
cache. Motivation and metrics: INT-2026-014 (about one third of contact-center
call time is status calls).

## 2. Requirements

### 2.1 Functional

| ID | Requirement | Acceptance criterion |
|---|---|---|
| FR-1 | A signed-in policyholder sees one status card per open claim on their policy. | Given a user with 2 open claims, the panel shows exactly 2 cards with claim number and loss date. |
| FR-2 | Each card shows one of four states with plain-language meaning and next step. | Each of `RECEIVED`, `UNDER_REVIEW`, `AWAITING_INFORMATION`, `DECIDED` renders its approved copy (§3.1). |
| FR-3 | `AWAITING_INFORMATION` tells the user what is needed and how to provide it. | Card shows the outstanding-item label from claims-core and a link to the existing "Contact us" page. |
| FR-4 | A user can only see claims on policies they hold. | Request for another policy's claim returns 404 (not 403, to avoid confirming existence). |
| FR-5 | If status cannot be retrieved, the panel degrades gracefully. | Panel shows "Status temporarily unavailable — try again later"; rest of page works. |

### 2.2 Non-functional

| ID | Requirement | Target | Source |
|---|---|---|---|
| NFR-1 | Respect claims-core rate limit | Portal-originated reads ≤ 50 requests/second to claims-core at peak | claims-core API contract (Claims platform) |
| NFR-2 | Freshness | Status no more than 5 minutes stale | Claims ops agreement |
| NFR-3 | Latency | Panel status request p95 < 400 ms with warm cache | Portal performance budget |
| NFR-4 | Accessibility | WCAG 2.2 AA; state conveyed by text, not color alone | accessibility-wcag skill |
| NFR-5 | Observability | Cache hit ratio, claims-core call rate, and 5xx rate emitted as metrics | Platform standard |

## 3. Design

### 3.1 User experience

Panel placed above the existing claims list. Four states (copy approved by brand-voice owner):

| State | Label | Meaning shown to user | Next step |
|---|---|---|---|
| `RECEIVED` | Received | We have your claim and will assign it shortly. | Nothing needed yet. |
| `UNDER_REVIEW` | Being reviewed | An adjuster is assessing your claim. | Nothing needed; we will contact you. |
| `AWAITING_INFORMATION` | We need something from you | We are waiting on: *{item}*. | Send it via Contact us. |
| `DECIDED` | Decision made | A decision has been sent to you by letter/email. | Read the decision letter. |

Loading skeleton, empty state ("You have no open claims"), and error state (FR-5) are required.

### 3.2 Interfaces and data

`GET /v1/claims/{claim_id}/status` (claims-api, new, read-only)

- Auth: existing portal session → gateway JWT (unchanged).
- Response `200`: `{ "claim_id": "C-123", "state": "UNDER_REVIEW", "outstanding_item": null, "updated_at": "2026-09-10T14:03:00Z" }`
- `404` if the claim is not on a policy held by the caller.
- Unknown query parameters/fields rejected with `400`.
- Data read from claims-core: state, outstanding-item label, updated timestamp. **No names, addresses, or payment details are read or returned.**
- Caching: per-claim entry, TTL 5 minutes (NFR-2), shared across portal instances, so steady-state claims-core calls stay well under 50 rps (NFR-1).

### 3.3 Security, privacy and compliance

| Policy (skill) | Applies because | How satisfied |
|---|---|---|
| Gateway JWT on every endpoint (secure-api-review) | New endpoint | Route sits behind the existing gateway auth; no anonymous access. |
| Validate against OpenAPI, reject unknown fields (secure-api-review) | New request surface | OpenAPI spec added; validator middleware enabled for the route. |
| Audit event on state change (secure-api-review) | Route is read-only | Not applicable — no state change. Read access logged at gateway as today. |
| PII never in logs/errors (secure-api-review, PS-4) | Claim IDs are linked to people | Log claim_id hash only; error bodies carry no claim data. |
| No new PII in portal session (PS-4) | Portal session scope | Response contains no fields beyond what the portal already shows. |
| WCAG 2.2 AA (accessibility-wcag) | New UI | Text labels for each state; keyboard reachable; contrast checked. |

## 4. Resolved open questions

| Question (from intent) | Answer | Decided by | Date |
|---|---|---|---|
| Should closed claims remain visible? | Show `DECIDED` claims for 90 days after decision, then hide. | Records management (L. Novak) | 2026-09-12 |
| Do third-party loss adjusters need access? | **Deferred.** Out of scope for v1; adjusters keep current tools. Revisit as a separate intent. | Claims ops director (R. Haddad) | 2026-09-12 |

## 5. Flagged concerns

| # | Concern | Policy owner | Status | Resolution |
|---|---|---|---|---|
| 1 | Portal traffic could exceed claims-core's 50 rps limit on storm days. | Claims platform (M. Silva) | resolved | Mandatory cache (TTL 5 min) + circuit breaker; load test in plan. |
| 2 | Showing `outstanding_item` text could leak adjuster notes if free text. | Privacy Office (J. Rivera) | resolved | Only the controlled-vocabulary label is returned, never free text. |
| 3 | Third-party adjuster access undecided. | Claims ops (R. Haddad) | deferred | Tracked as follow-up intent. |

## 6. Out of scope

Document upload, notifications, commercial lines, third-party adjuster view.

## 7. Decision

- Decision: proceed
- Decided by: Priya Raman — Date: 2026-09-12
- Tech lead consulted (if higher risk): K. Ito (claims-api) — agreed with caching approach
