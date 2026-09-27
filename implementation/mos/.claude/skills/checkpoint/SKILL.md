---
name: checkpoint
description: Use it when the user says they are about to wipe the context — "I'm going to clear", "let's close the session" — and on the agent's own initiative when the session has produced a lot and the context is getting heavy. Prepares the handover: every open thread filed in the inbox, log, memory and workstreams brought up to date, everything versioned committed and pushed, the environment left as found, and a report that says where to pick up; no external action is played.
---

# checkpoint, the handover before a clear

## Purpose
So that a session can stop at any moment without losing anything: the next one reads the inbox, the log and the memory, and picks up without the user having to explain it all again. When there is nothing to write on a point, the skill says so and moves on. It is neither a review (`weekly-review`) nor a close (`close-work`); it calls the latter when a workstream is delivered and approved.

## Procedure
1. **Open threads go to the inbox**: for every subject still alive, one item `inbox/YYYY-MM-DD-<slug>.md` (frontmatter `type: inbox`, `title`, `timestamp`) that says where it stands, what is needed from the user (the decisions awaited, numbered), and the next concrete action, paths included. A thread already covered: update the existing item. The next session starts with the inbox.
2. **The log gets what the sieve keeps** (Spec §11): whatever in the session changed a status, a scope or a constraint, or whose loss would force the work to be redone, and has no entry yet (format: `AGENTS.md` "Conventions").
3. **The agent memory, if the harness keeps one** (the harness gives the path; without one, move on): the state of ongoing work recorded nowhere else, the user's corrections and confirmations about the way to work, the index that lists them. Update rather than duplicate, remove what has become false; what the repository, the log or the KB already carries gets linked (`AGENTS.md` "Conventions").
4. **The workstreams keep their contract** (Spec §16): one `About.md` per production folder, next step and `awaiting` up to date; a workstream delivered and approved goes through `close-work`.
5. **Nothing left hanging in git**: `git status` on the core, the KB and every connected repository touched; commit everywhere; **push only where a push publishes nothing** (the core, a private repository without deployment). Any other push is an external action (step 7). Note the hashes. What the guard refuses is not worked around: you report it.
6. **The environment left as found**: background agents finished or declared still running; servers the session started stopped, the user's own untouched; repositories back on their branch.
7. **External actions wait**: during a checkpoint, nothing is sent, published or written into a live system (`AGENTS.md` "Security, hard vs soft"). Anything waiting on a GO is named in its inbox item, marked "waiting for a GO", so the next session can't mistake it for something decided.
8. **The report, the last message before the clear**: the inbox item to read first, what is waiting on the user, what is pushed (repositories and hashes), what is still running, what was deliberately left aside.

## Done
- Success condition: `git status` clean on every repository touched; every open thread has its inbox item; no external action was played.
- Reading criterion: a fresh context that reads only the inbox item named in the report can state the first action to take, without the conversation.
- Trace: the inbox items, the log entries, the commits whose hashes the report gives.
