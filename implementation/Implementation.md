---
type: playbook
title: "Implementation: setting up a Manence project"
description: "The step-by-step for starting a project without looking anywhere else: skeleton, frontmatter by type, and the wiki method (Karpathy) as an actionable procedure. The default MOS in mos/."
tags: [ai-os, playbook, mise-en-oeuvre]
timestamp: 2026-06-30
---

# Implementation

The framework states the *what* ([Manifesto](../Manifesto.md)) and the rules ([Spec](Spec.md)). Here is the *how*, for setting up a project without reopening the sources. The default MOS in [`mos/`](mos/BOOTSTRAP.md) (identity files, the 6 base skills, hooks, the startup ritual); a running example of a knowledge base in [`example/`](example/index.md).

## 1. Set up a new project (copy `mos/`, run the first startup)

```bash
git clone https://github.com/manence/manence.git
cp -R manence/implementation/mos my-project
```

Then open Claude Code in the new folder and say: **"run my first startup"**. The agent reads [`BOOTSTRAP.md`](mos/BOOTSTRAP.md) — the one-time ritual: language (English or French — the French set ships in `mos/fr/` and replaces the English files on request), an interview (name, activity, team, voice, direction), the identity files filled from your answers, prerequisites checked, production created outside git, `git init` and first commit, `lint.sh` at 0 findings — then the ritual file deletes itself.

There is no frozen `starter/` directory *and* no assembly script: `mos/` **is** the single source (law **L2**) — what you copy is what you run, and the personalization is a conversation, not a `sed`.

The result: a self-contained core **plus its production alongside, outside git** (Spec §16; location chosen at first startup):

```
my-project/           ← THE CORE (git repository: the system + the knowledge)
  CLAUDE.md            identity + direction + routing table (filled by the first startup)
  SOUL.md  STRATEGY.md  the voice, the strategy (filled by the first startup, openclaw convention)
  .claude/
    skills/            the 6 base skills (open-work, close-work, weekly-review, kb-ingest, kb-lint, connect-adapter)
    agents/            empty at start; a subagent template sits in templates/agent.template.md
    settings.json      hook wiring
    hooks/             guard.sh, lint.sh (executable)
  .mcp.json.example     MCP connectors (copy to .mcp.json if needed)
  .env.example          env variables, including $MY_PROJECT_PRODUCTION_ROOT (copy to .env, gitignored)
  CLAUDE.local.md.example  map of local/confidential connectors (copy to CLAUDE.local.md, gitignored)
  .gitignore
  templates/           workstream template (About.template.md) + OKF templates, within the project's reach
  scripts/   sources/  direct API calls; immutable raw sources (wiki method)
  knowledge-base/      the wiki (layer 2), see §3
    index.md  log.md   skeletons, stamped by the first startup; ready for kb-ingest
  inbox/               raw capture to be sorted
  log.md               the project journal (append-only)

production/           ← OUTSIDE git, in the container (default ../production/, created by the first startup)
  <domain>/           a business domain, created on first need by open-work
    in-progress/       ongoing workstreams
    done/              closed workstreams (prefix YYYYMMDD-, via close-work)
```

`.gitignore` provided: `.env`, `.env.*` (except `.env.example`), `node_modules/`, `.DS_Store`, `CLAUDE.local.md`, `.obsidian/workspace*`.

**Hard security** (blocking `rm -rf`, direct push, sending without approval): via `.claude/settings.json` + `hooks/guard.sh` (shipped in `mos/`), **not** via CLAUDE.md, see [Spec §12](Spec.md). Check the install: `bash .claude/hooks/lint.sh .` (0 findings expected).

## 2. Frontmatter, by type

Every knowledge file = YAML frontmatter + body. **Only `type:` is required.** Full templates: [`templates/frontmatter.md`](mos/templates/frontmatter.md).

| type | use | typical fields |
|---|---|---|
| `reference` | a stable fact (brand, product, entity record) | `title, description, resource, tags, timestamp` (+ extensions `valid_from`, `superseded_by`, `status` if it goes stale) |
| `log` | dated journal (reserved name `log.md`) | `title, description, timestamp` |
| `index` | map of a directory (reserved name `index.md`) | *no frontmatter* (OKF listing) |
| `runbook` | a procedure | `title, description, timestamp` |
| `partner` / `competitor` / … | your business entities | your choice |

Status cycle of an item (field `status:`): `proposal → validated → canon → archived | rejected`.

## 3. The wiki method (Karpathy), as a procedure

> Faithful to Karpathy's open source gist ("llm-wiki"; URL in [research/01](../concept/research/01-karpathy-practitioners.md)). He himself calls it **"intentionally abstract"**: it is a **pattern to adapt** with your LLM, not a fixed implementation. His central insight: *the cost of a knowledge base is neither reading nor thinking, it is the **bookkeeping***; the LLM does that part, tirelessly.

**Three layers**:
- **`sources/`**: the raw inputs, **immutable** (articles, PDFs, images, data). The LLM reads them, never modifies them.
- **the wiki** (`knowledge-base/`), the pages the LLM generates: summaries, **entity** pages, **concept** pages, comparisons, syntheses. One concept = one file. The LLM owns it; you read it.
- **the schema** (`CLAUDE.md`): the structure, conventions, and workflows the LLM follows. Co-evolves with the domain.

**Division of labor** (the core, verbatim Karpathy): *you* select the sources, ask the right questions, steer the analysis, and review; *the LLM* does **everything else** (summarize, create/link the pages, note contradictions, keep the index and the log, lint).

> The two loops below (**ingestion**, **lint**) are **provided as skills, present from the first startup**: `kb-ingest` and `kb-lint` (`mos/.claude/skills/`).

### Ingestion (for each new source)
1. **Drop** the source into `sources/`.
2. The LLM **reads** it and **discusses the key points** with you (one source at a time, supervised).
3. It **writes a summary page** in the wiki (template `concept.template.md`).
4. It **updates `index.md`** (link + one line).
5. It **updates the related entity/concept pages**; a single source often touches **10-15**; you *integrate*, you don't pile up (law **L7**).
6. It **adds an entry to `log.md`**: `## [YYYY-MM-DD] ingest | <source>`.

### Query (answering a question)
The LLM **searches through `index.md`**, reads the relevant pages, **synthesizes with citations** (links). The format varies (page, comparison table, Marp slides, graph). The key: **a good answer is folded back in as a new page**; exploration doesn't get lost in the chat, it **compounds**.

### Lint (periodic audit)
The LLM reviews the wiki and looks, following Karpathy, for: **contradictions** between pages, **stale claims** (superseded by more recent sources), **orphan pages** (no inbound link), **concepts cited without a dedicated page**, **missing cross-references between pages**, **data gaps** (to fill by web search). Out of this come new questions to dig into. **Provided as the `kb-lint` skill** (`mos/.claude/skills/`).

> Optional tooling (from the gist, everything is modular): **git** (versions), **Obsidian graph** (the shape of the wiki: hubs, orphans), **qmd** (local hybrid search at scale), **Marp** (slides), **Dataview** (queries by frontmatter).

## 4. The workshop: the life of a workstream

> The *why*: [concept/atelier](../concept/atelier.md). The rules: [Spec §16-§18](Spec.md). The moves below are **provided as skills** (`mos/.claude/skills/`), present from the first startup. Structural reminder: production lives **in the container, outside git** (`$<PROJECT>_PRODUCTION_ROOT`, default `../production/`), and its artifacts are **disposable by doctrine**.

- **Open (`open-work`)**: production root resolved (never guessed, Spec §18), routing checked (is this really ongoing work? a fact goes to the KB via `kb-ingest`, a capture into `inbox/`, a decision to the log, a periodic report to the KB), duplicate checked, then a `<domain>/in-progress/<slug>/` directory created from `templates/workstream/` — `templates/chantier/` on a French system — (the domain is created on first need), brief filled in with the **linked** context (KB pages, measurements, previous workstream; never copied, links computed from the final location), a `work-open` entry in the log, next step announced. **Creating a work directory in production is already opening a workstream**: the discipline applies as a matter of course, skill invoked or not.
- **Run**: everything lives in the workstream's directory, heavy assets included (production is not versioned); iterations overwrite in place (no `old/` subdirectory); the "Next step" section of the `About.md` stays current (that's what you read to pick the work back up); structuring decisions go to the log (L8); every sub-agent receives the **resolved absolute path** of the workstream in its prompt (Spec §18).
- **Close (`close-work`)**: explicit GO, move to `<domain>/done/YYYYMMDD-<slug>/`, status set (`validated`/`canon`, or `rejected`: an abandonment is closed too, its trace counts), **mandatory distillation** (durable facts → KB via `kb-ingest`, wrap-up → log: the artifacts are disposable, this move is the only guarantee of durability), and every external action gets its **measurement date** and its **observer** (which ritual). A closed workstream is never rewritten. The skill also carries the **retroactive record** that regularizes a badly-born workstream (a directory without an `About.md`).
- **Watch (`weekly-review`)**: once a week, by hand: mechanical lint (core **and** production root), inbox triage, stalled workstreams, orphans outside the routing table, badly-born workstreams, effect measurements that have come due, freshness of the periodic report (in the KB). The review **observes and proposes**, it does not fix (L4).

**The full loop**: measure (connectors, layer 7) → decide (periodic report in the KB, candidate actions in `inbox/`) → produce (`open-work`) → close (`close-work`) → measure again. **Manual first**: you automate (layer 6) only a ritual that has proven its value. And for tooling the moves, the **rule of 3 occurrences** ([atelier](../concept/atelier.md)): ad hoc twice, skill (self-healing prose) the third time; a script only if it is deterministic, frequent, and fails silently at real cost.

## 5. Wiring in external data (layer 7)
You do **not** pull the live data into the repo. You query it (MCP or script + API), and you **persist only the conclusion** in `knowledge-base/` (if it becomes a fact) or `production/` (if it is a deliverable). Keys in `.env`.

## 6. Start small
Level 1 first (`CLAUDE.md` + 1-2 skills), then split out the `knowledge-base/`, then isolate execution into sub-agents. Don't build it all at once; see the maturity ladder of the [framework](../Manifesto.md).

The skills common to every project (the **"base/OS"** family) live in [`implementation/mos/.claude/skills/`](mos/BOOTSTRAP.md) of `manence`; they arrive with the copy of the default MOS (in French, if the first startup was run in French). Six today: `open-work` (open a workstream), `close-work` (publish a workstream), `weekly-review` (weekly review: lint, inbox, open workstreams), `kb-ingest` (integrate a source), `kb-lint` (audit the KB), and `connect-adapter` (connects a new adapter, validating the contract [Spec §15](Spec.md) and routing confidential → `CLAUDE.local.md` / shared → `CLAUDE.md`).

Lesson from the field: when the knowledge lives in a **plugged-in adapter** (not a local `knowledge-base/`), **adjust the base skills' paths at copy time** (`kb-ingest`, `open-work`, `weekly-review`... then point to `../<knowledge-bundle>/`), and align the `CLAUDE.md` routing table with the core's real directories: every top-level directory gets its own line (Spec §17).

## 7. Wiring in an adapter (when things split off)

As long as it stays solo-simple, everything stays in the repo (§1). You **split a part out into a plugged-in adapter** only under a driving force: the knowledge becomes **shared** or **confidential**, or a target has its **own deploy**.

An adapter can be a **knowledge bundle** or a **capability bundle** (a skill + its connector, e.g. social publishing, shared across projects).

Wiring it in, concretely:
- **`claude --add-dir ../my-bundle`**, gives the core access to a neighboring repo. The simplest way.
- **A reference in the core's `CLAUDE.md`**, documenting the adapter's path and role (and `@import`ing a specific file if needed).
- **git submodule**, if you want to pin the adapter to a version.

**How the core *knows* its adapters: access ≠ knowledge.** Two distinct things, both necessary:
1. **Access** (can it *read*?): `--add-dir ../adapter`. Without it, the agent sees nothing outside its root repo. This is the physical wiring.
2. **Knowledge** (does it know it *exists* and what it's for?): the **connector map in the core's `CLAUDE.md`** (a *path → role* table), auto-loaded at startup. The `CLAUDE.md` adds *"at startup, read `../adapter/index.md`"* → the agent loads the detail; and each adapter carries **its own `CLAUDE.md`** (it self-describes), loaded when the directory is wired in.

It is this **pairing of access + knowledge** that makes **zero-knowledge** real (L9): a confidential adapter is **absent from the core's map** (knowledge) **and not `--add-dir`ed** for un-cleared instances (access); the agent can neither name it nor read it.

**Your instance owns its confidential connectors: the difference is LOCAL, not in the core.** Your (cleared) machine wires in the confidential adapter; a deployed copy does not. That difference lives in a **gitignored local config**, never in the shared core. Put the **map** of those connectors in **markdown** (`CLAUDE.local.md`, gitignored), **not** in the runtime's native format (`.claude/settings.json` recouples you to a tool). Markdown stays readable by **any model** (law *the model is a component*); only **access** (`--add-dir`) is a runtime-specific launch shim, to keep minimal. The "connector profile" (who wires in what) is a property **of the instance**, not of the core.

**External systems (layer 7): wired in, never co-located, never on a hard machine path.** A site / CRM / product app has its own lifecycle (team, deploy) → you *wire it in*, you don't put it inside the Manence OS container. And you reference it by **env variable** (`$X_ROOT`, documented default), not `~/Dev/...` or `/Users/you/...` hard-coded, or it breaks from one machine to the next.

Rules:
- Each adapter keeps **its own `.env`**; the core does not store the others' keys.
- **Confidentiality**: a sensitive bundle = a **separate repo**, wired in only by cleared instances (git access enforces the rule, law **L9**).
- **Boundary test**: "who owns the lifecycle?" Owned → core; separate → adapter.

Full model: the **hexagonal architecture** of the [framework](../Manifesto.md).

## 8. Onboarding an existing project (junk drawer → hexagon)
When you start from an **already-full** repo (not an empty directory), don't migrate blind:

1. **Audit first**, classify each item: **keep in the core** / **connect** (already a clean repo) / **confidential** (separate repo) / **capability** (bundle later) / **leave** (cruft, `node_modules`, binaries). This is the review artifact *before* moving anything.
2. **Copy then freeze**, never move the content: the source stays a **read-only backup**. You copy what serves, then freeze the old one (`ARCHIVED.md` + git tag, no more writes). This doesn't violate L2: once copied, the old one is **dead**, not a second living source.
3. **Move** (not copy) a repo that is **already clean and self-contained** (e.g. the KB): this is relocating an intact repo, not migrating content; it's safe.
4. **Extract the confidential** into a separate repo **first** (zero-knowledge), before any push.
5. **Heavy assets → external + OKF record**: binaries (video, images) do **not** go into git. You leave them external and create **one OKF record per deliverable** (not per asset, 200 videos = 1 record, not 200) that points to them (`resource:` / path). "Persist the pointer, not the binary" pattern (layer 7).
6. **Inherited absolute paths** (`~/…`) → env variables before wiring in.

> ⚠️ **Migration safety: check the SOURCE's `.gitignore` before copying.** A `cp`/`rsync` also copies what the source **gitignored**, potentially including **confidential** material (a sensitive directory, a copy of secrets). Before any push: (a) read the source's `.gitignore` rules to know what it was protecting; (b) **scan for confidential markers** (counterparty names, sensitive figures, `.env`) in what you copied. *(Lived: a confidential strategy file, gitignored on the source side, swept up by a "text" rsync and then pushed; fixed by rebuilding a **clean release** (history rebuilt + repo re-created), not by patching the existing repo.)*

## 9. Deploying an instance (and the move to multi-user)
**Single-user first.** One operator = one core, no deployment machinery. But keep the **dividing line** clean from now on, so that multi-user becomes a *wiring-in*, not a rewrite.

**The dividing line = static / dynamic (L3):**
- **Static = the shipped product**: `CLAUDE.md`, `SOUL.md`/`STRATEGY.md`, `.claude/skills/`, conventions, canonical knowledge (KB). Versioned, shared, deployed to everyone.
- **Dynamic = blank per instance**: `log.md`, `inbox/`, session memory, and production (outside git in the container; it never travels with the core: each instance mounts its own). Each accumulates **its own** journal; the founder's does not travel.
- **Confidential = separate repos, zero-knowledge** (see [Spec §12](Spec.md)).

**Deploying = shipping a release, not the repo:**
- `git clone --depth 1` (or a squashed commit) → the current state **without the history** (which can carry sensitive material: a migration, logs, a copy made by mistake).
- The shipped `log.md` and `inbox/` are **empty** (or a minimal starter); production is not part of the release (it is outside git by construction).
- The person wires in the bundles they are allowed to see (`--add-dir`); never the confidential ones.

**The day it's truly multi-user:**
1. One shared KB (static) + **N cores** (one per person/role) = multi-instance.
2. Each core composes the **authorized** bundles; the confidential stays zero-knowledge.
3. Governance (*who validated what*, L8) becomes the effective human supervision.

It is this boundary that makes the **AIOS Solo vs Enterprise** product.

## 10. The framework's lifecycle (feeding lessons back up)

The framework improves through its deployments, and the channel is doctrined (it has proven itself: nothing is lost, the context of birth stays linked):

- **At each AIOS project**: any lesson **at the framework level** (a trap or a pattern that should change Manence itself, not just this project) = an entry in the **project's** log, tagged `## [YYYY-MM-DD] framework | title`, noted that same day. The lesson is born where it was lived.
- **On the framework side**: the lessons are **harvested per version workstream**: a harvest document (one lesson = its generalized experience + its proposed doctrine + its destinations in the framework), worked through in a **dedicated session** in the framework repo: accept / amend / reject, propagate to the destinations, verify (`lint.sh` at 0 findings, a first startup from `mos/` produces a conforming MOS), one decision per lesson in the log (L8).
- **Never a client example in the framework**: the harvest generalizes (a neutral lesson); the detailed experience stays with the project, in its log.
