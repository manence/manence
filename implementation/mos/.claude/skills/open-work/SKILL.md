---
name: open-work
description: Opens a workstream (a unit of work with an identifiable deliverable) in the container's production, following the routing table in CLAUDE.md. Use it whenever the user wants to work on something new (a campaign, a webinar, a document, an exploration). IMPLICIT TRIGGER: creating a work folder in production IS opening a workstream; this discipline applies on its own, even if no one invoked the skill.
---

# open-work, opening a workstream

## Purpose
So that every piece of work is born **in the right place, with its context**, instead of ending up as an orphan folder. A workstream is a folder `<domain>/in-progress/YYYYMMDD-<slug>/` in the container's **production** (outside git), with a typed `About.md`, an identifiable deliverable, and a trace.

## Procedure
1. **Resolve the production root.** `$<PROJECT>_PRODUCTION_ROOT` (see `.env` / `.env.example`), default: `../production/` from the core. Resolve it to an **absolute path**: that is the one you use everywhere (and pass as-is to any subagent, never left "to guess", Spec §18).
2. **Route first.** Use the routing table in `CLAUDE.md` to confirm this really is *work in progress*:
   - a stable fact → not a workstream, this is `kb-ingest`;
   - a raw note with no deliverable → `inbox/`;
   - a procedure → a skill;
   - a decision on its own → an entry in `log.md`;
   - a periodic report → the KB (consolidated knowledge), not a workstream.
3. **Choose the domain.** Production is organized by business domain (`ads/`, `content/`, `reporting/`…), **created on first need** with its two subfolders `in-progress/` and `done/`. Reuse an existing domain if the work belongs there.
4. **Name it.** The opening date + a readable slug: `YYYYMMDD-<slug>` (`20260712-meta-back-to-school-campaign`). The prefix is set **at birth** and never changes: closing just moves the folder, so no incoming link ever breaks. Check that no similar workstream already exists in `in-progress/`, `done/`, or `inbox/` (if so: pick up the existing one, don't duplicate).
5. **Create** `<domain>/in-progress/YYYYMMDD-<slug>/About.md` from `templates/workstream/About.template.md` (in the core) and fill in the **brief** with the user: the goal in one sentence, the expected deliverable, and a deadline if there is one.
6. **Wire up the context, without copying it**: link the relevant KB pages, the pertinent measures (connectors), and the previous workstream of the same kind if there is one. The links are **computed from the workstream's final location** (you alone know both roots: verify them by resolving, not by assuming). You link, you don't recopy (L2).
7. **Trace it**: an entry `## [YYYY-MM-DD] work-open | <domain>/<slug>` in the core's `log.md` (one line: the goal).
8. **Announce** the next concrete step of the workstream.

## Guardrails
- A workstream is **one identifiable deliverable**. If you can't say what will be delivered, it's an exploration: note it as such in the brief, with a question to settle.
- All the work's files live **inside the workstream folder**, heavy assets included (production isn't versioned, so they clutter no git repo). Iterations overwrite in place, no `old/` subfolder.
- **Artifacts are disposable by doctrine**: whatever needs to last goes through `close-work` (distillation to the KB + log). Tell the user when a doubt comes up.
- A workstream born **without** this skill (a folder created by hand or in an ordinary session): apply this same discipline retroactively, right away or through the retroactive record in `close-work`.
- Internal skill: publish nothing, send nothing.
- Success condition: the folder exists with its `About.md` filled in (`status: proposal`), its links to the KB resolve, the log is up to date, and the user knows what the next step is.
