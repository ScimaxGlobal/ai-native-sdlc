# New Repo Onboarding Checklist

Use this checklist to bring an existing or new repository into the AI-native workflow. It assumes the platform baseline in [Platform-Setup-Checklist.md](Platform-Setup-Checklist.md) is already in place. Complete it in a single onboarding PR where possible so the change is reviewable and auditable.

Owner: tech lead, with code owners approving.

---

## 1. Prerequisites

- [ ] Repo has a named tech lead and current `CODEOWNERS`.
- [ ] Branch protection on main requires PRs and code-owner approval; direct pushes disabled.
- [ ] Build and tests run locally with one command.
- [ ] CI runs on every PR.
- [ ] Source of truth decided for work items: repo authoritative, or legacy tool authoritative with markdown as working copies. See [Source-of-Truth-and-Legacy-Systems.md](../02-Guides/Source-of-Truth-and-Legacy-Systems.md).

## 2. Context: `CLAUDE.md`

See [CLAUDE-md-Guide.md](../02-Guides/CLAUDE-md-Guide.md).

- [ ] Generated with `/init` and trimmed to day-one essentials.
- [ ] Under one page.
- [ ] Includes: commands, conventions, architecture layout, common mistakes, frozen areas.
- [ ] Includes a verification block: build success string, all tests green (never skip or delete), zero lint warnings, paste output before reporting done, fix code not tests.
- [ ] Checked in at repo root; `CLAUDE.md` covered by `CODEOWNERS`.

## 3. Verification targets

- [ ] Single target for multi-step checks (for example, `make test`).
- [ ] Healthy output documented in `CLAUDE.md`.
- [ ] UI repos: visual check approach documented (screenshot versus mock).

## 4. Repository configuration (`.claude/`)

- [ ] `.claude/settings.json` committed with team permissions and hooks.
- [ ] Hooks: protected paths, formatter/linter after edit, secret check, test-edit block during bug fixes.
- [ ] Subagents in `.claude/agents/` (for example, a verifier with limited tools) if useful.
- [ ] Repo-specific skills in `.claude/skills/` (only for knowledge not better placed in `CLAUDE.md`).
- [ ] `.claude/**` covered by `CODEOWNERS`.

## 5. Artifacts

- [ ] `work/` folder created (or linkage to legacy tool configured).
- [ ] Templates for `intent.md`, `spec.md`, `plan.md` available (org skill or [../03-Templates/](../03-Templates/)).
- [ ] PR template asks for links to intent, spec, and plan.

## 6. Review

See [PR-Review-Guide.md](../02-Guides/PR-Review-Guide.md).

- [ ] Claude code review enabled for the repo.
- [ ] `REVIEW.md` written: passes (bugs/logic, security, compliance), Important vs Nit, nit cap, exclusions (generated paths, CI-enforced rules).
- [ ] Team knows how to request fixes with `@claude`.
- [ ] Monthly review-tuning slot scheduled.

## 7. Evals and CI

- [ ] Repo tasks contributed to the eval suite, or a repo-level eval set created.
- [ ] Eval workflow triggers on `CLAUDE.md` and `.claude/**` changes.
- [ ] Read-only CI steps (failure triage, summaries) added.

## 8. Operations (for services)

- [ ] Service owner named.
- [ ] Rollback is one command and exercised in staging.
- [ ] Candidate metrics for control bands identified.
- [ ] Repo added to recurring security scan schedule.

## 9. Team readiness

- [ ] Team members completed the Foundations and Engineer training tracks.
- [ ] Champion assigned.
- [ ] First three changes through the full artifact chain planned.

## Onboarding sign-off

| Role | Name | Date |
|---|---|---|
| Tech lead | | |
| Code owner | | |
| Platform engineer | | |

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
