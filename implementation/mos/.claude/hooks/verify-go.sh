#!/usr/bin/env bash
# verify-go.sh — checks the signature of a `go` instruction item (Spec §21), 0.13.
# The format and the check are frozen here so that a front desk (Manence UI, a
# bridge) can sign later without the guard changing; in 0.13 nothing calls it on
# its own: the guard opens on the admin GO said in the prompt (admin-go.sh), and a
# signed GO from a front desk is the next step.
#
# Usage: bash .claude/hooks/verify-go.sh <inbox item.md> [signers file]
#   exit 0 and "OK <auteur> <cible>" when the item is signed by a key listed for
#   its auteur, for the namespace manence-go, and its valable_jusqua has not passed;
#   exit 1 and the reason otherwise. Asks nothing.
#
# What is signed: the item's frontmatter fields, in this order, one "key: value"
# line each (an absent field is an empty value), with a final newline:
#   mos, work_id, geste, cible, perimetre, valable_jusqua, auteur
# The signature: `ssh-keygen -Y sign -n manence-go -f <private key>` over those
# lines, its armored body (the lines between BEGIN and END SSH SIGNATURE) joined
# into one line, in the field `signature:`. The public side: an allowed-signers
# file (default .claude/hooks/go-signers, rule 4 protects it), one line per signer:
#   <auteur> namespaces="manence-go" ssh-ed25519 AAAA…
# Only the signer holds a secret; the guard needs none. Where the private key
# lives (a file, a hardware key that asks for a touch) is the front desk's choice:
# options-go-delegable.md of the 0.13 workstream weighs them.
# What this check does NOT do, and its caller must: compare `mos` with the core it
# runs in (a GO signed for one MOS verifies anywhere), and keep a GO from being
# played twice within its date if it is meant for one use. It needs OpenSSH 8.1 or
# later (ssh-keygen -Y); an older one reads as "ssh-keygen too old".
set -u
ITEM=${1:-}; SIGNERS=${2:-"$(dirname -- "${BASH_SOURCE[0]}")/go-signers"}
fail() { echo "FAIL $*"; exit 1; }
[ -f "$ITEM" ] || fail "no such item: $ITEM"
[ -f "$SIGNERS" ] || fail "no signers file: $SIGNERS"
command -v ssh-keygen >/dev/null 2>&1 || fail "ssh-keygen not found"
ssh-keygen -Y 2>&1 | grep -qi 'requires an argument' || fail "ssh-keygen too old (no -Y: OpenSSH 8.1 or later)"

front() {  # the frontmatter value of one key (first match, quotes stripped)
  awk -v k="$1" 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit }
    NR > 1 { if (index($0, k ":") == 1) { v = substr($0, length(k) + 2); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      if (v ~ /^".*"$/ || v ~ /^'\''.*'\''$/) v = substr(v, 2, length(v) - 2); print v; exit } }' "$ITEM"
}
[ "$(front geste)" = go ] || fail "not a go item (geste: $(front geste))"
AUTEUR=$(front auteur); [ -n "$AUTEUR" ] || fail "no auteur"
SIG=$(front signature); [ -n "$SIG" ] || fail "not signed"
UNTIL=$(front valable_jusqua)
case "$UNTIL" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) fail "valable_jusqua missing or not YYYY-MM-DD" ;; esac
[ "$(date +%Y-%m-%d)" \> "$UNTIL" ] && fail "valable_jusqua $UNTIL has passed"

TMPD=$(mktemp -d "${TMPDIR:-/tmp}/verify-go.XXXXXX") || fail "no temporary directory"
trap 'rm -f "$TMPD"/payload "$TMPD"/sig; rmdir "$TMPD" 2>/dev/null' EXIT
for k in mos work_id geste cible perimetre valable_jusqua auteur; do
  printf '%s: %s\n' "$k" "$(front "$k")"
done > "$TMPD/payload"
{ echo "-----BEGIN SSH SIGNATURE-----"; printf '%s' "$SIG" | tr -d ' ' | fold -w 70; echo; echo "-----END SSH SIGNATURE-----"; } \
  | grep -v '^$' > "$TMPD/sig"
ssh-keygen -Y verify -f "$SIGNERS" -I "$AUTEUR" -n manence-go -s "$TMPD/sig" < "$TMPD/payload" >/dev/null 2>&1 \
  || fail "bad signature for $AUTEUR"
echo "OK $AUTEUR $(front cible)"
