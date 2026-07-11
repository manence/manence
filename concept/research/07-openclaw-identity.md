---
type: research
title: "OpenClaw: identity conventions in files"
description: "What Manence borrows from OpenClaw (the agent's identity as versioned markdown files, SOUL.md first) and where it diverges (STRATEGY.md instead of USER.md/AGENTS.md)."
tags: [ai-os, research, identity, openclaw]
timestamp: 2026-07-11
---

# OpenClaw: identity conventions (research brief)

## The project

[OpenClaw](https://github.com/openclaw/openclaw), Peter Steinberger's open source personal AI assistant ("Your own personal AI assistant. Any OS. Any Platform."), MIT-licensed, massively adopted (380,000+ stars by early 2026). Its naming history is eventful: released in late 2025 as **Clawdbot**, renamed **Moltbot** on January 27, 2026 (a trademark objection from Anthropic — "Clawd" too close to "Claude"), then **OpenClaw** on January 30, 2026 (a matter of taste, not law). Not to be confused with the game engine of the same name (the *Captain Claw* reimplementation): web searches routinely mix the two up.

## The convention: the agent's identity lives in markdown files

OpenClaw's workspace (`~/.openclaw/workspace/`, which the docs recommend backing up **to a private git repository**) loads a set of markdown files at the start of every session, each with a clear role:

| File | Role |
|---|---|
| `SOUL.md` | the **voice**: tone, opinions, humor, behavioral limits |
| `USER.md` | who the **human** is, to personalize responses |
| `AGENTS.md` | persistent operating rules across sessions |
| `IDENTITY.md` | the agent's name, energy, emoji |
| `TOOLS.md` | local tooling conventions |
| `MEMORY.md` + `memory/YYYY-MM-DD.md` | curated long-term memory + daily journals |
| `HEARTBEAT.md`, `BOOT.md`, `BOOTSTRAP.md` | optional rituals (periodic runs, restart, one-time init) |

The core idea, the one that matters to Manence: **identity is not configuration, it's versioned text** — readable, editable, owned by the user, loaded every session.

## What Manence borrows

- **`SOUL.md`, as is**: the voice file at the root of the core — same name, same role (layer 1). The borrowing is nominal and acknowledged.
- **`BOOTSTRAP.md`, as a gesture**: the one-time startup ritual that interviews the human, sets the system up, and deletes itself — Manence's first startup ([`mos/BOOTSTRAP.md`](../../implementation/mos/BOOTSTRAP.md)) adopts the pattern.
- **The spirit**: identity as root markdown files, versioned on the user's side and loaded at session start — the opposite of a setting hidden at a provider. It's the same bet as the rest of the framework (markdown + git, [the memory model](../modele-memoire.md)).

## Where Manence diverges

- **`STRATEGY.md` replaces the `USER.md` / `AGENTS.md` pair.** OpenClaw equips a *personal* assistant: the voice's companion file describes the human. Manence runs an *activity* (a MOS — one installation for one activity): the voice's companion is the **direction** — objectives, guardrails, sequence. Operating rules live in `CLAUDE.md` (the Claude Code convention, brief [02](02-anthropic-architecture.md)).
- **Who the human is lives in the Knowledge.** The team, its roles and constraints are facts of the knowledge base and of the `CLAUDE.md` identity (layers 1-2: "who you are"), not a dedicated root file. A deliberate divergence, revisited at every version of the framework.
- **Memory doesn't follow `MEMORY.md`.** The Manence model is the KB that holds true plus the append-only log, not accumulation-style memory ([the memory model](../modele-memoire.md)).

## Sources

- Official repo: https://github.com/openclaw/openclaw (license: https://github.com/openclaw/openclaw/blob/main/LICENSE)
- Docs, workspace and identity files: https://docs.openclaw.ai/concepts/agent-workspace · https://docs.openclaw.ai/concepts/soul · https://docs.openclaw.ai/reference/templates/AGENTS
- Naming history: TechCrunch (2026-01-27) https://techcrunch.com/2026/01/27/everything-you-need-to-know-about-viral-personal-ai-assistant-clawdbot-now-moltbot/ · Forbes (2026-01-30) https://www.forbes.com/sites/ronschmelzer/2026/01/30/moltbot-molts-again-and-becomes-openclaw-pushback-and-concerns-grow/ · CNBC (2026-02-02) https://www.cnbc.com/2026/02/02/openclaw-open-source-ai-agent-rise-controversy-clawdbot-moltbot-moltbook.html
- Workspace file walkthrough: R. Capodieci, https://capodieci.medium.com/ai-agents-003-openclaw-workspace-files-explained-soul-md-agents-md-heartbeat-md-and-more-5bdfbee4827a
