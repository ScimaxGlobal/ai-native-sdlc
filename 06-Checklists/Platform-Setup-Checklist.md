# Platform Setup Checklist

For platform engineers and IT/MDM admins standing up the shared infrastructure an AI-native SDLC depends on. Work through the sections in order; later sections assume earlier ones are complete. Check the current [settings reference](https://code.claude.com/docs/en/settings) for exact key names and precedence before deploying.

Related: [Managed-Settings-Guide.md](../02-Guides/Managed-Settings-Guide.md), [CI-CD-Integration-Guide.md](../02-Guides/CI-CD-Integration-Guide.md), [Hooks-Guide.md](../02-Guides/Hooks-Guide.md)

---

## 1. Access and identity

- [ ] Model access route chosen (Anthropic API, Amazon Bedrock, Microsoft Foundry, or Google Vertex AI) and approved by security and compliance.
- [ ] SSO / identity integration configured per the [IAM documentation](https://code.claude.com/docs/en/iam).
- [ ] Licenses or seats allocated to the pilot team, including non-engineer originators and product owners.
- [ ] Separate identity for non-interactive (CI) usage.
- [ ] Enterprise network configuration (proxy, certificates) verified if applicable.

## 2. Managed settings

- [ ] Settings file stored in version control with change approval by security.
- [ ] Deployed via MDM or server-managed settings in the admin console.
- [ ] `permissions.deny`: secret and credential paths; arbitrary egress tools.
- [ ] `permissions.allow`: safe inner loop commands to avoid prompt fatigue.
- [ ] `disableBypassPermissionsMode` set.
- [ ] `allowManagedPermissionRulesOnly` set if repo-level permission rules must not apply.
- [ ] `allowManagedHooksOnly` set if only managed hooks may run.
- [ ] `requiredMinimumVersion` set.
- [ ] Verified on a sample of endpoints that users cannot override the settings.
- [ ] Exception request process documented.

## 3. Sandbox

- [ ] Sandbox enabled per the [sandboxing documentation](https://code.claude.com/docs/en/sandboxing).
- [ ] Network domain allowlist defined (package registries, git host, internal services as needed).
- [ ] Filesystem boundaries reviewed.
- [ ] `failIfUnavailable` set if the session must refuse to start without a working sandbox.
- [ ] `allowUnsandboxedCommands` decision documented.
- [ ] Tested on every supported OS in the fleet.

## 4. Plugin marketplace and skills

- [ ] Org marketplace repository created with owners and review process ([plugins documentation](https://code.claude.com/docs/en/plugins)).
- [ ] `strictKnownMarketplaces` configured to the org marketplace.
- [ ] `disableSideloadFlags` set.
- [ ] Initial skills published (for example, `intent.md` template, spec template, secure API review), each with a named owner.
- [ ] Update propagation tested: a skill change reaches engineers without manual steps.

## 5. MCP allowlist

- [ ] Approved MCP servers listed with owner, purpose, auth method, and data scope ([MCP documentation](https://code.claude.com/docs/en/mcp)).
- [ ] `allowManagedMcpServersOnly` set.
- [ ] Deploy/status/rollback MCP tools scoped per environment (dev, staging, production).
- [ ] Connectors for non-engineers to commit artifacts configured, if used.

## 6. Hooks (org level)

- [ ] Non-negotiable hooks identified with change management and compliance.
- [ ] Hooks implemented, tested, and deployed through managed settings.
- [ ] Hook logs shipped to the central log platform.
- [ ] Template repo hooks (`.claude/settings.json`) published for teams.

## 7. OpenTelemetry

- [ ] Telemetry backend chosen (collector plus metrics and logs store).
- [ ] Telemetry environment variables distributed via managed settings, per the [monitoring documentation](https://code.claude.com/docs/en/monitoring-usage).
- [ ] Resource attributes include team or cost center.
- [ ] Dashboards for usage, cost, sessions, tool decisions created (see [Metrics-and-KPIs.md](../04-Governance/Metrics-and-KPIs.md)).
- [ ] Retention and access controls set per policy.
- [ ] Compliance API access arranged for enterprise audit needs, where available.

## 8. CI secrets and pipeline

- [ ] CI runs Claude Code non-interactively (`claude -p`) or via `claude-code-action` ([GitHub Actions documentation](https://code.claude.com/docs/en/github-actions)).
- [ ] API key stored as a CI secret, scoped to the repos that need it.
- [ ] Separate key with budget for evals and scans; spend limits configured.
- [ ] Short-lived, scoped tokens for git host and cloud access; no standing production credentials.
- [ ] Sandboxed runner profile (container, network policy).
- [ ] `--allowedTools` set explicitly in every workflow.
- [ ] Environment protection rules with named approvers for production.
- [ ] Branch protection on main in every repo using agent writes.

## 9. Evals infrastructure

- [ ] `evals/` structure and checker script agreed ([Evals-Guide.md](../02-Guides/Evals-Guide.md)).
- [ ] Workflow runs on changes to `CLAUDE.md` and `.claude/**` and nightly.
- [ ] Pass-rate threshold configured as a required check.
- [ ] Results retained as CI artifacts.

## 10. Review and scans

- [ ] Claude code review enabled on pilot repos (managed service or `claude-code-action`).
- [ ] Template `REVIEW.md` published.
- [ ] Recurring security scans configured for critical repos where available ([Recurring-Security-Scans.md](../02-Guides/Recurring-Security-Scans.md)).

## Completion

| Item | Owner | Date | Evidence link |
|---|---|---|---|
| Managed settings live | IT/MDM admin | | |
| Sandbox verified | Platform engineer | | |
| Marketplace live | Platform engineer | | |
| Telemetry live | Platform engineer | | |
| CI integration live | Platform engineer | | |
| Security sign-off | Security lead | | |

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
