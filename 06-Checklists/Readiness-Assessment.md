# Readiness Assessment

Use this questionnaire before starting an AI-native SDLC rollout, and again before onboarding each new team. It measures whether the organizational, technical, and governance preconditions are in place. It is not a maturity score (see [Maturity-Model.md](../04-Governance/Maturity-Model.md) for that); it answers "are we ready to start, and where will we get stuck?"

## Scoring

Score each question:

| Score | Meaning |
|---|---|
| 0 | Not in place, and no plan |
| 1 | Planned or partially in place |
| 2 | In place for some teams or repos |
| 3 | In place and working for the scope being assessed |

Each section has a weight reflecting how strongly it blocks progress. Section score = (sum of question scores / maximum) x weight. Total is out of 100.

---

## Section A - Sponsorship and operating model (weight 15)

| # | Question | Score (0-3) | Notes |
|---|---|---|---|
| A1 | Is there a named executive sponsor who will fund platform work and defend the pace? | | |
| A2 | Has a pilot team volunteered, including at least one constructive skeptic? | | |
| A3 | Are product owners willing to approve intent and spec through PR merges? | | |
| A4 | Has change management agreed to map existing gates onto AI-native mechanisms? | | |
| A5 | Is there agreement that agents never hold an approval route? | | |

## Section B - Engineering foundations (weight 25)

| # | Question | Score (0-3) | Notes |
|---|---|---|---|
| B1 | Can each in-scope repo build and run its tests locally with one command? | | |
| B2 | Is the test suite trustworthy enough that green means "probably correct"? | | |
| B3 | Is branch protection with required code-owner approval enabled on main? | | |
| B4 | Is `CODEOWNERS` defined and current? | | |
| B5 | Are lint and formatting enforced automatically? | | |
| B6 | Is there a CI system that could run Claude Code non-interactively? | | |
| B7 | Does a one-command rollback exist and has it been exercised in staging? | | |

## Section C - Security and platform (weight 25)

| # | Question | Score (0-3) | Notes |
|---|---|---|---|
| C1 | Can IT deploy managed settings to engineer endpoints via MDM or the admin console? | | |
| C2 | Is there an agreed list of paths and secrets that must never enter model context? | | |
| C3 | Is there an agreed network egress allowlist for sandboxing? | | |
| C4 | Has a model access route been chosen that meets data residency requirements? | | |
| C5 | Is there a process to vet plugins and MCP servers before use? | | |
| C6 | Can CI issue short-lived, scoped tokens with no standing production credentials? | | |
| C7 | Is there a telemetry backend that can receive OpenTelemetry data? | | |

## Section D - Policy and knowledge (weight 15)

| # | Question | Score (0-3) | Notes |
|---|---|---|---|
| D1 | Do key policies (security, compliance, brand, UX) each have a named owner? | | |
| D2 | Does each such policy have a written source of truth? | | |
| D3 | Have you identified policies that are currently enforced inconsistently? | | |
| D4 | Is there a decision on the source of truth for requirements and work items (repo or legacy tool)? | | |

## Section E - Measurement (weight 10)

| # | Question | Score (0-3) | Notes |
|---|---|---|---|
| E1 | Are DORA four keys measured today (even roughly)? | | |
| E2 | Can you export PR and review data from the git host? | | |
| E3 | Is there a metrics store (for example, Prometheus or a CI API) for production signals? | | |

## Section F - People and change (weight 10)

| # | Question | Score (0-3) | Notes |
|---|---|---|---|
| F1 | Is there capacity for training (roughly one day per person in the first phase)? | | |
| F2 | Can you staff a champions network (about one per 8-12 engineers)? | | |
| F3 | Is there a communication channel and owner for rollout updates? | | |

---

## Score calculation

| Section | Sum | Max | Weight | Weighted score |
|---|---|---|---|---|
| A Sponsorship and operating model | | 15 | 15 | |
| B Engineering foundations | | 21 | 25 | |
| C Security and platform | | 21 | 25 | |
| D Policy and knowledge | | 12 | 15 | |
| E Measurement | | 9 | 10 | |
| F People and change | | 9 | 10 | |
| **Total** | | | **100** | |

Weighted score for a section = (Sum / Max) x Weight.

## Interpretation

| Total | Readiness | Recommended action |
|---|---|---|
| 0-39 | Not ready | Close gaps in sections B and C before starting; begin sponsorship and policy ownership work |
| 40-59 | Ready for a limited pilot | Start Phase 0 with one team and one or two repos; fix blockers in parallel |
| 60-79 | Ready to pilot and plan scale-out | Run Phases 0-1; schedule Phase 2 once section C is at 2 or above everywhere |
| 80-100 | Ready to scale | Proceed with the full roadmap; use the maturity model to target dimensions |

**Hard blockers** (regardless of total): any score of 0 on B1, B3, C1, C2, or A5. Resolve these before any production use.

## Output of the assessment

- [ ] Completed scoresheet stored in version control with date and assessors.
- [ ] List of hard blockers with owners and target dates.
- [ ] Top three gaps mapped to phases in [Adoption-Roadmap.md](../04-Governance/Adoption-Roadmap.md).
- [ ] Reassessment date set.

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
