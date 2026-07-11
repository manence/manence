# CLAUDE.md — Lumo knowledge base (example)

The **schema** (the wiki method's third layer) for this small, fictional knowledge base. It's a minimal demonstration, not a full layer (no `production/`, no skills here — see `../templates/` for a complete project).

## This KB's conventions
- **OKF**: every page carries a mandatory `type:` in its frontmatter (`reference`, `competitor`) plus `title`/`description`/`tags`/`timestamp`. `index.md` and `log.md` follow the OKF reserved-file rules.
- **File-relative links** between pages (`../competitors/rival-x.md`), never a leading slash.
- **Ingestion**: every new source lands in `sources/` (immutable), then goes through `kb-ingest` (the wiki method), which writes and links the wiki's pages and records the event in `log.md`.
- **`index.md`** keeps the folder's map current (one link and one line per page); **`log.md`** records every ingestion and decision, append-only.
- **Freshness**: a fact that changes gains a `valid_from` rather than overwriting its history (see `pricing.md`).
- **Status**: the `status:` field (`proposal → validated → canon`) marks a page's validation cycle (see `positioning.md`).

## On startup
Read `knowledge-base/index.md`, then the top of `knowledge-base/log.md`.
