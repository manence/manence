#!/bin/bash
# Linter mécanique du cadre Manence (couche 5). Remplace le placeholder :
# c'est le "dur" (script vérifiable) qui prend le relais de kb-lint (skill agentique,
# jugement) et sert de méthode de repli quand on n'a pas la vue graphe Obsidian.
#
# Contrôles sur les .md (hors .git/, .obsidian/, node_modules/), voir Spec §1/§3 :
#   a. liens markdown relatifs cassés (cible inexistante, après urldecode des %20),
#      en ignorant les liens cités dans un bloc de code (``` fences) ou en code
#      inline (`backticks`) : ils documentent, ils ne lient pas
#   b. liens à slash initial ](/...) (interdits par la Spec §3)
#   c. ancres cassées : un lien fichier.md#ancre (ou #ancre dans le même fichier)
#      dont aucun titre de la cible ne produit le slug GitHub correspondant
#      (algo github-slugger : minuscule, accents conservés, ponctuation retirée sauf
#      tiret/underscore, espaces→tirets, doublons -1/-2). Leçon d'origine : le slug
#      d'un titre traduit casse (2026-07-09)
#   d. frontmatter YAML présent + parseable + champ type: (sauf fichiers exemptés) ;
#      ":" non quoté dans title/description ; délimiteur en tiret cadratin (—) au
#      lieu de --- (piège d'éditeur qui casse le YAML)
#   e. review_when: daté et échu (date YYYY-MM-DD passée) → constat doux (0.4.x).
#      Les valeurs non datées (déclencheurs-événements) sont ignorées en silence.
#
# Portabilité / dépendances (outil LIVRÉ aux utilisateurs) :
#   - python3 OPTIONNEL : présent → parsing complet (Markdown fences/inline, ancres,
#     frontmatter, review_when). Absent → mode DÉGRADÉ annoncé : liens en regex
#     ligne à ligne (bash pur), le reste non vérifié. Aucune régression de format.
#   - PyYAML N'EST PLUS requis ni utilisé : le verdict frontmatter est produit par un
#     validateur stdlib déterministe (même résultat sur toute machine, avec ou sans
#     PyYAML installé). Le niveau de parsing est annoncé dans la ligne de résumé.
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

# --- Repli DÉGRADÉ sans python3 : les deux contrôles historiques de liens en bash
# pur (regex ligne à ligne, code inline retiré), honorant .lintignore et les
# gabarits. Ancres, frontmatter et review_when ne sont PAS vérifiés (annoncé). ---
run_bash_fallback() {
  local findings=0
  local nfiles=$#

  # racine du repo (dossier ancêtre portant .lintignore ou .git) pour un fichier
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
      # retire le code inline `...` (documentation, pas des liens)
      local line
      line=$(printf '%s' "$rawline" | sed 's/`[^`]*`/ /g')
      # extrait chaque cible de lien markdown ](...)
      printf '%s\n' "$line" | grep -oE '\]\([^)]+\)' 2>/dev/null | \
        sed -E 's/^\]\(//; s/\)$//' | while IFS= read -r target; do
          [ -z "$target" ] && continue
          case "$target" in
            /*) printf '%s:%s: lien-slash-initial: lien à slash initial interdit (Spec §3) : %s\n' "$file" "$lineno" "$target"; continue ;;
            *://*|mailto:*|\#*) continue ;;
          esac
          # retire l'ancre, urldecode %20, résout relativement au fichier
          local rel decoded
          rel="${target%%#*}"
          [ -z "$rel" ] && continue
          decoded=$(printf '%s' "$rel" | sed 's/%20/ /g')
          if [ ! -e "$dir/$decoded" ]; then
            printf '%s:%s: lien-casse: cible introuvable : %s\n' "$file" "$lineno" "$target"
          fi
        done
    done < "$file"
  done > /tmp/.lint_bash_$$ 2>/dev/null

  if [ -s /tmp/.lint_bash_$$ ]; then
    cat /tmp/.lint_bash_$$
    findings=$(wc -l < /tmp/.lint_bash_$$ | tr -d ' ')
  fi
  rm -f /tmp/.lint_bash_$$
  echo "--- lint.sh : ${findings} constat(s) sur ${nfiles} fichier(s) — parsing DÉGRADÉ (python3 absent : liens en regex ligne à ligne ; ancres, frontmatter et review_when NON vérifiés) ---"
  [ "$findings" -gt 0 ] && return 1
  return 0
}

# Sonde d'exécution réelle, pas `command -v` : sous Windows 11, un stub
# python3.exe (WindowsApps) qui ouvre le Microsoft Store répond « présent »
# au command -v — le repli dégradé ne se déclenchait jamais et le lint cassait
# (constat d'install réelle, 2026-08-06).
if python3 -c 'pass' >/dev/null 2>&1; then
  # Le corps python part dans un fichier temporaire via une simple redirection
  # (jamais dans un $(...) : le scanner de substitution de bash 3.2 compte les
  # backticks même à l'intérieur d'un heredoc quoté, et un nombre impair casse
  # le parsing). Robuste quel que soit le contenu du script.
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
    "CLAUDE.md",
}

# Lien markdown inline : le texte reste sur une ligne (comportement historique),
# l'URL peut se replier une fois (liens multilignes raisonnables).
LINK_RE = re.compile(r'!?\[[^\]\n]*\]\(([^)\n]*(?:\n[^)\n]*)?)\)')
FM_KEY_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_-]*)\s*:\s?(.*)$')
FENCE_RE = re.compile(r'^ {0,3}(`{3,}|~{3,})')
ATX_RE = re.compile(r'^ {0,3}#{1,6}\s+(.*)$')
# tiret cadratin (—, U+2014) ou demi-cadratin (–, U+2013) tenant lieu de délimiteur
DASH_LINE_RE = re.compile(r'^\s*[—–]+\s*$')
# github-slugger : ponctuation retirée (accents et lettres unicode conservés,
# tiret et underscore conservés)
SPECIALS_RE = re.compile(
    "[\\u2000-\\u206F\\u2E00-\\u2E7F\\\\'!\"#$%&()*+,./:;<=>?@\\[\\]^`{|}~\\u2019]")

findings = []
_lintignore_cache = {}
_slug_cache = {}


def report(path, line, kind, detail):
    findings.append(f"{path}:{line}: {kind}: {detail}")


def _repo_root(start_dir):
    """Remonte jusqu'au premier dossier qui contient un .lintignore ou un .git
    (la production vit hors git par doctrine : son .lintignore doit porter quand
    même — sémantique .gitignore)."""
    d = os.path.abspath(start_dir) or "/"
    while True:
        if os.path.isfile(os.path.join(d, ".lintignore")) or os.path.isdir(os.path.join(d, ".git")):
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


def is_exempt_from_frontmatter(path, basename):
    if basename in EXEMPT_BASENAMES:
        return True
    if basename.endswith(".template.md"):
        return True
    if basename == "SKILL.md":
        return True  # format skill Claude Code : frontmatter name/description, pas OKF
    parts = os.path.normpath(path).split(os.sep)
    if "inbox" in parts:
        return True  # inbox/ : capture brute pré-contrat, frictionless par doctrine ;
        # le garde-temps est à la weekly-review : capture > 14 j = triée ou supprimée
    if "sources" in parts:
        return True  # sources/ : inputs bruts immuables (méthode wiki), pas des pages de connaissance
    if ".claude" in parts and "agents" in parts:
        return True  # format sous-agent Claude Code : frontmatter name/description/tools/model, pas OKF
    return False


# --- Slug GitHub (github-slugger) et index des ancres d'un fichier -----------

def github_slug(text):
    """Reproduit github-slugger : lien/image réduits à leur texte visible,
    minuscule, ponctuation retirée (SPECIALS), espaces → tirets. Accents,
    lettres unicode, tiret et underscore conservés."""
    text = re.sub(r'!\[([^\]]*)\]\([^)]*\)', r'\1', text)
    text = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', text)
    text = text.strip()
    text = re.sub(r'\s+#+\s*$', '', text)  # ATX fermé : "## Titre ##"
    text = text.lower()
    text = SPECIALS_RE.sub('', text)
    text = re.sub(r'\s', '-', text)
    return text


def heading_slugs(path):
    """Ensemble des slugs de titres (ATX, hors blocs de code) d'un fichier,
    avec la dé-duplication -1/-2 de github-slugger."""
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


# --- Parsing Markdown des liens (fences + code inline + multiligne) ----------

def strip_inline_code(text):
    """Neutralise les spans de code inline (`...`, ``...``) en préservant les
    positions (remplacement par des espaces, retours à la ligne gardés) pour
    que les offsets restent alignés sur les numéros de ligne."""
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
            i = j  # run non fermé : pas un span, on le laisse
            continue
        for p in range(i, closed_at):
            if res[p] != "\n":
                res[p] = " "
        i = closed_at
    return "".join(res)


def build_scan_text(content):
    """Texte prêt à scanner : lignes de blocs de code (``` / ~~~) blanchies,
    code inline neutralisé, longueurs et retours à la ligne préservés."""
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
        return  # gabarits : les liens sont des placeholders volontaires
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
            report(path, lineno, "lien-slash-initial",
                   f"lien à slash initial interdit (Spec §3) : {target}")
            continue
        if "://" in target or target.startswith("mailto:"):
            continue  # lien externe, hors périmètre
        if "#" in target:
            file_part, anchor = target.split("#", 1)
        else:
            file_part, anchor = target, None
        file_part = file_part.strip()

        if file_part == "":
            resolved = path  # ancre dans le même fichier
        else:
            decoded = unquote(file_part)
            resolved = os.path.normpath(os.path.join(directory, decoded))
            if not os.path.exists(resolved):
                report(path, lineno, "lien-casse",
                       f"cible introuvable : {target} (résolu : {resolved})")
                continue

        if anchor:
            anchor_dec = unquote(anchor).strip().lower()
            if anchor_dec and resolved.endswith(".md") and os.path.isfile(resolved):
                if anchor_dec not in heading_slugs(resolved):
                    where = "ce fichier" if file_part == "" else os.path.basename(resolved)
                    report(path, lineno, "ancre-cassee",
                           f"ancre introuvable : #{anchor} (aucun titre de {where} ne produit ce slug)")


# --- Frontmatter : validateur stdlib déterministe (aucune dépendance PyYAML) -

def parse_frontmatter_block(lines):
    """Retourne (block_lines, start_index, end_index) ou (None, None, None)."""
    if not lines or lines[0].strip() != "---":
        return None, None, None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i], 0, i
    return None, None, None


def _leading_ws(raw):
    return raw[:len(raw) - len(raw.lstrip(" \t"))]


def frontmatter_structural_error(block):
    """Détecte les cassures YAML porteuses en stdlib pur : tabulation dans
    l'indentation, ou ligne de premier niveau qui n'est ni 'clé: valeur' ni un
    item de liste. Retourne (offset, message) ou None."""
    for offset, raw in enumerate(block):
        if "\t" in _leading_ws(raw):
            return offset, "tabulation dans l'indentation (interdit en YAML)"
    for offset, raw in enumerate(block):
        s = raw.strip()
        if not s or s.startswith("#"):
            continue
        if raw[:1] in (" ", "\t"):
            continue  # ligne indentée : continuation / liste / imbrication
        if s.startswith("- "):
            continue  # item de liste de premier niveau
        if not FM_KEY_RE.match(raw):
            return offset, f"ligne non reconnue (attendu 'clé: valeur') : {s}"
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
        # Piège d'éditeur : le délimiteur --- devient un tiret cadratin (—).
        if lines and DASH_LINE_RE.match(lines[0]) and lines[0].strip() != "---":
            report(path, 1, "tiret-cadratin",
                   "délimiteur de frontmatter en tiret cadratin/demi-cadratin au lieu de '---'")
            return
        if is_log or exempt:
            return  # frontmatter toléré mais pas exigé
        report(path, 1, "frontmatter-manquant",
               "pas de frontmatter YAML (--- ... ---) en tête de fichier")
        return

    # Piège : ":" non quoté dans title/description (casse le YAML)
    for offset, raw in enumerate(block):
        m = FM_KEY_RE.match(raw)
        if not m:
            continue
        key, value = m.group(1), m.group(2).strip()
        if key not in ("title", "description") or not value:
            continue
        quoted = value.startswith('"') or value.startswith("'")
        if not quoted and re.search(r'\S : \S|\S :\s*$', value):
            report(path, offset + 2, "yaml-deux-points-non-quote",
                   f"'{key}:' contient un ':' non quoté, quoter la valeur : {value}")

    # Validité structurelle (stdlib, déterministe)
    err = frontmatter_structural_error(block)
    if err:
        off, msg = err
        report(path, off + 2, "frontmatter-invalide", msg)
        return

    kv, line_of = top_level_kv(block)

    # review_when: daté et échu → constat doux (0.4.x). Non daté = déclencheur
    # événement, ignoré en silence.
    if "review_when" in kv:
        val = kv["review_when"].strip().strip('"').strip("'").strip()
        dm = re.match(r'(\d{4})-(\d{2})-(\d{2})', val)
        if dm:
            try:
                due = date(int(dm.group(1)), int(dm.group(2)), int(dm.group(3)))
                if due < TODAY:
                    report(path, line_of["review_when"] + 2, "review_when-echu",
                           f"review_when échu : {dm.group(0)} (échéance passée ; la fiche "
                           f"cesse de faire foi seule, reconfirmer ou mettre à jour)")
            except ValueError:
                pass  # date malformée : pas notre affaire ici

    # Présence de type:
    if not kv.get("type"):
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
    basename = os.path.basename(path)
    if is_lintignored(path):
        return  # zone déclarée hors périmètre par le .lintignore du repo
    check_links(path, content)
    if not is_loose_production(path):
        check_frontmatter(path, content.splitlines(), basename)


def main():
    paths = [p for p in sys.argv[1:] if p.strip()]
    for path in paths:
        lint_file(path)
    for line in findings:
        print(line)
    print(f"--- lint.sh : {len(findings)} constat(s) sur {len(paths)} fichier(s) "
          f"— parsing Markdown complet (fences/inline/ancres), frontmatter déterministe (stdlib) ---")
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
  exit 0  # PostToolUse : on rapporte, on ne bloque jamais
fi

exit "$STATUS"
