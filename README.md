# AI-Native SDLC — Playbook & Implementation Kit

A complete, implementation-ready documentation kit for running the software delivery lifecycle with Claude and
Claude Code, based on Anthropic's article
[*The AI-Native SDLC Playbook*](https://claude.com/blog/the-ai-native-sdlc-playbook) and expanded with detailed
how-tos, governance material, checklists, working templates and diagrams.

![The AI-native SDLC loop](05-Diagrams/01-ai-native-loop.svg)

## The idea in one paragraph

Coding agents have made writing code cheap. The bottleneck has moved to every stage that still runs at human
speed: planning, review, security, release governance and operations. An AI-native SDLC keeps the old control
objectives but swaps in new mechanisms. Each stage produces a **version-controlled artifact** that the next stage
reads (`intent.md → spec.md → plan.md → code + tests → PR`). **People own the gates, agents own the work between
them.** Production signals flow back in as new intent, so the lifecycle becomes a **loop**, not a line.

## How this kit is organised

| Folder | What's inside | Start here if you… |
|---|---|---|
| [`00-Playbook/`](00-Playbook/AI-Native-SDLC-Playbook.md) | **The playbook** — the complete end-to-end narrative, principles, all six stages, governance, metrics, roadmap | want the whole picture |
| [`01-Stages/`](01-Stages/README.md) | One deep-dive per stage: roles, prerequisites, step-by-step how-to, prompts, worked example, metrics, entry/exit criteria | are running a specific stage |
| [`02-Guides/`](02-Guides/README.md) | How-to guides for each mechanism: `CLAUDE.md`, skills, hooks, subagents, evals, PR review, managed settings, CI/CD, control bands, scans, on-call, source of truth | are building the machinery |
| [`03-Templates/`](03-Templates/README.md) | Copy-paste templates and **working scripts**: artifact templates, filled examples, skills, subagents, settings, hooks, CI workflows, evals, anomaly detection | want to install it in a repo |
| [`04-Governance/`](04-Governance/README.md) | RACI, controls matrix, metrics & KPIs, adoption roadmap, maturity model, risk register, audit evidence, change management | own risk, compliance or the rollout |
| [`05-Diagrams/`](05-Diagrams/README.md) | Nine SVG diagrams (+ PNG renders) used throughout | need visuals for a deck or wiki |
| [`06-Checklists/`](06-Checklists/README.md) | Readiness assessment, stage-gate checklists, security review, platform setup, repo onboarding, incident-to-eval | want to check you're ready |
| [`07-Reference/`](07-Reference/README.md) | Glossary, FAQ, prompt library, sources and further reading | need a definition or a ready prompt |

## The six stages at a glance

| # | Stage | Artifact produced | Human gate | Key mechanism |
|---|---|---|---|---|
| 1 | [Plan](01-Stages/01-Plan-Intent.md) | `intent.md` | Product owner merges | Claude interviews the originator; template as a skill |
| 2 | [Design](01-Stages/02-Design-Spec.md) | `spec.md` | PO signs off; policy owners resolve flags | Org policies encoded as skills |
| 3 | [Build](01-Stages/03-Build-Plan-Mode.md) | `plan.md`, code, tests | Engineer accepts plan | Plan mode, `CLAUDE.md`, skills, hooks, parallel worktrees, subagents |
| 4 | [Test](01-Stages/04-Test-Feedback-Loops-and-Evals.md) | Verified change, eval results | CI green; eval threshold | Self-verification loops, continuous evals |
| 5 | [Deploy](01-Stages/05-Deploy-Review-and-Gates.md) | Reviewed PR, release | Code owner approves; named manager releases | Two-way AI review, approval-gate hooks, managed settings, CI/CD via MCP |
| 6 | [Maintain](01-Stages/06-Maintain-Close-the-Loop.md) | New `intent.md`, post-mortems, evals | Service owner triages | Control bands, scheduled scans, Claude on call |

## Suggested reading paths

- **Executive (30 min):** [Playbook](00-Playbook/AI-Native-SDLC-Playbook.md) §1–3 and §11–14 →
  [Adoption Roadmap](04-Governance/Adoption-Roadmap.md) → [Maturity Model](04-Governance/Maturity-Model.md)
- **Product owner (1 h):** Playbook §4–6 → [Stage 1](01-Stages/01-Plan-Intent.md) → [Stage 2](01-Stages/02-Design-Spec.md) →
  [Prompt Library](07-Reference/Prompt-Library.md)
- **Engineer (2 h):** Playbook §7–9 → [Stage 3](01-Stages/03-Build-Plan-Mode.md) → [CLAUDE.md guide](02-Guides/CLAUDE-md-Guide.md) →
  [Parallel sessions & subagents](02-Guides/Parallel-Sessions-and-Subagents.md) → [Templates](03-Templates/README.md)
- **Platform / DevEx (half day):** [Hooks](02-Guides/Hooks-Guide.md) → [Managed settings](02-Guides/Managed-Settings-Guide.md) →
  [Evals](02-Guides/Evals-Guide.md) → [CI/CD](02-Guides/CI-CD-Integration-Guide.md) → [Platform setup checklist](06-Checklists/Platform-Setup-Checklist.md)
- **Security & compliance:** [Controls Matrix](04-Governance/Controls-Matrix.md) → [Risk Register](04-Governance/Risk-Register.md) →
  [Audit Evidence](04-Governance/Audit-Evidence-Guide.md) → [Security Review Checklist](06-Checklists/Security-Review-Checklist.md)
- **SRE / on-call:** [Stage 6](01-Stages/06-Maintain-Close-the-Loop.md) → [Control bands](02-Guides/Control-Bands-and-Anomaly-Detection.md) →
  [Claude on call](02-Guides/Claude-On-Call-Guide.md)

## Quick start: install into a pilot repository

1. Read [`03-Templates/README.md`](03-Templates/README.md) and copy the recommended layout into the repo.
2. Run `/init` in Claude Code, then trim the result using [`CLAUDE.template.md`](03-Templates/CLAUDE.template.md).
3. Copy `.claude/settings.json` from [`settings/project-settings.json`](03-Templates/settings/project-settings.json) and the
   scripts in [`hooks/`](03-Templates/hooks/). Make them executable.
4. Add [`REVIEW.md`](03-Templates/REVIEW.template.md) and the [PR review workflow](03-Templates/ci/claude-pr-review.yml).
5. Capture your first feature as an `intent.md` using the [worked example](03-Templates/examples/intent.claims-status.md) as a guide.
6. Walk it through the stages with the [Stage-Gate Checklists](06-Checklists/Stage-Gate-Checklists.md).

## Running example

Every stage document follows the same feature end to end — an insurer's **claims status self-service** portal
panel, motivated by status calls consuming roughly a third of contact-centre time — so you can see how one idea
becomes `intent.md`, `spec.md`, `plan.md`, code, a reviewed PR, a gated release and finally a monitored service.

## Attribution and disclaimer

Concepts are drawn from Anthropic's *The AI-Native SDLC Playbook* (credited contributors: Jim Blackhurst,
Will Steuk, Jamal Arif). This kit's prose, templates, scripts and diagrams are an independent implementation aid,
not official Anthropic documentation. Product features described as beta were so at the time of the source
article. Configuration keys and CLI flags change — verify against the current
[Claude Code documentation](https://code.claude.com/docs/en/overview) before production rollout. Compliance
mappings are indicative and not legal advice.
