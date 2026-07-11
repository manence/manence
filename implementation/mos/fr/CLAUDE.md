# CLAUDE.md, <nom du projet>

## Identité
<Qui je suis ici, la voix à adopter.> Voir `SOUL.md` pour le ton, `STRATEGY.md` pour le cap.

## Au démarrage de session
- Lire `knowledge-base/index.md` (la carte du savoir) et la tête de `log.md` (les dernières décisions).
- Vérifier s'il existe un `CLAUDE.local.md` à la racine : s'il déclare des connecteurs locaux, les charger aussi. Sinon, ignorer.
- Regarder les chantiers en cours dans la production (`$<PROJET>_PRODUCTION_ROOT`, défaut `../production/` : les dossiers `<domaine>/in-progress/`) et `inbox/` (capture brute à trier).

## Ce que fait ce projet
<En 2-3 lignes.>

## Où va chaque chose (table de routage)
Avant de créer ou déplacer un fichier, deux questions : **statique ou dynamique ? c'est quoi ?** Puis :

| C'est... | Ça va... |
|---|---|
| un fait stable (marque, produit, entité, règle métier) | `knowledge-base/` (OKF, un concept = un fichier ; via `kb-ingest` si ça vient d'une source) |
| du travail en cours (campagne, livrable, exploration) | un **chantier** `<domaine>/in-progress/<slug>/` dans la **production du conteneur** (hors git : `$<PROJET>_PRODUCTION_ROOT`, défaut `../production/`), ouvert par `open-work`. **Créer un dossier de travail là = ouvrir un chantier** : la discipline (About, contexte lié, trace) s'applique d'office |
| un livrable terminé | `<domaine>/done/YYYYMMDD-<slug>/`, via `close-work` (distillation KB + log **obligatoire** : les artefacts de production sont jetables) |
| une capture brute pas encore triée | `inbox/` |
| une procédure réutilisable | `.claude/skills/<nom>/SKILL.md` (règle des 3 occurrences : ad-hoc 2 fois, skill la 3e) |
| un événement, une décision | une entrée datée de `log.md` (append-only) |
| une donnée vivante d'un système externe | nulle part : on l'interroge via un connecteur (couche 7) et on ne persiste que la conclusion distillée |
| un rapport périodique (revue, reporting) | `knowledge-base/` : une série temporelle est du **savoir consolidé**, pas un chantier ; ses actions candidates vont dans `inbox/` |
| un asset lourd (vidéo, PSD, deck) | **avec son chantier**, dans la production (hors git). Une référence depuis la KB passe par une fiche pointeur (`resource:`) |

**Rien ne se crée à la racine ni hors de cette table.** En cas de doute, `open-work` pose les questions. Le lint (`.claude/hooks/lint.sh`) et la `weekly-review` détectent les orphelins.

## Connecteurs (l'hexagone)
<Carte des adaptateurs branchés : un tableau chemin · rôle · habilitation. Les adaptateurs confidentiels ne sont JAMAIS listés ici : ils vivent dans `CLAUDE.local.md` (gitignored). Brancher un nouveau : skill `connect-adapter`.>

| Connecteur | Chemin | Rôle |
|---|---|---|
| <aucun pour l'instant> | | |

## Conventions
- Connaissance : `knowledge-base/` (OKF : frontmatter YAML, `type:` obligatoire, un concept = un fichier ; on lie, on ne recopie jamais un fait).
- Dynamique : chantiers dans la production du conteneur (voir la table de routage) ; journal dans `log.md`, append-only, préfixes `## [YYYY-MM-DD] type | titre`.
- Une leçon **de niveau cadre** (qui devrait changer Manence lui-même, pas seulement ce projet) se tague dans le log : `## [YYYY-MM-DD] framework | titre`. Le cadre les moissonne par chantier de version.
- Les chemins se passent, ils ne se devinent pas : les emplacements mobiles ont une variable racine (`.env.example`) ; tout prompt de sous-agent qui touche un chantier contient le **chemin absolu résolu**.
- Liens markdown standard, relatifs au fichier (`../dossier/page.md`, `page-voisine.md`), jamais de slash initial (le graphe Obsidian ne les trace pas).
- Règles complètes : la Spec du cadre Manence (repo séparé, référence externe).

## Skills
Base (fournis par le cadre) : `open-work` (ouvrir un chantier), `close-work` (publier un chantier), `weekly-review` (revue hebdo : lint, inbox, chantiers), `kb-ingest` (intégrer une source au savoir), `kb-lint` (audit de la KB), `connect-adapter` (brancher un adaptateur).
<Skills propres au projet : à lister ici au fur et à mesure.>

## Sécurité, dur vs mou
- **Mou (ce fichier)** : CLAUDE.md ne fait que *suggérer*. Claude peut s'en écarter.
- **Dur (ce qui contraint vraiment)** : un hook `PreToolUse` ou `permissions.deny` dans `.claude/settings.json`. Pour *interdire* (ex. `rm -rf`, push direct), c'est là, pas ici. Fournis : `.claude/hooks/guard.sh` (bloque) et `lint.sh` (rapporte).
- Bon sens : `trash` plutôt que `rm` ; travail interne (lire, brouillons) → libre.
- **Écrire chez un tiers** (créer, publier, envoyer, activer) : GO explicite + dry-run (`validateOnly`) si l'API l'offre + avant/après tracé dans le livrable + **créer en pause/brouillon d'abord**, activer en second geste. Credentials lecture/écriture **séparés** : la mesure reste read-only, la capacité d'écriture s'ajoute sur décision.
- Clés API dans `.env` (gitignored, modèle dans `.env.example`), jamais commitées. Config locale/confidentielle : `CLAUDE.local.md` (gitignored), jamais dans ce fichier.

## Langue
<Fichiers en … ; conversations en ….>
