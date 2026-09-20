#!/usr/bin/env bash
#
# install.sh — put a Manence OS on disk.
#
# The human door. Copies the default MOS *with its dotfiles* into a new
# container, checks the copy is whole, and prints the one sentence to say
# to the agent. MIT: this file is code.
#
# Usage:
#   curl -fsSL --proto '=https' --tlsv1.2 https://manence.ai/install.sh | bash
#   bash install.sh                  # default: ~/manence
#   bash install.sh ~/my-activity    # explicit container path
#
# Portable: bash 3.2+ (macOS default), Linux, Git Bash on Windows.
# Requires: git (only when the script is not run from a clone).
#
set -eu

usage() {
  echo "usage: install.sh [container-path]" >&2
  echo "  default:  ~/manence" >&2
  echo "  example:  bash install.sh ~/my-activity" >&2
  echo "  then:     cd <container>/core" >&2
  echo "            open your coding agent and say:  run my first setup" >&2
  exit 2
}

case "${1:-}" in
  -h|--help) usage ;;
esac

if [ $# -ge 1 ]; then
  RAW_TARGET=$1
else
  RAW_TARGET=${HOME}/manence
  echo "install.sh: no path given — installing to $RAW_TARGET"
  echo "            (pass a folder to override:  bash install.sh ~/my-activity)"
fi

# Expand a leading ~ even when the caller quoted the path.
case "$RAW_TARGET" in
  "~")   TARGET=${HOME} ;;
  "~/"*) TARGET=${HOME}/${RAW_TARGET#~/} ;;
  *)     TARGET=$RAW_TARGET ;;
esac

# Resolve to an absolute path without requiring the directory to exist yet.
# (readlink -f is GNU; this works on macOS bash 3.2.)
_parent=$(dirname -- "$TARGET")
_base=$(basename -- "$TARGET")
if [ -d "$_parent" ]; then
  TARGET=$(cd -- "$_parent" && pwd)/$_base
else
  echo "install.sh: parent directory does not exist: $_parent" >&2
  exit 1
fi

if [ -e "$TARGET/core" ]; then
  echo "install.sh: $TARGET/core already exists — pick another path." >&2
  exit 1
fi
if [ -d "$TARGET/implementation/mos" ]; then
  echo "install.sh: $TARGET looks like the framework clone, not a container." >&2
  echo "  pick a new folder (e.g. ~/my-activity)." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Locate the default MOS: next to this script when run from a clone; otherwise
# clone the public repo into a temp dir.
# ---------------------------------------------------------------------------
MOS_SRC=""
CLEANUP=""

_script=${BASH_SOURCE[0]:-}
if [ -n "$_script" ] && [ -f "$_script" ]; then
  _dir=$(cd -- "$(dirname -- "$_script")" && pwd)
  if [ -d "$_dir/implementation/mos" ]; then
    MOS_SRC=$_dir/implementation/mos
  fi
fi

if [ -z "$MOS_SRC" ]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "install.sh: git is required to fetch the default MOS." >&2
    exit 1
  fi
  CLEANUP=$(mktemp -d "${TMPDIR:-/tmp}/manence-install.XXXXXX")
  echo "install.sh: fetching the default MOS…"
  git clone --depth 1 --quiet \
    "${MANENCE_REPO:-https://github.com/manence/manence.git}" \
    "$CLEANUP/manence"
  MOS_SRC=$CLEANUP/manence/implementation/mos
fi

if [ ! -f "$MOS_SRC/BOOTSTRAP.md" ]; then
  echo "install.sh: default MOS not found at $MOS_SRC" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Copy the folder, including dotfiles. `cp -R src/. dest/` is the portable
# form: `cp -R src dest` plus a file-manager drag of *contents* is exactly
# the failure BOOTSTRAP step 0 exists to catch.
# ---------------------------------------------------------------------------
mkdir -p "$TARGET/core"
cp -R "$MOS_SRC"/. "$TARGET/core/"

# Some copy paths drop the executable bit; the hooks are invoked via bash,
# but keep the bit when the filesystem honors it (no-op on NTFS).
chmod +x "$TARGET/core/.claude/hooks/"*.sh 2>/dev/null || true

# ---------------------------------------------------------------------------
# Integrity — the same organs BOOTSTRAP step 0 checks. Fail here, not after
# the interview.
# ---------------------------------------------------------------------------
missing=0
for organ in \
  .claude/settings.json .claude/hooks/guard.sh .claude/hooks/lint.sh .claude/skills \
  .claude/manence-version .claude/mos.json .env.example .gitattributes .gitignore \
  .mcp.json.example CLAUDE.local.md.example \
  AGENTS.md CLAUDE.md SOUL.md STRATEGY.md log.md knowledge-base templates inbox BOOTSTRAP.md
do
  if [ ! -e "$TARGET/core/$organ" ]; then
    echo "install.sh: MISSING $organ" >&2
    missing=1
  fi
done

if [ -n "$CLEANUP" ]; then
  rm -rf "$CLEANUP"
fi

if [ "$missing" -ne 0 ]; then
  echo "install.sh: the copy is not whole. Do not continue — recopy from a clone:" >&2
  echo "  git clone https://github.com/manence/manence.git" >&2
  echo "  bash manence/install.sh $TARGET" >&2
  exit 1
fi

cat <<EOF

Manence OS is on disk.

  container  $TARGET
  core       $TARGET/core

Next:

  cd $TARGET/core
  claude        # or: codex, grok — the ritual wires the agent you choose

Then say:  run my first setup
(or, in French:  fais mon premier démarrage)

The agent interviews you, fills in the system, checks the guardrails,
and deletes the ritual. Installing is already using it.

EOF
