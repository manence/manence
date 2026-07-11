---
name: connect-adapter
description: Connecte proprement un nouvel adaptateur (bundle de savoir, de capacité, ou confidentiel) à un cœur Manence OS. Valide le contrat d'adaptateur, route selon la confidentialité (carte des connecteurs du CLAUDE.md partagé, OU CLAUDE.local.md gitignored pour le confidentiel), écrit la ligne de carte, journalise. À utiliser quand on branche un repo voisin au cœur.
---

# connect-adapter, brancher un adaptateur

## But
Ajouter un adaptateur au cœur **sans casser le zéro-connaissance** (L9) ni l'hygiène des bundles. Séparer **accès** (peut-il lire ?) de **connaissance** (sait-il qu'il existe ?).

## Entrée
- **Chemin** du repo adaptateur (ex. `../mon-adaptateur`, relatif au cœur).
- **Type** : `savoir` (bundle de connaissance) | `capacité` (skill + connecteur) | `confidentiel`.

## Procédure

### 1. Valider le contrat d'adaptateur (checklist légère, reporter ✓/✗ par point)
- **Repo autonome** : `../mon-adaptateur/.git` existe. ✗ bloquant → pas un adaptateur, refuser.
- **Auto-descriptif** : a un `CLAUDE.md` qui se décrit lui-même. ✗ bloquant.
- **Secrets** : a un `.env.example`, `.env` est gitignoré, aucun secret commité. Grep rapide (`git ls-files | grep -i '\.env$'`, et scan de clés dans le suivi). ✗ bloquant si un secret est commité.
- **Chemins portables** : pas de chemin machine en dur (grep `/Users/`, `~/Dev/`, `/home/`). ✗ → avertir (non bloquant), proposer de passer par variable d'env.
- **Skills déclarés** : si l'adaptateur a des `SKILL.md`, chacun a `name:` + `description:` en frontmatter (pour pouvoir les lister dans la carte). ✗ → avertir.
- **Si `savoir`** : OKF respecté (a un `index.md`, chaque page a `type:` en frontmatter), **faits purs** : **pas** de `.env`/secret, **pas** de code exécutable. ✗ bloquant : ce n'est pas un bundle de savoir, c'est une capacité → le sortir en bundle séparé.
- **Si `confidentiel`** : `.env`/données bien gitignorés, **pas de remote public** (`git remote -v`). ✗ bloquant.

> Si un point **bloquant** échoue → **refuser de brancher**, dire précisément quoi corriger, s'arrêter.

### 2. Router (zéro-connaissance, L9)
- **`confidentiel`** → cible = **`CLAUDE.local.md`** du cœur (gitignored, local). **JAMAIS** dans le `CLAUDE.md` partagé : la simple mention trahit l'existence.
- **`savoir` / `capacité`** → cible = la **carte des connecteurs** du **`CLAUDE.md`** du cœur (partagé, auto-chargé au démarrage).

### 3. Écrire la ligne de carte
Format :
```
- <Nom> · <chemin relatif> · <rôle en 4 mots> · skills : <name des SKILL.md, ou "aucun">
```
Ex. : `- Growth Ops · ../growth-ops · fetch analytics + publie · skills : gads-fetch, social-publish`

Rappel à laisser une fois en tête de carte :
> Pour utiliser un skill de connecteur : lis son `SKILL.md` par chemin et suis-le. Pas de `--add-dir` requis (option confort seulement).

### 4. GO explicite
Montrer à l'utilisateur **la ligne exacte** + **le fichier cible** (`CLAUDE.md` ou `CLAUDE.local.md`) et **attendre le GO** avant d'écrire.

### 5. Journaliser
- **Si `savoir` / `capacité`** : après écriture, ajouter au `log.md` du cœur :
  ```
  ## [YYYY-MM-DD] connect | <adaptateur> → CLAUDE.md
  ```
- **Si `confidentiel`** : **aucune** entrée de log, dans le `log.md` du cœur ni ailleurs de partagé. La seule trace du branchement vit dans `CLAUDE.local.md` (gitignored) ; la simple mention de l'existence de l'adaptateur dans un fichier partagé trahirait le zéro-connaissance.

## Garde-fous
- **Ne jamais** router un `confidentiel` vers le `CLAUDE.md` partagé, ni vers son `log.md` : ni ligne de carte, ni entrée de log, ni trace d'historique partagé.
- Le cœur ne stocke **pas** les clés des adaptateurs : chacun garde son `.env`.
- Accès ≠ connaissance : cette procédure gère la **connaissance** (la carte) ; l'**accès** (`--add-dir`) reste un shim de lancement, hors bundle.
- Condition de succès : contrat validé, ligne écrite dans la **bonne** cible après GO ; `log.md` du cœur à jour **seulement** pour `savoir`/`capacité` ; pour `confidentiel`, aucune trace partagée, le branchement vit uniquement dans `CLAUDE.local.md`.
