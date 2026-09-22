---
type: spec
title: Concrete conventions of Manence
description: The rules you can apply right away (directory tree, frontmatter, naming, freshness, static/dynamic separation) for a markdown + git repository that an agent reads and writes.
tags: [ai-os, conventions, okf]
timestamp: 2026-06-30
---

# Concrete conventions

The theory lives in [Manifesto](../Manifesto.md). Here are the rules you apply as-is.

## 0. Vocabulary (MOS, core, container)

Three words come up everywhere; it is worth pinning them down before the rules.

- **MOS (Manence OS)** — a complete installation of the framework, dedicated to a single activity. Concretely, it is **the container**: the parent directory that holds the core, its wired-in connectors (ideally kept inside it, barring a historical reason), and production. One MOS = one activity = one perimeter of rightful owners.
- **The core** — the git repository at the center of the MOS, **the one you run the AI in**. It carries identity, skills, execution, automation, memory (layers 1, 3, 4, 5, 6); everything else wires in around it. It is the MOS's entry point.
- **The container** — the non-repo folder that holds it all (core + adapters + production). "Container" names the structure on disk, "MOS" names the same thing as a dedicated installation: both words point to the same perimeter.

How many MOS? Everyone draws the lines their own way; as a rule, **the system follows the capital** — one MOS per ownership/confidentiality perimeter, because a core holds one activity's decisions and its readers must coincide with its rightful owners. It is the boundary test from [hexagonal architecture](../concept/architecture-hexagonale.md) applied at the scale of the whole installation.

## 1. The file contract (OKF)

> Follows Google's **OKF v0.1** spec. The 5 recommended fields below come from the spec; our additions are marked **extension** (OKF allows any extra key).

Every knowledge file = **YAML frontmatter + markdown body**. One concept, one file; its identity is the path without `.md`.

```markdown
---
type: <required>          # THE ONLY required field (competitor | partner | runbook | reference …)
title: <readable title>    # OKF recommended
description: <one sentence> # OKF recommended, used to judge relevance at recall
resource: <URI>            # OKF recommended, URI of the underlying asset (source, dashboard…), when relevant
tags: [a, b]               # OKF recommended
timestamp: 2026-06-30      # OKF recommended, ISO 8601, last substantive change
# Manence extensions (outside OKF, but allowed)
# valid_from: 2026-06-22
# superseded_by: ../path/v2.md
# status: canon            # proposal | validated | canon | archived | rejected
---

The body. One concept per file.
```

- **Only `type:` is required** (route/filter: "read every `type: competitor`"). The five other OKF fields (`title`, `description`, `resource`, `tags`, `timestamp`) are **recommended**, not required.
- **`timestamp`**, not `updated`, is the OKF field (and the one our KB uses).
- **Permissive conformance**: a consumer **must preserve** unknown keys and **must not** reject a bundle over a missing optional field, an unknown `type`, a broken link, or an absent `index.md`.

## 2. Granularity & naming

- **One concept, one file.** The agent edits just the right file, without touching the others.
- **Name = readable slug**: `partenariat-acme.md`, never `202606301410.md` or `22.04-truc.md`. The filename is a semantic handle, for grep **and** for the LLM.
- Pattern: `domain/specific-thing.md` (e.g. `concurrents/un-concurrent.md`).

## 3. Links

- **Standard markdown links**, no Obsidian `[[wikilink]]` in shared bundles (portability, clean git diffs).
- Use links **relative to the file** (`../concurrents/un-concurrent.md`, `page-voisine.md`), not leading-slash links (`/concurrents/…`). Reason: Obsidian does **not** trace leading-`/` links in its graph view (it reads them as the disk root). The cost of relative links (recomputing the path when a file moves) is free bookkeeping for the LLM, exactly what the framework hands to it.
- A link from A to B **asserts a relationship**; you give it its type through the surrounding prose.
- **No false dilemma with Obsidian**: Obsidian traces **relative** markdown links in its graph view, not only `[[ ]]`. So you keep links that are **portable (OKF, rendered everywhere: Obsidian, GitHub, any viewer)** *and* you get the **graph** to visualize, without tying yourself to Obsidian.

## 4. Entry points

Two OKF **reserved names**, exempt from the frontmatter rule:
- **`index.md`** per folder: a catalog (one link + one line per page). OKF reserved file = **folder listing, no frontmatter**. It is the agent's map; keep it current so it does not drift.
- **`log.md`**: an append-only journal, never rewritten retroactively (a small `type: log` frontmatter stays tolerated). Parseable prefixes:
  ```
  ## [2026-06-30] ingest | Title of the source
  ## [2026-06-30] decision | What was settled
  ```

## 5. Static vs dynamic (law L3)

| | Reference (static) | Log / production (dynamic) |
|---|---|---|
| Editing | rewritten **in place** | **append-only**, dated |
| Example | `produit/mon-produit.md` | `journal/2026-06-13-reunion.md` |
| Freshness | `timestamp:` | the date prefix is authoritative |
| Never | put a dated report here | put an identity file here |

## 6. Status, freshness & expiry (the "poor man's Graphiti")

For a fact that can expire, don't overwrite silently, **invalidate**:

```markdown
---
type: reference
timestamp: 2026-06-30
valid_from: 2026-06-22
superseded_by: ../produit/v2.md   # when replaced
review_when: "2026-08-15, opposition window opens"   # optional: when to re-check
---
```

- git gives you the "when I learned it" axis for free (commit history).
- The frontmatter gives you "from/until when it is true".
- **Explicit statuses** (`shipped / upcoming / to confirm`, `obsolete`) are a lightweight form of invalidation.
- **`review_when:`** (optional) looks *forward* where the other two fields look back: a date or a trigger event after which the page stops being authoritative **on its own** and asks to be reconfirmed or updated. Without it, a stale truth stays `canon` until someone trips over it; with it, the weekly review surfaces the page mechanically at the right moment. Only pages whose truth can expire carry it — the lint flags a due `review_when`, it never demands the field. *(The forward-looking trigger is borrowed from LIVING REFERENCE's freshness axis, JP Noto.)*
- **A wait is a freshness too**: on a workstream, `awaiting` (§16) says what is waiting on whom since when, and the weekly review surfaces the old ones.

### Lifecycle of an item
Not everything the AI produces is usable. An item carries an explicit **status**, which evolves:

```
proposal → evaluated → validated → canonized → archived | rejected
```

- Frontmatter `status:` (`proposal` | `validated` | `canon` | `archived` | `rejected`).
- **`canon`** = becomes a reusable reference you can lean on. It is the proposal→canon transition that creates the value.
- Never treat a `proposal` as a fact. *(Status lifecycle borrowed from JP Noto's LIVING REFERENCE — source record in [research/06](../concept/research/06-living-reference.md); the freshness fields above come from the bi-temporal model of Zep/Graphiti, source 03.)*

## 7. Frictionless capture

- **`inbox/`**: you drop a raw note without filing it; the agent sorts it later (at `lint` or on request).
- Optional: **timed auto-commit** (à la swyx, e.g. every 20 min) for a git history without ceremony.

## 8. Periodic hygiene: the `lint` command

A regular Claude pass that looks for: orphan pages, an `index.md` that has drifted, expired claims (including a due `review_when`, §6), **contradictions between files**, broken links, duplicates (L2 violations). To be turned into a `kb-lint` skill. Visual aid: the **Obsidian graph** makes orphans (isolated nodes) and clusters/gaps obvious at a glance.

Two sizes belong to the same pass, for the same reason: they drift too slowly to be noticed on any ordinary day. Past **150 KB** for `log.md` or **200 lines** for `AGENTS.md` (§9), the review says so. What it proposes for an oversized log is a **rotation** — the entries of a closed year moved to `log-archive/YYYY.md`, same format, still append-only, still one `grep` away — never a summary and never a deletion; and for an oversized identity file, a trim: what has become documentation goes to the knowledge base, and `AGENTS.md` links to it.

Pruning has a test too, the mirror of the §11 sieve *(borrowed, like the sieve, from LIVING REFERENCE, JP Noto — source record in [research/06](../concept/research/06-living-reference.md))*: a page that is **no longer tied to any living decision** and whose loss **would force nothing to be redone** gets consolidated or archived — two verifiable questions, never a judgment of importance, and always proposed rather than applied. The KB does not promise to keep everything; it promises that what it keeps either conditions a decision or spares a redo.

Special case: `type: research` files are **source records** (they report what a primary source says). Their overlap with the Manifesto and the framework's concepts is **normal** and **excluded** from the duplicate check: law L2 targets the framework's own knowledge (one canonical file per fact), not its supporting evidence, which legitimately mirrors the content of the source it documents.

The **mechanical** counterpart ships with it: `templates/hooks/lint.sh` (broken links, leading slash, YAML + `type:`), standalone or as a PostToolUse hook. Its structural exemptions mirror the laws: in **production** (outside git, §16), only the `About.md` of active workstreams are held to OKF, artifacts are free (disposable), and closed workstreams (`done/`, formerly `published/`) are checked only on their links (a closed workstream is never rewritten, L3/§16); `sources/` and the Claude Code formats (`SKILL.md`, `.claude/agents/`) are outside OKF; and each repo can declare a **`.lintignore`** (one prefix per line, commented) for its out-of-scope zones: a dated corpus that is never rewritten, inherited files in another language. *(Lesson from the first deployment: on a real corpus, most of the raw findings came from dated archives and English files; the real debt is what remains after that scoping.)*

## 9. Context budget (law L1)

- **The identity file is `AGENTS.md`**, read by every agent that drives the core (Claude Code, Codex, Grok Build). `CLAUDE.md` stays, reduced to two things: an `@AGENTS.md` import and the addendum Claude Code alone needs (its wiring under `.claude/`). One home for the content, one entry point per agent.
- **`AGENTS.md` < ~200 lines** (the budget the identity file has always carried: Claude Code's official recommendation is *"target under 200 lines"*, and Codex concatenates the `AGENTS.md` files it finds under a 32 KiB ceiling; beyond that, adherence drops either way). Bullets, not paragraphs. Specific ("indent 2 spaces") rather than vague ("format nicely").
- **`SKILL.md`**: keep the body focused, but it **only loads on use**, so length costs little there; large content goes into bundled files loaded on demand.
- `@import path` for a shared fragment rather than copying it (max depth **4 hops**).
- `/clear` between two unrelated tasks.

## 10. Deciding: markdown+git or heavy infrastructure?

| Memory need | markdown + git is enough | infrastructure (graph/vector) justified |
|---|---|---|
| Procedural (skills) | almost always | almost never |
| Episodic (events) | **yes**, git IS the audit log | semantic search over a very long horizon |
| Semantic (facts) | few facts, hand-sorted | thousands of facts, frequent contradictions, relationship traversal |
| Bi-temporal | dozens of facts that change slowly (`valid_from`/`superseded_by`) | "as of date X" queries at scale → **Graphiti/Zep** |

By default, for a solo/SMB operator: **markdown + git covers everything**, except the day volume × contradiction rate × relationship-traversal need forces the graph.

## 11. Human validation = trace (double-value principle, law L8)

A validation is not a plain go/no-go: it is an **artifact** to keep. What earns a `log.md` entry is settled by a test, not by a feeling of importance — the **trace sieve** *(borrowed from LIVING REFERENCE, JP Noto, like the status model in §6)*: an interaction leaves a trace **if and only if** it changes a status, a scope, or a constraint, **or** if losing it would force the work to be redone (the *redo test*). Two no's: no trace — "important" is an adjective, not a criterion, and a log that records everything is just a bloated prompt deferred. When a decision does trace, the entry captures **who chose, what, why, and what was set aside** — and the set-aside matters: before re-proposing an option, the agent checks it was not already rejected, because a kept reason is what stops the same mistake from coming back.

```
## [2026-06-30] validation | Option chosen
- chosen by: <user>
- decision: "<the validated option>"
- set aside: 2 other paths
- why: <the deciding reason>
```

One gesture, four benefits:
- **Traceability**, the history of structuring decisions.
- **Accountability**, telling apart what the AI *proposed* from what the human *validated*. This is the **effective human oversight** required by the GDPR (Art. 22) and the AI Act whenever an AI assists a decision.
- **Personalization**, the system learns your real preferences and constraints.
- **Reuse**, the validation becomes a `canon` reference (see §6), callable later.

This is what separates an assistant that *answers* from a system that *supports a workflow and compounds the choices made*.

**An audit is valid for a state, not for an artifact.** A verification report is **dated and bound to the exact state it saw** (the commit, a hash, a word count), and any later edit either reopens the audit or is marked unaudited: a report that does not say which state it speaks of is indistinguishable from a stale one, and it goes on inspiring confidence after its object has changed. The same holds for the reference a check reads: any negative finding of the form "X does not exist in the reference" is preceded by a **synchronization of that reference** (`git fetch` and a comparison to origin, or the system's equivalent) and states which state it speaks of, commit and date — a negative drawn from a partial snapshot looks like proof, and it accuses. *(Lived: an audit rendered at 1,114 words, the text extended to 1,321 twenty minutes later, two factual errors passing under a report everyone still trusted; and, across machines, a "fabricated citation" verdict that came from a local clone simply running behind.)*

## 12. Security & confidentiality: hard vs soft (law L9)

Key distinction: **a hard constraint runs through a physical boundary, not a flag** an agent can ignore.

- **Soft**: `AGENTS.md` (and the `rules/`) only **suggest**. The agent reads, tries to follow, but can depart from them.
- **Hard (actions)**: to **block** an action whatever the agent decides → **`PreToolUse` hook** (`permissionDecision: "deny"`) or **`permissions.deny`** in `.claude/settings.json`. E.g. never `rm -rf`, never a push to `main`. (Shipped: `implementation/mos/.claude/settings.json` + `implementation/mos/.claude/hooks/guard.sh`.) The guardrail is written once and lives under `.claude/`; each agent wires it in its own file (Claude Code: `.claude/settings.json`; Codex: `.codex/config.toml`, installed by the first setup; Grok Build: its Claude compatibility, nothing to wire). The shipped `guard.sh` is an **anti-mistake barrier**, not a hostile-proof boundary: it matches common destructive forms by regex, fails closed when `jq` is missing, and documents its exact scope in its header; for strong guarantees, lean on `permissions.deny` and the runtime's sandbox.
- **Hard (data)**: for data that **must NEVER leak** (e.g. a confidential folder) → **a separate repo + git access**, never a `visibility:` field. Clearance = who can clone. Additive tiers: a shared bundle + a confidential delta, plugged in by role (see the framework's hexagonal architecture).
- **Zero-knowledge**: the shared core does **not even mention** the confidential adapter (no line in `AGENTS.md`, no log entry, no history trace). The adapter carries its **own identity file** and only appears when plugged in by whoever can clone it. Otherwise the mere mention "confidential connector: …" gives away its existence.
- **What you share is a release, not the repo**: you never deploy/share the working tree or the history (they can carry sensitive material: migration, logs, a copy made by mistake), but a **curated release** (the static layer; `git clone --depth 1` or a squashed commit). The dynamic part (`log.md`, `production/`) starts **empty** per instance.
- **External writing = guardrail** (reading outside is free): (1) explicit **GO** from the operator, (2) **`validateOnly`/dry-run** when the API offers it, (3) **before/after traced** in the deliverable, (4) **create paused/as a draft first**, then activate as a second gesture. The hard side: **separate read / write credentials**, the measurement bundle stays read-only, write capability is added deliberately, by decision. Detail: [frontiere-dure](../concept/frontiere-dure.md).
- **Local/confidential config → gitignored markdown, not the runtime format.** An operator's map of confidential connectors goes into a **markdown** file (`CLAUDE.local.md`, gitignored), readable by any model, not into a proprietary `settings.json` (that loses again the model portability you just gained). Only the **access** (`--add-dir`) stays a launch shim specific to the runtime.

## 13. Bundle hygiene (knowledge ≠ capability)

- **A knowledge bundle = pure facts**: **no secret** (`.env`), **no executable code**. It must stay **shareable** (without leaking keys) and **portable**.
- The skills that *produce* the facts (e.g. fetch analytics / CRM / ad platform) **+ their keys** = **capability** (layers 3+7) → **a separate bundle** that *queries* the external systems (layer 7) and **writes only the distilled conclusion** into the knowledge bundle ("persist the pointer/the conclusion, not the stream" rule). *(Lived: a shared KB carried 16 API keys + its `funnel`/`gads` skills, moved out into a `growth-ops` capability bundle; the KB is facts without secrets again.)*

## 14. Identity hygiene (layer 1)

- **Do not name the operator agent like an entity / a product documented in the KB.** Otherwise the agent reads its own "identity" in a product file and conflates itself with it. Reserve product names for the product; give the operator a **distinct** name, with an explicit guardrail ("you are not X"). *(Example: "Lumo" named both the AI *product* and the operator agent → collision; we rename the operator, with the guardrail "you are not Lumo".)*

## 15. The adapter contract (what a repo must respect to be pluggable)

What a repo must guarantee to plug cleanly into the core (via `--add-dir`, `@import` or submodule, see [Implementation §7](Implementation.md)):

- **A self-contained git repo**: its own lifecycle (its own owner / deploy / versioning), its own `.env`; the core does not store other repos' keys.
- **A self-describing identity file** (`AGENTS.md`, or the `CLAUDE.md` of a repo that predates it): the adapter's role and rules, read **on demand** when it is plugged in (the core does not have to know it by heart).
- **Secrets in a gitignored `.env`** + a **`.env.example`** listing the variables without values; **no committed secret**.
- **Portable paths**: relative (`../adaptateur`) or env variables (`$X_ROOT`, documented default), **never** a hard-coded machine path (`~/Dev/…`, `/Users/toi/…`), or it breaks from one machine to the next.
- **Declared skills**: every `SKILL.md` carries a `name` **and** a `description`, so it can be listed in the core's connector map.
- **If a knowledge bundle**: OKF (frontmatter + body), **pure facts**, `index.md` up to date, **without** secret or executable code (see §13).
- **If confidential**: gitignored or without a public remote, plugged in only via `CLAUDE.local.md` by cleared instances; **absent from the core's map** (zero-knowledge, §12).

This contract is what the base `connect-adapter` skill validates automatically.

## 16. The workstream contract (the operational layer)

The **workstream** is the dynamic unit of work (the *why*: [concept/atelier](../concept/atelier.md)). Its rules:

- **Production lives at the container, outside git**: `$<PROJECT>_PRODUCTION_ROOT` (documented default: `../production/` from the core, see §18), organized by **domain** created on first need, each domain with `in-progress/` and `done/`. You version only the **system** (the core) and the **knowledge** (the KB); a workstream's texts and assets live **together**.
- **A workstream = one `<domain>/in-progress/YYYYMMDD-<slug>/` folder** with an identifiable deliverable. A readable slug **prefixed with the opening date, at birth** — closing then moves the folder without renaming it, so no incoming link ever breaks. Progress belongs to the frontmatter (`status:`); the parent folder (`in-progress/` or `done/`) says the state.
- **`About.md` required**: `type: work` frontmatter + `status:` (`proposal → validated | canon | rejected`), goal and deliverable in one sentence, **linked** context (links to the KB and to the predecessor, **computed from the workstream's final location**, see §18; never a copy, L2), and a "Next step" section kept up to date (that is the one you read to resume). Template: `templates/chantier/About.template.md`. The same frontmatter carries **`work_id`**, equal to the folder name at birth: it is the stable identity a reader, or another MOS, refers to this workstream by, and a move never changes it — workstreams opened before the field keep none, since nothing is retrofitted. The **minimal form is enough to be born**: the frontmatter, the goal in one sentence, the next step; the rest fills in as the stakes grow. What applies to every workstream, whatever its size, is the discipline, not the length of the record — the ceremony is what keeps a workstream from being born wrong, and that risk does not shrink with the stakes.
- **The declared wait**: the same frontmatter carries `awaiting`, the list of what is waiting on a human — one entry per wait, with `who` (a short stable handle in the MOS), `what`, `kind` (`decision`, a choice only that person can make, or `action`, a gesture only they can perform) and `since` (the day the wait was born, not the last reminder), plus an optional `blocks` (what the wait prevents). An empty list means nothing is left to settle. `open-work` poses the field at birth, the working session adds an entry the moment it hits a human decision or gesture and removes it once settled, `close-work` **asks** rather than refuses when the list isn't empty (the remainder goes into the `work-close` entry as a traced renunciation or deferral), and the `weekly-review` surfaces the waits older than two weeks, grouped by person. A reader **never infers a wait from the prose**: this field is the only source.
- **All the work lives in the folder**, heavy assets included (production is not versioned, they clutter no git). Iterations overwrite in place, no `old/` subfolder. **Artifacts are disposable by doctrine**: durability goes through `close-work`, never through the folder.
- **Opening via `open-work`**: routing checked (is this really work?), duplicate checked (`in-progress/`, `done/`, `inbox/`), a `work-open` entry in the log. **Implicit workstream**: creating a work folder in production *is* opening a workstream, the discipline applies automatically; a workstream born wrong is repaired by `close-work`'s **retroactive file**, and the `weekly-review` flags folders without an `About.md`.
- **Closing via `close-work`**: explicit GO, move to `<domain>/done/` (**same folder name**: the date prefix was set at opening; a close never renames, so it never breaks a link), status settled, **mandatory distillation** (durable facts → KB via `kb-ingest`, the closed workstream becomes their `resource:`; a wrap-up in the log with the lesson learned, L8): it is the **only guarantor of durability**. Any closed **external action** records its **measurement date** and **who will observe it** (which ritual). **An abandonment is closed too** (`status: rejected`, with the reason).
- **A closed workstream is never rewritten** (dated, it is part of the history, L3).
- **A periodic report is not a workstream**: a time series (growth review, health) is **consolidated knowledge**, it lives in the **KB**; its candidate actions go into `inbox/`.

## 17. The routing table ("where each thing goes")

The framework's 2 questions, made operational:

- The core's `AGENTS.md` carries a **routing table**: one home per type of thing (stable fact → KB · work in progress → a workstream in the container's production · capture → `inbox/` · procedure → skill · decision → `log.md` · periodic report → KB, its candidate actions to `inbox/` · live data → layer 7, conclusion only · heavy asset → with its workstream, since production is not versioned). The generic version is the one shipped in `implementation/mos/AGENTS.md`; each core adapts it to its real folders.
- **Every top-level folder of the core has its row** in the table. A folder without a row is a gray zone: you route it or you delete it.
- **Nothing is created at the root or off the table.** When in doubt, `open-work` asks the questions.
- **Mechanical enforcement, not doctrinal**: `lint.sh` and the `weekly-review` detect orphans outside the structure; findings are handled in review, never in silence.
- **What a reader may rely on**: the production layout is an **API** for anything that reads a MOS without opening it by hand — a reader, an interface, a script. What it may rely on: `<domain>/in-progress/<slug>/About.md` and `<domain>/done/<slug>/About.md`; an `About.md` carrying `type: work`, `status`, `awaiting`, and `work_id` from 0.8 onwards; a folder under `in-progress/` **with no `About.md`** is a badly born workstream, which a reader **shows as such** and never silently skips. What it must **not** assume: that every slug carries the `YYYYMMDD-` prefix (only workstreams born after that rule do; older ones keep the name they were born with), that a workstream's assets follow any layout at all, or that anything other than `About.md` is OKF. The contract's version is the framework's own, read in `.claude/manence-version`.

## 18. Paths are passed, not guessed

As soon as a location can move (production at the container, a plugged-in external system), a path is never guessed, it is **passed on**:

- **One root variable per movable location**: pattern `$<PROJECT>_<LOCATION>_ROOT` (e.g. `$MONPROJET_PRODUCTION_ROOT`), **documented default** (in `.env.example` and the core's `AGENTS.md`), overridden per machine in `.env`. Never a hard-coded machine path (§15).
- **A hard rule for subagents**: every subagent prompt that touches a workstream contains the **resolved absolute path**. A subagent never derives a production path; the caller resolves it and passes it.
- **A workstream's links to the core or the KB are computed from the workstream's final location** (it is `open-work` that writes them: it knows both roots) and **verified from there** (`lint.sh <production-root>`, run by the `weekly-review`). A template that carries relative links is fragile to relocation: the lint is only valid from the real location.
- **The core's references to a production artifact are pointers** (`resource:` or a path under `$…_ROOT`, in a code span), never relative markdown links: production is outside git and can move, the repo's lint cannot guarantee them.

## 19. Seeing the MOS: Manence UI, the reader

A MOS is files in a terminal. **Manence UI** is what gives them a face: a reader of a MOS's production, and a separate piece of software — its own repository, its own version, installed once at the root of the container family (`~/MOS/manence-ui`, a sibling of the cores it reads) and pointed at as many MOS as you run. It reads; it never writes. It stays **local** — nothing leaves the machine, no telemetry, no account.

It answers three questions, and they are the ones an operator actually asks: **what is in progress** (by domain, each workstream with the freshness of its last movement), **what has already been done** (the closed workstreams, searchable), and **where something is waiting on a human** (the `awaiting` field, §16, grouped by person). Alongside them it shows the knowledge base as a **graph**, so a body of knowledge can be looked at rather than listed.

What it reads is the **format this framework versions**, and nothing else: the production layout of §17 ("What a reader may rely on"), the `About.md` contract of §16 (`type: work`, `status`, `awaiting`, `work_id`), and **`.claude/mos.json`** — the system's machine-readable declaration: its connectors as *attachments* (a declared position 0-5, a nature `kb | production | mos | git | externe`, a display name, a one-line summary, outbound links, `visible: false` to declare without showing). `connect-adapter` keeps it aligned with the `AGENTS.md` connector map: two synchronized homes — the prose is authoritative, the declaration is mechanical. A **confidential** adapter never enters `mos.json`: the file is versioned and shared, and §12's zero-knowledge applies to readers too — what is not declared is not displayed, by anyone.

The same file carries the **routines** — what is supposed to run on its own — and schema 3 makes them readable by a machine: each routine declares its `cadence` (taken from a closed list rather than written in prose) and its **proof**, the file pattern (or the marked log entry) whose most recent instance says the routine ran, so that lateness is *computed* from the files instead of guessed. A proof that has not arrived is stated as such and no further: a routine may have run somewhere that commits nothing, so breakage is never presumed from silence.

The rule between the two is simple, and it is what keeps them from waiting on each other: **the framework versions the format, the reader declares which versions it reads** ("Manence UI 0.1 reads Manence ≥ 0.8"). Neither ships on the other's schedule, and nothing in a MOS depends on a reader existing — **a MOS is complete without one**. A core that needed software to be legible would have failed its first promise: the files are the system.

## 20. Looking outward: the watch (`outward-watch`)

Every organ described so far looks inward: the log records what was decided, the knowledge base consolidates what was learned, the review inspects what was done. A MOS built only from these is blind to everything outside it — and the substrate it runs on changes faster than it does. The `outward-watch` skill is the counterweight, and it is deliberately the only organ allowed to bring in facts the work did not produce.

It watches on two levels. The **substrate** level is generic: what the system runs on, and the practice around it — the framework ships it complete, and only the filter is local. The **trade** level is a slot, empty on delivery, that each installation fills with its own field. Both feed one filter, *what does this change for this MOS, or for the framework?*, whose answer is the only thing that earns a line: a finding with no answer is recorded once as seen-without-effect, and never raised again.

The output is a **time series in the knowledge base** (`watch/YYYY-MM-DD.md`), not a workstream: a periodic report is consolidated knowledge (§17). Each finding keeps the sourced fact apart from the reading of it. What calls for action leaves as a candidate in `inbox/`, where the weekly review sorts it (§8's hygiene applies: the watch proposes, it never opens work). The watch writes nothing outside the core and publishes nothing, ever.

## 21. The instruction item: the human → agent channel

A MOS is driven from a terminal, and the reader (§19) only ever shows. One gesture is missing between the two: the operator should be able to **answer a wait, or give an instruction, from wherever it is on screen**, without reopening a terminal, and that gesture should take effect in the files. The framework settles this with a single piece, and the system already has it: **a file in `inbox/`**.

The whole contract is one inbox item, `type: instruction`. It is **written by a front desk** (Manence UI has one; any software that honors this contract may have one) and **read by the agent**, which acts through the framework's skills. The front desk writes that file, in that folder, and nothing else, and it never overwrites: it touches no About, no log, no knowledge base, no existing item. "The system declares, it does not arbitrate" holds for an interface as much as for a reader: the effect is the agent's to produce.

The frontmatter carries the source (`source`), the MOS and the workstream it targets (`mos`, `work_id`), the **gesture**, and its life cycle (`status`). There are three gestures. `decision` and `action` answer an `awaiting` entry (§16) — one with a decision, the other with a "done" and its proof — and copy the entry across when the item is filed (`awaiting_what`, `awaiting_who`, `awaiting_since`, `awaiting_index`), so the agent can find it again **by its text first**, and by its index only as a fallback, since the list shifts whenever it is edited. The third, `consigne`, is the generic gesture on a workstream: close it, abandon it, change course, fix something, ask a question; it can target a `document` in the workstream (path relative to its folder) and a `page`. The body is the operator's own words. The title is its first line, cut at a whole word.

The agent reads these items **first**, at session start and at review, through a base skill (`consignes`) that does what the gesture asks: remove the `awaiting` entry and record the decision or the proof in the About; carry out an instruction and record it; run `close-work` when the instruction opens with “Clore” or “Abandonner” (“Close” / “Abandon” in an English install) — that is the **explicit GO** that skill requires, and it is the only gesture that requires one; go back to a document's source before correcting it; answer a question **with an `awaiting` entry** in the About, never with a reply file, since the return channel already exists and it is the one the reader shows. Each item then moves to `status: traitee`, or to `rejetee` with the reason, with a dated footer line; the interface never deletes it, and the review sweeps it up later. An instruction that would write into someone else's system, send something, or publish something is rejected: a form is no way around the golden rule (§11).

**The file is the channel; any trigger is only an accelerator.** The "at session start" line in `AGENTS.md` is enough for any harness. A harness may add a signal of its own — a startup hook that counts newly filed items and says so at the top of the session, a message between sessions, a file watcher — but it declares the signal in its own wiring, never in the shared identity file, and all its failure costs is immediacy. A MOS whose channel only worked under one harness would have no channel at all; a MOS with no front desk is still complete: the operator answers at the terminal, as before.
