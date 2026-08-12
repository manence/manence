#!/usr/bin/env python3
"""Generates the map data of a MOS (schema 2). One MOS per run, paths passed
as arguments (never guessed), disclosure profiles.

  python3 generate-mos.py --coeur <core-root> [--production <root>] [--kb <root>]
      [--nom <name>] [--profil interne|public] [--lang fr|en] [--sortie <file.json>]

Connectors: read from <core>/.claude/mos-map.json (declarative); absent otherwise.
Public profile: structure, counts and titles only — never excerpts, descriptions,
inbox items, journal titles, file lists or machine paths."""
import argparse, json, os, re, sys, unicodedata

FM_RE = re.compile(r"^---\r?\n(.*?)\r?\n---", re.S)
LINK_RE = re.compile(r"\]\(([^)#\s]+\.md)(?:#[^)]*)?\)")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
ETATS_CLOS = {"done", "published"}          # published/: legacy alias (Spec §17)
RESERVES_KB = {"log.md"}                    # reserved names: out of the graph and the tree
EXCL_DIRS = {"node_modules", ".git", "dist", ".vercel", "__pycache__", ".obsidian"}

# Generator warnings are USER-FACING (they land in the map's footer) → bilingual.
AVERTISSEMENTS = {
    "en": {
        "pas_de_carte": "no .claude/mos-map.json: default attachments (KB + production)",
        "schema_inconnu": "mos-map.json: unknown schema {v!r} (2 expected), attachments ignored",
        "illisible": "mos-map.json unreadable: {e}",
        "log_ignorees": "journal: {n} dated entr{y} in an unexpected format, ignored",
    },
    "fr": {
        "pas_de_carte": "pas de .claude/mos-map.json : attaches par défaut (KB + production)",
        "schema_inconnu": "mos-map.json : schéma {v!r} inconnu (2 attendu), attaches ignorées",
        "illisible": "mos-map.json illisible : {e}",
        "log_ignorees": "log : {n} entrée(s) datée(s) au format inattendu, ignorée(s)",
    },
}

def lire(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read().lstrip("﻿").replace("\r\n", "\n")

def frontmatter(text):
    m = FM_RE.match(text)
    fm = {}
    if m:
        for line in m.group(1).splitlines():
            mm = re.match(r"^(\w[\w_-]*):\s*(.*)$", line)
            if mm:
                fm[mm.group(1)] = mm.group(2).strip().strip('"')
    return fm, (text[m.end():] if m else text)

def excerpt(body):
    for p in re.split(r"\n\s*\n", body):
        p = p.strip()
        if p and not p.startswith(("#", "<!--", "|", "-", "!", "```", ">")):
            return re.sub(r"\s+", " ", p)[:340]
    return ""

def statut(fm):
    v = (fm.get("status") or "").split()
    return v[0] if v else ""

def date_ou_vide(v):
    v = (v or "").strip()
    return v if DATE_RE.match(v) else ""

def normaliser_type(t):
    t = unicodedata.normalize("NFD", t.strip().lower())
    return "".join(c for c in t if unicodedata.category(c) != "Mn")

def scan_mos(nom, coeur, prod_root, profil, kb_root=None, lang="en"):
    public = profil == "public"
    W = AVERTISSEMENTS.get(lang, AVERTISSEMENTS["en"])
    d = {"nom": nom, "profil": profil, "fiches": {}, "edges": [], "tree": [],
         "log": [], "inbox": [], "skills": [], "attaches": [], "routines": [], "meta": {}}
    avertissements = []

    # --- attachments: declarative (schema 2: vertices 0-5, 0 = north then clockwise) ---
    mp = os.path.join(coeur, ".claude", "mos-map.json")
    if os.path.isfile(mp):
        try:
            carte = json.loads(lire(mp))
            if carte.get("schema") == 2:
                d["attaches"] = carte.get("attaches", [])
                d["routines"] = carte.get("routines", [])
            else:
                avertissements.append(W["schema_inconnu"].format(v=carte.get("schema")))
        except Exception as e:
            avertissements.append(W["illisible"].format(e=e))
    else:
        avertissements.append(W["pas_de_carte"])
    # KB and production exist even undeclared: the pillars get their vertices by default
    natures = {a.get("nature") for a in d["attaches"]}
    if "production" not in natures:
        d["attaches"].append({"sommet": 0, "id": "production", "nature": "production", "nom": "Production", "resume": ""})
    if "kb" not in natures:
        d["attaches"].append({"sommet": 3, "id": "kb", "nature": "kb", "nom": "Knowledge base", "resume": ""})

    # --- journal: sorted newest-first, types normalized, malformed entries counted ---
    lp = os.path.join(coeur, "log.md")
    ignorees = 0
    if os.path.isfile(lp):
        txt = lire(lp)
        for ligne in re.findall(r"^## \[.*$", txt, re.M):
            m = re.match(r"^## \[(\d{4}-\d{2}-\d{2})\] ([^|\n]+)\|(.*)$", ligne)
            if m:
                d["log"].append({"date": m.group(1), "type": normaliser_type(m.group(2)),
                                 "title": "" if public else m.group(3).strip()})
            else:
                ignorees += 1
        d["log"].sort(key=lambda e: e["date"], reverse=True)  # stable: file order breaks ties
    if ignorees:
        avertissements.append(W["log_ignorees"].format(n=ignorees, y="ies" if ignorees > 1 else "y"))

    # --- inbox: items with their real title (frontmatter or first H1) and an excerpt ---
    ib = os.path.join(coeur, "inbox")
    arbre_inbox = {"name": "inbox", "path": "inbox", "kind": "dir", "children": []}
    n_inbox = 0
    if os.path.isdir(ib):
        for f in sorted(os.listdir(ib)):
            if not f.endswith(".md"):
                continue
            n_inbox += 1
            if public:
                continue
            m = re.match(r"(\d{4}-\d{2}-\d{2})-(.*)\.md", f)
            fm, body = frontmatter(lire(os.path.join(ib, f)))
            h1 = re.search(r"^# (.+)$", body, re.M)
            titre = fm.get("title") or (h1.group(1).strip() if h1 else (m.group(2) if m else f[:-3]).replace("-", " "))
            item = {"date": m.group(1) if m else "", "name": titre, "excerpt": excerpt(body)}
            d["inbox"].append(item)
            arbre_inbox["children"].append({"name": f, "path": "inbox/" + f, "kind": "inboxitem",
                "meta": {"title": titre, "date": item["date"], "excerpt": item["excerpt"],
                         "body": body.strip()[:80000]}})

    # --- skills ---
    sk = os.path.join(coeur, ".claude", "skills")
    if os.path.isdir(sk):
        for s in sorted(os.listdir(sk)):
            sp = os.path.join(sk, s, "SKILL.md")
            if os.path.isfile(sp):
                fm, _ = frontmatter(lire(sp))
                d["skills"].append({"name": s, "desc": "" if public else fm.get("description", "")})

    # --- knowledge base: pages, deduplicated links, index.md = catalogs (out of the graph) ---
    # the KB may be a separate adapter (older-generation MOS): --kb points at it
    KB = kb_root or os.path.join(coeur, "knowledge-base")
    kb_files = {}
    if os.path.isdir(KB):
        for root, dirs, files in os.walk(KB):
            dirs[:] = [x for x in dirs if not x.startswith(".") and x not in EXCL_DIRS]
            for f in files:
                if f.endswith(".md") and f not in RESERVES_KB:
                    rel = os.path.relpath(os.path.join(root, f), KB).replace(os.sep, "/")
                    kb_files[rel] = os.path.join(root, f)
    paires = set()
    for rel, path in sorted(kb_files.items()):
        txt = lire(path)
        fm, body = frontmatter(txt)
        chemin = "knowledge-base/" + rel
        est_index = os.path.basename(rel) == "index.md"
        d["fiches"][chemin] = {
            "title": fm.get("title", os.path.basename(rel)[:-3]),
            "type": "catalogue" if est_index else fm.get("type", ""),
            "status": statut(fm), "review": "" if public else fm.get("review_when", ""),
            "desc": "" if public else fm.get("description", "")[:260],
            "excerpt": "" if public else excerpt(body),
            "body": "" if public else body.strip()[:80000], "index": est_index}
        for target in LINK_RE.findall(txt):
            resolved = os.path.normpath(os.path.join(os.path.dirname(rel), target)).replace(os.sep, "/")
            if resolved in kb_files and resolved != rel:
                # index files are catalogs (reserved name, Spec §4): their links are plumbing,
                # not the web of knowledge
                if est_index or os.path.basename(resolved) == "index.md":
                    continue
                paires.add(("knowledge-base/" + rel, "knowledge-base/" + resolved))
    d["edges"] = [{"a": a, "b": b} for a, b in sorted(paires)]

    # --- trees ---
    def noeud_dir(nom_d, chemin):
        return {"name": nom_d, "path": chemin, "kind": "dir", "children": []}

    def sous_arbre_kb():
        racine = noeud_dir("knowledge-base", "knowledge-base")
        dossiers = {"knowledge-base": racine}
        for rel in sorted(kb_files):
            parts = ("knowledge-base/" + rel).split("/")
            for i in range(1, len(parts) - 1):
                c = "/".join(parts[:i + 1])
                if c not in dossiers:
                    dossiers[c] = noeud_dir(parts[i], c)
                    dossiers["/".join(parts[:i])]["children"].append(dossiers[c])
            dossiers["/".join(parts[:-1])]["children"].append(
                {"name": parts[-1], "path": "/".join(parts), "kind": "fiche"})
        return racine

    budget_md = [1_500_000]  # global budget for embedded .md bodies (characters)

    def arbre_fichiers(base_abs, base_chemin, plafond=300):
        """Materializes subdirectories (breadcrumb segments must exist in the tree).
        .md files embed their body (interne profile, ≤80 KB each, global budget)."""
        racine_l, total = [], 0
        dossiers = {}
        for r2, d2, f2 in os.walk(base_abs):
            d2[:] = [x for x in d2 if x not in EXCL_DIRS and not x.startswith(".")]
            for f in sorted(f2):
                if total >= plafond:
                    racine_l.append({"name": f"… ({plafond}+)", "path": base_chemin + "/_tronque",
                                     "kind": "file"})
                    return racine_l, total
                total += 1
                abs_f = os.path.join(r2, f)
                rel = os.path.relpath(abs_f, base_abs).replace(os.sep, "/")
                parts = rel.split("/")
                port = racine_l
                for i in range(len(parts) - 1):
                    c = base_chemin + "/" + "/".join(parts[:i + 1])
                    if c not in dossiers:
                        dossiers[c] = noeud_dir(parts[i], c)
                        port.append(dossiers[c])
                    port = dossiers[c]["children"]
                fichier = {"name": parts[-1], "path": base_chemin + "/" + rel, "kind": "file",
                           "size": os.path.getsize(abs_f)}
                if (not public and f.endswith(".md") and fichier["size"] <= 80_000
                        and budget_md[0] > 0):
                    corps = frontmatter(lire(abs_f))[1].strip()
                    fichier["body"] = corps
                    budget_md[0] -= len(corps)
                port.append(fichier)
        return racine_l, total

    def sous_arbre_prod():
        racine = noeud_dir("production", "production")
        actifs = clos = 0
        if not os.path.isdir(prod_root):
            return racine, actifs, clos
        for dom in sorted(os.listdir(prod_root)):
            dp = os.path.join(prod_root, dom)
            if not os.path.isdir(dp) or dom.startswith("."):
                continue
            nd = noeud_dir(dom, f"production/{dom}")
            for etat in sorted(os.listdir(dp)):
                ep = os.path.join(dp, etat)
                if not os.path.isdir(ep) or etat.startswith(".") or etat in EXCL_DIRS:
                    continue
                ne = noeud_dir(etat, f"production/{dom}/{etat}")
                for ch in sorted(os.listdir(ep)):
                    chp = os.path.join(ep, ch)
                    if not os.path.isdir(chp):
                        continue
                    chemin = f"production/{dom}/{etat}/{ch}"
                    nc = noeud_dir(ch, chemin)
                    about = os.path.join(chp, "About.md")
                    fm = frontmatter(lire(about))[0] if os.path.isfile(about) else {}
                    enfants, n_fichiers = ([], 0) if public else arbre_fichiers(chp, chemin)
                    nc["children"] = enfants
                    est_clos = etat in ETATS_CLOS
                    nc["meta"] = {"title": fm.get("title", ch),
                                  "desc": "" if public else fm.get("description", ""),
                                  "status": statut(fm),
                                  "date": date_ou_vide(fm.get("timestamp")) or date_ou_vide(f"{ch[:4]}-{ch[4:6]}-{ch[6:8]}"),
                                  "clos": est_clos, "n_files": n_fichiers}
                    if est_clos:
                        clos += 1
                    else:
                        actifs += 1
                    ne["children"].append(nc)
                nd["children"].append(ne)
            racine["children"].append(nd)
        return racine, actifs, clos

    arbre_prod, actifs, clos = sous_arbre_prod()
    d["tree"] = [sous_arbre_kb(), arbre_prod, arbre_inbox]
    d["meta"] = {
        "kb_fiches": sum(1 for f in d["fiches"].values() if not f["index"]),
        "kb_index": sum(1 for f in d["fiches"].values() if f["index"]),
        "kb_domaines": sorted({r.split("/")[0] for r in kb_files if "/" in r}),
        "kb_liens": len(d["edges"]),
        "chantiers_actifs": actifs, "chantiers_clos": clos,
        "inbox_total": n_inbox, "avertissements": avertissements}
    vp = os.path.join(coeur, ".claude", "manence-version")
    d["meta"]["version"] = lire(vp).strip().lstrip("v") if os.path.isfile(vp) else ""
    if not public:  # absolute roots: for the "open locally" links (never in public)
        d["meta"]["racine_coeur"] = coeur
        d["meta"]["racine_production"] = prod_root
    return d

def main():
    ap = argparse.ArgumentParser(description="Map of a MOS: scan → JSON (schema 2).")
    ap.add_argument("--coeur", required=True, help="root of the core (the MOS's repository)")
    ap.add_argument("--production", default=None,
                    help="production root (default: $MOS_PRODUCTION_ROOT, else <core>/../production)")
    ap.add_argument("--kb", default=None,
                    help="knowledge-base root when it is a separate adapter (default: <core>/knowledge-base)")
    ap.add_argument("--nom", default=None, help="display name (default: the core's basename)")
    ap.add_argument("--profil", choices=["interne", "public"], default="interne")
    ap.add_argument("--lang", choices=["fr", "en"], default="en",
                    help="language of the generator's warnings (the map UI language is set at build)")
    ap.add_argument("--sortie", default=None, help="output JSON file")
    a = ap.parse_args()
    coeur = os.path.abspath(a.coeur)
    if not os.path.isdir(coeur):
        sys.exit(f"core not found: {coeur}")
    prod = os.path.abspath(a.production or os.environ.get("MOS_PRODUCTION_ROOT")
                           or os.path.join(coeur, "..", "production"))
    nom = a.nom or os.path.basename(coeur)
    data = {"schema": 2, "mos": scan_mos(nom, coeur, prod, a.profil,
                                         os.path.abspath(a.kb) if a.kb else None, a.lang)}
    sortie = a.sortie or os.path.join(os.getcwd(), f"mos-{nom}-{a.profil}.json")
    with open(sortie, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    m = data["mos"]["meta"]
    print(f"{nom} [{a.profil}] → {sortie}: kb {m['kb_fiches']} pages (+{m['kb_index']} index)/"
          f"{m['kb_liens']} links · workstreams {m['chantiers_actifs']}+{m['chantiers_clos']} · "
          f"journal {len(data['mos']['log'])} · inbox {m['inbox_total']} · v{m['version'] or '?'}")
    for av in m["avertissements"]:
        print(f"  ⚠ {av}")

if __name__ == "__main__":
    main()
