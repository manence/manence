---
name: kb-ingest
description: Use it whenever an outside source has to become knowledge — an article, a PDF, a transcript, a web page, raw notes, or something the user simply pastes in. Produces one concept page integrated into the knowledge base following the wiki method (Karpathy): the index and the linked pages brought up to date, contradictions with what is already there flagged.
---

# kb-ingest, integrating a source

## Purpose
To turn a raw source into **integrated knowledge**, without piling up duplicates. Law L7: *to ingest is to integrate*, not to drop off.

## Input
A source: a file (often in `inbox/`), a URL, or whatever the user provides.

## Procedure
1. **Choose what to keep with the user**, and wait for their agreement before you write: you don't keep everything (law L1: high signal), and what matters to this MOS is something they know.
2. **Write or update the concept page** in `knowledge-base/`, following the file contract (Spec §1, `AGENTS.md` "Conventions"; template `templates/concept.template.md`), with the source in `resource:`.
3. **Update `knowledge-base/index.md`**: the page's line (a link + one sentence).
4. **Update the linked pages**: connect to the entities and concepts involved; one source often touches several.
5. **Contradictions**: if the source contradicts an existing fact, **don't overwrite it**; tell the user, and where appropriate set `superseded_by:` / `status:` on the old page (Spec §6).
6. **Log**: `## [YYYY-MM-DD] ingest | <source title>` if the ingestion passes the sieve (Spec §11), for instance when it invalidates an established fact.

## Done
- Success condition: the concept page exists with its `resource:`, `index.md` lists it, `lint.sh` is clean on the files touched, **no contradiction left silent**.
- Reading criterion: a fresh context reads the page without the source and understands it; every fact it states can be found in the source.
- Trace: the concept page and its `index.md` line; the `ingest |` entry when the sieve keeps it.
