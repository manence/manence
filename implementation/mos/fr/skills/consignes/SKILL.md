---
name: consignes
description: À utiliser au démarrage de chaque session (le hook SessionStart le signale quand il y a quelque chose), à la demande de l'utilisateur (« traite les consignes », « regarde l'inbox »), et avant la weekly-review. Lit l'inbox du cœur, traite les items `type: instruction` déposés depuis Manence UI (réponse à une attente, « fait », consigne sur un chantier ou sur un document), consigne chaque effet dans l'About du chantier visé, passe l'item en `status: traitee`, journalise une entrée par run et commite le cœur. Idempotent ; n'écrit jamais chez un tiers, n'envoie jamais rien.
---

# consignes, traiter ce qu'Alexandre a déposé depuis Manence UI

## But
Qu'une réponse ou une consigne donnée dans l'interface **produise son effet dans les fichiers** sans qu'Alexandre ait à la redire au terminal. Le guichet de Manence UI (ou tout autre guichet qui respecte le contrat) ne fait que déposer un fichier ; ce skill est l'autre moitié du canal : il lit, agit par les skills du cadre, trace, et marque l'item traité. Le fichier est la vérité (portable à tout harnais) ; tout déclencheur n'est qu'un accélérateur.

## Le contrat lu
Un item de `inbox/` avec le frontmatter :
- `type: instruction`, `source: manence-ui`, `mos`, `work_id`, `status: deposee | traitee | rejetee`, `timestamp` ;
- `geste: decision` ou `action` → réponse à une entrée d'`awaiting` : `awaiting_index`, `awaiting_what`, `awaiting_who`, `awaiting_since` (recopie de l'entrée au moment du dépôt) ;
- `geste: consigne` → texte libre sur le chantier ; en option `document` (chemin d'un fichier du chantier, relatif à son dossier) et `page`.
Le corps porte le texte d'Alexandre. Définition complète : Spec §21 (« L'item d'instruction : le canal humain → agent »).

## Procédure
1. **Lister** les items `type: instruction` en `status: deposee` de `inbox/`, du plus ancien au plus récent. Aucun → le dire en une ligne et s'arrêter (pas d'entrée de log, pas de commit).
2. **Retrouver le chantier** par `work_id` dans la production (`<domaine>/in-progress/<work_id>/About.md`). Introuvable (clos entre-temps, renommé) → item en `status: rejetee` avec le motif en pied, et continuer.
3. **Traiter par geste** :
   - **`decision` / `action`** : retrouver l'entrée d'`awaiting` **par `awaiting_what` d'abord**, `awaiting_index` en repli (l'index bouge quand la liste est éditée). Retirer l'entrée ; écrire dans la section *Décisions* de l'About une ligne datée « (via Manence UI) » avec la décision, ou la preuve du « fait » ; mettre à jour la *Prochaine étape* si elle en dépend. Si la décision change un statut, un périmètre ou une contrainte : une entrée `decision |` au log (tamis habituel).
   - **`consigne` qui commence par « Clore » ou « Abandonner »** (ou, dans une installation anglaise, « Close » / « Abandon » : le skill reconnaît les deux langues) : c'est le **GO explicite** de `close-work` (le seul geste qui en exige un). Jouer `close-work` : attentes restantes tracées en reliquat, distillation KB, entrée `work-close` au log, dossier déplacé vers `done/`. « Abandonner » → `status: rejected`.
   - **`consigne` qui change le travail** (angle, prix, périmètre, correction) : l'appliquer sur le chantier, consigner la décision dans l'About (datée, « via Manence UI »), recaler la *Prochaine étape*.
   - **`consigne` avec `document`** : remonter à la **source** du document (un PDF se corrige dans le HTML ou le markdown qui l'a produit, lien « source » dans l'About ; un `.md` s'édite directement), appliquer, régénérer si c'est un rendu, consigner.
   - **`consigne` qui pose une question** : la réponse ne repart pas par l'inbox. Elle devient une entrée d'`awaiting` dans l'About (`who: alexandre`, `kind: decision`, `what` = la réponse ou la question reformulée, `since` = aujourd'hui) : elle s'affiche dans Manence UI, là où Alexandre répond déjà.
4. **Marquer l'item** : `status: traitee` (ou `rejetee`) dans son frontmatter, et une ligne de pied datée disant ce qui a été fait et où. Ne jamais supprimer l'item : la revue le balaie après 14 jours.
5. **Journaliser** une seule entrée par run : `## [AAAA-MM-JJ] event | consignes : N traitée(s), M rejetée(s)` avec une ligne par item (chantier, geste, effet). Un `close-work` a déjà sa propre entrée `work-close`.
6. **Commiter** le cœur (log, inbox, KB si touchée) avec un message dans la langue de travail ; push de la branche suivie, **jamais forcé**. La production n'est pas versionnée.
7. **Rendre compte** en cinq lignes : items traités, effets, ce qui a été rejeté et pourquoi, ce qui attend encore quelqu'un.

## Garde-fous
- **Aucune écriture chez un tiers, aucun envoi, aucune publication**, quelle que soit la consigne : une consigne qui le demande est **rejetée** avec le motif (règle d'or ; ce geste reste au terminal, avec son circuit). Le skill ne pousse que le cœur privé.
- **Ne touche qu'à ses items** : `type: instruction` en `deposee`. Le reste de l'inbox est au tri de la revue.
- **Idempotent** : rejouable sans double traitement (un item `traitee` n'est jamais rejoué ; une entrée d'`awaiting` déjà absente n'est pas une erreur, on consigne et on marque).
- **Un seul writer** : si une autre session travaille sur le même cœur (alternance des harnais), ne pas jouer.
- **Une session sans opérateur** (`-p`, headless) applique les mêmes règles et s'arrête sur tout ce qui exigerait une question à Alexandre : la question devient une entrée d'`awaiting`.
- Skill interne : le compte rendu suffit, rien n'est publié.
- Condition de succès : plus aucun item `deposee` dont le chantier existe ; chaque effet lisible dans l'About visé ; une entrée de log ; `git status` propre.
