---
name: kb-lint
description: Use it when the knowledge base calls for an audit rather than an edit: periodically as it grows, before a release or a handover, when the weekly review reports that the KB has moved, or when a contradiction is suspected. Produces a dated report of proposals (contradictions, stale claims, orphans, concepts without a page, missing cross-references, data gaps, pruning); it repairs nothing.
---

# kb-lint, auditing the knowledge base

## Purpose
To keep the wiki healthy as it grows: a list of fixes **and** of new questions to dig into. This is the *checker* from law L4: if the session itself wrote pages of the KB, the audit runs in a fresh context (a subagent given the scope, the commit under audit, and the right to write its report and nothing else).

## Procedure
First run `.claude/hooks/lint.sh knowledge-base/` and take its findings as they are (links, frontmatter, `type:`, dated `review_when:` that have come due) rather than redoing them by hand. Then walk through `knowledge-base/` and flag, following the Karpathy method:
1. **Contradictions** between pages (same facts, diverging values).
2. **Stale claims**, superseded by more recent sources (cross-check `timestamp` and `superseded_by`); and any `review_when:` whose trigger **event** has occurred: the page stops being authoritative on its own, so propose reconfirming or updating it (Spec §6).
3. **Orphan pages**, with no incoming link.
4. **Concepts cited without a dedicated page**, a name that recurs across several pages but has none of its own.
5. **Missing cross-references**, two pages semantically linked but with no link between them.
6. **Data gaps**, open questions a search could fill.
7. **L2**: an `index.md` that has drifted, duplicates (one fact in two places; `type: research` pages are excluded, Spec §8).
8. **Pruning**: the redo test (Spec §8), as a proposal only.

If the wiki is large: sample by folder **and say so** (no silent cap).

## Done
- Success condition: a dated report exists, `inbox/YYYY-MM-DD-kb-lint.md` (or the synthesis of the `weekly-review` that called it); it names the commit it audited (Spec §11), groups its findings by category, and each finding cites its file with the proposed action; `git status knowledge-base/` shows no change.
- Reading criterion: every contradiction is cited with both sentences and their files.
- Stop: no fix without the user's agreement.
