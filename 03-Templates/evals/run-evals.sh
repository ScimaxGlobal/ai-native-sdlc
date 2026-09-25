#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run-evals.sh — run every eval case, write results, print the pass rate
#
# Usage: evals/run-evals.sh [EVAL_DIR]            (default: evals)
#
# Environment:
#   THRESHOLD        minimum pass rate in percent to exit 0   (default 90)
#   RESULTS_DIR      where per-case results go                (default evals/results)
#   CLAUDE_BIN       Claude Code CLI to invoke                (default claude)
#   EVAL_ISOLATION   worktree | none                          (default worktree)
#                    worktree = each case runs in a fresh `git worktree` at HEAD,
#                    so cases cannot contaminate each other or your checkout.
#   EVAL_FILTER      only run cases whose id matches this regex
#
# Output:
#   $RESULTS_DIR/<id>.result.json   raw claude -p JSON output
#   $RESULTS_DIR/<id>.check.txt     check.sh report
#   $RESULTS_DIR/summary.json       {"total","passed","failed","pass_rate","threshold","cases":[...]}
#   stdout: one line per case and the final pass rate
# Exit: 0 if pass_rate >= THRESHOLD, 1 otherwise, 2 on setup error.
# ---------------------------------------------------------------------------
set -u

EVAL_DIR="${1:-evals}"
THRESHOLD="${THRESHOLD:-90}"
RESULTS_DIR="${RESULTS_DIR:-$EVAL_DIR/results}"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
EVAL_ISOLATION="${EVAL_ISOLATION:-worktree}"
EVAL_FILTER="${EVAL_FILTER:-.}"

ROOT="$(pwd)"
CHECK="$ROOT/$EVAL_DIR/check.sh"
mkdir -p "$RESULTS_DIR"
RESULTS_ABS="$(cd "$RESULTS_DIR" && pwd)"

# --- Python for JSON (reading case fields, writing the summary) ------------
PY=""
for c in python3 python py; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import json' >/dev/null 2>&1; then PY="$c"; break; fi
done
[ -n "$PY" ] || { echo "run-evals: python is required" >&2; exit 2; }
command -v "$CLAUDE_BIN" >/dev/null 2>&1 || [ -x "$CLAUDE_BIN" ] || { echo "run-evals: '$CLAUDE_BIN' not found (npm i -g @anthropic-ai/claude-code)" >&2; exit 2; }

# field <file> <key> [default] -> prints the value (setup list joined by newlines)
field_py() {
  "$PY" - "$1" "$2" "${3:-}" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
v = d.get(sys.argv[2], sys.argv[3])
sys.stdout.write("\n".join(v) if isinstance(v, list) else str(v))
PYEOF
}
# Normalize Windows Python's CRLF output; keep field_py's exit status.
field() {
  local out rc
  out="$(field_py "$@")"; rc=$?
  printf '%s' "$out" | tr -d '\r'
  return $rc
}

total=0; passed=0
CASES_TSV="$RESULTS_ABS/.cases.tsv"; : > "$CASES_TSV"

for case_file in "$EVAL_DIR"/*.json; do
  base="$(basename "$case_file")"
  [ "$base" = "schema.json" ] && continue
  id="$(field "$case_file" id)" || { echo "SKIP  $base (unreadable)"; continue; }
  printf '%s' "$id" | grep -Eq -- "$EVAL_FILTER" || continue
  total=$((total + 1))

  prompt="$(field "$case_file" prompt)"
  tools="$(field "$case_file" allowed_tools 'Read,Edit,Bash(make test)')"
  max_turns="$(field "$case_file" max_turns 30)"
  timeout_s="$(field "$case_file" timeout_seconds 900)"
  setup="$(field "$case_file" setup '')"
  case_abs="$(cd "$(dirname "$case_file")" && pwd)/$base"

  # --- 1. Isolated working copy -------------------------------------------
  # A worktree needs a commit to check out; without one, fall back to running in place.
  if [ "$EVAL_ISOLATION" = "worktree" ] && ! git rev-parse --verify -q HEAD >/dev/null 2>&1; then
    echo "WARN  no git commit found; running cases in the current checkout (EVAL_ISOLATION=none)" >&2
    EVAL_ISOLATION=none
  fi
  if [ "$EVAL_ISOLATION" = "worktree" ]; then
    WT="$(mktemp -d)/wt"
    git worktree add --detach --quiet "$WT" HEAD || { echo "run-evals: git worktree failed" >&2; exit 2; }
  else
    WT="$ROOT"
  fi

  # --- 2. Setup commands (e.g. introduce the bug, enable fix mode) --------
  if [ -n "$setup" ]; then
    ( cd "$WT" && mkdir -p .claude && bash -c "$setup" ) >/dev/null 2>&1 || echo "WARN  $id: setup returned non-zero"
  fi

  # --- 3. Run Claude non-interactively ------------------------------------
  # `timeout` (coreutils) bounds a runaway session; skipped if absent (e.g. stock macOS).
  if command -v timeout >/dev/null 2>&1; then TIMEOUT_CMD="timeout $timeout_s"; else TIMEOUT_CMD=""; fi
  started=$(date +%s)
  # shellcheck disable=SC2086  # TIMEOUT_CMD is intentionally word-split
  ( cd "$WT" && $TIMEOUT_CMD "$CLAUDE_BIN" -p "$prompt" \
        --allowedTools "$tools" \
        --max-turns "$max_turns" \
        --output-format json ) > "$RESULTS_ABS/$id.result.json" 2> "$RESULTS_ABS/$id.stderr.txt"
  claude_rc=$?
  duration=$(( $(date +%s) - started ))

  # --- 4. Check the outcome ------------------------------------------------
  if bash "$CHECK" "$case_abs" "$RESULTS_ABS/$id.result.json" "$WT" > "$RESULTS_ABS/$id.check.txt" 2>&1; then
    status=pass; passed=$((passed + 1))
  else
    status=fail
  fi
  printf '%-4s  %-45s %4ss  (claude exit %s)\n' "$(echo $status | tr a-z A-Z)" "$id" "$duration" "$claude_rc"
  printf '%s\t%s\t%s\t%s\n' "$id" "$status" "$duration" "$claude_rc" >> "$CASES_TSV"

  # --- 5. Clean up the worktree --------------------------------------------
  if [ "$WT" != "$ROOT" ]; then git worktree remove --force "$WT" >/dev/null 2>&1; fi
done

[ "$total" -gt 0 ] || { echo "run-evals: no eval cases found in $EVAL_DIR" >&2; exit 2; }

# --- 6. Summary --------------------------------------------------------------
"$PY" - "$CASES_TSV" "$RESULTS_ABS/summary.json" "$THRESHOLD" <<'PYEOF'
import json, sys, datetime
rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1], encoding="utf-8") if l.strip()]
cases = [{"id": r[0], "status": r[1], "duration_s": int(r[2]), "claude_exit": int(r[3])} for r in rows]
passed = sum(c["status"] == "pass" for c in cases)
summary = {
    "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
    "total": len(cases), "passed": passed, "failed": len(cases) - passed,
    "pass_rate": round(100.0 * passed / len(cases), 1) if cases else 0.0,
    "threshold": float(sys.argv[3]), "cases": cases,
}
json.dump(summary, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
PYEOF
rm -f "$CASES_TSV"

rate="$("$PY" -c "import json,sys;print(json.load(open(sys.argv[1]))['pass_rate'])" "$RESULTS_ABS/summary.json" | tr -d '\r')"
echo "----------------------------------------------------------------"
echo "pass rate: ${rate}%  (${passed}/${total})  threshold: ${THRESHOLD}%"

# Exit non-zero below threshold so CI can gate the config change.
"$PY" -c "import sys; sys.exit(0 if float(sys.argv[1]) >= float(sys.argv[2]) else 1)" "$rate" "$THRESHOLD"
