# Stage-Gate Checklists

Each stage of the AI-native SDLC has a **Definition of Ready** (what must be true before the stage starts) and a **Definition of Done** (what must be true before the next stage can read its output). Copy the relevant section into the PR that carries the stage's artifact.

![](../05-Diagrams/03-artifact-chain.svg)

---

## Stage 1 - Plan (`intent.md`)

Guide: [01-Plan-Intent.md](../01-Stages/01-Plan-Intent.md) | Template: [../03-Templates/](../03-Templates/)

### Definition of Ready
- [ ] The originator can describe the problem in plain language.
- [ ] The originator has Claude access and knows where the `work/` folder is (or has a connector to commit without git).
- [ ] The organization's `intent.md` template is available (ideally as a skill).

### Definition of Done
- [ ] `intent.md` uses the org template: Title, Author, Status, Problem, Proposed outcome, Affected users/systems, Constraints, Open questions.
- [ ] Problem is backed by evidence (data, customer quotes, volumes).
- [ ] Proposed outcome includes a measurable success metric.
- [ ] Constraints include data and privacy boundaries.
- [ ] Open questions are listed, not hidden.
- [ ] The originator has read and corrected Claude's draft.
- [ ] Committed to `work/<slug>/intent.md` with author and timestamp.
- [ ] If a legacy tool is the source of truth, the record ID is in the artifact and the commit SHA is in the record.
- [ ] Product owner has merged (approved) or closed with a reason (rejected).

---

## Stage 2 - Design (`spec.md`)

Guide: [02-Design-Spec.md](../01-Stages/02-Design-Spec.md)

### Definition of Ready
- [ ] `intent.md` is merged.
- [ ] Org skills for brand, security, compliance, and UX are installed and current.
- [ ] The PO has Claude access.
- [ ] Named policy owners are known for each relevant policy.

### Definition of Done
- [ ] `spec.md` combines requirements and design in one document.
- [ ] Claude was asked to flag policy concerns; all flags are listed.
- [ ] Each flag is resolved by the named policy owner, with the decision in the PR thread.
- [ ] Spec traces back to every item in the intent's proposed outcome.
- [ ] Open questions from the intent are answered or explicitly deferred.
- [ ] Skill versions used in the design pass are recorded.
- [ ] Tech lead consulted for higher-risk changes (record in PR).
- [ ] PO decided to proceed; `spec.md` committed next to `intent.md`.

---

## Stage 3 - Build (`plan.md`, code)

Guide: [03-Build-Plan-Mode.md](../01-Stages/03-Build-Plan-Mode.md)

### Definition of Ready
- [ ] `spec.md` is merged.
- [ ] Repo has a current `CLAUDE.md` (under one page, code-owner approved).
- [ ] Build-time hooks are active (protected paths, lint/format, secret checks).
- [ ] Engineer starts Claude Code in plan mode.

### Definition of Done - plan
- [ ] `plan.md` header links to the intent and spec.
- [ ] Lists files that change, order of work, risks, and proof (tests, screenshots).
- [ ] Risks include external limits (rate limits, quotas, frozen APIs) and mitigations.
- [ ] Alternatives were considered and the choice explained.
- [ ] A non-author could implement from the plan alone.
- [ ] `plan.md` committed before implementation starts.

### Definition of Done - implementation
- [ ] Implementation follows the plan; any departure is reflected in `plan.md` in the same commit.
- [ ] Every file in the diff is either in the plan or explained.
- [ ] No edits to protected paths without approval.
- [ ] Parallel sessions (if used) each have their own worktree and are attributed to the steering engineer.
- [ ] Any mistake seen twice has been added to `CLAUDE.md`.

---

## Stage 4 - Test (feedback loops and evals)

Guide: [04-Test-Feedback-Loops-and-Evals.md](../01-Stages/04-Test-Feedback-Loops-and-Evals.md)

### Definition of Ready
- [ ] Build, test, and lint run with one command each (or one combined target).
- [ ] `CLAUDE.md` lists the commands and what healthy output looks like.
- [ ] For bug fixes: a failing test exists that reproduces the bug.

### Definition of Done
- [ ] Build reports success.
- [ ] All tests pass; none skipped or deleted to get there.
- [ ] Lint reports zero warnings.
- [ ] Output of all three pasted into the PR or session summary.
- [ ] For bug fixes: failing test committed first, then the fix; no test edits during the fix.
- [ ] For UI changes: screenshot compared against the mock.
- [ ] If the change touches `CLAUDE.md`, `.claude/**`, prompts, or model choice: eval suite ran and pass rate meets threshold.

---

## Stage 5 - Deploy (review and release)

Guide: [05-Deploy-Review-and-Gates.md](../01-Stages/05-Deploy-Review-and-Gates.md) | [PR-Review-Guide.md](../02-Guides/PR-Review-Guide.md)

![](../05-Diagrams/08-pr-review-flow.svg)

### Definition of Ready (PR)
- [ ] Stage 4 done.
- [ ] PR description links to intent, spec, and plan.
- [ ] Claude review is enabled for the repo and `REVIEW.md` is current.

### Definition of Done (merge)
- [ ] Claude review completed; all Important findings addressed or explicitly accepted with a reason.
- [ ] Fixes requested via `@claude` are recorded in the thread.
- [ ] Required checks green.
- [ ] Code-owner approval by someone other than the author; no approval by an agent identity.
- [ ] Reviewer considered intent and risk, not only the diff.
- [ ] Repeat findings added to `CLAUDE.md`.

### Definition of Done (release)
- [ ] Deployed and verified in dev and staging.
- [ ] Rollback path is one command and was exercised in staging.
- [ ] Release manager authorized the production step (environment approval or gate signal).
- [ ] Agent identity prepared the release but did not hold production credentials.
- [ ] Post-deploy monitoring window defined.

---

## Stage 6 - Maintain (close the loop)

Guide: [06-Maintain-Close-the-Loop.md](../01-Stages/06-Maintain-Close-the-Loop.md) | [Control-Bands-and-Anomaly-Detection.md](../02-Guides/Control-Bands-and-Anomaly-Detection.md)

### Definition of Ready
- [ ] Service owner has chosen stable metrics.
- [ ] Deterministic detection script exists, is versioned, and is unit-tested.
- [ ] Response tiers are in versioned config (1 sigma log, 2 sigma read-only diagnose, 3 sigma propose).
- [ ] Trigger is wired (scheduled workflow, webhook, or cron).
- [ ] Rollback pipeline is rehearsed.

### Definition of Done (per anomaly)
- [ ] Diagnosis written as `intent.md` with anomaly, evidence, proposed outcome, affected systems, open questions.
- [ ] Service owner or on-call triaged: fix now, schedule, or dismiss, with reason recorded.
- [ ] Dismissals feed band tuning.
- [ ] Fix (if any) went through the normal PR gate.
- [ ] Eval added for the incident class once the fix ships (see [Incident-to-Eval-Checklist.md](Incident-to-Eval-Checklist.md)).
- [ ] Post-mortem stored in the versioned lessons folder.

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
