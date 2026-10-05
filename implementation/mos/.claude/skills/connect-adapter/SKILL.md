---
name: connect-adapter
description: Use it when plugging something new into a Manence OS core — a neighboring repository, a knowledge bundle, a capability, a confidential adapter — or when an existing connector's declaration needs fixing. Validates the adapter contract, routes by confidentiality (the connector map in the shared AGENTS.md, or the gitignored CLAUDE.local.md for confidential ones), writes the map line, declares the attachment in .claude/mos.json (never for a confidential adapter), and logs it.
---

# connect-adapter, wiring in an adapter

## Purpose
To add an adapter to the core **without breaking zero-knowledge** (L9, Spec §12) or the hygiene of the bundles. Separate **access** (can it read?) from **knowledge** (does it know the adapter exists?).

## Input
- The **path** to the adapter repo (e.g. `../my-adapter`, relative to the core).
- The **type**: `knowledge` (a knowledge bundle) | `capability` (a skill + connector) | `confidential`.

## Procedure

### 1. Validate the adapter contract (Spec §15)
- **Blocking**: no `.git` of its own (not an adapter); no self-describing identity file; a committed secret; a `knowledge` bundle that is not OKF or carries a secret or code (it is a capability: split it out as a separate bundle); a `confidential` adapter with a public remote.
- **Warn**: a hardcoded machine path (suggest an env variable); a `SKILL.md` without `name:` or `description:`.

> If a **blocking** point fails → **refuse to wire it in**, say exactly what to fix, and stop.

### 2. Route it
- **`confidential`** → the core's `CLAUDE.local.md` (gitignored, local).
- **`knowledge` / `capability`** → the connector map in the core's `AGENTS.md` (the "Connectors" section).

### 3. Draft the map line
One entry **in the existing map's format**, saying what to open and why, and naming the connector's skills if it has any. Drafted, not written yet.

### 4. Draft the attachment for `.claude/mos.json` (`knowledge`/`capability` only)
Draft the attachment following the schema described at the top of the file (the `//` key) and in Spec §19. No `mos.json`? Don't create one for this: note its absence in the report.

### 5. Explicit GO
Show the user **the exact line** + **the target file** (`AGENTS.md` or `CLAUDE.local.md`), plus **the `mos.json` attachment** when applicable, and **wait for the GO**; only then write both.

### 6. Log it (`knowledge`/`capability` only)
After writing, at the top of `log.md`, under its H1 (Spec §4): `## [YYYY-MM-DD] connect | <adapter> → AGENTS.md`.

## Guardrails
- A `confidential` adapter enters **no shared file**: not the `AGENTS.md` map, not `log.md`, not `.claude/mos.json`. Its only trace lives in `CLAUDE.local.md` (zero-knowledge, Spec §12).
- A connector fact has **two synchronized homes**: the `AGENTS.md` map (the prose that is authoritative) and the `mos.json` attachment (the machine declaration). Changing one checks the other — this skill is what guarantees the alignment.

## Done
- Success condition: the contract is validated, the line is written in the **right** target after the GO; a `mos.json` attachment and a log entry **only** for `knowledge` / `capability`.
- Reading criterion: the map line, read alone by a fresh context, is enough to know what to open and why.
- Trace: the `connect |` log entry or, for a `confidential` adapter, its single line in `CLAUDE.local.md`.
