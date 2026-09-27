---
type: guide
title: "Contributing to Manence"
description: Contribution rules for the repository (language, lint, licenses, what is welcome).
timestamp: 2026-07-05
---

# Contributing to Manence

Thanks for your interest. A few simple rules.

## Language

The doctrine of this repository is maintained **in English**, and so is everything the framework ships to a MOS (`implementation/mos/`: identity files, skills, hooks, templates). A skill is a program: it is written in English and it produces its outputs (log entries, About fields, replies) in the MOS's working language, which `AGENTS.md` declares. Manence was **born in French**, and that lineage ships with the repo as a French presentation set: `README.fr.md`, `Manifesto.fr.md`, `QUICKSTART.fr.md`. Issues and PRs are welcome **in English or in French**.

What this means in practice:
- a PR that touches the English doctrine or the install set doesn't need to touch anything else — English is the single original;
- a PR that changes the README, Manifesto, or QUICKSTART flags the French counterpart (the maintainers regenerate it — it's a derived translation, never edited on its own);
- there is no French install set anymore (removed in 0.10, decision of 2026-09-27): a French MOS runs the English organs and writes in French.

## Before a PR

1. Read the [Manifesto](Manifesto.md) and the [Spec](implementation/Spec.md): the repository's conventions (OKF, frontmatter, relative links) are documented and linted.
2. Run the lint locally; it must report **0 findings**:
   ```bash
   bash implementation/mos/.claude/hooks/lint.sh
   ```
3. One PR, one idea. The framework applies its own law L6 to itself: one file, one idea; one PR, one coherent change.

## What is welcome

- Fixes (links, typos, YAML) and improvements to the default MOS (`implementation/mos/`, its `BOOTSTRAP.md`, the hooks).
- Reports from real-world operation: open a "field report" issue — this is the raw material of releases (the framework evolves by harvesting lived lessons, not by speculation).
- Ports to languages other than FR/EN: discuss in an issue first (the doctrine has a single home per language, L2).

## What will be declined

- Adding concepts with no source and no field grounding (the repository publishes nothing asserted without a primary source or a lived lesson).
- Duplicating content that already has a home (L2: you link, you don't copy).

## Licenses

By contributing, you agree that your contribution is published under the repository's licenses: MIT for code and templates, CC BY-NC-SA 4.0 for the doctrine (see [LICENSE](LICENSE) and [LICENSE-docs.md](LICENSE-docs.md)).
