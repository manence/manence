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
#      truncate, touch, rm/trash/unlink, ln, mv naming one of them anywhere,
#      cp/install/rsync whose last argument is one of them, or a chmod that takes
#      the owner's read bit away; since 0.13.1 the path is read through a variable,
#      ~/, $HOME, $PWD, $(pwd), "//", "/./" and "dir/../", and a cd into the
#      folder, a guarded path put in a variable, or an interpreter one-liner that
#      names one of them count when the command writes). Reading them, and running them, stays free. These files
#      change through upgrade.sh (run by the user or by the agent as a script) or
#      by the user's hand: a guardrail the agent can rewrite protects nothing.
#      Since 0.13 this hook is the only layer for these files: permissions.deny
#      no longer lists them, because a deny outranks every hook and would keep
#      them shut after an admin GO (Claude Code applies Edit(...) rules to shell
#      redirections too, observed 2026-10-05). A hook deny holds in every
#      permission mode, bypass included; if this hook cannot run at all, rule 4
#      cannot either, which is why rule 4 also refuses mv, rm and chmod on it.
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

# Reads chmod segments on stdin; true when one takes the owner's read bit away
# (a hook that bash cannot read fails, and a failing hook lets the call through).
# Numeric modes: owner digit below 4. Symbolic: u, a or no "who" with -r, or = without r.
chmod_drops_read() {
  awk '{
    i = 1; while (i <= NF && $i !~ /(^|[({])chmod$/) i++
    for (i++; i <= NF && $i ~ /^-[RfvhHLP]+$/; i++) ;
    m = $i
    if (m ~ /^[0-7]+$/) { while (length(m) < 3) m = "0" m; if (substr(m, length(m) - 2, 1) + 0 < 4) hit = 1; next }
    n = split(m, cl, ",")
    for (k = 1; k <= n; k++) {
      c = cl[k]; who = c; sub(/[-+=].*$/, "", who); rest = substr(c, length(who) + 1)
      if (who != "" && who !~ /[ua]/) continue
      op = substr(rest, 1, 1); perms = substr(rest, 2)
      if ((op == "-" && perms ~ /r/) || (op == "=" && perms !~ /r/)) hit = 1
    }
  } END { exit hit ? 0 : 1 }'
}

# 4. a shell write to the guardrail's own files. The path is folded first: the
# home and working-directory forms (~/, $HOME/, $PWD/, $(pwd)/…) become the real
# directories, "//", "/./" and "dir/../" collapse, and the project's absolute path
# becomes "./". A guarded path is then one that starts the word, a variable
# allowed in front ($R/.claude/hooks/…, "${R}"/.claude/settings.json: a variable
# there is presumed to name the project): ".claude/hooks/…" or
# "./.claude/settings.json" — not "implementation/mos/.claude/…", which is
# someone else's copy (the framework's own source tree, for one).
# 0.13.1: three more shapes of the same mistake, seen on a core on 2026-10-06. A
# command that changes into the guarded folder (cd .claude/hooks) or puts a
# guarded path in a variable (H=.claude/hooks) and then writes anything; and an
# interpreter one-liner (python3 -c, node -e…) that names a guarded file and
# writes. Still an anti-mistake barrier: a path the shell builds at run time, a
# glob (.clau*/hooks) or a script that writes from a file of its own is not seen.
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
if [ -z "$REASON" ]; then
  FOLDED=$(printf '%s' "$SEGMENTS" | fold_paths); FOLDED_LINE=$(printf '%s' "$JOINED" | fold_paths)
  VP='(\$\{?[A-Za-z_][A-Za-z0-9_]*\}?"?/)?'
  GP="${VP}"'(\./)?\.claude/(hooks(/|[[:space:]"'\'']|$)|settings(\.local)?\.json)'
  W='(^|[[:space:]"'\''=])'
  # Any write at all in the command: a redirection (to a file, not a descriptor or
  # /dev/null), or a segment that begins with a writing command. Used for the cd,
  # variable and interpreter shapes, where the written path itself is not readable.
  any_write() {
    printf '%s\n' "$FOLDED_LINE" | sed -E 's#[0-9]*>{1,2}[|]?[[:space:]]*(&[0-9-]*|/dev/(null|stdout|stderr|tty|fd/[0-9]+))##g' | grep -q '>' \
      || echo "$FOLDED" | grep -qE "${PREFIX}((sed|perl)[[:space:]](.*[[:space:]])?-[A-Za-z]*i|(tee|truncate|touch|rm|trash|unlink|shred|ln|mv|cp|install|rsync|dd)([[:space:]]|$)|git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+(checkout|restore|apply|am|mv|rm)([[:space:]]|$))"
  }
  GUARDED_DIR="${VP}"'(\./)?\.claude(/hooks)?/?'
  MENTION=$(printf '%s\n' "$FOLDED_LINE" | sed 's#implementation/mos/\.claude#implementation/mos/_claude#g')
  if echo "$FOLDED_LINE" | grep -qE ">[|]?[[:space:]]*[\"']?${GP}" \
    || { echo "$FOLDED" | grep -qE "${PREFIX}(cd|pushd)[[:space:]]+[\"']?${GUARDED_DIR}[\"']?[[:space:]]*$" && any_write; } \
    || { echo "$MENTION" | grep -qE "${W}[A-Za-z_][A-Za-z0-9_]*=[\"']?(${GUARDED_DIR}|${GP}[^[:space:]\"';]*)([[:space:]\"';]|$)" && any_write; } \
    || { echo "$FOLDED" | grep -qE "${PREFIX}(python3?|node|ruby|php|deno|bun|perl)[[:space:]]" \
         && echo "$MENTION" | grep -qE '\.claude/(hooks|settings)' \
         && echo "$MENTION" | grep -qE "open\([^)]*[\"'][wax+]|write|unlink|remove|rename|truncate|chmod|rmtree|copyfile|move\(|rmSync|[^0-9&]>{1,2}[[:space:]]*[^&[:space:]]"; } \
    || echo "$FOLDED" | grep -E "${PREFIX}(sed|perl)[[:space:]](.*[[:space:]])?-[A-Za-z]*i" | grep -qE "${W}${GP}" \
    || echo "$FOLDED" | grep -E "${PREFIX}(tee|truncate|touch|rm|trash|unlink|shred|ln|mv)([[:space:]]|$)" | grep -qE "${W}${GP}" \
    || echo "$FOLDED" | grep -E "${PREFIX}(cp|install|rsync)[[:space:]]" | grep -qE "${W}${GP}[^[:space:]]*[[:space:]]*$" \
    || echo "$FOLDED" | grep -E "${PREFIX}git([[:space:]]+-[^[:space:]]+([[:space:]]+[^[:space:]]+)?)*[[:space:]]+(checkout|restore|apply|am|mv|rm)([[:space:]]|$)" | grep -qE "${W}${GP}" \
    || echo "$FOLDED" | grep -E "${PREFIX}dd[[:space:]]" | grep -qE "(^|[[:space:]])of=[\"']?${GP}" \
    || echo "$FOLDED" | grep -E "${PREFIX}chmod[[:space:]]" | grep -E "${W}${GP}" | chmod_drops_read; then
    if granted; then
      trace_line "guard-files-granted" "$COMMAND"
    else
      REASON=$GUARD_FILES_REASON; RULE="guard-files"
    fi
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
if [ -z "$REASON" ]; then
  if echo "$SEGMENTS" | grep -E "${LAUNCH}([^[:space:]]*/)?((ba|z|da)?sh[[:space:]]+((-[^n[:space:]][^[:space:]]*|--[^[:space:]]+)[[:space:]]+)*|source[[:space:]]+|\.[[:space:]]+)?[^[:space:]]*admin-go\.sh([[:space:]]|$)" \
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
