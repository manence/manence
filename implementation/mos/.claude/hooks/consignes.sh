#!/usr/bin/env bash
# consignes.sh — SessionStart hook (Claude Code): counts the `type: instruction` items in `status: deposee`
# in consignes/ (and, during the 0.15 transition, in inbox/), and the due reminders in inbox/rappels/,
# and says so at the top of the session. It signals, it does nothing: the agent runs the `consignes` skill.
# Fast, no dependency, fail-open: any error = silence. (Spec §7 the inbox, §21 the instruction item.)
set -u
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
n=0; items=""
for f in "$ROOT"/consignes/*.md "$ROOT"/inbox/*.md; do
  [ -f "$f" ] || continue
  head -n 30 "$f" 2>/dev/null | grep -qE '^type:[[:space:]]*instruction[[:space:]]*$' || continue
  head -n 30 "$f" 2>/dev/null | grep -qE '^status:[[:space:]]*deposee' || continue
  n=$((n+1)); items="$items  - ${f#"$ROOT"/}"$'\n'
done
today=$(date +%Y-%m-%d); r=0
for f in "$ROOT"/inbox/rappels/*.md; do
  [ -f "$f" ] || continue
  d=$(head -n 30 "$f" 2>/dev/null | sed -nE 's/^rappel_le:[[:space:]]*"?([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/p' | head -n 1)
  [ -n "$d" ] || continue
  [[ "$d" > "$today" ]] || r=$((r+1))
done
[ "$n" -gt 0 ] && printf 'Manence UI: %d instruction(s) filed in consignes/, to handle first — run the consignes skill.\n%s' "$n" "$items"
[ "$r" -gt 0 ] && printf 'Inbox: %d reminder(s) due in inbox/rappels/ — the consignes skill brings them back to sort.\n' "$r"
exit 0
