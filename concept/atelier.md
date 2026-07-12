---
type: reference
title: "The workshop"
description: "The operational layer of the framework: the workstream as a dynamic unit of work, the routing table that says where each thing belongs, and the loop from measurement to decision to production. What makes the OS the place where work gets done, not only where it gets filed."
tags: [ai-os, workshop, workstream, routing, operations]
timestamp: 2026-07-02
---

# The workshop

## What it is

The **operational layer** of the framework: the tooling-backed answer to the question "where does work-in-progress go, and how does it move forward?" Three parts that work together:

- the **workstream**, the dynamic unit of work: a `<domaine>/in-progress/YYYYMMDD-<slug>/` folder (the date prefix is the opening date, set at birth) in the **container's production** (outside git), with a typed `About.md` (`type: work`), an identifiable deliverable, **linked** context (never copied), and a trace;
- the **routing table**, the framework's 2 questions (static or dynamic? what is it?) turned into a concrete table in the core's `CLAUDE.md`: every type of thing has its home, and nothing gets created outside the table;
- the **three skills** that keep it all alive: `open-work` (open), `close-work` (publish and capitalize), `weekly-review` (watch over).

This concept came out of practice: an OS can have an excellent memory (identity, knowledge, measurements) and still go unused, because the work has **no point of entry**. It then happens outside the structure, in orphan folders, and the operator finds that "the AI isn't helped enough in understanding what goes where." The workshop fixes this by making routing a **mechanism** (table + skill + lint), not a paragraph of doctrine.

## How it works

### Where production lives (in the container, outside git)
You version only the **system** (the core) and the **knowledge** (the KB). The deliverables themselves live **in the container, outside git**: `../production/` from the core (the `$<PROJET>_PRODUCTION_ROOT` variable, with a documented default; for the paths, see [Spec §18](../implementation/Spec.md)), organized by **domain** created the first time it's needed, each domain with `in-progress/` and `done/`. Two reasons: binary assets have no business in the core's git, and the **locality of the workstream** (the text and the assets of one piece of work live together, not text on one side and binaries on the other). An accepted corollary: **artifacts are disposable by doctrine**; durability comes through `close-work` (KB distillation + log, mandatory), never through the folder. A **periodic report** (a time series: growth review, health) is **consolidated knowledge**: it lives in the **KB**, not in production.

### The routing table
A table in the core's `CLAUDE.md`: a stable fact goes to the KB, work-in-progress into a workstream, a capture into `inbox/`, a procedure into a skill, a decision into `log.md`, a live piece of data stays in its own system (layer 7 — you persist only the conclusion), a heavy asset lives **with its workstream** (production isn't versioned; only a reference from the KB goes through a `resource:` pointer note). **Every top-level folder of the core has its own row** (otherwise it becomes a gray area). When in doubt, route through `open-work`; `lint.sh` and the `weekly-review` catch orphans.

### The life cycle of a workstream
`<domaine>/in-progress/YYYYMMDD-<slug>/` (status `proposal`) → the work lives **inside** the folder (iterations overwrite in place, artifacts are disposable: no `old/` subfolder) → `close-work` moves it to `<domaine>/done/YYYYMMDD-<slug>/` — **same name, a pure move**: renaming at close would break every incoming link, and a closed workstream is frozen with them — and rules on it (`validated`, `canon` if the deliverable becomes a reference, `rejected` if abandoned). An abandonment **also gets closed**: the trace of a reasoned decision to give up is worth its weight in gold. A closed workstream is never rewritten (it is dated, it is part of the history). **Progress belongs to the frontmatter** (`status:`); the folder name carries the opening date and the slug — its parent (`in-progress/` or `done/`) says the state.

**The implicit workstream.** Creating a work folder in production **is** opening a workstream: the discipline of `open-work` (About, linked context, trace) applies by default, whether or not the skill was invoked. A **badly born** workstream (well routed, but with no About and no trace) is repaired by the **retroactive note** of `close-work`; the `weekly-review` flags production folders that have no `About.md`.

### The operational loop
The bridge between layers 7, 6, and 2, the one that is most often missing:

> **measure** (the connectors, layer 7) → **decide** (cross measurements with knowledge; the decision to the log, L8) → **produce** (the workstream) → **publish** (`close-work`) → **measure** again, and the distilled conclusion goes back to the KB.

It's this loop that makes the OS "the one you launch the next action through," and not only the one that files away the previous ones.

Three practices proven in the field:
- the **periodic report**: a dated review (growth, health...) written by a skill **in the KB** (a time series is consolidated knowledge, not a workstream), whose **candidate actions** land in `inbox/` to feed `open-work`. This is the loop in its regular form;
- the **effect measurement belongs to the ritual, not to the workstream**: the workstream closes, the measurement survives in the system. Every closed external action records its **measurement date** (e.g. day+7) and **who will observe it** (which ritual: the review flags a missing report, then sees the effect);
- **manual first**: the loop runs by hand for as long as layer 5 hasn't shown "value > cost." You automate only a ritual that has proven itself, never the reverse.

### The rule of 3 occurrences (tooling without over-engineering)
A gesture is written **ad hoc** the first and the second time; the **third**, it enters a **skill**, prose that repairs itself: the agent adapts the procedure when the world moves. It becomes a **script** only if it's deterministic, frequent, and expensive to fail silently. *(From experience: a third-party API had silently migrated its field names; the prose skill adapted mid-run, the agent discovered the migration and corrected the doctrine, where a frozen script would have failed silently.)*

## Why this is the right form

- **Work is born with its context**: a workstream's brief links the KB pages, the measurements, and the precedent of the same type, instead of starting over from scratch. The RAM stays high-signal (L1), knowledge isn't copied (L2).
- **Every workstream leaves a double trace** (L8): the dated deliverable in `done/`, and what was learned in the log (the `close-work` summary). Since artifacts are disposable, this distillation isn't optional: `close-work` is the **only guarantor of durability**.
- **Mechanized routing replaces hoped-for discipline**: a table the agent applies at every creation, backed by a lint that catches the deviations, in the spirit of L9 (the tool rather than the promise).

## → Source

No external source: a concept born from the framework's first real deployment, then refined by the pilot project's first full day of operation (the loop run twice; the lessons from that harvest were each worked through one by one into v1.1, see [CHANGELOG](../CHANGELOG.md)). The status cycle of workstreams reuses the proposal → canon of LIVING REFERENCE (JP Noto, credited private project).

## → Alongside (the how)

- [Spec §16: the workstream contract](../implementation/Spec.md), [§17: the routing table](../implementation/Spec.md), and [§18: the paths](../implementation/Spec.md).
- Ready-to-copy skills: [`open-work`](../implementation/mos/.claude/skills/open-work/SKILL.md) · [`close-work`](../implementation/mos/.claude/skills/close-work/SKILL.md) · [`weekly-review`](../implementation/mos/.claude/skills/weekly-review/SKILL.md).
- Template: [templates/chantier/](../implementation/mos/templates/workstream/About.template.md); the generic routing table lives in [CLAUDE.template.md](../implementation/mos/CLAUDE.md).

Related concepts: [The memory model](modele-memoire.md) (the workstream is the "in progress" part of dynamic memory) · [The double value](double-valeur.md) (the close-work summary) · [The wiki method](methode-wiki.md) (the KB that the workstream links and feeds) · [Manifesto](../Manifesto.md).
