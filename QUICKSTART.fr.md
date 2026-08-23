# Démarrer avec Manence

> 🌐 **English** : [read in English](QUICKSTART.md) — la version de référence. La doctrine complète du dépôt est en anglais ; cette présentation française t'amène jusqu'au premier geste, et ton système, lui, s'installe en français si tu le demandes.

**Pour qui ?** Celui qui a vécu la courbe : l'IA impressionne au début, puis le projet dure, tout s'accumule, et la confiance baisse. Si ton travail avec une IA n'a pas duré quelques semaines, tu n'en as peut-être pas besoin encore. S'il a duré, et que tu lui fais un peu moins confiance qu'au début : c'est pour toi. Manence est fait pour travailler avec un agent IA (Claude Code) sur des projets qui durent.

**Ce que ça donne, en une phrase :** un système de travail où la discipline est tenue par l'IA elle-même : chaque échange fait le travail **et** met le système à jour ; le tout piloté comme un **système d'exploitation** (fichiers versionnés = disque, contexte = RAM, skills = programmes).

## Prérequis

- **git**, pour récupérer le cadre et versionner ton système.
- [Claude Code](https://claude.com/claude-code), l'agent avec lequel le cadre travaille.
- **bash**, la langue des hooks de sécurité. Déjà là sur macOS et Linux. Sous Windows, [Git pour Windows](https://git-scm.com/download/win) le fournit — installe-le **en premier**, exécute les commandes ci-dessous depuis **Git Bash**, et vérifie que `C:\Program Files\Git\bin` est dans le PATH (l'installeur ne l'y met pas toujours).
- **jq** et **python3**, utilisés par les hooks de sécurité (`guard.sh`, `lint.sh`). Le premier démarrage les vérifie et propose de t'aider. Sans jq, `guard.sh` **échoue fermé** : il bloque les actions outillées tant que jq n'est pas installé (mieux vaut muet que aveugle). Sans python3, le lint se replie en mode dégradé ligne à ligne et son rapport l'annonce. Note Windows : l'installeur python.org crée `python.exe` mais pas `python3.exe`, et Windows 11 livre un stub `python3.exe` qui ouvre le Microsoft Store — le lint sonde un python3 *réellement exécutable* et se dégrade proprement sinon.
- **Testé là où ça compte :** le parcours d'installation complet — clone, conteneur, rituel BOOTSTRAP, hooks, chemin fail-closed du guard compris — est exercé sur **macOS et Linux** (Ubuntu), et un **parcours d'installation réel complet a été joué sous Windows** (via Git Bash, 2026-08-06) ; les pièges Windows qu'il a révélés sont corrigés dans cette version.

## Les 3 premiers gestes

1. **Installer le MOS par défaut.** Une commande crée le conteneur et copie le cœur *avec ses fichiers cachés* :

   ```bash
   curl -fsSL --proto '=https' --tlsv1.2 https://manence.ai/install.sh | bash
   ```

   Emplacement par défaut : `~/manence`. Un autre dossier : `| bash -s -- ~/mon-activite`. Depuis un clone : `bash manence/install.sh`. Le script vérifie que la copie est entière avant de s'arrêter — le mode d'échec qu'il existe à empêcher, c'est le glisser-déposer qui laisse `.claude/` derrière.

   Deux dossiers, deux rôles. Le **conteneur** (`~/manence/`) abrite le **cœur** (`core/` — le système et la connaissance, versionnés) et, dès que le premier démarrage l'aura créée, `production/` à côté (tes artefacts de travail, hors git). Plusieurs MOS ? Passe un dossier différent par activité.

   Chemin à la main, si tu veux voir chaque geste : `git clone` puis `mkdir ~/mon-activite` puis `cp -R manence/implementation/mos/. ~/mon-activite/core/` — copie le *contenu y compris les fichiers cachés* (`mos/.`, le `/.` final est ce qui les emporte). Préfère le script.

2. **Faire son premier démarrage.** Ouvre Claude Code dans le cœur (`cd ~/manence/core` puis `claude`) et dis-lui : **« fais mon premier démarrage »**. L'agent lit [`BOOTSTRAP.md`](implementation/mos/BOOTSTRAP.md) et prend la main : il demande ta langue (**français ou anglais** — réponds français, et tout ton système s'installe en français : identité, skills, gabarits), t'interviewe — le nom, ce que fait l'activité, qui travaille ici, la voix, le cap — remplit tes fichiers d'identité avec tes réponses, vérifie les garde-fous, te montre la carte, puis supprime le fichier du rituel. C'est aussi ta première leçon : **les skills s'invoquent en parlant à l'agent**, pas en ligne de commande. Quand c'est fini, donne-lui du vrai travail : *« ouvre un chantier pour ‹ce sur quoi tu bosses cette semaine› »*.

3. **(Optionnel) Lire le [Manifeste](Manifesto.fr.md).** Le fil unique : le modèle mental, les 7 couches, les 9 lois. Pas requis pour démarrer ; c'est le document qui fait tenir le système. Chaque idée se déplie ensuite dans [`concept/`](concept/index.md) (en anglais).

> **Bonus** : ouvre le dossier du projet dans [Obsidian](https://obsidian.md) (gratuit) — les liens relatifs dessinent le **graphe** de ta connaissance : clusters, orphelines et trous visibles d'un coup d'œil. Une vue humaine optionnelle, jamais une dépendance (voir [le modèle de mémoire](concept/modele-memoire.md), en anglais).

> Ensuite : les règles concrètes sont dans [Implementation](implementation/Implementation.md), les sources vérifiées dans [`research/`](concept/research/index.md) (en anglais).
