---
type: reference
title: Frontmatter par type
description: Le format de frontmatter selon le type de fichier, conforme au spec OKF v0.1 de Google. Copier le bloc voulu.
tags: [ai-os, template, frontmatter, okf]
timestamp: 2026-06-30
---

# Frontmatter par type

Conforme à **OKF v0.1** (Open Knowledge Format, Google). **Seul `type:` est obligatoire** ; les autres champs OKF sont *recommandés*. Un consommateur préserve les clés qu'il ne connaît pas et ne rejette pas un fichier pour un champ manquant.

## Champs OKF (ordre de priorité du spec)

```yaml
type:        # OBLIGATOIRE, clé de routage (reference, runbook, partner…)
title:       # titre lisible
description: # une phrase, sert à juger la pertinence au rappel
resource:    # URI de l'asset sous-jacent (URL source, dashboard, fichier), si pertinent
tags: [a, b]
timestamp: 2026-06-30   # ISO 8601, dernier changement de fond
```

## Extensions Manence (hors OKF, mais permises)

Pour les faits qui peuvent périmer :

```yaml
valid_from: 2026-06-30        # depuis quand c'est vrai
superseded_by: ../chemin/v2.md  # quand remplacé (au lieu d'écraser)
status: canon                 # proposal | validated | canon | archived | rejected
```

Pour un chantier (`type: work`) seulement, son identité stable :

```yaml
work_id: 20260712-campagne-meta-rentree   # le nom du dossier, tel qu'il était à la naissance
```

- `work_id` est ce par quoi un lecteur, une carte ou un autre MOS désigne ce chantier : écrit à la naissance, identique au nom du dossier, et **jamais renommé** — la clôture déplace le dossier, et un jour le dossier peut encore bouger ; l'identifiant ne suit pas.
- **Pas de rétrofit** : un chantier ouvert avant ce champ n'en a tout simplement pas, et personne ne lui en invente un après coup.

Pour un chantier (`type: work`) seulement, ce qui attend un humain :

```yaml
awaiting:
  - who: alexandre          # identifiant court et stable dans le MOS, pas d'e-mail, pas de nom complet
    what: autoriser les citations clients dans les pubs
    kind: decision          # decision = un choix que seule cette personne peut faire | action = un geste que seule cette personne peut poser (clic, paiement, appel)
    since: 2026-09-08       # le jour où l'attente est née, pas la dernière relance
    blocks: mise en ligne   # optionnel : ce que l'attente empêche
```

- `who`, `what`, `kind` et `since` sont obligatoires sur chaque entrée ; `blocks` est optionnel.
- `kind` prend exactement deux valeurs : `decision` ou `action`.
- Champ absent ou liste vide (`awaiting: []`) = rien n'attend ; une attente tranchée se **retire** de la liste (c'est un état présent, pas un historique) et sa résolution s'écrit dans la section Décisions de l'About, et au log si elle change un statut.

## Fichiers réservés OKF

- **`index.md`**, listing de dossier, **sans frontmatter** (voir `index.template.md`).
- **`log.md`**, journal chronologique append-only (un petit frontmatter `type: log` reste toléré).

## Gabarits prêts à copier

### `reference`, un fait stable
```yaml
---
type: reference
title: <titre>
description: <une phrase>
tags: []
timestamp: 2026-06-30
---
```

### `runbook`, une procédure
```yaml
---
type: runbook
title: <quoi faire>
description: <quand l'utiliser>
timestamp: 2026-06-30
---
```

### `log`, journal (nom réservé `log.md`)
```yaml
---
type: log
title: "Journal : <projet ou dossier>"
description: Historique append-only.
timestamp: 2026-06-30
---
```
