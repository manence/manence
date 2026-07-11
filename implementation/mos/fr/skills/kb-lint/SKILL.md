---
name: kb-lint
description: Audit d'hygiène de la knowledge-base, cherche contradictions, affirmations périmées, pages orphelines, concepts cités sans page, renvois manquants, trous de données. À lancer périodiquement pour garder le wiki sain à mesure qu'il grandit.
---

# kb-lint, audit de la knowledge-base

## But
Garder le wiki sain quand il grossit. Produire une liste de corrections **et** de nouvelles questions à creuser. (C'est le *checker* de la loi L4, séparé de qui a écrit les pages.)

## Procédure
Parcourir `knowledge-base/` et signaler, d'après la méthode Karpathy :
1. **Contradictions** entre pages (mêmes faits, valeurs divergentes).
2. **Claims périmés**, remplacés par des sources plus récentes (croiser `timestamp` et `superseded_by`).
3. **Pages orphelines**, aucun lien entrant.
4. **Concepts cités sans page dédiée**, un nom revient dans plusieurs pages mais n'a pas la sienne.
5. **Cross-références manquantes**, deux pages liées sémantiquement mais sans lien.
6. **Trous de données**, questions ouvertes comblables par une recherche web.
7. **Conformité OKF / L2**, `type:` manquant, `index.md` qui a dérivé, doublons (un fait à deux endroits). Exception : les fiches `type: research` (relevés de sources) sont **exclues** du contrôle de doublons, leur recouvrement avec le Manifesto et les concepts du cadre est normal.
8. **Liens cassés / non graphables**, cible inexistante, ou lien à **slash initial** (`/dossier/page.md`) que le graphe Obsidian ne trace pas, signaler pour repasser en relatif au fichier.
9. **Frontmatter valide + typographie** : chaque page (hors `index.md`/`log.md`) a un frontmatter YAML **parseable**, piège classique : un `:` non quoté dans `title`/`description` (ex. « Produit : le pitch ») casse le YAML, il faut quoter la valeur ; et **aucun tiret cadratin `—`** dans le frontmatter (virgule / deux-points / parenthèses ; le demi-cadratin `–` des plages reste permis).

## Sortie
Un rapport markdown, par catégorie : la liste des fichiers + l'action proposée. **Ne rien corriger automatiquement**, proposer, l'utilisateur valide.

## Garde-fous
- Lecture seule par défaut ; toute correction passe par validation.
- Appui visuel possible : le **graphe Obsidian** (nœuds isolés = orphelines).
- Si le wiki est gros : échantillonner par dossier **et le dire** (pas de cap silencieux).
