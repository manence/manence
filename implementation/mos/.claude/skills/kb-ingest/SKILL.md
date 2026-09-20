---
name: kb-ingest
description: Use it whenever an outside source has to become knowledge — an article, a PDF, a transcript, a web page, raw notes, or something the user simply pastes in. Reads the source and summarizes it into one concept page following the wiki method (Karpathy), updates the index and the linked pages, flags contradictions with what is already there, and logs it.
---

# kb-ingest, integrating a source

## Purpose
To turn a raw source into **integrated knowledge**, without piling up duplicates. Law L7: *to ingest is to integrate*, not to drop off.

## Input
A source: a file in `sources/` or `inbox/`, or a URL / path the user provides.

## Procedure
1. **Read** the source in full.
2. **Discuss** the 3-5 key points to keep with the user, and wait for approval. You don't keep everything (law L1: high signal).
3. **Write / update the concept page** in `knowledge-base/`: one concept, one file (`domain/specific-thing.md`), OKF frontmatter (`type`, `title`, `description`, `resource` = the source, `tags`, `timestamp`). Template: `concept.template.md`.
4. **Update `knowledge-base/index.md`**: add or adjust the line (a link + one sentence). *(index.md = an OKF listing, no frontmatter.)*
5. **Update the linked pages**: connect to the entities and concepts involved (markdown links **relative to the file**, no leading slash, see Spec §3, a condition for the Obsidian graph). One source often touches several.
6. **Flag contradictions**: if the source contradicts an existing fact, **don't overwrite it** — tell the user, and where appropriate set `superseded_by:` / `status:` on the old page.
7. **Add to `log.md`**: `## [YYYY-MM-DD] ingest | <source title>` + one line.

## Guardrails
- One source at a time, supervised. **Don't invent** a fact the source doesn't contain.
- Record the origin in `resource:`.
- Success condition: the concept page exists, `index.md` and `log.md` are up to date, **no contradiction left silent**.
- Internal skill: publish nothing, send nothing.
