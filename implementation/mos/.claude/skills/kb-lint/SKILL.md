---
name: kb-lint
description: A hygiene audit of the knowledge base — looks for contradictions, stale claims, orphan pages, concepts cited without a page, missing cross-references, and data gaps. Run it periodically to keep the wiki healthy as it grows.
---

# kb-lint, auditing the knowledge base

## Purpose
To keep the wiki healthy as it grows. It produces a list of fixes **and** of new questions to dig into. (This is the *checker* from law L4, separate from whoever wrote the pages.)

## Procedure
Walk through `knowledge-base/` and flag, following the Karpathy method:
1. **Contradictions** between pages (same facts, diverging values).
2. **Stale claims**, superseded by more recent sources (cross-check `timestamp` and `superseded_by`).
3. **Orphan pages**, with no incoming link.
4. **Concepts cited without a dedicated page**, a name that recurs across several pages but has none of its own.
5. **Missing cross-references**, two pages semantically linked but with no link between them.
6. **Data gaps**, open questions a web search could fill.
7. **OKF / L2 compliance**, a missing `type:`, an `index.md` that has drifted, duplicates (one fact in two places). Exception: `type: research` pages (source records) are **excluded** from the duplicate check — their overlap with the Manifesto and the framework's concepts is expected.
8. **Broken / ungraphable links**, a target that doesn't exist, or a link with a **leading slash** (`/folder/page.md`) that the Obsidian graph doesn't trace — flag it to be put back to relative-to-file.
9. **Valid frontmatter + typography**: every page (except `index.md` / `log.md`) has a **parseable** YAML frontmatter — the classic trap: an unquoted `:` in `title` / `description` (e.g. "Product: the pitch") breaks the YAML, and the value has to be quoted; and **no em dash `—`** in the frontmatter (use a comma / colon / parentheses; the en dash `–` for ranges stays allowed).

## Output
A markdown report, by category: the list of files + the proposed action. **Fix nothing automatically** — propose, and the user approves.

## Guardrails
- Read-only by default; every fix goes through approval.
- A visual aid is available: the **Obsidian graph** (isolated nodes = orphans).
- If the wiki is large: sample by folder **and say so** (no silent cap).
