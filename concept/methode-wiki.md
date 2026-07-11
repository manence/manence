---
type: reference
title: The wiki method
description: "Treat knowledge like code: raw sources → a wiki the LLM maintains → schema, so a domain's knowledge becomes a queryable, integrated memory rather than a pile of notes. Karpathy's pattern."
resource: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
tags: [ai-os, knowledge-management, karpathy, wiki]
timestamp: 2026-06-30
---

# The wiki method

## What it is

The way to organize a **domain's knowledge** (layer 2) so an AI agent can put it to use: not a folder where notes pile up, but a **living wiki that the LLM maintains**. It is Andrej Karpathy's pattern (*LLM Knowledge Bases*, the `llm-wiki.md` gist), which he himself calls **"intentionally abstract"** — a pattern to adapt with your LLM, not a fixed implementation.

The analogy that underpins everything: **knowledge is handled like code.**

> *Your PDFs / notes = the source code · the wiki = the binary · the LLM = the programmer.* (Karpathy)

The insight that justifies investing here: the cost of a knowledge base **is not reading and it is not thinking — it is the bookkeeping**: filing, linking, reconciling, indexing, dating. This is exactly the work a human hates and gives up on, and that the LLM does **tirelessly**. The wiki method exists to hand that bookkeeping to the machine.

## How it works

### Three layers (the structure)
1. **Raw sources** (`sources/`): the **immutable** inputs (articles, PDFs, transcripts, data). The LLM reads them and never changes them. This is the *source code*.
2. **The wiki** (`knowledge-base/`): the pages **the LLM generates and links to one another** (summaries, entity pages, concept pages, comparisons, syntheses). **One concept = one file.** The LLM owns it; you read it. This is the *binary*.
3. **The schema** (`CLAUDE.md`): the structure, conventions, and workflows the LLM follows. It co-evolves with the domain. This is the *build config*.

Markdown throughout — in Karpathy's words, "the most compact structured format, readable by the LLM and auditable by the human." The index (`index.md`) catalogs the pages (one link plus one line); the log (`log.md`) is append-only, with dated, parseable prefixes.

### Three loops (the life of the wiki)
Three motions keep the wiki alive. Here their *nature* and their principle; the exact steps live in the companion piece.
- **Ingestion**: brings a source into the wiki. Its principle: **integrate, don't dump** (law **L7**). A source is not archived as-is; it revises the existing pages and **surfaces contradictions** instead of overwriting them. Supervised, one source at a time.
- **Query**: answers a question from the wiki. Its principle: **every good answer becomes a page**. The exploration does not evaporate into the chat; it *compounds*, and knowledge accumulates instead of being replayed.
- **Lint**: a periodic health audit. Its principle: **actively look for the disorder that creeps in** (contradictions, stale claims, orphan pages, concepts with no page, missing links, gaps) before it rots the knowledge. It yields new questions worth digging into.

### How the work is split (the heart of it)
Karpathy verbatim: **you** select the sources, ask the right questions, steer the analysis, and review; **the LLM** does *everything else*: summarizing, creating and linking pages, noting contradictions, keeping the index and the log, linting. A clean division: **the agent writes the wiki (it searches through the files), you explore it** (the Obsidian graph is the optional human view — see [modele-memoire](modele-memoire.md)).

## Why it is the right shape for AI

- **Single source, you link** (L2): a fact has one home, and pages reference each other instead of copying, otherwise the LLM drifts.
- **Integrate > pile up** (L7): the knowledge stays coherent and free of duplicates, so it stays queryable with high signal (L1) instead of flooding the RAM.
- **Bookkeeping is free**: what made a wiki unmanageable by hand (keeping it up to date) is precisely what the LLM does at zero marginal cost.

## → Source (verified)
[research/01: Karpathy & practitioners](research/01-karpathy-practitioners.md): the `llm-wiki.md` gist, the *LLM Knowledge Bases* tweet, and the patterns borrowed from Willison (one concept = one file), swyx (auto-commit), Litt (malleable schema), Forte (PARA).

## → Companion (the how)
The **step-by-step procedure** and the ready-to-copy tools live in the implementation:
- [Implementation §3: The wiki method](../implementation/Implementation.md): the 3 layers, the split of work, and the ingestion / query / lint loops in detail.
- Runnable skills: [`kb-ingest`](../implementation/mos/.claude/skills/kb-ingest/SKILL.md) (integrate a source) and [`kb-lint`](../implementation/mos/.claude/skills/kb-lint/SKILL.md) (periodic audit).

Related concepts: [The OKF format](okf.md) (the contract the wiki's pages follow) · [The memory model](modele-memoire.md) (where the wiki is filed: semantic memory) · [Manifesto](../Manifesto.md) (layer 2).
