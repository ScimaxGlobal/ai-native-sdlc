#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# protect-tests.sh — PreToolUse hook (matcher: "Edit|Write|MultiEdit|NotebookEdit")
#
# Purpose: protect the feedback loop during a bug fix. The workflow is:
#   1. Write a failing test that reproduces the bug (test-writer subagent or human).
#   2. Turn on fix mode:   export FIX_MODE=1   or   touch .claude/fix-mode
#   3. Let Claude fix the CODE. Any attempt to edit a TEST file is blocked, so
#      the only way to go green is to make the code satisfy the test.
#   4. Turn fix mode off:  unset FIX_MODE / rm .claude/fix-mode
#
# Test-file detection (override with TEST_PATH_PATTERN, an ERE):
#   tests/ test/ __tests__/ spec/ src/test/ src/integrationTest/ directories,
#   test_*.py, *_test.py, *_test.go, *.test.ts(x)/js(x), *.spec.ts(x)/js(x),
#   *Test.java, *Tests.java, *IT.java, *Test.kt
#
# Contract: stdin JSON; exit 0 allow; exit 2 block (stderr = reason to Claude).
# Test:
#   echo '{"tool_input":{"file_path":"tests/test_status.py"}}' | FIX_MODE=1 bash protect-tests.sh; echo $?  # -> 2
# ---------------------------------------------------------------------------
set -u

INPUT="$(cat)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# --- 1. Is fix mode on? If not, this hook does nothing. --------------------
if [ "${FIX_MODE:-0}" != "1" ] && [ ! -e "$PROJECT_DIR/.claude/fix-mode" ]; then
  exit 0
fi

# --- 2. JSON helper (jq, else Python) --------------------------------------
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

json_fields tool_input.file_path tool_input.notebook_path; rc=$?
TARGET="$F1"
if [ "$rc" -eq 3 ]; then
  echo "protect-tests: fix mode is on but hook input cannot be parsed (install jq or python). Blocking." >&2
  exit 2
fi
[ -z "$TARGET" ] && TARGET="$F2"   # NotebookEdit uses notebook_path
[ -z "$TARGET" ] && exit 0

# Normalize Windows separators so one regex works everywhere.
T="$(printf '%s' "$TARGET" | tr '\\' '/')"

# --- 3. Is the target a test file? -----------------------------------------
TEST_RE="${TEST_PATH_PATTERN:-(^|/)(tests?|__tests__|spec|src/test|src/integrationTest)/|(^|/)test_[^/]*\.py$|_test\.(py|go)$|\.(test|spec)\.[jt]sx?$|(Test|Tests|IT)\.(java|kt)$}"

if printf '%s' "$T" | grep -Eq "$TEST_RE"; then
  cat >&2 <<EOF
BLOCKED by protect-tests: fix mode is ON, and '$TARGET' is a test file.
During a fix, the failing test is the specification. Change the production code until the
test passes. If you believe the test itself is wrong, STOP and explain why to the engineer;
they can turn off fix mode (unset FIX_MODE / remove .claude/fix-mode) and edit it themselves.
EOF
  exit 2
fi

exit 0
