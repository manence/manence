#!/bin/bash
# Garde-fou DUR (couche 5) : bloque les commandes destructrices avant exécution.
# Branché sur l'événement PreToolUse (matcher "Bash") dans .claude/settings.json.
# Contrairement à une règle CLAUDE.md (qui ne fait que SUGGÉRER), un hook PreToolUse
# qui renvoie permissionDecision "deny" BLOQUE réellement l'appel.
#
# Trois familles de commandes bloquées (Spec §12) :
#   1. rm récursif + forcé, toutes combinaisons -rf/-fr/-r -f/-f -r (espaces multiples tolérés)
#   2. fork bomb ":(){ :|:& };:" (motif en grep -F, une regex ERE avec "()" formerait
#      un groupe capturant vide et ne matcherait jamais la vraie fork bomb)
#   3. git push --force (ou -f) et git push qui référence explicitement main/master en destination
#      (y compris git -C <dir> / --git-dir / --work-tree : le motif tolère les options globales)

COMMAND=$(jq -r '.tool_input.command')

REASON=""

# 1. rm récursif + forcé
if echo "$COMMAND" | grep -qE 'rm[[:space:]]+(-[A-Za-z]*r[A-Za-z]*f[A-Za-z]*|-[A-Za-z]*f[A-Za-z]*r[A-Za-z]*|-r[[:space:]]+-f|-f[[:space:]]+-r)([[:space:]]|$)'; then
  REASON="rm récursif + forcé bloqué par guard.sh"
fi

# 2. fork bomb, chaîne littérale (grep -F, pas d'ERE ambigu sur les parenthèses vides)
if [ -z "$REASON" ] && echo "$COMMAND" | grep -qF ':(){ :'; then
  REASON="fork bomb bloquée par guard.sh"
fi

# 3. git push destructeur : --force/-f, ou destination main/master explicite
if [ -z "$REASON" ] && echo "$COMMAND" | grep -qE 'git([[:space:]]+(-C|--git-dir|--work-tree)([=[:space:]][^[:space:]]+)?)*[[:space:]]+push'; then
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
