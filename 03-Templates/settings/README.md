# Settings templates

JSON cannot carry comments, so this file explains every key in
`project-settings.json` and `managed-settings.json`. Syntax was checked against
the Claude Code docs (settings, settings-reference, permissions, hooks,
sandboxing, managed-settings, plugins/org, managed-mcp) in September 2026.
Anything not confirmed there is marked **verify**.

Precedence, highest first: **managed** → command line (`--settings`) →
`.claude/settings.local.json` → `.claude/settings.json` → `~/.claude/settings.json`.
Nothing a developer sets overrides a managed value (a few security-sensitive keys
accept a *stricter* lower value).

---

## `project-settings.json` → copy to `<repo>/.claude/settings.json`

Owner: tech lead / platform engineer. Committed to git; changes reviewed through CODEOWNERS.

| Key | What it does | Notes |
|---|---|---|
| `$schema` | Editor autocompletion/validation. | Optional. Schema URL is the community SchemaStore entry — **verify** it tracks the current version. |
| `permissions.defaultMode` | Starting permission mode. `"default"` asks on first use of each tool. Other values: `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions`. | Teams moving to plan-mode-by-default can set `"plan"`. |
| `permissions.allow` | Pre-approves the safe inner loop (build, test, lint, read-only git) so engineers are not prompted all day. | Rule syntax: `Tool` or `Tool(specifier)`. `Bash(make test *)` uses `*` as a wildcard. |
| `permissions.ask` | Always prompt, even if a broader allow exists. | Used for `git push`, PR creation. |
| `permissions.deny` | Never allowed; deny beats allow. | `Read(/.env)` — a leading `/` anchors at the project root in project settings. `~/` anchors at the home directory. `//` is filesystem-absolute. `Edit(...)` rules cover every built-in file-editing tool (Edit, Write, MultiEdit). |
| `hooks.PreToolUse[]` | Runs before a tool call. Exit code `2` blocks the call and the script's stderr is shown to Claude. | `matcher` is an exact tool name, a `|`-separated list (`Edit|Write`), or a regex. |
| `hooks.PostToolUse[]` | Runs after a tool call succeeds. Used here for the formatter. | Keep it fast and scoped to the changed file. |
| `type: "command"` / `command` / `timeout` | Shell command to run, and a timeout in seconds. | `${CLAUDE_PROJECT_DIR}` expands to the project root. The command is wrapped in `bash "..."` so the script does not need the executable bit (useful on Windows/Git Bash). |

Hooks wired in the template:

| Event / matcher | Script | Blocks when |
|---|---|---|
| PreToolUse `Bash` | `production-gate.sh` | command looks like a production deploy and `RELEASE_APPROVAL` is unset |
| PreToolUse `Edit|Write|MultiEdit|NotebookEdit` | `protect-paths.sh` | target matches `.claude/protected-paths.txt` |
| PreToolUse `Edit|Write|MultiEdit|NotebookEdit` | `protect-tests.sh` | fix mode is on (`FIX_MODE=1` or `.claude/fix-mode`) and target is a test file |
| PreToolUse `Read|Edit|Write|MultiEdit|Bash` | `block-secrets.sh` | secret file read/written, secret-looking content written, or a command dumps credentials |
| PostToolUse `Edit|Write|MultiEdit` | `post-edit-format.sh` | never (always exits 0) |

**Windows-native teams:** replace the `bash "..."` commands with
`pwsh -NoProfile -File "${CLAUDE_PROJECT_DIR}/.claude/hooks/production-gate.ps1"` (and
`protect-paths.ps1`). The PowerShell tool's input also carries `tool_input.command`, so
the production gate should match `"Bash|PowerShell"` there. **Verify** the exact tool
name your Claude Code version reports for PowerShell by logging one hook input.

Optional refinements:

- A hook entry can carry `"if": "Bash(git push *)"` to fire only for matching calls (confirmed in the hooks reference). Useful to avoid starting a script on every Bash call.
- Instead of exit 2, a PreToolUse hook may print JSON `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny"|"ask"|"allow","permissionDecisionReason":"..."}}` and exit 0. Use `"ask"` for gates where a human in the session may approve.

---

## `managed-settings.json` → deploy by MDM / admin console for regulated enterprises

Owner: platform / security engineering, with change-management and compliance sign-off.
Engineers cannot override it.

File locations (confirmed):

| OS | Path |
|---|---|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux / WSL | `/etc/claude-code/managed-settings.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-settings.json` |

Alternatives: a `managed-settings.d/*.json` drop-in directory beside the file (one file per owning team), an MDM profile/registry value, or **server-managed settings** in the claude.ai admin console (the only source that reaches cloud sessions). If a managed file fails to parse, Claude Code refuses to start — validate with `python -m json.tool` before shipping.

| Key | Purpose (playbook control) | Status |
|---|---|---|
| `requiredMinimumVersion` | Refuse to run clients older than a version that has the controls you rely on. String semver. Read at startup. | confirmed (managed-only). Pick a real version for your fleet. |
| `permissions.disableBypassPermissionsMode: "disable"` | No one can start in `bypassPermissions` mode. | confirmed — value is the string `"disable"`. `permissions.disableAutoMode: "disable"` does the same for auto mode if your policy forbids it. |
| `permissions.deny` | Keep secrets out of context (`~/.ssh`, `~/.aws/credentials`, `.env`, keys) and block ad-hoc egress tools (`curl`, `wget`, `nc`, `ssh`, `scp`, `WebFetch`). | confirmed syntax. Removing `WebFetch` and `curl` from deny is reasonable if the sandbox network allowlist is your egress control. |
| `permissions.allow` | Pre-approve the safe inner loop so strict policy does not create prompt fatigue. | confirmed |
| `allowManagedPermissionRulesOnly: true` | Only managed allow/ask/deny rules apply; project and user rules are ignored. | confirmed (managed-only). Consequence: put every allow rule teams need here. |
| `sandbox.enabled` | OS-level isolation of Bash (Seatbelt on macOS, bubblewrap on Linux/WSL2). | confirmed. **Not supported on native Windows** — Windows users must run in WSL2 or a container. |
| `sandbox.failIfUnavailable: true` | Treat the sandbox as a gate: Claude Code refuses to start if the sandbox cannot initialize. | confirmed |
| `sandbox.allowUnsandboxedCommands: false` | Removes the "retry outside the sandbox" escape hatch. | confirmed |
| `sandbox.autoAllowBashIfSandboxed` | Sandboxed commands run without a prompt (the boundary contains them). | confirmed (defaults to `true`). |
| `sandbox.excludedCommands` | Commands that must run outside the sandbox. Keep empty or very narrow — developers can append entries and there is no managed-only lock. | confirmed |
| `sandbox.network.allowedDomains` | Egress allowlist enforced at OS level for sandboxed commands. | confirmed. Replace the example hosts. |
| `sandbox.network.allowManagedDomainsOnly: true` | Only managed domain entries count; developers cannot widen the list. | confirmed (managed-only). |
| `sandbox.filesystem.denyRead` | Blocks sandboxed processes from reading credential directories. | confirmed |
| `sandbox.credentials.files[] / envVars[]` with `"mode": "deny"` | Denies reads of credential files and **unsets secret env vars** before each sandboxed command. | confirmed. `"mode": "mask"` is also available. |
| `allowManagedHooksOnly: true` | Only managed hooks run; project/user hooks are ignored. | confirmed (managed-only). Consequence: the hooks you need must be listed here, pointing to scripts you deploy (example path `/etc/claude-code/hooks/`). |
| `hooks` (in managed) | Non-negotiable gates (production gate, secrets). | confirmed shape; the script paths are examples — deploy the scripts with the same MDM package. |
| `disableSideloadFlags: true` | Rejects `--plugin-dir`, `--plugin-url`, `--agents`, `--mcp-config` at startup. | confirmed (managed-only). |
| `strictKnownMarketplaces` | Allowlist of plugin marketplace sources, e.g. `{ "source": "github", "repo": "org/repo" }`. `[]` blocks all. | confirmed (managed-only). Add `{ "source": "skills-dir" }` if you want skills-directory plugins to keep loading. |
| `extraKnownMarketplaces` + `enabledPlugins` | Registers the org marketplace and force-enables policy plugins (e.g. the one that ships `secure-api-review`). | confirmed. Plugin/marketplace names are examples. |
| `allowManagedMcpServersOnly: true` + `allowedMcpServers` | Only MCP servers on the managed allowlist can connect. Entries use `serverUrl` (wildcards allowed), `serverCommand` (array), or `serverName`. | confirmed (`serverUrl`/`serverCommand` shapes seen in docs; **verify** `serverName` if you use it). |
| `env` | Environment for every session — here, OpenTelemetry export so gate wait times and tool use are measurable. | `env` confirmed. The `CLAUDE_CODE_ENABLE_TELEMETRY` / `OTEL_*` variable names follow the monitoring docs — **verify** against the current monitoring-usage page and your collector. |

Also consider (not in the template): `permissions.disableAutoMode`, `availableModels`,
`blockedMarketplaces`, `strictPluginOnlyCustomization`, `allowManagedReadPathsOnly`
(sandbox), and `managedSourcesBehavior` if you deliver more than one managed source.

## Validate before shipping

```bash
python -m json.tool settings/project-settings.json > /dev/null && echo OK
python -m json.tool settings/managed-settings.json > /dev/null && echo OK
```

Then start Claude Code on a test machine and run `/status` — "Enterprise managed
settings" should appear under setting sources — and `/permissions` to see the
effective rules.
