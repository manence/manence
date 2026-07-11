---
name: kb-ingest
description: Intègre une nouvelle source dans la knowledge-base selon la méthode wiki (Karpathy), lire, résumer en une page concept, mettre à jour l'index et les pages liées, signaler les contradictions, logger. À utiliser quand on ajoute un article, un PDF, un transcript ou des notes brutes au savoir du projet.
---

# kb-ingest, intégrer une source

## But
Transformer une source brute en **connaissance intégrée**, sans empiler des doublons. Loi L7 : *ingérer = intégrer*, pas déposer.

## Entrée
Une source : un fichier dans `sources/` ou `inbox/`, ou une URL / un chemin fourni par l'utilisateur.

## Procédure
1. **Lire** la source en entier.
2. **Discuter** avec l'utilisateur les 3-5 points clés à retenir, et attendre sa validation. On ne retient pas tout (loi L1 : haut signal).
3. **Écrire / mettre à jour la page concept** dans `knowledge-base/` : un concept = un fichier (`domaine/chose-precise.md`), frontmatter OKF (`type`, `title`, `description`, `resource` = la source, `tags`, `timestamp`). Gabarit : `concept.template.md`.
4. **Mettre à jour `knowledge-base/index.md`** : ajouter/ajuster la ligne (lien + une phrase). *(index.md = listing OKF, sans frontmatter.)*
5. **Mettre à jour les pages liées** : relier aux entités/concepts concernés (liens markdown **relatifs au fichier**, pas de slash initial, voir Spec §3, condition du graphe Obsidian). Une source en touche souvent plusieurs.
6. **Signaler les contradictions** : si la source contredit un fait existant, **ne pas écraser**, le dire à l'utilisateur, et le cas échéant poser `superseded_by:` / `status:` sur l'ancienne page.
7. **Ajouter au `log.md`** : `## [YYYY-MM-DD] ingest | <titre de la source>` + une ligne.

## Garde-fous
- Une source à la fois, supervisée. **Ne pas inventer** de fait absent de la source.
- Tracer l'origine dans `resource:`.
- Condition de succès : la page concept existe, `index.md` et `log.md` sont à jour, **aucune contradiction laissée silencieuse**.
- Skill interne : ne rien publier ni envoyer.
