#!/usr/bin/env python3
"""mos-map: builds the visual map of a MOS (one self-contained HTML file, no server).

  python3 build.py --coeur <core-root> [--production <root>] [--kb <root>]
      [--nom <name>] [--profil interne|public] [--lang fr|en]
      [--sortie <file.html>] [--ouvrir]

Prerequisites: python3 alone (stdlib). The produced page opens in any recent
browser, offline, on double-click. Public profile: structure, counts and titles
only (never excerpts, descriptions, inbox, bodies or machine paths)."""
import argparse, datetime, json, os, subprocess, sys, tempfile

ICI = os.path.dirname(os.path.abspath(__file__))
TITRES = {"fr": "Le MOS {nom} — la carte", "en": "The {nom} MOS — the map"}

def lire(p):
    with open(p, encoding="utf-8") as f:
        return f.read()

def main():
    ap = argparse.ArgumentParser(description="Visual map of a MOS → one self-contained HTML file.")
    ap.add_argument("--coeur", required=True)
    ap.add_argument("--production", default=None)
    ap.add_argument("--kb", default=None, help="knowledge base as a separate adapter (default: <core>/knowledge-base)")
    ap.add_argument("--nom", default=None)
    ap.add_argument("--profil", choices=["interne", "public"], default="interne")
    ap.add_argument("--lang", choices=["fr", "en"], default="en", help="the map's interface language")
    ap.add_argument("--sortie", default=None)
    ap.add_argument("--ouvrir", action="store_true", help="open the map in the browser")
    a = ap.parse_args()
    nom = a.nom or os.path.basename(os.path.abspath(a.coeur))
    sortie = os.path.abspath(a.sortie or f"carte-{nom}-{a.profil}.html")

    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as tf:
        data_path = tf.name
    try:
        cmd = [sys.executable, os.path.join(ICI, "generate-mos.py"),
               "--coeur", a.coeur, "--profil", a.profil, "--nom", nom,
               "--lang", a.lang, "--sortie", data_path]
        if a.production: cmd += ["--production", a.production]
        if a.kb: cmd += ["--kb", a.kb]
        subprocess.run(cmd, check=True)
        # data goes in LAST, via a single split/join (never re-scanned by other substitutions);
        # `</` and `<!--` are neutralized (script-close and double-escaped tokenizer states)
        donnees = (json.dumps(json.load(open(data_path, encoding="utf-8")), ensure_ascii=False)
                   .replace("</", "<\\/").replace("<!--", "<\\u0021--"))
    finally:
        os.unlink(data_path)

    tpl = (lire(os.path.join(ICI, "template.html"))
           .replace("__DATE__", datetime.date.today().isoformat())
           .replace("__LANG__", a.lang)
           .replace("__TITLE__", TITRES[a.lang].format(nom=nom))
           .replace("__D3__", lire(os.path.join(ICI, "vendor", "d3-slim.min.js"))))
    morceaux = tpl.split("__DATA__")
    assert len(morceaux) == 2, "the template must contain exactly one __DATA__"
    with open(sortie, "w", encoding="utf-8") as f:
        f.write(morceaux[0] + donnees + morceaux[1])
    print(f"{sortie} — {os.path.getsize(sortie)//1024} KB [{a.profil}, {a.lang}]")

    if a.ouvrir:
        if sys.platform == "darwin": subprocess.run(["open", sortie])
        elif os.name == "nt": os.startfile(sortie)  # noqa
        else: subprocess.run(["xdg-open", sortie])

if __name__ == "__main__":
    main()
