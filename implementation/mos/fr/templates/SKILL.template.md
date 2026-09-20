---
name: <nom-du-skill>
description: <quand l'utiliser, une phrase déclenchable. C'est ce que l'agent lit pour décider de charger ce skill.>
---

# <Nom du skill>

## But
<Ce que ce skill accomplit, en une ligne.>

## Quand l'utiliser
<Conditions de déclenchement.>

## Procédure
1. <étape>
2. <étape>
3. <étape>

## Entrées / sorties
- Entrée : <…>
- Sortie : <où va le résultat, ex. `knowledge-base/`, le chantier en cours (chemin passé en entrée)…>

## Garde-fous
- Condition de succès : <une phrase, vérifiable>.
- Limites : <max-turns / budget / stop si bloqué>.
- Vérification : externe (script/test/juge), pas l'auto-évaluation.
- Critère de lecture : <au moins un critère qu'une machine ne coche pas, à côté des critères mécaniques : une relecture sous contrainte, formulée pour être rejouée à l'identique (ex. « masquer les sous-titres : la suite des titres doit tenir seule »). Tout critère de qualité laissé implicite disparaît en quelques dizaines d'exécutions ; un skill de production en écrit au moins un, et pointe les exemplaires à relire — avec leur chemin — pour chaque dimension qu'il veut préserver.>
- <Si ce skill ÉCRIT chez un tiers (créer, publier, envoyer) : GO explicite avant d'écrire ; dry-run (`validateOnly`) si l'API l'offre ; avant/après tracé dans le livrable ; créer en pause/brouillon d'abord, activer en second geste (Spec §12).>
