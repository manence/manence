---
name: weekly-review
description: Revue hebdomadaire de santé de Manence OS, lint mécanique (cœur + production), tri de l'inbox, état des chantiers en cours, détection des orphelins et des chantiers mal nés (dossiers de production sans About.md), mesures d'effet arrivées à échéance, propositions d'actions. À lancer une fois par semaine (à la main ou par cron/heartbeat), ou quand l'utilisateur demande « où on en est ».
---

# weekly-review, la revue hebdomadaire

## But
Empêcher les deux dérives qui tuent un Manence OS : le désordre qui s'installe (orphelins, inbox qui déborde, liens cassés, chantiers mal nés) et les chantiers qui s'enlisent sans que personne ne le voie.

## Procédure
1. **Lint mécanique** : lancer `.claude/hooks/lint.sh` sur le repo, **puis** sur la racine de production (`$<PROJET>_PRODUCTION_ROOT`, défaut `../production/`, résolue en absolu) : c'est de là que les liens des chantiers vers la KB doivent résoudre (Spec §18). Rapporter les constats. Ne rien corriger sans validation (maker ≠ checker, L4).
2. **Orphelins** : chercher les fichiers/dossiers qui vivent **hors** des emplacements de la table de routage du `CLAUDE.md` (à la racine du cœur, hors `knowledge-base/`/`inbox/`/`.claude/`/`scripts/`). Pour chacun, proposer sa destination selon la table (chantier ? KB ? inbox ? poubelle ?).
3. **Chantiers mal nés** : dans la production, signaler tout dossier de `in-progress/` **sans `About.md`** (travail né hors discipline) → proposer la fiche rétroactive de `close-work`.
4. **Inbox** : passer `inbox/` en revue, item par item : router chacun (fait → `kb-ingest`, travail → candidat `open-work`, périmé → `trash`, à garder tel quel → il reste mais on le date). Objectif : inbox vide ou consciente.
5. **Chantiers en cours** : lister les `<domaine>/in-progress/` avec, pour chacun : l'objectif (son `About.md`), son âge, sa dernière activité. Signaler ceux qui n'ont pas bougé depuis 2 semaines : avancer, ou clore (`close-work`, y compris en abandon assumé).
6. **Mesures d'effet** : relever les actions externes closes dont la **date de mesure** est atteinte (inscrites par `close-work`) et signaler tout rapport de mesure manquant. La mesure appartient au rituel : c'est ici qu'on voit l'effet.
7. **KB** : un `kb-lint` léger si la KB a bougé cette semaine (contradictions, index qui dérive) ; sinon le noter comme non fait. Vérifier au passage la fraîcheur du rapport périodique (dans la KB).
8. **Synthèse** : un état en 5-10 lignes (santé, chantiers, inbox, mesures) + **2-3 actions proposées** classées par valeur (candidats `open-work`, chantiers à clore, corrections). C'est l'utilisateur qui choisit.
9. **Tracer** : entrée `## [YYYY-MM-DD] review | semaine <n°>` dans `log.md` avec la synthèse condensée et ce qui a été décidé.

## Garde-fous
- La revue **constate et propose**, elle ne corrige rien et n'ouvre aucun chantier sans validation.
- Si elle tourne en automatique (cron/heartbeat), la synthèse attend la relecture de l'utilisateur ; rien ne part vers l'extérieur.
- Condition de succès : l'utilisateur sait en une lecture ce qui est sain, ce qui traîne, ce qui doit être mesuré et quoi faire ensuite ; le log en garde la trace.
