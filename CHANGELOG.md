---
type: log
title: "Changelog: Manence"
description: Log of Manence's public releases.
timestamp: 2026-07-09
---

# Changelog

Log of Manence's public releases. Format based on [Keep a Changelog](https://keepachangelog.com/en/). Numbering stays in **0.x**: the framework is young and its doctrine is still shifting; 1.0.0 will arrive once that doctrine has settled under use by hands other than our own.

## [0.3.0] - 2026-07-11

**This release refounds the repository.** The git history restarts at this version (the repo had no external users yet); this changelog remains the memory of 0.1.0 and 0.2.0.

- **English becomes the canonical language.** The doctrine now lives in English at the root; the `en/` mirror folder is gone. Manence remains **born in French**: a French presentation set ships at the root (`README.fr.md`, `Manifesto.fr.md`, `QUICKSTART.fr.md`), and a French install set in `implementation/mos/fr/` — your own system installs in French if you ask. The full-mirror bilingualism of 0.2.0 (every file in both languages, kept in sync forever) is retired: it promised more than it kept.
- **Installing becomes a conversation.** `scaffold.sh` is retired. The repo ships `implementation/mos/` — the default MOS, ready to copy — with **`BOOTSTRAP.md`**, a one-time startup ritual the agent executes: language, an interview (name, activity, team, voice, direction), identity files filled from the answers, prerequisites checked, everything verified, then the ritual file deletes itself. Installing the system is already using it. *(Pattern borrowed from OpenClaw's BOOTSTRAP.md — see `concept/research/07`.)*
- **Entry path fixed** (from a cold-eye audit): `git clone` now precedes every install command; the QUICKSTART says how skills are invoked (by talking to the agent, not on a command line); prerequisites clarified (jq/python3, Windows).
- **Honest proof**: the README states plainly that the three production grounds are the author's own — proof of practice, not yet of adoption — and shows a real journal trace.
- **New research brief**: `concept/research/07-openclaw-identity.md` — the SOUL.md attribution sourced, the STRATEGY.md-versus-USER.md divergence documented.
- **Renames**: `Mise en oeuvre.md` → `Implementation.md`, `Spec - Conventions.md` → `Spec.md`; `LICENSE-docs.md` now in English.

## [0.2.0] - 2026-07-09

- **Fully bilingual**: the `en/` folder is the complete English mirror of the readable body; French holds true, and the English is regenerated from it. A 🌐 language switch sits on every page.
- **Canonical vocabulary**: a **MOS** (Manence OS) is one complete install of the framework, dedicated to a single line of work; **the core** is the git repository where you launch the AI (Manifesto, hexagonal architecture, Spec §0). Default rule for splitting: "the system follows the capital." The term **"Manence OS"** replaces "AI-OS" everywhere.
- **The 7 layers renumbered**: Memory moves to layer 6 (Capability 3, Execution 4, Automation 5). The order now follows the **static → dynamic** gradient, and the **three organs** (the knowledge that holds true · the gesture carried through · the real world, wired in) cover the layers in three contiguous ranges (1-2 · 3-5 · 6-7). New diagram `assets/en/schema-organes-couches` in the Manifesto.
- **Docs realigned with the canon**: README rewritten (the diagnosis: accumulation, not forgetting; the three organs; the field evidence; "what Manence is not"; portability), QUICKSTART and Manifesto revised. The guiding idea enters the doctrine: **the system does the tidying**.
- **Lint refocused on structure**: the typographic check (em dash) is removed; that was a rule about voice, not about the system.
- CONTRIBUTING: the bilingual rule (a PR on the French doctrine carries the English through).
- Re-versioning: the 1.0.0 of 2026-07-05 is renumbered **0.1.0** (an owned early stage, before any public distribution).

## [0.1.0] - 2026-07-05

First release, under the name **Manence**. *(Originally published as 1.0.0; renumbered 0.1.0 when the project moved to 0.x numbering, before any distribution.)*

- The full framework: Manifesto (mental model, 7 layers, 9 laws, maturity scale), 9 concepts unpacked, 5 verified source notes (plus one credited private source: LIVING REFERENCE, JP Noto) (`concept/research/`).
- The implementation: Spec (conventions), Implementation (playbook), templates, 6 base skills (`open-work`, `close-work`, `weekly-review`, `kb-ingest`, `kb-lint`, `connect-adapter`), safety hooks (`guard.sh`, `lint.sh`), a complete example (`example/`).
- `scaffold.sh`: a complete project in one command.
- Dual license: MIT (code, templates, example) plus CC BY-NC-SA 4.0 (doctrine).

The framework was built and put through real conditions (running a SaaS company) before this release; this 0.1.0 corresponds to internal v1.1, after the lessons of the first pilot were worked in.
