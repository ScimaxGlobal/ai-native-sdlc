<#
.SYNOPSIS
  production-gate.ps1 - PreToolUse hook (matcher "Bash" or "PowerShell") for Windows.

.DESCRIPTION
  PowerShell equivalent of production-gate.sh. Blocks a command that looks like
  a production deploy unless RELEASE_APPROVAL is set in the environment Claude
  Code was started from.

  Wiring (in .claude/settings.json):
    "command": "pwsh -NoProfile -File \"${CLAUDE_PROJECT_DIR}/.claude/hooks/production-gate.ps1\""

  Contract: reads the hook event JSON from stdin.
    exit 0 -> allow (normal permission flow continues)
    exit 2 -> block; text written to stderr is shown to Claude as the reason

.EXAMPLE
  '{"tool_input":{"command":"deploy production"}}' | pwsh -NoProfile -File .\production-gate.ps1; $LASTEXITCODE   # 2
#>

$ErrorActionPreference = 'Stop'

# --- 1. Read and parse stdin. Fail CLOSED if the event cannot be parsed. ---
try {
    $raw   = [Console]::In.ReadToEnd()
    $hookInput = $raw | ConvertFrom-Json
} catch {
    [Console]::Error.WriteLine('production-gate: cannot parse hook input. Blocking to be safe.')
    exit 2
}

# --- 2. Extract the command (Bash and PowerShell tools both use tool_input.command).
$command = $null
if ($hookInput.PSObject.Properties.Name -contains 'tool_input' -and $hookInput.tool_input) {
    $command = $hookInput.tool_input.command
}
if ([string]::IsNullOrWhiteSpace($command)) { exit 0 }

$lc = $command.ToLowerInvariant()

# --- 3. Detect a production deploy.
#   Rule A: mentions "deploy" AND the word "prod"/"production".
#   Rule B: org-specific patterns; override with env PROD_GATE_EXTRA (regex).
$extra = if ($env:PROD_GATE_EXTRA) { $env:PROD_GATE_EXTRA } else {
    '(kubectl .*--context[= ]+prod|helm (upgrade|install) .*prod|terraform apply .*prod|--env[= ]+prod(uction)?)'
}
$isProd = ($lc -match 'deploy' -and $lc -match '(^|[^a-z])prod(uction)?([^a-z]|$)') -or ($lc -match $extra)
if (-not $isProd) { exit 0 }

# --- 4. Require a human-granted release approval.
if ([string]::IsNullOrWhiteSpace($env:RELEASE_APPROVAL)) {
    [Console]::Error.WriteLine(@'
BLOCKED by production-gate: this command deploys to production and no release approval is present.
Production deploys need a named human approver. To proceed:
  1. Get the change approved in the change-management system (CAB / release ticket).
  2. The approver (not Claude) restarts the session with RELEASE_APPROVAL=<change-id> set,
     or runs the deploy through the release pipeline.
Claude: prepare the release (notes, rollback command, checks) but do not retry this command.
'@)
    exit 2
}

[Console]::Error.WriteLine("production-gate: allowed under RELEASE_APPROVAL=$($env:RELEASE_APPROVAL)")
exit 0
