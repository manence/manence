---
name: open-work
description: Ouvre un chantier (une unité de travail avec un livrable identifiable) dans la production du conteneur, en appliquant la table de routage du CLAUDE.md. À utiliser dès que l'utilisateur veut travailler sur quelque chose de nouveau (une campagne, un webinaire, un document, une exploration). DÉCLENCHEUR IMPLICITE : créer un dossier de travail dans la production EST ouvrir un chantier ; cette discipline s'applique d'office, même si personne n'a invoqué le skill.
---

# open-work, ouvrir un chantier

## But
Que tout travail naisse **au bon endroit, avec son contexte**, au lieu de finir en dossier orphelin. Un chantier = un dossier `<domaine>/in-progress/<slug>/` dans la **production du conteneur** (hors git), avec un `About.md` typé, un livrable identifiable et une trace.

## Procédure
1. **Résoudre la racine de production.** `$<PROJET>_PRODUCTION_ROOT` (voir `.env` / `.env.example`), défaut : `../production/` depuis le cœur. Résoudre en **chemin absolu** : c'est lui qu'on utilisera partout (et qu'on passera tel quel à tout sous-agent, jamais « à deviner », Spec §18).
2. **Router d'abord.** Vérifier avec la table de routage du `CLAUDE.md` que c'est bien un *travail en cours* :
   - un fait stable → ce n'est pas un chantier, c'est `kb-ingest` ;
   - une note brute sans livrable → `inbox/` ;
   - une procédure → un skill ;
   - une décision seule → une entrée de `log.md` ;
   - un rapport périodique → la KB (savoir consolidé), pas un chantier.
3. **Choisir le domaine.** La production s'organise par domaine métier (`pub/`, `contenu/`, `reporting/`…), **créé au premier besoin** avec ses deux sous-dossiers `in-progress/` et `done/`. Réutiliser un domaine existant si le travail s'y range.
4. **Nommer.** Un slug lisible (`campagne-meta-rentree`, `webinaire-produit-x`), pas de date en préfixe (elle viendra à la clôture). Vérifier qu'aucun chantier semblable n'existe déjà dans les `in-progress/`, `done/` ou `inbox/` (sinon : reprendre l'existant, pas dupliquer).
5. **Créer** `<domaine>/in-progress/<slug>/About.md` depuis `templates/chantier/About.template.md` (dans le cœur) et remplir le **brief** avec l'utilisateur : objectif en une phrase, livrable attendu, échéance s'il y en a une.
6. **Brancher le contexte, sans le copier** : lier les pages de la KB concernées, les mesures pertinentes (connecteurs), le chantier précédent du même type s'il existe. Les liens se **calculent depuis l'emplacement final** du chantier (toi seul connais les deux racines : les vérifier en les résolvant, pas en les supposant). On lie, on ne recopie pas (L2).
7. **Tracer** : entrée `## [YYYY-MM-DD] work-open | <domaine>/<slug>` dans le `log.md` du cœur (une ligne : l'objectif).
8. **Annoncer** la prochaine étape concrète du chantier.

## Garde-fous
- Un chantier = **un livrable identifiable**. Si on ne sait pas dire ce qui sera livré, c'est une exploration : le noter dans le brief comme telle, avec une question à trancher.
- Tous les fichiers du travail vivent **dans le dossier du chantier**, assets lourds compris (la production n'est pas versionnée, ils n'encombrent aucun git). Les itérations s'écrasent sur place, pas de sous-dossier `old/`.
- **Les artefacts sont jetables par doctrine** : ce qui doit durer passera par `close-work` (distillation KB + log). Le dire à l'utilisateur si un doute apparaît.
- Chantier né **sans** ce skill (dossier créé à la main ou en session ordinaire) : appliquer cette même discipline rétroactivement, tout de suite ou via la fiche rétroactive de `close-work`.
- Skill interne : ne rien publier ni envoyer.
- Condition de succès : le dossier existe avec son `About.md` rempli (`status: proposal`), ses liens vers la KB résolvent, le log est à jour, l'utilisateur sait quelle est la prochaine étape.
