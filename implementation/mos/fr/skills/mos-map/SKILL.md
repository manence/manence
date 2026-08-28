---
name: mos-map
description: Génère la carte visuelle d'un MOS — un fichier HTML autonome (zéro serveur, hors ligne, double-clic) montrant l'hexagone et ses attaches (knowledge base, production, connecteurs), l'explorateur des répertoires, le graphe local du savoir avec recherche plein texte, le journal en frise. Scan en lecture seule du MOS réel ; profils de divulgation interne/public. À lancer quand l'utilisateur veut « voir » son MOS, régénérer la carte après du travail, ou produire une carte partageable.
---

# mos-map, la carte visuelle du MOS

## But
Rendre un MOS visible d'un regard : **rien n'est dessiné, tout est généré** depuis les fichiers réels. La grammaire : un type d'objet, un rendu — le MOS en façade (l'hexagone, sommets 0-5 : 0 = nord pour la production, 3 = sud pour la knowledge base, connecteurs sur les diagonales), un répertoire en explorateur, un corpus lié en graphe local scopé, une fiche en page rendue (markdown, liens internes navigables), le journal en frise.

## Usage
```
python3 .claude/skills/mos-map/build.py --coeur <racine-du-cœur> [options] --ouvrir
```
- `--coeur` (requis) : la racine du repo du MOS.
- `--production` : la racine de production (défaut : `$MOS_PRODUCTION_ROOT`, sinon `<cœur>/../production`).
- `--kb` : si la knowledge base est un **adaptateur séparé** (MOS d'ancienne génération), sa racine.
- `--lang fr|en` : la langue de l'interface de la carte (défaut : `en` — passer `fr` pour un système en français).
- `--profil interne|public` : `interne` (défaut) embarque descriptions, extraits, corps des .md, inbox et chemins machine ; `public` ne sort que **structure, comptes et titres**.
- `--sortie` : le fichier produit (défaut : `carte-<nom>-<profil>.html` dans le cwd) ; `--ouvrir` : l'ouvre dans le navigateur.

Exemple — ce MOS : `python3 .claude/skills/mos-map/build.py --coeur . --lang fr --ouvrir`

## Ce que la carte lit
- Les organes : `log.md` (entrées `## [date] type | titre`, triées, types normalisés), `inbox/`, `.claude/skills/`, `knowledge-base/` (fiches OKF, liens markdown réels — les `index.md` sont des catalogues, hors graphe), la production (`in-progress`/`done`, alias legacy `published`).
- **`.claude/mos-map.json`** (schema 2, livré avec les deux piliers) : les **attaches** de l'hexagone (sommet 0-5, nature `kb | production | mos | git | externe`, nom d'affichage, résumé en une ligne, liens sortants, `visible`) et les **routines déclarées** (cadence + état réel). À tenir aligné sur la carte des connecteurs d'`AGENTS.md` : c'est le skill `connect-adapter` qui écrit les deux.

## Garde-fous
- **Lecture seule** : le scan n'écrit rien dans le MOS ; la carte est une **photo datée** — la rafraîchir = relancer la commande (candidat : la régénérer à chaque weekly-review).
- **Confidentialité** : le fichier interne contient le corpus — il se partage comme un document sensible. Pour un tiers : `--profil public`. Pour un usage marketing : un **jeu de données synthétique**, jamais un corpus réel (même en public, les titres restent des faits). Un adaptateur confidentiel (CLAUDE.local.md) n'est jamais scanné ni déclaré.
- **Rien ne se publie sans GO explicite** (page hébergée, artifact partagé, site).
- Prérequis : `python3` (stdlib seule) pour générer ; un navigateur récent pour consulter. Aucun serveur, aucun réseau, aucune dépendance. `d3-slim.min.js` vendorisé (licence ISC, © Mike Bostock).
