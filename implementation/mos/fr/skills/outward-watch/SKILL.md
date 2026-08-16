---
name: outward-watch
description: Veille tournée vers l'extérieur — le substrat (Anthropic, Claude Code, pratiques agentiques ; identique pour tout MOS) et le métier (un slot que chaque installation remplit elle-même) — chaque trouvaille passée au filtre unique « qu'est-ce que ça change pour ce MOS, ou pour le cadre ? ». Écrit un rapport daté dans knowledge-base/veille/ (série temporelle) et route les actions candidates vers inbox/. À lancer environ une fois par semaine, avant la weekly-review qui le consomme, à la main ou en routine planifiée.
---

# outward-watch, l'organe tourné vers l'extérieur

## But
Tous les autres organes d'un MOS regardent dedans. Le log, la knowledge-base, la distillation, la revue : tous capitalisent sur le travail déjà fait. Aucun ne découvre quoi que ce soit dehors, et le substrat sur lequel tourne un MOS bouge plus vite que le MOS lui-même. Ce skill est l'œil tourné vers l'extérieur, et il ne rapporte que ce qui change quelque chose ici.

## Deux choses à surveiller

**Le substrat** — générique, identique pour tout MOS. Ce sur quoi le système tourne : Anthropic et Claude Code (releases, changelog, annonces, nouvelles capacités) et la pratique plus large autour (context engineering, mémoire, patterns multi-agents, outillage qui mérite d'être connu). Le cadre livre cette moitié finie ; seul le filtre est local.

**Le métier** — un slot, un par MOS, vide à la livraison. Le domaine dans lequel l'activité travaille vraiment : les concurrents et les acteurs adjacents, les mentions publiques qui comptent, les sources qui font autorité. On le remplit une fois, il tient :

> **La veille métier de ce MOS** — *vide jusqu'à ce qu'on la remplisse*
> `<quoi surveiller · quelles pages de la KB servent de base de comparaison · ce qui compte comme signal>`

Si le slot est encore vide au moment où le skill tourne, demander la réponse à l'utilisateur et l'écrire dans ce fichier avant de collecter quoi que ce soit. Une veille métier que l'assistant s'est inventée est du bruit.

## Procédure
1. **Le delta d'abord.** Lire `STRATEGY.md`, le rapport le plus récent de `knowledge-base/veille/` et la tête de `log.md`. La date du dernier rapport **borne la fenêtre** de celui-ci (premier passage : environ six semaines en arrière). Rien de déjà vu, rien de déjà écarté ne remonte une seconde fois — c'est à ça que sert la section « vu, sans effet » du rapport précédent (contrôle de dérive D2).
2. **Collecter** — sous-agents de recherche en parallèle, en lecture seule : le substrat d'un côté, le slot métier de l'autre. Sans réseau, écrire « non fait » et s'arrêter là ; une veille qui comble ses trous de mémoire vaut moins que pas de veille du tout.
3. **Filtrer.** Chaque trouvaille passe une seule question : **qu'est-ce que ça change pour ce MOS, ou pour le cadre ?** Réponse vide → une ligne sous « vu, sans effet », et on n'y revient jamais. Le reste se classe :
   - **P0** — ça casse quelque chose ici, ou la fenêtre pour agir est courte ;
   - **P1** — à intégrer au prochain chantier qui touche au sujet ;
   - **P2** — à surveiller, rien à faire.
4. **Le rapport.** `knowledge-base/veille/YYYY-MM-DD.md` (OKF, `type: report`), référencé dans `knowledge-base/veille/index.md` — créer le dossier et son index au premier passage. Trois sections : substrat, métier, vu-sans-effet. Chaque trouvaille tient le **fait** (ce qui est sorti, sourcé et daté) à l'écart de l'**interprétation** (ce que ça change ici) : le fait garde sa valeur le jour où l'interprétation se révèle fausse. Une série temporelle est du savoir consolidé, et c'est pourquoi le rapport vit dans la knowledge-base et pas dans un chantier (table de routage).
5. **Actions candidates.** Les P0 et P1 qui appellent quelque chose partent dans un seul item daté, `inbox/YYYY-MM-DD-veille-actions.md`, comme candidats `open-work` ou `kb-ingest`. La veille propose, la weekly-review trie, l'utilisateur décide.
6. **Le log.** Rien par défaut : un rapport de routine ne change ni statut ni contrainte, le tamis l'écarte. Un P0 avéré fait exception et mérite son entrée.

## Garde-fous
- **Lecture seule vers l'extérieur.** La veille interroge ; elle n'écrit nulle part ailleurs qu'ici. Rien de publié, aucun chantier ouvert, aucun compte tiers touché.
- La cadence suit le rythme de l'utilisateur, pas celui du monde : tout arrive frais le jour où il s'assoit, rien ne s'empile la nuit.
- **La brièveté du rapport est le but.** Le filtre est fait pour écarter. Un rapport qui liste tout n'a rien filtré.
- En constellation, plusieurs MOS surveillent le même substrat et font le travail deux fois. Redondant, pas faux — chacun le lit à travers son propre filtre. Partager un seul rapport entre installations relève de l'opérateur, pas d'une règle du cadre.
