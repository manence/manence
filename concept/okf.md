---
type: reference
title: The OKF format
description: "Open Knowledge Format (Google), the framework's file contract: YAML frontmatter + markdown body, a single required field (type), permissive conformance. Why this contract is the right shape for a memory that an agent reads and writes."
tags: [ai-os, okf, frontmatter, contrat]
timestamp: 2026-07-02
---

# The OKF format

## What it is

The **file contract** that every knowledge page follows: a **YAML frontmatter** + a **markdown body**, one concept per file, its identity = the path without `.md`. The framework adopts **OKF v0.1** (Open Knowledge Format, Google) rather than a homegrown convention, so that it speaks an open, interoperable format.

The minimal rule, and this is all that is required:

```yaml
---
type: <required>   # THE ONLY required field, the routing key (reference, competitor, runbook…)
---
```

The five other OKF fields (`title`, `description`, `resource`, `tags`, `timestamp`) are **recommended**, not required.

## How it works

### `type:` is the routing key
A single required field, because it is what you use to **filter and route**: "read every `type: competitor`", "ingest the `type: runbook`". This is what makes a folder of markdown **queryable like a database** with no database.

### Permissive conformance (the principle that makes it hold up)
A consumer **must preserve** keys it does not recognize and **must not** reject a bundle over any of: a missing optional field, an unknown `type`, a broken link, or a missing `index.md`. The guiding consequence: the format **tolerates incompleteness and extension** — you can enrich a bundle without breaking existing readers, and connect bundles from different origins.

### Two reserved names (the entry points)
`index.md` (a folder's catalog, **with no frontmatter**) and `log.md` (an append-only journal) are exempt from the frontmatter rule; they are the agent's entry maps.

### The freshness extensions
Outside OKF but allowed (permissive conformance), for facts that expire: `valid_from`, `superseded_by`, `status:`. They give you the "poor man's Graphiti" (see [modele-memoire](modele-memoire.md)).

## Why this contract for AI

- **Readable/auditable on both sides**: YAML + markdown is compact for the LLM and diffable by a human in git.
- **A single required field**: the cost of entry is zero (you don't have to fill everything in), so the convention is *actually* followed — a rule you keep is worth more than a perfect schema you route around.
- **Permissive = composable**: this is what lets the hexagonal architecture connect heterogeneous bundles without a missing field making everything fail.

## → Source (verified)
**OKF v0.1 spec (Google)**, documented and re-read in [research/04 : Méthodes PKM](research/04-pkm-methodologies.md) (a bundle = a markdown folder, a file = a concept, `type` the only required field, permissive conformance, `index.md`/`log.md` reserved). Fidelity corrections to the spec kept here: `timestamp` rather than `updated`, the `resource` field, `index.md` with no frontmatter, freshness extensions labeled as outside OKF.

## → Alongside (the how)
- [templates/frontmatter.md](../implementation/mos/templates/frontmatter.md): the ready-to-copy blocks by `type`.
- [Spec §1 : Le contrat de fichier (OKF)](../implementation/Spec.md): the full rule and permissive conformance.

Related concepts: [La méthode wiki](methode-wiki.md) (OKF is the format of its pages) · [Le modèle de mémoire](modele-memoire.md) (the freshness extensions) · [Manifeste](../Manifesto.md).
