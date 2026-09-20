---
name: outward-watch
description: Use it about once a week, ahead of the weekly-review that consumes it — by hand or as a scheduled routine — and whenever the user asks what is moving outside. Looks outward at the substrate (Anthropic, Claude Code, agentic practice; the same for every MOS) and at the trade (a slot each installation fills for itself), puts every finding through a single filter, "what does this change for this MOS, or for the framework?", writes a dated report into knowledge-base/watch/ (a time series), and routes the candidate actions to inbox/.
---

# outward-watch, the organ that looks outward

## Purpose
Every other organ of a MOS looks inward. The log, the knowledge base, distillation, the review — all of them capitalize on work already done. None of them discovers anything from outside, and the substrate a MOS runs on changes faster than the MOS does. This skill is the eye that faces out, and it reports only what changes something here.

## Two things to watch

**The substrate** — generic, identical for every MOS. What the system runs on: Anthropic and Claude Code (releases, changelog, announcements, new capabilities) and the wider practice around them (context engineering, memory, multi-agent patterns, tooling worth knowing about). The framework ships this half finished; only the filter is local.

**The trade** — a slot, one per MOS, empty on delivery. The field the activity actually works in: the competitors and adjacent players, the public mentions that matter, the sources that count. Fill it once and it holds:

> **This MOS's trade watch** — *empty until filled*
> `<what to track · which KB pages serve as the baseline · what counts as a signal>`

If the slot is still empty when the skill runs, ask the user for it and write the answer into this file before collecting anything. A trade watch the assistant invented for itself is noise.

## Procedure
1. **The delta first.** Read `STRATEGY.md`, the most recent report in `knowledge-base/watch/`, and the top of `log.md`. The last report's date **bounds this one's window** (first run: about six weeks back). Nothing already seen, and nothing already set aside, gets raised a second time — that is what the previous report's "seen, no effect" section is for (drift check D2).
2. **Collect** — parallel research subagents, read-only: the substrate on one side, the trade slot on the other. Without network, write "not done" and stop there; a watch that fills its gaps from memory is worse than no watch. Two rules keep the collection honest:
   - **A blocked domain gets a declared fallback.** A primary source you cannot reach — the egress proxy of a scheduled routine, a scraper that fails, a paywall — is never skipped in silence, and owning up to it at the top of the report is not enough: the admission leaves the hole exactly where it was. You read it by a fallback path, and there is always one: search-engine excerpts (title, date, salient points), or handing the source to a session that can reach it. The finding then carries the note "read degraded, to be confirmed", and the report's reliability section lists the blocked domains **and**, for each, the path used.
   - **A number is read at its source, or marked unverified.** Stars, followers, downloads, rankings: when a public API gives both the number and the list behind it, that is what speaks, and a movement is explained by what it returns — never by conjecture. With no call available, the number enters the report marked **unverified**. An order of magnitude presented as a fact is the cheapest way to corrupt a time series.
3. **Filter.** Every finding goes through one question: **what does this change for this MOS, or for the framework?** An empty answer earns one line under "seen, no effect" and is never raised again. The rest is ranked:
   - **P0** — it breaks something here, or the window to act on it is short;
   - **P1** — fold it into the next workstream that touches the area;
   - **P2** — worth watching, nothing to do.
4. **The report.** `knowledge-base/watch/YYYY-MM-DD.md` (OKF, `type: report`), listed in `knowledge-base/watch/index.md` — create the folder and its index on the first run. Three sections: substrate, trade, seen-no-effect. Each finding keeps the **fact** (what shipped, sourced and dated) apart from the **reading** (what it changes here): the fact still holds its value on the day the reading turns out wrong. A time series is consolidated knowledge, which is why the report lives in the knowledge base and not in a workstream (routing table).
5. **Candidate actions.** The P0s and P1s that call for something go into one dated item, `inbox/YYYY-MM-DD-watch-actions.md`, as candidates for `open-work` or `kb-ingest`. The watch proposes, the weekly-review sorts, the user decides.
6. **The log.** Nothing by default: a routine report changes no status and no constraint, so the sieve keeps it out. A confirmed P0 is the exception and earns its entry.

## Checking the organ: the blind recall test

A watch that reports nothing is indistinguishable from a watch that sees nothing. The test that separates the two takes four gestures, and is played once a quarter, or after any change in how the watch runs — a new routine, a new harness, a new egress network.

1. **Plant the target.** A human picks a real publication from the current window, objectively major for this MOS, and leaves it untouched: nothing about it enters the log, the knowledge base or the inbox before the run.
2. **Let it run.** The watch runs normally, knowing nothing of the test.
3. **Read the verdict from the report alone.** The target is in it, or it is not. Absent, that is a **missed recall**, and it qualifies itself: *an access failure* (the source was out of reach) or *a filter failure* (it was read, then set aside). Both are repairable, but not in the same place — the first in the fallback path, the second in the filter.
4. **Clear and trace.** The target is then handled normally, and the verdict goes to the log as a dated entry: it is the only reliability figure this organ will ever produce.

The test reads in one direction only: it proves a gap, never completeness. A target found does not say the watch sees everything; a target missed says it is blind somewhere, and where.

## Guardrails
- **Read-only, outward.** The watch queries; it writes nowhere but here. Nothing published, no workstream opened, no third-party account touched.
- The cadence follows the user's rhythm, not the world's: everything arrives fresh on the day they sit down, and nothing piles up overnight.
- **A short report is the point.** The filter exists to discard. A report that lists everything has filtered nothing.
- In a constellation, several MOS watch the same substrate and do the work twice. Redundant, not wrong — each one reads it through its own filter. Sharing a single report across installations is the operator's call, not a rule of the framework.
