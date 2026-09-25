#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# post-edit-format.sh — PostToolUse hook (matcher: "Edit|Write|MultiEdit")
#
# Purpose: after Claude edits a file, run the project formatter on THAT FILE
# ONLY (fast, scoped). Formatting is a mechanical fix, so this hook never
# blocks: it always exits 0. If a formatter is not installed, it is skipped.
#
# Customize the case table below for your stack. Keep each command scoped to
# "$FILE" — whole-repo formatting inside a hook slows every edit.
#
# Test:
#   echo '{"tool_input":{"file_path":"x.py"}}' | bash post-edit-format.sh; echo $?  # -> 0
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

json_fields tool_input.file_path || exit 0   # formatting is best-effort: never block
FILE="$F1"
[ -z "$FILE" ] && exit 0
[ -f "$FILE" ] || exit 0     # deleted or not yet on disk -> nothing to format

# Run a formatter only if its executable exists; report but never fail.
run_if() {
  local tool="$1"; shift
  if command -v "$tool" >/dev/null 2>&1; then
    if ! "$tool" "$@" >/dev/null 2>&1; then
      echo "post-edit-format: $tool reported a problem on $FILE (not blocking)" >&2
    fi
  fi
}

# --- Formatter per file type ------------------------------------------------
case "$FILE" in
  *.py)                          run_if ruff format --quiet "$FILE" || true
                                 command -v ruff >/dev/null 2>&1 || run_if black -q "$FILE" ;;
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.md|*.yml|*.yaml)
                                 run_if npx --no-install prettier --write "$FILE" ;;
  *.go)                          run_if gofmt -w "$FILE" ;;
  *.rs)                          run_if rustfmt "$FILE" ;;
  *.java)                        run_if google-java-format -i "$FILE" ;;
  *.kt)                          run_if ktlint -F "$FILE" ;;
  *.sh)                          run_if shfmt -w "$FILE" ;;
  *.tf)                          run_if terraform fmt "$FILE" ;;
  *) : ;;                        # unknown type: leave untouched
esac

exit 0
