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
#
# Options:
#   --to <rev>            target version (default: the newest tag of the source)
#   --from <vX.Y.Z>       version you have (default: <core>/.claude/manence-version)
#   --source <dir|url>    where the target tree comes from (default: the public repo)
#   --from-source <dir>   where the *installed* version's tree comes from (default: --source)
#   --lang en|fr          install set to merge from (default: detected from the core)
#   --production <dir>    production root (default: <core>/.env, else <core>/../production)
#   --apply               write; without it nothing on disk changes
#
# It never commits, never pushes, never deletes, and never touches your
# identity files. See UPGRADING.md for what it leaves to your hands.
#
# Portable: bash 3.2+ (macOS default), Linux, Git Bash on Windows.
# Requires: git. Uses python3 when present for the JSON and frontmatter
# migrations; without it, it says which ones you must play by hand.
#
set -eu

SELF_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo ".")
MOS=implementation/mos
BASE_SKILLS="checkpoint close-work connect-adapter kb-ingest kb-lint open-work outward-watch weekly-review"
# Versions this script knows how to walk. Keep in sync with UPGRADING.md.
KNOWN_VERSIONS="0.5.0 0.5.1 0.6.0 0.6.1 0.6.2 0.7.0 0.8.0 0.8.1 0.8.2 0.8.3"
DEFAULT_REPO=${MANENCE_REPO:-https://github.com/manence/manence.git}

usage() {
  cat >&2 <<'EOF'
usage: upgrade.sh <core-dir> [options]

  --to <rev>            target version (default: newest tag of the source)
  --from <vX.Y.Z>       version installed (default: <core>/.claude/manence-version)
  --source <dir|url>    source of the target tree (default: the public repo)
  --from-source <dir>   source of the installed version's tree (default: --source)
  --lang en|fr          install set (default: detected)
  --production <dir>    production root (default: <core>/.env, else <core>/../production)
  --apply               write (without it: dry run, nothing is written)

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
PROD_OPT=""; APPLY=0

while [ $# -gt 0 ]; do
  case $1 in
    -h|--help) usage ;;
    --apply) APPLY=1 ;;
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
  echo "upgrade.sh: fetching $_spec…" >&2
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

if [ "$LANG_SET" = fr ]; then
  SK_SRC=$MOS/fr/skills; TPL_SRC=$MOS/fr/templates
else
  SK_SRC=$MOS/.claude/skills; TPL_SRC=$MOS/templates
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
printf '  production    %s (%s)\n' "$PROD" "$PROD_WHY"
printf '  from          %s (%s) — %s\n' "$FROM_VER" "$FROM_ORIGIN" "$FROM_SOURCE"
printf '  to            %s (%s) — %s\n' "$TO_REV" "$TO_ORIGIN" "$SOURCE"
printf "  versions      %s\n" "${VERSIONS:-$VERSIONS_NOTE}"
printf '  UPGRADING.md  %s\n' "${UPGRADING_WHY:-not found (manual touches will not be listed)}"
printf '  mode          %s\n' "$MODE"
echo

# ---------------------------------------------------------------------------
# The organ table. Class (a), mechanical: merged three ways, base = the version
# you have. Built from the *target* tree: what the new version ships.
# ---------------------------------------------------------------------------
TABLE=$TMP/organs.tsv
: > "$TABLE"
TAB=$(printf '\t')

add_organ() { printf '%s\t%s\n' "$1" "$2" >> "$TABLE"; }

add_organ ".claude/hooks/guard.sh" "$MOS/.claude/hooks/guard.sh"
add_organ ".claude/hooks/lint.sh"  "$MOS/.claude/hooks/lint.sh"

if [ -d "$TO_DIR/$TPL_SRC" ]; then
  (cd "$TO_DIR/$TPL_SRC" && find . -type f ! -name '.DS_Store' | sed 's|^\./||' | sort) \
  | while IFS= read -r f; do
      [ -n "$f" ] || continue
      printf 'templates/%s\t%s/%s\n' "$f" "$TPL_SRC" "$f" >> "$TABLE"
    done
fi

for s in $BASE_SKILLS; do
  [ -d "$TO_DIR/$SK_SRC/$s" ] || continue
  (cd "$TO_DIR/$SK_SRC/$s" && find . -type f ! -name '.DS_Store' | sed 's|^\./||' | sort) \
  | while IFS= read -r f; do
      [ -n "$f" ] || continue
      printf '.claude/skills/%s/%s\t%s/%s/%s\n' "$s" "$f" "$SK_SRC" "$s" "$f" >> "$TABLE"
    done
done

N_MERGED=0; N_REPLACED=0; N_CREATED=0; N_SAME=0; N_CONFLICT=0; N_SKIPPED=0
N_MIGRATED=0; N_MANUAL=0

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

echo "Mechanical organs — hooks, templates, the eight base skills"
echo "  (three-way merged: your file, the version you have, the new version)"

if [ ! -s "$TABLE" ]; then
  report "—" "nothing shipped for language $LANG_SET at $TO_REV (wrong --lang?)"
fi

while IFS="$TAB" read -r corepath srcrel; do
  [ -n "$corepath" ] || continue
  localf=$CORE/$corepath
  tof=$TO_DIR/$srcrel
  fromf=$FROM_DIR/$srcrel
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

  if cmp -s "$localf" "$tof"; then
    report "up to date" "$corepath"
    N_SAME=$((N_SAME + 1)); continue
  fi

  if [ -f "$fromf" ] && cmp -s "$fromf" "$tof"; then
    report "unchanged" "$corepath — the new version doesn't touch it; yours stands"
    N_SAME=$((N_SAME + 1)); continue
  fi

  if [ -f "$fromf" ] && cmp -s "$localf" "$fromf"; then
    write_file "$tof" "$localf"
    report "replaced" "$corepath — no local change"
    N_REPLACED=$((N_REPLACED + 1)); continue
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

  if [ "$predates" -eq 1 ] && [ "$rc" -lt 128 ]; then
    case "$corepath" in
      .claude/skills/*) what="local skill" ;;
      *)                what="local file" ;;
    esac
    write_file "$TMP/merge.out" "$localf.upgrade-conflict"
    report "CONFLICT" "$corepath ($what predates the shipped one) — yours untouched; the framework's version waits beside it in $corepath.upgrade-conflict$basenote"
    N_CONFLICT=$((N_CONFLICT + 1))
  elif [ "$rc" -eq 0 ]; then
    write_file "$TMP/merge.out" "$localf"
    report "merged" "$corepath — your edits kept"
    N_MERGED=$((N_MERGED + 1))
  elif [ "$rc" -gt 0 ] && [ "$rc" -lt 128 ]; then
    write_file "$TMP/merge.out" "$localf.upgrade-conflict"
    report "CONFLICT" "$corepath — $rc hunk(s); resolve by hand in $corepath.upgrade-conflict$basenote"
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

# ---------------------------------------------------------------------------
# Class (b), identity: never touched. Named so the silence is explicit.
# ---------------------------------------------------------------------------
echo
echo "Identity organs — never touched by this script"
for f in AGENTS.md CLAUDE.md CLAUDE.local.md SOUL.md STRATEGY.md .claude/settings.json \
         .env .env.example log.md knowledge-base inbox; do
  [ -e "$CORE/$f" ] && report "yours" "$f"
done
report "yours" "everything else the core holds (brand/, scripts/, your own skills…)"

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

echo
echo "Declared migrations"
if [ -z "$VERSIONS" ]; then
  report "nothing" "${VERSIONS_NOTE:-no version walked over}"
else
  MIG_DECLARED=0
  for v in $VERSIONS; do
    case $v in
      0.8.0) MIG_DECLARED=1; migrate_0_8 ;;
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
  report "not written" "$N_CONFLICT conflict(s) left — resolve them, then rerun"
elif [ "$TO_IS_VERSION" -ne 1 ]; then
  report "not written" "$TO_REV is not a released version — the stamp names releases only"
elif [ "$APPLY" -ne 1 ]; then
  report "would write" ".claude/manence-version = v${TO_REV#v}"
elif [ -z "$VERSIONS" ]; then
  report "unchanged" ".claude/manence-version = $FROM_VER (nothing traversed)"
else
  printf 'v%s\n' "${TO_REV#v}" > "$CORE/.claude/manence-version"
  report "written" ".claude/manence-version = v${TO_REV#v}"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "Summary"
printf '  merged %d · replaced %d · created %d · up to date %d · CONFLICT %d · skipped %d · migrations %d · manual touches %d\n' \
  "$N_MERGED" "$N_REPLACED" "$N_CREATED" "$N_SAME" "$N_CONFLICT" "$N_SKIPPED" "$N_MIGRATED" "$N_MANUAL"

if [ "$APPLY" -ne 1 ]; then
  echo "  dry run: nothing was written. Rerun with --apply when the plan above suits you."
else
  echo "  written, not committed: reread the diff (git diff) and commit it yourself."
fi

if [ "$N_CONFLICT" -gt 0 ] || [ "$N_MANUAL" -gt 0 ]; then
  echo
  echo "  exit 2 — something is left for you: $N_CONFLICT conflict(s), $N_MANUAL manual touch(es)."
  exit 2
fi

exit 0
