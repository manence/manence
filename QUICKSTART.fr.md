---
type: guide
title: "Démarrer : Manence en 3 gestes"
description: "Le point d'entrée express du cadre : pour qui il est, ce qu'il donne, et les trois premiers gestes pour s'y mettre."
tags: [ai-os, quickstart, onboarding]
timestamp: 2026-07-02
---

# Démarrer avec Manence

> 🌐 **English** : [read in English](QUICKSTART.md) — la version de référence. La doctrine complète du dépôt est en anglais ; cette présentation française t'amène jusqu'au premier geste, et ton système, lui, s'installe en français si tu le demandes.

**Pour qui ?** Celui qui a vécu la courbe : l'IA impressionne au début, puis le projet dure, tout s'accumule, et la confiance baisse. Manence est fait pour travailler avec un agent IA (Claude Code) sur des projets qui durent.

**Ce que ça donne, en une phrase :** un système de travail où la discipline est tenue par l'IA elle-même : chaque échange fait le travail **et** met le système à jour ; le tout piloté comme un **système d'exploitation** (fichiers versionnés = disque, contexte = RAM, skills = programmes).

## Prérequis

- **git**, pour récupérer le cadre et versionner ton système.
- [Claude Code](https://claude.com/claude-code), l'agent avec lequel le cadre travaille.
- **jq** et **python3**, utilisés par les hooks de sécurité (`guard.sh`, `lint.sh`). Le premier démarrage les vérifie et propose de t'aider. Sans jq, `guard.sh` **échoue fermé** : il bloque les actions outillées tant que jq n'est pas installé (mieux vaut muet que aveugle). Sans python3, le lint ne tourne pas ; avec python3 mais sans **PyYAML**, il tourne en mode YAML dégradé et son rapport l'annonce. Sous Windows, les hooks sont des scripts bash : [Git pour Windows](https://git-scm.com/download/win) fournit le bash qu'il leur faut.

## Les 3 premiers gestes

1. **Lire le [Manifeste](Manifesto.fr.md) (5 min).** Le fil unique : le modèle mental, les 7 couches, les 9 lois. C'est le seul document à comprendre pour saisir le cadre ; chaque idée se déplie ensuite dans [`concept/`](concept/index.md) (en anglais).

2. **Copier le MOS par défaut.** Récupérer le cadre, puis copier le système prêt à l'emploi dans un conteneur à lui :

   ```bash
   git clone https://github.com/manence/manence.git
   mkdir ~/mon-projet                                    # le conteneur — c'est ton MOS
   cp -R manence/implementation/mos ~/mon-projet/core    # le cœur — un dépôt git à lui seul
   ```

   Deux dossiers, deux rôles. `~/mon-projet/` est le **conteneur** : il abrite le **cœur** (`core/` — le système et la connaissance, versionnés) et, dès que le premier démarrage l'aura créée, `production/` à côté (tes artefacts de travail, hors git). Plusieurs MOS ? Nomme chaque cœur d'après son activité (`mon-projet-core`), tes onglets de terminal resteront lisibles.

   ⚠️ **Copie le dossier, jamais son contenu.** Le cœur porte des fichiers cachés — `.claude/` (les skills et les hooks de sécurité), `.gitignore`, `.env.example` — que ton explorateur masque par défaut : glisser le *contenu* de `mos/` les laisse silencieusement derrière, et tu obtiens un cœur sans garde-fous. Passe par la commande ci-dessus, ou glisse le **dossier** `mos` lui-même. (Le premier démarrage le vérifie et te le dit s'il manque quelque chose.)

   Tout le reste est dans la copie : fichiers d'identité, table de routage, 6 skills de base, hooks de sécurité, knowledge-base — plus `BOOTSTRAP.md`, le rituel de premier démarrage.

3. **Faire son premier démarrage.** Ouvre Claude Code dans le cœur (`cd ~/mon-projet/core` puis `claude`) et dis-lui : **« fais mon premier démarrage »**. L'agent lit [`BOOTSTRAP.md`](implementation/mos/BOOTSTRAP.md) et prend la main : il demande ta langue (**français ou anglais** — réponds français, et tout ton système s'installe en français : identité, skills, gabarits), t'interviewe — le nom, ce que fait l'activité, qui travaille ici, la voix, le cap — remplit tes fichiers d'identité avec tes réponses, vérifie les garde-fous, contrôle tout, puis supprime le fichier du rituel. C'est aussi ta première leçon : **les skills s'invoquent en parlant à l'agent**, pas en ligne de commande. Quand c'est fini, donne-lui du vrai travail : *« ouvre un chantier pour ‹ce sur quoi tu bosses cette semaine› »*.

> **Bonus** : ouvre le dossier du projet dans [Obsidian](https://obsidian.md) (gratuit) — les liens relatifs dessinent le **graphe** de ta connaissance : clusters, orphelines et trous visibles d'un coup d'œil. Une vue humaine optionnelle, jamais une dépendance (voir [le modèle de mémoire](concept/modele-memoire.md), en anglais).

> Ensuite : les règles concrètes sont dans [Implementation](implementation/Implementation.md), les sources vérifiées dans [`research/`](concept/research/index.md) (en anglais).
