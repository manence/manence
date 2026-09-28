---
name: outward-watch
description: Use it about once a week, ahead of the weekly-review that consumes it — by hand or as a scheduled routine — and whenever the user asks what is moving outside. Looks outward at the substrate (Anthropic, Claude Code, agentic practice; the same for every MOS) and at the trade (a slot each installation fills for itself), puts every finding through a single filter, "what does this change for this MOS, or for the framework?", writes a dated report into knowledge-base/watch/ (a time series), and routes the candidate actions to inbox/.
---

# outward-watch, the organ that looks outward

## Purpose
Every other organ of a MOS looks inward, and the substrate it runs on changes faster than it does. This skill is the eye that faces out, and it reports only what changes something here (Spec §20).

## Two things to watch

**The substrate** — the same for every MOS: Anthropic and Claude Code (releases, changelog, announcements, **the blog included**, not just the documentation: blind recall test of 2026-08-30, target missed on the blog) and the practice around them (context engineering, memory, multi-agent patterns, tooling).

**The trade** — a slot, one per MOS, empty on delivery: the competitors and adjacent players, the public mentions that matter, the sources that count. Fill it once and it holds:

> **This MOS's trade watch** — *empty until filled*
> `<what to track · which KB pages serve as the baseline · what counts as a signal>`

The slot lives in a file of the MOS, never in this skill (an installed copy is replaced at every upgrade): a knowledge-base page the MOS names, for instance `knowledge-base/watch/scope.md`, which also names the folder the reports go to (default `knowledge-base/watch/`), pointed to from the `outward-watch` line of `AGENTS.md` Skills. If that file is missing or empty when the skill runs, ask the user for it and create it before collecting anything. A trade watch the assistant invented for itself is noise.

## Procedure
1. **The delta first.** Read `STRATEGY.md`, the most recent report in the MOS's watch folder (named in the scope page; default `knowledge-base/watch/`), and the top of `log.md`. The last report's date **bounds this one's window** (first run: a window you choose and declare at the top of the report). Nothing already seen, and nothing already set aside, gets raised a second time — that is what the previous report's "seen, no effect" section is for (drift check D2).
2. **Collect**, read-only. When the collection is handed to research subagents, each one gets its role (substrate, or trade along with the slot), the window, and the rule that it writes nothing; each returns sourced, dated findings. With no network access at all, write "not done" and stop: a watch that fills its gaps from memory is worse than no watch. One blocked domain among others is a different case:
   - **A blocked domain gets a declared fallback.** A primary source you cannot reach (the egress proxy of a scheduled routine, a scraper that fails, a paywall) is never skipped, and owning up to it at the top of the report is not enough: the blind recall test of 2026-08-30 missed its target because the substrate's blog was blocked and merely owned up to. You read it by a fallback path: search-engine excerpts (title, date, salient points), or handing the source to a session that can reach it. The finding carries "read degraded, to be confirmed", and the report's reliability section lists the blocked domains **and**, for each, the path used.
   - **A number is read at its source, or marked unverified.** Stars, followers, downloads, rankings: when a public API gives both the number and the list behind it (on GitHub, the dated list of stargazers), that is what speaks, never conjecture; on 2026-08-30, a star movement a report had left as a "mystery" could be read in a single call. With no call available, the number enters the report marked **unverified**: an order of magnitude presented as a fact corrupts a time series.
3. **Filter.** Every finding goes through one question: **what does this change for this MOS, or for the framework?** An empty answer earns one line under "seen, no effect" and is never raised again. The rest is ranked:
   - **P0** — it breaks something here, or the window to act on it is short;
   - **P1** — fold it into the next workstream that touches the area;
   - **P2** — worth watching, nothing to do.
4. **The report.** `<watch folder>/YYYY-MM-DD.md` (OKF, `type: report`; the folder is the one the scope page names, default `knowledge-base/watch/`), listed in that folder's `index.md` — create the folder and its index on the first run. At the top, the actual window and the reliability section; then three sections: substrate, trade, seen-no-effect. Each finding keeps the **fact** (what shipped, sourced and dated) apart from the **reading** (what it changes here): the fact still holds its value on the day the reading turns out wrong.
5. **Candidate actions.** The P0s and P1s that call for something go into one dated item, `inbox/YYYY-MM-DD-watch-actions.md`, as candidates for `open-work` or `kb-ingest`. The watch proposes, the weekly-review sorts, the user decides.
6. **The log.** Nothing by default: a routine report changes no status and no constraint. A confirmed P0 earns its entry.

## Checking the organ: the blind recall test

A watch that reports nothing is indistinguishable from a watch that sees nothing. The test that separates the two is played once a quarter, or after any change in how the watch runs — a new routine, a new harness, a new egress network.

1. **Plant the target.** A human picks a real publication from the current window, objectively major for this MOS, and leaves it untouched: nothing about it enters the log, the knowledge base or the inbox before the run.
2. **Let it run.** The watch runs normally, knowing nothing of the test.
3. **Read the verdict from the report alone.** The target is in it, or it is not. Absent, that is a **missed recall**, and it qualifies itself: *an access failure* (the source was out of reach) or *a filter failure* (it was read, then set aside). The first is repaired in the fallback path, the second in the filter.
4. **Clear and trace.** The target is then handled normally, and the verdict goes to the log as a dated entry: it is the only reliability figure this organ will ever produce.

The test proves a gap, never completeness.

## Guardrails
- **Read-only, outward**: nothing published, no third-party account touched, no workstream opened (`AGENTS.md` "Security, hard vs soft"; Spec §20).
- The cadence is declared in `.claude/mos.json` (routines), not here.
- **A short report is the point.** The filter exists to discard. A report that lists everything has filtered nothing.

## Done
- Success condition: a dated report in the MOS's watch folder, listed in its index, that declares its window and its reliability (or "not done"); the `watch-actions` item if there are P0s or P1s.
- Reading gate: the blind recall test, above.
- Trace: the report and the inbox item; the log only for a confirmed P0 or the test's verdict.
