---
name: weekly-review
description: A weekly health review of Manence OS — mechanical lint (core + production), triaging the inbox, the state of workstreams in progress, spotting orphans and badly born workstreams (production folders with no About.md), effect measures that have come due, and proposed actions. Run it once a week (by hand or via cron/heartbeat), or whenever the user asks "where do we stand?".
---

# weekly-review, the weekly review

## Purpose
To prevent the two drifts that kill a Manence OS: the disorder that sets in (orphans, an overflowing inbox, broken links, badly born workstreams) and the workstreams that stall without anyone noticing.

## Procedure
1. **Mechanical lint**: run `.claude/hooks/lint.sh` on the repo, **then** on the production root (`$<PROJECT>_PRODUCTION_ROOT`, default `../production/`, resolved to an absolute path): that is where the workstreams' links to the KB have to resolve from (Spec §18). Report the findings. Fix nothing without approval (maker ≠ checker, L4).
2. **Orphans**: look for files and folders that live **outside** the routing table's locations in `CLAUDE.md` (at the root of the core, outside `knowledge-base/`, `inbox/`, `.claude/`, `scripts/`). For each one, propose its destination from the table (a workstream? the KB? the inbox? the trash?).
3. **Badly born workstreams**: in production, flag any `in-progress/` folder **with no `About.md`** (work born outside the discipline) → propose the retroactive record from `close-work`.
4. **Inbox**: go through `inbox/` item by item: route each one (a fact → `kb-ingest`, work → a candidate for `open-work`, stale → `trash`, keep as-is → it stays but you date it). **Time guard**: any capture older than 14 days gets sorted or trashed at this review — the inbox is exempt from the file contract precisely because this sweep exists. Goal: an empty or a deliberate inbox.
5. **Workstreams in progress**: list the `<domain>/in-progress/` folders with, for each: the goal (its `About.md`), its age, its last activity. Flag the ones that haven't moved in 2 weeks: move them forward, or close them (`close-work`, including a deliberate abandonment).
6. **Effect measures**: pick up the closed external actions whose **measurement date** has been reached (recorded by `close-work`) and flag any missing measurement report. The measure belongs to the ritual: this is where you see the effect.
7. **KB**: a light `kb-lint` if the KB moved this week (contradictions, an index that has drifted); otherwise note it as not done. While you're at it, check the freshness of the periodic report (in the KB), and pick up any page whose `review_when:` has come due (a due page stops being authoritative on its own: propose reconfirming or updating it).
8. **Framework freshness**: the installed core carries its version in `.claude/manence-version`. Compare it to the latest tag of the public framework repo — `git ls-remote --tags https://github.com/manence/manence.git` (a public read over the network; nothing about your MOS is sent; without network, note "not checked this week" and move on). If the repo is ahead: list the missed versions **with their CHANGELOG notes** (fetch the raw `CHANGELOG.md` from the repo) and put the update in the proposed actions — the review signals, it never applies. If `.claude/manence-version` is missing, the install predates 0.5.0: say so and propose stamping it with the version the core actually matches.
9. **Drift checks** *(five questions borrowed from LIVING REFERENCE's drift tests, JP Noto)* — each answered against the KB and the log, never against an impression:
   - Does any recent production (workstream, deliverable, public surface) **contradict a `canon` page** of the KB?
   - Has an option **set aside in the log come back** — re-proposed or quietly re-applied — even though its rejection reason still holds?
   - Is a decision **made for one workstream being applied beyond it**, as if it bound the whole project?
   - Is a **draft or proposal cited somewhere as if it were settled** (`status: proposal` treated as fact)?
   - Is a **validated constraint being ignored** anywhere (a publication rule, a guard, a naming convention)?
   Observe only: the repair (reject, archive, replace, revalidate) goes into the synthesis as a proposal, and the user decides.
10. **Synthesis**: a 5-10 line status (health, workstreams, inbox, measures, framework freshness, drifts) + **2-3 proposed actions** ranked by value (`open-work` candidates, workstreams to close, fixes). It's the user who chooses.
11. **Trace it**: an entry `## [YYYY-MM-DD] review | week <no.>` in `log.md` with the condensed synthesis and what was decided.

## Guardrails
- The review **observes and proposes**, it fixes nothing and opens no workstream without approval.
- If it runs automatically (cron/heartbeat), the synthesis waits for the user to read it; nothing goes out.
- Success condition: in one read, the user knows what is healthy, what is dragging, what needs to be measured, and what to do next; the log keeps a trace of it.
