---
name: mos-map
description: Generates the visual map of a MOS — one self-contained HTML file (no server, works offline, opens on double-click) showing the hexagon and its attachments (knowledge base, production, connectors), the file explorer, the local knowledge graph with full-text search, the journal as a timeline. Read-only scan of the real MOS; interne/public disclosure profiles. Use it when the user wants to *see* their MOS, to refresh the map after some work, or to produce a shareable map.
---

# mos-map, the visual map of the MOS

## Purpose
Make a MOS visible at a glance: **nothing is drawn, everything is generated** from the real files. The grammar: one kind of object, one rendering — the MOS as a façade (the hexagon, vertices 0-5: 0 = north for production, 3 = south for the knowledge base, connectors on the diagonals), a directory as an explorer, a linked corpus as a scoped local graph, a record as a rendered page (markdown, navigable internal links), the journal as a timeline.

## Usage
```
python3 .claude/skills/mos-map/build.py --coeur <core-root> [options] --ouvrir
```
- `--coeur` (required): the root of the MOS's repository.
- `--production`: the production root (default: `$MOS_PRODUCTION_ROOT`, else `<core>/../production`).
- `--kb`: if the knowledge base is a **separate adapter** (older-generation MOS), its root.
- `--lang fr|en`: the map's interface language (default: `en`).
- `--profil interne|public`: `interne` (default) embeds descriptions, excerpts, the .md bodies, the inbox and machine paths; `public` outputs **structure, counts and titles only**.
- `--sortie`: the output file (default: `carte-<name>-<profile>.html` in the cwd); `--ouvrir`: open it in the browser.

Example — this MOS: `python3 .claude/skills/mos-map/build.py --coeur . --ouvrir`

## What the map reads
- The organs: `log.md` (entries `## [date] type | title`, sorted, types normalized), `inbox/`, `.claude/skills/`, `knowledge-base/` (OKF records, real markdown links — `index.md` files are catalogs, kept out of the graph), production (`in-progress`/`done`, legacy alias `published`).
- **`.claude/mos-map.json`** (schema 2, shipped with the two pillars): the hexagon's **attachments** (vertex 0-5, nature `kb | production | mos | git | externe`, display name, one-line summary, outbound links, `visible`) and the **declared routines** (cadence + actual state). Keep it aligned with the CLAUDE.md connector map: the `connect-adapter` skill writes both.

## Guardrails
- **Read-only**: the scan writes nothing into the MOS; the map is a **dated snapshot** — refreshing it means re-running the command (candidate: regenerate it at each weekly-review).
- **Confidentiality**: the interne file embeds the corpus — share it like a sensitive document. For a third party: `--profil public`. For marketing use: a **synthetic dataset**, never a real corpus (even public, titles are facts). A confidential adapter (CLAUDE.local.md) is never scanned nor declared.
- **Nothing gets published without an explicit GO** (hosted page, shared artifact, website).
- Prerequisites: `python3` (stdlib only) to generate; a recent browser to view. No server, no network, no dependency. Vendored `d3-slim.min.js` (ISC license, © Mike Bostock).
