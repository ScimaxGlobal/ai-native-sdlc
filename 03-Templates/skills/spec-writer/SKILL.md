---
name: spec-writer
description: Produces a combined requirements-and-design spec.md from an accepted intent.md, applying the organization's policy skills while writing and flagging concerns for named policy owners. Use when an intent has been accepted, when asked to write, draft, or update a spec, specification, requirements, or design for a feature.
---

<!--
Owner: Product operations + Architecture (<names>). Template: spec.template.md.
Pairs with the /write-spec command (commands/write-spec.md) for manual runs,
and with a non-interactive CI job that runs the same pass when an intent PR merges.
-->

# Spec writer

## Inputs

- An accepted `work/<...>/intent.md` (status `accepted`). If the intent is not accepted, stop and say so.
- The organization policy skills available in this session (for example `secure-api-review`, brand, accessibility, privacy). Apply each one that is relevant.

## Procedure

1. Read the intent in full. List its constraints and open questions.
2. Read any code, API contracts, or docs the intent names so the design reflects reality. Do not invent system behavior; mark unknowns.
3. Write `work/<ID>-<slug>/spec.md` following the organization spec template: frontmatter (`id`, `intent`, `legacy_record`, `skills_applied` with each skill's version, `policy_owners_consulted`), then Summary, Requirements (numbered FR-/NFR- with acceptance criteria), Design (UX, interfaces and data, security/privacy/compliance table), Resolved open questions, Flagged concerns, Out of scope, Decision.
4. **Apply policy while writing.** For each relevant policy skill, add a row to the security/privacy/compliance table saying how the design satisfies it.
5. **Flag, don't bury.** Anything ambiguous, conflicting with policy, or dependent on an unanswered question goes into "Flagged concerns" with the named policy owner. Never silently resolve a policy conflict.
6. Carry every intent open question into "Resolved open questions"; if you cannot resolve one, leave the answer blank and add a flagged concern.
7. Record skill versions in `skills_applied` (use the git SHA or tag if you can find it; otherwise write `unknown` and flag it).

## Quality bar

- Every requirement has a testable acceptance criterion.
- Every non-functional requirement has a number and a source.
- An engineer can start plan mode from this file without asking the product owner anything.
- Leave `Decision` for the product owner to fill.
