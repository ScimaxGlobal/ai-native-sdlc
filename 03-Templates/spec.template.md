---
# ---------------------------------------------------------------------------
# spec.md — Stage 2 (Design) artifact: requirements + design in one document
# Copy to: work/<ID>-<slug>/spec.md
# Owner: product owner. Consulted: tech lead (higher-risk changes), named
# policy owners for every flagged concern. Approval = merge.
# ---------------------------------------------------------------------------
id: SPEC-YYYY-NNN
title: "<Same title as the intent>"
author: "<Product owner name>"
created: YYYY-MM-DD
status: draft               # draft | in-review | accepted | superseded
intent: INT-YYYY-NNN        # the accepted intent this spec implements
legacy_record: ""           # same record ID the intent carries (or a child record)
source_of_truth: repo       # repo | legacy
skills_applied:             # record every policy skill + version used while writing
  - name: secure-api-review
    version: "<git SHA or tag of the skill>"
policy_owners_consulted: [] # e.g. ["Privacy: J. Rivera", "Security: A. Chen"]
links:
  intent: work/<ID>-<slug>/intent.md
  plan: ""                  # filled in at Stage 3
---

# <Title> — Specification

<!--
HOW TO USE THIS TEMPLATE
- Generate with the /write-spec command (commands/write-spec.md) or the
  spec-writer skill, with the org policy skills loaded. Policy is applied
  while writing, not discovered in later review.
- The spec must be implementable by someone who never saw the intent
  conversation. If a reader has to guess, the spec is not done.
- Every "must" should be testable. Acceptance criteria become tests in Stage 3.
-->

## 1. Summary

<!-- Two or three sentences: what is being built and why (link the intent). -->

## 2. Requirements

### 2.1 Functional

<!-- Numbered so plan.md and tests can reference them: FR-1, FR-2 ... -->

| ID | Requirement | Acceptance criterion |
|---|---|---|
| FR-1 |  |  |

### 2.2 Non-functional

<!-- Performance, availability, accessibility, observability. Give numbers. -->

| ID | Requirement | Target | Source |
|---|---|---|---|
| NFR-1 |  |  |  |

## 3. Design

### 3.1 User experience

<!-- Screens/states, copy, accessibility. Link the mock. List every state (loading, empty, error). -->

### 3.2 Interfaces and data

<!-- API contracts (method, path, request, response), data read/written, schema changes. -->

### 3.3 Security, privacy and compliance

<!--
Output of applying the org policy skills. For each policy: what applies, how
the design satisfies it. Anything that does NOT clearly comply goes in §5.
-->

| Policy (skill) | Applies because | How satisfied |
|---|---|---|
|  |  |  |

## 4. Resolved open questions

<!-- Carry every open question from intent.md here with its answer and who answered. -->

| Question (from intent) | Answer | Decided by | Date |
|---|---|---|---|
|  |  |  |  |

## 5. Flagged concerns

<!--
Claude is asked to flag anything that conflicts with policy or is ambiguous.
Each concern routes to a NAMED owner. Spec cannot be accepted with an
"open" concern unless the owner explicitly defers it.
-->

| # | Concern | Policy owner | Status (open/resolved/deferred) | Resolution |
|---|---|---|---|---|
| 1 |  |  | open |  |

## 6. Out of scope

-

## 7. Decision

<!-- Product owner's go/no-go. For higher-risk changes, record tech-lead consultation. -->

- Decision: proceed | revise | stop
- Decided by:  — Date:
- Tech lead consulted (if higher risk):
