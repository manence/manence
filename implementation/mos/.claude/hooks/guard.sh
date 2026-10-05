#!/bin/bash
# HARD guardrail (layer 5): an ANTI-MISTAKE BARRIER, not a security boundary.
# It blocks the most common shapes of destructive commands (exact scope below);
# it matches with regular expressions, so an unusual phrasing can get through.
# For a strong constraint, lean on permissions.deny and the runtime's sandbox.
# Wired to the PreToolUse event in .claude/settings.json: matcher "Bash" for the
# commands, matcher "Edit|Write|MultiEdit|NotebookEdit" for the file tools.
# Unlike a rule in AGENTS.md (which only SUGGESTS), a PreToolUse hook that
# returns permissionDecision "deny" actually BLOCKS the call.
#
# Four families of refusals (Spec §12):
#   1. recursive + forced rm: short options (-rf/-fr/-r -f), long options
#      (--recursive --force), and split options on the same command segment
#   2. fork bomb ":(){ :|:& };:" (matched with grep -F: an ERE with "()" would
#      form an empty capture group and never match the real fork bomb)
#   3. git push --force (or -f), and git push that explicitly names main/master
#      as the destination (the pattern tolerates any global option: -C, -c,
#      --git-dir, --work-tree…)
#   4. the guardrail's own files (0.12): no file tool writes to
#      <project>/.claude/hooks/, .claude/settings.json or .claude/settings.local.json,
#      and no shell segment writes there either (a redirection, sed/perl -i, tee,
#      truncate, rm/trash/unlink, ln, or cp/mv/install/rsync whose last argument
#      is one of them). Reading them, and running them, stays free. These files
#      change through upgrade.sh (run by the user or by the agent as a script) or
#      by the user's hand: a guardrail the agent can rewrite protects nothing.
#      permissions.deny carries the same rule for Claude Code (Edit(...) rules);
#      this hook is the second layer and the one other harnesses read.
#
# NOTE on scope: rules 1 and 2 read the WHOLE command, quoted text included — a
# heredoc that quotes `rm -rf` is blocked as if it were the command (deliberate:
# a rare false positive beats a real negative; write such texts through the
# file-editing tools, or paraphrase). Rules 1bis, 3 and 4 read the command by
# SEGMENT (split on ; | & and newlines, backslash-newline continuations joined
# first), and rules 3 and 4 only look at segments that BEGIN with the command
# they check: a branch name in a commit message, a `--base main` on a chained
# `gh pr create`, or a note that mentions a push no longer block the push next to
# them (three false positives in ten days, lived on 2026-09-15/22/23; fix and
# test suite from the Déclic installation, 2026-09-26). The price: a command
# hidden inside `$(…)` or behind a prefix the anchor does not know gets through —
# this is an anti-mistake barrier, see above. Run test-guard.sh after any change.
#
# TRACE (0.12): every refusal appends one line to a file outside git,
# .claude/guard-refusals.log (gitignored), so that the weekly review can say
# when the guardrail last refused something: ISO date, dialect/tool, rule,
# the command or path cut at 200 characters, tab-separated. MANENCE_GUARD_LOG
# overrides the path (test-guard.sh points it elsewhere). The trace never asks
# anything and never blocks: a file it cannot write is skipped in silence.
#
# MULTI-HARNESS (0.7): the stdin payload varies — Claude Code and Codex send
# snake_case (.tool_name/.tool_input), Grok Build sends camelCase
# (.toolName/.toolInput) with its native tool names. The guard reads both and
# answers in the caller's dialect.

# FAIL-CLOSED: without jq, this guard cannot read the command submitted to it.
# It then blocks EVERYTHING (exit 2 = deny) instead of silently letting all through.
if ! command -v jq >/dev/null 2>&1; then
  echo "guard.sh: jq not found — the guardrail cannot inspect commands, so it blocks everything (fail-closed). Install jq: brew install jq (macOS) / apt install jq (Linux) / winget install jqlang.jq (Windows)." >&2
  exit 2
fi

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // .toolName // empty' 2>/dev/null)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .toolInput.command // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
if echo "$INPUT" | jq -e 'has("tool_input") or has("tool_name")' >/dev/null 2>&1; then
  DIALECT="claude"
else
  DIALECT="grok"
fi
[ -n "$CWD" ] || CWD=$PWD
PROJ="${CLAUDE_PROJECT_DIR:-$CWD}"
PROJ_REAL=$(cd "$PROJ" 2>/dev/null && pwd -P) || PROJ_REAL=$PROJ

REASON=""; RULE=""; SUBJECT=""

# One line per refusal, outside git; never fails the hook.
trace_refusal() {
  local log="${MANENCE_GUARD_LOG:-$PROJ/.claude/guard-refusals.log}" text
  text=$(printf '%s' "$SUBJECT" | tr '\t\r\n' '   ' | cut -c1-200)
  { printf '%s\t%s/%s\t%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)" \
      "$DIALECT" "${TOOL:-?}" "$RULE" "$text" >> "$log"; } 2>/dev/null || true
}

deny() {
  trace_refusal
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
  exit 0
}

GUARD_FILES_REASON="the guardrail's own files (.claude/hooks/, .claude/settings*.json) are not written by the agent (guard.sh rule 4): they change through upgrade.sh or by the user's hand"

# Is this path (absolute, or relative to the call's cwd) one of the guardrail's files?
is_guard_file() {
  local p="$1" abs dir real
  [ -n "$p" ] || return 1
  case "$p" in /*) abs=$p ;; *) abs="$CWD/$p" ;; esac
  dir=$(dirname -- "$abs")
  real=$(cd "$dir" 2>/dev/null && pwd -P) || real=$dir
  case "$real/$(basename -- "$abs")" in
    "$PROJ_REAL"/.claude/hooks/*|"$PROJ_REAL"/.claude/hooks) return 0 ;;
    "$PROJ_REAL"/.claude/settings.json|"$PROJ_REAL"/.claude/settings.local.json) return 0 ;;
  esac
  return 1
}

# --- File tools (Edit, Write, MultiEdit, NotebookEdit; Grok's native names;
# Codex apply_patch, whose patch text names its files) ------------------------
case "$TOOL" in
  Bash|run_terminal_command|"") : ;;
  *)
    PATHS=$(echo "$INPUT" | jq -r '
      (.tool_input // .toolInput // {}) as $in
      | ([$in.file_path, $in.notebook_path, $in.filePath, $in.path] | map(select(type == "string"))[]),
        ([$in | .. | strings] | map(split("\n")[] | select(test("^\\*\\*\\* (Add|Update|Delete) File: ")) | sub("^\\*\\*\\* (Add|Update|Delete) File: "; ""))[])
    ' 2>/dev/null)
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      if is_guard_file "$p"; then
        REASON=$GUARD_FILES_REASON; RULE="guard-files"; SUBJECT=$p
        deny
      fi
    done <<< "$PATHS"
    exit 0
    ;;
esac

# --- Shell commands ---------------------------------------------------------
SUBJECT=$COMMAND
JOINED="${COMMAND//\\$'\n'/ }"
SEGMENTS=$(printf '%s\n' "$JOINED" | tr ';|&' '\n')
# What may precede the command at the start of a segment: sudo/command/exec/
# time/nohup, a shell keyword, a VAR=value prefix, an opening parenthesis/brace.
PREFIX='^[[:space:]({]*((sudo|command|exec|time|nohup|if|elif|while|until|do|then|else|!)[[:space:]]+|[A-Za-z_][A-Za-z0-9_]*=("[^"]*"|'\''[^'\'']*'\''|[^[:space:]]*)[[:space:]]+)*'

# 1. recursive + forced rm
if echo "$COMMAND" | grep -qE 'rm[[:space:]]+(-[A-Za-z]*r[A-Za-z]*f[A-Za-z]*|-[A-Za-z]*f[A-Za-z]*r[A-Za-z]*|-r[[:space:]]+-f|-f[[:space:]]+-r)([[:space:]]|$)'; then
  REASON="recursive forced rm blocked by guard.sh"; RULE="rm-rf"
fi

# 1bis. recursive + forced rm with long or split options (--recursive --force, -r … -f).
# Split the command into segments (; | &) and require recursive AND forced on the
# segment that carries rm — so that "rm -r x && tail -f log" is not blocked.
if [ -z "$REASON" ] && echo "$SEGMENTS" \
  | grep -E '(^|[[:space:]])rm[[:space:]]' \
  | grep -E -- '(^|[[:space:]])(--recursive|-[A-Za-z]*[rR][A-Za-z]*)([[:space:]]|$)' \
  | grep -qE -- '(^|[[:space:]])(--force|-[A-Za-z]*f[A-Za-z]*)([[:space:]]|$)'; then
  REASON="recursive forced rm blocked by guard.sh (long/split options included)"; RULE="rm-rf"
fi

# 2. fork bomb, literal string (grep -F: no ambiguous ERE on empty parentheses)
if [ -z "$REASON" ] && echo "$COMMAND" | grep -qF ':(){ :'; then
  REASON="fork bomb blocked by guard.sh"; RULE="fork-bomb"
fi

# 3. destructive git push: --force/-f, or an explicit main/master destination.
# Examined by SEGMENT, and only on segments that begin with the git command: the
# two checks used to read the whole line, and the branch name in a commit message
# or the word in a note blocked a harmless push next to them. Backslash-newline
# continuations are joined first so that a push whose options sit on the next
# line is still one segment. The pattern tolerates any global option between git
# and push (-C, -c, --git-dir…): a closed list let "git -c x=y push --force" through.
if [ -z "$REASON" ]; then
  PUSH_SEGMENTS=$(echo "$SEGMENTS" \
    | grep -E "${PREFIX}"'git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+push([[:space:]]|$)')
  if [ -n "$PUSH_SEGMENTS" ]; then
    if echo "$PUSH_SEGMENTS" | grep -qE -- '--force|(^|[[:space:]])-f([[:space:]]|$)'; then
      REASON="git push --force blocked by guard.sh"; RULE="push-force"
    elif echo "$PUSH_SEGMENTS" | grep -qE '(^|[^A-Za-z0-9_-])(main|master)([^A-Za-z0-9_-]|$)'; then
      REASON="direct push to main/master blocked by guard.sh"; RULE="push-main"
    fi
  fi
fi

# 4. a shell write to the guardrail's own files. The project's absolute path is
# folded to "./" first, then a guarded path is one that starts the word:
# ".claude/hooks/…" or "./.claude/settings.json" — not "implementation/mos/.claude/…",
# which is someone else's copy (the framework's own source tree, for one).
if [ -z "$REASON" ]; then
  FOLDED=$SEGMENTS; FOLDED_LINE=$JOINED
  for root in "$PROJ_REAL" "$PROJ"; do
    [ -n "$root" ] || continue
    FOLDED=${FOLDED//"$root"\//./}; FOLDED_LINE=${FOLDED_LINE//"$root"\//./}
  done
  GP='(\./)?\.claude/(hooks(/|[[:space:]"'\'']|$)|settings(\.local)?\.json)'
  W='(^|[[:space:]"'\''=])'
  if echo "$FOLDED_LINE" | grep -qE ">[|]?[[:space:]]*[\"']?${GP}" \
    || echo "$FOLDED" | grep -E "${PREFIX}(sed|perl)[[:space:]](.*[[:space:]])?-[A-Za-z]*i" | grep -qE "${W}${GP}" \
    || echo "$FOLDED" | grep -E "${PREFIX}(tee|truncate|rm|trash|unlink|shred|ln)([[:space:]]|$)" | grep -qE "${W}${GP}" \
    || echo "$FOLDED" | grep -E "${PREFIX}(cp|mv|install|rsync)[[:space:]]" | grep -qE "${W}${GP}[^[:space:]]*[[:space:]]*$"; then
    REASON=$GUARD_FILES_REASON; RULE="guard-files"
  fi
fi

if [ -n "$REASON" ]; then
  deny
fi
exit 0  # no decision; the normal permission flow applies
