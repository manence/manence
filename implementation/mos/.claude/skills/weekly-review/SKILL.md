---
name: weekly-review
description: Use it once a week — by hand or as a scheduled routine — and whenever the user asks "where do we stand?", wants the state of things, or a health check of the system. Puts the core and production through a sieve (lint, inbox, workstreams and their waits, effect measures, routines, freshness of the framework and of the skills, the outward watch, drift) and produces a synthesis with proposed actions, traced in the log. It observes and proposes; it fixes nothing.
---

# weekly-review, the weekly review

## Purpose
To prevent the two drifts that kill a Manence OS: the disorder that sets in (orphans, an overflowing inbox, broken links, badly born workstreams) and the workstreams that stall without anyone noticing.

## Procedure
1. **Mechanical lint**: `.claude/hooks/lint.sh` on the repo, **then** on the production root (`$<PROJECT>_PRODUCTION_ROOT`, default `../production/`, resolved to an absolute path): that is where the workstreams' links to the KB have to resolve from (Spec §18). Report the findings.
   **Two sizes** (`wc -c log.md`, `wc -l AGENTS.md`) against the thresholds in Spec §8; what to propose when one is exceeded (rotating the log, trimming `AGENTS.md`) is described there, and is never played on its own.
2. **Orphans**: whatever lives outside the routing table in `AGENTS.md` (Spec §17; the `skills` link at the root is the bridge described in `AGENTS.md` "Skills", not an orphan). For each one, propose its destination from the table.
3. **Badly born workstreams**: any `in-progress/` folder with no `About.md` (Spec §16) → propose the retroactive record from `close-work`.
4. **Inbox**: a `type: instruction` item in `status: deposee` is not triaged, it is handled by the `consignes` skill (Spec §21; as a scheduled routine, only report it). Route every other item (a fact → `kb-ingest`, work → a candidate for `open-work`, stale → propose `trash`, keep as-is → it stays but you date it). **Time guard**: any capture older than 14 days, and any `traitee` or `rejetee` item older than 14 days, is listed for sorting or trashing; the review proposes, the user disposes; the inbox is exempt from the file contract precisely because this sweep exists.
5. **Workstreams in progress**: for each `<domain>/in-progress/`, the goal (its `About.md`), its age, its last activity; flag the ones that haven't moved in 2 weeks (move them forward, or close them with `close-work`, a deliberate abandonment included). Then the waits, as Spec §16 defines them: the `awaiting` entries older than 14 days grouped by person, and any in-progress `About.md` with no `awaiting` field.
6. **Effect measures**: the closed external actions whose measurement date has been reached (Spec §16), and any missing measurement report.
7. **KB**: a light `kb-lint` if the KB moved this week; otherwise note it as not done. The freshness of the periodic report (in the KB), and any `review_when:` whose trigger event has occurred (due dates belong to the lint, step 1).
8. **Framework freshness**: compare `.claude/manence-version` with the latest tag of the public framework repo, `git ls-remote --tags https://github.com/manence/manence.git` (a public read; nothing about the MOS is sent; without network, note "not checked this week"). If the repo is ahead: list the missed versions with their `CHANGELOG.md` notes, and propose the update (`upgrade.sh`, see `UPGRADING.md`). If `.claude/manence-version` is missing, the install predates 0.5.0: say so and propose stamping it with the version the core actually matches.
9. **Skills**: the age of each skill in git (`git log -1 --format=%cs -- .claude/skills/<name>/`); the installed copy compared with the version the framework ships (what a dry run of `upgrade.sh <core>` shows); drift in both directions (a copy that has fallen behind, a local adaptation never contributed back). A review of a skill may conclude it should be retired; the method is `skill-craft`, the weekly review only observes.
10. **Routines**: first synchronize the reference (`git fetch`, compare to `origin`: Spec §11). Then, for each routine declared in `.claude/mos.json`, find its last proof — the most recent file matching `proof_glob`, or, when a `proof_marker` is declared, the last line of that file carrying the marker, dated by the `## [YYYY-MM-DD]` heading above it — and compare its age with the cadence's period plus `grace_days` (2 unless declared): *proof received N days ago*, or *late by N days*. Never call a routine **broken**: a proof that hasn't arrived may mean it ran somewhere that commits nothing.
11. **Outward watch**: read the most recent report in the MOS's watch folder (the one its scope page names; default `knowledge-base/watch/`; the `outward-watch` skill). Missing, or older than a week? Run `outward-watch` first, or note it as not done. Then pick up the P0s and P1s whose inbox item wasn't routed at step 4.
12. **Drift checks** *(five questions borrowed from LIVING REFERENCE's drift tests, a source credited in Spec §6)*, each answered against the KB and the log, never against an impression:
   - Does any recent production (workstream, deliverable, public surface) **contradict a `canon` page** of the KB?
   - Has an option **set aside in the log come back** — re-proposed or quietly re-applied — even though its rejection reason still holds?
   - Is a decision **made for one workstream being applied beyond it**, as if it bound the whole project?
   - Is a **draft or proposal cited somewhere as if it were settled** (`status: proposal` treated as fact)?
   - Is a **validated constraint being ignored** anywhere (a publication rule, a guard, a naming convention)?
   The repair (reject, archive, replace, revalidate) goes into the synthesis as a proposal.
13. **Force of proposal** *(the review's one divergent gesture)*: starting from `STRATEGY.md` and the watch report, put forward ideas the user would not have had on their own — a blind spot in the stated direction, something never tried, a connection between an outside finding and a problem here. An idea already set aside in the log comes back only if its context has changed, and you say what changed (Spec §11).
14. **Synthesis**: the state of things (health, workstreams, waits, inbox, measures, freshness of the framework and of the skills, routines, watch, drift), the proposed actions ranked by value (`open-work` candidates, workstreams to close, fixes), and the ideas from step 13 listed apart. It's the user who chooses.
15. **Trace it**: an entry `## [YYYY-MM-DD] review | week <no.>` in `log.md` with the condensed synthesis and what was decided.

## Done
- Success condition: the `review |` entry exists in the log under today's date and carries the proposed actions and the ones chosen.
- Reading criterion: a fresh context reading that entry alone knows what is healthy, what is dragging, which actions were proposed, and which were chosen.
- Stop: the review fixes nothing and opens no workstream without the user's agreement.

## Running as a scheduled routine
The review can run with no human at the keyboard (a cloud routine, a cron, whatever the harness offers), on one condition: **signal only**. It reads, measures and proposes; it corrects nothing, opens and closes no workstream, and touches nothing outside the core. It writes only its `review |` entry in `log.md` (step 15) and its synthesis, pushed where the human will read it (a commit, a message, an inbox item). Every proposed action waits for them.

Declare it in `.claude/mos.json` like any other routine: `cadence: "weekly"`, `proof_glob: "log.md"`, `proof_marker: "] review |"`. A review that ran somewhere that commits nothing shows up as a proof that did not arrive: a fact to state, not a breakage to presume (step 10).
