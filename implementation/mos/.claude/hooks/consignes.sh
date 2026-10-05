#!/usr/bin/env bash
# consignes.sh — SessionStart hook (Claude Code): counts the inbox items `type: instruction` in `status: deposee`
# (filed from Manence UI) and says so at the top of the session. It signals, it does nothing: the agent is the one
# that runs the `consignes` skill on this signal. Fast, no dependency, fail-open: any error = silence.
set -u
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
INBOX="$ROOT/inbox"
[ -d "$INBOX" ] || exit 0
n=0; items=""
for f in "$INBOX"/*.md; do
  [ -f "$f" ] || continue
  head -n 30 "$f" 2>/dev/null | grep -qE '^type:[[:space:]]*instruction[[:space:]]*$' || continue
  head -n 30 "$f" 2>/dev/null | grep -qE '^status:[[:space:]]*deposee' || continue
  n=$((n+1)); items="$items  - $(basename "$f")"$'\n'
done
[ "$n" -gt 0 ] || exit 0
printf 'Manence UI: %d instruction(s) filed in inbox/, to handle first — run the consignes skill.\n%s' "$n" "$items"
exit 0
