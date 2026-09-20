---
name: checkpoint
description: Use it when the user says they are about to wipe the context — "I'm going to clear", "let's close the session" — and on your own initiative when the session has produced a lot and the context is getting heavy. Prepares the handover, in order: every thread still open goes to the inbox with its state and the decisions it awaits, the log is brought up to date, the agent memory too if the harness keeps one, the workstreams are ruled on, everything versioned is committed and pushed, the environment is left as it was found, pending external actions are listed without being played, and a five-line report says where to pick up.
---

# checkpoint, the handover before a clear

## Purpose
So that a session can stop at any moment without losing anything: the next one reads the inbox, the log and the memory, and picks up where this one left off without the user having to explain it all again. The skill invents nothing: when there is nothing to write on a point, it says so and moves on.

What it is not: a weekly review (`weekly-review`), nor the closing of a workstream (`close-work`). It calls them when a workstream is delivered and approved; it does not replace them.

## Procedure, in order

1. **Open threads go to the inbox.** For every subject still alive in the session, one item `inbox/YYYY-MM-DD-<slug>.md` (frontmatter `type: inbox`, `title`, `timestamp`) with three paragraphs: **where it stands**, **what is needed from the user** (the decisions awaited, numbered), **the next concrete action** (with its paths). A thread an existing item already covers: update that item rather than open a second one. Items the session has made moot go to the trash (`trash`). This is the centerpiece: the next session starts with the inbox.
2. **The log is complete.** Reread the session: every decision the user made, every delivery, every incident or lesson has its `## [YYYY-MM-DD] type | title` entry in `log.md`. Whatever was said in conversation and never traced gets written now. Append-only, never a rewrite.
3. **The memory is up to date.** If the harness keeps an agent memory — it is the harness that gives the path, and not all of them have one: without it, move on — write into it the state of ongoing work that is recorded nowhere else, the user's corrections and confirmations about the way to work, and the index that lists them. Check first whether an existing entry covers the subject; update rather than duplicate; remove what has become false. Recopy nothing the repository, the log or the knowledge base already carries.
4. **The workstreams are sound.** Every folder created in production has its `About.md` (if not: write it, retroactively). A workstream delivered and approved goes through `close-work`. One that stays open has its next step up to date, and its `awaiting` says what is waiting on someone.
5. **Nothing is left hanging in git.** The core (`log.md`, `inbox/`, the skills), the knowledge base, every connected repository: `git status` on each, commit with a message in the working language, push the tracked branch. The core's guardrails hold here as anywhere else: what they refuse is not worked around, it is reported. Absolute paths in every git command. The hashes go into the report.
6. **The environment is left as it was found.** Background agents: finished, or explicitly left running (say which). Servers the session started: stopped; the user's own: untouched. Repositories put back on the branch they were on. Temporary files: in the scratchpad, not in the repositories.
7. **Pending external actions are listed, never played.** Anything waiting on a GO (a purge, a merge, a send, a write into a live system) is named in the matching inbox item, marked "waiting for a GO". The next session must not be able to mistake it for something already decided.
8. **The report, five lines, the last message before the clear**: where to pick up (the inbox item to read first), what is waiting on the user, what is pushed (repositories and hashes), what is still running, and what was deliberately left aside.

## Trigger
- The user says "I'm going to clear", "clear the session", "if you have things to write down, do it now".
- On my own initiative, when the session has delivered several things and the context is getting heavy: offer the checkpoint rather than wait until it is too late.

## Guardrails
- No external action and no write into a live system (a CRM, an ad platform, a site in production) during a checkpoint: you tidy up, you trace, you push what is versioned, and that is all.
- One inbox item per real thread; no item to say that there is nothing.
- Success condition: `git status` clean on every repository touched, every open thread has its inbox item, the log covers the session, the memory contradicts nothing that was decided, and the report fits in five lines.
