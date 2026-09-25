# Incident-to-Eval Checklist

Every production incident and every validated security finding should leave behind a permanent regression eval, so the same class of failure is caught in CI the next time agent configuration changes. This checklist walks the owning team from resolved incident to merged eval.

Related: [Evals-Guide.md](../02-Guides/Evals-Guide.md), [06-Maintain-Close-the-Loop.md](../01-Stages/06-Maintain-Close-the-Loop.md), [Claude-On-Call-Guide.md](../02-Guides/Claude-On-Call-Guide.md)

Owner: service owner (accountable); owning team (responsible).

---

## 1. Capture

- [ ] Incident or finding ID recorded.
- [ ] Post-mortem written to the versioned lessons folder (Claude may draft; a human confirms).
- [ ] Root cause stated as a **class** of failure, not only the specific instance (for example, "unbounded retry against a rate-limited upstream", not "retry bug in claims panel").
- [ ] Was an agent involved in introducing, detecting, or fixing it? Note which configuration was in force (commit SHA of `CLAUDE.md`, `.claude/`).

## 2. Decide what to change

- [ ] Could `CLAUDE.md` have prevented it? If so, add a correction (keep under one page).
- [ ] Could a skill have prevented it? If so, propose a change to the skill owner.
- [ ] Is the rule must-hold? If so, add or extend a hook or CI check.
- [ ] Does the control band or response tier need tuning?

## 3. Write the eval

- [ ] Eval prompt reproduces the task that led to the failure, using realistic context.
- [ ] Checks are objective: tests pass, lint clean, behavior unchanged, policy followed.
- [ ] The eval **fails** against the configuration in force at the time of the incident (proves it discriminates).
- [ ] The eval **passes** with the fix or the configuration change.
- [ ] Eval file named and tagged with incident ID and failure class.
- [ ] `--allowedTools` in the eval run is no broader than needed.

## 4. Merge

- [ ] Eval PR reviewed by the config-owning team.
- [ ] Eval runs in the nightly suite and on configuration changes.
- [ ] Pass-rate threshold still met by the current configuration.
- [ ] Incident record updated with the eval file path and commit SHA.

## 5. Follow-through

- [ ] Incident-to-eval time recorded (resolution to eval merge).
- [ ] If the incident came from a scan finding, a vulnerability-class eval is included.
- [ ] Similar services checked for the same failure class; findings raised as `intent.md` where needed.
- [ ] After the eval has passed consistently for a long period, consider moving it to the baseline set (keep it; do not delete).

## Record

| Field | Value |
|---|---|
| Incident / finding ID | |
| Failure class | |
| Eval file | |
| Eval PR | |
| Config changes (CLAUDE.md, skill, hook) | |
| Incident resolved at | |
| Eval merged at | |
| Owner | |

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
