# Example: a minimal knowledge base

A "hello world" mini-project that shows **layer 2 (Knowledge)** at work, following OKF and the wiki method. Fictional domain: **Lumo**, an imaginary SaaS.

What it demonstrates:
- immutable `sources/` → `knowledge-base/` (the wiki the LLM maintains).
- **One concept = one file**, with OKF frontmatter (`type`, `title`, `description`, `resource`, `tags`, `timestamp`).
- **File-relative** markdown links between concepts (this is what the Obsidian graph draws).
- `index.md` = a listing **with no frontmatter** (an OKF reserved name).
- `log.md` = a dated, append-only journal (`ingest` and `decision` entries).
- **Freshness**: `valid_from`, and a fact updated without overwriting its history (Pro €19 → €29).
- **Types**: `reference` (product) and `competitor`.
- **Status**: `status: canon` on `positioning.md`, a page's validation cycle.
- `CLAUDE.md`, the **schema** (the wiki method's third layer): the conventions specific to this KB.

To use it: copy the tree, empty out the content, and run `kb-ingest` on your first source.
