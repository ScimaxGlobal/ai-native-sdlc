<!--
REVIEW.md — instructions for the automated reviewer (managed Code Review or
anthropics/claude-code-action; see ci/claude-pr-review.yml).
Place at repository root. Owner: tech lead. Tuned monthly: the tech lead rates
a sample of findings (useful / noise), then tightens this file.
Claude's review NEVER approves or blocks on its own — code-owner approval via
branch protection is still required.
-->

# Review instructions

Read the PR diff together with the linked `work/<ID>-<slug>/` intent, spec and plan
files, `CLAUDE.md`, and the org policy skills. Run three passes and tag each
finding with its pass.

## Pass 1 — [bugs] Correctness and logic

- Does the code do what `work/<ID>-<slug>/plan.md` says, and does it satisfy the acceptance criteria in the spec?
- Edge cases: empty inputs, nulls, concurrency, retries, time zones, pagination limits.
- Error handling: are failures surfaced, not swallowed?
- Tests: do new tests actually assert the behavior, or only that code runs?

## Pass 2 — [security] Security

- Apply the `secure-api-review` skill to every changed endpoint.
- Authn/authz on every new path; object-level ownership checks.
- Input validation; injection (SQL, command, template, path traversal).
- Secrets, tokens, PII in code, logs, error messages or test fixtures.

## Pass 3 — [compliance] Compliance with spec, plan and principles

- Any diff that is not in the plan's "Files that change" table must be explained in the plan's "Deviations" section.
- Constraints from the intent/spec (e.g. "no new PII in session") are visibly honored.
- Rules in `CLAUDE.md` "Do not" are followed.

## Severity

- **Important** — would break behavior, leak data, or breach a written policy. Must be addressed or explicitly waived by a code owner.
- **Nit** — style, naming, minor readability. Never block on a nit.

Report at most **5 nits**. If there are more, summarize the rest as a count ("+7 more nits of the same kind").

## Do not report

- Anything under `src/gen/`, `build/generated/`, lockfiles, or vendored code.
- Anything CI already enforces (formatting, lint rules, type errors, license headers).
- Pure preference with no stated principle behind it.

## When a finding repeats

If the same finding appears on two separate PRs, propose a one-line addition to `CLAUDE.md` in your review summary.
