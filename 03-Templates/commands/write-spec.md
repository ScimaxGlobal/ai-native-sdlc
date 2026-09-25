---
description: Stage 2 — draft work/<ID>-<slug>/spec.md from an accepted intent file, applying org policy skills and flagging concerns
argument-hint: <path-to-intent.md>
allowed-tools: Read Grep Glob Write Bash(git log *) Bash(git rev-parse *)
---

<!--
Place at: .claude/commands/write-spec.md  -> invoked as /write-spec work/<ID>-<slug>/intent.md
(Custom commands still work; the same content can also live in
.claude/skills/write-spec/SKILL.md, which additionally supports supporting files.)
Owner: product operations. Used by product owners in an interactive session;
the CI version runs the same prompt with `claude -p` when an intent PR merges.
-->

Write the specification for the intent at `$ARGUMENTS`.

1. Read `$ARGUMENTS` in full. If its frontmatter `status` is not `accepted`, stop and tell me.
2. Use the **spec-writer** skill procedure and the organization spec template (`work/_templates/spec.md` if present, otherwise the structure in the skill).
3. Apply every relevant organization policy skill while writing — at minimum `secure-api-review` for any API surface, plus brand, accessibility, and privacy skills if available. Record each skill and its version (from `git log -1 --format=%h -- .claude/skills/<name>`) in `skills_applied`.
4. Honor every constraint in the intent. Where a constraint cannot clearly be met, or policy is ambiguous, add a row to **Flagged concerns** naming the policy owner. Do not resolve policy conflicts yourself.
5. Carry every open question from the intent into **Resolved open questions**; leave the answer blank if unknown.
6. Save to `work/<ID>-<slug>/spec.md`, the same folder as the intent. Set `status: draft`, copy `legacy_record` from the intent, and link both files.
7. Finish with a short list: flagged concerns and who must answer each, and anything you assumed.
