#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# production-gate.sh — PreToolUse hook (matcher: "Bash")
#
# Purpose: an approval gate enforced at the moment of action. Claude may do
# everything up to the production gate, nothing past it. A Bash command that
# looks like a production deploy is BLOCKED unless a human has granted release
# approval by exporting RELEASE_APPROVAL (e.g. a change/ticket number) in the
# environment Claude Code was started from.
#
# Install: copy to .claude/hooks/production-gate.sh and wire it in
#          .claude/settings.json (see settings/project-settings.json).
#          For a non-negotiable gate, wire it in managed settings instead.
#
# Contract (Claude Code hooks):
#   stdin  : JSON event, e.g. {"tool_name":"Bash","tool_input":{"command":"..."}}
#   exit 0 : allow (normal permission flow continues)
#   exit 2 : block; stderr is shown to Claude as the reason
#
# Test:
#   echo '{"tool_input":{"command":"deploy production"}}' | bash production-gate.sh; echo $?   # -> 2
#   echo '{"tool_input":{"command":"make test"}}'         | bash production-gate.sh; echo $?   # -> 0
# ---------------------------------------------------------------------------
set -u

# --- 1. Read the whole hook event from stdin -------------------------------
INPUT="$(cat)"

# --- 2. JSON helper -----------------------------------------------------------
# json_fields PATH...
#   Parses the hook event in $INPUT ONCE and sets F1..Fn to the values at the
#   given dotted paths ("" when absent; objects/arrays as compact JSON).
#   Uses jq when installed, otherwise Python (jq is often missing on Windows /
#   Git Bash). Values are NUL-separated so multi-line content survives intact.
#   Returns 3 when no parser is available or $INPUT is not valid JSON, so the
#   caller can decide to fail closed.
json_fields() {
  local i=0 v ok="" p py="" filter='"OK", "\u0000"'
  for p in "$@"; do
    i=$((i + 1)); eval "F$i=''"
    filter="$filter, (.${p} // \"\" | if type==\"string\" then . else tojson end), \"\u0000\""
  done
  if ! command -v jq >/dev/null 2>&1; then
    for c in python3 python py; do
      if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import json' >/dev/null 2>&1; then py="$c"; break; fi
    done
    [ -n "$py" ] || return 3
  fi
  i=0
  while IFS= read -r -d '' v; do
    if [ "$i" -eq 0 ]; then ok="$v"; else eval "F$i=\$v"; fi
    i=$((i + 1))
  done < <(
    if [ -z "$py" ]; then
      printf '%s' "$INPUT" | jq -j "$filter" 2>/dev/null
    else
      printf '%s' "$INPUT" | "$py" -c '
import json, sys
try:
    d = json.loads(sys.stdin.read())
except Exception:
    sys.exit(0)                      # no "OK" sentinel -> caller sees rc 3
out = ["OK"]
for path in sys.argv[1:]:
    v = d
    for k in path.split("."):
        v = v.get(k) if isinstance(v, dict) else None
        if v is None:
            break
    out.append("" if v is None else v if isinstance(v, str) else json.dumps(v, separators=(",", ":")))
sys.stdout.buffer.write(("\0".join(out) + "\0").encode("utf-8"))
' "$@"
    fi
  )
  [ "$ok" = "OK" ] || return 3
  return 0
}

# --- 3. Extract the command. Fail CLOSED if we cannot parse: a gate that
#        silently opens when its parser is missing is not a gate. ----------
json_fields tool_input.command; rc=$?
COMMAND="$F1"
if [ "$rc" -eq 3 ]; then
  echo "production-gate: cannot parse hook input (install jq or python). Blocking to be safe." >&2
  exit 2
fi
[ -z "$COMMAND" ] && exit 0   # not a Bash command event -> nothing to gate

# Lower-case copy for case-insensitive matching.
CMD_LC="$(printf '%s' "$COMMAND" | tr '[:upper:]' '[:lower:]')"

# --- 4. Decide whether this is a production deploy --------------------------
# Rule A (from the playbook example): mentions "deploy" AND "production"/"prod".
# Rule B: extra org-specific patterns (ERE), override with PROD_GATE_EXTRA.
EXTRA_PATTERN="${PROD_GATE_EXTRA:-(kubectl .*--context[= ]+prod|helm (upgrade|install) .*prod|terraform apply .*prod|--env[= ]+prod(uction)?)}"

is_prod=0
if printf '%s' "$CMD_LC" | grep -Eq 'deploy' && printf '%s' "$CMD_LC" | grep -Eq '(^|[^a-z])prod(uction)?([^a-z]|$)'; then
  is_prod=1
elif printf '%s' "$CMD_LC" | grep -Eq "$EXTRA_PATTERN"; then
  is_prod=1
fi
[ "$is_prod" -eq 0 ] && exit 0

# --- 5. Production deploy: require human release approval ------------------
if [ -z "${RELEASE_APPROVAL:-}" ]; then
  cat >&2 <<'EOF'
BLOCKED by production-gate: this command deploys to production and no release approval is present.
Production deploys need a named human approver. To proceed:
  1. Get the change approved in the change-management system (CAB / release ticket).
  2. The approver (not Claude) restarts the session with RELEASE_APPROVAL=<change-id> set,
     or runs the deploy through the release pipeline.
Claude: prepare the release (notes, rollback command, checks) but do not retry this command.
EOF
  exit 2
fi

# Approval present: allow, and leave an audit line on stderr (non-blocking).
echo "production-gate: allowed under RELEASE_APPROVAL=${RELEASE_APPROVAL}" >&2
exit 0
