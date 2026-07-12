---
type: guide
title: "Get started: Manence in 3 moves"
description: "The express entry point to the framework: who it's for, what it gives you, and the first three moves to get going."
tags: [ai-os, quickstart, onboarding]
timestamp: 2026-07-02
---

# Get started with Manence

> 🌐 **Français** : [lire en français](QUICKSTART.fr.md).

**Who is it for?** Anyone who has lived through the curve: an AI impresses you at first, then the project runs on, everything piles up, and your trust erodes. Manence is built for working with an AI agent (Claude Code) on long-running projects.

**What it gives you, in one sentence:** a way of working where the discipline is held by the AI itself: every exchange does the work **and** brings the system up to date; the whole thing running like an **operating system** (versioned files = disk, context = RAM, skills = programs).

## Prerequisites

- **git**, to fetch the framework and version your system.
- [Claude Code](https://claude.com/claude-code), the agent the framework works with.
- **jq** and **python3**, used by the safety hooks (`guard.sh`, `lint.sh`). The first startup checks for them and offers to help. Without jq, `guard.sh` **fails closed**: it blocks tool actions until jq is installed (better mute than blind). Without python3, the lint can't run; with python3 but no **PyYAML**, it runs in a degraded YAML mode and its report says so. On Windows, the hooks are bash scripts: [Git for Windows](https://git-scm.com/download/win) provides the bash they need.

## The first 3 moves

1. **Read the [Manifesto](Manifesto.md) (5 min).** The single thread: the mental model, the 7 layers, the 9 laws. It's the one document you need to grasp the framework; each idea then unfolds in [`concept/`](concept/index.md).

2. **Copy the default MOS.** Get the framework, then copy the ready-made system wherever yours should live:

   ```bash
   git clone https://github.com/manence/manence.git
   cp -R manence/implementation/mos ~/my-project
   ```

   (Copying the folder in your file manager works just as well.) Everything is in the copy: identity files, the routing table, 6 base skills, safety hooks, knowledge base — plus `BOOTSTRAP.md`, the one-time startup ritual.

3. **Run your first startup.** Open Claude Code inside the new folder (`cd ~/my-project`, then `claude`) and say: **"run my first startup"**. The agent reads [`BOOTSTRAP.md`](implementation/mos/BOOTSTRAP.md) and takes it from there: it asks your language (**English or French**), interviews you — name, what the activity does, who works here, the voice, the direction — fills in your identity files from your answers, checks the guardrails, verifies everything, then deletes the ritual file. That's also your first lesson: **skills are invoked by talking to the agent**, not on a command line. When it's done, hand it real work: *"open a workstream for ‹something you're working on this week›"*.

> **Bonus**: open the project folder in [Obsidian](https://obsidian.md) (free) — the relative links draw the **graph** of your knowledge: clusters, orphans, and gaps, all visible at a glance. An optional human view, never a dependency (see [the memory model](concept/modele-memoire.md)).

> Next: the concrete rules are in [Implementation](implementation/Implementation.md), the verified sources in [`research/`](concept/research/index.md).
