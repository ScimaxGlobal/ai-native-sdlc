# Security Review Checklist

Use this checklist when reviewing the security posture of an AI-native setup: a new team's configuration, a change to managed settings or hooks, a new MCP server or plugin, a new CI integration, or a release with elevated risk. It complements, and does not replace, your existing application security review.

Related: [Controls-Matrix.md](../04-Governance/Controls-Matrix.md), [Risk-Register.md](../04-Governance/Risk-Register.md), [Managed-Settings-Guide.md](../02-Guides/Managed-Settings-Guide.md)

---

## 1. Endpoint and managed settings

- [ ] Managed settings are deployed via MDM or admin console and cannot be overridden by users.
- [ ] `permissions.deny` covers credential and secret paths (for example, `~/.ssh`, `~/.aws/credentials`, `.env` files, key stores).
- [ ] Secrets are stripped from the environment passed to sessions.
- [ ] `permissions.allow` pre-approves only the safe inner loop (build, test, lint, read).
- [ ] `disableBypassPermissionsMode` is set.
- [ ] `allowManagedPermissionRulesOnly` is set where required.
- [ ] Sandbox is enabled with a network domain allowlist.
- [ ] `failIfUnavailable` makes the sandbox a gate (session refuses to start without it) where required; `allowUnsandboxedCommands` is set deliberately.
- [ ] `allowManagedHooksOnly` is set if non-negotiable hooks must not be replaced by repo hooks.
- [ ] `requiredMinimumVersion` is set.

## 2. Extensions: plugins, skills, MCP

- [ ] `strictKnownMarketplaces` restricts plugins to the org marketplace; `disableSideloadFlags` is set.
- [ ] Every plugin and skill in the marketplace has an owner and passed review.
- [ ] `allowManagedMcpServersOnly` restricts MCP servers to the approved list.
- [ ] Each MCP server: authentication method reviewed, scopes minimal, data flows documented.
- [ ] MCP tools for deploy/status/rollback are scoped per environment.
- [ ] Versions of plugins and MCP servers are pinned and changes are reviewed.

## 3. Prompt injection exposure

- [ ] Untrusted inputs are identified (issues, PR comments, logs, web content, dependency files, MCP tool output).
- [ ] Sessions processing untrusted input run with read-only or minimal tools.
- [ ] Egress is blocked except for allowlisted domains, limiting exfiltration.
- [ ] No session that reads untrusted input holds write credentials to production.
- [ ] High-risk commands are blocked or require approval via PreToolUse hooks.

## 4. Hooks

- [ ] Every must-hold policy in a skill is backed by a hook or setting.
- [ ] Hooks are version-controlled and code-owner approved (repo) or managed (org).
- [ ] Hooks fail closed where the policy requires it.
- [ ] Block messages explain why and how to get approval.
- [ ] Hooks are fast and scoped to the changed file.
- [ ] Hook scripts have been tested with representative inputs, including adversarial ones (quoting, chained commands).
- [ ] Hook decisions are logged centrally.

## 5. Repository and review

- [ ] Branch protection prevents direct pushes to main and requires code-owner approval.
- [ ] Agent identities cannot approve PRs.
- [ ] `REVIEW.md` includes a security pass.
- [ ] Security skill (for example, a secure API review skill) is installed and triggers on relevant work.
- [ ] Secret scanning runs in CI and/or as a hook.
- [ ] Dependency changes are flagged for human review.

## 6. CI/CD

- [ ] Claude runs in CI in a sandboxed profile (container, network policy).
- [ ] Tokens are short-lived and scoped; no standing production credentials.
- [ ] `--allowedTools` is set explicitly for each non-interactive invocation.
- [ ] Non-interactive runs use a distinct agent identity.
- [ ] All agent writes arrive as PRs; no direct path to main.
- [ ] Production deploy requires a named human approval.
- [ ] Eval and API keys have spend limits.

## 7. Data handling

- [ ] Model access route and region meet data residency requirements.
- [ ] Data classification guidance is in `CLAUDE.md` or a skill (what may and may not be pasted or read).
- [ ] PII-tagged fields are never logged or included in error messages (skill plus CI or hook check).
- [ ] Telemetry configuration does not export sensitive content beyond policy.

## 8. Monitoring and response

- [ ] OpenTelemetry data arrives and is retained per policy.
- [ ] Alerts exist for unusual hook blocks, sandbox violations, or cost spikes.
- [ ] Recurring scans are scheduled for in-scope repos; dismissals require reasons.
- [ ] Incident channel with Claude on call (if used) has retention and access controls.
- [ ] Incident runbook covers suspected agent misuse or injection.

## Sign-off

| Role | Name | Date | Decision |
|---|---|---|---|
| Security lead | | | Approve / Approve with conditions / Reject |
| Platform engineer | | | |
| Code owner (if repo-scoped) | | | |

Conditions and exceptions (with expiry dates):

---

*Based on concepts from Anthropic's AI-Native SDLC Playbook; expanded guidance for implementation.*
