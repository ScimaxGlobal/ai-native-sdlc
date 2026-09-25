#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# check-endpoints.sh — heuristic endpoint inventory for the secure-api-review skill
#
# Usage:  bash check-endpoints.sh [SOURCE_DIR]        (default: current dir)
#
# What it does:
#   1. Finds route declarations in common frameworks:
#        Python  : FastAPI/Flask  @app.get(...)  @router.post(...)  @bp.route(...)
#        JS/TS   : Express/Koa    app.get('/x', ...)  router.post('/x', ...)
#        Java    : Spring         @GetMapping @PostMapping @RequestMapping ...
#   2. For each route, searches its own region for an auth marker
#      (configurable via AUTH_PATTERN): the decorator stack directly above it,
#      the route line itself, and up to WINDOW lines below, stopping at the
#      next route so a neighbor's auth never counts.
#   3. Prints one line per endpoint: OK / MISSING-AUTH? / EXEMPT (health).
#
# Exit codes: 0 = no suspicious endpoints, 1 = at least one MISSING-AUTH?,
#             2 = usage error.
#
# This is a HEURISTIC to point a reviewer at code; it is not a security proof.
# Tune AUTH_PATTERN to your codebase's real auth decorator/middleware names.
# ---------------------------------------------------------------------------
set -u

SRC_DIR="${1:-.}"
if [ ! -d "$SRC_DIR" ]; then
  echo "usage: $0 [SOURCE_DIR]  (directory not found: $SRC_DIR)" >&2
  exit 2
fi

# Defaults are single-quoted so the regex characters (quotes, parens, pipes)
# reach grep untouched; each can be overridden from the environment.

# Regex (ERE) that identifies a route declaration line.
DEFAULT_ROUTE='(@(app|router|bp|api|blueprint)\.(get|post|put|patch|delete|route)\(|(^|[^A-Za-z_.])(app|router)\.(get|post|put|patch|delete)\([[:space:]]*["'"'"'`]|@(Get|Post|Put|Patch|Delete|Request)Mapping)'
ROUTE_PATTERN="${ROUTE_PATTERN:-$DEFAULT_ROUTE}"

# Regex (ERE, case-insensitive) that indicates auth is applied near the route.
DEFAULT_AUTH='(require_jwt|jwt_required|Depends\((get_current_user|verify_jwt|require_auth)|login_required|requireAuth|authenticate|passport\.authenticate|@PreAuthorize|@Secured|@RolesAllowed|gateway_jwt)'
AUTH_PATTERN="${AUTH_PATTERN:-$DEFAULT_AUTH}"

# Paths exempt from the auth rule (policy: only /health).
DEFAULT_EXEMPT='["'"'"'`]/health["'"'"'`]'
EXEMPT_PATTERN="${EXEMPT_PATTERN:-$DEFAULT_EXEMPT}"

# Max lines BELOW the route line to search (handler signature / middleware list).
# The search also stops at the next route, so one handler's auth never
# "covers" its neighbor.
WINDOW="${WINDOW:-6}"

total=0
missing=0

echo "secure-api-review endpoint check — source: $SRC_DIR"
echo "--------------------------------------------------------------"

# Find candidate source files, skipping dependency/build/test directories.
while IFS= read -r file; do
  # All route line numbers in this file (needed to bound each search region).
  # (while-read instead of mapfile keeps this working on macOS bash 3.2)
  routes=()
  while IFS= read -r n; do routes+=("$n"); done < <(grep -n -E "$ROUTE_PATTERN" "$file" 2>/dev/null | cut -d: -f1)
  [ "${#routes[@]}" -eq 0 ] && continue

  for idx in "${!routes[@]}"; do
    lineno="${routes[$idx]}"
    total=$((total + 1))
    route_line=$(sed -n "${lineno}p" "$file" | sed 's/^[[:space:]]*//')

    # Region ABOVE: only the contiguous stack of decorators/annotations ('@...')
    # directly above the route line (e.g. @login_required, @PreAuthorize).
    start=$lineno
    while [ "$start" -gt 1 ]; do
      prev=$(sed -n "$((start - 1))p" "$file")
      printf '%s' "$prev" | grep -Eq '^[[:space:]]*@' || break
      printf '%s' "$prev" | grep -Eq "$ROUTE_PATTERN" && break
      start=$((start - 1))
    done

    # Region BELOW: up to WINDOW lines, stopping before the next route.
    end=$((lineno + WINDOW))
    next="${routes[$((idx + 1))]:-}"
    if [ -n "$next" ] && [ "$end" -ge "$next" ]; then end=$((next - 1)); fi

    window_text=$(sed -n "${start},${end}p" "$file")

    if printf '%s' "$route_line" | grep -Eq "$EXEMPT_PATTERN"; then
      status="EXEMPT"
    elif printf '%s' "$window_text" | grep -Eiq "$AUTH_PATTERN"; then
      status="OK"
    else
      status="MISSING-AUTH?"
      missing=$((missing + 1))
    fi

    printf '%-14s %s:%s  %s\n' "$status" "${file#"$SRC_DIR"/}" "$lineno" "$route_line"
  done
done < <(find "$SRC_DIR" -type f \( -name '*.py' -o -name '*.ts' -o -name '*.js' -o -name '*.java' -o -name '*.kt' \) \
           -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/build/*' \
           -not -path '*/dist/*' -not -path '*/venv/*' -not -path '*/.venv/*' \
           -not -path '*/test*/*' 2>/dev/null | sort)

echo "--------------------------------------------------------------"
echo "endpoints: $total   suspicious (MISSING-AUTH?): $missing"

# Non-zero exit lets CI or a hook treat suspicious endpoints as a failure.
[ "$missing" -eq 0 ] || exit 1
exit 0
