#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# protect-paths.sh — PreToolUse hook (matcher: "Edit|Write|MultiEdit|NotebookEdit")
#
# Purpose: deterministic guardrail. Blocks edits to any path listed in
# .claude/protected-paths.txt (one glob per line, '#' comments allowed).
# Typical entries: frozen APIs, generated code, migrations, CI config, the
# hooks themselves.
#
# protected-paths.txt pattern rules (paths are relative to the project root):
#   api/v1/**        -> everything under api/v1/   ('**' and '*' both cross '/')
#   *.lock           -> any file ending in .lock at any depth
#   .github/workflows/  (trailing slash) -> directory prefix
#   CODEOWNERS       -> exact file
#
# Contract: stdin JSON event; exit 0 allow; exit 2 block with stderr reason.
# Test:
#   printf 'api/v1/**\n' > .claude/protected-paths.txt
#   echo '{"tool_input":{"file_path":"api/v1/Foo.java"}}' | bash protect-paths.sh; echo $?  # -> 2
# ---------------------------------------------------------------------------
set -u

INPUT="$(cat)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LIST_FILE="${PROTECTED_PATHS_FILE:-$PROJECT_DIR/.claude/protected-paths.txt}"

# No list -> nothing is protected by this hook.
[ -f "$LIST_FILE" ] || exit 0

# --- JSON helper (jq, else Python fallback) --------------------------------
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

# --- Target path: Edit/Write/MultiEdit use file_path; NotebookEdit uses notebook_path.
json_fields tool_input.file_path tool_input.notebook_path; rc=$?
TARGET="$F1"
if [ "$rc" -eq 3 ]; then
  echo "protect-paths: cannot parse hook input (install jq or python). Blocking to be safe." >&2
  exit 2
fi
[ -z "$TARGET" ] && TARGET="$F2"   # NotebookEdit uses notebook_path
[ -z "$TARGET" ] && exit 0

# --- Normalize to a project-relative, forward-slash path --------------------
# Converts backslashes to '/', and a Windows drive prefix "C:/x" to "/c/x", so
# CLAUDE_PROJECT_DIR and file_path compare equal whichever form each arrives in.
norm() {
  local s
  s="$(printf '%s' "$1" | tr '\\' '/')"
  case "$s" in
    [A-Za-z]:/*) s="/$(printf '%s' "${s%%:*}" | tr '[:upper:]' '[:lower:]')${s#?:}" ;;
  esac
  printf '%s' "$s"
}
T="$(norm "$TARGET")"
P="$(norm "$PROJECT_DIR")"
case "$T" in
  "$P"/*) REL="${T#"$P"/}" ;;
  *)      REL="${T#./}" ;;
esac

# --- Compare against every pattern ------------------------------------------
while IFS= read -r raw || [ -n "$raw" ]; do
  pat="$(printf '%s' "$raw" | tr -d '\r' | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -z "$pat" ] && continue
  hit=0
  case "$pat" in
    */) case "$REL" in "$pat"*) hit=1 ;; esac ;;                 # directory prefix
    *)  # bash 'case' globs: '*' already matches '/', so '**' behaves the same.
        # shellcheck disable=SC2254
        case "$REL" in $pat) hit=1 ;; esac
        # Patterns with no '/' also match the basename at any depth (like .gitignore).
        if [ "$hit" -eq 0 ] && [ "${pat#*/}" = "$pat" ]; then
          # shellcheck disable=SC2254
          case "${REL##*/}" in $pat) hit=1 ;; esac
        fi ;;
  esac
  if [ "$hit" -eq 1 ]; then
    cat >&2 <<EOF
BLOCKED by protect-paths: '$REL' matches protected pattern '$pat' in .claude/protected-paths.txt.
This path is protected (frozen API, generated code, or controlled config).
If the change is genuinely required, stop and ask the code owner; changes here go through a
human-authored PR with code-owner approval. Do not try to work around this block.
EOF
    exit 2
  fi
done < "$LIST_FILE"

exit 0
