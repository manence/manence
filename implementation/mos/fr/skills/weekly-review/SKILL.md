---
name: weekly-review
description: Revue hebdomadaire de santé de Manence OS, lint mécanique (cœur + production), tri de l'inbox, état des chantiers en cours, détection des orphelins et des chantiers mal nés (dossiers de production sans About.md), mesures d'effet arrivées à échéance, veille extérieure consommée (rapport outward-watch), force de proposition divergente, propositions d'actions. À lancer une fois par semaine (à la main ou par cron/heartbeat), ou quand l'utilisateur demande « où on en est ».
---

# weekly-review, la revue hebdomadaire

## But
Empêcher les deux dérives qui tuent un Manence OS : le désordre qui s'installe (orphelins, inbox qui déborde, liens cassés, chantiers mal nés) et les chantiers qui s'enlisent sans que personne ne le voie.

## Procédure
1. **Lint mécanique** : lancer `.claude/hooks/lint.sh` sur le repo, **puis** sur la racine de production (`$<PROJET>_PRODUCTION_ROOT`, défaut `../production/`, résolue en absolu) : c'est de là que les liens des chantiers vers la KB doivent résoudre (Spec §18). Rapporter les constats. Ne rien corriger sans validation (maker ≠ checker, L4).
2. **Orphelins** : chercher les fichiers/dossiers qui vivent **hors** des emplacements de la table de routage d'`AGENTS.md` (à la racine du cœur, hors `knowledge-base/`/`inbox/`/`.claude/`/`scripts/` ; un lien `skills` à la racine est le pont dont certains agents ont besoin pour atteindre `.claude/skills/`, ce n'est pas un orphelin). Pour chacun, proposer sa destination selon la table (chantier ? KB ? inbox ? poubelle ?).
3. **Chantiers mal nés** : dans la production, signaler tout dossier de `in-progress/` **sans `About.md`** (travail né hors discipline) → proposer la fiche rétroactive de `close-work`.
4. **Inbox** : passer `inbox/` en revue, item par item : router chacun (fait → `kb-ingest`, travail → candidat `open-work`, périmé → `trash`, à garder tel quel → il reste mais on le date). **Garde-temps** : toute capture de plus de 14 jours est triée ou supprimée à cette revue — l'inbox est exemptée du contrat de fichier précisément parce que ce balayage existe. Objectif : inbox vide ou consciente.
5. **Chantiers en cours** : lister les `<domaine>/in-progress/` avec, pour chacun : l'objectif (son `About.md`), son âge, sa dernière activité. Signaler ceux qui n'ont pas bougé depuis 2 semaines : avancer, ou clore (`close-work`, y compris en abandon assumé).
6. **Mesures d'effet** : relever les actions externes closes dont la **date de mesure** est atteinte (inscrites par `close-work`) et signaler tout rapport de mesure manquant. La mesure appartient au rituel : c'est ici qu'on voit l'effet.
7. **KB** : un `kb-lint` léger si la KB a bougé cette semaine (contradictions, index qui dérive) ; sinon le noter comme non fait. Vérifier au passage la fraîcheur du rapport périodique (dans la KB), et relever toute page dont le `review_when:` est échu (une page échue cesse de faire foi seule : proposer sa reconfirmation ou sa mise à jour).
8. **Fraîcheur du cadre** : le cœur installé porte sa version dans `.claude/manence-version`. La comparer au dernier tag du repo public du framework — `git ls-remote --tags https://github.com/manence/manence.git` (une lecture publique via le réseau ; rien de ton MOS n'est envoyé ; sans réseau, noter « non vérifié cette semaine » et passer). Si le repo est en avance : lister les versions manquées **avec leurs notes de CHANGELOG** (récupérer le `CHANGELOG.md` brut du repo) et mettre la mise à jour dans les actions proposées — la revue signale, elle n'applique jamais. Si `.claude/manence-version` manque, l'installation précède la 0.5.0 : le dire et proposer de l'estampiller avec la version à laquelle le cœur correspond réellement.
9. **Veille extérieure** : lire le rapport le plus récent de `knowledge-base/veille/`, écrit par le skill `outward-watch`. Absent, ou vieux de plus d'une semaine ? Lancer `outward-watch` d'abord — ou le noter comme non fait, sans réseau. Puis relever les P0 et P1 dont l'item d'inbox n'a pas été routé à l'étape 4 : la veille propose, c'est ici que ses propositions rencontrent le reste de la semaine.
10. **Contrôles de dérive** *(cinq questions empruntées aux tests de dérive de LIVING REFERENCE, JP Noto)*, chacune tranchée contre la KB et le log, jamais contre une impression :
   - Une production récente (chantier, livrable, surface publique) **contredit-elle une page `canon`** de la KB ?
   - Une option **écartée dans le log est-elle revenue**, re-proposée ou ré-appliquée en douce, alors que la raison de son rejet tient toujours ?
   - Une décision **prise pour un chantier est-elle appliquée au-delà**, comme si elle engageait tout le projet ?
   - Un **brouillon est-il cité quelque part comme s'il faisait foi** (`status: proposal` traité comme un fait) ?
   - Une **contrainte validée est-elle ignorée** quelque part (règle de publication, garde-fou, convention de nommage) ?
   Constat seulement : la réparation (rejeter, archiver, remplacer, revalider) part en synthèse comme proposition, et l'utilisateur décide.
11. **Force de proposition** *(le seul geste divergent de la revue)* : partir de `STRATEGY.md` et du rapport de veille, et proposer **1 à 3 idées que l'utilisateur n'aurait pas eues seul** — un angle mort du cap annoncé, une chose jamais essayée, un rapprochement entre une trouvaille exogène et un problème d'ici. À ne pas confondre avec les actions proposées ci-dessous, qui dérivent de l'introspection (inbox, chantiers, lint). Avant de proposer, vérifier au log : une idée déjà écartée ne revient que si le contexte qui l'avait fait rejeter a changé, et on dit ce qui a changé (contrôle de dérive D2).
12. **Synthèse** : un état en 5-10 lignes (santé, chantiers, inbox, mesures, fraîcheur du cadre, veille, dérives) + **2-3 actions proposées** classées par valeur (candidats `open-work`, chantiers à clore, corrections), et les idées divergentes de l'étape 11 listées à part. C'est l'utilisateur qui choisit.
13. **Tracer** : entrée `## [YYYY-MM-DD] review | semaine <n°>` dans `log.md` avec la synthèse condensée et ce qui a été décidé.

## Garde-fous
- La revue **constate et propose**, elle ne corrige rien et n'ouvre aucun chantier sans validation.
- Si elle tourne en automatique (cron/heartbeat), la synthèse attend la relecture de l'utilisateur ; rien ne part vers l'extérieur.
- Condition de succès : l'utilisateur sait en une lecture ce qui est sain, ce qui traîne, ce qui doit être mesuré et quoi faire ensuite ; le log en garde la trace.
