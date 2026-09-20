---
name: close-work
description: À utiliser quand un livrable est terminé et validé, quand un chantier est abandonné, ou pour régulariser un chantier mal né (un dossier de production sans About.md). Clôt le chantier en le déplaçant, nom inchangé, de <domaine>/in-progress/ vers <domaine>/done/, avec distillation obligatoire — faits durables vers la knowledge-base, bilan au log : les artefacts de production sont jetables, ce skill est le seul garant de durabilité.
---

# close-work, clore un chantier

## But
Qu'un chantier fini **capitalise** au lieu de juste s'arrêter. La production est hors git et **jetable par doctrine** : ce qui n'est pas distillé ici (KB + log) est réputé perdu. La distillation n'est donc pas optionnelle, elle est le cœur du skill (double valeur, L8).

## Procédure
1. **Vérifier** avec l'utilisateur : le livrable est-il terminé et validé (GO explicite) ? Sinon, deux issues : le chantier reste ouvert, ou il est **abandonné** (aller à l'étape 7, variante abandon).
2. **Trancher les attentes restantes** : lire `awaiting` dans `About.md`. Si la liste n'est pas vide, **énumérer ce qui reste** (qui, quoi, depuis quand) et demander : « *il reste ceci non tranché : … — on clôt quand même ?* ». Sur **oui**, les reporter dans l'entrée de log `work-close` (étape 7) comme renoncement ou report tracé, puis vider la liste. Sur **non**, le chantier reste ouvert et la clôture s'arrête là. Le skill pose la question, il ne refuse jamais.
3. **Clore** : déplacer `<domaine>/in-progress/YYYYMMDD-<slug>/` vers `<domaine>/done/YYYYMMDD-<slug>/` : **le même nom, un pur déplacement** (le préfixe daté s'est posé à l'ouverture ; renommer ici casserait tous les liens entrants). La racine de production est `$<PROJET>_PRODUCTION_ROOT` (défaut `../production/`), résolue en absolu, jamais devinée (Spec §18).
4. **Statuer** : dans `About.md`, passer `status:` à `validated` (ou `canon` si le livrable devient une référence réutilisable) et mettre à jour `timestamp:`.
5. **Distiller (obligatoire)** : les faits durables du chantier (un prix, un positionnement, un résultat de campagne) partent à la `knowledge-base/` via `kb-ingest` ; le chantier clos devient la `resource:` de la page (un **pointeur** sous la racine de production, pas un lien relatif : la production peut bouger). On ne laisse **jamais** un fait vivre uniquement dans un artefact jetable.
6. **Programmer la mesure** : toute **action externe** du chantier (campagne activée, contenu publié, envoi) inscrit **sa date de mesure** (ex. J+7) et **qui l'observera** (quel rituel : `weekly-review`, revue mensuelle…). La mesure appartient au rituel, pas au chantier : le chantier se clôt, la mesure survit dans le système. Concrètement : une ligne datée dans `inbox/` ou le rapport périodique visé, pas une note dans le dossier clos.
7. **Tracer** : entrée `## [YYYY-MM-DD] work-close | <domaine>/<slug>` dans le `log.md` du cœur avec le bilan en 2-3 lignes : ce qui a été livré, **ce qu'on a appris** (ce qui a marché, ce qui a frotté), et le pointeur vers le dossier clos. *Variante abandon* : `status: rejected` dans `About.md`, le dossier part en `done/` quand même, nom inchangé (la trace d'un renoncement motivé vaut de l'or), entrée `work-close` avec la raison de l'abandon.

## Fiche rétroactive (réparer un chantier mal né)
Un dossier de travail découvert dans la production **sans** `About.md` (bien routé, mal né) : créer son `About.md` depuis le gabarit, rétroactivement (objectif reconstitué, contexte lié, `status:` reflétant l'état réel), et une entrée `work-open` datée d'aujourd'hui au log mentionnant la régularisation. Puis le chantier suit le cycle normal.

## Garde-fous
- Jamais de clôture sans GO explicite de l'utilisateur.
- Ne rien réécrire dans les chantiers déjà clos (ils sont datés, ils font partie de l'historique).
- Si le chantier appelle une suite (itérer, relancer), la noter : soit un nouvel item dans `inbox/`, soit directement `open-work`.
- Condition de succès : plus rien dans `in-progress/` pour ce chantier, `About.md` statué, `awaiting` vide ou son reliquat tracé au log, KB à jour si faits nouveaux, chaque action externe a sa date de mesure et son observateur, entrée de log avec bilan.
