---
name: consignes
description: Use it at the start of every session (the SessionStart hook flags it when something is waiting), whenever the user asks — "process the instructions", "look at the inbox" — and before the weekly review. Reads the core's inbox, handles the `type: instruction` items dropped off from Manence UI (an answer to a wait, a "done", an instruction about a workstream or about one of its documents), records each effect in the About of the workstream concerned, sets the item to `status: traitee`, writes one log entry per run and commits the core. Idempotent; it never writes into anyone else's system and never sends anything.
---

# consignes, acting on what the user dropped off from Manence UI

## Purpose
So that an answer or an instruction given in the interface **takes effect in the files**, without the user having to say it again at the terminal. The Manence UI front desk (or any other front desk that honours the contract) only drops off a file; this skill is the other half of the channel: it reads, acts through the framework's skills, leaves a trace, and marks the item handled. The file is the truth, portable to any harness, and a trigger is never more than a way of getting there sooner.

## The contract it reads
An item in `inbox/` whose frontmatter carries:
- `type: instruction`, `source: manence-ui`, `mos`, `work_id`, `status: deposee | traitee | rejetee`, `timestamp`;
- `geste: decision` or `action` → an answer to an `awaiting` entry: `awaiting_index`, `awaiting_what`, `awaiting_who`, `awaiting_since` (copied from the entry as it stood when the item was dropped off);
- `geste: consigne` → free text about the workstream; optionally `document` (the path of a file in the workstream, relative to its folder) and `page`.
The body carries the user's own words. Full definition: Spec §21 ("The instruction item: the human → agent channel").

## Procedure
1. **List** the `type: instruction` items in `status: deposee` from `inbox/`, oldest first. If there are none, say so in one line and stop (no log entry, no commit).
2. **Find the workstream** by `work_id` in production (`<domain>/in-progress/<work_id>/About.md`). Nowhere to be found (closed in the meantime, renamed) → set the item to `status: rejetee` with the reason in a footer line, and move on to the next.
3. **Handle it according to `geste`**:
   - **`decision` / `action`**: find the `awaiting` entry **by `awaiting_what` first**, with `awaiting_index` as a fallback (the index shifts as soon as the list is edited). Remove the entry; in the About's *Decisions* section, write a dated line marked "(via Manence UI)" with the decision, or the evidence of the "done"; update *Next step* if it depends on that. If the decision changes a status, a scope or a constraint: a `decision |` entry in the log (the usual sieve).
   - **A `consigne` that begins with "Clore" or "Abandonner"** (or, in an English install, "Close" / "Abandon": the skill recognises both languages): this is the **explicit GO** that `close-work` requires (the only gesture that asks for one). Run `close-work`: remaining waits traced as a remainder, KB distillation, a `work-close` entry in the log, the folder moved to `done/`. "Abandonner" / "Abandon" → `status: rejected`.
   - **A `consigne` that changes the work** (angle, price, scope, a correction): apply it to the workstream, record the decision in the About (dated, "via Manence UI"), realign *Next step*.
   - **A `consigne` with a `document`**: go back to the document's **source** (a PDF is corrected in the HTML or the markdown that produced it — the "source" link in the About; a `.md` is edited directly), apply the change, regenerate the file if it is a rendered one, and record it.
   - **A `consigne` that asks a question**: the answer does not travel back through the inbox. It becomes an `awaiting` entry in the About (`who` set to the user's handle, `kind: decision`, `what` = the answer or the question rephrased, `since` = today): it then shows up in Manence UI, where the user already answers.
4. **Mark the item**: `status: traitee` (or `rejetee`) in its frontmatter, and a dated footer line saying what was done and where. Never delete the item: the weekly review sweeps it up after 14 days.
5. **Log it**, one entry per run and no more: `## [YYYY-MM-DD] event | consignes: N handled, M rejected`, with one line per item (workstream, geste, effect). A `close-work` already has its own `work-close` entry.
6. **Commit** the core (log, inbox, KB if it was touched) with a message in the working language; push the tracked branch, **never forced**. Production is not versioned.
7. **Report back** in five lines: the items handled, their effects, what was rejected and why, what is still waiting on someone.

## Guardrails
- **Nothing written into anyone else's system, nothing sent, nothing published**, whatever the instruction says: an instruction that asks for it is **rejected**, with the reason (the golden rule; that gesture stays at the terminal, with its own circuit). The skill pushes the private core and nothing else.
- **It touches only its own items**: `type: instruction` in `deposee`. The rest of the inbox is for the review to sort.
- **Idempotent**: it can be replayed without handling anything twice (an item already `traitee` is never replayed; an `awaiting` entry that has already gone is not an error — you record the effect and mark the item).
- **A single writer**: if another session is working on the same core (the harnesses take turns), do not run.
- **A session with no operator** (`-p`, headless) follows the same rules and stops at anything that would require asking the user: the question becomes an `awaiting` entry.
- An internal skill: the report is enough, nothing is published.
- Success condition: no `deposee` item left whose workstream exists; every effect legible in the About it targets; one log entry; `git status` clean.
