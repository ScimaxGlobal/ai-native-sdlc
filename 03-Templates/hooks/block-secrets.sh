#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# block-secrets.sh — PreToolUse hook (matcher: "Read|Edit|Write|MultiEdit|Bash")
#
# Purpose: keep credentials out of Claude's context and out of the repo.
#   - Read  : block reading well-known secret files (.env, private keys,
#             cloud credential files).
#   - Edit/Write/MultiEdit : block writing content that looks like a secret
#             (cloud keys, private keys, tokens, hard-coded passwords), and
#             block writing to secret files.
#   - Bash  : block commands that print secret files (cat ~/.ssh/id_rsa, etc.).
#
# This is defense in depth. In managed settings ALSO deny these paths with
# permissions.deny and sandbox.credentials (see settings/managed-settings.json).
#
# Contract: stdin JSON; exit 0 allow; exit 2 block (stderr = reason).
# Test:
#   echo '{"tool_name":"Write","tool_input":{"file_path":"a.py","content":"k=\"AKIAABCDEFGHIJKLMNOP\""}}' | bash block-secrets.sh; echo $?  # -> 2
# ---------------------------------------------------------------------------
set -u

INPUT="$(cat)"

# --- JSON helper (jq, else Python) -----------------------------------------
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

block() {
  echo "BLOCKED by block-secrets: $1" >&2
  echo "Secrets must come from the secret manager / environment at runtime, never from files Claude reads or writes. If this is a false positive, ask the engineer to allowlist it." >&2
  exit 2
}

# One parse: tool name, target file, Bash command, and the whole tool_input as
# JSON text (covers Write.content, Edit.new_string and MultiEdit.edits[]).
json_fields tool_name tool_input.file_path tool_input.command tool_input; rc=$?
if [ "$rc" -eq 3 ]; then
  echo "block-secrets: cannot parse hook input (install jq or python). Blocking to be safe." >&2
  exit 2
fi
TOOL="$F1"
FILE="$(printf '%s' "$F2" | tr '\\' '/')"
CMD="$F3"
PAYLOAD="$F4"

# --- 1. Secret FILE names (read or write) ----------------------------------
SECRET_FILE_RE='(^|/)(\.env(\.[A-Za-z0-9_-]+)?|id_(rsa|dsa|ecdsa|ed25519)|[^/]*\.pem|[^/]*\.p12|[^/]*\.pfx|[^/]*\.key|credentials|\.netrc|\.pgpass|\.npmrc|\.pypirc)$|(^|/)\.ssh/|(^|/)\.aws/|(^|/)\.gnupg/|(^|/)\.kube/config$'
ALLOW_FILE_RE='(^|/)\.env\.(example|sample|template)$'

if [ -n "$FILE" ] && printf '%s' "$FILE" | grep -Eq "$SECRET_FILE_RE" && ! printf '%s' "$FILE" | grep -Eq "$ALLOW_FILE_RE"; then
  block "'$FILE' is a credential/secret file."
fi

# --- 2. Bash commands that dump secret files --------------------------------
if [ -n "$CMD" ]; then
  if printf '%s' "$CMD" | grep -Eq '(cat|less|more|head|tail|type|base64|xxd|cp|scp|curl .*(-d|--data|-F|-T)) [^|;&]*(\.ssh/|\.aws/credentials|\.env([^.a-z]|$)|id_rsa|\.pem|\.netrc)'; then
    block "the command would read or send a credential file."
  fi
  if printf '%s' "$CMD" | grep -Eq '(^|[;&|[:space:]])(printenv|env)([[:space:]]*$|[[:space:]]*\|)'; then
    block "dumping the full environment can expose secrets. Print only the specific non-secret variable you need."
  fi
fi

# --- 3. Content that looks like a secret (writes only) ----------------------
case "$TOOL" in
  Edit|Write|MultiEdit|NotebookEdit|"")
    if [ -n "$PAYLOAD" ]; then
      # Each line: <label>|<ERE>. Keep patterns specific to limit false positives.
      while IFS='|' read -r label re; do
        [ -z "$label" ] && continue
        if printf '%s' "$PAYLOAD" | grep -Eq -- "$re"; then
          block "content contains what looks like a $label."
        fi
      done <<'PATTERNS'
AWS access key ID|(AKIA|ASIA)[0-9A-Z]{16}
private key block|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----
GitHub token|gh[pousr]_[A-Za-z0-9]{36,}
Slack token|xox[baprs]-[A-Za-z0-9-]{10,}
Anthropic API key|sk-ant-[A-Za-z0-9_-]{20,}
Google API key|AIza[0-9A-Za-z_-]{35}
Stripe live key|sk_live_[0-9A-Za-z]{20,}
hard-coded password|(password|passwd|pwd|secret|api[_-]?key)[\"']?[[:space:]]*[:=][[:space:]]*[\\]?[\"'][^\"'[:space:]$\{<]{8,}[\\]?[\"']
PATTERNS
    fi
    ;;
esac

exit 0
