---
name: close-work
description: Use it when a deliverable is finished and approved, when a workstream is being abandoned, or to regularize a badly born workstream (a production folder with no About.md). Closes it by moving it, name unchanged, from <domain>/in-progress/ to <domain>/done/, with mandatory distillation — durable facts to the knowledge base, a wrap-up in the log: production artifacts are disposable, and this skill is the sole guarantor of durability.
---

# close-work, closing a workstream

## Purpose
So that a finished workstream **compounds** instead of just stopping. Production is outside git and **disposable by doctrine**: whatever isn't distilled here (KB + log) is considered lost. Distillation is therefore not optional, it is the heart of the skill (double value, L8).

## Procedure
1. **Check** with the user: is the deliverable finished and approved (explicit GO)? If not, two ways out: the workstream stays open, or it is **abandoned** (go to step 7, abandonment variant).
2. **Settle the remaining waits**: read `awaiting` in `About.md`. If the list isn't empty, **list the remaining items** (who, what, since when) and ask: *"this is still unsettled: … — close anyway?"*. On **yes**, carry them into the `work-close` log entry (step 7) as a traced renunciation or deferral, then empty the list. On **no**, the workstream stays open and the close stops here. The skill asks, it never refuses.
3. **Close it**: move `<domain>/in-progress/YYYYMMDD-<slug>/` to `<domain>/done/YYYYMMDD-<slug>/` — **the same name, a pure move** (the date prefix was set at opening; renaming here would break every incoming link). The production root is `$<PROJECT>_PRODUCTION_ROOT` (default `../production/`), resolved to an absolute path, never guessed (Spec §18).
4. **Set the status**: in `About.md`, change `status:` to `validated` (or `canon` if the deliverable becomes a reusable reference) and update `timestamp:`.
5. **Distill (mandatory)**: the workstream's durable facts (a price, a positioning, a campaign result) go to the `knowledge-base/` via `kb-ingest`; the closed workstream becomes the page's `resource:` (a **pointer** under the production root, not a relative link: production can move). You **never** leave a fact living only in a disposable artifact.
6. **Schedule the measure**: every **external action** in the workstream (a campaign gone live, content published, a send) records **its measurement date** (e.g. day +7) and **who will observe it** (which ritual: `weekly-review`, a monthly review…). The measure belongs to the ritual, not the workstream: the workstream closes, the measure lives on in the system. In practice: a dated line in `inbox/` or in the target periodic report, not a note in the closed folder.
7. **Trace it**: an entry `## [YYYY-MM-DD] work-close | <domain>/<slug>` in the core's `log.md` with a 2-3 line wrap-up: what was delivered, **what you learned** (what worked, what chafed), and the pointer to the closed folder. *Abandonment variant*: `status: rejected` in `About.md`, the folder still goes to `done/`, name unchanged (the trace of a reasoned retreat is worth its weight in gold), a `work-close` entry with the reason for the abandonment.

## Retroactive record (fixing a badly born workstream)
A work folder found in production **without** an `About.md` (well routed, badly born): create its `About.md` from the template, retroactively (goal reconstructed, context linked, `status:` reflecting the real state), and a `work-open` entry dated today in the log noting the regularization. The workstream then follows the normal cycle.

## Guardrails
- Never close without an explicit GO from the user.
- Rewrite nothing in already-closed workstreams (they are dated, they are part of the history).
- If the workstream calls for a follow-up (iterate, relaunch), note it: either a new item in `inbox/`, or `open-work` directly.
- Success condition: nothing left in `in-progress/` for this workstream, `About.md` set, `awaiting` empty or its remainder traced in the log, KB up to date if there are new facts, every external action has its measurement date and its observer, a log entry with the wrap-up.
