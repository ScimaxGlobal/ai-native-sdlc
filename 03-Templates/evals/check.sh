#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# check.sh — evaluate one eval case against the state Claude left behind
#
# Usage: evals/check.sh <eval.json> <result.json> [WORKDIR]
#   eval.json   : the case (see evals/schema.json)
#   result.json : output of `claude -p ... --output-format json`
#   WORKDIR     : directory Claude worked in (default: current directory)
#
# Prints one PASS/FAIL line per check and exits 0 only if ALL checks pass.
# Requires python (for JSON parsing — portable across Linux/macOS/Git Bash).
#
# Check types:
#   command            run a shell command in WORKDIR; compare exit code
#   file_contains      file matches regex (grep -E)
#   file_not_contains  file does not match regex
#   file_unchanged     file identical to git HEAD (or to the index if no commit yet)
#   output_contains    Claude's final text (.result) matches regex
#   output_not_contains
#   no_error           result.json has is_error == false
# ---------------------------------------------------------------------------
set -u

EVAL_FILE="${1:?usage: check.sh <eval.json> <result.json> [WORKDIR]}"
RESULT_FILE="${2:?usage: check.sh <eval.json> <result.json> [WORKDIR]}"
WORKDIR="${3:-$(pwd)}"

# --- Locate a working Python interpreter ---------------------------------
PY=""
for c in python3 python py; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import json' >/dev/null 2>&1; then PY="$c"; break; fi
done
[ -n "$PY" ] || { echo "check.sh: python is required" >&2; exit 2; }

# --- Flatten the checks to TAB-separated lines: type, name, a, b ----------
# (a/b depend on type: command -> run, expect_exit; file_* -> path, pattern)
CHECKS="$("$PY" - "$EVAL_FILE" <<'PYEOF'
import json, sys
case = json.load(open(sys.argv[1], encoding="utf-8"))
for i, c in enumerate(case.get("checks", []), 1):
    t = c["type"]
    name = c.get("name", f"check-{i}")
    if t == "command":
        a, b = c["run"], str(c.get("expect_exit", 0))
    elif t.startswith("file_"):
        a, b = c["path"], c.get("pattern", "")
    else:
        a, b = c.get("pattern", ""), ""
    # Tabs/newlines inside values would break the TSV; replace defensively.
    clean = lambda s: str(s).replace("\t", " ").replace("\n", " ")
    print("\t".join([t, clean(name), clean(a), clean(b)]))
PYEOF
)" || { echo "check.sh: cannot parse $EVAL_FILE" >&2; exit 2; }
# Windows Python emits CRLF; strip CR so patterns and exit codes compare cleanly.
CHECKS="$(printf '%s' "$CHECKS" | tr -d '\r')"

# --- Extract fields from Claude's JSON result ------------------------------
result_field() {
  "$PY" - "$RESULT_FILE" "$1" <<'PYEOF'
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    d = {}
# --output-format json yields one object; tolerate a list of events too.
if isinstance(d, list):
    d = next((e for e in reversed(d) if isinstance(e, dict) and e.get("type") == "result"), {})
v = d.get(sys.argv[2], "")
sys.stdout.write(json.dumps(v) if isinstance(v, bool) else str(v))
PYEOF
}
RESULT_TEXT="$(result_field result | tr -d '\r')"
IS_ERROR="$(result_field is_error | tr -d '\r')"

pass=0; fail=0
report() {  # $1=PASS|FAIL $2=type $3=name $4=detail
  printf '%-4s  %-20s %s%s\n' "$1" "$2" "$3" "${4:+  ($4)}"
  if [ "$1" = PASS ]; then pass=$((pass+1)); else fail=$((fail+1)); fi
}

# --- Run each check ---------------------------------------------------------
while IFS=$'\t' read -r type name a b; do
  [ -z "$type" ] && continue
  case "$type" in
    command)
      ( cd "$WORKDIR" && bash -c "$a" ) >/dev/null 2>&1; rc=$?
      if [ "$rc" -eq "$b" ]; then report PASS "$type" "$name"; else report FAIL "$type" "$name" "exit $rc, expected $b"; fi ;;
    file_contains)
      if grep -Eq -- "$b" "$WORKDIR/$a" 2>/dev/null; then report PASS "$type" "$name"; else report FAIL "$type" "$name" "$a !~ /$b/"; fi ;;
    file_not_contains)
      if [ -f "$WORKDIR/$a" ] && ! grep -Eq -- "$b" "$WORKDIR/$a"; then report PASS "$type" "$name"
      elif [ ! -f "$WORKDIR/$a" ]; then report FAIL "$type" "$name" "$a missing"
      else report FAIL "$type" "$name" "$a matches /$b/"; fi ;;
    file_unchanged)
      # Compare with HEAD; in a repo with no commit yet, compare with the index.
      if git -C "$WORKDIR" rev-parse --verify -q HEAD >/dev/null 2>&1; then ref="HEAD"; else ref=""; fi
      # shellcheck disable=SC2086  # empty $ref must vanish
      if git -C "$WORKDIR" diff --quiet $ref -- "$a" 2>/dev/null; then report PASS "$type" "$name"; else report FAIL "$type" "$name" "$a differs from ${ref:-index}"; fi ;;
    output_contains)
      if printf '%s' "$RESULT_TEXT" | grep -Eiq -- "$a"; then report PASS "$type" "$name"; else report FAIL "$type" "$name" "final output !~ /$a/"; fi ;;
    output_not_contains)
      if printf '%s' "$RESULT_TEXT" | grep -Eiq -- "$a"; then report FAIL "$type" "$name" "final output matches /$a/"; else report PASS "$type" "$name"; fi ;;
    no_error)
      if [ "$IS_ERROR" = "false" ]; then report PASS "$type" "$name"; else report FAIL "$type" "$name" "is_error=$IS_ERROR"; fi ;;
    *)
      report FAIL "$type" "$name" "unknown check type" ;;
  esac
done <<< "$CHECKS"

echo "checks: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
