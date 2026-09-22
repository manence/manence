---
name: connect-adapter
description: À utiliser quand on branche quelque chose de nouveau à un cœur Manence OS — un repo voisin, un bundle de savoir, une capacité, un adaptateur confidentiel — ou quand la déclaration d'un connecteur existant doit être corrigée. Valide le contrat d'adaptateur, route selon la confidentialité (carte des connecteurs de l'AGENTS.md partagé, ou CLAUDE.local.md gitignored pour le confidentiel), écrit la ligne de carte, déclare l'attache dans .claude/mos.json (jamais pour un adaptateur confidentiel), journalise.
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
- **Auto-descriptif** : a un fichier d'identité qui se décrit lui-même (`AGENTS.md`, ou le `CLAUDE.md` d'un repo qui lui est antérieur). ✗ bloquant.
- **Secrets** : a un `.env.example`, `.env` est gitignoré, aucun secret commité. Grep rapide (`git ls-files | grep -i '\.env$'`, et scan de clés dans le suivi). ✗ bloquant si un secret est commité.
- **Chemins portables** : pas de chemin machine en dur (grep `/Users/`, `~/Dev/`, `/home/`). ✗ → avertir (non bloquant), proposer de passer par variable d'env.
- **Skills déclarés** : si l'adaptateur a des `SKILL.md`, chacun a `name:` + `description:` en frontmatter (pour pouvoir les lister dans la carte). ✗ → avertir.
- **Si `savoir`** : OKF respecté (a un `index.md`, chaque page a `type:` en frontmatter), **faits purs** : **pas** de `.env`/secret, **pas** de code exécutable. ✗ bloquant : ce n'est pas un bundle de savoir, c'est une capacité → le sortir en bundle séparé.
- **Si `confidentiel`** : `.env`/données bien gitignorés, **pas de remote public** (`git remote -v`). ✗ bloquant.

> Si un point **bloquant** échoue → **refuser de brancher**, dire précisément quoi corriger, s'arrêter.

### 2. Router (zéro-connaissance, L9)
- **`confidentiel`** → cible = **`CLAUDE.local.md`** du cœur (gitignored, local). **JAMAIS** dans l'`AGENTS.md` partagé : la simple mention trahit l'existence.
- **`savoir` / `capacité`** → cible = la **carte des connecteurs** de l'**`AGENTS.md`** du cœur (partagé, lu au démarrage de chaque session).

### 3. Écrire la ligne de carte
Format :
```
- <Nom> · <chemin relatif> · <rôle en 4 mots> · skills : <name des SKILL.md, ou "aucun">
```
Ex. : `- Growth Ops · ../growth-ops · fetch analytics + publie · skills : gads-fetch, social-publish`

Rappel à laisser une fois en tête de carte :
> Pour utiliser un skill de connecteur : lis son `SKILL.md` par chemin et suis-le. Pas de `--add-dir` requis (option confort seulement).

### 3 bis. Déclarer l'attache dans la déclaration du MOS (`savoir`/`capacité` SEULEMENT)
Si le cœur a un `.claude/mos.json` (schema 3 — la déclaration machine-lisible du MOS, lue par la revue hebdo et par tout lecteur de ce système ; un fichier schema 2 se lit toujours), ajouter l'attache du nouvel adaptateur :
```json
{ "sommet": <0-5, une position libre ; 0 et 3 sont réservés à production/KB>,
  "id": "<id>", "nature": "mos | git | externe", "nom": "<nom d'affichage>",
  "resume": "<une phrase affichée>", "liens": [["<libellé>", "https://…"]] }
```
⚠️ **JAMAIS pour un `confidentiel`** : `mos.json` est versionné et partagé — y inscrire un adaptateur confidentiel trahirait le zéro-connaissance (L9), exactement comme une ligne dans l'`AGENTS.md`. Un adaptateur confidentiel ne se déclare nulle part de partagé : aucun lecteur de ce système ne le montrera jamais.
Un bundle de savoir qui *est* la knowledge base du système (la KB dans un dépôt séparé) pose aussi `"chemin": "<chemin relatif au cœur>"` sur son attache `kb`, pour qu'un lecteur la trouve sans deviner.

Pas de `mos.json` ? Ne pas le créer pour ça — noter seulement son absence dans le rapport.

### 4. GO explicite
Montrer à l'utilisateur **la ligne exacte** + **le fichier cible** (`AGENTS.md` ou `CLAUDE.local.md`), et le cas échéant **l'attache `mos.json`**, puis **attendre le GO** avant d'écrire.

### 5. Journaliser
- **Si `savoir` / `capacité`** : après écriture, ajouter au `log.md` du cœur :
  ```
  ## [YYYY-MM-DD] connect | <adaptateur> → AGENTS.md
  ```
- **Si `confidentiel`** : **aucune** entrée de log, dans le `log.md` du cœur ni ailleurs de partagé. La seule trace du branchement vit dans `CLAUDE.local.md` (gitignored) ; la simple mention de l'existence de l'adaptateur dans un fichier partagé trahirait le zéro-connaissance.

## Garde-fous
- **Ne jamais** router un `confidentiel` vers l'`AGENTS.md` partagé, ni vers son `log.md`, **ni vers `.claude/mos.json`** : ni ligne de carte, ni entrée de log, ni attache déclarée, ni trace d'historique partagé.
- Un fait de connecteur a **deux domiciles synchrones** : la carte de l'`AGENTS.md` (la prose qui fait foi) et l'attache `mos.json` (la déclaration machine sur laquelle va tout lecteur). Toute modification de l'un vérifie l'autre — c'est ce skill qui garantit l'alignement.
- Le cœur ne stocke **pas** les clés des adaptateurs : chacun garde son `.env`.
- Accès ≠ connaissance : cette procédure gère la **connaissance** (la carte) ; l'**accès** (`--add-dir`) reste un shim de lancement, hors bundle.
- Condition de succès : contrat validé, ligne écrite dans la **bonne** cible après GO ; `log.md` du cœur à jour **seulement** pour `savoir`/`capacité` ; pour `confidentiel`, aucune trace partagée, le branchement vit uniquement dans `CLAUDE.local.md`.
