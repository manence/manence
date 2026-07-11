---
type: research
title: "Karpathy and practitioners: personal knowledge systems for AI"
description: How Karpathy, Willison, swyx, Litt, and Forte structure their knowledge to work with an LLM. Concrete mechanics and patterns worth borrowing.
tags: [ai-os, research, karpathy, pkm]
timestamp: 2026-06-30
---

# Karpathy and practitioners (research brief)

## Karpathy (philosophy + mechanics)

**Philosophy.** *Software 3.0 / "LLM as OS"*: weights = CPU, **context window = RAM**, and everything outside it (notes, docs, vector stores) = disk that you have to **load** explicitly before it can shape the reasoning. Hence **context engineering**: "the delicate art of filling the window with just the right information for the next step." A corollary (April 2026, the *LLM Knowledge Bases* tweet + the `llm-wiki.md` gist): spend your token throughput "less on shuffling code, more on shuffling **knowledge**." Treat knowledge the way you treat code: *your PDFs/notes are the source code, the wiki is the binary, the LLM is the programmer.*

**Concrete mechanics (from his gist):**
- **Three layers**: (1) **raw sources** = immutable inputs; (2) **the wiki** = markdown the LLM generates and cross-references; (3) **the schema** = a config doc (e.g. `CLAUDE.md`) that sets the conventions. Markdown throughout: "the most compact structured format, readable by the LLM and auditable by the human."
- **Ingestion loop**: the LLM "reads the source, discusses the key points with you, writes a summary page, **updates the index, updates the wiki's entity/concept pages, and adds a log entry**." It doesn't file things away, it **integrates** them, revises the summaries, and **flags contradictions** with existing claims.
- **`index.md`** = a catalog (one link and one line per page). **`log.md`** = append-only, with parseable prefixes like `## [2026-04-02] ingest | Title`.
- **Query** = search across the pages and synthesize with citations; good answers get folded back in as new pages. **Lint** = a periodic health check (contradictions, stale claims, orphan pages, missing cross-refs).
- **Division of labor**: the human curates the sources, explores, and asks the right questions; the LLM summarizes, cross-references, sorts, and keeps the books. The human works through Obsidian; the LLM through Claude Code with filesystem access (`cd ~/wiki && claude`).
- **Community template**: `wiki/{_templates,projects,research,reference,meetings,inbox}/`, a header per note (`**Summary:**`, `**Tags:**`, timestamps), Obsidian `[[wiki links]]`, and an `inbox/` for raw capture that the LLM sorts later.

## Other practitioners

**Simon Willison: the blog/notes as queryable external memory.** Everything you learn becomes a durable, searchable artifact. The **`llm` CLI** logs every prompt+response to SQLite (`~/.llm/log.db`), which you can browse with Datasette. His **TIL repo** (~580 entries) = **one folder per topic, one markdown file per thing learned** (`python/convert-to-utc.md`). *Worth borrowing*: a small markdown file per lesson, `topic/specific-thing.md`, committed right away; log the LLM's I/O to a queryable store.

**swyx: Learn in Public / a public second brain.** Public notes to "widen your luck surface area"; you're talking to yourself-from-3-months-ago. An Obsidian vault synced to a public GitHub repo via **Obsidian Git auto-committing every 20 minutes**; organized with **PARA**; an explicit split between **raw and polished**. *Worth borrowing*: timed auto-commit (versioning without ceremony); a `raw/`/`inbox/` tier where unfinished thinking is allowed.

**Geoffrey Litt: malleable software.** "Edit software at the speed of thought": build the *smallest* tool for your own use and extend it the moment a need shows up. *Worth borrowing*: keep the schema doc (`CLAUDE.md`/conventions) editable and let Claude Code evolve the wiki's structure as the needs change.

**Tiago Forte: PARA / Building a Second Brain.** **CODE** (Capture, Organize, Distill, Express) + **PARA** (organize by *actionability*, not by topic): Projects / Areas / Resources / Archive. *Worth borrowing*: PARA as the top-level folder layout, so the LLM sorts every note by actionability.

## Patterns worth borrowing

- **Source ≠ wiki ≠ schema** (Karpathy's 3 layers).
- **`index.md` + append-only `log.md`** (dated, parseable prefixes).
- **Ingest = integrate, don't dump**: update entities/concepts + flag contradictions.
- **A `lint` command**: orphans, stale claims, contradictions, missing links.
- **A raw-capture `inbox/`** sorted afterward.
- **One file per idea, `topic/specific-thing.md`** (Willison).
- **Timed auto-commit** (swyx, 20 min).
- **`[[wikilinks]]`** as a graph for human+LLM (Obsidian vaults only).
- **Top-level PARA** (Forte) for deterministic sorting.
- **Log the LLM's I/O** to a queryable store (Willison + Datasette).

## Sources
- Karpathy, *LLM Knowledge Bases*, https://x.com/karpathy/status/2039805659525644595
- Karpathy, gist `llm-wiki.md`, https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- MindStudio (LLM Wiki + Claude Code), https://www.mindstudio.ai/blog/andrej-karpathy-llm-wiki-knowledge-base-claude-code
- MindStudio (Software 3.0), https://www.mindstudio.ai/blog/software-3-0-explained-karpathy-context-window-ram-model-weights-cpu
- DAIR.AI Academy, https://academy.dair.ai/blog/llm-knowledge-bases-karpathy
- Willison, `llm` CLI + SQLite, https://simonwillison.net/2023/Apr/4/llm/
- Willison TIL, https://github.com/simonw/til · https://til.simonwillison.net/llms
- swyx, Learn in Public, https://swyx.io/learn-in-public · Obsidian brain, https://www.swyx.io/obsidian-brain · repo, https://github.com/swyxio/brain
- Geoffrey Litt, https://www.geoffreylitt.com/2023/03/25/llm-end-user-programming.html
