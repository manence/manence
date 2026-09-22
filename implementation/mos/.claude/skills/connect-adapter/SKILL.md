---
name: connect-adapter
description: Use it when plugging something new into a Manence OS core — a neighboring repository, a knowledge bundle, a capability, a confidential adapter — or when an existing connector's declaration needs fixing. Validates the adapter contract, routes by confidentiality (the connector map in the shared AGENTS.md, or the gitignored CLAUDE.local.md for confidential ones), writes the map line, declares the attachment in .claude/mos.json (never for a confidential adapter), and logs it.
---

# connect-adapter, wiring in an adapter

## Purpose
To add an adapter to the core **without breaking zero-knowledge** (L9) or the hygiene of the bundles. Separate **access** (can it read?) from **knowledge** (does it know the adapter exists?).

## Input
- The **path** to the adapter repo (e.g. `../my-adapter`, relative to the core).
- The **type**: `knowledge` (a knowledge bundle) | `capability` (a skill + connector) | `confidential`.

## Procedure

### 1. Validate the adapter contract (a light checklist, report ✓/✗ per point)
- **Self-contained repo**: `../my-adapter/.git` exists. ✗ blocking → not an adapter, refuse.
- **Self-describing**: has an identity file that describes itself (`AGENTS.md`, or the `CLAUDE.md` of a repo that predates it). ✗ blocking.
- **Secrets**: has a `.env.example`, `.env` is gitignored, no secret committed. A quick grep (`git ls-files | grep -i '\.env$'`, and a scan for keys under version control). ✗ blocking if a secret is committed.
- **Portable paths**: no hardcoded machine path (grep `/Users/`, `~/Dev/`, `/home/`). ✗ → warn (non-blocking), suggest using an env variable.
- **Declared skills**: if the adapter has `SKILL.md` files, each one has a `name:` + `description:` in the frontmatter (so they can be listed in the map). ✗ → warn.
- **If `knowledge`**: OKF respected (has an `index.md`, every page has a `type:` in its frontmatter), **pure facts**: **no** `.env` / secret, **no** executable code. ✗ blocking: this isn't a knowledge bundle, it's a capability → split it out as a separate bundle.
- **If `confidential`**: `.env` / data properly gitignored, **no public remote** (`git remote -v`). ✗ blocking.

> If a **blocking** point fails → **refuse to wire it in**, say exactly what to fix, and stop.

### 2. Route it (zero-knowledge, L9)
- **`confidential`** → target = the core's **`CLAUDE.local.md`** (gitignored, local). **NEVER** the shared `AGENTS.md`: the mere mention betrays its existence.
- **`knowledge` / `capability`** → target = the **connector map** in the core's **`AGENTS.md`** (shared, read at the start of every session).

### 3. Write the map line
Format:
```
- <Name> · <relative path> · <role in 4 words> · skills: <the SKILL.md names, or "none">
```
E.g.: `- Growth Ops · ../growth-ops · fetch analytics + publish · skills: gads-fetch, social-publish`

A reminder to leave once at the top of the map:
> To use a connector skill: read its `SKILL.md` by path and follow it. No `--add-dir` required (a convenience option only).

### 3 bis. Declare the attachment in the MOS's declaration (`knowledge`/`capability` ONLY)
If the core has a `.claude/mos.json` (schema 3 — the machine-readable declaration of the MOS, read by the weekly review and by any reader of this system; a schema 2 file still reads), add the new adapter's attachment:
```json
{ "sommet": <0-5, a free position; 0 and 3 are reserved for production/KB>,
  "id": "<id>", "nature": "mos | git | externe", "nom": "<display name>",
  "resume": "<one displayed sentence>", "liens": [["<label>", "https://…"]] }
```
⚠️ **NEVER for a `confidential` adapter**: `mos.json` is versioned and shared — an attachment there would break zero-knowledge (L9), exactly like an `AGENTS.md` map line. A confidential adapter is declared nowhere that is shared, so no reader of this system ever shows it.
A knowledge bundle that *is* the system's knowledge base (the KB living in a separate repository) also sets `"chemin": "<path relative to the core>"` on its `kb` attachment, so that a reader finds it without guessing.

No `mos.json`? Don't create one for this — just note its absence in the report.

### 4. Explicit GO
Show the user **the exact line** + **the target file** (`AGENTS.md` or `CLAUDE.local.md`), plus **the `mos.json` attachment** when applicable, and **wait for the GO** before writing.

### 5. Log it
- **If `knowledge` / `capability`**: after writing, add to the core's `log.md`:
  ```
  ## [YYYY-MM-DD] connect | <adapter> → AGENTS.md
  ```
- **If `confidential`**: **no** log entry, in the core's `log.md` or anywhere else that is shared. The only trace of the wiring lives in `CLAUDE.local.md` (gitignored); merely mentioning the adapter's existence in a shared file would break zero-knowledge.

## Guardrails
- **Never** route a `confidential` adapter to the shared `AGENTS.md`, nor to its `log.md`, **nor to `.claude/mos.json`**: no map line, no log entry, no declared attachment, no shared history trace.
- A connector fact has **two synchronized homes**: the `AGENTS.md` map (the prose that is authoritative) and the `mos.json` attachment (the machine declaration any reader goes by). Changing one checks the other — this skill is what guarantees the alignment.
- The core does **not** store the adapters' keys: each one keeps its own `.env`.
- Access ≠ knowledge: this procedure handles **knowledge** (the map); **access** (`--add-dir`) stays a launch-time shim, outside the bundle.
- Success condition: the contract is validated, the line is written in the **right** target after the GO; the core's `log.md` is up to date **only** for `knowledge` / `capability`; for `confidential`, no shared trace — the wiring lives only in `CLAUDE.local.md`.
