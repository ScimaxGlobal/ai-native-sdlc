# Glossary

Terms are listed alphabetically. Where a term maps to a specific file or feature, the relevant guide in this kit is linked.

---

**Acceptance (of a plan).** The engineer's explicit decision that a `plan.md` is good enough to implement. In plan mode, Claude cannot edit files until the plan is accepted, which makes acceptance a design-review gate before any code exists. See [03-Build-Plan-Mode.md](../01-Stages/03-Build-Plan-Mode.md).

**Advisory control.** A control that guides behavior but does not guarantee it, such as a skill, `CLAUDE.md`, or Claude's review findings. Contrast with *deterministic control*. See [Controls-Matrix.md](../04-Governance/Controls-Matrix.md).

**Agent.** An AI system that takes actions (reading files, running commands, editing code, calling tools) in pursuit of a goal, rather than only producing text. In this kit, usually Claude Code running interactively or non-interactively.

**Agent identity.** A distinct account or credential under which non-interactive agent runs (for example, in CI) operate, so their actions are attributable and cannot be confused with a human's approval.

**Agent SDK.** Anthropic's software development kit for building agents on the same foundation as Claude Code; can be used to run a service that receives webhooks and invokes Claude in the Maintain stage.

**AI-native SDLC.** A software development lifecycle in which AI is embedded at every stage, each stage produces a version-controlled artifact the next stage reads, and human judgment is applied at critical gates. Also called agentic SDLC or AI SDLC. See [../00-Playbook/AI-Native-SDLC-Playbook.md](../00-Playbook/AI-Native-SDLC-Playbook.md).

**Artifact chain.** The sequence `intent.md` -> `spec.md` -> `plan.md` -> code and tests -> PR -> production signals -> new `intent.md`. Each link is committed and references the one before.

**Auto mode.** A way of running Claude Code in which routine actions are accepted automatically rather than prompted one by one. Appropriate once guardrails are mature (tuned `CLAUDE.md`, policy skills, safe-action hooks, strong tests); review then shifts from watching actions to reviewing artifacts.

**Automation bias.** The tendency to over-trust automated output and under-weight contrary evidence. A key people risk in AI-native review and triage. See [Risk-Register.md](../04-Governance/Risk-Register.md).

**Baseline (eval).** Eval cases that once discriminated between good and bad configurations but now consistently pass. They stay in the suite as a regression floor while new cases are added from monitoring.

**Band breach.** A metric value or pattern that violates its control band according to the detection rules, triggering the configured response tier.

**Bi-directional review.** Review running both ways: Claude reviews incoming PRs, and Claude addresses review comments on its own PRs. See [PR-Review-Guide.md](../02-Guides/PR-Review-Guide.md).

**Branch protection.** Git host rules that prevent direct pushes to protected branches and require checks and approvals before merge. The deterministic basis for segregation of duties.

**CAB (change advisory board).** A traditional governance meeting that approves changes. In the AI-native model its objectives are kept but enforced by hooks, approvals, and evidence at the moment of action.

**Champion.** A volunteer within a team who helps peers adopt the new workflow and feeds improvements back. See [Change-Management-and-Training.md](../04-Governance/Change-Management-and-Training.md).

**Claude Code.** Anthropic's agentic coding tool, usable in a terminal, IDE, desktop, web, and CI. See the [overview documentation](https://code.claude.com/docs/en/overview).

**`claude-code-action`.** A GitHub Action for running Claude Code in GitHub workflows, used for PR review, responding to `@claude` mentions, and pipeline steps. See [CI-CD-Integration-Guide.md](../02-Guides/CI-CD-Integration-Guide.md).

**Claude Security.** A hosted scanning capability (described in the source as a public beta for Claude Enterprise) that scans connected GitHub repositories on Anthropic infrastructure, validates findings before reporting, and assigns a confidence rating. See [Recurring-Security-Scans.md](../02-Guides/Recurring-Security-Scans.md).

**Claude Tag.** Claude in Slack (described in the source as a public beta), where Claude is a channel member under its own identity and can act as first responder for on-call. See [Claude-On-Call-Guide.md](../02-Guides/Claude-On-Call-Guide.md).

**`CLAUDE.md`.** A markdown file at the repository root that Claude reads at the start of every session. It holds what a new team member needs on day one: commands, conventions, architecture, and common mistakes. Keep it under one page; code owners approve changes. See [CLAUDE-md-Guide.md](../02-Guides/CLAUDE-md-Guide.md).

**Code owners.** People or teams listed in `CODEOWNERS` whose approval is required to merge changes to specified paths.

**Compliance API.** An enterprise interface for retrieving organization-level activity records for audit and compliance. See [Audit-Evidence-Guide.md](../04-Governance/Audit-Evidence-Guide.md).

**Connector.** An integration that lets Claude reach external systems; in the Plan stage, connectors let non-technical users commit `intent.md` without using git directly.

**Continuous evals.** An eval suite that runs on a schedule and on every configuration change, acting as QA for the agent setup itself. See [Evals-Guide.md](../02-Guides/Evals-Guide.md).

**Control band.** The expected range of a metric, typically defined by a rolling mean plus or minus multiples of the standard deviation (sigma). See [Control-Bands-and-Anomaly-Detection.md](../02-Guides/Control-Bands-and-Anomaly-Detection.md).

**Control objective.** What a control is meant to achieve (for example, segregation of duties), independent of how it is enforced.

**Deterministic control.** A control enforced by code outside the model, such as a hook, managed setting, branch protection, or CI check, so the outcome does not depend on what the model decides.

**DORA metrics.** The four keys from the DevOps Research and Assessment program: deployment frequency, lead time for changes, change failure rate, and time to restore service. See [Metrics-and-KPIs.md](../04-Governance/Metrics-and-KPIs.md).

**Eval.** A test for agent behavior: a prompt plus objective checks (tests pass, lint clean, behavior unchanged, policy followed). Suites of 20 to 50 real tasks are a practical starting point.

**Eval gaming.** Passing checks without achieving the goal, for example by editing tests, or an eval suite that no longer discriminates.

**Feedback loop.** A way for Claude to verify its own work (tests, build, lint, screenshots) before a human sees it.

**Flag (policy flag).** A concern Claude raises while writing a spec, noting that part of the design may conflict with a policy. Flags route to the named policy owner.

**Gate.** A point where work cannot proceed without a decision or check: PO merge, plan acceptance, code-owner approval, release authorization.

**Headless mode.** Running Claude Code non-interactively, typically with `claude -p "<prompt>"`, for scripts and CI. Often combined with `--allowedTools` and `--output-format json`.

**Hook.** A user-defined command that Claude Code runs at specific lifecycle events, such as before a tool call (PreToolUse) or after it (PostToolUse). Hooks enforce deterministically: a PreToolUse hook exiting with code 2 blocks the action and returns its message to Claude. See [Hooks-Guide.md](../02-Guides/Hooks-Guide.md).

**Important (finding).** In `REVIEW.md`, a finding that breaks behavior, leaks data, or breaches policy, as opposed to a nit.

**`intent.md`.** The Plan-stage artifact: a version-controlled proto-spec describing the problem, proposed outcome, affected users and systems, constraints, and open questions. Written by the originator with Claude. See [01-Plan-Intent.md](../01-Stages/01-Plan-Intent.md).

**Lessons folder.** A versioned folder of post-mortems and learnings that future investigations can read.

**Managed settings.** Organization-wide Claude Code settings deployed through MDM or the admin console that users cannot override: permission rules, sandbox, managed-only hooks, marketplace restrictions, MCP allowlist, minimum version. See [Managed-Settings-Guide.md](../02-Guides/Managed-Settings-Guide.md).

**Marketplace (plugin).** A catalog from which plugins are installed. Organizations can restrict installation to a private org marketplace.

**MCP (Model Context Protocol).** An open protocol for connecting AI applications to tools and data sources. In this kit, MCP servers expose tools such as deploy, status, and rollback, scoped per environment. See the [MCP documentation](https://code.claude.com/docs/en/mcp).

**MDM.** Mobile device management; the endpoint management system used to deploy managed settings.

**Nit.** A minor, style-level finding. `REVIEW.md` typically caps nits (for example, at five) and summarizes the rest as a count.

**Non-interactive job.** A Claude Code run with no human in the session, triggered by an event (merge, schedule, webhook).

**OpenTelemetry (OTel).** An open standard for telemetry. Claude Code can export metrics and events via OpenTelemetry for usage, cost, and governance analysis. See the [monitoring documentation](https://code.claude.com/docs/en/monitoring-usage).

**Originator.** The person with the problem, who may be a non-engineer, and who produces `intent.md`.

**Parallel sessions.** Multiple Claude Code instances, each in its own git worktree, steered by one engineer. Two or three is a sensible start. See [Parallel-Sessions-and-Subagents.md](../02-Guides/Parallel-Sessions-and-Subagents.md).

**Permissions (allow / deny).** Rules that pre-approve or forbid tool uses. Deny rules keep secrets out of context and block egress; allow rules pre-approve the safe inner loop to prevent prompt fatigue.

**Plan mode.** A Claude Code mode in which Claude researches and proposes a plan but cannot edit files until the plan is accepted.

**`plan.md`.** The Build-stage artifact: files that change, order of work, risks, and proof. Committed before implementation and updated in the same commit if implementation departs from it.

**Plugin.** A package that bundles skills, subagents, hooks, commands, or MCP configuration for distribution. See the [plugins documentation](https://code.claude.com/docs/en/plugins).

**Policy owner.** The named person accountable for a policy (security, compliance, brand, UX) and its encoding as a skill.

**PostToolUse / PreToolUse.** Hook events that run after or before a tool call. PreToolUse can allow, ask, or block.

**Production gate.** The boundary the agent may act up to but not past; a named human authorizes production.

**Prompt fatigue.** The tendency to approve permission prompts without reading them when they are too frequent. Mitigated by allow rules for safe actions.

**Prompt injection.** Instructions hidden in content the agent reads (issues, web pages, logs, tool output) that attempt to redirect its behavior.

**Release manager.** The named person who authorizes production releases.

**Response tiers.** Versioned configuration mapping band breach severity to allowed agent actions: typically 1 sigma log, 2 sigma read-only diagnosis, 3 sigma may open a PR or run a pre-approved runbook.

**`REVIEW.md`.** A repository file, owned by the tech lead, that tells Claude what to check in PR review (passes such as bugs/logic, security, compliance), how to classify findings, and what to skip.

**Rollback.** Returning production to a previous known-good state. Should be the most rehearsed path: one command, exercised in staging.

**Runbook (pre-approved).** A documented, approved procedure an agent may execute at the highest response tier, such as triggering an existing rollback pipeline.

**Sandbox.** OS-level isolation for commands Claude runs, restricting filesystem and network access (for example, to an allowlist of domains). See the [sandboxing documentation](https://code.claude.com/docs/en/sandboxing).

**Sigma (σ).** Standard deviation. Band thresholds are expressed as multiples of sigma from the rolling mean.

**Skill.** A folder containing a `SKILL.md` file (frontmatter with name and a description of when it applies, plus instructions) that Claude loads when relevant. Skills make institutional knowledge operational. They are advisory. See [Skills-Guide.md](../02-Guides/Skills-Guide.md).

**Skill drift.** Divergence between a skill and the policy source it encodes, or loss of triggering.

**Source of truth.** The one authoritative system for a given artifact. Either the repository is authoritative and legacy tools reference commits, or a legacy tool (for example, Jira or ServiceNow) is authoritative and markdown files are working copies. Minimum linkage: artifacts carry the record ID, records carry the commit SHA. See [Source-of-Truth-and-Legacy-Systems.md](../02-Guides/Source-of-Truth-and-Legacy-Systems.md).

**`spec.md`.** The Design-stage artifact combining requirements and design, written with org skills applied, with policy concerns flagged. See [02-Design-Spec.md](../01-Stages/02-Design-Spec.md).

**Stateless (agent run).** A run that carries no memory between invocations; context comes from the repository, artifacts, and the trigger payload.

**Subagent.** A scoped helper within a Claude Code session, with its own context window and tool restrictions, defined in `.claude/agents/`. Example: a verifier that runs the app and reports without fixing. See the [sub-agents documentation](https://code.claude.com/docs/en/sub-agents).

**Tiered autonomy.** Different agent permissions per environment: free action in dev, constrained in staging, prepare-only in production with human authorization.

**Triage (of a diagnosis).** The service owner's decision on an agent-generated `intent.md`: fix now, schedule, or dismiss. Dismissals tune the bands.

**Verifier.** A subagent or step whose job is to check a change works (start the app, exercise changed and neighboring flows) and report, without fixing.

**Western Electric rules.** A set of statistical process control rules for detecting non-random patterns in a control chart, such as a single point beyond 3 sigma, two of three consecutive points beyond 2 sigma on the same side, four of five beyond 1 sigma, or a run of consecutive points on one side of the mean. They detect drift as well as spikes. See [Control-Bands-and-Anomaly-Detection.md](../02-Guides/Control-Bands-and-Anomaly-Detection.md).

**Worktree.** A git feature that checks out additional working directories from the same repository, allowing parallel sessions on different branches without interference (for example, `claude --worktree feature-auth`).

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
