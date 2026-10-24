#!/usr/bin/env bash
# whoami.sh — SessionStart hook: who is at the screen, and who else works here.
# It reads PEOPLE.md (one "## <handle>" section per person) and resolves the
# operator, in this order: the MANENCE_OPERATOR variable, then .claude/operator
# (one line, the handle; gitignored, each machine has its own), then the only
# person when PEOPLE.md has one, else unknown. Among several people it prints the
# operator's section, one line per other person with their authority, and the
# pull/push discipline. A single person (a solo): silence, as without PEOPLE.md,
# except one note line when MANENCE_OPERATOR or .claude/operator names a handle
# that is not that person (0.14.1). Unknown operator among several people: it
# says so and tells the agent to ask "who are you?" once, then write the handle
# into .claude/operator — an identity question, never a permission.
#
# It says, it does nothing else: no write, no network, no question of its own.
# The "at session start" line of AGENTS.md still holds without it (the file is
# the channel, the hook an accelerator). No PEOPLE.md (a MOS from before 0.14,
# or a single person who never wrote one): silence. A PEOPLE.md still holding
# the shipped placeholder: silence too. A malformed file degrades: the sections
# it can read are used, the rest is named in one line. Fail-open: any error is
# silence. Bash 3.2 and standard tools only (awk, sed, tr); jq is used for the
# payload when present, never required.
set -u

# The payload is only needed for its cwd, when the harness does not name the
# project dir. Run by hand or by the agent, stdin may be a terminal, or a pipe
# that nobody writes to nor closes (an agent's shell tool): never wait on it
# (0.16.2). With CLAUDE_PROJECT_DIR set, stdin is not read; otherwise it is read
# for at most 2 seconds (bash 3.2: read -t), and an empty or silent stdin is
# said on stderr, then the core is taken from the current folder.
INPUT=""
if [ -z "${CLAUDE_PROJECT_DIR:-}" ] && [ ! -t 0 ]; then
  IFS= read -r -d '' -t 2 INPUT 2>/dev/null || true
  [ -n "$INPUT" ] || echo "whoami.sh: no hook payload on standard input (run by hand?): reading the core from the current folder." >&2
fi

# The core's root: the harness's project dir, else the payload's cwd, else here.
ROOT="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$ROOT" ] && [ -n "$INPUT" ]; then
  if command -v jq >/dev/null 2>&1; then
    ROOT=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null) || ROOT=""
  fi
  [ -n "$ROOT" ] || ROOT=$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null | head -1)
fi
[ -n "$ROOT" ] || ROOT=$(pwd)
cd "$ROOT" 2>/dev/null || exit 0
[ -f PEOPLE.md ] && [ -r PEOPLE.md ] || exit 0

# The operator: variable, then file. Lenient on the form (case, a leading @,
# surrounding blanks, CRLF; only the first line counts), strict on the match
# against PEOPLE.md, except with a single person: MANENCE_OPERATOR is global to
# the machine, across MOSes, so a name absent from a one-person PEOPLE.md falls
# back to that person, with a note. Printed lines are capped (300 characters
# each, 50 people listed): a runaway file cannot flood the session.
OP=""; SRC=""
if [ -n "${MANENCE_OPERATOR:-}" ]; then
  OP=$(printf '%s\n' "$MANENCE_OPERATOR" | sed -n '/[^[:space:]]/{p;q;}'); SRC="MANENCE_OPERATOR"
elif [ -f .claude/operator ]; then
  OP=$(sed -n '/[^[:space:]]/{p;q;}' .claude/operator 2>/dev/null); SRC=".claude/operator"
fi
OP=$(printf '%s' "$OP" | tr -d '\r' | sed 's/^[[:space:]]*@\{0,1\}//; s/[[:space:]]*$//' | tr 'A-Z' 'a-z' | cut -c1-64)
[ -n "$OP" ] || SRC=""

awk -v op="$OP" -v src="$SRC" '
  { sub(/\r$/, "") }
  NR == 1 && /^---[ \t]*$/ { infm = 1; next }
  infm { if ($0 ~ /^---[ \t]*$/) infm = 0; next }
  /^[ \t]*(```|~~~)/ { fence = !fence; next }
  fence { next }
  /^## / {
    h = substr($0, 4); sub(/^[ \t]+/, "", h); sub(/[ \t]+$/, "", h)
    cur = 0
    if (h == "<handle>") { placeholder = 1 }
    else if (h !~ /^[a-z0-9-]+$/) { bad = bad (bad == "" ? "" : ", ") "\"" substr(h, 1, 40) "\"" }
    else if (h in seen) { dup = dup (dup == "" ? "" : ", ") h }
    else { n++; hd[n] = h; seen[h] = n; cur = n; nb[n] = 0 }
    next
  }
  /^#/ { cur = 0; next }
  cur && /[^ \t]/ {
    if (nb[cur] < 20) { nb[cur]++; body[cur, nb[cur]] = cap($0) }
    if ($0 ~ /^[ \t]*[-*][ \t]*[A-Za-z_]+[ \t]*:/) {
      l = $0; sub(/^[ \t]*[-*][ \t]*/, "", l)
      k = l; sub(/[ \t]*:.*$/, "", k); k = tolower(k)
      v = l; sub(/^[^:]*:[ \t]*/, "", v)
      if (!((cur, k) in kv)) kv[cur, k] = v
    }
  }
  function cap(t) { return (length(t) > 300) ? substr(t, 1, 300) "..." : t }
  function field(i, k,   v) { v = ((i, k) in kv) ? kv[i, k] : ""; return (v == "") ? "(not set)" : v }
  function oneline(i,   s) {
    s = "- @" hd[i]
    if (((i, "name") in kv) && kv[i, "name"] != "") s = s " (" kv[i, "name"] ")"
    return cap(s ": authority " field(i, "authority") "; admin " field(i, "admin"))
  }
  function list(skip,   i, c, rest) {
    c = 0; rest = 0
    for (i = 1; i <= n; i++) {
      if (i == skip) continue
      if (c < 50) { print oneline(i); c++ } else rest++
    }
    if (rest) print "- ... and " rest " more (see PEOPLE.md)"
  }
  END {
    if (n == 0) {
      if (placeholder && bad == "" && dup == "") exit 0
      print "PEOPLE.md is here but holds no readable person (each person is a \"## <handle>\" heading, the handle in a-z, 0-9 and -): the operator is unknown until it is fixed."
      exit 0
    }
    oi = 0; named = 0
    shown = op; gsub(/[^a-z0-9._@ -]/, "?", shown)
    if (op != "") { if (op in seen) oi = seen[op]; else if (n == 1) { oi = 1; note = src " names \"" shown "\", who is not in PEOPLE.md; with a single person, that person is the operator."; src = "" } else named = 1 }
    else if (n == 1) oi = 1

    # A solo: nothing to tell them about themselves (0.14.1). Only the mismatch
    # note and what the file could not read are said.
    if (n == 1) {
      if (note != "") print "Note: " note " (@" hd[1] ")"
      if (dup != "") print "PEOPLE.md: duplicate section(s) ignored, the first one counts: " dup "."
      if (bad != "") print "PEOPLE.md: heading(s) that are not a handle (a-z, 0-9, -) ignored: " bad "."
      exit 0
    }

    print "People of this MOS (PEOPLE.md, " n " " (n == 1 ? "person" : "people") "):"
    if (oi) {
      how = (src != "") ? src : "the only person in PEOPLE.md"
      print "At the screen: @" hd[oi] " (from " how "). Their section:"
      for (j = 1; j <= nb[oi]; j++) print "    " body[oi, j]
      if (note != "") print "Note: " note
      if (n > 1) print "The others:"
      list(oi)
    } else {
      if (named) print "At the screen: unknown. " src " names \"" shown "\", who is not in PEOPLE.md. Ask who is at the screen, then correct " (src == ".claude/operator" ? ".claude/operator" : "MANENCE_OPERATOR") " (one handle from the list below)."
      else print "At the screen: unknown (no MANENCE_OPERATOR, no .claude/operator). Ask \"who are you?\" in your first reply, then write their handle on one line into .claude/operator (gitignored: one per machine). An identity question, once per machine, not a permission."
      list(0)
    }
    if (n > 1) print "Several people share this core: git pull at the start of the session, git push after each commit of the core; a log heading ends with \" · @<handle>\" (AGENTS.md, Conventions). A GO counts from whoever holds authority over the perimeter; an admin GO from an admin: yes person."
    if (dup != "") print "PEOPLE.md: duplicate section(s) ignored, the first one counts: " dup "."
    if (bad != "") print "PEOPLE.md: heading(s) that are not a handle (a-z, 0-9, -) ignored: " bad "."
  }
' PEOPLE.md 2>/dev/null || true
exit 0
