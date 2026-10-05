---
name: close-work
description: Use it when a deliverable is finished and approved, when a workstream is being abandoned, or to regularize a production folder born without an About.md. Closes the workstream — moved under the same name to <domain>/done/, durable facts distilled into the knowledge base, a wrap-up in the log — and is the sole guarantor of durability, since production artifacts are disposable.
---

# close-work, closing a workstream

## Purpose
So that a finished workstream compounds instead of just stopping: production is disposable, and whatever isn't distilled here into the KB and the log is lost (L8). The closing contract is Spec §16; this skill is its procedure.

## Procedure
1. **The user's GO**: is the deliverable finished and approved? Without the user's explicit word — finished and approved, or abandoned (variant in step 7) — there is no close: the workstream stays open.
2. **Remaining waits**: if `awaiting` isn't empty, list what remains (who, what, since when) and ask whether to close anyway. Yes: the remainder goes into the `work-close` entry as a traced renunciation or deferral, then the list is emptied. No: stop there. The skill asks, it doesn't refuse (Spec §16).
3. **Move** the folder from `<domain>/in-progress/` to `<domain>/done/` under **the same name**: renaming would break incoming links. The root is resolved to an absolute path (Spec §18).
   **Then repair the links the move broke**: a move between `in-progress/` and `done/` keeps the depth, so only two kinds break: the relative links elsewhere in production that pointed into `<domain>/in-progress/<slug>/` (search the production root for the slug), and the folder's own links to sibling workstreams still in `in-progress/` (`../<other>/…`). Rewrite the path and nothing else; the same goes for a `resource:` pointer in the knowledge base that names the old place. A link inside a closed folder is repaired too: fixing a link a move broke is not a rewrite (Spec §16). Before this step, one close broke two such links, one of them inside a closed folder (2026-09-28).
4. **Set the status** in `About.md`: `status: validated`, or `canon` if the deliverable becomes a reusable reference; `timestamp:` set to today.
5. **Distill**: every durable fact (a price, a positioning, a result) goes to the `knowledge-base/` via `kb-ingest`, with the closed workstream as its `resource:`, a pointer under the production root (Spec §18).
6. **Schedule the measure**: every external action in the workstream (a campaign gone live, content published, a send) gets its measurement date and the ritual that will observe it, as a dated line in `inbox/` or in the target periodic report, not in the closed folder: the workstream closes, the measure lives on.
7. **Trace it**: `## [YYYY-MM-DD] work-close | <domain>/<slug>`, at the top of `log.md`, under its H1 (Spec §4): what was delivered, what you learned, the pointer to the closed folder. *Abandonment variant*: `status: rejected`, the folder still goes to `done/` under the same name, and the entry gives the reason for abandoning.

## Retroactive record (a badly born workstream)
A work folder found in production without an `About.md`: write its `About.md` from `templates/workstream/About.template.md` (goal reconstructed, context linked, `status:` true to the real state) and a `work-open` entry dated today that records the regularization. The workstream then follows the normal cycle.

## Done
- Success condition: nothing left under `in-progress/` for this workstream; `lint.sh` from the production root reports no broken link naming its slug, and no `resource:` in `knowledge-base/` names `in-progress/<slug>`; `About.md` set; `awaiting` empty or its remainder in the log; the KB carries the new facts; every external action has its measurement date and its observer.
- Reading criterion: the `work-close` entry, read on its own without opening the folder, says what was delivered and what was learned.
- Trace: the `work-close` entry in the log and the distilled KB pages.
