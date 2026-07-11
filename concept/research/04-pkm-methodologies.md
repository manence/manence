---
type: research
title: PKM Methods in the LLM Era
description: PARA, Zettelkasten, Johnny.Decimal, digital garden, OKF, judged by how legible each is to an LLM agent. The synthesized convention for a markdown + git knowledge base.
tags: [ai-os, research, pkm, okf]
timestamp: 2026-06-30
---

# PKM Methods in the LLM Era (research brief)

There is a new test: how well does each method serve an LLM agent acting as the **primary reader and writer** of a markdown + git knowledge base.

## Methodologies

**PARA (Tiago Forte).** Organize by *actionability*: **P**rojects / **A**reas / **R**esources / **A**rchives. No IDs, no required links. *LLM verdict*: useful, but weak on its own. Folder *names* leak an intent the agent can act on (`Archives/` means stale, skip it when the question is about what's current), but there is no per-file metadata and no links, so the agent has to infer everything from the prose. Good as a **top-level shelf**, not as a file format.

**Zettelkasten.** "One note, one idea"; knowledge emerges from dense links. Each note gets a unique ID (a timestamp like `202606301410`). *LLM verdict*: the *principle* is right: one file per idea is exactly what an agent wants to fetch and edit surgically. But the *implementation* works against you: opaque timestamp IDs as filenames are unreadable, you can't grep them, and they mean nothing to an LLM reasoning about semantics. Keep the principle (one idea per note) and the links; drop the cryptic IDs for readable slugs.

**Johnny.Decimal.** A numbered hierarchy with a fixed ceiling (AC.ID, ≤10 per level) for findability. *LLM verdict*: tuned for *human* recall ("I know it's 22.01"), which the agent doesn't need, since it greps. The numeric prefixes add noise and a rigid cap that fights organic growth. The idea of **bounded width** (small folders you can scan) helps; the numbering doesn't.

**Digital garden / evergreen notes (Matuschak, Appleton; Obsidian).** Concept-oriented "evergreen" notes, revised continuously, densely linked; nothing is ever "done." One concept per note, title-as-API, `[[wikilinks]]` / bidirectional links, a local markdown vault. *LLM verdict*: **the best inheritance from the human era for agents**. Descriptive titles are semantic anchors; `[[links]]` are explicit edges you can traverse; plain markdown is git-friendly. The weak spot: wikilinks aren't standard markdown (they break outside Obsidian), and there is no required `type`.

## OKF (Open Knowledge Format)

OKF (Google Cloud, June 2026) is the first spec *designed around AI agents as first-class consumers*. It specifies: a **bundle** is a folder of UTF-8 markdown files; **one file is one concept**; a concept's identity is its path without `.md` (`tables/users.md` → `tables/users`). Each file is YAML frontmatter (`---`) plus a free-form markdown body. **The only required field is `type`** (a short string for routing, filtering, and presentation). The recommended optional fields: `title`, `description` (one sentence), `resource` (a URI), `tags`, `timestamp` (ISO 8601). Links are **standard markdown links**, either absolute to the bundle (starting with `/`, recommended) or relative; a link from A to B *asserts a relation*. Two reserved names: `index.md` (listings) and `log.md` (history). Conformance is lenient: preserve unknown keys, and don't reject a file for a missing optional field or an unknown `type`.

Why it fits AI: "just markdown, just files" (readable anywhere, rendered on GitHub, git-hostable, no SDK), while `type` plus frontmatter give it a structure you can route on, and `index.md` / `log.md` separate stable reference from episodic log.

## The synthesized convention

For a markdown + git knowledge base that an agent both reads *and* writes:

1. **One concept per file** (Zettelkasten + OKF), so retrieval and editing stay surgical.
2. **Names are readable slugs** (`partenariat-acme.md`), no timestamps or decimal codes.
3. **YAML frontmatter everywhere**, OKF-style: `type:` required; plus `title`, `description`, `tags`, `timestamp:`.
4. **Standard markdown links, absolute to the bundle** (`[Acme](/partenaires/acme.md)`).
5. **An `index.md` per folder**, the agent's map, kept up to date so it doesn't drift.
6. **A single source of truth, no duplication**: link rather than restate.
7. **Separate stable reference from episodic log**: reference gets rewritten in place, `log.md` is append-only.
8. **Handle staleness**: `timestamp:` everywhere; move the inactive into an `Archives/` (PARA) to scope "current."

The pattern: **PARA for the shelf, evergreen/atomic for granularity, OKF for the file contract.**

## Sources
- PARA, https://fortelabs.com/blog/para/
- Zettelkasten, https://zettelkasten.de/atomicity/guide/
- Johnny.Decimal, https://johnnydecimal.com/documentation/philosophy
- Evergreen / gardens, https://maggieappleton.com/evergreens · https://obsidian.md
- OKF spec, https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md · https://okf.md/spec/
