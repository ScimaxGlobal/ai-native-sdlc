# Prompt Library

Ready-to-use prompts for each stage of the AI-native SDLC. Replace anything in `<angle brackets>`. Once a prompt is used often and consistently, promote it to an org skill or slash command so that everyone gets the same version and it can be updated centrally (see [Skills-Guide.md](../02-Guides/Skills-Guide.md)).

**General tips**
- Name the artifact you want and the template to use.
- Name the constraints and ask Claude to *flag* concerns rather than silently resolve them.
- Ask for evidence: commands run, output pasted, files cited.
- For anything that changes code, say how "done" will be verified.

---

## 1. Plan - brainstorming to `intent.md`

### 1a. Open the brainstorm (originator)

```text
I want to explore a problem before anyone designs a solution.

Problem in my words: <describe the problem, who is affected, how often, what it costs>.

Please interview me to make this concrete. Ask one question at a time, covering:
scope (what is in and out), affected users and systems, constraints (data, privacy,
regulatory, technical), how we would measure success, and open questions. Challenge
vague answers. Do not propose a solution yet.
```

### 1b. Write the intent

```text
Using our intent.md template, write intent.md from our conversation.
Sections: Title, Author (<name>), Status (Draft), Problem, Proposed outcome,
Affected users/systems, Constraints, Open questions.
Keep the problem evidence-based and the outcome measurable. Put anything we did not
settle under Open questions rather than guessing. Save it to work/<slug>/intent.md.
```

### 1c. Stress-test the intent (product owner)

```text
Read work/<slug>/intent.md. As a skeptical product owner, list:
1) assumptions not backed by evidence, 2) success metrics that cannot be measured
with data we have, 3) constraints that are missing given the affected systems,
4) the three questions I should ask the originator before approving.
```

## 2. Design - `spec.md` with flags

### 2a. Design pass with policy flags

```text
Read work/<slug>/intent.md. Produce spec.md combining requirements and design,
applying our org skills for security, compliance, brand, and UX.

Constraints to respect: <for example, no new PII in portal session; claims-core API
limit 50 rps; WCAG 2.2 AA>.

Where any part of the design conflicts with, or is ambiguous under, a policy, do not
resolve it silently. Add a "Flags" section listing each concern with: the policy,
the specific risk, the options, and the named policy owner who should decide.
Trace every requirement back to a line in the intent's Proposed outcome.
Save to work/<slug>/spec.md.
```

### 2b. Check spec against intent

```text
Compare work/<slug>/spec.md against work/<slug>/intent.md. List anything in the
spec that is not justified by the intent (scope creep), anything in the intent not
covered by the spec, and any open question the spec answered without evidence.
```

## 3. Build - plan interrogation

### 3a. Ask for the plan (plan mode)

```text
Read work/<slug>/spec.md and intent.md. Propose an implementation plan with:
- Files that change (paths) and why
- Order of work
- Risks, including external limits and frozen areas from CLAUDE.md
- Proof: which tests and checks will show it works
Do not edit anything yet.
```

### 3b. Interrogate the plan

```text
Before I accept this plan:
1. What are the two riskiest steps, and what could go wrong in each?
2. What alternatives did you consider, and why did you reject them?
3. Which assumptions about the existing code have you not verified by reading it?
   Read those files now and update the plan.
4. What would a reviewer who did not write this plan find unclear?
5. Which neighboring flows could this break, and how will the tests catch it?
Revise the plan so a non-author could implement it from the plan alone.
```

### 3c. Commit the plan

```text
Write the accepted plan to work/<slug>/plan.md with a header linking the intent
and spec. Commit it on its own before implementation, with a message that
references <record ID if using a legacy tool>.
```

### 3d. Keep plan and code consistent

```text
You departed from plan.md in <area>. Update plan.md to reflect what you actually
did and why, and include that change in the same commit as the code.
```

## 4. Test - bug fix with a failing test first

```text
Bug: <description, including steps to reproduce and expected vs actual behavior>.

1. Write a test that reproduces this bug. Run it and paste the failing output.
   Commit the failing test on its own.
2. Fix the code so the test passes. Do NOT modify, skip, or delete the test or any
   other test while fixing.
3. Run the full verification from CLAUDE.md (build, all tests, lint) and paste the
   output. If anything fails, fix the code, not the test.
4. Summarize the root cause in two sentences.
```

### UI verification

```text
After implementing, start the app, open <page>, and take a screenshot. Compare it
with <mock path or link> and list every visible difference. Fix differences that
are not intentional, then take a final screenshot.
```

## 5. Deploy - review

### 5a. Self-review before opening a PR

```text
Review your own diff against plan.md and REVIEW.md before I open the PR.
Do three passes: 1) bugs and logic, 2) security, 3) compliance with the spec, the
plan, and our principles. Tag each finding Important or Nit using REVIEW.md
definitions. Fix Important findings; list Nits (max five) for me to decide.
```

### 5b. Human reviewer asking Claude for context

```text
Summarize this PR for a code owner in five bullets: what changed, why (link to
intent), the riskiest part, what the tests prove, and what they do not prove.
Point me to the lines where I should spend my attention.
```

### 5c. Addressing review comments (on the PR)

```text
@claude please address this comment: <paste or reference>. Keep the change minimal,
run the verification from CLAUDE.md, and reply in this thread with what you changed.
```

### 5d. Pipeline failure triage (headless)

```bash
claude -p "Read out/build.log. Decide whether this failure is flaky or real, and
explain why in one line. Then give a three-line summary: failing step, likely cause,
suggested next action." --allowedTools "Read" >> triage.md
```

## 6. Maintain - triage and post-mortem

### 6a. Diagnose a band breach (2-sigma, read-only)

```text
Metric <metric> breached its control band at <time> (<rule triggered>, value
<value>, baseline <mean> +/- <sigma>). Using read-only tools, investigate recent
deploys, CI runs, and code changes in the window. Write work/<anomaly-slug>/intent.md
with: Anomaly, Evidence (with links and command output), Proposed outcome, Affected
systems, Open questions. Do not change code or configuration.
```

### 6b. Triage support (service owner)

```text
Read work/<anomaly-slug>/intent.md. Give me the case for each option: fix now,
schedule, or dismiss. For dismiss, suggest how the band or rule should be tuned so
this does not fire again for the same benign cause.
```

### 6c. Incident channel first response

```text
@Claude we are seeing <symptom> on <service> since <time>. Check the dashboards and
recent deploys, tell us what changed in the window, and propose the smallest safe
action. Do not act until someone in this channel confirms.
```

### 6d. Post-mortem draft

```text
Draft a blameless post-mortem for incident <ID> from this channel's history and the
linked PRs. Sections: Summary, Impact, Timeline (UTC), Root cause as a failure class,
What went well, What did not, Action items (owner, due date), Eval to add.
Save to lessons/<date>-<slug>.md. Mark anything uncertain for human confirmation.
```

### 6e. Convert an incident into an eval

```text
From lessons/<date>-<slug>.md, draft an eval case in evals/<slug>.json: a prompt that
reproduces the task that led to the failure, and objective checks that would have
caught it. Explain how to confirm it fails on configuration <old SHA> and passes now.
```

## 7. Configuration maintenance

### Update `CLAUDE.md` after a repeat mistake

```text
You have now made this mistake twice: <mistake>. Propose the shortest possible
addition to CLAUDE.md that would prevent it, and suggest one existing line we could
remove to keep the file under one page.
```

### Draft a skill from a policy

```text
Here is our policy: <paste or path>. Owner: <name>. Draft a SKILL.md with frontmatter
(name, and a description stating when it should trigger) and a body listing the
concrete checks to perform. List which rules are must-hold and therefore also need a
hook or CI check.
```

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
