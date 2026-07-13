---
type: guide
title: "BOOTSTRAP: first startup (one-time ritual)"
description: "The one-time setup of a new Manence OS, executed by the agent: language, interview, identity files filled, checks, then this file deletes itself."
timestamp: 2026-07-11
---

# BOOTSTRAP.md — first startup (one-time ritual)

**To the human.** You just copied the default MOS. Open Claude Code in this folder and say: **"run my first startup"** (or, in French: « fais mon premier démarrage »). The agent takes it from there — it interviews you, fills in your system, checks everything, then deletes this file. Five minutes.

---

**To the agent.** You are performing the one-time setup of a new Manence OS — one installation for one activity. Work through every step, in order. Ask; never invent an answer. When every check passes, this file gets deleted: a system that still contains BOOTSTRAP.md is not set up.

## 0. Integrity — is the copy whole?

Before anything else, check that this core still has all its organs. A copy made through a file manager silently drops the **dotfiles** (they are hidden by default), and a core without `.claude/` is a core without skills and without guardrails — a failure you must catch now, not at step 5.

Every one of these must exist, here, at the root:

```
.claude/settings.json   .claude/hooks/guard.sh   .claude/hooks/lint.sh   .claude/skills/
.env.example   .gitignore   .mcp.json.example   CLAUDE.local.md.example
CLAUDE.md   SOUL.md   STRATEGY.md   log.md   knowledge-base/   templates/   inbox/
```

If anything is missing, **stop the ritual** and say so plainly. The near-certain cause: the *contents* of `mos/` were copied instead of the folder itself (a drag-and-drop, hidden files off). The fix is not to hand-craft the missing pieces — it is to recopy properly, from the manence clone:

```bash
cp -R manence/implementation/mos <container>/core
```

(Or, to repair in place without losing what has already been written: `cp -R manence/implementation/mos/. .` — the trailing `/.` is what carries the dotfiles.) Then restart the ritual. Also check `.claude/hooks/*.sh` are executable (`chmod +x` otherwise): some copy paths drop the bit.

## 1. Prerequisites first

Run `jq --version` and `python3 --version`. **Without jq, `guard.sh` fails closed: it blocks every tool action until jq is installed** — so this check comes before any other gesture. Without python3, `lint.sh` can't run; with python3 but no PyYAML, it runs in a degraded YAML mode and says so in its report. If something is missing, offer the install command for the human's OS and wait for their decision.

Then, version control. This folder must become **its own** repository: run `git rev-parse --git-dir` first. If it reports an existing repository — the manence clone you copied from, or a project of the human's — **stop the ritual** and tell the human: copy the default MOS to a fresh folder outside any repository, then restart there. A core entangled in another history is not a Manence OS (its journal, its commits and its guardrails assume they own the repository). Otherwise: `git init`, then a first commit of everything as it stands (`Init Manence OS`). The ritual itself must be traceable.

## 2. Language

Ask which language this system should work in: **English or French?**

- **French**: replace the English files with their `fr/` counterparts — `fr/CLAUDE.md` → `CLAUDE.md`, `fr/SOUL.md` → `SOUL.md`, `fr/STRATEGY.md` → `STRATEGY.md`, `fr/CLAUDE.local.md.example` → `CLAUDE.local.md.example`, `fr/.env.example` → `.env.example`, `fr/skills/<name>/SKILL.md` → `.claude/skills/<name>/SKILL.md` (all 6), `fr/templates/` → `templates/` (the workstream template folder is named `templates/chantier/` in French — remove the now-superseded `templates/workstream/`), `fr/knowledge-base/` → `knowledge-base/`, `fr/log.md` → `log.md`. Then remove `fr/` (`git rm -r fr`) and continue the conversation in French.
- **English**: remove `fr/` (`git rm -r fr`).

## 3. Interview

One question at a time, and use every answer — they become the system's identity:

1. **The name** of the project or activity. It replaces every `<project name>` / `<nom du projet>` gap, and derives the env prefix (uppercase, non-alphanumeric → `_`) that replaces `<PROJECT>` / `<PROJET>`.
2. **What this activity does**, in 2-3 sentences (→ CLAUDE.md, "What this project does").
3. **Who works here** — names, roles, constraints worth knowing (→ CLAUDE.md, Identity).
4. **The voice** — how should the assistant sound (a few words), and is there anything it should never say or promise (→ SOUL.md).
5. **The direction** — one to three goals at 12 months (measurable when possible), and 2-3 operational guardrails the human wants respected (→ STRATEGY.md, Goals and Guardrails).

Fill **every** `<...>` gap in `CLAUDE.md`, `SOUL.md`, and `STRATEGY.md`. Two kinds of gaps, two rules:

- **Identity facts** (names, numbers, goals, guardrails, never-says) come from the human only — a gap the answers don't cover gets a follow-up question, never an invention.
- **Structural sections the interview doesn't reach** (the pillars, the cadence, the metrics table, the registers of the voice): draft a proposal from what you've heard, read it back, and let the human confirm or amend it — a confirmed proposal counts as their answer. A table with nothing real to hold yet says so plainly ("none yet — the first connector will bring them").

Some placeholders fill from the setup itself, not the interview: the connectors map ("none yet"), the project-skills line ("none yet"), the Language line (from step 2). The env prefix also lands in `.env.example` — `<PREFIX>_PRODUCTION_ROOT=` keeps an empty value when the default location is used, but the `<PROJECT>`/`<PROJET>` token must be resolved.

## 4. Configuration

- **Production root.** Production (workstreams, disposable artifacts) lives *outside* this repository, **in the container** — the parent folder that holds this core and is, itself, the MOS (Spec §0). Propose the default: `../production/` next to this folder. Look at that parent before creating anything: if it is a home directory, a repository, or an otherwise crowded folder, this core was copied without its container — say so, and let the human choose (move the core into a container of its own, or name another location). Never scatter `production/` into a folder that is not the MOS. If accepted, create it with a short README stating: workstreams live here, outside git; one folder per domain, each with `in-progress/` and `done/`; durability goes through the `close-work` skill. If the human wants another location, create it there and record `<PREFIX>_PRODUCTION_ROOT=<path>` in `.env.example`'s documented slot.
- **Dates.** Stamp today's date into every remaining `<YYYY-MM-DD>` gap — `log.md`, `knowledge-base/log.md`, and the frontmatters of `SOUL.md` and `STRATEGY.md` — and the project name into `knowledge-base/index.md`.

## 5. Verify — run the checks, don't assume

- `bash .claude/hooks/lint.sh .` → must report **0 findings**.
- `grep -rn '<project name>\|<PROJECT>\|<nom du projet>\|<PROJET>\|<YYYY-MM-DD>' --exclude=BOOTSTRAP.md *.md knowledge-base/ .env.example` → must return **nothing** (this file quotes those tokens, hence the exclude).
- In `SOUL.md` and `STRATEGY.md`, `grep -n '<'` must return **nothing** — the interview-and-confirm covers every slot, prose gaps included. In `CLAUDE.md`, the only `<...>` left must be the structural notation of the routing table (`<domain>/in-progress/YYYYMMDD-<slug>/` and kin), never an identity gap.
- `CLAUDE.md`, `SOUL.md`, `STRATEGY.md` read back coherently (open them; a half-filled identity is a failed setup).

If a check fails, fix and re-run. Do not proceed on red.

## 6. Close the ritual

- Delete this file (`git rm BOOTSTRAP.md`).
- Commit: `First startup complete`.
- Tell the human, in their language: what their system is called, its language, where production lives — then hand them the first real gesture: *"say: **open a workstream for** ‹something you're actually working on this week›"*. The setup ends where the work begins.
