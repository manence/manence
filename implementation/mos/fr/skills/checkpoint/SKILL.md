---
name: checkpoint
description: À utiliser quand l'utilisateur annonce qu'il va effacer le contexte — « je vais clear », « on clôt la session » — et de sa propre initiative quand la session a beaucoup produit et que le contexte s'alourdit. Prépare la passation, dans l'ordre : chaque fil encore ouvert part à l'inbox avec son état et les décisions attendues, le log est complété, la mémoire de l'agent mise à jour si le harnais en tient une, les chantiers statués, tout le versionné commité et poussé, l'environnement rendu comme trouvé, les actions externes en attente listées sans être exécutées, et un compte rendu de cinq lignes dit où reprendre.
---

# checkpoint, la passation avant un clear

## But
Qu'une session puisse s'arrêter n'importe quand sans rien perdre : la suivante lit l'inbox, le log et la mémoire, et reprend sans que l'utilisateur ait à réexpliquer. Le skill n'invente rien : s'il n'y a rien à écrire sur un point, il le dit et passe.

Ce qu'il n'est pas : une revue hebdomadaire (`weekly-review`), ni une clôture de chantier (`close-work`). Il les appelle si un chantier est livré et validé, il ne les remplace pas.

## Procédure, dans l'ordre

1. **Les fils ouverts vont à l'inbox.** Pour chaque sujet encore vivant dans la session, un item `inbox/YYYY-MM-DD-<slug>.md` (frontmatter `type: inbox`, `title`, `timestamp`) avec trois paragraphes : **où on en est**, **ce qu'il faut de l'utilisateur** (les décisions attendues, numérotées), **la prochaine action concrète** (avec les chemins). Un fil déjà couvert par un item existant : mettre l'item à jour plutôt qu'en créer un second. Les items rendus caducs par la session partent à la corbeille (`trash`). C'est la pièce maîtresse : la session suivante commence par l'inbox.
2. **Le log est complet.** Relire la session : chaque décision de l'utilisateur, chaque livraison, chaque incident ou leçon a son entrée `## [YYYY-MM-DD] type | titre` dans `log.md`. Ce qui a été dit en conversation sans être tracé s'écrit maintenant. Append-only, jamais de réécriture.
3. **La mémoire est à jour.** Si le harnais tient une mémoire d'agent — il en donne le chemin, et tous n'en ont pas : sans elle, on passe — y porter l'état des projets en cours qui n'est écrit nulle part ailleurs, les corrections et confirmations de l'utilisateur sur la façon de travailler, et l'index qui les recense. Vérifier d'abord qu'une entrée existante couvre le sujet ; mettre à jour plutôt que dupliquer ; supprimer ce qui est devenu faux. Ne rien y recopier de ce que le dépôt, le log ou la knowledge-base portent déjà.
4. **Les chantiers sont sains.** Tout dossier créé dans la production a son `About.md` (sinon : l'écrire, rétroactif). Un chantier livré et validé passe par `close-work`. Un chantier qui reste ouvert a sa prochaine étape à jour, et son `awaiting` dit ce qui attend quelqu'un.
5. **Rien n'est en suspens dans git.** Le cœur (`log.md`, `inbox/`, les skills), la knowledge-base, tout dépôt connecté : `git status` sur chacun, commit avec un message dans la langue de travail, push de la branche suivie. Les garde-fous du cœur s'appliquent ici comme ailleurs : ce qu'ils refusent ne se contourne pas, il se signale. Chemins absolus dans toutes les commandes git. Les hachages vont dans le compte rendu.
6. **L'environnement est rendu comme trouvé.** Agents de fond : terminés ou explicitement laissés en cours (le dire). Serveurs lancés par la session : coupés ; ceux de l'utilisateur : intacts. Dépôts remis sur la branche où ils étaient. Fichiers temporaires : dans le scratchpad, pas dans les dépôts.
7. **Les actions externes en attente sont listées, jamais exécutées.** Tout ce qui attend un GO (une purge, un merge, un envoi, une écriture dans un système vivant) est nommé dans l'item d'inbox correspondant, avec la mention « en attente de GO ». La session suivante ne doit pas pouvoir le confondre avec une chose décidée.
8. **Le compte rendu, cinq lignes, dernier message avant le clear** : où reprendre (l'item d'inbox à lire en premier), ce qui attend l'utilisateur, ce qui est poussé (dépôts et hachages), ce qui tourne encore, ce qui a été volontairement laissé de côté.

## Déclenchement
- L'utilisateur dit « je vais clear », « clear la session », « si tu as des choses à écrire, fais-le ».
- De ma propre initiative, quand la session a livré plusieurs choses et que le contexte s'alourdit : proposer le checkpoint plutôt que d'attendre qu'il soit trop tard.

## Garde-fous
- Aucune action externe, aucune écriture dans un système vivant (un CRM, une régie publicitaire, un site en production) pendant un checkpoint : on range, on trace, on pousse le versionné, c'est tout.
- Un item d'inbox par fil réel ; pas d'item pour dire qu'il n'y a rien.
- Condition de succès : `git status` propre sur tous les dépôts touchés, chaque fil ouvert a son item d'inbox, le log couvre la session, la mémoire ne contredit rien de ce qui a été décidé, et le compte rendu tient en cinq lignes.
