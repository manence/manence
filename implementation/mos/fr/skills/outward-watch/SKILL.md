---
name: outward-watch
description: À utiliser environ une fois par semaine, avant la weekly-review qui la consomme — à la main ou en routine planifiée — et chaque fois que l'utilisateur demande ce qui bouge dehors. Regarde vers l'extérieur : le substrat (Anthropic, Claude Code, pratiques agentiques ; identique pour tout MOS) et le métier (un slot que chaque installation remplit elle-même), passe chaque trouvaille au filtre unique « qu'est-ce que ça change pour ce MOS, ou pour le cadre ? », écrit un rapport daté dans knowledge-base/veille/ (série temporelle) et route les actions candidates vers inbox/.
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
2. **Collecter** — sous-agents de recherche en parallèle, en lecture seule : le substrat d'un côté, le slot métier de l'autre. Sans réseau, écrire « non fait » et s'arrêter là ; une veille qui comble ses trous de mémoire vaut moins que pas de veille du tout. Deux règles tiennent la collecte honnête :
   - **Domaine bloqué : chemin de secours déclaré.** Une source primaire hors d'atteinte — proxy de sortie d'une routine planifiée, scraper en échec, mur payant — ne se saute pas en silence, et l'avouer en tête de rapport ne suffit pas : l'aveu laisse le trou béant. On la lit par un chemin de secours, et il y en a toujours un : les extraits de moteur de recherche (titre, date, points saillants), ou le report sur une session qui, elle, y accède. La trouvaille porte alors la mention « lue en dégradé, à confirmer », et la section fiabilité du rapport liste les domaines bloqués **et**, pour chacun, le chemin employé.
   - **Un chiffre se lit à sa source, ou se marque non vérifié.** Étoiles, abonnés, téléchargements, classements : quand une API publique donne le chiffre et la liste qui le compose, c'est elle qui parle, et une variation s'explique par ce qu'elle renvoie — jamais par conjecture. Sans appel possible, le chiffre entre au rapport marqué **non vérifié**. Un ordre de grandeur présenté comme un fait est la façon la moins coûteuse de corrompre une série temporelle.
3. **Filtrer.** Chaque trouvaille passe une seule question : **qu'est-ce que ça change pour ce MOS, ou pour le cadre ?** Réponse vide → une ligne sous « vu, sans effet », et on n'y revient jamais. Le reste se classe :
   - **P0** — ça casse quelque chose ici, ou la fenêtre pour agir est courte ;
   - **P1** — à intégrer au prochain chantier qui touche au sujet ;
   - **P2** — à surveiller, rien à faire.
4. **Le rapport.** `knowledge-base/veille/YYYY-MM-DD.md` (OKF, `type: report`), référencé dans `knowledge-base/veille/index.md` — créer le dossier et son index au premier passage. Trois sections : substrat, métier, vu-sans-effet. Chaque trouvaille tient le **fait** (ce qui est sorti, sourcé et daté) à l'écart de l'**interprétation** (ce que ça change ici) : le fait garde sa valeur le jour où l'interprétation se révèle fausse. Une série temporelle est du savoir consolidé, et c'est pourquoi le rapport vit dans la knowledge-base et pas dans un chantier (table de routage).
5. **Actions candidates.** Les P0 et P1 qui appellent quelque chose partent dans un seul item daté, `inbox/YYYY-MM-DD-veille-actions.md`, comme candidats `open-work` ou `kb-ingest`. La veille propose, la weekly-review trie, l'utilisateur décide.
6. **Le log.** Rien par défaut : un rapport de routine ne change ni statut ni contrainte, le tamis l'écarte. Un P0 avéré fait exception et mérite son entrée.

## Vérifier l'organe : le test de rappel en aveugle

Une veille qui ne rapporte rien est indiscernable d'une veille qui ne voit rien. Le test qui sépare les deux tient en quatre gestes, et se joue une fois par trimestre, ou après tout changement dans la façon dont la veille tourne — nouvelle routine, nouveau harnais, nouveau réseau de sortie.

1. **Poser la cible.** Un humain choisit une parution réelle de la fenêtre en cours, objectivement majeure pour ce MOS, et ne la traite pas : rien n'en entre au log, à la KB ni à l'inbox avant le passage.
2. **Laisser tourner.** La veille s'exécute normalement, sans rien savoir du test.
3. **Lire le verdict sur le seul rapport.** La cible y est, ou elle n'y est pas. Absente, c'est un **rappel manqué**, et il se qualifie : *défaut d'accès* (la source était hors d'atteinte) ou *défaut de filtre* (elle a été lue, puis écartée). Les deux se réparent, mais pas au même endroit — le premier dans le chemin de secours, le second dans le filtre.
4. **Purger et tracer.** La cible se traite ensuite normalement, et le verdict part au log en entrée datée : c'est le seul chiffre de fiabilité que cet organe produira jamais.

Le test ne se lit que dans un sens : il prouve un manque, jamais une exhaustivité. Une cible retrouvée ne dit pas que la veille voit tout ; une cible manquée dit qu'elle est aveugle quelque part, et où.

## Garde-fous
- **Lecture seule vers l'extérieur.** La veille interroge ; elle n'écrit nulle part ailleurs qu'ici. Rien de publié, aucun chantier ouvert, aucun compte tiers touché.
- La cadence suit le rythme de l'utilisateur, pas celui du monde : tout arrive frais le jour où il s'assoit, rien ne s'empile la nuit.
- **La brièveté du rapport est le but.** Le filtre est fait pour écarter. Un rapport qui liste tout n'a rien filtré.
- En constellation, plusieurs MOS surveillent le même substrat et font le travail deux fois. Redondant, pas faux — chacun le lit à travers son propre filtre. Partager un seul rapport entre installations relève de l'opérateur, pas d'une règle du cadre.
