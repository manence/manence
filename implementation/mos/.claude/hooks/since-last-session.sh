#!/usr/bin/env bash
# since-last-session.sh — SessionStart hook: what moved since the last session started.
# A summary DERIVED from the traces, never written by hand: the core's commits, the
# inbox items that are new or changed, the guardrail's refusals (and openings), and
# the workstreams whose About.md moved. It says, it does nothing, it asks nothing:
# an accelerator like consignes.sh, and the "at session start" line of AGENTS.md
# still holds without it. Fast, no dependency beyond git, fail-open: any error is
# silence. Nothing to report = no output at all.
#
# Where "the last session" is remembered: one small file inside the repository's
# git directory (.git/manence-last-session), so outside git's tracking by
# construction — nothing to ignore, nothing to commit, nothing to ask; a core
# without .git falls back to .claude/last-session. It holds the epoch of the last
# start, the guard trace's line count then, and is rewritten at every start except
# a context compaction (source "compact": the same session goes on).
# MANENCE_SINCE_STATE overrides the path (tests).
set -u
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$ROOT" 2>/dev/null || exit 0

INPUT=$(cat 2>/dev/null || true)
case "$INPUT" in *'"source"'*'"compact"'*) exit 0 ;; esac

if [ -n "${MANENCE_SINCE_STATE:-}" ]; then
  STATE=$MANENCE_SINCE_STATE
else
  GITDIR=$(git rev-parse --absolute-git-dir 2>/dev/null || true)
  if [ -n "$GITDIR" ] && [ -d "$GITDIR" ]; then STATE="$GITDIR/manence-last-session"
  else STATE="$ROOT/.claude/last-session"; fi
fi
TRACE="${MANENCE_GUARD_LOG:-$ROOT/.claude/guard-refusals.log}"
NOW=$(date +%s)
TRACE_LINES=$({ wc -l < "$TRACE"; } 2>/dev/null | tr -d ' ')
TRACE_LINES=${TRACE_LINES:-0}

write_state() {
  { printf 'epoch=%s\ntrace_lines=%s\n' "$NOW" "$TRACE_LINES" > "$STATE"; } 2>/dev/null || true
}

# First session on this clone: remember it, say nothing.
if [ ! -f "$STATE" ]; then write_state; exit 0; fi

LAST=$(sed -n 's/^epoch=//p' "$STATE" 2>/dev/null | head -1)
LAST_TRACE=$(sed -n 's/^trace_lines=//p' "$STATE" 2>/dev/null | head -1)
case "$LAST" in ''|*[!0-9]*) write_state; exit 0 ;; esac
case "$LAST_TRACE" in ''|*[!0-9]*) LAST_TRACE=0 ;; esac
# A copy of the state file made under -newer must keep the old mtime: the marker
# is the state file itself, read before it is rewritten.
MARK=$(mktemp "${TMPDIR:-/tmp}/since.XXXXXX" 2>/dev/null) || { write_state; exit 0; }
trap 'rm -f "$MARK"' EXIT
touch -r "$STATE" "$MARK" 2>/dev/null || { write_state; exit 0; }

when=$(date -r "$LAST" '+%Y-%m-%d %H:%M' 2>/dev/null || date -d "@$LAST" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$LAST")
out=""
add() { out="$out$1"$'\n'; }
MAX=8

# 1. The core's commits since then.
commits=$(git log --since="@$LAST" --format='%h %s' 2>/dev/null | cut -c1-110)
if [ -n "$commits" ]; then
  n=$(printf '%s\n' "$commits" | wc -l | tr -d ' ')
  add "- $n commit(s) in the core:"
  add "$(printf '%s\n' "$commits" | head -n "$MAX" | sed 's/^/    /')"
  [ "$n" -gt "$MAX" ] && add "    … and $((n - MAX)) more (git log --since=@$LAST)"
fi

# 2. Inbox items new or changed since then.
if [ -d inbox ]; then
  items=$(find inbox -maxdepth 1 -type f -name '*.md' -newer "$MARK" 2>/dev/null | sort)
  if [ -n "$items" ]; then
    n=$(printf '%s\n' "$items" | wc -l | tr -d ' ')
    add "- $n inbox item(s) new or changed:"
    add "$(printf '%s\n' "$items" | head -n "$MAX" | sed 's/^/    /')"
    [ "$n" -gt "$MAX" ] && add "    … and $((n - MAX)) more"
  fi
fi

# 3. The guardrail's trace: lines written since then (a shorter file was rotated: all of it).
if [ -f "$TRACE" ] && [ "$TRACE_LINES" -gt 0 ]; then
  [ "$TRACE_LINES" -lt "$LAST_TRACE" ] && LAST_TRACE=0
  new=$((TRACE_LINES - LAST_TRACE))
  if [ "$new" -gt 0 ]; then
    lastline=$(tail -n 1 "$TRACE" | awk -F'\t' '{ printf "%s %s: %s", $1, $3, substr($4, 1, 80) }')
    add "- $new guard line(s) in .claude/guard-refusals.log, the last: $lastline"
  fi
fi

# 4. Workstreams whose About.md moved (production root as upgrade.sh resolves it).
PROD=""
if [ -f .env ]; then
  line=$(grep -E '^[A-Za-z0-9_]*PRODUCTION_ROOT=' .env 2>/dev/null | head -1)
  PROD=$(printf '%s' "${line#*=}" | tr -d '"'"'")
fi
[ -n "$PROD" ] || PROD="../production"
case "$PROD" in /*) ;; "~/"*) PROD="$HOME/${PROD#\~/}" ;; *) PROD="$ROOT/$PROD" ;; esac
if [ -d "$PROD" ]; then
  moved=$(find "$PROD" -mindepth 4 -maxdepth 4 -path '*/in-progress/*/About.md' -newer "$MARK" 2>/dev/null \
    | sed -E 's|.*/([^/]+)/in-progress/([^/]+)/About\.md$|\1/\2|' | sort)
  if [ -n "$moved" ]; then
    n=$(printf '%s\n' "$moved" | wc -l | tr -d ' ')
    add "- $n workstream(s) whose About.md moved:"
    add "$(printf '%s\n' "$moved" | head -n "$MAX" | sed 's/^/    /')"
    [ "$n" -gt "$MAX" ] && add "    … and $((n - MAX)) more"
  fi
fi

write_state
[ -n "$out" ] || exit 0
printf 'Since the last session (started %s), derived from the traces:\n%s' "$when" "$out"
exit 0
