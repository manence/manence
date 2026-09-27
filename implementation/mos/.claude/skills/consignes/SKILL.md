---
name: consignes
description: Use it at session start when `inbox/` holds `type: instruction` items in `status: deposee` (the SessionStart hook flags them), whenever the user asks ("process the instructions"), and before the weekly review. Handles those items dropped off from Manence UI (an answer to a wait, a "done", an instruction about a workstream or about one of its documents), records each effect in the About of the workstream concerned, sets the item to `status: traitee`, writes one log entry per run and commits the core.
---

# consignes, acting on what the user dropped off from Manence UI

## Purpose
So that an answer or an instruction given in the interface **takes effect in the files**, without the user having to say it again at the terminal. The front desk only drops off a file; this skill is the other half of the channel: it reads, acts through the framework's skills, leaves a trace, and marks the item handled.

## The contract it reads
An item in `inbox/` with `type: instruction`; full definition: Spec §21. The fields that matter for sorting: `work_id`, `status: deposee | traitee | rejetee`, `geste` (`decision` and `action` carry `awaiting_what` and `awaiting_index`; a `consigne` may carry `document` and `page`). The body carries the user's own words.

## Procedure
1. **List** the `type: instruction` items in `status: deposee` from `inbox/`, oldest first. If there are none, say so in one line and stop (no log entry, no commit).
2. **Find the workstream** by `work_id` in production (`<domain>/in-progress/<work_id>/About.md`). Nowhere to be found (closed in the meantime, renamed) → set the item to `status: rejetee` with the reason in a footer line, and move on to the next.
3. **Handle it according to `geste`**:
   - **`decision` / `action`**: find the `awaiting` entry by `awaiting_what` first, with `awaiting_index` as a fallback. Remove the entry; in the About's *Decisions* section, write a dated line marked "(via Manence UI)" with the decision, or the evidence of the "done"; update *Next step* if it depends on that. If the decision changes a status, a scope or a constraint: a `decision |` entry in the log.
   - **A `consigne` that begins with "Clore" or "Abandonner"** ("Close" / "Abandon" in an English install): this is the explicit GO `close-work` requires; run it. "Abandonner" / "Abandon" → `status: rejected`.
   - **A `consigne` that changes the work** (angle, price, scope, a correction): apply it to the workstream, record the decision in the About (dated, "via Manence UI"), realign *Next step*.
   - **A `consigne` with a `document`**: go back to the document's **source** (a PDF is corrected in the HTML or the markdown that produced it — the "source" link in the About; a `.md` is edited directly), apply the change, regenerate the file if it is a rendered one, and record it.
   - **A `consigne` that asks a question**: the answer becomes an `awaiting` entry in the About (`who` set to the user's handle, `kind: decision`, `what` = the answer or the question rephrased, `since` = today), never a reply file: the return channel is the one the reader shows.
4. **Mark the item**: `status: traitee` (or `rejetee`) in its frontmatter, and a dated footer line saying what was done and where. Never delete the item: the review is what sweeps it up.
5. **Log it**: one `event |` entry per run — `## [YYYY-MM-DD] event | consignes: N handled, M rejected`, with one line per item (workstream, geste, effect). The entries other gestures owe (a `decision |` from step 3, a `work-close` from `close-work`) come in addition.
6. **Commit** the core (log, inbox, KB if it was touched) and push the tracked branch. Production is not versioned.
7. **Report back**: the items handled, their effects, what was rejected and why, what is still waiting on someone.

## Guardrails
- An instruction that asks to write into someone else's system, send or publish something is **rejected**, with the reason: that gesture stays at the terminal (`AGENTS.md` "Security, hard vs soft").
- **It touches only its own items**: `type: instruction` in `deposee`. The rest of the inbox is for the review to sort.
- **Idempotent**: an item already `traitee` is never replayed; an `awaiting` entry that has already gone is not an error — you record the effect and mark the item.
- **A single writer**: if another session is working on the same core (the harnesses take turns), do not run.
- **A session with no operator** (`-p`, headless) follows the same rules and stops at anything that would require asking the user: the question becomes an `awaiting` entry.

## Done
- Success condition: no `deposee` item left whose workstream exists; one `event |` entry for the run; `git status` clean.
- Reading gate: a fresh context reading the About alone finds every instruction handled and its effect.
- Trace: the workstream's About, the item's footer, the log, the commit.
