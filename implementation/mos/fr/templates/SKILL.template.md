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
- <Si ce skill ÉCRIT chez un tiers (créer, publier, envoyer) : GO explicite avant d'écrire ; dry-run (`validateOnly`) si l'API l'offre ; avant/après tracé dans le livrable ; créer en pause/brouillon d'abord, activer en second geste (Spec §12).>
