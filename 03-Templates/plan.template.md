---
# ---------------------------------------------------------------------------
# plan.md — Stage 3 (Build) artifact, produced in Claude Code plan mode
# Copy to: work/<ID>-<slug>/plan.md
# Owner: implementing engineer. Accepted by: the engineer (and tech lead for
# higher-risk changes) BEFORE any code is written.
# Rule: if implementation departs from the plan, update this file in the
# same commit as the code that departs.
# ---------------------------------------------------------------------------
id: PLAN-YYYY-NNN
title: "<Same title>"
author: "<Engineer name>"
created: YYYY-MM-DD
status: draft               # draft | accepted | implemented | superseded
intent: INT-YYYY-NNN
intent_date: YYYY-MM-DD     # the date of the accepted intent this traces to
spec: SPEC-YYYY-NNN
legacy_record: ""           # same record ID as intent/spec
accepted_by: ""             # who accepted the plan (attribution is the governance record)
accepted_on: ""
links:
  intent: work/<ID>-<slug>/intent.md
  spec: work/<ID>-<slug>/spec.md
  pr: ""                    # filled when the PR opens
---

# Plan: <Title>

<!--
HOW TO USE THIS TEMPLATE
1. Start Claude Code in plan mode (Shift+Tab to cycle modes, or
   `claude --permission-mode plan`). Plan mode cannot edit files, so design
   review happens before any code exists.
2. Give it the spec and the intent: "Read work/<x>/spec.md and
   work/<x>/intent.md. Propose a plan: files that change, order of work, tests."
3. Interrogate: "What are the risks? What alternatives did you reject and why?
   What would a reviewer object to?" Iterate until someone who was not in the
   session could implement from this file alone.
4. Commit this file, then accept the plan and let Claude implement.
-->

## Traceability

- Intent: <INT id> (accepted <intent_date>)
- Spec: <SPEC id> — requirements covered: FR-1, FR-2, NFR-1 ...

## Files that change

<!-- Every file created, modified or deleted, with a one-line reason. -->

| File | Change | Why (requirement) |
|---|---|---|
|  | new / modify / delete |  |

## Order of work

<!-- Numbered steps. Each step should leave the build green. Tests first where practical. -->

1.

## Risks and mitigations

<!-- Technical risks, dependency limits, migration hazards, rollback approach. -->

| Risk | Likelihood / impact | Mitigation |
|---|---|---|
|  |  |  |

## Alternatives considered

| Option | Rejected because |
|---|---|
|  |  |

## Proof (definition of done)

<!--
How we will know it works — commands and expected output, not intentions.
These become the verification the agent must run before saying "done".
-->

- [ ] `make test` — all green, including new tests: ...
- [ ] `make lint` — zero warnings
- [ ] Visual check: screenshot matches mock at <link>
- [ ] Verifier subagent report attached to PR

## Deviations during implementation

<!-- Fill in the same commit as any code that departs from the plan above. -->

| Date | Deviation | Reason |
|---|---|---|
