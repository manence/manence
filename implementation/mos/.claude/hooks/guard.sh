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
#      and no shell command WRITES there either (0.16: the rule reads the targets
#      of a write, not the mentions): a redirection to one of them, a command
#      that writes, moves, deletes or changes the rights of one of them (tee,
#      touch, truncate, rm, trash, ln, mv, chmod, chown, sed/perl -i, cp/install/
#      rsync to one of them, git checkout/restore/mv/rm on one of them…), a cd
#      into the folder followed by such a write, a heredoc whose target is one
#      of them or whose body a shell or an interpreter runs and writes there, and,
#      in doubt, a command the guard does not know given one of them as argument,
#      bash -c/eval/source/xargs naming one of them, interpreter code that names
#      one and holds any write pattern (0.16.1: code that only reads passes). The path is read through a variable, ~/, $HOME, $PWD,
#      $(pwd), "//", "/./" and "dir/../". Reading them (cat, grep, ls, diff…),
#      running them (bash test-guard.sh), and naming them in a log entry or a
#      capture written through a heredoc, stay free. Detail at rule 4 below. These files
#      change through upgrade.sh (run by the user or by the agent as a script) or
#      by the user's hand: a guardrail the agent can rewrite protects nothing.
#      Since 0.13 this hook is the only layer for these files: permissions.deny
#      no longer lists them, because a deny outranks every hook and would keep
#      them shut after an admin GO (Claude Code applies Edit(...) rules to shell
#      redirections too, observed 2026-10-05). A hook deny holds in every
#      permission mode, bypass included; if this hook cannot run at all, rule 4
#      cannot either, which is why rule 4 also refuses mv, rm and chmod on it
#      (any chmod since 0.16: until 0.15 only one that took the read bit away).
#      THE ADMIN GO (0.13): a line of the user's own message that begins with
#      "admin GO" (or "GO admin") opens these files for the session (admin-go.sh writes the grant
#      from the prompt, this hook reads it, every write through it is traced as
#      guard-files-granted), by file tool and by shell alike. Rule 4bis keeps the GO the
#      human's: the agent neither runs admin-go.sh nor hands the words to a harness
#      session it launches.
#
# NOTE on scope: rules 1 and 2 read the WHOLE command, quoted text included — a
# heredoc that quotes `rm -rf` is blocked as if it were the command (deliberate:
# a rare false positive beats a real negative; write such texts through the
# file-editing tools, or paraphrase). Rules 1bis, 3 and 4 read the command by
# SEGMENT (split on ; | & and newlines, backslash-newline continuations joined
# first; for rule 4, the body of a data heredoc dropped first, since 0.16), and
# rules 3 and 4 only look at segments that BEGIN with the command they check: a branch name in a commit message, a `--base main` on a chained
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
# LOCAL RULES (0.13): a MOS that needs rules of its own never edits this file.
# It writes them in .claude/hooks/guard.local.sh, which upgrade.sh never touches
# and rule 4 protects like the rest of the folder. That file is sourced (not run)
# once the payload is read, and may:
#   - ADD refusals: define local_file_rules (called with each path a file tool
#     writes) and/or local_shell_rules (called once per shell command, after the
#     shipped rules let it through). Each sets REASON and RULE to refuse, then
#     returns; it reads TOOL, COMMAND, JOINED, SEGMENTS, CWD, PROJ, PROJ_REAL,
#     PREFIX and the helpers (is_guard_file…). It never calls deny itself.
#   - LIFT a shipped rule by name: GUARD_LIFT="push-main" (space-separated, among
#     rm-rf fork-bomb push-force push-main). guard-files cannot be lifted: a local
#     file that tries is obeyed for the rest and warned about on stderr.
# A local file that does not parse (bash -n) is skipped with a warning on stderr:
# the shipped rules still hold and its lifts do not, so a broken local file makes
# the guard stricter, never looser. MANENCE_GUARD_LOCAL overrides the path (tests).
# Its cases live in .claude/hooks/test-guard.local.sh, which test-guard.sh plays
# when it exists.
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
SESSION=$(echo "$INPUT" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)
case "$SESSION" in *[!A-Za-z0-9_-]*) SESSION="" ;; esac
if echo "$INPUT" | jq -e 'has("tool_input") or has("tool_name")' >/dev/null 2>&1; then
  DIALECT="claude"
else
  DIALECT="grok"
fi
[ -n "$CWD" ] || CWD=$PWD
PROJ="${CLAUDE_PROJECT_DIR:-$CWD}"
PROJ_REAL=$(cd "$PROJ" 2>/dev/null && pwd -P) || PROJ_REAL=$PROJ

REASON=""; RULE=""; SUBJECT=""

# The guard's own functions, (re)defined after the local file is read, so that
# a local file can never replace deny, the trace or the grant check.
core_functions() {
  # One line per refusal, outside git; never fails the hook.
  trace_refusal() { trace_line "$RULE" "$SUBJECT"; }
  trace_line() {  # rule subject
    local log="${MANENCE_GUARD_LOG:-$PROJ/.claude/guard-refusals.log}" text
    text=$(printf '%s' "$2" | tr '\t\r\n' '   ' | cut -c1-200)
    { printf '%s\t%s/%s\t%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S%z)" \
        "$DIALECT" "${TOOL:-?}" "$1" "$text" >> "$log"; } 2>/dev/null || true
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

  lifted() {  # is this shipped rule lifted by the local file? guard-files never is.
    [ "$1" != "guard-files" ] || return 1
    case " $GUARD_LIFT " in *" $1 "*) return 0 ;; esac
    return 1
  }
  has_local() { declare -F "$1" >/dev/null 2>&1; }

  # The admin GO (0.13): does the session of this call hold a grant, written by
  # admin-go.sh from the human's own prompt? Format 1, see admin-go.sh.
  granted() {
    local g="${MANENCE_GRANTS_DIR:-$PROJ_REAL/.claude/hooks/grants}/$SESSION"
    [ -n "$SESSION" ] && [ -f "$g" ] || return 1
    grep -qx 'manence-grant: 1' "$g" && grep -qx 'scope: guard-files' "$g" && grep -qx "session: $SESSION" "$g"
  }

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

}
core_functions

# --- Local rules (0.13), see the header. Sourced, never executed. ------------
# Hardened: its output goes to stderr (stdout is the guard's answer), and if it
# ends the guard early (an exit, a set -e that trips), the EXIT trap refuses the
# call instead of letting it through; set -e/-u it may leave are undone after.
GUARD_LIFT=""
GUARD_DONE=1
local_broke() {
  [ "$GUARD_DONE" = 1 ] && return
  REASON="guard.local.sh ended the guardrail early (an exit or an error inside it): the call is refused until it is fixed"; RULE="local-broken"; SUBJECT="${COMMAND:-$TOOL}"
  GUARD_DONE=1; deny >&3
}
exec 3>&1   # the guard's answer, kept apart from what the local file prints
trap local_broke EXIT
GUARD_LOCAL="${MANENCE_GUARD_LOCAL:-$(dirname -- "${BASH_SOURCE[0]}")/guard.local.sh}"
if [ -f "$GUARD_LOCAL" ]; then
  if bash -n "$GUARD_LOCAL" 2>/dev/null; then
    GUARD_DONE=0
    # shellcheck source=/dev/null
    . "$GUARD_LOCAL" >&2
    set +e +u; GUARD_DONE=1
  else
    echo "guard.sh: $GUARD_LOCAL does not parse (bash -n): skipped; the shipped rules hold, its lifts do not" >&2
  fi
fi
core_functions
case " $GUARD_LIFT " in
  *" guard-files "*) echo "guard.sh: guard-files cannot be lifted by a local file; the rule holds" >&2 ;;
esac
call_local() {  # name [args]: run one local rule, shielded like the load
  GUARD_DONE=0
  "$@" >&2
  set +e +u; GUARD_DONE=1
}

GUARD_FILES_REASON="the guardrail's own files (.claude/hooks/, .claude/settings*.json) are not written by the agent without an admin GO (guard.sh rule 4). If this write is needed, ask the user, in their language: \"I need an admin GO to write <file> (<reason>). OK?\" Their reply must begin with the words \"admin GO\" (or \"GO admin\"): that opens these files for this session. A plain yes is not an admin GO, and the GO is never written on their behalf. Otherwise these files change through upgrade.sh or by the user's hand."

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
        if granted; then
          trace_line "guard-files-granted" "$p"
        else
          REASON=$GUARD_FILES_REASON; RULE="guard-files"; SUBJECT=$p
          deny
        fi
      fi
      if has_local local_file_rules; then
        call_local local_file_rules "$p"
        if [ -n "$REASON" ]; then SUBJECT=$p; deny; fi
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
if ! lifted rm-rf && echo "$COMMAND" | grep -qE 'rm[[:space:]]+(-[A-Za-z]*r[A-Za-z]*f[A-Za-z]*|-[A-Za-z]*f[A-Za-z]*r[A-Za-z]*|-r[[:space:]]+-f|-f[[:space:]]+-r)([[:space:]]|$)'; then
  REASON="recursive forced rm blocked by guard.sh"; RULE="rm-rf"
fi

# 1bis. recursive + forced rm with long or split options (--recursive --force, -r … -f).
# Split the command into segments (; | &) and require recursive AND forced on the
# segment that carries rm — so that "rm -r x && tail -f log" is not blocked.
if [ -z "$REASON" ] && ! lifted rm-rf && echo "$SEGMENTS" \
  | grep -E '(^|[[:space:]])rm[[:space:]]' \
  | grep -E -- '(^|[[:space:]])(--recursive|-[A-Za-z]*[rR][A-Za-z]*)([[:space:]]|$)' \
  | grep -qE -- '(^|[[:space:]])(--force|-[A-Za-z]*f[A-Za-z]*)([[:space:]]|$)'; then
  REASON="recursive forced rm blocked by guard.sh (long/split options included)"; RULE="rm-rf"
fi

# 2. fork bomb, literal string (grep -F: no ambiguous ERE on empty parentheses)
if [ -z "$REASON" ] && ! lifted fork-bomb && echo "$COMMAND" | grep -qF ':(){ :'; then
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
    if ! lifted push-force && echo "$PUSH_SEGMENTS" | grep -qE -- '--force|(^|[[:space:]])-f([[:space:]]|$)'; then
      REASON="git push --force blocked by guard.sh"; RULE="push-force"
    elif ! lifted push-main && echo "$PUSH_SEGMENTS" | grep -qE '(^|[^A-Za-z0-9_-])(main|master)([^A-Za-z0-9_-]|$)'; then
      REASON="direct push to main/master blocked by guard.sh"; RULE="push-main"
    fi
  fi
fi

# 4. a shell WRITE to the guardrail's own files (0.16: the targets, not the
# mentions). Until 0.15 a mention was enough in several shapes (a heredoc body
# read as commands, a variable naming the folder followed by any write, an
# interpreter line naming a hook and writing anything): two cores worked around
# it by writing from a script outside the core, worse than the risk. Since 0.16
# the rule looks for what the command WRITES:
#   - the text is cut first: a heredoc body read by a data command (cat, tee,
#     git commit -F -, grep…) is data and is dropped, unless something on the
#     same line runs a script; a body read by a shell is read as commands; a body
#     read by an interpreter (python3 -, node…) is read as code; a body read by
#     anything else (git apply, patch, an unknown command) refuses as soon as it
#     names a guarded file;
#   - the paths are folded (below), and a variable that names a guarded path or
#     folder (H=.claude/hooks, for f in .claude/hooks/*) is replaced by its value;
#   - each segment is then classified by its command word: a redirection to a
#     guarded path refuses; a writing command (tee, touch, truncate, rm, trash,
#     unlink, shred, ln, mv, chmod, chown, chgrp, chflags, xattr, mkdir, rmdir,
#     sed/perl -i, awk -i inplace, sort -o) refuses when one of its arguments is a
#     guarded path; cp/install/rsync/ditto/scp when the destination is (the last
#     argument, or -t); dd when of= is; git when a guarded path is an argument of
#     anything but a read (add, diff, log, show, status, blame, grep, ls-files,
#     commit…); find with -delete or an -exec that is not a read; a reading
#     command (cat, grep, ls, head, diff, jq, echo, test…) never refuses by its
#     arguments; running a guarded script (bash .claude/hooks/test-guard.sh, or
#     the path as the command) stays free; ANY OTHER command that takes a guarded
#     path as an argument refuses (in doubt, refuse: a rare false positive beats
#     a real negative);
#   - after a cd/pushd into .claude or .claude/hooks, relative paths are read as
#     inside it;
#   - bash/sh -c, eval, source/., and xargs running anything but a read refuse
#     when the command names a guarded file anywhere;
#   - interpreter code (python3 -c, node -e, a heredoc read by an interpreter),
#     cut out of the command, refuses when it names a guarded file and holds a
#     write pattern on any line, or when it is not in the command at all and the
#     command names a guarded file; code that only reads passes (0.16.1, detail at
#     interp_code below).
# A mention in a reading command, in a data heredoc whose target is another file
# (a log entry, an inbox capture), or in a comment no longer refuses. Still an
# anti-mistake barrier: a path the shell builds at run time, a glob
# (.clau*/hooks) or a script that writes from a file of its own is not seen.
fold_paths() {  # stdin -> stdout: the text with its paths folded as above
  local t h
  t=$(cat)
  for h in '${HOME}/' '"${HOME}"/' '"$HOME"/' '$HOME/' '~/'; do t=${t//"$h"/$HOME/}; done
  for h in '"$(pwd -P)"/' '"$(pwd)"/' '$(pwd -P)/' '$(pwd)/' '`pwd`/' '"${PWD}"/' '"$PWD"/' '${PWD}/' '$PWD/'; do
    t=${t//"$h"/$CWD/}
  done
  t=$(printf '%s' "$t" | sed -E -e ':a' -e 's#//+#/#g; s#/\./#/#g' \
    -e 's#(^|[[:space:]"'\''=/])([^./[:space:]"'\''=][^/[:space:]"'\''=]*|\.[^./[:space:]"'\''=][^/[:space:]"'\''=]*)/\.\./#\1#g' -e 'ta')
  for root in "$PROJ_REAL" "$PROJ"; do
    [ -n "$root" ] || continue
    t=${t//"$root"\//./}
  done
  printf '%s\n' "$t" | sed -E 's#(^|[[:space:]"'\''=])(\./)+#\1./#g'
}

# Heredocs: tags each line C (command), D (body of a data heredoc), I (body read
# by an interpreter) or U (body read by anything else). A shell-read body is C.
split_heredocs() {
  awk '
  function base(w) { sub(/^.*\//, "", w); gsub(/["\047]/, "", w); return w }
  function cls(w, rest,   c) {
    c = base(w)
    if (c == "git") return (rest ~ /(^|[[:space:]])(apply|am)([[:space:]]|$)/) ? 3 : 0
    if (c ~ /^(cat|tee|echo|printf|grep|egrep|fgrep|rg|sed|awk|gawk|jq|wc|sort|uniq|head|tail|cut|tr|column|pbcopy|less|more|diff|cmp|base64|read|fold|fmt|nl|gh|true)$/) return 0
    if (c ~ /^(ba|z|da|k)?sh$/) return 1
    if (c ~ /^(python[0-9.]*|node|ruby|perl|php|deno|bun|osascript|lua|Rscript)$/) return 2
    return 3
  }
  function word(s,   n, w, i, j) {  # the command word of a simple command; sets REST
    n = split(s, w, /[[:space:]]+/); REST = ""
    for (i = 1; i <= n; i++) {
      if (w[i] == "" || w[i] ~ /^(sudo|command|exec|time|nohup|env|then|do|else|if|elif|while|until|!|[{(]+)$/ || w[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) continue
      if (w[i] ~ /^[0-9&]*[<>]/) { if (w[i] ~ /^[0-9&]*[<>]+[|&]?$/) i++; continue }
      for (j = i + 1; j <= n; j++) REST = REST " " w[j]
      return w[i]
    }
    return ""
  }
  function consumer(pre, post,   n, p, c, best, x, m, pc, k) {
    n = split(pre, p, /[;|&(`]/)
    c = word(p[n]); best = (c == "") ? 0 : cls(c, REST)
    m = split(post, pc, /\|/)
    for (k = 2; k <= m; k++) { c = word(pc[k]); if (c != "") { x = cls(c, REST); if (x > best) best = x } }
    return best
  }
  BEGIN { nq = 0; qh = 1 }
  {
    if (nq > 0) {
      t = $0; if (strip[qh]) sub(/^\t+/, "", t)
      if (t == delim[qh]) { qh++; if (qh > nq) { nq = 0; qh = 1 }; next }
      k = kind[qh]
      tg = (k == 0) ? "D" : (k == 1) ? "C" : (k == 2) ? "I" : "U"; print tg "\t" $0
      next
    }
    print "C\t" $0
    rest = $0; pre = ""
    while (match(rest, /<<-?[[:space:]]*[\\"\047]?[A-Za-z_][A-Za-z0-9_.-]*["\047]?/)) {
      if (RSTART > 1 && substr(rest, RSTART - 1, 1) == "<") { pre = pre substr(rest, 1, RSTART + 1); rest = substr(rest, RSTART + 2); continue }
      tok = substr(rest, RSTART, RLENGTH); before = pre substr(rest, 1, RSTART - 1)
      rest = substr(rest, RSTART + RLENGTH); pre = before tok
      d = tok; sub(/^<<-?[[:space:]]*/, "", d); gsub(/[\\"\047]/, "", d)
      nq++; delim[nq] = d; strip[nq] = (tok ~ /^<<-/); kind[nq] = consumer(before, rest)
    }
  }'
}

# A variable that names a guarded path or folder is replaced by its value.
GV='^(\$\{?[A-Za-z_][A-Za-z0-9_]*\}?/)?\.claude(/hooks(/[^[:space:]]*)?|/settings(\.local)?\.json)?/?$'
subst_vars() {
  G4_GV=$GV awk '
  function clean(v) { gsub(/["\047]/, "", v); sub(/^(\.\/)+/, "", v); return v }
  { L[NR] = $0 }
  END {
    GV = ENVIRON["G4_GV"]
    for (r = 1; r <= NR; r++) {
      n = split(L[r], w, /[[:space:];&|()]+/)
      for (k = 1; k <= n; k++) {
        if (match(w[k], /^[A-Za-z_][A-Za-z0-9_]*=/)) {
          nm = substr(w[k], 1, RLENGTH - 1); v = clean(substr(w[k], RLENGTH + 1))
          if (v != "" && v ~ GV) V[nm] = v
        }
        if (w[k] == "for" && k + 2 <= n && w[k + 2] == "in")
          for (j = k + 3; j <= n && w[j] != "do"; j++) { v = clean(w[j]); if (v ~ GV) { V[w[k + 1]] = v; break } }
      }
    }
    for (r = 1; r <= NR; r++) {
      s = L[r]
      for (nm in V) {
        val = V[nm]; gsub(/&/, "\\\\&", val)
        gsub("\\$\\{" nm "\\}", val, s)
        out = ""
        while (match(s, "\\$" nm "([^A-Za-z0-9_]|$)")) { out = out substr(s, 1, RSTART - 1) V[nm]; s = substr(s, RSTART + 1 + length(nm)) }
        s = out s
      }
      print s
    }
  }'
}

# Classifies each segment (stdin, one per line) by its command word, as listed
# above. Prints HIT (a guarded path written), and the flags RISKY (sh -c, eval,
# source, env -S, xargs), INTERP (inline interpreter code), RUNS (a script is
# run) and ADMINRUN (the script run is admin-go.sh, for rule 4bis).
GPW='^(\$\{?[A-Za-z_][A-Za-z0-9_]*\}?/)?\.claude/(hooks(/.*)?|settings(\.local)?\.json)$'
GDW='^(\$\{?[A-Za-z_][A-Za-z0-9_]*\}?/)?\.claude(/hooks)?/?$'
READS='^(cat|less|more|head|tail|grep|egrep|fgrep|rg|ag|ack|ls|stat|file|wc|diff|diff3|cmp|comm|jq|yq|uniq|cut|tr|nl|od|xxd|hexdump|strings|md5|md5sum|shasum|sha1sum|sha256sum|cksum|readlink|realpath|basename|dirname|test|\[|\[\[|echo|printf|bat|column|tree|du|shellcheck|pbcopy|true|false|type|which|whence|for|case|in|select|esac|done|fi|export|local|declare|readonly|typeset|unset|set|shift|return|exit|wait|sleep|date|pwd|gh|popd|read|fold|fmt|base64)$'
GITREADS='^(add|diff|log|show|status|blame|annotate|grep|ls-files|ls-tree|cat-file|rev-parse|check-ignore|check-attr|commit|shortlog|whatchanged|diff-files|diff-index|diff-tree|describe)$'
classify_segments() {
  G4_GPW=$GPW G4_GDW=$GDW G4_READS=$READS G4_GITREADS=$GITREADS awk '
  BEGIN { GPW = ENVIRON["G4_GPW"]; GDW = ENVIRON["G4_GDW"]; READS = ENVIRON["G4_READS"]; GITREADS = ENVIRON["G4_GITREADS"]; cddir = "" }
  function path(w,   e) {  # the word as a path: unquoted, after =, inside the cd folder
    e = w; gsub(/["\047]/, "", e)
    if (e ~ /^-/ && e !~ /=/) return ""
    if (e ~ /=/) sub(/^[^=]*=/, "", e)
    if (e == "") return ""
    if (cddir != "" && e !~ /^[\/~$]/) e = cddir "/" e
    sub(/^(\.\/)+/, "", e)
    while (e ~ /(^|\/)[^\/.][^\/]*\/\.\.(\/|$)/) sub(/[^\/.][^\/]*\/\.\.(\/|$)/, "", e)
    return e
  }
  function isgp(w,   e) { e = path(w); return (e != "" && e ~ GPW) }
  function anygp(from,   k) { for (k = from; k <= na; k++) if (isgp(a[k])) return 1; return 0 }
  function isgpd(w,   e) { e = path(w); return (e != "" && (e ~ GPW || e ~ GDW)) }   # the folder itself too
  function anygpd(from,   k) { for (k = from; k <= na; k++) if (isgpd(a[k])) return 1; return 0 }
  function hit() { HIT = 1 }
  {
    n = split($0, w, /[[:space:]]+/); na = 0
    # redirections out of the word list (a write to a guarded target is a hit)
    for (k = 1; k <= n; k++) {
      t = w[k]; if (t == "") continue
      if (t ~ /^[0-9&]*(>>?|<<?<?)[|]?/) {
        tg = t; sub(/^[0-9&]*(>>?|<<?<?)[|]?/, "", tg)
        if (tg == "" && k < n) { k++; tg = w[k] }
        if (t ~ /^[0-9&]*>/ && tg !~ /^&/ && isgp(tg)) hit()
        continue
      }
      a[++na] = t
    }
    # the launchers in front of the command word (0.16.2: env with its options,
    # timeout with its duration; a check run under them is still a check)
    i = 1
    while (i <= na) {
      if (a[i] ~ /^(sudo|command|exec|time|nohup|if|elif|while|until|do|then|else|!|[({]+)$/ || a[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { i++; continue }
      if (a[i] == "env") {
        for (i++; i <= na && (a[i] ~ /^-/ || a[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/); i++) {
          if (a[i] ~ /^-[A-Za-z]*S|^--split-string/) { RISKY = 1; next }
          if (a[i] ~ /^(-u|--unset|-C|--chdir)$/) i++
        }
        continue
      }
      if (a[i] ~ /^g?timeout$/) {
        for (i++; i <= na && a[i] ~ /^-/; i++) if (a[i] ~ /^(-s|-k|--signal|--kill-after)$/) i++
        i++; continue
      }
      break
    }
    if (i > na) next
    cmd = a[i]; sub(/^[({]+/, "", cmd); c = cmd; sub(/^.*\//, "", c); gsub(/["\047]/, "", c)
    if (c == "admin-go.sh") ADMINRUN = 1
    if (c == "cd" || c == "pushd") {
      e = path(a[i + 1]); cddir = (e != "" && e ~ GDW) ? e : ""; sub(/\/$/, "", cddir); next
    }
    if (cmd ~ /\// && isgp(cmd)) { RUNS = 1; next }                       # running a guarded script
    if (c ~ /^(ba|z|da|k)?sh$/) {
      for (k = i + 1; k <= na && a[k] ~ /^-/; k++) { if (a[k] ~ /^-[A-Za-z]*c/) { RISKY = 1; next }; if (a[k] == "-n") next }
      if (k <= na) { RUNS = 1; if (a[k] ~ /admin-go\.sh["\047]?$/) ADMINRUN = 1; if (!isgp(a[k]) && anygp(k + 1)) hit() }
      next
    }
    if (c == "plutil") { if (a[i + 1] ~ /^-(lint|p|help)$/) next; if (anygpd(i + 1)) hit(); next }
    if (c ~ /^(python[0-9.]*|node|ruby|php|deno|bun|osascript|lua|Rscript|perl)$/) {
      if (c == "perl") for (k = i + 1; k <= na; k++) if (a[k] ~ /^-[A-Za-z]*i/) { if (anygp(i + 1)) hit(); next }
      for (k = i + 1; k <= na && a[k] ~ /^-/; k++) {
        if (a[k] ~ /^-([A-Za-z]*[ceEr]|-eval|-print)?$/) { INTERP = 1; next }
        if (a[k] == "-m") {   # json.tool reads its first file and writes only a second one (0.16.2)
          if (a[k + 1] == "json.tool") { np = 0; for (j = k + 2; j <= na; j++) if (a[j] !~ /^-/ && ++np >= 2 && isgp(a[j])) hit() }
          else if (anygp(k + 1)) hit()
          next
        }
      }
      if (k > na) { INTERP = 1; next }
      RUNS = 1; if (!isgp(a[k]) && anygp(k + 1)) hit()
      next
    }
    if (c == "eval" || c == "source" || c == ".") { RISKY = 1; next }
    if (c == "xargs") {
      for (k = i + 1; k <= na && a[k] ~ /^-/; k++) if (a[k] ~ /^-[nIPLdEsa]$/) k++
      s = a[k]; sub(/^.*\//, "", s)
      if (k > na || !(s ~ READS || (s == "sed" && !anyinplace(k)) || (s ~ /^(ba|z|da|k)?sh$/ && a[k + 1] == "-n"))) RISKY = 1
      next
    }
    if (c == "sed") { for (k = i + 1; k <= na; k++) if (a[k] ~ /^-[A-Za-z]*i|^--in-place/) { if (anygp(i + 1)) hit(); break } next }
    if (c == "awk" || c == "gawk") { for (k = i + 1; k <= na; k++) if (a[k] ~ /^-i(nplace)?$/ && (a[k] != "-i" || a[k + 1] == "inplace")) { if (anygp(i + 1)) hit(); break } next }
    if (c == "sort") { for (k = i + 1; k <= na; k++) if (a[k] ~ /^-o|^--output/) { if (anygp(i + 1)) hit(); break } next }
    if (c == "find") {
      if (!anygp(i + 1)) next
      for (k = i + 1; k <= na; k++) {
        if (a[k] ~ /^-(delete|fprint|fprint0|fprintf|fls)$/) { hit(); break }
        if (a[k] ~ /^-(exec|execdir|ok|okdir)$/) { s = a[k + 1]; sub(/^.*\//, "", s); if ((!(s ~ READS) && !(s ~ /^(ba|z|da|k)?sh$/ && a[k + 2] == "-n")) || (s == "sed")) { hit(); break } }
      }
      next
    }
    if (c == "git") {
      for (k = i + 1; k <= na && a[k] ~ /^-/; k++) if (a[k] == "-C" || a[k] == "-c") k++
      if (k <= na && a[k] !~ GITREADS && anygp(k + 1)) hit()
      next
    }
    if (c ~ /^(cp|install|rsync|ditto|scp)$/) {
      for (k = i + 1; k <= na; k++) if ((a[k] == "-t" || a[k] == "--target-directory") && isgpd(a[k + 1])) hit(); else if (a[k] ~ /^--target-directory=/ && isgpd(a[k])) hit()
      if (na > i && isgpd(a[na])) hit()
      next
    }
    if (c == "dd") { for (k = i + 1; k <= na; k++) if (a[k] ~ /^of=/ && isgp(a[k])) hit(); next }
    if (c ~ READS) next
    # a writing command, or one the guard does not know: a guarded argument refuses
    if (anygpd(i + 1)) hit()
  }
  function anyinplace(from,   k) { for (k = from; k <= na; k++) if (a[k] ~ /^-[A-Za-z]*i/) return 1; return 0 }
  END { print "DONE"; if (HIT) print "HIT"; if (RISKY) print "RISKY"; if (INTERP) print "INTERP"; if (RUNS) print "RUNS"; if (ADMINRUN) print "ADMINRUN" }'
}

# Interpreter code (0.16.1: a reader passes). The code is what the interpreter
# runs, cut out of the command (interp_code): the argument of -c, -e, -E, -r or
# --eval (node, deno, bun: -p and --print too), a here-string, the body of a
# heredoc read by an interpreter, and any later argument of that call that names
# a guarded file (the code may open sys.argv[1]). When the code cannot be cut
# out for sure, the whole command is read instead (an unterminated quote); and
# when the code is not in the command at all (a double-quoted code holding a $
# or a backtick, an interpreter reading a pipe or a file redirection), a command
# that names a guarded file anywhere refuses: unseen code given a guarded path. Then (code_writes), triple-quoted strings and comment lines
# dropped: code that names no guarded file passes; code that names one passes
# only when it holds no write pattern on any line: open() with a mode holding w,
# a, x or + (or a mode given by a name), a write method (.write( except to
# stdout or stderr, write_text, writeFile, appendFile…), a file-system call that
# changes something (os.* other than a read, shutil, unlink, rename, a one-
# argument .replace(), mkdir, chmod, touch, truncate…), a process (subprocess,
# system, popen, spawn, exec, child_process, a backtick, %x, qx), eval, exec and
# dynamic imports (__import__, importlib, getattr), Perl's in-place $^I, a quoted
# redirection (">", "+<", "|-": Perl, Ruby), open flags (O_WRONLY, O_CREAT…).
# In doubt, refuse. A shell redirection on the same line is the shell's (read
# above), not the code's.
interp_code() {  # stdin: the command lines -> stdout: the inline code; UNSEEN, FALLBACK
  G4_GP='\.claude/(hooks|settings)' awk '
  function endword() { if (inw) { nw++; W[nw] = cur; D[nw] = dol } cur = ""; inw = 0; dol = 0 }
  function emit(j) { if (j > nw || D[j]) print "UNSEEN"; else print W[j] }
  function endseg(   k, c, j, cf, code, script, stdin, hd) {
    k = 1
    while (k <= nw) {   # the same launchers as classify_segments: env and its options, timeout and its duration
      if (W[k] ~ /^(sudo|command|exec|time|nohup|if|elif|while|until|do|then|else|!|\{)$/ || W[k] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { k++; continue }
      if (W[k] == "env") { for (k++; k <= nw && (W[k] ~ /^-/ || W[k] ~ /^[A-Za-z_][A-Za-z0-9_]*=/); k++) if (W[k] ~ /^(-u|--unset|-C|--chdir)$/) k++; continue }
      if (W[k] ~ /^g?timeout$/) { for (k++; k <= nw && W[k] ~ /^-/; k++) if (W[k] ~ /^(-s|-k|--signal|--kill-after)$/) k++; k++; continue }
      break
    }
    if (k <= nw) {
      c = W[k]; sub(/^.*\//, "", c)
      if (c ~ /^(python[0-9.]*|node|ruby|perl|php|deno|bun|osascript|lua|Rscript)$/) {
        cf = (c ~ /^(node|deno|bun)$/) ? "^-([A-Za-z]*[ep]|-eval|-print)$" : "^-([A-Za-z]*[ceEr]|-eval)$"
        code = 0; script = 0; stdin = 0; hd = 0
        for (j = k + 1; j <= nw; j++) {
          if (W[j] ~ cf) { code = 1; emit(j + 1); j++; continue }
          if (W[j] ~ /^[0-9]*<<</) { code = 1; if (W[j] ~ /^[0-9]*<<<$/) { emit(j + 1); j++ } else { if (D[j]) print "UNSEEN"; else { x = W[j]; sub(/^[0-9]*<<</, "", x); print x } } continue }
          if (W[j] ~ /^[0-9]*<</) { hd = 1; if (W[j] ~ /^[0-9]*<<-?$/) j++; continue }
          if (W[j] ~ /^[0-9]*</) { stdin = 1; if (W[j] ~ /^[0-9]*<$/) j++; continue }
          if (W[j] ~ /^[0-9&]*>/) { if (W[j] ~ /^[0-9&]*>>?[|]?$/) j++; continue }
          if (W[j] == "-" && !code && !script) { stdin = 1; continue }
          if (W[j] ~ ENVIRON["G4_GP"]) print W[j]
          if (!code && !stdin && W[j] !~ /^-/) script = 1
        }
        if (!code && !hd && (stdin || !script)) print "UNSEEN"
      }
    }
    nw = 0
  }
  { s = s $0 "\n" }
  END {
    n = length(s); i = 1; nw = 0; cur = ""; inw = 0; dol = 0
    while (i <= n) {
      ch = substr(s, i, 1)
      if (ch == "\047") {
        j = index(substr(s, i + 1), "\047"); if (!j) { bad = 1; break }
        cur = cur substr(s, i + 1, j - 1); i += j + 1; inw = 1; continue
      }
      if (ch == "\"") {
        i++
        while (i <= n) {
          c2 = substr(s, i, 1)
          if (c2 == "\\") { d2 = substr(s, i + 1, 1); if (d2 ~ /["\\$`]/) { cur = cur d2; i += 2; continue } if (d2 == "\n") { i += 2; continue } cur = cur c2; i++; continue }
          if (c2 == "\"") break
          if (c2 == "$" || c2 == "`") dol = 1
          cur = cur c2; i++
        }
        if (i > n) { bad = 1; break }
        i++; inw = 1; continue
      }
      if (ch == "\\") { cur = cur substr(s, i + 1, 1); i += 2; inw = 1; continue }
      if (ch == " " || ch == "\t") { endword(); i++; continue }
      if (ch ~ /[;&|()\n]/) { endword(); endseg(); i++; continue }
      if (ch == "$" || ch == "`") dol = 1
      cur = cur ch; inw = 1; i++
    }
    if (bad) print "FALLBACK"; else { endword(); endseg() }
  }'
}

INTERP_GP='\.claude/(hooks|settings)|["'\'']\.claude["'\''].*["'\''](hooks|settings(\.local)?\.json)["'\'']'
CW_N='(^|[^A-Za-z0-9_])'; CW_E='([^A-Za-z0-9_]|$)'
CODE_WRITE="${CW_N}(write_text|write_bytes|writelines|writeFile|writeFileSync|appendFile|appendFileSync|createWriteStream|unlink|unlinkSync|rename|renames|renameSync|rmtree|rmdir|rmdirSync|rmSync|rm|removedirs|mkdir|mkdirSync|makedirs|touch|chmod|chmodSync|lchmod|chown|lchown|chflags|symlink|symlink_to|symlinkSync|hardlink_to|link_to|linkSync|truncate|ftruncate|truncateSync|utime|utimes|utimesSync|copyfile|copyFile|copyFileSync|cpSync|copytree|copy2|copymode|copystat|sysopen|binwrite|syswrite|system|popen|spawn|spawnSync|execSync|execFile|execFileSync|exec|execv|execvp|fork|eval|__import__|import_module|importlib|getattr|builtins|__builtins__|subprocess|child_process|shutil|FileUtils|ctypes|pty|qx|O_WRONLY|O_RDWR|O_CREAT|O_APPEND|O_TRUNC|WRONLY|RDWR|CREAT|TRUNC)${CW_E}|\.write(lines)?[[:space:]]*\(|\.replace[[:space:]]*\([^,()]*\)|\.(copy|copy_into|move|move_into)[[:space:]]*\([[:space:]]*[^)[:space:]]|(^|[^A-Za-z0-9_.])remove[[:space:]]*\(|from[[:space:]]+(os|posix|nt)[[:space:]]+import|import[[:space:]]+(os|posix|nt)[[:space:]]+as|\`|%x|\\\$\^I|[\"'](\+?>|\+<|\|-|-\|)|flag[[:space:]]*:[[:space:]]*[\"'][^\"']*[wax+]|File\.(write|delete|binwrite)|IO\.(write|binwrite|popen|sysopen)"
OPEN_WRITE="[\"'][rbtU]*[wax+][rbtU+]*[\"']|mode[[:space:]]*=[[:space:]]*([^\"'[:space:]]|[\"'][^\"']*[wax+])|open(Sync)?[[:space:]]*\([^,]*,[[:space:]]*[A-Za-z_][A-Za-z0-9_.]*[[:space:]]*[,)]|\.open[[:space:]]*\([[:space:]]*[A-Za-z_][A-Za-z0-9_.]*[[:space:]]*[,)]"
OS_READS='path|environ|getenv|getcwd|getcwdb|listdir|scandir|walk|stat|lstat|sep|linesep|pathsep|extsep|access|fspath|name|curdir|pardir|devnull|getpid|getppid|cpu_count|get_terminal_size|isatty|fsencode|fsdecode|getuid|getgid|getlogin|uname|times|urandom|readlink|R_OK|F_OK|X_OK'
code_writes() {  # stdin: interpreter code -> true when it names a guarded file and may write
  local code
  code=$(awk '{ s = $0; out = ""
      while (s != "") {
        if (inq) { p = index(s, q); if (!p) { s = ""; break } s = substr(s, p + 3); inq = 0; continue }
        p1 = index(s, "\"\"\""); p2 = index(s, "\047\047\047")
        if (!p1 && !p2) { out = out s; break }
        if (!p1 || (p2 && p2 < p1)) { p = p2; q = "\047\047\047" } else { p = p1; q = "\"\"\"" }
        out = out substr(s, 1, p - 1); s = substr(s, p + 3); inq = 1
      }
      print out }' | sed 's#implementation/mos/\.claude#implementation/mos/_claude#g' | grep -vE '^[[:space:]]*(#|//)')
  printf '%s\n' "$code" | grep -qE "$INTERP_GP" || return 1
  code=$(printf '%s\n' "$code" | sed -E 's/(sys\.|process\.|\$)?std(out|err)\.write/STD_OUT/g')
  printf '%s\n' "$code" | grep -qE "$CODE_WRITE" && return 0
  printf '%s\n' "$code" | grep -oE '(^|[^A-Za-z0-9_.])os\.[A-Za-z_]+' | sed 's/.*os\./os./' | grep -qvxE "os\.($OS_READS)" && return 0
  printf '%s\n' "$code" | grep -E 'open(Sync)?[[:space:]]*\(' | grep -qE "$OPEN_WRITE" && return 0
  return 1
}

guard_files_write() {  # true when the command writes one of the guardrail's files
  local tagged cmdtext text flags mention_re full TAB icode
  TAB=$(printf '\t')
  tagged=$(printf '%s\n' "$JOINED" | split_heredocs) && [ -n "$tagged" ] || return 0
  cmdtext=$(printf '%s\n' "$tagged" | sed -n "s/^C${TAB}//p")
  text=$(printf '%s\n' "$cmdtext" | sed '/^[[:space:]]*#/d' | fold_paths | subst_vars)   # a comment line is not a command
  GP='(\$\{?[A-Za-z_][A-Za-z0-9_]*\}?"?/)?(\./)?\.claude/(hooks(/|[[:space:]"'\'']|$)|settings(\.local)?\.json)'
  # a redirection glued to its target, quoted, or inside a string (>x, >"x")
  printf '%s\n' "$text" | grep -qE ">[|]?[[:space:]]*[\"']?${GP}" && return 0
  flags=$(printf '%s\n' "$text" | tr ';|&' '\n' | classify_segments)
  case "$flags" in *HIT*|"") return 0 ;; esac   # an awk that fails refuses (fail-closed)
  case "$flags" in *DONE*) : ;; *) return 0 ;; esac
  mention_re='\.claude/(hooks|settings)'
  full=$(printf '%s\n' "$JOINED" | fold_paths | sed 's#implementation/mos/\.claude#implementation/mos/_claude#g')
  case "$flags" in *RISKY*) printf '%s\n' "$full" | grep -qE "$mention_re" && return 0 ;; esac
  icode=""
  if printf '%s\n' "$cmdtext" | grep -qE '(^|[^A-Za-z0-9_])(python[0-9.]*|node|ruby|perl|php|deno|bun|osascript|lua|Rscript)([^A-Za-z0-9_.]|$)'; then
    icode=$(printf '%s\n' "$cmdtext" | interp_code)
    case "$icode" in *UNSEEN*)
      printf '%s\n' "$cmdtext" | fold_paths | sed 's#implementation/mos/\.claude#implementation/mos/_claude#g' | grep -qE "$mention_re" && return 0 ;;
    esac
    case "$icode" in *FALLBACK*) icode=$cmdtext ;; esac
  fi
  { printf '%s\n' "$icode"; printf '%s\n' "$tagged" | sed -n "s/^I${TAB}//p"; } | code_writes && return 0
  printf '%s\n' "$tagged" | sed -n "s/^U${TAB}//p" | sed 's#implementation/mos/\.claude#implementation/mos/_claude#g' | grep -qE "$mention_re" && return 0
  case "$flags" in *RUNS*)
    printf '%s\n' "$tagged" | sed -n "s/^D${TAB}//p" | sed 's#implementation/mos/\.claude#implementation/mos/_claude#g' | grep -qE "$mention_re" && return 0 ;;
  esac
  return 1
}
if [ -z "$REASON" ] && guard_files_write; then
  if granted; then
    trace_line "guard-files-granted" "$COMMAND"
  else
    REASON=$GUARD_FILES_REASON; RULE="guard-files"
  fi
fi

# 4bis. the admin GO is the human's, never the agent's (0.13): the agent does not
# run the hook that writes grants (a syntax check, bash -n, stays free), nor hand
# the words to a harness session it launches (that session's prompt would be the
# agent's text; the line is read whole, so a pipe or a heredoc into the harness
# counts). A text the shell builds at run time ($(cat notes.md)) is not seen: an
# anti-mistake barrier. Note that a harness session the agent launches starts by
# closing every grant (admin-go.sh --session-start): it ends the human's admin GO.
# Not liftable, and an admin GO does not open it.
ADMIN_WORDS='(^|[^[:alnum:]_])(go[[:space:]]+admin|admin[[:space:]]+go)([^[:alnum:]_]|$)'
LAUNCH="${PREFIX}((env|npx|exec)[[:space:]]+([^[:space:]]+=[^[:space:]]*[[:space:]]+)*)?"
admin_go_run() {  # true when the classifier sees admin-go.sh run or sourced, whatever launcher stands before it (0.16.2)
  local TAB; TAB=$(printf '\t')
  printf '%s\n' "$JOINED" | split_heredocs | sed -n "s/^C${TAB}//p" | sed '/^[[:space:]]*#/d' | fold_paths \
    | tr ';|&' '\n' | classify_segments | grep -qx ADMINRUN
}
if [ -z "$REASON" ]; then
  if admin_go_run; then
    REASON="admin-go.sh is the user's: it runs on their prompt, never by the agent (guard.sh rule 4bis). Ask the user for an admin GO instead."; RULE="admin-go-forge"
  elif echo "$SEGMENTS" | grep -E "${LAUNCH}([^[:space:]]*/)?((ba|z|da)?sh[[:space:]]+((-[^n[:space:]][^[:space:]]*|--[^[:space:]]+)[[:space:]]+)*|source[[:space:]]+|\.[[:space:]]+)?[^[:space:]]*admin-go\.sh([[:space:]]|$)" \
     | grep -vqE "(^|[[:space:]])sh[[:space:]]+-n[[:space:]]|bash[[:space:]]+-n[[:space:]]"; then
    REASON="admin-go.sh is the user's: it runs on their prompt, never by the agent (guard.sh rule 4bis). Ask the user for an admin GO instead."; RULE="admin-go-forge"
  elif echo "$SEGMENTS" | grep -qE "${LAUNCH}([^[:space:]]*/)?(claude|codex|grok)([[:space:]]|$)" \
     && printf '%s\n' "$JOINED" | grep -qiE "$ADMIN_WORDS"; then
    REASON="an admin GO handed to a harness session the agent launches is the agent's text, not the user's (guard.sh rule 4bis). Ask the user for it in this session."; RULE="admin-go-relay"
  fi
fi

# 5. the local rules (0.13), only when the shipped ones let the command through.
if [ -z "$REASON" ] && has_local local_shell_rules; then
  call_local local_shell_rules
fi

if [ -n "$REASON" ]; then
  deny
fi
exit 0  # no decision; the normal permission flow applies
