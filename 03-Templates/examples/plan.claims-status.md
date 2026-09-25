---
id: PLAN-2026-014
title: "Claims status self-service in the customer portal"
author: "Kenji Ito"
created: 2026-09-15
status: accepted
intent: INT-2026-014
intent_date: 2026-09-08
spec: SPEC-2026-014
legacy_record: "JIRA CLM-1427"
accepted_by: "Kenji Ito (engineer); reviewed by S. Mensah (tech lead)"
accepted_on: 2026-09-15
links:
  intent: work/CLM-1427-claims-status-self-service/intent.md
  spec: work/CLM-1427-claims-status-self-service/spec.md
  pr: ""
---

# Plan: Claims status self-service

## Traceability

- Intent: INT-2026-014 (accepted 2026-09-10, drafted 2026-09-08)
- Spec: SPEC-2026-014 — covers FR-1…FR-5, NFR-1…NFR-5

## Files that change

| File | Change | Why (requirement) |
|---|---|---|
| `claims-api/routes/status.py` | new | `GET /v1/claims/{claim_id}/status`, ownership check, cache read-through (FR-1, FR-4, NFR-1, NFR-2) |
| `claims-api/tests/test_status.py` | new | Tests for all four claim states, ownership 404, unknown-field 400, cache behavior, degraded path (FR-2..FR-5) |
| `claims-api/openapi/status.yaml` | new | Contract for validator middleware (secure-api-review) |
| `claims-api/app.py` | modify | Register route + validator |
| `portal/src/claims/StatusPanel.tsx` | new | Panel with four state cards, loading/empty/error states (FR-1..FR-3, FR-5, NFR-4) |
| `portal/src/claims/StatusPanel.test.tsx` | new | Render tests per state; axe accessibility check |
| `portal/src/claims/MyClaimsPage.tsx` | modify | Mount panel above claims list |

## Order of work

1. Write `claims-api/tests/test_status.py` covering the four states (`RECEIVED`, `UNDER_REVIEW`, `AWAITING_INFORMATION`, `DECIDED`), 404 ownership, 400 unknown field, and claims-core-down → 503. Confirm they fail.
2. Add OpenAPI contract and route in `claims-api/routes/status.py` with a read-through cache (TTL 300 s) and circuit breaker around the claims-core client. Make step-1 tests pass.
3. Emit metrics: cache hit ratio, claims-core calls/s, 5xx rate (NFR-5).
4. Build `portal/src/claims/StatusPanel.tsx` against the API contract with a mocked client; add render tests for each state and the error/empty states.
5. Mount the panel in `MyClaimsPage.tsx`; run the verifier subagent against the running app.
6. Load test the status route at 3× expected peak; confirm claims-core call rate stays < 50 rps.

## Risks and mitigations

| Risk | Likelihood / impact | Mitigation |
|---|---|---|
| **claims-core API rate limit is 50 rps**; a storm-day surge of portal visits could exceed it and slow adjuster tools. | Medium / High | **The panel must cache.** Server-side per-claim cache (TTL 5 min) shared across instances; circuit breaker returns 503 → panel error state rather than retry-storming claims-core. Load test in step 6. |
| Cache serves stale state after a decision. | Medium / Low | TTL bounded at 5 min per NFR-2; `updated_at` shown on card. |
| Ownership check bypass exposes other customers' claims. | Low / Critical | Ownership resolved from session's policy list server-side, never from request params; explicit test for cross-policy 404. |
| Status copy drifts from letter wording. | Low / Medium | Copy sourced from a single constants file reviewed by brand-voice owner. |

## Alternatives considered

| Option | Rejected because |
|---|---|
| Portal calls claims-core directly | Bypasses cache and rate protection; would need new credentials in the portal tier. |
| Push status via events into a portal read-model | Better long-term, but requires claims-core event changes; out of scope for v1. |

## Proof (definition of done)

- [ ] `make test` in `claims-api/` — all green; `test_status.py` covers all four claim states plus 404/400/503 paths.
- [ ] `npm test` in `portal/` — StatusPanel render tests green, axe reports zero violations.
- [ ] `make lint` — zero warnings in both packages.
- [ ] Screenshot of each of the four state cards matches the approved mock.
- [ ] Load test: claims-core calls stay < 50 rps at 3× peak portal traffic.
- [ ] Verifier subagent report (happy path + two neighboring flows) pasted in PR.

## Deviations during implementation

| Date | Deviation | Reason |
|---|---|---|
