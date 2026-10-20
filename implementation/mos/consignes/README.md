# consignes/

The **decisions already taken, waiting for the agent to carry them out**. An instruction is not a capture: the person has decided (an answer to a wait, a "done", an instruction about a workstream or one of its documents, a GO, the fate of an inbox capture), and what is left is for the agent to produce the effect in the files. Before 0.15 these items lived in `inbox/`; the inbox now holds only what has not been decided yet (Spec §7).

## Who writes, who reads
- **Writes**: a front desk (Manence UI, or any software that honors the contract of the `type: instruction` item, Spec §21). A front desk creates a file here and nothing else; it never overwrites.
- **Reads and carries out**: the `consignes` skill, at session start (the "At the start of a session" line of `AGENTS.md`), on request, and before the weekly review. The file is the channel; a session-start hook only points at it.

## The cycle
`deposee` (written by the front desk) → `traitee` or `rejetee` (written by the agent, with a dated footer line that says what was done and where). A handled or rejected item is **moved into `traitees/`** by the `consignes` skill, in the same run. The root of this folder therefore only ever holds what waits for the agent.

## Housekeeping
The `weekly-review` trashes the items of `traitees/` older than 30 days (never `rm`): the lasting trace is elsewhere (the workstream's About, the journal, the commit).
