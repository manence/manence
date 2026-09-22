#!/usr/bin/env bash
# consignes.sh — hook SessionStart (Claude Code) : compte les items d'inbox `type: instruction` en `status: deposee`
# (déposés depuis Manence UI) et le dit en tête de session. Il signale, il ne fait rien : c'est l'agent qui joue
# le skill `consignes` sur ce signal. Rapide, sans dépendance, fail-open : toute erreur = silence.
set -u
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
INBOX="$ROOT/inbox"
[ -d "$INBOX" ] || exit 0
n=0; liste=""
for f in "$INBOX"/*.md; do
  [ -f "$f" ] || continue
  head -n 30 "$f" 2>/dev/null | grep -qE '^type:[[:space:]]*instruction[[:space:]]*$' || continue
  head -n 30 "$f" 2>/dev/null | grep -qE '^status:[[:space:]]*deposee' || continue
  n=$((n+1)); liste="$liste  - $(basename "$f")"$'\n'
done
[ "$n" -gt 0 ] || exit 0
printf 'Manence UI : %d consigne(s) déposée(s) dans inbox/, à traiter en premier — lance le skill consignes.\n%s' "$n" "$liste"
exit 0
