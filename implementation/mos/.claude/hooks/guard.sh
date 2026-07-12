#!/bin/bash
# Garde-fou DUR (couche 5) : une BARRIÈRE ANTI-ERREUR, pas une frontière de sécurité.
# Il bloque les formes les plus courantes de gestes destructeurs (périmètre exact
# ci-dessous) ; il valide par expressions régulières, donc une formulation inhabituelle
# peut passer. Pour une contrainte forte, s'appuyer sur permissions.deny et le sandbox
# du runtime. Branché sur l'événement PreToolUse (matcher "Bash") dans .claude/settings.json.
# Contrairement à une règle CLAUDE.md (qui ne fait que SUGGÉRER), un hook PreToolUse
# qui renvoie permissionDecision "deny" BLOQUE réellement l'appel.
#
# Trois familles de commandes bloquées (Spec §12) :
#   1. rm récursif + forcé : options courtes (-rf/-fr/-r -f), longues (--recursive --force)
#      et séparées sur le même segment de commande
#   2. fork bomb ":(){ :|:& };:" (motif en grep -F, une regex ERE avec "()" formerait
#      un groupe capturant vide et ne matcherait jamais la vraie fork bomb)
#   3. git push --force (ou -f) et git push qui référence explicitement main/master en destination
#      (le motif tolère toutes les options globales : -C, -c, --git-dir, --work-tree…)

# FAIL-CLOSED : sans jq, ce guard ne peut pas lire la commande qu'on lui soumet.
# Il bloque alors TOUT (exit 2 = deny) au lieu de laisser tout passer en silence.
if ! command -v jq >/dev/null 2>&1; then
  echo "guard.sh: jq not found — the guardrail cannot inspect commands, so it blocks everything (fail-closed). Install jq: brew install jq (macOS) / apt install jq (Linux)." >&2
  exit 2
fi

COMMAND=$(jq -r '.tool_input.command')

REASON=""

# 1. rm récursif + forcé
if echo "$COMMAND" | grep -qE 'rm[[:space:]]+(-[A-Za-z]*r[A-Za-z]*f[A-Za-z]*|-[A-Za-z]*f[A-Za-z]*r[A-Za-z]*|-r[[:space:]]+-f|-f[[:space:]]+-r)([[:space:]]|$)'; then
  REASON="rm récursif + forcé bloqué par guard.sh"
fi

# 1bis. rm récursif + forcé en options longues ou séparées (--recursive --force, -r … -f).
# On découpe la commande par segment (; | &) et on exige récursif ET forcé sur le
# segment qui contient rm — pour ne pas bloquer « rm -r x && tail -f log ».
if [ -z "$REASON" ] && echo "$COMMAND" | tr ';|&' '\n' \
  | grep -E '(^|[[:space:]])rm[[:space:]]' \
  | grep -E -- '(^|[[:space:]])(--recursive|-[A-Za-z]*[rR][A-Za-z]*)([[:space:]]|$)' \
  | grep -qE -- '(^|[[:space:]])(--force|-[A-Za-z]*f[A-Za-z]*)([[:space:]]|$)'; then
  REASON="rm récursif + forcé bloqué par guard.sh (options longues/séparées comprises)"
fi

# 2. fork bomb, chaîne littérale (grep -F, pas d'ERE ambigu sur les parenthèses vides)
if [ -z "$REASON" ] && echo "$COMMAND" | grep -qF ':(){ :'; then
  REASON="fork bomb bloquée par guard.sh"
fi

# 3. git push destructeur : --force/-f, ou destination main/master explicite
# La détection tolère n'importe quelle option globale entre git et push (-C, -c, --git-dir…) :
# une liste fermée laissait passer « git -c x=y push --force ».
if [ -z "$REASON" ] && echo "$COMMAND" | grep -qE 'git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+push'; then
  if echo "$COMMAND" | grep -qE -- '--force|(^|[[:space:]])-f([[:space:]]|$)'; then
    REASON="git push --force bloqué par guard.sh"
  elif echo "$COMMAND" | grep -qE '(^|[^A-Za-z0-9_-])(main|master)([^A-Za-z0-9_-]|$)'; then
    REASON="push direct sur main/master bloqué par guard.sh"
  fi
fi

if [ -n "$REASON" ]; then
  jq -n --arg reason "$REASON" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
else
  exit 0  # pas de décision ; le flux de permission normal s'applique
fi
