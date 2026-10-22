#!/usr/bin/env bash
#
# upgrade.sh — bring an installed Manence OS up to a newer framework version.
#
# install.sh puts a MOS on disk once. This is the other half: a system that has
# been living for months, with its own skills, its own guard lines, its own
# knowledge, and a framework that has moved three versions ahead. The script
# carries the framework's changes in without carrying the system's work out.
#
# It reads two trees — the version you have, the version you want — and treats
# the files you have as the third side of a three-way merge, exactly as git
# does on a branch. Your local edits survive; the framework's edits arrive;
# where both touched the same line, the script stops and says so.
#
# Usage:
#   bash upgrade.sh <core-dir>                          # dry run: says everything, writes nothing
#   bash upgrade.sh <core-dir> --apply                  # writes
#   bash upgrade.sh <core-dir> --to v0.8.0 --apply
#   bash upgrade.sh <core-dir> --source ../manence --to HEAD
#   bash upgrade.sh <core-dir> --resolved --apply       # after resolving conflicts by hand
#
# Options:
#   --to <rev>            target version (default: the newest tag of the source)
#   --from <vX.Y.Z>       version you have (default: <core>/.claude/manence-version)
#   --source <dir|url>    where the target tree comes from (default: the public repo)
#   --from-source <dir>   where the *installed* version's tree comes from (default: --source)
#   --lang en|fr          language the core was installed in (default: detected);
#                         since 0.10 it only picks the merge BASE: the French
#                         set is retired, every core receives the English organs
#   --production <dir>    production root (default: <core>/.env, else <core>/../production)
#   --apply               write; without it nothing on disk changes
#   --resolved            the conflicts of a previous run were resolved by hand:
#                         a file whose merge still conflicts is taken as it
#                         stands, provided no <file>.upgrade-conflict is left
#                         beside it and it carries no conflict marker
#
# It never commits, never pushes, never deletes, and never touches your
# identity files, but for two declared gestures: the 0.15 move of instruction
# items out of inbox/, and the 0.16.1 rules appended to permissions.allow. See UPGRADING.md for what it leaves to your hands.
#
# Portable: bash 3.2+ (macOS default), Linux, Git Bash on Windows.
# Requires: git. Uses python3 when present for the JSON and frontmatter
# migrations; without it, it says which ones you must play by hand.
#
set -eu

SELF_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo ".")
MOS=implementation/mos
BASE_SKILLS="checkpoint close-work connect-adapter consignes kb-ingest kb-lint open-work outward-watch skill-craft upgrade weekly-review"
# Versions this script knows how to walk. Keep in sync with UPGRADING.md.
KNOWN_VERSIONS="0.5.0 0.5.1 0.6.0 0.6.1 0.6.2 0.7.0 0.8.0 0.8.1 0.8.2 0.8.3 0.9.0 0.10.0 0.11.0 0.12.0 0.13.0 0.13.1 0.14.0 0.14.1 0.15.0 0.16.0 0.16.1"
DEFAULT_REPO=${MANENCE_REPO:-https://github.com/manence/manence.git}

usage() {
  cat >&2 <<'EOF'
usage: upgrade.sh <core-dir> [options]

  --to <rev>            target version (default: newest tag of the source)
  --from <vX.Y.Z>       version installed (default: <core>/.claude/manence-version)
  --source <dir|url>    source of the target tree (default: the public repo)
  --from-source <dir>   source of the installed version's tree (default: --source)
  --lang en|fr          language the core was installed in (default: detected);
                        picks the merge base only — the target is always English
                        from 0.10 on (the French set is retired)
  --production <dir>    production root (default: <core>/.env, else <core>/../production)
  --apply               write (without it: dry run, nothing is written)
  --resolved            conflicts were resolved by hand: take a still-conflicting
                        file as it stands if no .upgrade-conflict file and no
                        conflict marker is left (then the stamp can be written)

  dry run first, then --apply. Nothing is ever committed: you reread and commit.
  See UPGRADING.md.
EOF
  exit 1
}

die() { echo "upgrade.sh: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------
CORE=""; TO_REV=""; FROM_VER=""; SOURCE=""; FROM_SOURCE=""; LANG_SET=""
PROD_OPT=""; APPLY=0; RESOLVED=0

while [ $# -gt 0 ]; do
  case $1 in
    -h|--help) usage ;;
    --apply) APPLY=1 ;;
    --resolved) RESOLVED=1 ;;
    --to) shift; [ $# -gt 0 ] || usage; TO_REV=$1 ;;
    --from) shift; [ $# -gt 0 ] || usage; FROM_VER=$1 ;;
    --source) shift; [ $# -gt 0 ] || usage; SOURCE=$1 ;;
    --from-source) shift; [ $# -gt 0 ] || usage; FROM_SOURCE=$1 ;;
    --lang) shift; [ $# -gt 0 ] || usage; LANG_SET=$1 ;;
    --production) shift; [ $# -gt 0 ] || usage; PROD_OPT=$1 ;;
    --) shift; break ;;
    -*) echo "upgrade.sh: unknown option: $1" >&2; usage ;;
    *) [ -z "$CORE" ] || { echo "upgrade.sh: unexpected argument: $1" >&2; usage; }; CORE=$1 ;;
  esac
  shift
done

[ -n "$CORE" ] || usage
case "${LANG_SET:-en}" in en|fr) ;; *) echo "upgrade.sh: --lang takes en or fr" >&2; usage ;; esac
command -v git >/dev/null 2>&1 || die "git is required."

case "$CORE" in
  "~")   CORE=${HOME} ;;
  "~/"*) CORE=${HOME}/${CORE#~/} ;;
esac
[ -d "$CORE" ] || die "no such directory: $CORE"
CORE=$(cd -- "$CORE" && pwd)
[ -d "$CORE/.claude" ] || die "$CORE does not look like a MOS core (no .claude/)."
[ -f "$CORE/AGENTS.md" ] || [ -f "$CORE/CLAUDE.md" ] \
  || die "$CORE does not look like a MOS core (no AGENTS.md, no CLAUDE.md)."

TMP=$(mktemp -d "${TMPDIR:-/tmp}/manence-upgrade.XXXXXX")
cleanup() { [ -n "${TMP:-}" ] && [ -d "$TMP" ] && rm -rf "$TMP"; }
trap cleanup EXIT HUP INT TERM
: > "$TMP/empty"

PY=""
if command -v python3 >/dev/null 2>&1 && python3 -c 'pass' >/dev/null 2>&1; then PY=python3; fi

# ---------------------------------------------------------------------------
# Versions. A key like 000008000 so that plain string comparison orders them.
# ---------------------------------------------------------------------------
is_version() {
  case ${1#v} in
    ''|*[!0-9.]*) return 1 ;;
    *.*.*) return 0 ;;
    *) return 1 ;;
  esac
}

ver_key() {
  if ! is_version "$1"; then printf '000000000'; return 0; fi
  _v=${1#v}
  _a=${_v%%.*}; _r=${_v#*.}; _b=${_r%%.*}; _c=${_r#*.}; _c=${_c%%[!0-9]*}
  printf '%03d%03d%03d' "${_a:-0}" "${_b:-0}" "${_c:-0}"
}

# ---------------------------------------------------------------------------
# Sources: a local clone (the public repo or the atelier) or a git URL.
# A URL is cloned bare-ish into the temp dir; nothing is written outside it.
# ---------------------------------------------------------------------------
CLONE_N=0
prepare_repo() {
  _spec=$1
  if [ -d "$_spec" ]; then
    _abs=$(cd -- "$_spec" && pwd)
    git -C "$_abs" rev-parse --git-dir >/dev/null 2>&1 \
      || die "$_abs is not a git repository (--source wants a clone or a git URL)."
    echo "$_abs"
    return 0
  fi
  case "$_spec" in
    *://*|*@*:*) ;;
    *) die "no such directory and not a git URL: $_spec" ;;
  esac
  CLONE_N=$((CLONE_N + 1))
  _dest=$TMP/clone-$CLONE_N
  echo "upgrade.sh: fetching ${_spec}…" >&2
  git clone --quiet --no-checkout "$_spec" "$_dest" >&2 \
    || die "could not clone $_spec"
  echo "$_dest"
}

resolve_rev() {  # repo rev -> commit sha, or empty
  _repo=$1; _rev=$2
  for _cand in "$_rev" "v${_rev#v}" "${_rev#v}"; do
    _sha=$(git -C "$_repo" rev-parse --verify --quiet "$_cand^{commit}" 2>/dev/null || true)
    [ -n "$_sha" ] && { echo "$_sha"; return 0; }
  done
  return 1
}

latest_tag() {  # repo -> newest vX.Y.Z tag
  _best=""; _bestk=""
  for _t in $(git -C "$1" tag --list 'v[0-9]*' 2>/dev/null); do
    is_version "$_t" || continue
    _k=$(ver_key "$_t")
    if [ -z "$_bestk" ] || [ "$_k" \> "$_bestk" ]; then _best=$_t; _bestk=$_k; fi
  done
  [ -n "$_best" ] || return 1
  echo "$_best"
}

materialize() {  # repo rev destdir — lay down implementation/mos of that revision
  _repo=$1; _rev=$2; _dest=$3
  mkdir -p "$_dest"
  git -C "$_repo" archive --format=tar "$_rev" "$MOS" 2>/dev/null | (cd "$_dest" && tar -xf -) \
    || die "revision $_rev of $_repo carries no $MOS/ — wrong repository?"
  [ -d "$_dest/$MOS" ] || die "revision $_rev of $_repo carries no $MOS/ — wrong repository?"
}

[ -n "$SOURCE" ] || SOURCE=$DEFAULT_REPO
SRC_REPO=$(prepare_repo "$SOURCE")
if [ -n "$FROM_SOURCE" ]; then
  FROM_REPO=$(prepare_repo "$FROM_SOURCE")
else
  FROM_REPO=$SRC_REPO; FROM_SOURCE=$SOURCE
fi

# The version installed: the stamp, unless told otherwise.
FROM_ORIGIN="--from"
if [ -z "$FROM_VER" ]; then
  if [ -f "$CORE/.claude/manence-version" ]; then
    FROM_VER=$(tr -d ' \t\r\n' < "$CORE/.claude/manence-version")
    FROM_ORIGIN="stamp"
  fi
fi
[ -n "$FROM_VER" ] || die "no .claude/manence-version in this core (install predates 0.5.0): pass --from vX.Y.Z."

# The target: the newest tag, unless told otherwise.
TO_ORIGIN="--to"
if [ -z "$TO_REV" ]; then
  TO_REV=$(latest_tag "$SRC_REPO") || die "no vX.Y.Z tag in $SOURCE: pass --to."
  TO_ORIGIN="newest tag"
fi

FROM_SHA=$(resolve_rev "$FROM_REPO" "$FROM_VER") \
  || die "revision $FROM_VER not found in $FROM_SOURCE (pass --from-source pointing at a clone that has the tag)."
TO_SHA=$(resolve_rev "$SRC_REPO" "$TO_REV") \
  || die "revision $TO_REV not found in $SOURCE."

FROM_DIR=$TMP/from; TO_DIR=$TMP/to
materialize "$FROM_REPO" "$FROM_SHA" "$FROM_DIR"
materialize "$SRC_REPO" "$TO_SHA" "$TO_DIR"

TO_IS_VERSION=0
is_version "$TO_REV" && TO_IS_VERSION=1

# ---------------------------------------------------------------------------
# Language. A French core was installed from implementation/mos/fr/; the giveaway
# is structural (templates/chantier) before it is textual.
#
# Since 0.10 the French set is retired: every core receives the English organs,
# and its working language stays its own (AGENTS.md). The language now picks one
# thing, the merge BASE: a French core's organs descend from the French set of
# the version it has. A target that still ships fr/ (0.9 and older) is merged
# French to French as before; a target without it, from a French base, is the
# switch — handled file by file below, never merged across languages.
# ---------------------------------------------------------------------------
LANG_WHY=""
if [ -n "$LANG_SET" ]; then
  LANG_WHY="--lang"
else
  _fr=0; _en=0; _seen=""
  [ -d "$CORE/templates/chantier" ] && { _fr=$((_fr + 2)); _seen="templates/chantier"; }
  [ -d "$CORE/templates/workstream" ] && { _en=$((_en + 2)); _seen="templates/workstream"; }
  for _f in "$CORE/AGENTS.md" "$CORE/CLAUDE.md"; do
    [ -f "$_f" ] || continue
    _n=$(grep -c -i -e 'langue de travail' -e 'français' -e 'francais' \
                    -e 'Au démarrage de session' -e 'Où va chaque chose' \
                    -e 'un \*\*chantier\*\*' "$_f" 2>/dev/null || true)
    _fr=$((_fr + _n))
    _n=$(grep -c -i -e 'working language' -e 'At the start of a session' \
                    -e 'Where each thing goes' -e 'a \*\*workstream\*\*' "$_f" 2>/dev/null || true)
    _en=$((_en + _n))
  done
  if [ "$_fr" -gt "$_en" ]; then LANG_SET=fr; else LANG_SET=en; fi
  LANG_WHY="detected: fr $_fr / en $_en${_seen:+, $_seen}"
fi

# Target set: what the new version ships. Base set: what the core descends from.
SK_SRC=$MOS/.claude/skills; TPL_SRC=$MOS/templates
BASE_SK=$MOS/.claude/skills; BASE_TPL=$MOS/templates
SWITCH=0; ORGANS_WHY="English"
if [ "$LANG_SET" = fr ]; then
  if [ -d "$TO_DIR/$MOS/fr" ]; then
    SK_SRC=$MOS/fr/skills; TPL_SRC=$MOS/fr/templates; ORGANS_WHY="French (the target still ships fr/)"
  fi
  if [ -d "$FROM_DIR/$MOS/fr" ]; then
    BASE_SK=$MOS/fr/skills; BASE_TPL=$MOS/fr/templates
    [ -d "$TO_DIR/$MOS/fr" ] || { SWITCH=1; ORGANS_WHY="English — this core moves from the French set, retired in 0.10"; }
  fi
fi

# ---------------------------------------------------------------------------
# Production root — where the workstreams live (outside git, at the container).
# ---------------------------------------------------------------------------
PROD=""
if [ -n "$PROD_OPT" ]; then
  PROD=$PROD_OPT; PROD_WHY="--production"
elif [ -f "$CORE/.env" ]; then
  # Only the one variable is read; the rest of .env is none of our business.
  _line=$(grep -E '^[A-Za-z0-9_]*PRODUCTION_ROOT=' "$CORE/.env" 2>/dev/null | head -1 || true)
  _val=${_line#*=}
  _val=$(printf '%s' "$_val" | tr -d '"' | tr -d "'")
  if [ -n "$_val" ]; then PROD=$_val; PROD_WHY=".env"; fi
fi
if [ -z "$PROD" ]; then PROD=$CORE/../production; PROD_WHY="default"; fi
case "$PROD" in
  /*) ;;
  "~/"*) PROD=${HOME}/${PROD#~/} ;;
  *) PROD=$CORE/$PROD ;;
esac
[ -d "$PROD" ] && PROD=$(cd -- "$PROD" && pwd)

# ---------------------------------------------------------------------------
# UPGRADING.md — the human half of an upgrade, one block per version.
# ---------------------------------------------------------------------------
UPGRADING=""; UPGRADING_WHY=""
if git -C "$SRC_REPO" cat-file -e "$TO_SHA:UPGRADING.md" 2>/dev/null; then
  git -C "$SRC_REPO" show "$TO_SHA:UPGRADING.md" > "$TMP/UPGRADING.md" 2>/dev/null \
    && { UPGRADING=$TMP/UPGRADING.md; UPGRADING_WHY="$TO_REV of the source"; }
fi
if [ -z "$UPGRADING" ] && [ -f "$SRC_REPO/UPGRADING.md" ]; then
  UPGRADING=$SRC_REPO/UPGRADING.md; UPGRADING_WHY="working tree of the source"
fi
if [ -z "$UPGRADING" ] && [ -f "$SELF_DIR/UPGRADING.md" ]; then
  UPGRADING=$SELF_DIR/UPGRADING.md; UPGRADING_WHY="next to this script"
fi

manual_block() {  # version -> the bullet lines of its manual block
  [ -n "$UPGRADING" ] || return 0
  awk -v v="$1" '
    $0 == "<!-- manual v" v " -->" { on = 1; next }
    on && $0 == "<!-- /manual -->" { on = 0 }
    on { print }
  ' "$UPGRADING" | sed '/^[[:space:]]*$/d'
}

# Versions to walk: everything strictly after the installed one, up to the target.
# When the starting point is not a released version (--from HEAD, a branch), there
# is no list to walk: migrations and manual touches are keyed to released versions.
VERSIONS=""; VERSIONS_NOTE=""
if is_version "$FROM_VER"; then
  FROM_KEY=$(ver_key "$FROM_VER")
  for v in $KNOWN_VERSIONS; do
    k=$(ver_key "$v")
    [ "$k" \> "$FROM_KEY" ] || continue
    if [ "$TO_IS_VERSION" -eq 1 ]; then
      TO_KEY=$(ver_key "$TO_REV")
      if [ "$k" \> "$TO_KEY" ]; then continue; fi
    fi
    VERSIONS="$VERSIONS $v"
  done
  VERSIONS=${VERSIONS# }
  [ -n "$VERSIONS" ] || VERSIONS_NOTE="none — already at the target"
else
  VERSIONS_NOTE="none — $FROM_VER is not a released version, so no version is walked over"
fi

# ---------------------------------------------------------------------------
# The report header
# ---------------------------------------------------------------------------
if [ "$APPLY" -eq 1 ]; then MODE="apply (files are written; nothing is committed)"
else MODE="dry run (nothing is written; add --apply to write)"; fi

echo
echo "upgrade.sh — a Manence OS in place"
echo
printf '  core          %s\n' "$CORE"
printf '  language      %s (%s)\n' "$LANG_SET" "$LANG_WHY"
printf '  organs        %s\n' "$ORGANS_WHY"
printf '  production    %s (%s)\n' "$PROD" "$PROD_WHY"
printf '  from          %s (%s) — %s\n' "$FROM_VER" "$FROM_ORIGIN" "$FROM_SOURCE"
printf '  to            %s (%s) — %s\n' "$TO_REV" "$TO_ORIGIN" "$SOURCE"
printf "  versions      %s\n" "${VERSIONS:-$VERSIONS_NOTE}"
printf '  UPGRADING.md  %s\n' "${UPGRADING_WHY:-not found (manual touches will not be listed)}"
printf '  mode          %s\n' "$MODE"
[ "$RESOLVED" -eq 1 ] && printf '  resolved      --resolved: conflicts resolved by hand are taken as they stand\n'
echo

# ---------------------------------------------------------------------------
# The organ table. Class (a), mechanical: merged three ways, base = the version
# you have. Built from the *target* tree: what the new version ships.
# ---------------------------------------------------------------------------
TABLE=$TMP/organs.tsv
: > "$TABLE"
TAB=$(printf '\t')

# Three columns: path in the core, path in the target tree, path in the base tree.
add_organ() { printf '%s\t%s\t%s\n' "$1" "$2" "$2" >> "$TABLE"; }

# Hooks exist in one language only: never part of the switch.
add_organ ".claude/hooks/guard.sh" "$MOS/.claude/hooks/guard.sh"
add_organ ".claude/hooks/lint.sh"  "$MOS/.claude/hooks/lint.sh"
add_organ ".claude/hooks/consignes.sh" "$MOS/.claude/hooks/consignes.sh"
add_organ ".claude/hooks/test-guard.sh" "$MOS/.claude/hooks/test-guard.sh"
add_organ ".claude/hooks/since-last-session.sh" "$MOS/.claude/hooks/since-last-session.sh"
add_organ ".claude/hooks/admin-go.sh" "$MOS/.claude/hooks/admin-go.sh"
add_organ ".claude/hooks/verify-go.sh" "$MOS/.claude/hooks/verify-go.sh"
add_organ ".claude/hooks/whoami.sh" "$MOS/.claude/hooks/whoami.sh"
add_organ ".claude/hooks/test-whoami.sh" "$MOS/.claude/hooks/test-whoami.sh"
# The framework's own script in the core's scripts/ (0.12): the log rotation.
add_organ "scripts/log-rotate.py" "$MOS/scripts/log-rotate.py"

if [ -d "$TO_DIR/$TPL_SRC" ]; then
  (cd "$TO_DIR/$TPL_SRC" && find . -type f ! -name '.DS_Store' | sed 's|^\./||' | sort) \
  | while IFS= read -r f; do
      [ -n "$f" ] || continue
      printf 'templates/%s\t%s/%s\t%s/%s\n' "$f" "$TPL_SRC" "$f" "$BASE_TPL" "$f" >> "$TABLE"
    done
fi

for s in $BASE_SKILLS; do
  [ -d "$TO_DIR/$SK_SRC/$s" ] || continue
  (cd "$TO_DIR/$SK_SRC/$s" && find . -type f ! -name '.DS_Store' | sed 's|^\./||' | sort) \
  | while IFS= read -r f; do
      [ -n "$f" ] || continue
      printf '.claude/skills/%s/%s\t%s/%s/%s\t%s/%s/%s\n' "$s" "$f" "$SK_SRC" "$s" "$f" "$BASE_SK" "$s" "$f" >> "$TABLE"
    done
done

N_MERGED=0; N_REPLACED=0; N_CREATED=0; N_SAME=0; N_CONFLICT=0; N_SKIPPED=0
N_MIGRATED=0; N_MANUAL=0; N_RESOLVED=0; N_DIVERGES=0

report() { printf '  %-14s %s\n' "$1" "$2"; }

CORE_REAL=$(cd -- "$CORE" && pwd -P)
inside_core() {  # does this path's real parent still sit under the core?
  _d=$(dirname -- "$1")
  while [ ! -d "$_d" ] && [ "$_d" != "/" ] && [ "$_d" != "." ]; do _d=$(dirname -- "$_d"); done
  _r=$(cd -- "$_d" 2>/dev/null && pwd -P) || return 1
  case "$_r" in "$CORE_REAL"|"$CORE_REAL"/*) return 0 ;; *) return 1 ;; esac
}

write_file() {  # src dest — only under --apply
  [ "$APPLY" -eq 1 ] || return 0
  inside_core "$2" || die "refusing to write outside the core: $2"
  mkdir -p "$(dirname -- "$2")"
  cat "$1" > "$2"
  case "$2" in *.sh) chmod +x "$2" 2>/dev/null || true ;; esac
}

# After a hand resolution the merge cannot tell a resolved conflict from an
# unresolved one: the base is still the version you had, and a local change kept
# inside a hunk the new version also changed conflicts again. --resolved is the
# human saying "I resolved it"; this is the check that the saying holds.
# Prints why not, or nothing when the file reads resolved.
unresolved_why() {  # localf
  if [ -e "$1.upgrade-conflict" ]; then
    echo "$(basename -- "$1").upgrade-conflict is still there"
  elif grep -qE '^(<<<<<<<|>>>>>>>)( |$)' "$1" 2>/dev/null; then
    echo "conflict markers are still in the file"
  fi
}

echo "Mechanical organs — hooks, templates, the eleven base skills, scripts/log-rotate.py"
echo "  (three-way merged: your file, the version you have, the new version)"

if [ ! -s "$TABLE" ]; then
  report "—" "nothing shipped at $TO_REV (wrong --source?)"
fi

while IFS="$TAB" read -r corepath srcrel baserel; do
  [ -n "$corepath" ] || continue
  localf=$CORE/$corepath
  tof=$TO_DIR/$srcrel
  fromf=$FROM_DIR/${baserel:-$srcrel}
  switched=0
  [ "$SWITCH" -eq 1 ] && [ "$srcrel" != "${baserel:-$srcrel}" ] && switched=1
  [ -f "$tof" ] || continue

  if [ -L "$localf" ]; then
    report "SKIPPED" "$corepath — a symlink; upgrade.sh never follows one"
    N_SKIPPED=$((N_SKIPPED + 1)); continue
  fi

  if [ ! -e "$localf" ]; then
    write_file "$tof" "$localf"
    report "created" "$corepath"
    N_CREATED=$((N_CREATED + 1)); continue
  fi

  # A conflict file from the French-to-English switch holds this core's edits,
  # not yet re-applied: the English file in place does not make it up to date.
  if [ "$switched" -eq 1 ] && [ -e "$localf.upgrade-conflict" ]; then
    report "CONFLICT" "$corepath — this core's French edits wait in $corepath.upgrade-conflict: re-apply them by hand in English, remove that file, then rerun with --resolved"
    N_CONFLICT=$((N_CONFLICT + 1)); continue
  fi

  if cmp -s "$localf" "$tof"; then
    report "up to date" "$corepath"
    N_SAME=$((N_SAME + 1)); continue
  fi

  if [ -f "$fromf" ] && cmp -s "$fromf" "$tof"; then
    # The new version leaves this organ as it was, and yours differs from it: a
    # local edit, or a local prototype an earlier upgrade kept (incident of
    # 2026-09-28: "yours stands" hid a prototype of a skill the framework had
    # since shipped). Nothing is written; the difference is named every time.
    case "$corepath" in
      .claude/skills/*) hint="a local edit, or the prototype of a skill the framework has since shipped" ;;
      *)                hint="a local edit" ;;
    esac
    report "diverges" "$corepath — the new version doesn't change it, but yours differs from the shipped one ($hint): kept as it is; compare, then keep it, upstream it, or take the shipped one"
    N_DIVERGES=$((N_DIVERGES + 1)); continue
  fi

  if [ -f "$fromf" ] && cmp -s "$localf" "$fromf"; then
    write_file "$tof" "$localf"
    if [ "$switched" -eq 1 ]; then
      report "replaced" "$corepath — moved to the English organ (no local change to the French one)"
    else
      report "replaced" "$corepath — no local change"
    fi
    N_REPLACED=$((N_REPLACED + 1)); continue
  fi

  # The switch with local edits: a merge from a French base to an English target
  # conflicts on every line, so it is not attempted. The English organ lands; the
  # local file, French edits and all, waits beside it as the conflict file. A
  # conflict file already there holds those edits: it is never overwritten.
  if [ "$switched" -eq 1 ] && [ -f "$fromf" ]; then
    if [ "$RESOLVED" -eq 1 ] && [ -z "$(unresolved_why "$localf")" ]; then
      report "resolved" "$corepath — your edits re-applied in English, kept as it stands (--resolved: no conflict file, no marker)"
      N_RESOLVED=$((N_RESOLVED + 1)); continue
    fi
    write_file "$localf" "$localf.upgrade-conflict"
    write_file "$tof" "$localf"
    report "CONFLICT" "$corepath — this core's local edits to it were written in French; the organ is now English: the English file is in place, yours waits in $corepath.upgrade-conflict — re-apply them by hand in English, then rerun with --resolved"
    N_CONFLICT=$((N_CONFLICT + 1)); continue
  fi

  # The case with no common ancestor: the framework ships this file for the
  # first time, and the system already grew one of its own under that name — a
  # local skill written before the framework had one (it happens: a good skill
  # is born in one system and harvested into the framework later). There is no
  # base to merge against, and the local file was nobody's copy of ours, so it
  # is never overwritten and never merged in silence: the two versions are laid
  # side by side, and a human decides what the name should mean here.
  predates=0
  base=$fromf; basenote=""
  if [ ! -f "$fromf" ]; then
    base=$TMP/empty
    basenote=" — the framework shipped no such file at $FROM_VER"
    predates=1
  fi

  set +e
  git merge-file -p \
      -L "yours ($corepath)" -L "$FROM_VER (base)" -L "$TO_REV (new)" \
      "$localf" "$base" "$tof" > "$TMP/merge.out" 2>"$TMP/merge.err"
  rc=$?
  set -e

  why=""
  if [ "$RESOLVED" -eq 1 ] && [ "$rc" -gt 0 ] && [ "$rc" -lt 128 ]; then
    why=$(unresolved_why "$localf")
    if [ -z "$why" ]; then
      report "resolved" "$corepath — resolved by hand, kept as it stands (--resolved: no conflict file, no marker)"
      N_RESOLVED=$((N_RESOLVED + 1)); continue
    fi
    why=" (--resolved refused: $why)"
  fi

  if [ "$predates" -eq 1 ] && [ "$rc" -lt 128 ]; then
    case "$corepath" in
      .claude/skills/*) what="local skill" ;;
      *)                what="local file" ;;
    esac
    # The file beside yours is the shipped organ itself, byte for byte: a merge
    # against an empty base is nothing but conflict markers, and a conflict file
    # taken at its word ("the framework's version") once broke a core's test suite
    # behind a guard that then refused the repair (2026-10-05, two cores).
    write_file "$tof" "$localf.upgrade-conflict"
    report "CONFLICT" "$corepath ($what predates the shipped one) — yours untouched; the framework's version waits beside it in $corepath.upgrade-conflict$basenote$why"
    N_CONFLICT=$((N_CONFLICT + 1))
  elif [ "$rc" -eq 0 ]; then
    write_file "$TMP/merge.out" "$localf"
    report "merged" "$corepath — your edits kept"
    N_MERGED=$((N_MERGED + 1))
  elif [ "$rc" -gt 0 ] && [ "$rc" -lt 128 ]; then
    write_file "$TMP/merge.out" "$localf.upgrade-conflict"
    report "CONFLICT" "$corepath — $rc hunk(s); resolve by hand in $corepath.upgrade-conflict$basenote$why"
    N_CONFLICT=$((N_CONFLICT + 1))
  else
    report "ERROR" "$corepath — git merge-file failed: $(head -1 "$TMP/merge.err" 2>/dev/null)"
    N_SKIPPED=$((N_SKIPPED + 1))
  fi
done < "$TABLE"

if [ -e "$CORE/.claude/mos.json" ] || [ -e "$CORE/.claude/mos-map.json" ]; then
  report "migration" ".claude/mos.json — your declaration; only the migrations below touch it"
else
  if [ -f "$TO_DIR/$MOS/.claude/mos.json" ]; then
    write_file "$TO_DIR/$MOS/.claude/mos.json" "$CORE/.claude/mos.json"
    report "created" ".claude/mos.json"
    N_CREATED=$((N_CREATED + 1))
  fi
fi

# Skills this system grew on its own are its own business.
EXTRA=""
if [ -d "$CORE/.claude/skills" ]; then
  for d in "$CORE"/.claude/skills/*/; do
    [ -d "$d" ] || continue
    n=$(basename -- "$d")
    case " $BASE_SKILLS mos-map " in *" $n "*) continue ;; esac
    EXTRA="$EXTRA $n"
  done
fi
[ -n "$EXTRA" ] && { echo; report "untouched" "skills of your own:$EXTRA"; }
if [ "$SWITCH" -eq 1 ] && [ -d "$CORE/templates/chantier" ]; then
  report "left" "templates/chantier/ — the French workstream template is no longer shipped (templates/workstream/ replaces it); yours until you remove it"
fi

# ---------------------------------------------------------------------------
# Class (b), identity: never touched. Named so the silence is explicit.
# ---------------------------------------------------------------------------
echo
echo "Identity organs — never touched by this script"
for f in AGENTS.md CLAUDE.md CLAUDE.local.md PEOPLE.md SOUL.md STRATEGY.md .claude/settings.json \
         .env .env.example log.md knowledge-base inbox consignes; do
  [ -e "$CORE/$f" ] || continue
  if [ "$f" = .claude/settings.json ]; then
    report "yours" "$f (one additive gesture since 0.16.1: the shipped permissions.allow rules it lacks, under Declared migrations)"
  else
    report "yours" "$f"
  fi
done
report "yours" "everything else the core holds (brand/, scripts/, your own skills…)"

# The guard's local rules (0.13): a file of the core's own, never merged, never
# written. Said every time, so that "does this core have local guard rules?" has
# an answer; and when guard.sh itself still carries local edits, where they go.
if [ -f "$CORE/.claude/hooks/guard.local.sh" ]; then
  _lift=$(sed -n "s/^[[:space:]]*GUARD_LIFT=[\"']\{0,1\}\([^\"'#]*\).*/\1/p" "$CORE/.claude/hooks/guard.local.sh" | tail -1 | sed 's/[[:space:]]*$//')
  report "local guard" ".claude/hooks/guard.local.sh — your guard rules, never touched (lifts: ${_lift:-none})"
  [ -f "$CORE/.claude/hooks/test-guard.local.sh" ] \
    && report "local guard" ".claude/hooks/test-guard.local.sh — its cases, played by test-guard.sh" \
    || report "local guard" "no .claude/hooks/test-guard.local.sh — your local rules have no cases of their own"
else
  report "local guard" "none (.claude/hooks/guard.local.sh absent)"
fi
_gl=$CORE/.claude/hooks/guard.sh; _gb=$FROM_DIR/$MOS/.claude/hooks/guard.sh
if [ -f "$_gl" ] && [ -f "$_gb" ] && ! cmp -s "$_gl" "$_gb" && ! cmp -s "$_gl" "$TO_DIR/$MOS/.claude/hooks/guard.sh"; then
  if grep -q 'guard.local.sh' "$TO_DIR/$MOS/.claude/hooks/guard.sh" 2>/dev/null; then
    report "hint" ".claude/hooks/guard.sh differs from the shipped organ: move your rules into .claude/hooks/guard.local.sh and take the shipped guard.sh as it is (UPGRADING, 0.13.0)"
  fi
fi

# ---------------------------------------------------------------------------
# Class (c), declared migrations — in version order, each idempotent.
# ---------------------------------------------------------------------------
mos_json_file() {
  if [ -f "$CORE/.claude/mos.json" ]; then echo "$CORE/.claude/mos.json"
  elif [ -f "$CORE/.claude/mos-map.json" ]; then echo "$CORE/.claude/mos-map.json"
  else echo ""; fi
}

py_mos_json() {  # file apply -> prints one line of verdict, exit 0
  "$PY" - "$1" "$2" <<'PYEOF'
import json, sys, collections
path, apply_s = sys.argv[1], sys.argv[2]
apply_it = apply_s == "1"
try:
    with open(path, encoding="utf-8") as fh:
        doc = json.load(fh, object_pairs_hook=collections.OrderedDict)
except Exception as exc:                      # a hand-edited file that no longer parses
    print("ERROR: %s is not valid JSON (%s) — by hand" % (path, exc))
    sys.exit(3)
changes = []
schema = doc.get("schema")
if not isinstance(schema, int) or schema < 3:
    doc["schema"] = 3
    changes.append("schema %s -> 3" % schema)
routines = doc.get("routines")
n = 0
if isinstance(routines, list):
    for i, r in enumerate(routines):
        if not isinstance(r, dict) or "proof_glob" in r:
            continue
        new = collections.OrderedDict()
        for k, v in r.items():
            new[k] = v
            if k == "etat":
                new["proof_glob"] = ""
        if "proof_glob" not in new:
            new["proof_glob"] = ""
        routines[i] = new
        n += 1
    if n:
        changes.append("proof_glob added to %d routine(s), left empty for you to fill" % n)
if not changes:
    print("nothing to do (schema 3, every routine carries its proof)")
    sys.exit(0)
if apply_it:
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(doc, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    print("done: " + "; ".join(changes))
else:
    print("would do: " + "; ".join(changes))
sys.exit(0)
PYEOF
}

py_awaiting() {  # apply prod -> prints "<touched> <scanned>"
  "$PY" - "$1" "$2" <<'PYEOF'
import glob, os, sys
apply_it, prod = sys.argv[1] == "1", sys.argv[2]
touched = scanned = 0
for about in sorted(glob.glob(os.path.join(prod, "*", "in-progress", "*", "About.md"))):
    try:
        with open(about, encoding="utf-8") as fh:
            lines = fh.readlines()
    except Exception:
        continue
    if not lines or lines[0].rstrip("\n").strip() != "---":
        continue                                   # no frontmatter: not ours to rewrite
    end = None
    for i in range(1, len(lines)):
        if lines[i].rstrip("\n").strip() == "---":
            end = i
            break
    if end is None:
        continue
    scanned += 1
    front = lines[1:end]
    if any(l.startswith("awaiting:") for l in front):
        continue
    at = None
    for i, l in enumerate(front):
        if l.startswith("status:"):
            at = i + 1
            break
    if at is None:
        at = len(front)                            # no status: the field still lands in the frontmatter
    entry = "awaiting: []   # who / what / kind (decision | action) / since\n"
    new = lines[:1] + front[:at] + [entry] + front[at:] + lines[end:]
    touched += 1
    if apply_it:
        with open(about, "w", encoding="utf-8") as fh:
            fh.writelines(new)
print("%d %d" % (touched, scanned))
PYEOF
}

migrate_0_8() {
  # 1. The map's declaration loses its cartographic name.
  if [ -f "$CORE/.claude/mos-map.json" ] && [ ! -e "$CORE/.claude/mos.json" ]; then
    if [ "$APPLY" -eq 1 ]; then
      if git -C "$CORE" rev-parse --git-dir >/dev/null 2>&1 \
         && git -C "$CORE" ls-files --error-unmatch ".claude/mos-map.json" >/dev/null 2>&1; then
        git -C "$CORE" mv ".claude/mos-map.json" ".claude/mos.json"
        report "migrated" "v0.8.0  .claude/mos-map.json -> .claude/mos.json (git mv)"
      else
        mv "$CORE/.claude/mos-map.json" "$CORE/.claude/mos.json"
        report "migrated" "v0.8.0  .claude/mos-map.json -> .claude/mos.json (mv)"
      fi
    else
      report "would do" "v0.8.0  .claude/mos-map.json -> .claude/mos.json"
    fi
    N_MIGRATED=$((N_MIGRATED + 1))
  elif [ -f "$CORE/.claude/mos.json" ] && [ -f "$CORE/.claude/mos-map.json" ]; then
    report "MANUAL" "v0.8.0  both .claude/mos.json and .claude/mos-map.json exist — merge them by hand"
    N_MANUAL=$((N_MANUAL + 1))
  else
    report "nothing" "v0.8.0  .claude/mos.json already named right"
  fi

  # 2. Schema 3: each routine says where the proof of its running lands.
  mj=$(mos_json_file)
  if [ -z "$mj" ]; then
    report "nothing" "v0.8.0  no .claude/mos.json to bring to schema 3"
  elif [ -z "$PY" ]; then
    report "MANUAL" "v0.8.0  no python3: set \"schema\": 3 and add an empty \"proof_glob\" per routine by hand"
    N_MANUAL=$((N_MANUAL + 1))
  else
    set +e
    out=$(py_mos_json "$mj" "$APPLY"); prc=$?
    set -e
    if [ "$APPLY" -eq 1 ]; then w=migrated; else w="would do"; fi
    case "$out" in
      "nothing to do"*) report "nothing" "v0.8.0  .claude/mos.json — $out" ;;
      ERROR*) report "MANUAL" "v0.8.0  $out"; N_MANUAL=$((N_MANUAL + 1)) ;;
      *) o=${out#would do: }; o=${o#done: }
         report "$w" "v0.8.0  .claude/mos.json — $o"; N_MIGRATED=$((N_MIGRATED + 1)) ;;
    esac
    [ "$prc" -eq 0 ] || true
  fi

  # 3. The mos-map skill retires. Nothing is deleted: it is set aside.
  if [ -d "$CORE/.claude/skills/mos-map" ]; then
    dest=$CORE/.upgrade-removed/.claude/skills/mos-map
    if [ -e "$dest" ]; then
      report "MANUAL" "v0.8.0  .upgrade-removed/.claude/skills/mos-map already there, and the skill is back — by hand"
      N_MANUAL=$((N_MANUAL + 1))
    elif [ "$APPLY" -eq 1 ]; then
      if git -C "$CORE" rev-parse --git-dir >/dev/null 2>&1; then
        git -C "$CORE" rm -r --cached --quiet ".claude/skills/mos-map" >/dev/null 2>&1 || true
      fi
      mkdir -p "$(dirname -- "$dest")"
      mv "$CORE/.claude/skills/mos-map" "$dest"
      report "migrated" "v0.8.0  skill mos-map -> .upgrade-removed/.claude/skills/mos-map (kept, not deleted)"
      N_MIGRATED=$((N_MIGRATED + 1))
    else
      report "would do" "v0.8.0  skill mos-map -> .upgrade-removed/.claude/skills/mos-map (kept, not deleted)"
      N_MIGRATED=$((N_MIGRATED + 1))
    fi
  else
    report "nothing" "v0.8.0  no mos-map skill to retire"
  fi

  # 4. A workstream says in its frontmatter what waits for a human.
  if [ ! -d "$PROD" ]; then
    report "nothing" "v0.8.0  no production at $PROD — no About.md to fit with awaiting"
  elif [ -z "$PY" ]; then
    report "MANUAL" "v0.8.0  no python3: add 'awaiting: []' under 'status:' in each in-progress About.md by hand"
    N_MANUAL=$((N_MANUAL + 1))
  else
    set +e
    res=$(py_awaiting "$APPLY" "$PROD"); arc=$?
    set -e
    if [ "$arc" -ne 0 ]; then
      report "MANUAL" "v0.8.0  could not read the production at $PROD — by hand"
      N_MANUAL=$((N_MANUAL + 1))
    else
      touched=${res%% *}; scanned=${res##* }
      if [ "$touched" -eq 0 ]; then
        report "nothing" "v0.8.0  awaiting — $scanned in-progress About.md, all of them already carry the field"
      else
        if [ "$APPLY" -eq 1 ]; then w="migrated"; else w="would do"; fi
        report "$w" "v0.8.0  awaiting: [] into $touched of $scanned in-progress About.md"
        report "read it" "v0.8.0  an empty awaiting is a claim: reread each workstream and write the real waits"
        N_MIGRATED=$((N_MIGRATED + 1))
      fi
    fi
  fi
}

# Nothing to play before 0.8.0: what those versions changed is either mechanical
# (merged above) or a retouch of the identity (printed below).
migrate_0_5_0() { :; }
migrate_0_5_1() { :; }
migrate_0_6_0() { :; }
migrate_0_6_1() { :; }
migrate_0_6_2() { :; }
migrate_0_7_0() { :; }
# Kept for the version after this one: declared, never called until it exists.
migrate_0_9() { :; }

# 0.14: a line each for two dotfiles of the core. They are the core's own (a MOS
# adds lines of its own), so they are never merged or rewritten: the missing line
# is appended with its comment, and a line already there is left alone.
append_line() {  # core-relative file, exact line, comment ("" = none)
  local f="$CORE/$1"
  if [ -f "$f" ] && tr -d '\r' < "$f" | grep -qxF -- "$2"; then
    report "nothing" "v0.14.0  $1 already carries '$2'"
    return 0
  fi
  if [ "$APPLY" -eq 1 ]; then
    { if [ -s "$f" ] && [ -n "$(tail -c 1 "$f")" ]; then echo; fi
      if [ -n "$3" ]; then printf '\n# %s\n' "$3"; fi
      printf '%s\n' "$2"; } >> "$f"
    report "migrated" "v0.14.0  $1 += '$2'"
  else
    report "would do" "v0.14.0  $1 += '$2'"
  fi
  N_MIGRATED=$((N_MIGRATED + 1))
}
migrate_0_14() {
  # A merge rule of the core's own for a log.md is the core's choice: kept, named.
  _ours=$(printf '/log.md merge=union\n/knowledge-base/log.md merge=union')
  _theirs=""
  [ -f "$CORE/.gitattributes" ] && _theirs=$(tr -d '\r' < "$CORE/.gitattributes" \
    | grep -vE '^[[:space:]]*(#|$)' | grep -E '(^|/)log\.md[[:space:]].*merge' | grep -vxF "$_ours" || true)
  if [ -n "$_theirs" ]; then
    report "yours" "v0.14.0  .gitattributes already sets a merge rule for a log.md ($(printf '%s' "$_theirs" | head -1)): left as it is"
  else
    append_line .gitattributes "/log.md merge=union" \
      "The journals with several people (0.14): at a merge, union keeps the entries both sides prepended, with no conflict marker. Only the two journals: a page rewritten in place would keep both versions."
    append_line .gitattributes "/knowledge-base/log.md merge=union" ""
  fi
  append_line .gitignore ".claude/operator" \
    "Who is at the screen on this machine (whoami.sh, 0.14): one line, a handle from PEOPLE.md; never committed"
  # PEOPLE.md is identity: named, never written.
  if [ -f "$CORE/PEOPLE.md" ]; then
    report "nothing" "v0.14.0  PEOPLE.md exists — yours, untouched"
  else
    report "read it" "v0.14.0  no PEOPLE.md: identity, never created by this script; with one person the core runs as before — to write it, UPGRADING.md 0.14.0"
  fi
}

# 0.15: the inbox is an inbox again (Spec §7), and the instructions of a front desk
# live in consignes/ (Spec §21). The folders are created; every `type: instruction`
# item leaves inbox/ (deposee -> consignes/, traitee | rejetee -> consignes/traitees/,
# git mv when tracked); the captures that do not meet the new contract are only
# listed: their origine is read in their content, and sorting is a judgment, the
# agent's (the upgrade skill), never this script's.
fm_block() {  # file -> its frontmatter lines (CR stripped), nothing without one
  tr -d '\r' < "$1" 2>/dev/null | awk 'NR == 1 { if ($0 != "---") exit; next } $0 == "---" { exit } { print }'
}
fm_value() {  # file key -> the scalar value of a top-level key, unquoted
  fm_block "$1" | sed -nE "s/^$2:[[:space:]]*//p" | head -n 1 \
    | sed -E 's/[[:space:]]+#.*$//; s/^"(.*)"$/\1/; s/^'\''(.*)'\''$/\1/; s/[[:space:]]+$//'
}
move_item() {  # core-relative src, core-relative dest dir
  local src=$1 dir=$2 name
  name=$(basename -- "$src")
  if [ -e "$CORE/$dir/$name" ]; then
    report "MANUAL" "v0.15.0  $src — $dir/$name already exists: move it by hand"
    N_MANUAL=$((N_MANUAL + 1)); return 0
  fi
  if [ "$APPLY" -eq 1 ]; then
    mkdir -p "$CORE/$dir"
    if git -C "$CORE" rev-parse --git-dir >/dev/null 2>&1 \
       && git -C "$CORE" ls-files --error-unmatch "$src" >/dev/null 2>&1; then
      git -C "$CORE" mv "$src" "$dir/$name"
      report "migrated" "v0.15.0  $src -> $dir/ (git mv)"
    else
      mv "$CORE/$src" "$CORE/$dir/$name"
      report "migrated" "v0.15.0  $src -> $dir/ (mv)"
    fi
  else
    report "would do" "v0.15.0  $src -> $dir/"
  fi
  N_MIGRATED=$((N_MIGRATED + 1))
}
migrate_0_15() {
  # 1. The folders: consignes/ (its README), consignes/traitees/, inbox/rappels/.
  local d f rel typ st o why n_bad=0
  for d in consignes consignes/traitees inbox/rappels; do
    case $d in
      consignes) f=README.md ;;
      *)         f=.gitkeep ;;
    esac
    if [ -e "$CORE/$d/$f" ] || { [ "$f" = .gitkeep ] && [ -d "$CORE/$d" ] && [ -n "$(ls -A "$CORE/$d" 2>/dev/null)" ]; }; then
      report "nothing" "v0.15.0  $d/ already there"
      continue
    fi
    if [ "$APPLY" -eq 1 ]; then
      mkdir -p "$CORE/$d"
      if [ "$f" = README.md ] && [ -f "$TO_DIR/$MOS/consignes/README.md" ]; then
        cp "$TO_DIR/$MOS/consignes/README.md" "$CORE/$d/$f"
      else
        : > "$CORE/$d/$f"
      fi
      report "migrated" "v0.15.0  $d/$f created"
    else
      report "would do" "v0.15.0  $d/$f created"
    fi
    N_MIGRATED=$((N_MIGRATED + 1))
  done

  # 2. The instruction items leave the inbox. 3. The captures out of contract are listed.
  if [ ! -d "$CORE/inbox" ]; then
    report "nothing" "v0.15.0  no inbox/ to sort out"
    return 0
  fi
  for f in "$CORE"/inbox/*.md "$CORE"/inbox/rappels/*.md; do
    [ -f "$f" ] || continue
    rel=${f#"$CORE"/}
    case $(basename -- "$f") in README.md|index.md) continue ;; esac
    typ=$(fm_value "$f" type)
    if [ "$typ" = instruction ]; then
      st=$(fm_value "$f" status)
      case $st in
        deposee)         move_item "$rel" consignes ;;
        traitee|rejetee) move_item "$rel" consignes/traitees ;;
        *) report "MANUAL" "v0.15.0  $rel — an instruction item with status '${st:-(none)}': file it in consignes/ by hand"
           N_MANUAL=$((N_MANUAL + 1)) ;;
      esac
      continue
    fi
    why=""
    [ "$typ" = capture ] || why="type: ${typ:-(none)}"
    o=$(fm_value "$f" origine)
    case $o in
      main|checkpoint|watch|close-work|review|front-desk) : ;;
      "")      why="${why:+$why, }no origine" ;;
      veille)  why="${why:+$why, }origine: veille (now watch)" ;;
      revue)   why="${why:+$why, }origine: revue (now review)" ;;
      guichet) why="${why:+$why, }origine: guichet (now front-desk)" ;;
      *)       why="${why:+$why, }origine: $o (off the list)" ;;
    esac
    [ -n "$(fm_value "$f" status)" ] && why="${why:+$why, }a status"
    case $rel in
      inbox/rappels/*) [ -n "$(fm_value "$f" rappel_le)" ] || why="${why:+$why, }no rappel_le" ;;
    esac
    if [ -n "$why" ]; then
      report "to sort" "v0.15.0  $rel — $why"
      n_bad=$((n_bad + 1))
    fi
  done
  if [ "$n_bad" -gt 0 ]; then
    report "MANUAL" "v0.15.0  $n_bad inbox file(s) out of the capture contract (Spec §7): left as they are — give each its type, origine and source, or its exit (UPGRADING.md 0.15.0)"
    N_MANUAL=$((N_MANUAL + 1))
  else
    report "nothing" "v0.15.0  every inbox file is a capture in contract"
  fi
}

# 0.16: the skills bridge for Codex. Codex 0.163 and later look for skills in
# .agents/skills (from the working directory up to the root), no longer in a
# root skills/ link: a relative link .agents/skills -> ../.claude/skills is laid
# when missing. A real folder, or a link aimed elsewhere, is the core's: named,
# left. Where ln -s cannot make a link (Git Bash on Windows without the right),
# nothing is left behind and the junction is a manual touch. And /.agents/skills
# is ignored (gitignore_agents_skills, below: since 0.16.1 whether or not the
# core ignores its root /skills link).
# Nothing else to migrate: pour on a capture is optional.
migrate_0_16() {
  local l="$CORE/.agents/skills" gi="$CORE/.gitignore"
  if [ -L "$l" ] && [ "$(readlink "$l")" = ../.claude/skills ]; then
    report "nothing" "v0.16.0  .agents/skills already links to ../.claude/skills"
  elif [ -e "$l" ] || [ -L "$l" ]; then
    report "MANUAL" "v0.16.0  .agents/skills exists and is not the link to ../.claude/skills: yours, left as it is (Codex reads the skills there)"
    N_MANUAL=$((N_MANUAL + 1))
  elif [ ! -d "$CORE/.claude/skills" ]; then
    report "nothing" "v0.16.0  no .claude/skills to link .agents/skills to"
  elif [ "$APPLY" -eq 1 ]; then
    mkdir -p "$CORE/.agents"
    ln -s ../.claude/skills "$l" 2>/dev/null || true
    if [ -L "$l" ]; then
      report "migrated" "v0.16.0  .agents/skills -> ../.claude/skills (link for Codex)"
      N_MIGRATED=$((N_MIGRATED + 1))
    else
      rm -rf "$l"; rmdir "$CORE/.agents" 2>/dev/null || true
      report "MANUAL" "v0.16.0  .agents/skills: no symbolic link possible here; make the junction (BOOTSTRAP, \"Codex wiring\")"
      N_MANUAL=$((N_MANUAL + 1))
    fi
  else
    report "would do" "v0.16.0  .agents/skills -> ../.claude/skills (link for Codex)"
    N_MIGRATED=$((N_MIGRATED + 1))
  fi
  gitignore_agents_skills 0.16.0
}

# The .agents/skills line of .gitignore (0.16, fixed in 0.16.1): added as soon as
# it is missing, whether or not the core ignores /skills (0.16.0 added it only
# beside /skills, and three cores out of four wrote it by hand); a core without
# .gitignore gets one with this line. Said once per run: walked from 0.16.0 and
# 0.16.1 alike, the second call finds the first one's plan.
GI_AGENTS_PLANNED=0
gitignore_agents_skills() {  # version label
  local gi="$CORE/.gitignore"
  if [ "$GI_AGENTS_PLANNED" -eq 1 ]; then
    return 0
  elif [ -f "$gi" ] && tr -d '\r' < "$gi" | grep -qxF '/.agents/skills'; then
    report "nothing" "v$1  .gitignore already carries '/.agents/skills'"
    return 0
  fi
  GI_AGENTS_PLANNED=1
  N_MIGRATED=$((N_MIGRATED + 1))
  if [ "$APPLY" -ne 1 ]; then
    if [ -f "$gi" ]; then report "would do" "v$1  .gitignore += '/.agents/skills'"
    else report "would do" "v$1  .gitignore created with '/.agents/skills'"; fi
    return 0
  fi
  if [ -f "$gi" ]; then
    { if [ -s "$gi" ] && [ -n "$(tail -c 1 "$gi")" ]; then echo; fi
      printf '\n# %s\n/.agents/skills\n' "The skills bridge for Codex 0.163 and later (0.16): a link, never committed"; } >> "$gi"
    report "migrated" "v$1  .gitignore += '/.agents/skills'"
  else
    printf '# %s\n/.agents/skills\n' "The skills bridge for Codex 0.163 and later (0.16): a link, never committed" > "$gi"
    report "migrated" "v$1  .gitignore created with '/.agents/skills'"
  fi
}

# 0.16.1: the skills' gestures in permissions.allow (Spec §12). .claude/settings.json
# is identity: the one gesture played on it is additive. The shipped rules the
# core's allow list lacks are appended, in the shipped order; nothing is removed
# or reordered, deny and every other key are left as they are. The file is
# edited in place as text (the new rules before the closing bracket of allow,
# or an allow list opened at the top of permissions), and the result must parse
# to the old document plus those rules, else it is rewritten from the parsed
# document (two-space indent, key order kept). A dated copy is left beside it,
# the write is atomic. A file that does not parse, or whose permissions or
# allow is not of the expected shape, is left untouched and named (MANUAL).
py_settings_allow() {  # core-settings shipped-settings apply -> one verdict line
  "$PY" - "$1" "$2" "$3" <<'PYEOF'
import collections, datetime, json, os, re, shutil, sys, tempfile
path, shipped_path, apply_it = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
OD = collections.OrderedDict
try:
    shipped = json.load(open(shipped_path, encoding="utf-8"))["permissions"]["allow"]
except Exception as exc:
    print("MANUAL\tthe shipped settings.json carries no permissions.allow to read (%s)" % exc); sys.exit(0)
if not os.path.exists(path):
    print("MANUAL\tno .claude/settings.json: take the shipped one (its hooks wire the guard)"); sys.exit(0)
raw = open(path, encoding="utf-8").read()
try:
    doc = json.loads(raw, object_pairs_hook=OD)
except Exception as exc:
    print("MANUAL\t.claude/settings.json is not readable JSON (%s): left untouched; add the shipped permissions.allow by hand (UPGRADING.md 0.16.1)" % exc); sys.exit(0)
if not isinstance(doc, dict):
    print("MANUAL\t.claude/settings.json is not a JSON object: left untouched"); sys.exit(0)
perms = doc.get("permissions", OD())
if not isinstance(perms, dict):
    print("MANUAL\t.claude/settings.json: permissions is not an object: left untouched"); sys.exit(0)
allow = perms.get("allow", [])
if not isinstance(allow, list):
    print("MANUAL\t.claude/settings.json: permissions.allow is not a list: left untouched"); sys.exit(0)
missing = [r for r in shipped if r not in allow]
if not missing:
    print("nothing\tpermissions.allow already carries the %d shipped rules" % len(shipped)); sys.exit(0)
what = "permissions.allow += %d rule(s) of the skills (%s%s)" % (
    len(missing), ", ".join(missing[:3]), ", …" if len(missing) > 3 else "")
if not apply_it:
    print("would do\t" + what); sys.exit(0)
expected = json.loads(raw, object_pairs_hook=OD)
ep = expected.setdefault("permissions", OD())
ep.setdefault("allow", [])
ep["allow"] = list(ep["allow"]) + missing
def line_indent(pos):
    line = raw.rfind("\n", 0, pos) + 1
    return re.match(r"[ \t]*", raw[line:]).group(0)
new = None
m = re.search(r'"permissions"\s*:\s*\{', raw)
if m and "allow" in perms and len(re.findall(r'"allow"\s*:', raw)) == 1:
    a = re.search(r'"allow"\s*:\s*\[', raw[m.end():])
    if a:
        start = m.end() + a.end()
        end = raw.index("]", start)                # a rule holds no bracket
        body = raw[start:end]
        ind_allow = line_indent(m.end() + a.start())
        first = re.search(r'\n([ \t]*)"', body)
        ind = first.group(1) if first else ind_allow + "  "
        lines = ",\n".join(ind + json.dumps(r, ensure_ascii=False) for r in missing)
        head = body.rstrip() + "," if body.strip() else ""
        new = raw[:start] + head + "\n" + lines + "\n" + ind_allow + raw[end:]
elif m and "allow" not in perms:
    k = re.match(r'\s*\n([ \t]*)"', raw[m.end():])
    ind = k.group(1) if k else line_indent(m.start()) + "  "
    lines = ",\n".join(ind + "  " + json.dumps(r, ensure_ascii=False) for r in missing)
    rest = raw[m.end():]
    sep = "," if rest.strip()[:1] not in ("}", "") else ""
    new = raw[:m.end()] + "\n" + ind + '"allow": [\n' + lines + "\n" + ind + "]" + sep + rest
try:
    ok = new is not None and json.loads(new) == json.loads(json.dumps(expected))
except Exception:
    ok = False
how = "edited in place"
if not ok:
    new = json.dumps(expected, indent=2, ensure_ascii=False) + "\n"; how = "rewritten from the parsed file (two-space indent, key order kept)"
stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
backup = path + ".before-0.16.1-" + stamp
shutil.copy2(path, backup)
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".settings.json.")
with os.fdopen(fd, "w", encoding="utf-8") as fh:
    fh.write(new)
shutil.copymode(path, tmp)
os.replace(tmp, path)
print("migrated\t%s; %s; the file as it was: %s" % (what, how, os.path.basename(backup)))
PYEOF
}

migrate_0_16_1() {
  gitignore_agents_skills 0.16.1
  local out
  if [ -z "$PY" ]; then
    report "MANUAL" "v0.16.1  no python3: add the shipped permissions.allow to .claude/settings.json by hand (UPGRADING.md 0.16.1)"
    N_MANUAL=$((N_MANUAL + 1)); return 0
  fi
  out=$(py_settings_allow "$CORE/.claude/settings.json" "$TO_DIR/$MOS/.claude/settings.json" "$APPLY")
  report "${out%%	*}" "v0.16.1  ${out#*	}"
  case ${out%%	*} in
    migrated|"would do") N_MIGRATED=$((N_MIGRATED + 1)) ;;
    MANUAL) N_MANUAL=$((N_MANUAL + 1)) ;;
  esac
}

echo
echo "Declared migrations"
if [ -z "$VERSIONS" ]; then
  report "nothing" "${VERSIONS_NOTE:-no version walked over}"
else
  MIG_DECLARED=0
  for v in $VERSIONS; do
    case $v in
      0.8.0) MIG_DECLARED=1; migrate_0_8 ;;
      0.14.0) MIG_DECLARED=1; migrate_0_14 ;;
      0.15.0) MIG_DECLARED=1; migrate_0_15 ;;
      0.16.0) MIG_DECLARED=1; migrate_0_16 ;;
      0.16.1) MIG_DECLARED=1; migrate_0_16_1 ;;
      *) : ;;
    esac
  done
  if [ "$MIG_DECLARED" -eq 0 ]; then
    report "nothing" "no migration declared for $VERSIONS"
  fi
fi

# ---------------------------------------------------------------------------
# The human half: what UPGRADING.md leaves to your hands, version by version.
# ---------------------------------------------------------------------------
echo
echo "Manual touches — the identity is yours; these are for your hands"
if [ -z "$VERSIONS" ]; then
  report "nothing" "${VERSIONS_NOTE:-no version walked over}"
elif [ -z "$UPGRADING" ]; then
  report "UNKNOWN" "UPGRADING.md not found — read the CHANGELOG for$VERSIONS by hand"
  N_MANUAL=$((N_MANUAL + 1))
else
  for v in $VERSIONS; do
    block=$(manual_block "$v" || true)
    if [ -z "$block" ]; then
      printf '  v%s: nothing to retouch by hand\n' "$v"
      continue
    fi
    printf '  v%s\n' "$v"
    printf '%s\n' "$block" | sed 's|^|    |'
    n=$(printf '%s\n' "$block" | grep -c '^[[:space:]]*-' || true)
    N_MANUAL=$((N_MANUAL + n))
  done
fi

# ---------------------------------------------------------------------------
# Class (d), the stamp — written last, and only when nothing is left hanging.
# ---------------------------------------------------------------------------
echo
echo "Version stamp"
if [ "$N_CONFLICT" -gt 0 ]; then
  if [ "$RESOLVED" -eq 1 ]; then
    report "not written" "$N_CONFLICT conflict(s) left — finish them (remove each .upgrade-conflict, no marker left), then rerun with --resolved"
  else
    report "not written" "$N_CONFLICT conflict(s) left — resolve them, then rerun with --resolved"
  fi
elif [ "$TO_IS_VERSION" -ne 1 ]; then
  report "not written" "$TO_REV is not a released version — the stamp names releases only"
elif [ "$APPLY" -ne 1 ]; then
  report "would write" ".claude/manence-version = v${TO_REV#v}"
elif [ -z "$VERSIONS" ]; then
  report "unchanged" ".claude/manence-version = $FROM_VER (nothing traversed)"
else
  printf 'v%s\n' "${TO_REV#v}" > "$CORE/.claude/manence-version"
  if [ "$N_RESOLVED" -gt 0 ]; then
    report "written" ".claude/manence-version = v${TO_REV#v} ($N_RESOLVED conflict(s) taken as resolved by hand)"
  else
    report "written" ".claude/manence-version = v${TO_REV#v}"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "Summary"
printf '  merged %d · replaced %d · created %d · up to date %d · diverges %d · resolved by hand %d · CONFLICT %d · skipped %d · migrations %d · manual touches %d\n' \
  "$N_MERGED" "$N_REPLACED" "$N_CREATED" "$N_SAME" "$N_DIVERGES" "$N_RESOLVED" "$N_CONFLICT" "$N_SKIPPED" "$N_MIGRATED" "$N_MANUAL"

if [ "$APPLY" -ne 1 ]; then
  echo "  dry run: nothing was written. Rerun with --apply when the plan above suits you."
else
  echo "  written, not committed: reread the diff (git diff) and commit it yourself."
fi

if [ "$N_CONFLICT" -gt 0 ]; then
  echo
  echo "  exit 2 — something is left for you: $N_CONFLICT conflict(s), $N_MANUAL manual touch(es)."
  exit 2
elif [ "$N_MANUAL" -gt 0 ]; then
  echo
  echo "  exit 0 — the upgrade is complete; $N_MANUAL manual touch(es) listed above are yours to do (the script cannot check them)."
  exit 0
fi

exit 0
