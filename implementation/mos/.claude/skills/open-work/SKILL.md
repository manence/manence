---
name: open-work
description: Use it whenever the user wants to work on something new that has an identifiable deliverable — a campaign, a webinar, a document, an exploration. Opens a workstream in the container's production, after checking against the routing table in AGENTS.md that it is one, and leaves a dated folder, its About.md, and a work-open entry in the log. IMPLICIT TRIGGER: creating a work folder in production IS opening a workstream; the discipline applies on its own, even if no one invoked the skill.
---

# open-work, opening a workstream

## Purpose
So that every piece of work is born in the right place, with its context, instead of ending up as an orphan folder. The workstream contract (folder, `About.md`, `work_id`, `awaiting`, disposable artifacts) is Spec §16; this skill is its opening procedure.

## Procedure
1. **Resolve the production root** to an absolute path: `$<PROJECT>_PRODUCTION_ROOT`, default `../production/` (Spec §18).
2. **Route first**: the table in `AGENTS.md` ("Where each thing goes") tells you whether this really is work in progress. If not, send it to its home and stop there.
3. **Look for a duplicate** in `in-progress/`, `done/`, and `inbox/`: if one exists, pick it up rather than open a second workstream.
4. **Domain and name**: an existing business domain if the work belongs there, otherwise create it with `in-progress/` and `done/`; the folder is named `YYYYMMDD-<slug>` from the opening day (`20260712-meta-back-to-school-campaign`), once and for all (Spec §16).
5. **Create `About.md`** from `templates/workstream/About.template.md` and fill in the brief **with the user**, who alone knows it: the goal in one sentence, the deliverable, a deadline if there is one. If no one can say what will be delivered, it's an exploration: write it down as such, with the question to settle. `work_id` = the folder name; `awaiting` = whatever already waits on someone, otherwise `[]` (Spec §16). The minimal form is enough to be born.
6. **Link the context, don't copy it**: KB pages, measures, the previous workstream of the same kind; links computed from the final location and verified by resolving them (Spec §18).
7. **Trace it**: `## [YYYY-MM-DD] work-open | <domain>/<slug>`, at the top of `log.md`, under its H1 (Spec §4), one line: the goal.

## Done
- Success condition: the folder exists under `in-progress/` with an `About.md` (`type: work`, `status: proposal`, `work_id`, `awaiting`) that `lint.sh` passes from production; no second workstream open on a subject that already had one (step 3).
- Reading criterion: a fresh context that reads only the `About.md` can state the deliverable and the next step.
- Trace: the `work-open` entry in the log.
