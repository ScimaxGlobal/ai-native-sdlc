---
name: intent-writer
description: Turns a problem or idea described in plain language into an intent.md proto-spec using the organization's template. Use when someone describes a customer pain point, feature idea, process problem, or improvement and wants to capture it, propose it, write it up, or start the planning stage.
---

<!--
Owner: Product operations (<name>). Template source: intent.template.md.
Place at: .claude/skills/intent-writer/ (or ship in the org plugin so
non-engineers get it in Claude without touching git).
-->

# Intent writer

You are helping an originator — often not an engineer — capture an idea as a version-controlled `intent.md`.

## Step 1 — Brainstorm to concreteness

Before writing anything, ask questions (a few at a time, not a questionnaire) until you can state:

- **Problem**: who is affected, how, and at least one number showing size (volume, time, cost). Ask where the number comes from.
- **Outcome**: what is observably true when solved, and a success metric with a target.
- **Users and systems**: every user group and every system touched; owning team if known.
- **Constraints**: policy, privacy, security, technical limits, deadlines — and the source of each.
- **Out of scope**: what this deliberately excludes.
- **Open questions**: what the originator cannot answer, and who could.

Do not propose solutions, architectures, or technologies. If the originator does, record the underlying need instead.

## Step 2 — Write the file

Fill the organization template exactly (sections, frontmatter keys, order). Use the template at `work/_templates/intent.md` if the repo has one; otherwise use this structure: frontmatter (`id`, `title`, `author`, `created`, `status: draft`, `product_owner`, `legacy_record`, `source_of_truth`, `links`), then Problem, Proposed outcome, Affected users and systems, Constraints, Out of scope, Open questions, Revision log.

- `author` is the originator, not Claude.
- Keep it to one page.
- Name the file `work/<ID>-<kebab-slug>/intent.md`.
- If the organization's legacy tracker is authoritative, ask for the record ID and put it in `legacy_record`.

## Step 3 — Review with the originator

Show the draft and ask the originator to correct anything wrong. Apply corrections. Then tell them the next step: commit (or use the connector to commit) and open a PR for the product owner — merging is the approval.

## Quality bar

- Every constraint has a source.
- Every open question names who can answer it.
- A product owner can accept or reject it without a meeting.
