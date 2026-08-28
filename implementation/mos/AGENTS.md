# AGENTS.md, <project name> (Manence OS core)

This file is the system's identity, and it is agent-neutral: whichever coding agent you are (Claude Code, OpenAI Codex, Grok Build), this is what you read first.

## Identity
<Who I am here, the voice to adopt.> See `SOUL.md` for tone, `STRATEGY.md` for direction.

## At the start of a session
- Read `knowledge-base/index.md` (the map of your knowledge) and the top of `log.md` (the latest decisions).
- Check whether a `CLAUDE.local.md` exists at the root: if it declares local connectors, load them too. Otherwise, ignore it.
- Look at the open workstreams in production (`$<PROJECT>_PRODUCTION_ROOT`, default `../production/`: the `<domain>/in-progress/` folders) and `inbox/` (raw capture to sort).

## What this project does
<In 2-3 lines.>

## Where each thing goes (routing table)
Before you create or move a file, two questions: **static or dynamic? what is it?** Then:

| It's... | It goes... |
|---|---|
| a stable fact (brand, product, entity, business rule) | `knowledge-base/` (OKF, one concept per file; through `kb-ingest` if it comes from a source) |
| work in progress (a campaign, a deliverable, an exploration) | a **workstream** `<domain>/in-progress/YYYYMMDD-<slug>/` (dated at opening) in the **container's production** (outside git: `$<PROJECT>_PRODUCTION_ROOT`, default `../production/`), opened by `open-work`. **Creating a working folder there = opening a workstream**: the discipline (About, linked context, trace) applies by default |
| a finished deliverable | `<domain>/done/`, through `close-work` (same folder name — never renamed, so links survive; KB distillation + log **required**: production artifacts are disposable) |
| raw capture not yet sorted | `inbox/` |
| a reusable procedure | `.claude/skills/<name>/SKILL.md` (the rule of three: ad hoc twice, a skill the third time) |
| an event, a decision | a dated entry in `log.md` (append-only) |
| a live piece of data from an external system | nowhere: you query it through a connector (layer 7) and keep only the distilled conclusion |
| a periodic report (a review, reporting) | `knowledge-base/`: a time series is **consolidated knowledge**, not a workstream; its candidate actions go to `inbox/` |
| a heavy asset (video, PSD, deck) | **with its workstream**, in production (outside git). A reference from the KB goes through a pointer file (`resource:`) |

**Nothing is created at the root or outside this table.** When in doubt, `open-work` asks the questions. The lint (`.claude/hooks/lint.sh`) and the `weekly-review` catch orphans.

## Connectors (the hexagon)
<A map of the plugged-in adapters: a table of path · role · clearance. Confidential adapters are NEVER listed here: they live in `CLAUDE.local.md` (gitignored). To plug in a new one: the `connect-adapter` skill.>

| Connector | Path | Role |
|---|---|---|
| <none yet> | | |

## Conventions
- Knowledge: `knowledge-base/` (OKF: YAML frontmatter, `type:` required, one concept per file; you link, you never recopy a fact).
- Dynamic: workstreams in the container's production (see the routing table); the journal in `log.md`, append-only, with `## [YYYY-MM-DD] type | title` prefixes.
- A **framework-level** lesson (one that should change Manence itself, not just this project) is tagged in the log: `## [YYYY-MM-DD] framework | title`. The framework harvests them per version workstream.
- Paths are passed, not guessed: movable locations have a root variable (`.env.example`); every subagent prompt that touches a workstream carries the **resolved absolute path**.
- Standard markdown links, relative to the file (`../folder/page.md`, `neighbor-page.md`), never a leading slash (the Obsidian graph doesn't trace those).
- Full rules: the Manence framework Spec, in a separate repo: <https://github.com/manence/manence> (`implementation/Spec.md`).

## Skills
Base (provided by the framework): `open-work` (open a workstream), `close-work` (publish a workstream), `weekly-review` (weekly review: lint, inbox, workstreams), `kb-ingest` (integrate a source into your knowledge), `kb-lint` (audit the KB), `connect-adapter` (plug in an adapter), `mos-map` (see this system: the visual map), `outward-watch` (look outward: the substrate and the trade).
They live in `.claude/skills/`, whatever the agent — that is their single home. Some agents find them through a `skills/` link at the root, installed by the first setup: a bridge, never a second home; you never write there.
<Project-specific skills: list them here as you add them.>

## Security, hard vs soft
- **Soft (this file)**: this file only *suggests*. The agent may depart from it.
- **Hard (what actually constrains)**: a `PreToolUse` hook or a denied permission, declared in the agent's own configuration. To *forbid* (e.g. `rm -rf`, a direct push), that's where it goes, not here. The guardrails themselves are shipped once, under `.claude/`: `.claude/hooks/guard.sh` (blocks) and `.claude/hooks/lint.sh` (reports). Each harness wires them its own way — Claude Code: `.claude/settings.json` + those hooks; OpenAI Codex: `.codex/config.toml`; Grok Build: its native Claude compatibility, nothing to wire.
- Common sense: `trash` over `rm`; internal work (reading, drafts) → free.
- **Writing at a third party** (creating, publishing, sending, activating): an explicit GO + a dry-run (`validateOnly`) when the API offers one + before/after logged in the deliverable + **create it paused/as a draft first**, activate as a second step. Separate read and write credentials: measurement stays read-only, write capability is added on decision.
- API keys in `.env` (gitignored, template in `.env.example`), never committed. Local/confidential config: `CLAUDE.local.md` (gitignored), never in this file.

## Language
<Files in …; conversations in ….>
