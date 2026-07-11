#!/bin/bash
# Linter mécanique du cadre Manence (couche 5). Remplace le placeholder :
# c'est le "dur" (script vérifiable) qui prend le relais de kb-lint (skill agentique,
# jugement) et sert de méthode de repli quand on n'a pas la vue graphe Obsidian.
#
# Contrôles sur les .md (hors .git/, .obsidian/, node_modules/), voir Spec §1/§3 :
#   a. liens markdown relatifs cassés (cible inexistante, après urldecode des %20)
#   b. liens à slash initial ](/...) (interdits par la Spec §3)
#   c. frontmatter YAML présent + parseable + champ type: (sauf fichiers exemptés)
#
# Exemptions structurelles :
#   - la production (Spec §16 : hors git, artefacts jetables) : les chantiers clos
#     (composant de chemin "done", ou l'ancien production/published/) sont exemptés
#     des contrôles c et d (jamais réécrits, L3 ; les liens restent contrôlés) ;
#     dans "in-progress", seul About.md est tenu à l'OKF, les autres artefacts
#     ne sont contrôlés que sur leurs liens
#   - .lintignore à la racine du repo (le dossier qui contient .git) : une ligne
#     par chemin relatif à ignorer entièrement (préfixe ; "#" = commentaire).
#     Pour les zones hors périmètre du lint : corpus hérité, fichiers dans une
#     autre langue, etc.
#
# Deux modes d'usage :
#   - standalone : lint.sh [chemin]   -> un fichier, ou tout le repo (défaut : ".")
#                                         exit 1 s'il y a des constats, 0 sinon
#   - hook       : lint.sh --hook     -> lit le JSON PostToolUse sur stdin
#                                         (tool_input.file_path), lint SEULEMENT
#                                         ce fichier, ne bloque jamais (exit 0)

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
  # PostToolUse : le fichier édité vient du JSON sur stdin, pas d'un argument chemin.
  FILE_PATH=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
  if [ -z "$FILE_PATH" ] || [[ "$FILE_PATH" != *.md ]]; then
    exit 0  # rien à faire : pas de fichier, ou pas un .md
  fi
  TARGET="$FILE_PATH"
elif [ -z "$TARGET" ]; then
  TARGET="."
fi

if [ ! -e "$TARGET" ]; then
  echo "lint.sh : chemin introuvable : $TARGET" >&2
  [ "$HOOK_MODE" -eq 1 ] && exit 0
  exit 0
fi

# Liste des .md à contrôler, en excluant .git/, .obsidian/, node_modules/
if [ -f "$TARGET" ]; then
  FILES="$TARGET"
else
  FILES=$(find "$TARGET" \
    \( -name .git -o -name .obsidian -o -name node_modules \) -prune -o \
    -type f -name '*.md' -print)
fi

if [ -z "$FILES" ]; then
  exit 0  # rien à lint
fi

# (pas de mapfile : macOS embarque bash 3.2, mapfile/readarray n'existent qu'en 4+)
FILE_ARR=()
while IFS= read -r line; do
  [ -n "$line" ] && FILE_ARR+=("$line")
done <<< "$FILES"

REPORT=$(python3 - "${FILE_ARR[@]}" <<'PYEOF'
import os
import re
import sys
from urllib.parse import unquote

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

EXEMPT_BASENAMES = {"index.md", "README.md", "QUICKSTART.md", "CLAUDE.md"}
LINK_RE = re.compile(r'!?\[[^\]]*\]\(([^)]+)\)')
FRONTMATTER_KV_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_-]*):\s?(.*)$')

findings = []

_lintignore_cache = {}


def _repo_root(start_dir):
    """Remonte jusqu'au dossier qui contient .git (ou s'arrête à /)."""
    d = os.path.abspath(start_dir) or "/"
    while True:
        if os.path.isdir(os.path.join(d, ".git")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def is_lintignored(path):
    """Vrai si le fichier matche un préfixe du .lintignore de son repo."""
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
    """Artefacts de production exemptés d'OKF/typographie, liens contrôlés (Spec §16/§8) :
    chantiers clos (done/, ou l'ancien production/published/), et tout artefact
    d'un chantier en cours (in-progress/) autre que son About.md."""
    parts = os.path.normpath(path).split(os.sep)
    if "done" in parts or ("production" in parts and "published" in parts):
        return True
    if "in-progress" in parts and os.path.basename(path) != "About.md":
        return True
    return False


def report(path, line, kind, detail):
    findings.append(f"{path}:{line}: {kind}: {detail}")


def is_exempt_from_frontmatter(path, basename):
    if basename in EXEMPT_BASENAMES:
        return True
    if basename.endswith(".template.md"):
        return True
    if basename == "SKILL.md":
        return True  # format skill Claude Code : frontmatter name/description, pas OKF
    parts = os.path.normpath(path).split(os.sep)
    if "sources" in parts:
        return True  # sources/ : inputs bruts immuables (méthode wiki), pas des pages de connaissance
    if ".claude" in parts and "agents" in parts:
        return True  # format sous-agent Claude Code : frontmatter name/description/tools/model, pas OKF
    return False


CODE_SPAN_RE = re.compile(r'`[^`]*`')


def check_links(path, lines):
    if os.path.basename(path).endswith(".template.md"):
        return  # gabarits : les liens sont des placeholders volontaires
    directory = os.path.dirname(path)
    for lineno, raw_line in enumerate(lines, start=1):
        # les liens cités dans un code span (`...`) documentent, ils ne lient pas
        line = CODE_SPAN_RE.sub("", raw_line)
        for match in LINK_RE.finditer(line):
            target = match.group(1).strip()
            if not target:
                continue
            if target.startswith("/"):
                report(path, lineno, "lien-slash-initial",
                       f"lien à slash initial interdit (Spec §3) : {target}")
                continue
            if "://" in target or target.startswith("mailto:"):
                continue  # lien externe, hors périmètre
            if target.startswith("#"):
                continue  # ancre dans le même fichier
            # cible relative : retire l'ancre, urldecode, résout par rapport au fichier
            relative_target = target.split("#", 1)[0].strip()
            if not relative_target:
                continue
            decoded = unquote(relative_target)
            resolved = os.path.normpath(os.path.join(directory, decoded))
            if not os.path.exists(resolved):
                report(path, lineno, "lien-casse",
                       f"cible introuvable : {target} (résolu : {resolved})")


def parse_frontmatter_block(lines):
    """Retourne (block_lines, start_index, end_index) ou (None, None, None)."""
    if not lines or lines[0].strip() != "---":
        return None, None, None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i], 0, i
    return None, None, None


def check_frontmatter(path, lines, basename):
    exempt = is_exempt_from_frontmatter(path, basename)
    # Les gabarits, skills, agents et sources gardent leurs formats propres
    # (placeholders, frontmatter Claude Code) : entièrement hors périmètre.
    # Les points d'entrée (index/README/QUICKSTART/CLAUDE) ne sont pas TENUS
    # d'avoir un frontmatter, mais s'ils en ont un, il doit être VALIDE
    # (piège vécu : un ":" non quoté dans QUICKSTART cassait le rendu Obsidian).
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
        if is_log or exempt:
            return  # frontmatter toléré mais pas exigé
        report(path, 1, "frontmatter-manquant",
               "pas de frontmatter YAML (--- ... ---) en tête de fichier")
        return

    block_text = "\n".join(block)

    # Piège : ":" non quoté dans title/description (casse le YAML)
    for offset, raw in enumerate(block):
        m = FRONTMATTER_KV_RE.match(raw)
        if not m:
            continue
        key, value = m.group(1), m.group(2).strip()
        if key not in ("title", "description"):
            continue
        if not value:
            continue
        quoted = value.startswith('"') or value.startswith("'")
        if not quoted and re.search(r'\S : \S|\S :\s*$', value):
            report(path, offset + 2, "yaml-deux-points-non-quote",
                   f"'{key}:' contient un ':' non quoté, quoter la valeur : {value}")

    # Validité YAML + présence de type:
    parsed = None
    yaml_error = None
    if HAS_YAML:
        try:
            parsed = yaml.safe_load(block_text)
        except yaml.YAMLError as exc:
            yaml_error = str(exc).splitlines()[0]
    else:
        # Validation naïve sans le module yaml : on ne peut pas confirmer la
        # validité complète, seulement vérifier la présence de la clé type:.
        parsed = {}
        for raw in block:
            m = FRONTMATTER_KV_RE.match(raw)
            if m:
                parsed[m.group(1)] = m.group(2).strip()

    if yaml_error:
        report(path, start + 1, "frontmatter-invalide", yaml_error)
        return

    if not isinstance(parsed, dict) or not parsed.get("type"):
        if is_log or exempt:
            return  # type: toléré mais pas exigé sur les logs et points d'entrée
        report(path, start + 1, "type-manquant",
               "frontmatter présent mais champ 'type:' absent ou vide")



def lint_file(path):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            content = fh.read()
    except (OSError, UnicodeDecodeError) as exc:
        report(path, 1, "lecture-impossible", str(exc))
        return
    lines = content.splitlines()
    basename = os.path.basename(path)
    if is_lintignored(path):
        return  # zone déclarée hors périmètre par le .lintignore du repo
    check_links(path, lines)
    if not is_loose_production(path):
        check_frontmatter(path, lines, basename)


def main():
    paths = [p for p in sys.argv[1:] if p.strip()]
    for path in paths:
        lint_file(path)
    for line in findings:
        print(line)
    print(f"--- lint.sh : {len(findings)} constat(s) sur {len(paths)} fichier(s) ---")
    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()
PYEOF
)
STATUS=$?

echo "$REPORT"

if [ "$HOOK_MODE" -eq 1 ]; then
  exit 0  # PostToolUse : on rapporte, on ne bloque jamais
fi

exit "$STATUS"
