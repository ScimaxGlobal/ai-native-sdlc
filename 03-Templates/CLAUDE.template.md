<!--
CLAUDE.md template — place at the repository root as CLAUDE.md.
Owner: code owners of the repo (changes go through CODEOWNERS review).
How to create: run /init in Claude Code, then TRIM the result to what a new
team member needs on day one. Keep it under one page — Claude reads it every
session, so every line is a recurring cost.
Maintenance rule: when Claude makes the same mistake twice, add one line here
that prevents it. When a line stops earning its place, delete it.
Changes to this file trigger the agent-evals CI workflow (ci/agent-evals.yml).
Delete these comments after filling in.
-->

# <Service name>

<One sentence: what this service does and who calls it.>

## Commands

<!-- Exact commands, and what healthy output looks like. Claude uses these to verify its own work. -->

| Task | Command | Healthy output |
|---|---|---|
| Build | `make build` | ends with `Build succeeded` |
| Test | `make test` | `0 failed` |
| Lint | `make lint` | `0 warnings` |
| Run locally | `make run` | `Listening on :8080` |

## Architecture

<!-- 3–6 bullets. Directory layout and the one rule per directory that people get wrong. -->

- `src/api/` — 
- `src/core/` — 
- `src/adapters/` — 

## Conventions

<!-- Only conventions a linter/formatter does NOT already enforce. -->

- 

## Do not

<!-- Hard "never" rules. If a rule MUST hold, also back it with a hook — CLAUDE.md is advisory. -->

- Do not 

## Verification (required before saying "done")

- Build must print `Build succeeded`.
- All tests green. Never skip, disable, or delete a failing test.
- Lint reports zero warnings.
- Run all three before reporting a task complete and paste the output.
- If a test fails, fix the code, not the test. If you believe the test is wrong, stop and say so.

## Common mistakes

<!-- Added under the "twice" rule. Date each line so stale ones can be pruned. -->

- (YYYY-MM-DD) 

## Workflow artifacts

- Intent, spec and plan for each change live in `work/<ID>-<slug>/` — read them before changing behavior.
- Non-trivial work starts in plan mode and produces `work/<ID>-<slug>/plan.md`.
