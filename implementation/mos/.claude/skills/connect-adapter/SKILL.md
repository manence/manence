---
name: connect-adapter
description: Cleanly connects a new adapter (a knowledge bundle, a capability bundle, or a confidential one) to a Manence OS core. Validates the adapter contract, routes by confidentiality (the connector map in the shared CLAUDE.md, OR the gitignored CLAUDE.local.md for confidential ones), writes the map line, logs it. Use it when wiring a neighboring repo to the core.
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
- **Self-describing**: has a `CLAUDE.md` that describes itself. ✗ blocking.
- **Secrets**: has a `.env.example`, `.env` is gitignored, no secret committed. A quick grep (`git ls-files | grep -i '\.env$'`, and a scan for keys under version control). ✗ blocking if a secret is committed.
- **Portable paths**: no hardcoded machine path (grep `/Users/`, `~/Dev/`, `/home/`). ✗ → warn (non-blocking), suggest using an env variable.
- **Declared skills**: if the adapter has `SKILL.md` files, each one has a `name:` + `description:` in the frontmatter (so they can be listed in the map). ✗ → warn.
- **If `knowledge`**: OKF respected (has an `index.md`, every page has a `type:` in its frontmatter), **pure facts**: **no** `.env` / secret, **no** executable code. ✗ blocking: this isn't a knowledge bundle, it's a capability → split it out as a separate bundle.
- **If `confidential`**: `.env` / data properly gitignored, **no public remote** (`git remote -v`). ✗ blocking.

> If a **blocking** point fails → **refuse to wire it in**, say exactly what to fix, and stop.

### 2. Route it (zero-knowledge, L9)
- **`confidential`** → target = the core's **`CLAUDE.local.md`** (gitignored, local). **NEVER** the shared `CLAUDE.md`: the mere mention betrays its existence.
- **`knowledge` / `capability`** → target = the **connector map** in the core's **`CLAUDE.md`** (shared, auto-loaded at startup).

### 3. Write the map line
Format:
```
- <Name> · <relative path> · <role in 4 words> · skills: <the SKILL.md names, or "none">
```
E.g.: `- Growth Ops · ../growth-ops · fetch analytics + publish · skills: gads-fetch, social-publish`

A reminder to leave once at the top of the map:
> To use a connector skill: read its `SKILL.md` by path and follow it. No `--add-dir` required (a convenience option only).

### 4. Explicit GO
Show the user **the exact line** + **the target file** (`CLAUDE.md` or `CLAUDE.local.md`) and **wait for the GO** before writing.

### 5. Log it
- **If `knowledge` / `capability`**: after writing, add to the core's `log.md`:
  ```
  ## [YYYY-MM-DD] connect | <adapter> → CLAUDE.md
  ```
- **If `confidential`**: **no** log entry, in the core's `log.md` or anywhere else that is shared. The only trace of the wiring lives in `CLAUDE.local.md` (gitignored); merely mentioning the adapter's existence in a shared file would break zero-knowledge.

## Guardrails
- **Never** route a `confidential` adapter to the shared `CLAUDE.md`, nor to its `log.md`: no map line, no log entry, no shared history trace.
- The core does **not** store the adapters' keys: each one keeps its own `.env`.
- Access ≠ knowledge: this procedure handles **knowledge** (the map); **access** (`--add-dir`) stays a launch-time shim, outside the bundle.
- Success condition: the contract is validated, the line is written in the **right** target after the GO; the core's `log.md` is up to date **only** for `knowledge` / `capability`; for `confidential`, no shared trace — the wiring lives only in `CLAUDE.local.md`.
