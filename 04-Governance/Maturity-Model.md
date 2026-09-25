# Maturity Model

This model describes five levels of AI-native SDLC maturity across nine dimensions. Use it to locate where a team or organization is today, to agree on the next realistic step, and to track progress quarterly. Levels are cumulative: a team at Level 4 in a dimension also meets the Level 3 criteria.

Most organizations will be at different levels in different dimensions. That is expected. The roadmap in [Adoption-Roadmap.md](Adoption-Roadmap.md) is designed to raise the weakest prerequisite dimensions first.

## The five levels

| Level | Name | Summary |
|---|---|---|
| 1 | **Ad hoc assistant use** | Individuals use AI chat or coding assistants informally. No shared context, no artifacts, no controls beyond existing ones. Output quality depends on the individual. |
| 2 | **Assisted** | Claude Code is sanctioned and configured with baseline managed settings. Repos have `CLAUDE.md`. Engineers use plan mode for larger changes and run tests before submitting. |
| 3 | **Artifact-driven** | Every change flows through version-controlled artifacts (`intent.md`, `spec.md`, `plan.md`). Policy is encoded as skills with named owners. Feedback loops are part of "done." |
| 4 | **Governed / automated** | Must-hold policies are enforced by hooks and managed settings. Claude reviews every PR and addresses comments; code owners approve. Evals gate configuration changes. Claude runs in CI up to the production gate. |
| 5 | **Closed-loop** | Production signals breaching control bands automatically produce diagnoses as new `intent.md`. Scheduled scans run with no human in the path. Claude is on call. Incidents become permanent evals. Metrics drive tuning. |

```mermaid
flowchart LR
    L1["L1 Ad hoc<br/>individual use"] --> L2["L2 Assisted<br/>CLAUDE.md, managed baseline"]
    L2 --> L3["L3 Artifact-driven<br/>intent/spec/plan, skills"]
    L3 --> L4["L4 Governed<br/>hooks, PR review, evals, CI"]
    L4 --> L5["L5 Closed-loop<br/>bands, scans, on-call"]
    L5 -.new intent.md.-> L3
```

---

## Dimension matrix

| Dimension | L1 Ad hoc | L2 Assisted | L3 Artifact-driven | L4 Governed / automated | L5 Closed-loop |
|---|---|---|---|---|---|
| **Planning artifacts** | Tickets and chat threads; nothing versioned | Occasional plan-mode plans, not committed | `intent.md` -> `spec.md` -> `plan.md` committed for all non-trivial work; PO approval is merge | Intent merge triggers non-interactive spec pass opened as a PR; single source of truth named per artifact | Agent-generated `intent.md` from production signals and scans enters the same queue |
| **Context / CLAUDE.md** | None | `CLAUDE.md` generated with `/init`, lightly edited | Under one page, day-one essentials, verification block; "twice means add it" rule; code-owner approved | Changes to `CLAUDE.md` gated by eval pass rate | Repeat-mistake rate tracked and fed back; lessons folder informs future sessions |
| **Policy as skills** | Policies live in wikis | A few personal or team skills | Org skills with named owners and a written source of truth; tested for triggering | Distributed via org plugin marketplace; version logged; policy-to-skill lead time measured | Policy-citing findings near zero; drift detected via metrics and evals |
| **Enforcement hooks** | None | Default permissions prompts | Formatter/linter hooks; some protected paths | Every must-hold skill backed by a hook; approval-gate hooks; managed-only hooks; sandbox as gate | Hook violation and gate wait metrics reviewed; gates tuned based on evidence |
| **Verification / evals** | Manual testing, if any | Tests run before submitting | One-command verify target; failing-test-first for bugs; verification in "done" | Eval suite (20-50 tasks) nightly and on config change; pass rate as merge check | Every incident class yields a permanent eval; new cases come from monitoring |
| **Review** | Human review only, unchanged | Occasional AI review on request | Claude review on most PRs; `REVIEW.md` exists | Claude reviews every PR and fixes on `@claude`; babysits own PRs; code-owner approval mandatory; monthly tuning | Review metrics (time to first review, escapes) drive `REVIEW.md` and `CLAUDE.md` changes |
| **Deployment** | Manual, unchanged | Unchanged | Claude drafts release notes and triage in CI (read-only) | Write steps behind gates; tiered autonomy by environment; release manager authorizes production; rehearsed one-command rollback | 3-sigma breaches with a deploy in window can trigger the existing rollback pipeline |
| **Operations** | Humans watch dashboards | Humans watch dashboards | Claude used ad hoc in incidents | Deterministic detection scripts and versioned response tiers for key metrics | Claude on call in incident channels; scheduled security scans; diagnoses routed through gates |
| **Measurement** | None | Usage and cost visible | Stage leading/lagging metrics from git | DORA plus stage metrics on a shared dashboard; OpenTelemetry for gates | Metrics reviewed on cadence and used to tune bands, skills, hooks, and review |

---

## Self-assessment scoring sheet

Score each dimension from 1 to 5 using the matrix above. Pick the highest level whose criteria are **fully** met; partial credit goes in the notes. Record evidence for each score (a link to the artifact, setting, or dashboard).

| # | Dimension | Score (1-5) | Evidence (link) | Target next quarter | Owner |
|---|---|---|---|---|---|
| 1 | Planning artifacts | | | | Product owner |
| 2 | Context / CLAUDE.md | | | | Tech lead |
| 3 | Policy as skills | | | | Policy owners |
| 4 | Enforcement hooks | | | | Platform engineer |
| 5 | Verification / evals | | | | Platform engineer |
| 6 | Review | | | | Tech lead |
| 7 | Deployment | | | | Release manager |
| 8 | Operations | | | | Service owner |
| 9 | Measurement | | | | Engineering leadership |
| | **Total (9-45)** | | | | |

### Interpreting the total

| Total | Overall stage | Guidance |
|---|---|---|
| 9-15 | Ad hoc | Focus on Phase 0: managed settings, `CLAUDE.md`, one pilot team |
| 16-24 | Assisted | Phase 1: plan mode default, feedback loops, artifact templates |
| 25-32 | Artifact-driven | Phase 2: skills with owners, hooks for must-hold rules, PR review |
| 33-40 | Governed | Phase 3 to 4: evals as merge checks, CI/CD, first control bands |
| 41-45 | Closed-loop | Sustain: widen coverage, tune from metrics, share practices |

### Guardrail rules for scoring

- **Governance cannot run ahead of prerequisites.** Do not score Operations at 5 if Enforcement hooks is below 4; closed-loop action without deterministic gates is a risk, not maturity.
- **Evidence or it did not happen.** A dimension scores only as high as the evidence you can link.
- **Lowest dimension sets the ceiling.** Report the minimum score alongside the total; it usually identifies the next investment.

### Quick diagnostic questions

1. Can you show the `intent.md`, `spec.md`, and `plan.md` for the last three production changes?
2. If Claude tried to read `~/.aws/credentials` on an engineer's laptop, what would stop it?
3. Which skills exist, who owns each, and when did each last change?
4. Which policies are backed by a hook, and which are advisory only?
5. What happened to the eval pass rate the last time someone changed `CLAUDE.md`?
6. What is the median time to first review this month?
7. Can the agent deploy to production? If not, what stops it?
8. What was the last anomaly detected without a human noticing first?
9. Which metrics did leadership review last quarter, and what changed as a result?

## Related

- [Readiness-Assessment.md](../06-Checklists/Readiness-Assessment.md) - organization-level readiness before starting
- [Adoption-Roadmap.md](Adoption-Roadmap.md)
- [Metrics-and-KPIs.md](Metrics-and-KPIs.md)

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
