#!/usr/bin/env bash
# Checks that whoami.sh resolves the operator as the Spec says and degrades
# gracefully: silent without PEOPLE.md, the only person when there is one, the
# variable before the file, unknown named as such, a malformed file read as far
# as it can be. Run it after any change to whoami.sh or to the format of PEOPLE.md.
# Usage: bash .claude/hooks/test-whoami.sh   (exit 0 when every case conforms)
#
# The suite runs in a throwaway project (a temporary directory): it never reads
# or writes this MOS's PEOPLE.md or .claude/operator.
HOOKS="$(cd "$(dirname "$0")" && pwd)"
WHOAMI="$HOOKS/whoami.sh"
unset MANENCE_OPERATOR
ok=0; ko=0

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/test-whoami.XXXXXX") || exit 1
trap 'chmod -R u+rw "$SANDBOX" 2>/dev/null; rm -r "$SANDBOX"' EXIT
SANDBOX=$(cd "$SANDBOX" && pwd -P)
PROJ="$SANDBOX/proj"

fresh() {  # an empty core
  rm -rf "$PROJ"; mkdir -p "$PROJ/.claude"
}
people() {  # write PEOPLE.md from stdin
  cat > "$PROJ/PEOPLE.md"
}
run() {  # run the hook as the harness does; stdout in $OUT, exit code in $RC
  OUT=$(CLAUDE_PROJECT_DIR="$PROJ" bash "$WHOAMI" < /dev/null 2>"$SANDBOX/err"); RC=$?
}
expect() {  # label, then pairs: has|lacks pattern (grep -E on the output)
  local label=$1 bad=""; shift
  [ "$RC" -eq 0 ] || bad="exit $RC"
  [ -s "$SANDBOX/err" ] && bad="$bad; stderr: $(head -c 120 "$SANDBOX/err")"
  while [ $# -gt 1 ]; do
    case $1 in
      has)   printf '%s\n' "$OUT" | grep -qE -- "$2" || bad="$bad; missing /$2/" ;;
      lacks) printf '%s\n' "$OUT" | grep -qE -- "$2" && bad="$bad; unexpected /$2/" ;;
      empty) [ -z "$OUT" ] || bad="$bad; output not empty" ;;
    esac
    shift 2
  done
  if [ -z "$bad" ]; then ok=$((ok+1)); printf '  ok  %s\n' "$label"
  else ko=$((ko+1)); printf '  KO  %s (%s)\n' "$label" "${bad#; }"; printf '%s\n' "$OUT" | sed 's/^/        | /'; fi
}

two_people() {
  people <<'EOF'
---
type: reference
title: "People"
---

# People

## sam
- name: Sam Rivera
- role: founder
- authority: *
- admin: yes
- notes: one day a week

## lee
- name: Lee Chen
- role: partner
- authority: site, offers/
- admin: no
EOF
}

# 1. A MOS from before 0.14: no PEOPLE.md, no word.
fresh; run
expect "no PEOPLE.md: silent" empty x

# 2. The shipped template, not yet filled by the first setup: no word either.
fresh; printf -- '---\ntype: reference\n---\n\n# People\n\nEach person is a section.\n\n## <handle>\n- name: <Full name>\n- authority: *\n' > "$PROJ/PEOPLE.md"
run
expect "shipped placeholder: silent" empty x

# 3. One person, no operator: that person, and nothing about pulling.
fresh; people <<'EOF'
# People

## sam
- name: Sam Rivera
- authority: *
- admin: yes
EOF
run
expect "one person, no operator: the only person" has '^At the screen: @sam \(from the only person' has '- authority: \*' lacks 'unknown' lacks 'git pull' lacks 'who are you'

# 4. Two people, the operator in .claude/operator (CRLF, @, uppercase tolerated).
fresh; two_people; printf '@Lee\r\n' > "$PROJ/.claude/operator"; run
expect "two people, operator file: lee at the screen" has '^At the screen: @lee \(from \.claude/operator\)' has '- name: Lee Chen' has '^- @sam \(Sam Rivera\): authority \*; admin yes' has 'git pull' has 'git push' lacks 'unknown'

# 5. Two people, no operator: unknown, ask once, list everyone.
fresh; two_people; run
expect "two people, no operator: unknown, ask" has '^At the screen: unknown' has 'who are you' has '\.claude/operator' has '^- @sam ' has '^- @lee \(Lee Chen\): authority site, offers/; admin no' has 'git pull'

# 6. The variable wins over the file.
fresh; two_people; printf 'lee\n' > "$PROJ/.claude/operator"
OUT=$(MANENCE_OPERATOR=sam CLAUDE_PROJECT_DIR="$PROJ" bash "$WHOAMI" < /dev/null 2>"$SANDBOX/err"); RC=$?
expect "MANENCE_OPERATOR overrides .claude/operator" has '^At the screen: @sam \(from MANENCE_OPERATOR\)' has '^- @lee '

# 7. The operator names a handle absent from PEOPLE.md: unknown, said as such.
fresh; two_people; printf 'bob\n' > "$PROJ/.claude/operator"; run
expect "operator absent from PEOPLE.md: named, unknown" has 'names "bob", who is not in PEOPLE\.md' has '^- @sam ' has '^- @lee ' lacks '^At the screen: @'

# 8. A single person and an operator that does not match (MANENCE_OPERATOR is
#    global to the machine): that person, with a note.
fresh; people <<'EOF'
## sam
- name: Sam Rivera
EOF
printf 'lee\n' > "$PROJ/.claude/operator"; run
expect "one person, operator file names someone else: that person, noted" has '^At the screen: @sam \(from the only person' has '^Note: \.claude/operator names "lee"'
OUT=$(MANENCE_OPERATOR=other CLAUDE_PROJECT_DIR="$PROJ" bash "$WHOAMI" < /dev/null 2>"$SANDBOX/err"); RC=$?
expect "one person, MANENCE_OPERATOR from another MOS: that person, noted" has '^At the screen: @sam ' has '^Note: MANENCE_OPERATOR names "other"'

# 8b. Only the first line of MANENCE_OPERATOR counts.
fresh; two_people
OUT=$(MANENCE_OPERATOR="$(printf '\n  lee\nsam\n')" CLAUDE_PROJECT_DIR="$PROJ" bash "$WHOAMI" < /dev/null 2>"$SANDBOX/err"); RC=$?
expect "MANENCE_OPERATOR: first non-blank line only" has '^At the screen: @lee '

# 8c. Caps: a 400-character line is cut, 60 people list 50 and say the rest.
fresh; { printf '## sam\n- name: Sam\n- notes: '; head -c 400 /dev/zero | tr '\0' x; printf '\n'; i=1; while [ $i -le 60 ]; do printf '\n## p%s\n- authority: site\n' $i; i=$((i+1)); done; } > "$PROJ/PEOPLE.md"
printf 'sam\n' > "$PROJ/.claude/operator"; run
long=$(printf '%s\n' "$OUT" | awk '{ if (length($0) > m) m = length($0) } END { print m + 0 }')
expect "caps: lines cut at 300, people listed up to 50" has '^- \.\.\. and 10 more' has '^- @p50:' lacks '^- @p51:'
[ "$long" -le 320 ]; RC=$?; OUT=x
expect "caps: no printed line over 320 characters" has x

# 9. An empty operator file counts as none.
fresh; people <<'EOF'
## sam
- name: Sam Rivera
EOF
: > "$PROJ/.claude/operator"; run
expect "empty .claude/operator: the only person" has '^At the screen: @sam '

# 10. Malformed: broken frontmatter, CRLF, a fenced example, a bad heading,
#     a duplicate, a section with no keys, keys missing. Read what can be read.
fresh; printf -- '---\ntype: reference\r\n\r\n# People\r\n\r\n```\r\n## fake\r\n```\r\n\r\n## Ada Lovelace\r\n- name: x\r\n\r\n## sam\r\n- name: Sam\r\nfree text line\r\n\r\n## sam\r\n- name: Other\r\n\r\n## lee\r\n' > "$PROJ/PEOPLE.md"; run
expect "unterminated frontmatter: one notice line" has 'no readable person' lacks '@fake'
fresh; printf '# People\r\n\r\n```\r\n## fake\r\n```\r\n\r\n## Ada Lovelace\r\n- name: x\r\n\r\n## sam\r\n- name: Sam\r\nfree text line\r\n\r\n## sam\r\n- name: Other\r\n\r\n## lee\r\n' > "$PROJ/PEOPLE.md"; run
expect "malformed body: readable sections used, the rest named" has '^At the screen: unknown' has '^- @sam \(Sam\): authority \(not set\); admin \(not set\)' has '^- @lee: authority \(not set\)' has 'duplicate section\(s\) ignored.*sam' has 'not a handle.*"Ada Lovelace"' lacks 'fake' lacks 'Other'

# 11. Garbage and an empty file: no crash, exit 0.
fresh; head -c 2048 /dev/urandom > "$PROJ/PEOPLE.md" 2>/dev/null; run
expect "binary garbage: exit 0, no stderr" has '.|^$'
fresh; : > "$PROJ/PEOPLE.md"; run
expect "empty PEOPLE.md: one notice line" has 'no readable person'

# 12. Unreadable file: silence (fail open).
fresh; two_people; chmod 000 "$PROJ/PEOPLE.md"
if [ -r "$PROJ/PEOPLE.md" ]; then printf '  --  unreadable file skipped (running as root)\n'
else run; expect "unreadable PEOPLE.md: silent" empty x; fi
chmod 644 "$PROJ/PEOPLE.md" 2>/dev/null

# 13. Root from the payload's cwd when CLAUDE_PROJECT_DIR is not set (Codex).
fresh; two_people; printf 'sam\n' > "$PROJ/.claude/operator"
OUT=$(cd "$SANDBOX" && printf '{"session_id":"x","cwd":"%s","source":"startup"}' "$PROJ" | env -u CLAUDE_PROJECT_DIR bash "$WHOAMI" 2>"$SANDBOX/err"); RC=$?
expect "root from the payload cwd" has '^At the screen: @sam '

# 14. A missing root: silence.
OUT=$(CLAUDE_PROJECT_DIR="$SANDBOX/no/such/dir" bash "$WHOAMI" < /dev/null 2>"$SANDBOX/err"); RC=$?
expect "missing root: silent" empty x

# 15. Writes nothing.
fresh; two_people; before=$(cd "$PROJ" && find . | sort); run; after=$(cd "$PROJ" && find . | sort)
[ "$before" = "$after" ]; RC=$?; OUT=x
expect "writes nothing in the core" has x

printf '\n%d cases conform, %d deviate\n' "$ok" "$ko"
[ "$ko" -eq 0 ]
