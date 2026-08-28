#!/bin/bash
# HARD guardrail (layer 5): an ANTI-MISTAKE BARRIER, not a security boundary.
# It blocks the most common shapes of destructive commands (exact scope below);
# it matches with regular expressions, so an unusual phrasing can get through.
# For a strong constraint, lean on permissions.deny and the runtime's sandbox.
# Wired to the PreToolUse event (matcher "Bash") in .claude/settings.json.
# Unlike a rule in AGENTS.md (which only SUGGESTS), a PreToolUse hook that
# returns permissionDecision "deny" actually BLOCKS the call.
#
# Three families of blocked commands (Spec §12):
#   1. recursive + forced rm: short options (-rf/-fr/-r -f), long options
#      (--recursive --force), and split options on the same command segment
#   2. fork bomb ":(){ :|:& };:" (matched with grep -F: an ERE with "()" would
#      form an empty capture group and never match the real fork bomb)
#   3. git push --force (or -f), and git push that explicitly names main/master
#      as the destination (the pattern tolerates any global option: -C, -c,
#      --git-dir, --work-tree…)
#
# NOTE: the guard reads the WHOLE command, quoted text included — a heredoc or
# a commit message that QUOTES a forbidden command is blocked as if it were the
# command. This is deliberate (a rare false positive beats a real negative):
# write texts that mention forbidden commands through the file-editing tools,
# not the shell — or paraphrase.
#
# MULTI-HARNESS (0.7): the stdin payload varies — Claude Code and Codex send
# snake_case (.tool_input), Grok Build sends camelCase (.toolInput). The guard
# reads both and answers in the caller's dialect.

# FAIL-CLOSED: without jq, this guard cannot read the command submitted to it.
# It then blocks EVERYTHING (exit 2 = deny) instead of silently letting all through.
if ! command -v jq >/dev/null 2>&1; then
  echo "guard.sh: jq not found — the guardrail cannot inspect commands, so it blocks everything (fail-closed). Install jq: brew install jq (macOS) / apt install jq (Linux) / winget install jqlang.jq (Windows)." >&2
  exit 2
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .toolInput.command // empty')
if echo "$INPUT" | jq -e 'has("tool_input") or has("tool_name")' >/dev/null 2>&1; then
  DIALECT="claude"
else
  DIALECT="grok"
fi

REASON=""

# 1. recursive + forced rm
if echo "$COMMAND" | grep -qE 'rm[[:space:]]+(-[A-Za-z]*r[A-Za-z]*f[A-Za-z]*|-[A-Za-z]*f[A-Za-z]*r[A-Za-z]*|-r[[:space:]]+-f|-f[[:space:]]+-r)([[:space:]]|$)'; then
  REASON="recursive forced rm blocked by guard.sh"
fi

# 1bis. recursive + forced rm with long or split options (--recursive --force, -r … -f).
# Split the command into segments (; | &) and require recursive AND forced on the
# segment that carries rm — so that "rm -r x && tail -f log" is not blocked.
if [ -z "$REASON" ] && echo "$COMMAND" | tr ';|&' '\n' \
  | grep -E '(^|[[:space:]])rm[[:space:]]' \
  | grep -E -- '(^|[[:space:]])(--recursive|-[A-Za-z]*[rR][A-Za-z]*)([[:space:]]|$)' \
  | grep -qE -- '(^|[[:space:]])(--force|-[A-Za-z]*f[A-Za-z]*)([[:space:]]|$)'; then
  REASON="recursive forced rm blocked by guard.sh (long/split options included)"
fi

# 2. fork bomb, literal string (grep -F: no ambiguous ERE on empty parentheses)
if [ -z "$REASON" ] && echo "$COMMAND" | grep -qF ':(){ :'; then
  REASON="fork bomb blocked by guard.sh"
fi

# 3. destructive git push: --force/-f, or an explicit main/master destination.
# The pattern tolerates any global option between git and push (-C, -c, --git-dir…):
# a closed list used to let "git -c x=y push --force" through.
if [ -z "$REASON" ] && echo "$COMMAND" | grep -qE 'git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+push'; then
  if echo "$COMMAND" | grep -qE -- '--force|(^|[[:space:]])-f([[:space:]]|$)'; then
    REASON="git push --force blocked by guard.sh"
  elif echo "$COMMAND" | grep -qE '(^|[^A-Za-z0-9_-])(main|master)([^A-Za-z0-9_-]|$)'; then
    REASON="direct push to main/master blocked by guard.sh"
  fi
fi

if [ -n "$REASON" ]; then
  if [ "$DIALECT" = "grok" ]; then
    jq -n --arg reason "$REASON" '{ decision: "deny", reason: $reason }'
  else
    jq -n --arg reason "$REASON" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
  fi
else
  exit 0  # no decision; the normal permission flow applies
fi
