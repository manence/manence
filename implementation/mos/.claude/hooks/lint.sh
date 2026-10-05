#!/bin/bash
# Mechanical linter of the Manence framework (layer 5). Replaces the placeholder:
# it is the "hard" side (a verifiable script) that takes over from kb-lint (an
# agentic skill, judgment) and serves as the fallback method when the Obsidian
# graph view is not at hand.
#
# Checks on .md files (excluding .git/, .obsidian/, node_modules/), see Spec §1/§3:
#   a. broken relative markdown links (target does not exist, after urldecoding %20),
#      ignoring links quoted in a code block (``` fences) or in inline code
#      (`backticks`): they document, they do not link
#   b. links with a leading slash ](/...) (forbidden by Spec §3)
#   c. broken anchors: a file.md#anchor link (or #anchor in the same file)
#      for which no heading of the target produces the matching GitHub slug
#      (github-slugger algorithm: lowercase, accents kept, punctuation removed except
#      hyphen/underscore, spaces→hyphens, duplicates -1/-2). Original lesson: the slug
#      of a translated heading breaks (2026-07-09)
#   d. YAML frontmatter present + parseable + a type: field (except exempted files);
#      unquoted ":" in title/description; delimiter written as an em dash (—)
#      instead of --- (an editor trap that breaks the YAML)
#   e. review_when: dated and past due (a YYYY-MM-DD date in the past) → soft finding (0.4.x).
#      Undated values (event triggers) are silently ignored.
#   f. awaiting: (workstreams, type: work only, and only if the key is there):
#      STRUCTURE only: either [], or a list of entries carrying who, what,
#      kind and since (blocks optional), with kind ∈ {decision, action}, since as
#      YYYY-MM-DD and who without a space or "@" → soft finding. The lint never invents
#      nor corrects a wait: it only says whether the one written down holds.
#   g. (0.12, standalone on a folder) an in-progress/ or done/ nested below
#      another one (Spec §17), and h. the sizes the Spec bounds: log.md over
#      150 KB, AGENTS.md over 200 lines (Spec §8, §9). See the end of the file.
#
# Portability / dependencies (a tool SHIPPED to users):
#   - python3 OPTIONAL: present → full parsing (Markdown fences/inline, anchors,
#     frontmatter, review_when, awaiting). Absent → announced DEGRADED mode: links by
#     line-by-line regex (pure bash), the rest — anchors, frontmatter, review_when and
#     awaiting — not checked. No format regression.
#   - PyYAML is NO LONGER required nor used: the frontmatter verdict comes from a
#     deterministic stdlib validator (same result on any machine, with or without
#     PyYAML installed). The parsing level is announced in the summary line.
#
# Structural exemptions:
#   - production (Spec §16: outside git, disposable artifacts): closed workstreams
#     (a "done" path component, or the legacy production/published/) are exempted
#     from checks c and d (never rewritten, L3; links are still checked);
#     in "in-progress", only About.md is held to OKF, the other artifacts
#     are only checked for their links
#   - .lintignore at the repo root (the folder that contains .git): one line
#     per relative path to ignore entirely (prefix; "#" = comment).
#     For areas outside the lint's scope: legacy corpus, files in another
#     language, etc.
#
# Two modes of use:
#   - standalone: lint.sh [path]      -> one file, or the whole repo (default: ".")
#                                         exit 1 if there are findings, 0 otherwise
#   - hook      : lint.sh --hook      -> reads the PostToolUse JSON on stdin
#                                         (tool_input.file_path), lints ONLY
#                                         that file, never blocks (exit 0)

set -uo pipefail

HOOK_MODE=0
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --hook) HOOK_MODE=1 ;;
    *) TARGET="$arg" ;;
  esac
done

if [ "$HOOK_MODE" -eq 1 ]; then
  # PostToolUse: the edited file comes from the JSON on stdin, not from a path argument.
  FILE_PATH=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
  if [ -z "$FILE_PATH" ] || [[ "$FILE_PATH" != *.md ]]; then
    exit 0  # nothing to do: no file, or not a .md
  fi
  TARGET="$FILE_PATH"
elif [ -z "$TARGET" ]; then
  TARGET="."
fi

if [ ! -e "$TARGET" ]; then
  echo "lint.sh: path not found: $TARGET" >&2
  [ "$HOOK_MODE" -eq 1 ] && exit 0
  exit 0
fi

# List of .md files to check, excluding .git/, .obsidian/, node_modules/
if [ -f "$TARGET" ]; then
  FILES="$TARGET"
else
  FILES=$(find "$TARGET" \
    \( -name .git -o -name .obsidian -o -name node_modules \) -prune -o \
    -type f -name '*.md' -print)
fi

if [ -z "$FILES" ]; then
  exit 0  # nothing to lint
fi

# (no mapfile: macOS ships bash 3.2, mapfile/readarray only exist in 4+)
FILE_ARR=()
while IFS= read -r line; do
  [ -n "$line" ] && FILE_ARR+=("$line")
done <<< "$FILES"

# --- DEGRADED fallback without python3: the two historical link checks in pure
# bash (line-by-line regex, inline code removed), honoring .lintignore and the
# templates. Anchors, frontmatter and review_when are NOT checked (announced). ---
run_bash_fallback() {
  local findings=0
  local nfiles=$#

  # repo root (ancestor folder holding .lintignore or .git) for a file
  _repo_root() {
    local d
    d=$(cd "$(dirname "$1")" 2>/dev/null && pwd)
    [ -z "$d" ] && return 1
    while [ -n "$d" ]; do
      if [ -f "$d/.lintignore" ] || [ -d "$d/.git" ]; then
        printf '%s' "$d"; return 0
      fi
      [ "$d" = "/" ] && break
      d=$(dirname "$d")
    done
    return 1
  }

  _is_lintignored() {
    local file="$1" root rel pat
    root=$(_repo_root "$file") || return 1
    [ -f "$root/.lintignore" ] || return 1
    local abs
    abs=$(cd "$(dirname "$file")" 2>/dev/null && pwd)/$(basename "$file")
    rel="${abs#"$root"/}"
    while IFS= read -r pat; do
      pat="${pat#"${pat%%[![:space:]]*}"}"   # ltrim
      pat="${pat%"${pat##*[![:space:]]}"}"    # rtrim
      [ -z "$pat" ] && continue
      case "$pat" in \#*) continue ;; esac
      case "$rel" in
        "$pat"|"${pat%/}"/*|"$pat"*) return 0 ;;
      esac
    done < "$root/.lintignore"
    return 1
  }

  local file dir lineno=0
  for file in "$@"; do
    case "$(basename "$file")" in *.template.md) continue ;; esac
    _is_lintignored "$file" && continue
    dir=$(dirname "$file")
    lineno=0
    while IFS= read -r rawline || [ -n "$rawline" ]; do
      lineno=$((lineno + 1))
      # remove inline code `...` (documentation, not links)
      local line
      line=$(printf '%s' "$rawline" | sed 's/`[^`]*`/ /g')
      # extract each markdown link target ](...)
      printf '%s\n' "$line" | grep -oE '\]\([^)]+\)' 2>/dev/null | \
        sed -E 's/^\]\(//; s/\)$//' | while IFS= read -r target; do
          [ -z "$target" ] && continue
          case "$target" in
            /*) printf '%s:%s: leading-slash-link: link with a leading slash is forbidden (Spec §3): %s\n' "$file" "$lineno" "$target"; continue ;;
            *://*|mailto:*|\#*) continue ;;
          esac
          # remove the anchor, urldecode %20, resolve relative to the file
          local rel decoded
          rel="${target%%#*}"
          [ -z "$rel" ] && continue
          decoded=$(printf '%s' "$rel" | sed 's/%20/ /g')
          if [ ! -e "$dir/$decoded" ]; then
            printf '%s:%s: broken-link: target not found: %s\n' "$file" "$lineno" "$target"
          fi
        done
    done < "$file"
  done > /tmp/.lint_bash_$$ 2>/dev/null

  if [ -s /tmp/.lint_bash_$$ ]; then
    cat /tmp/.lint_bash_$$
    findings=$(wc -l < /tmp/.lint_bash_$$ | tr -d ' ')
  fi
  rm -f /tmp/.lint_bash_$$
  echo "--- lint.sh: ${findings} finding(s) in ${nfiles} file(s) — DEGRADED parsing (python3 missing: links by line-by-line regex; anchors, frontmatter, review_when and awaiting NOT checked) ---"
  [ "$findings" -gt 0 ] && return 1
  return 0
}

# Real execution probe, not `command -v`: on Windows 11, a python3.exe stub
# (WindowsApps) that opens the Microsoft Store answers "present" to
# command -v, so the degraded fallback never kicked in and the lint broke
# (found on a real install, 2026-08-06).
if python3 -c 'pass' >/dev/null 2>&1; then
  # The python body goes to a temporary file through a plain redirection
  # (never inside a $(...): the bash 3.2 substitution scanner counts backticks
  # even inside a quoted heredoc, and an odd number breaks the parsing).
  # Robust whatever the script contains.
  PYSCRIPT=$(mktemp "${TMPDIR:-/tmp}/lint.XXXXXX") || PYSCRIPT="${TMPDIR:-/tmp}/lint.$$.py"
  cat > "$PYSCRIPT" <<'PYEOF'
import bisect
import os
import re
import sys
from datetime import date
from urllib.parse import unquote

TODAY = date.today()

EXEMPT_BASENAMES = {
    "index.md",
    "README.md", "README.fr.md",
    "QUICKSTART.md", "QUICKSTART.fr.md",
    "LICENSE.md",
    "AGENTS.md",
    "CLAUDE.md",
}

# Inline markdown link: the text stays on one line (historical behavior),
# the URL may wrap once (reasonable multi-line links).
LINK_RE = re.compile(r'!?\[[^\]\n]*\]\(([^)\n]*(?:\n[^)\n]*)?)\)')
FM_KEY_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_-]*)\s*:\s?(.*)$')
# awaiting: indented list read from the raw lines of the block (no PyYAML).
# An entry opens on a hyphen ('  - who: …'), its following keys are indented
# (4 spaces by convention) and have no hyphen.
AWAITING_ITEM_RE = re.compile(r'^ +-\s+([A-Za-z_][A-Za-z0-9_-]*)\s*:\s?(.*)$')
AWAITING_KEY_RE = re.compile(r'^ +([A-Za-z_][A-Za-z0-9_-]*)\s*:\s?(.*)$')
ISO_DATE_RE = re.compile(r'^\d{4}-\d{2}-\d{2}$')
AWAITING_KINDS = ("decision", "action")
FENCE_RE = re.compile(r'^ {0,3}(`{3,}|~{3,})')
ATX_RE = re.compile(r'^ {0,3}#{1,6}\s+(.*)$')
# em dash (—, U+2014) or en dash (–, U+2013) standing in for a delimiter
DASH_LINE_RE = re.compile(r'^\s*[—–]+\s*$')
# github-slugger: punctuation removed (accents and unicode letters kept,
# hyphen and underscore kept)
SPECIALS_RE = re.compile(
    "[\\u2000-\\u206F\\u2E00-\\u2E7F\\\\'!\"#$%&()*+,./:;<=>?@\\[\\]^`{|}~\\u2019]")

findings = []
_lintignore_cache = {}
_slug_cache = {}


def report(path, line, kind, detail):
    findings.append(f"{path}:{line}: {kind}: {detail}")


def _repo_root(start_dir):
    """Walk up to the first folder that contains a .lintignore or a .git
    (production lives outside git by doctrine: its .lintignore must still
    apply, .gitignore semantics)."""
    d = os.path.abspath(start_dir) or "/"
    while True:
        if os.path.isfile(os.path.join(d, ".lintignore")) or os.path.isdir(os.path.join(d, ".git")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def is_lintignored(path):
    """True if the file matches a prefix of its repo's .lintignore."""
    root = _repo_root(os.path.dirname(os.path.abspath(path)) or ".")
    if root is None:
        return False
    if root not in _lintignore_cache:
        patterns = []
        ignore_file = os.path.join(root, ".lintignore")
        if os.path.isfile(ignore_file):
            with open(ignore_file, encoding="utf-8") as fh:
                for raw in fh:
                    entry = raw.strip()
                    if entry and not entry.startswith("#"):
                        patterns.append(entry)
        _lintignore_cache[root] = patterns
    patterns = _lintignore_cache[root]
    if not patterns:
        return False
    rel = os.path.relpath(os.path.abspath(path), root)
    return any(rel == p or rel.startswith(p.rstrip("/") + "/") or rel.startswith(p)
               for p in patterns)


def is_loose_production(path):
    """Production artifacts exempted from OKF/typography, links checked (Spec §16/§8):
    closed workstreams (done/, or the legacy production/published/), and every artifact
    of a workstream in progress (in-progress/) other than its About.md."""
    parts = os.path.normpath(path).split(os.sep)
    if "done" in parts or ("production" in parts and "published" in parts):
        return True
    if "in-progress" in parts and os.path.basename(path) != "About.md":
        return True
    return False


def is_exempt_from_frontmatter(path, basename):
    if basename in EXEMPT_BASENAMES:
        return True
    if basename.endswith(".template.md"):
        return True
    if basename == "SKILL.md":
        return True  # Claude Code skill format: name/description frontmatter, not OKF
    parts = os.path.normpath(path).split(os.sep)
    if "inbox" in parts:
        return True  # inbox/: raw pre-contract capture, frictionless by doctrine;
        # the time guard is the weekly-review's: capture > 14 days = sorted or deleted
    if "sources" in parts:
        return True  # sources/: immutable raw inputs (wiki method), not knowledge pages
    if ".claude" in parts and "agents" in parts:
        return True  # Claude Code subagent format: name/description/tools/model frontmatter, not OKF
    return False


# --- GitHub slug (github-slugger) and the anchor index of a file -------------

def github_slug(text):
    """Reproduces github-slugger: link/image reduced to its visible text,
    lowercase, punctuation removed (SPECIALS), spaces → hyphens. Accents,
    unicode letters, hyphen and underscore kept."""
    text = re.sub(r'!\[([^\]]*)\]\([^)]*\)', r'\1', text)
    text = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', text)
    text = text.strip()
    text = re.sub(r'\s+#+\s*$', '', text)  # closed ATX: "## Title ##"
    text = text.lower()
    text = SPECIALS_RE.sub('', text)
    text = re.sub(r'\s', '-', text)
    return text


def heading_slugs(path):
    """Set of heading slugs (ATX, outside code blocks) of a file,
    with github-slugger's -1/-2 de-duplication."""
    if path in _slug_cache:
        return _slug_cache[path]
    slugs = set()
    try:
        with open(path, "r", encoding="utf-8") as fh:
            content = fh.read()
    except (OSError, UnicodeDecodeError):
        _slug_cache[path] = slugs
        return slugs
    occurrences = {}
    in_fence = False
    fence_char = None
    fence_len = 0
    for raw in content.split("\n"):
        fm = FENCE_RE.match(raw)
        if fm:
            marker = fm.group(1)[0]
            mlen = len(fm.group(1))
            if not in_fence:
                in_fence, fence_char, fence_len = True, marker, mlen
            elif marker == fence_char and mlen >= fence_len:
                in_fence = False
            continue
        if in_fence:
            continue
        hm = ATX_RE.match(raw)
        if not hm:
            continue
        base = github_slug(hm.group(1))
        if not base:
            continue
        slug = base
        while slug in occurrences:
            occurrences[base] += 1
            slug = base + "-" + str(occurrences[base])
        occurrences[slug] = 0
        slugs.add(slug)
    _slug_cache[path] = slugs
    return slugs


# --- Markdown parsing of links (fences + inline code + multi-line) -----------

def strip_inline_code(text):
    """Neutralizes inline code spans (`...`, ``...``) while preserving
    positions (replaced by spaces, newlines kept) so that the offsets
    stay aligned with line numbers."""
    res = list(text)
    n = len(text)
    i = 0
    while i < n:
        if text[i] != "`":
            i += 1
            continue
        j = i
        while j < n and text[j] == "`":
            j += 1
        run = j - i
        k = j
        closed_at = -1
        while k < n:
            if text[k] == "`":
                m = k
                while m < n and text[m] == "`":
                    m += 1
                if m - k == run:
                    closed_at = m
                    break
                k = m
            else:
                k += 1
        if closed_at == -1:
            i = j  # unclosed run: not a span, leave it
            continue
        for p in range(i, closed_at):
            if res[p] != "\n":
                res[p] = " "
        i = closed_at
    return "".join(res)


def build_scan_text(content):
    """Text ready to scan: code block lines (``` / ~~~) blanked,
    inline code neutralized, lengths and newlines preserved."""
    out = []
    in_fence = False
    fence_char = None
    fence_len = 0
    for raw in content.split("\n"):
        fm = FENCE_RE.match(raw)
        if fm:
            marker = fm.group(1)[0]
            mlen = len(fm.group(1))
            if not in_fence:
                in_fence, fence_char, fence_len = True, marker, mlen
            elif marker == fence_char and mlen >= fence_len:
                in_fence = False
            out.append(" " * len(raw))
            continue
        out.append(" " * len(raw) if in_fence else raw)
    return strip_inline_code("\n".join(out))


def check_links(path, content):
    if os.path.basename(path).endswith(".template.md"):
        return  # templates: the links are deliberate placeholders
    directory = os.path.dirname(path)
    text = build_scan_text(content)
    newline_offsets = [mo.start() for mo in re.finditer("\n", text)]

    def lineno_at(off):
        return bisect.bisect_right(newline_offsets, off) + 1

    for match in LINK_RE.finditer(text):
        target = match.group(1).strip()
        if not target:
            continue
        lineno = lineno_at(match.start())
        if target.startswith("/"):
            report(path, lineno, "leading-slash-link",
                   f"link with a leading slash is forbidden (Spec §3): {target}")
            continue
        if "://" in target or target.startswith("mailto:"):
            continue  # external link, out of scope
        if "#" in target:
            file_part, anchor = target.split("#", 1)
        else:
            file_part, anchor = target, None
        file_part = file_part.strip()

        if file_part == "":
            resolved = path  # anchor in the same file
        else:
            decoded = unquote(file_part)
            resolved = os.path.normpath(os.path.join(directory, decoded))
            if not os.path.exists(resolved):
                report(path, lineno, "broken-link",
                       f"target not found: {target} (resolved: {resolved})")
                continue

        if anchor:
            anchor_dec = unquote(anchor).strip().lower()
            if anchor_dec and resolved.endswith(".md") and os.path.isfile(resolved):
                if anchor_dec not in heading_slugs(resolved):
                    where = "this file" if file_part == "" else os.path.basename(resolved)
                    report(path, lineno, "broken-anchor",
                           f"anchor not found: #{anchor} (no heading of {where} produces this slug)")


# --- Frontmatter: deterministic stdlib validator (no PyYAML dependency) ------

def parse_frontmatter_block(lines):
    """Returns (block_lines, start_index, end_index) or (None, None, None)."""
    if not lines or lines[0].strip() != "---":
        return None, None, None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i], 0, i
    return None, None, None


def _leading_ws(raw):
    return raw[:len(raw) - len(raw.lstrip(" \t"))]


def frontmatter_structural_error(block):
    """Detects load-bearing YAML breakage in pure stdlib: a tab in the
    indentation, or a top-level line that is neither 'key: value' nor a
    list item. Returns (offset, message) or None."""
    for offset, raw in enumerate(block):
        if "\t" in _leading_ws(raw):
            return offset, "tab in the indentation (forbidden in YAML)"
    for offset, raw in enumerate(block):
        s = raw.strip()
        if not s or s.startswith("#"):
            continue
        if raw[:1] in (" ", "\t"):
            continue  # indented line: continuation / list / nesting
        if s.startswith("- "):
            continue  # top-level list item
        if not FM_KEY_RE.match(raw):
            return offset, f"unrecognized line (expected 'key: value'): {s}"
    return None


def top_level_kv(block):
    kv = {}
    line_of = {}
    for offset, raw in enumerate(block):
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if raw[:1] in (" ", "\t"):
            continue
        m = FM_KEY_RE.match(raw)
        if m and m.group(1) not in kv:
            kv[m.group(1)] = m.group(2).strip()
            line_of[m.group(1)] = offset
    return kv, line_of


def _scalar(value):
    return value.strip().strip('"').strip("'").strip()


def _strip_comment(v):
    """Removes a trailing YAML comment (a '#' preceded by whitespace): the template
    and the 0.8 migration write `awaiting: []   # ...`, which must stay valid."""
    return re.split(r"\s+#", v or "", maxsplit=1)[0].strip()


def check_awaiting(path, block, kv, line_of):
    """Structure of the awaiting field (Spec §16), on workstreams only:
    either [], or a list of who/what/kind/since entries (+ optional blocks).
    SOFT finding: the lint says what does not hold, corrects nothing and
    never invents a wait from the prose."""
    offset = line_of["awaiting"]
    inline = _strip_comment(_scalar(kv["awaiting"]))
    if inline:
        if inline.replace(" ", "") != "[]":
            report(path, offset + 2, "awaiting-structure",
                   f"awaiting expects '[]' or a list of indented entries, found: {inline}")
        return

    entries = []  # [(offset of the entry, {key: (offset, value)})]
    current = None
    i = offset + 1
    while i < len(block):
        raw = block[i]
        if not raw.strip() or raw.lstrip().startswith("#"):
            i += 1
            continue
        if raw[:1] not in (" ", "\t"):
            break  # back to the top level: the list is over
        m = AWAITING_ITEM_RE.match(raw)
        if m:
            current = {m.group(1): (i, _strip_comment(m.group(2)))}
            entries.append((i, current))
            i += 1
            continue
        m = AWAITING_KEY_RE.match(raw)
        if m and current is not None:
            current[m.group(1)] = (i, _strip_comment(m.group(2)))
            i += 1
            continue
        report(path, i + 2, "awaiting-structure",
               f"unrecognized wait line (expected '  - key: value' then "
               f"'    key: value'): {raw.strip()}")
        i += 1

    if not entries:
        report(path, offset + 2, "awaiting-structure",
               "awaiting declared without any entry: write 'awaiting: []' when nothing is waiting")
        return

    for eoff, entry in entries:
        for key in ("who", "what", "kind", "since"):
            if key not in entry or not _scalar(entry[key][1]):
                report(path, eoff + 2, "awaiting-structure",
                       f"wait entry without '{key}:' (who, what, kind and since "
                       f"are required, blocks is optional)")
        if "kind" in entry:
            kind = _scalar(entry["kind"][1])
            if kind and kind not in AWAITING_KINDS:
                report(path, entry["kind"][0] + 2, "awaiting-structure",
                       f"kind expects 'decision' or 'action', found: {kind}")
        if "since" in entry:
            since = _scalar(entry["since"][1])
            bad = not ISO_DATE_RE.match(since)
            if not bad:
                try:
                    date(int(since[0:4]), int(since[5:7]), int(since[8:10]))
                except ValueError:
                    bad = True
            if since and bad:
                report(path, entry["since"][0] + 2, "awaiting-structure",
                       f"since expects a YYYY-MM-DD date (the day the wait "
                       f"began), found: {since}")
        if "who" in entry:
            who = _scalar(entry["who"][1])
            if who and (" " in who or "@" in who):
                report(path, entry["who"][0] + 2, "awaiting-structure",
                       f"who expects a short, stable MOS identifier (no space "
                       f"and no '@', not an e-mail nor a full name), found: {who}")


def check_frontmatter(path, lines, basename):
    exempt = is_exempt_from_frontmatter(path, basename)
    # Templates, skills, agents and sources keep their own formats
    # (placeholders, Claude Code frontmatter): entirely out of scope.
    # Entry points (index/README/QUICKSTART/AGENTS/CLAUDE) are not REQUIRED
    # to have a frontmatter, but if they have one, it must be VALID
    # (a real trap: an unquoted ":" in QUICKSTART broke the Obsidian rendering).
    fully_out = (basename.endswith(".template.md") or basename == "SKILL.md"
                 or is_lintignored(path))
    parts = os.path.normpath(path).split(os.sep)
    if "sources" in parts or (".claude" in parts and "agents" in parts):
        fully_out = True
    if fully_out:
        return

    is_log = basename == "log.md"

    block, start, end = parse_frontmatter_block(lines)

    if block is None:
        # Editor trap: the --- delimiter turns into an em dash (—).
        if lines and DASH_LINE_RE.match(lines[0]) and lines[0].strip() != "---":
            report(path, 1, "em-dash-delimiter",
                   "frontmatter delimiter written as an em/en dash instead of '---'")
            return
        if is_log or exempt:
            return  # frontmatter tolerated but not required
        report(path, 1, "missing-frontmatter",
               "no YAML frontmatter (--- ... ---) at the top of the file")
        return

    # Trap: unquoted ":" in title/description (breaks the YAML)
    for offset, raw in enumerate(block):
        m = FM_KEY_RE.match(raw)
        if not m:
            continue
        key, value = m.group(1), m.group(2).strip()
        if key not in ("title", "description") or not value:
            continue
        quoted = value.startswith('"') or value.startswith("'")
        if not quoted and re.search(r'\S : \S|\S :\s*$', value):
            report(path, offset + 2, "yaml-unquoted-colon",
                   f"'{key}:' contains an unquoted ':', quote the value: {value}")

    # Structural validity (stdlib, deterministic)
    err = frontmatter_structural_error(block)
    if err:
        off, msg = err
        report(path, off + 2, "invalid-frontmatter", msg)
        return

    kv, line_of = top_level_kv(block)

    # review_when: dated and past due → soft finding (0.4.x). Undated = event
    # trigger, silently ignored.
    if "review_when" in kv:
        val = kv["review_when"].strip().strip('"').strip("'").strip()
        dm = re.match(r'(\d{4})-(\d{2})-(\d{2})', val)
        if dm:
            try:
                due = date(int(dm.group(1)), int(dm.group(2)), int(dm.group(3)))
                if due < TODAY:
                    report(path, line_of["review_when"] + 2, "review_when-due",
                           f"review_when past due: {dm.group(0)} (deadline passed; the page "
                           f"no longer stands on its own, reconfirm or update it)")
            except ValueError:
                pass  # malformed date: not our business here

    # awaiting: structure only, on workstreams and if the key is present.
    if kv.get("type", "").strip() == "work" and "awaiting" in kv:
        check_awaiting(path, block, kv, line_of)

    # Presence of type:
    if not kv.get("type"):
        if is_log or exempt:
            return  # type: tolerated but not required on logs and entry points
        report(path, start + 1, "missing-type",
               "frontmatter present but the 'type:' field is missing or empty")


def lint_file(path):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            content = fh.read()
    except (OSError, UnicodeDecodeError) as exc:
        report(path, 1, "unreadable", str(exc))
        return
    basename = os.path.basename(path)
    if is_lintignored(path):
        return  # area declared out of scope by the repo's .lintignore
    check_links(path, content)
    if not is_loose_production(path):
        check_frontmatter(path, content.splitlines(), basename)


def main():
    paths = [p for p in sys.argv[1:] if p.strip()]
    for path in paths:
        lint_file(path)
    for line in findings:
        print(line)
    print(f"--- lint.sh: {len(findings)} finding(s) in {len(paths)} file(s) "
          f"— full Markdown parsing (fences/inline/anchors), deterministic frontmatter (stdlib) ---")
    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()
PYEOF
  REPORT=$(python3 "$PYSCRIPT" "${FILE_ARR[@]}")
  STATUS=$?
  rm -f "$PYSCRIPT"
else
  REPORT=$(run_bash_fallback "${FILE_ARR[@]}")
  STATUS=$?
fi

echo "$REPORT"

if [ "$HOOK_MODE" -eq 1 ]; then
  exit 0  # PostToolUse: we report, we never block
fi

# --- Structure (0.12), standalone mode on a folder only; bash, no python needed.
#   g. nesting (Spec §17, one level): an in-progress/ or done/ folder that sits
#      below another in-progress/ or done/ is outside the production contract.
#   h. sizes the Spec bounds (§8, §9): log.md over 150 KB, AGENTS.md over 200
#      lines, read at the top of the folder linted. Thresholds can be moved with
#      MANENCE_LOG_MAX_BYTES and MANENCE_AGENTS_MAX_LINES.
if [ -d "$TARGET" ]; then
  STRUCT=""
  _root=${TARGET%/}
  while IFS= read -r _d; do
    [ -n "$_d" ] || continue
    _rel=${_d#"$_root"/}
    _above=$(dirname -- "$_rel")
    case "/$_above/" in
      */in-progress/*|*/done/*)
        STRUCT="${STRUCT}${_d}:1: nested-workstream-folder: $(basename -- "$_d")/ below another in-progress/ or done/ (Spec §17: <domain>/in-progress/ and <domain>/done/, one level, never deeper)
" ;;
    esac
  done <<EOF_DIRS
$(find "$_root" \( -name .git -o -name .obsidian -o -name node_modules \) -prune -o \
    -type d \( -name in-progress -o -name done \) -print 2>/dev/null)
EOF_DIRS
  _logmax=${MANENCE_LOG_MAX_BYTES:-150000}
  _agmax=${MANENCE_AGENTS_MAX_LINES:-200}
  if [ -f "$_root/log.md" ]; then
    _b=$(wc -c < "$_root/log.md" | tr -d ' ')
    if [ "$_b" -gt "$_logmax" ]; then
      STRUCT="${STRUCT}${_root}/log.md:1: size: ${_b} bytes, over ${_logmax} (Spec §8: the review proposes a rotation, scripts/log-rotate.py, played on the user's GO)
"
    fi
  fi
  if [ -f "$_root/AGENTS.md" ]; then
    _l=$(wc -l < "$_root/AGENTS.md" | tr -d ' ')
    if [ "$_l" -gt "$_agmax" ]; then
      STRUCT="${STRUCT}${_root}/AGENTS.md:1: size: ${_l} lines, over ${_agmax} (Spec §9: the review proposes a measured trim)
"
    fi
  fi
  _n=0
  if [ -n "$STRUCT" ]; then
    printf '%s' "$STRUCT"
    _n=$(printf '%s' "$STRUCT" | grep -c . || true)
    STATUS=1
  fi
  echo "--- lint.sh structure: ${_n} finding(s) (nesting, sizes) ---"
fi

exit "$STATUS"
