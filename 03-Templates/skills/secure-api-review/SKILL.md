---
name: secure-api-review
description: Applies the organization's API security policy (gateway JWT, OpenAPI validation, audit events, PII handling). Use when designing, writing, changing, or reviewing any HTTP endpoint, route, controller, API handler, or OpenAPI contract, or when asked whether an API is secure or compliant.
allowed-tools: Bash(bash ${CLAUDE_SKILL_DIR}/scripts/check-endpoints.sh *) Read Grep Glob
---

<!--
Policy owner: Application Security (AppSec lead: <name>)
Source of truth: <link to API security standard, e.g. SEC-API-001 v3>
Place at: .claude/skills/secure-api-review/ in each repo, or ship via the
org plugin marketplace so every repo gets updates automatically.
Change process: policy change -> owner sign-off -> PR to this file -> version tag.
This skill is ADVISORY. The must-hold parts are also enforced by hooks and CI.
-->

# Secure API review

Apply every rule below to each endpoint you create, change, or review.

## Rules

1. **Authentication.** Every endpoint requires a gateway-issued JWT. The only exception is `GET /health`. Do not add other unauthenticated routes; if one seems necessary, stop and flag it for AppSec.
2. **Authorization.** Check that the caller owns the object requested (object-level check), using identity from the token, never from request parameters. Return `404` for objects the caller may not see.
3. **Input validation.** Validate request bodies and query parameters against the OpenAPI contract. Reject unknown fields with `400`. Add or update the OpenAPI file in the same change.
4. **Audit.** Every state-changing operation (POST, PUT, PATCH, DELETE) emits an audit event with `actor`, `action`, `entity`, `timestamp`. Read-only endpoints do not need one.
5. **PII.** Fields tagged PII in the data catalog never appear in logs, metrics labels, error messages, or exception text. Log opaque IDs or hashes instead.

## Procedure

1. Identify every endpoint in scope (new, changed, or under review).
2. Run the endpoint checker and include its full output in your response or PR description:
   ```bash
   bash ${CLAUDE_SKILL_DIR}/scripts/check-endpoints.sh <source-dir>
   ```
   It lists endpoints and flags those with no recognizable auth marker. It is a heuristic: treat `MISSING-AUTH?` as "verify by reading", not as proof.
3. For each endpoint, report a line per rule: `PASS`, `FAIL` (with file:line and the fix), or `N/A` (with reason).
4. Any `FAIL` on rules 1, 2 or 5 is **Important**. Do not describe the change as complete while one is open.

## Output format

```
Endpoint: GET /v1/claims/{id}/status  (claims-api/routes/status.py:14)
  1 auth ........ PASS  gateway JWT dependency present
  2 authz ....... PASS  ownership from token policy list
  3 validation .. FAIL  no OpenAPI schema; add openapi/status.yaml
  4 audit ....... N/A   read-only
  5 PII ......... PASS  logs claim_id hash only
```
