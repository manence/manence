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
---
```

- git gives you the "when I learned it" axis for free (commit history).
- The frontmatter gives you "from/until when it is true".
- **Explicit statuses** (`shipped / upcoming / to confirm`, `obsolete`) are a lightweight form of invalidation.

### Lifecycle of an item
Not everything the AI produces is usable. An item carries an explicit **status**, which evolves:

```
proposal → evaluated → validated → canonized → archived | rejected
```

- Frontmatter `status:` (`proposal` | `validated` | `canon` | `archived` | `rejected`).
- **`canon`** = becomes a reusable reference you can lean on. It is the proposal→canon transition that creates the value.
- Never treat a `proposal` as a fact. *(Status model borrowed from JP Noto's CANON FLOTANT / LIVING REFERENCE, a private project credited here.)*

## 7. Frictionless capture

- **`inbox/`**: you drop a raw note without filing it; the agent sorts it later (at `lint` or on request).
- Optional: **timed auto-commit** (à la swyx, e.g. every 20 min) for a git history without ceremony.

## 8. Periodic hygiene: the `lint` command

A regular Claude pass that looks for: orphan pages, an `index.md` that has drifted, expired claims, **contradictions between files**, broken links, duplicates (L2 violations). To be turned into a `kb-lint` skill. Visual aid: the **Obsidian graph** makes orphans (isolated nodes) and clusters/gaps obvious at a glance.

Special case: `type: research` files are **source records** (they report what a primary source says). Their overlap with the Manifesto and the framework's concepts is **normal** and **excluded** from the duplicate check: law L2 targets the framework's own knowledge (one canonical file per fact), not its supporting evidence, which legitimately mirrors the content of the source it documents.

The **mechanical** counterpart ships with it: `templates/hooks/lint.sh` (broken links, leading slash, YAML + `type:`), standalone or as a PostToolUse hook. Its structural exemptions mirror the laws: in **production** (outside git, §16), only the `About.md` of active workstreams are held to OKF, artifacts are free (disposable), and closed workstreams (`done/`, formerly `published/`) are checked only on their links (a closed workstream is never rewritten, L3/§16); `sources/` and the Claude Code formats (`SKILL.md`, `.claude/agents/`) are outside OKF; and each repo can declare a **`.lintignore`** (one prefix per line, commented) for its out-of-scope zones: a dated corpus that is never rewritten, inherited files in another language. *(Lesson from the first deployment: on a real corpus, most of the raw findings came from dated archives and English files; the real debt is what remains after that scoping.)*

## 9. Context budget (law L1)

- **`CLAUDE.md` < ~200 lines** (official Claude Code recommendation: *"target under 200 lines"*; beyond that, adherence drops). Bullets, not paragraphs. Specific ("indent 2 spaces") rather than vague ("format nicely").
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

A validation is not a plain go/no-go: it is an **artifact** to keep. Every important decision leaves a `log.md` entry that captures **who chose, what, why, and what was set aside**:

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

## 12. Security & confidentiality: hard vs soft (law L9)

Key distinction: **a hard constraint runs through a physical boundary, not a flag** an agent can ignore.

- **Soft**: `CLAUDE.md` and the `rules/` only **suggest**. Claude reads, tries to follow, but can depart from them.
- **Hard (actions)**: to **block** an action whatever Claude decides → **`PreToolUse` hook** (`permissionDecision: "deny"`) or **`permissions.deny`** in `.claude/settings.json`. E.g. never `rm -rf`, never a push to `main`. (Shipped: `templates/settings.example.json` + `templates/hooks/guard.sh`.)
- **Hard (data)**: for data that **must NEVER leak** (e.g. a confidential folder) → **a separate repo + git access**, never a `visibility:` field. Clearance = who can clone. Additive tiers: a shared bundle + a confidential delta, plugged in by role (see the framework's hexagonal architecture).
- **Zero-knowledge**: the shared core does **not even mention** the confidential adapter (no line in `CLAUDE.md`, no log entry, no history trace). The adapter has its **own `CLAUDE.md`** and only appears when plugged in by whoever can clone it. Otherwise the mere mention "confidential connector: …" gives away its existence.
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
- **A self-describing `CLAUDE.md`**: the adapter's role and rules, read **on demand** when it is plugged in (the core does not have to know it by heart).
- **Secrets in a gitignored `.env`** + a **`.env.example`** listing the variables without values; **no committed secret**.
- **Portable paths**: relative (`../adaptateur`) or env variables (`$X_ROOT`, documented default), **never** a hard-coded machine path (`~/Dev/…`, `/Users/toi/…`), or it breaks from one machine to the next.
- **Declared skills**: every `SKILL.md` carries a `name` **and** a `description`, so it can be listed in the core's connector map.
- **If a knowledge bundle**: OKF (frontmatter + body), **pure facts**, `index.md` up to date, **without** secret or executable code (see §13).
- **If confidential**: gitignored or without a public remote, plugged in only via `CLAUDE.local.md` by cleared instances; **absent from the core's map** (zero-knowledge, §12).

This contract is what the base `connect-adapter` skill validates automatically.

## 16. The workstream contract (the operational layer)

The **workstream** is the dynamic unit of work (the *why*: [concept/atelier](../concept/atelier.md)). Its rules:

- **Production lives at the container, outside git**: `$<PROJECT>_PRODUCTION_ROOT` (documented default: `../production/` from the core, see §18), organized by **domain** created on first need, each domain with `in-progress/` and `done/`. You version only the **system** (the core) and the **knowledge** (the KB); a workstream's texts and assets live **together**.
- **A workstream = one `<domain>/in-progress/<slug>/` folder** with an identifiable deliverable. A readable slug, **with no date prefix** (that comes at closing). Progress belongs to the frontmatter (`status:`); the folder name only says in-progress or done.
- **`About.md` required**: `type: work` frontmatter + `status:` (`proposal → validated | canon | rejected`), goal and deliverable in one sentence, **linked** context (links to the KB and to the predecessor, **computed from the workstream's final location**, see §18; never a copy, L2), and a "Next step" section kept up to date (that is the one you read to resume). Template: `templates/chantier/About.template.md`.
- **All the work lives in the folder**, heavy assets included (production is not versioned, they clutter no git). Iterations overwrite in place, no `old/` subfolder. **Artifacts are disposable by doctrine**: durability goes through `close-work`, never through the folder.
- **Opening via `open-work`**: routing checked (is this really work?), duplicate checked (`in-progress/`, `done/`, `inbox/`), a `work-open` entry in the log. **Implicit workstream**: creating a work folder in production *is* opening a workstream, the discipline applies automatically; a workstream born wrong is repaired by `close-work`'s **retroactive file**, and the `weekly-review` flags folders without an `About.md`.
- **Closing via `close-work`**: explicit GO, move to `<domain>/done/YYYYMMDD-<slug>/`, status settled, **mandatory distillation** (durable facts → KB via `kb-ingest`, the closed workstream becomes their `resource:`; a wrap-up in the log with the lesson learned, L8): it is the **only guarantor of durability**. Any closed **external action** records its **measurement date** and **who will observe it** (which ritual). **An abandonment is closed too** (`status: rejected`, with the reason).
- **A closed workstream is never rewritten** (dated, it is part of the history, L3).
- **A periodic report is not a workstream**: a time series (growth review, health) is **consolidated knowledge**, it lives in the **KB**; its candidate actions go into `inbox/`.

## 17. The routing table ("where each thing goes")

The framework's 2 questions, made operational:

- The core's `CLAUDE.md` carries a **routing table**: one home per type of thing (stable fact → KB · work in progress → a workstream in the container's production · capture → `inbox/` · procedure → skill · decision → `log.md` · periodic report → KB, its candidate actions to `inbox/` · live data → layer 7, conclusion only · heavy asset → with its workstream, since production is not versioned). The generic version lives in `templates/CLAUDE.template.md`; each core adapts it to its real folders.
- **Every top-level folder of the core has its row** in the table. A folder without a row is a gray zone: you route it or you delete it.
- **Nothing is created at the root or off the table.** When in doubt, `open-work` asks the questions.
- **Mechanical enforcement, not doctrinal**: `lint.sh` and the `weekly-review` detect orphans outside the structure; findings are handled in review, never in silence.

## 18. Paths are passed, not guessed

As soon as a location can move (production at the container, a plugged-in external system), a path is never guessed, it is **passed on**:

- **One root variable per movable location**: pattern `$<PROJECT>_<LOCATION>_ROOT` (e.g. `$MONPROJET_PRODUCTION_ROOT`), **documented default** (in `.env.example` and the core's `CLAUDE.md`), overridden per machine in `.env`. Never a hard-coded machine path (§15).
- **A hard rule for subagents**: every subagent prompt that touches a workstream contains the **resolved absolute path**. A subagent never derives a production path; the caller resolves it and passes it.
- **A workstream's links to the core or the KB are computed from the workstream's final location** (it is `open-work` that writes them: it knows both roots) and **verified from there** (`lint.sh <production-root>`, run by the `weekly-review`). A template that carries relative links is fragile to relocation: the lint is only valid from the real location.
- **The core's references to a production artifact are pointers** (`resource:` or a path under `$…_ROOT`, in a code span), never relative markdown links: production is outside git and can move, the repo's lint cannot guarantee them.
