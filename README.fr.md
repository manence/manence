# Manence

> 🌐 **English** : [read in English](README.md) — la version de référence. La doctrine complète du dépôt est en anglais ; en français : ce README, le [Manifeste](Manifesto.fr.md) et le [QUICKSTART](QUICKSTART.fr.md) — et ton propre système s'installe en français si tu le demandes.

**Manence rend ton IA fiable sur les projets qui durent.** Une IA, que ce soit en chat ou en agentique, ne connaît que son contexte : ce qu'elle a sous les yeux à l'instant présent, rien d'autre. Ce qui doit durer a donc besoin d'un lieu qui survit à la session — et d'une façon de travailler qui garde ce lieu juste. Manence est les deux : un système de travail où **chaque échange fait le travail *et* range le système**. L'ordre en sous-produit, pas en corvée.

![Un Manence OS vu par Manence UI : les domaines de production, ce qui est en cours, ce qui attend quelqu'un, la knowledge base au centre](assets/fr/manence-ui.png)

## Le problème

Avec une IA, c'est génial au début. Elle comprend vite, produit vite, propose juste. Puis le projet dure : les conversations s'allongent, les brouillons finissent par ressembler à des décisions, les erreurs corrigées reviennent.

**Ce n'est pas que l'IA oublie (elle a une mémoire) : c'est que tout s'accumule et que rien ne se range.** Une IA ne connaît que son contexte, ce qu'elle charge dans l'instant ; plus le corpus grossit, plus il lui est difficile d'attraper la bonne information au bon moment. Le chat subit le phénomène. L'agentique, où l'IA lit et écrit tes fichiers en continu, le vit à la puissance dix.

Le problème n'est ni ton prompt, ni ton modèle : c'est qu'il n'y a pas de système autour. Et « il faut ranger » n'est pas une réponse : le rangement traité comme une corvée perd toujours contre l'urgence. Les entreprises se paient des wikis internes depuis vingt ans ; ils ne sont jamais à jour.

## La réponse : le système est le rangement

Manence est un système de travail où **travailler produit déjà de l'ordre**. Il tient sur trois organes :

1. **Le savoir qui fait foi.** Une knowledge-base où ce qui est écrit est vrai : tes produits, tes règles, tes décisions validées. Un fait, un seul domicile ; jamais polluée par le travail du jour.
2. **Le réel branché.** Tout travail naît en **chantier**, dans son espace, avec son contexte déjà relié, connecté à tes vrais outils (CRM, analytics, site, dépôts). Ton IA travaille sur tes vraies données, pas sur des souvenirs périmés.
3. **Le geste qui va au bout.** La règle qui tient l'ensemble : chaque échange fait le travail **et** met le système à jour. 
    - Une décision prise ? Actée, avec son pourquoi. 
    - Une information qui a changé ? La base est mise à jour. 
    - Une erreur repérée ? La correction est créée, expliquée.

Alors la courbe s'inverse : chaque heure de travail laisse le système plus sain qu'elle ne l'a trouvé, et ton IA repart toujours de ce qui est juste, le meilleur contexte au meilleur moment. Le rangement n'est pas une tâche : c'est un sous-produit. Sur les vieux Windows, il fallait défragmenter le disque, une corvée qu'on repoussait des mois ; sous Linux, le système range en écrivant, la notion de defrag n'existe pas. C'est la logique de Manence.

Et tu possèdes tout : le code et les gabarits sont open source (MIT) — ce que l'installation copie dans ton projet est à toi, sans aucune condition — et la doctrine se lit, se partage et s'adapte librement ([CC BY-NC-SA](LICENSE-docs.md)). Markdown + git, en clair, chez toi : le modèle d'IA est un composant interchangeable, tu passes à une IA open source, souveraine ou auto-hébergée sans rien réécrire. *(Un « projet » ChatGPT ou Claude, lui, vit chez eux : exportable, jamais vraiment à toi.)*

## Le modèle mental : tu fais tourner un OS

Le cadre repose sur le modèle de Karpathy (*Software 3.0*) : le modèle d'IA est le **processeur**, le contexte la **RAM** (rare et chère, à charger au minimum utile), tes fichiers (markdown + git) le **disque**, les skills les **programmes**. Organiser ses projets pour l'IA, c'est concevoir le disque et les programmes d'un OS dont la RAM est minuscule. Le plan complet : [Manifesto.fr.md](Manifesto.fr.md).

## Installation

Une commande, puis une phrase à ton agent :

```bash
curl -fsSL --proto '=https' --tlsv1.2 https://manence.ai/install.sh | bash
```

Ça pose un MOS dans `~/manence`. Un autre dossier : ajoute `| bash -s -- ~/mon-activite`. Tu ne veux pas piper ? `git clone https://github.com/manence/manence.git && bash manence/install.sh`.

Tu en as déjà un qui tourne ? `bash upgrade.sh <cœur>` fait entrer une nouvelle version sans faire sortir ton travail — voir [UPGRADING.md](UPGRADING.md) (en anglais).

Ensuite :

```bash
cd ~/manence/core
claude
```

Dis-lui : **« fais mon premier démarrage »**. L'agent t'interviewe, remplit le système, vérifie les garde-fous, supprime le rituel. Installer, c'est déjà s'en servir. Détail : [QUICKSTART.fr.md](QUICKSTART.fr.md).

**Voir son MOS : Manence UI, un lecteur à part.** Un MOS, ce sont des fichiers qui s'ouvrent à la main ; Manence UI est un logiciel distinct, avec son propre rythme de sortie, qui en lit un — ce qui est en cours, ce qui est fait, ce qui attend quelqu'un — sans jamais y écrire. Un MOS est complet sans lui.

## La preuve : il tourne déjà sur du vrai travail

Ce cadre n'est pas une théorie : il s'est construit en production et y tourne chaque jour — sur **les trois activités de son auteur**, ce qui est dit tel quel. Une preuve de pratique, pas encore d'adoption :

- **une entreprise SaaS** (PME, 18 salariés) : stratégie, CRM, pipeline de leads, support, veille quotidienne, tout journalisé ;
- **Manence lui-même** : ce dépôt, sa doctrine et le site [manence.ai](https://manence.ai) sont construits et pilotés sous Manence ;
- **un média** : [declic.media](https://declic.media), 122 articles en trois langues, workflows éditoriaux complets.

Une trace réelle, telle qu'elle dort dans le journal de la première — un matin, un lead arrive dans le CRM étiqueté « DIRECT, aucune source » ; le système ne l'avale pas :

```
## [2026-06-14] correctif | Attribution des leads web
Lead « DIRECT, aucune source » : croisement CRM × analytics
→ vraie origine reconstituée : Brave Search, ~11 h (tracker bloqué par un adblocker).
Mesure : 39 % des leads web (28/71) mal étiquetés depuis des semaines.
Analyse livrée. Correctif déployé le jour même.
```

Un exemple vécu. Six mois après un chantier, quelqu'un demande : « pourquoi on avait écarté l'option B, déjà ? » Pas besoin de retrouver la conversation : le dossier du chantier dit qui a décidé quoi, ce qui a été écarté, et pourquoi. L'IA le lit et répond en trente secondes, sources à l'appui. Six mois plus tard, on comprend ce qui s'est passé, pas seulement le résultat. C'est le geste qui va au bout.

## Ce que Manence n'est pas

Tu as déjà une mémoire d'IA, un carnet de notes, et un agent qui travaille dans tes dossiers avec tes outils. Ce sont les ingrédients. Le problème commence après : qu'est-ce qui fait foi, qu'est-ce qui n'est qu'un brouillon, pourquoi on a écarté B, et est-ce que le chiffre du CRM est le même que l'analytics.

- **Une « mémoire » de plus.** La mémoire stocke tout ce qui passe : de l'accumulation vendue comme un progrès. Au bout de quelques semaines, elle te ressert le mélange. Manence tient un lieu où ce qui est écrit est vrai, et le protège du reste.
- **Un second cerveau.** Un wiki perso, c'est toi qui le tiens. Les wikis d'entreprise existent depuis vingt ans ; ils ne sont jamais à jour. Le rangement-corvée perd toujours. Dans Manence, c'est l'IA qui tient la discipline, en sous-produit du travail : tu n'as pas un deuxième métier d'archiviste.
- **Cowork, Claude Code, ou un paquet de MCP.** Un agent qui a les mains est puissant. Un accès n'est pas une vue d'ensemble : des outils isolés ne voient pas qu'un chiffre absurde dans le CRM crève les yeux au regard de l'analytics du même client. Et rien, dans l'agent brut, ne structure la durée : pas d'ouverture ni de clôture de projet, pas de journal des décisions, pas de frontière entre le vrai et le brouillon. Manence est cette structure, par-dessus. Cowork lui donne les mains. Manence lui dit ce qui est vrai, ce qui est en cours, et ce qui est déjà tranché.

## Multi-IA, par construction

Ton système ne dépend pas d'un fournisseur d'IA. Tout ce qui compte — savoir, journal, chantiers — est du markdown simple que n'importe quel agent sait lire ; le fichier d'identité est le standard partagé **`AGENTS.md`** ; les fichiers de skills suivent le format inter-outils Agent Skills. Le rituel d'installation demande quel agent va piloter, et le câble en conséquence :

- **Claude Code** — le chemin natif. Rien à ajouter.
- **Grok Build (xAI)** — lit nativement `AGENTS.md` et le câblage `.claude/` livré. Rien à ajouter.
- **OpenAI Codex** — lit nativement `AGENTS.md` ; le rituel pose un lien `skills` à la racine et un `.codex/config.toml` pour que les skills et le garde-fou suivent.

Une règle : un seul agent à la fois sur un conteneur. Rien n'est annoncé comme supporté avant d'avoir été testé pour de vrai — l'état exact des tests, couche par couche, est dans **[PORTABILITY.md](PORTABILITY.md)** *(en anglais)*.

## La carte

- **[QUICKSTART.fr.md](QUICKSTART.fr.md)** : la porte d'entrée (pour qui, quoi, 3 gestes). **Commence ici.**
- **[Manifesto.fr.md](Manifesto.fr.md)** : *le pourquoi*. La synthèse du cadre (modèle mental, 7 couches, architecture hexagonale, 9 lois, maturité) + l'index des concepts.
- **[concept/](concept/index.md)** *(en anglais)* : chaque idée dépliée en un fichier, + [`research/`](concept/research/index.md) (les sources vérifiées : Karpathy, OKF, Anthropic, PKM, loops, OpenClaw, LIVING REFERENCE de JP Noto).
- **[implementation/](implementation/index.md)** *(en anglais)* : *le comment*, avec [Spec](implementation/Spec.md) (les règles), [Implementation](implementation/Implementation.md) (le playbook), [`mos/`](implementation/mos/BOOTSTRAP.md) (le MOS par défaut, prêt à copier : identité, 8 skills (dont `outward-watch`, l'œil tourné vers l'extérieur), hooks, rituel de démarrage qui se clôt sur le premier chantier) et [`example/`](implementation/example/index.md) (une KB minimale qui tourne).
- **[CHANGELOG.md](CHANGELOG.md)** *(en anglais)* : les versions.

## Le nom

*Manence*, du latin *manere* (demeurer), la racine de **permanence**, **rémanence** et **immanence** : ce qui reste quand la conversation s'efface, ce qui persiste quand la session se ferme, ce qui demeure chez toi quand le modèle se débranche.

## Filiation et crédits

Manence synthétise et outille des idées dont les sources sont nommées et documentées dans [`concept/research/`](concept/research/index.md) : le modèle ordinateur de **Andrej Karpathy** (*Software 3.0*), le spec **OKF** (Google), le modèle de mémoire **CoALA**, les pratiques d'ingénierie de contexte d'**Anthropic**, les conventions d'identité du projet open source **OpenClaw**, et **LIVING REFERENCE** de **JP Noto** (double valeur, validation tracée, cycle de statuts — et, depuis la 0.4, le tamis de trace, le déclencheur de révision et les tests de dérive, sur accord écrit). Le cadrage hexagonal et les 9 lois sont des synthèses originales du cadre.

Créé par **Alexandre Noto** ([Alex Déclic](https://www.youtube.com/@alexdeclic)), dirigeant de SaaS, qui pilote sa propre entreprise avec ce cadre.

## Licences

Double licence, voir [LICENSE.md](LICENSE.md) (la version courte), [LICENSE](LICENSE) et [LICENSE-docs.md](LICENSE-docs.md) :

- **Code et gabarits** (`implementation/mos/`, `implementation/example/`) : **MIT**. Ce que tu copies dans ton projet **t'appartient sans condition**.
- **Doctrine** (README, QUICKSTART, Manifesto, `concept/`, Spec, Implementation) : **CC BY-NC-SA 4.0**. Libre de lire, partager, adapter avec attribution ; **usage commercial du texte interdit** (revendre cette doctrine dans une formation payante, par exemple). Pour une licence commerciale : contact via [manence.ai](https://manence.ai).

---

**Avec une IA, c'est génial au début. Avec Manence, ce n'est que le début.**

*Site : [manence.ai](https://manence.ai) · Dépôt canonique : [github.com/manence/manence](https://github.com/manence/manence)*
