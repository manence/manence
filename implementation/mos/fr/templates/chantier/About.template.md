---
type: work
work_id: <YYYYMMDD-slug>   # identique au nom du dossier à la naissance, jamais renommé
title: "<Titre du chantier>"
description: "<Le livrable attendu, en une phrase.>"
tags: [chantier]
timestamp: <YYYY-MM-DD>
status: proposal   # proposal | validated | canon | rejected (statué par close-work)
awaiting: []   # who / what / kind (decision | action) / since — ce qui attend un humain ; vide = rien à trancher
---

# <Titre du chantier>

## Objectif
<Une phrase : ce que ce chantier doit livrer, pour qui, et l'échéance s'il y en a une.>

## Contexte (on lie, on ne recopie pas)
- Savoir : <liens vers les pages de la knowledge-base concernées, calculés depuis CE dossier et vérifiés en les résolvant (Spec §18)>
- Mesures / données : <ce que disent les connecteurs, en une ligne, avec la date de la mesure>
- Précédent : <lien vers le chantier clos du même type (done/), s'il existe>

## Décisions
<Les choix structurants du chantier : qui a choisi, quoi, ce qui a été écarté, pourquoi. Les décisions majeures vont aussi dans le log.md du projet (L8).>
<Quand une attente est tranchée, on retire son entrée d'`awaiting:` et on écrit la décision ici.>

## Contenu du chantier
<La carte des fichiers de ce dossier, un lien + une ligne chacun, tenue à jour.>

## Assets
<Les fichiers lourds (vidéo, PSD, deck) vivent ICI, avec le chantier : la production n'est pas versionnée, ils n'encombrent aucun git. Si un asset vit ailleurs malgré tout (drive d'équipe, DAM), un pointeur chacun : où, quoi, version.>

## Prochaine étape
<Toujours une seule, concrète. C'est elle qu'on lit pour reprendre le chantier.>
