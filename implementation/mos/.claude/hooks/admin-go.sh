#!/usr/bin/env bash
# admin-go.sh — the admin GO: the user's own words open the guardrail's files for
# one session (0.13). Wired twice in .claude/settings.json:
#   UserPromptSubmit  (no argument)      reads the prompt the human just typed
#   SessionStart      (--session-start)  closes every grant (a compaction excepted)
#
# Like sudo: most GOs stay ordinary words in a conversation and change nothing
# here. Opening the guardrail's own files (.claude/hooks/, .claude/settings*.json,
# guard.sh rule 4) takes a GO one level up: a line of the human's message that
# BEGINS with "admin GO" or "GO admin" (any case; "yes,", "oui,", "ok," may come
# first). A mention elsewhere in a sentence, in quotes or in code opens nothing:
# while the feature itself is discussed, the words come up without being a GO. The agent may ask for it — rule 4's refusal
# tells it how — and the reply that carries the words is the GO; a bare "yes" is
# not one. Why this holds: the prompt the human types is the one text the agent's
# tools cannot write, and this hook sees it before the agent does. A subagent's
# prompt does not fire UserPromptSubmit (observed under Claude Code 2.1.289,
# 2026-10-05: only SubagentStart fires); a message relayed from another session
# arrives wrapped in an envelope (<cross-session-message …>, <task-notification>…):
# a prompt that carries one grants nothing at all, and text inside any other tag
# pair is dropped before the words are looked for.
#
# THE GRANT (format 1, frozen in 0.13; the signed front-desk GO of a later version
# reuses it): one file per session, .claude/hooks/grants/<session_id>, written by
# this hook only (the folder is rule 4's: the agent cannot write it), gitignored.
#   manence-grant: 1
#   scope: guard-files
#   session: <session_id>
#   origin: prompt
#   granted_at: <ISO date>
#   evidence: <the human's line that carries the words, cut at 160 characters>
# guard.sh lets a rule-4 write through when the call's session holds a grant, and
# traces it. Scope: the whole session; any session start closes the guard again,
# a resumed one included, since a resume keeps its session id (the SessionStart
# pass removes every grant, except on a compaction: the same session goes on).
# A harness session the agent launches starts too, and so ends the GO: refused by
# rule 4bis when it carries the words, it still closes the guard. Nothing else is opened:
# rm -rf, forced pushes and the local rules hold as before.
#
# TRACE: every opening, and every ordinary "GO" (uppercase, a word of its own; a
# publication GO said at the terminal, Spec §21), appends one line to the guard's
# trace (.claude/guard-refusals.log; MANENCE_GUARD_LOG moves it): trace only, it
# blocks and opens nothing. The hook asks nothing, and fails closed: an error,
# a missing jq or perl, means no grant and the guard stays shut.
# MANENCE_GRANTS_DIR moves the grants (tests).
set -u
command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat 2>/dev/null || true)
# The project root as guard.sh computes it: CLAUDE_PROJECT_DIR, else the payload's
# cwd, real path — so that the grant lands where the guard looks for it.
ROOT="${CLAUDE_PROJECT_DIR:-$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)}"
[ -n "$ROOT" ] || ROOT=$(pwd)
ROOT=$(cd "$ROOT" 2>/dev/null && pwd -P) || exit 0
GRANTS="${MANENCE_GRANTS_DIR:-$ROOT/.claude/hooks/grants}"
TRACE="${MANENCE_GUARD_LOG:-$ROOT/.claude/guard-refusals.log}"
SESSION=$(printf '%s' "$INPUT" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)
# A session id names a file: anything but [A-Za-z0-9_-] and it is not one.
case "$SESSION" in ''|*[!A-Za-z0-9_-]*) SESSION="" ;; esac

trace() {  # rule text
  { printf '%s\t%s\t%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)" "hook/UserPromptSubmit" "$1" \
      "$(printf '%s' "$2" | tr '\t\r\n' '   ' | cut -c1-200)" >> "$TRACE"; } 2>/dev/null || true
}

if [ "${1:-}" = "--session-start" ]; then
  [ -d "$GRANTS" ] || exit 0
  SOURCE=$(printf '%s' "$INPUT" | jq -r '.source // empty' 2>/dev/null)
  [ "$SOURCE" = compact ] && exit 0
  for g in "$GRANTS"/*; do
    [ -f "$g" ] && rm -f -- "$g" 2>/dev/null
  done
  exit 0
fi

PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // .userPrompt // .message // empty' 2>/dev/null)
[ -n "$PROMPT" ] || exit 0
# A relayed message (another session, a background task) is not the human's
# typing: a prompt that carries such an envelope, closed or not, grants nothing.
if printf '%s' "$PROMPT" | grep -qiE '<(cross-session-message|task-notification|teammate-message|channel-message)([[:space:]>]|$)'; then
  exit 0
fi
# Then drop what is not the human's own sentence: text inside a tag pair, fenced
# code, inline code, and quoted text ("…", «…», “…”).
TYPED=$(printf '%s' "$PROMPT" | perl -CSD -0777 -pe '
  s{<([A-Za-z][\w:-]*)\b[^>]*>.*?</\1\s*>}{}gs;
  s{^```.*?^```}{}gms; s{`[^`\n]*`}{}g;
  s{"[^"\n]*"}{}g; s{\x{AB}[^\x{BB}\n]*\x{BB}}{}g; s{\x{201C}[^\x{201D}\n]*\x{201D}}{}g;
' 2>/dev/null) || TYPED=""
[ -n "$TYPED" ] || exit 0

# The words must begin a line ("yes,", "oui,", "ok," may come first).
ADMIN_RE='^[[:space:]]*((yes|oui|ok|okay|d.accord)[[:space:],.!:;-]+)?(go[[:space:]]+admin|admin[[:space:]]+go)([^[:alnum:]_]|$)'
LINE=$(printf '%s\n' "$TYPED" | grep -iE "$ADMIN_RE" | head -1)
if [ -n "$LINE" ]; then
  [ -n "$SESSION" ] || { echo "admin GO heard, but this harness sent no session id: the guard stays shut (see UPGRADING, 0.13.0)."; exit 0; }
  mkdir -p "$GRANTS" 2>/dev/null || exit 0
  EVIDENCE=$(printf '%s' "$LINE" | tr '\t\r' '  ' | cut -c1-160)
  if [ ! -f "$GRANTS/$SESSION" ]; then
    { printf 'manence-grant: 1\nscope: guard-files\nsession: %s\norigin: prompt\ngranted_at: %s\nevidence: %s\n' \
        "$SESSION" "$(date +%Y-%m-%dT%H:%M:%S%z)" "$EVIDENCE" > "$GRANTS/$SESSION"; } 2>/dev/null || exit 0
    trace "admin-go-open" "$EVIDENCE"
  fi
  echo "admin GO recorded for this session: the guardrail's own files (.claude/hooks/, .claude/settings*.json) are open to you until the session ends; every write through it is traced. Nothing else is opened."
  exit 0
fi

# An ordinary GO, uppercase and standing alone: traced, nothing opened (Spec §21).
GO_LINE=$(printf '%s\n' "$TYPED" | grep -E '(^|[^[:alnum:]_])GO([^[:alnum:]_]|$)' | head -1)
[ -n "$GO_LINE" ] && trace "go" "$GO_LINE"
exit 0
