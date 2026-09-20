# Get started with Manence

> 🌐 **Français** : [lire en français](QUICKSTART.fr.md).

**Who is it for?** Anyone who has lived through the curve: an AI impresses you at first, then the project runs on, everything piles up, and your trust erodes. If your work with an AI hasn't lasted a few weeks, you may not need this yet. If it has, and you trust it a little less than at the start: this is for you. Manence is built for working with an AI agent (Claude Code) on long-running projects.

**What it gives you, in one sentence:** a way of working where the discipline is held by the AI itself: every exchange does the work **and** brings the system up to date; the whole thing running like an **operating system** (versioned files = disk, context = RAM, skills = programs).

## Prerequisites

- **git**, to fetch the framework and version your system.
- [Claude Code](https://claude.com/claude-code), the agent the framework works with.
- **bash**, the language of the safety hooks. Already there on macOS and Linux. On Windows, [Git for Windows](https://git-scm.com/download/win) provides it — install it **first**, run the commands below from **Git Bash**, and check that `C:\Program Files\Git\bin` is on the PATH (the installer does not always add it).
- **jq** and **python3**, used by the safety hooks (`guard.sh`, `lint.sh`). The first setup checks for them and offers to help. Without jq, `guard.sh` **fails closed**: it blocks tool actions until jq is installed (better mute than blind). Without python3, the lint falls back to a degraded line-by-line mode and its report says so. Windows note: the python.org installer creates `python.exe` but no `python3.exe`, and Windows 11 ships a `python3.exe` stub that opens the Microsoft Store — the lint probes for a *runnable* python3 and degrades cleanly otherwise.
- **Tested where it counts:** the full install path — clone, container, BOOTSTRAP ritual, hooks, the guard's fail-closed path included — is exercised on **macOS and Linux** (Ubuntu), and a **complete real install has been run on Windows** (via Git Bash, 2026-08-06); the Windows pitfalls that run surfaced are fixed in this version.

## The first 3 moves

1. **Install the default MOS.** One command creates the container and copies the core *with its dotfiles*:

   ```bash
   curl -fsSL --proto '=https' --tlsv1.2 https://manence.ai/install.sh | bash
   ```

   Default location: `~/manence`. Another folder: `| bash -s -- ~/my-activity`. From a clone: `bash manence/install.sh`. The script checks the copy is whole before it stops — the failure mode it exists to prevent is a file-manager drag that silently drops `.claude/`.

   Two folders, two jobs. The **container** (`~/manence/`) holds the **core** (`core/` — the system and the knowledge, versioned) and, once the first setup has created it, `production/` alongside (your working artifacts, outside git). Running several MOS? Pass a different folder per activity.

   Manual path, if you want to see each gesture: `git clone` then `mkdir ~/my-activity` then `cp -R manence/implementation/mos/. ~/my-activity/core/` — copy the folder's *contents including dotfiles* (`mos/.`, the trailing `/.` is what carries them). Prefer the script.

2. **Run your first setup.** Open Claude Code inside the core (`cd ~/manence/core`, then `claude`) and say: **"run my first setup"**. The agent reads [`BOOTSTRAP.md`](implementation/mos/BOOTSTRAP.md) and takes it from there: it asks your language (**English or French**), interviews you — name, what the activity does, who works here, the voice, the direction — fills in your identity files from your answers, checks the guardrails, then deletes the ritual file. That's also your first lesson: **skills are invoked by talking to the agent**, not on a command line. When it's done, hand it real work: *"open a workstream for ‹something you're working on this week›"*.

3. **(Optional) Read the [Manifesto](Manifesto.md).** The single thread: the mental model, the 7 layers, the 9 laws. Not required to start; it's the document that makes the system make sense. Each idea then unfolds in [`concept/`](concept/index.md).

> **Bonus**: open the project folder in [Obsidian](https://obsidian.md) (free) — the relative links draw the **graph** of your knowledge: clusters, orphans, and gaps, all visible at a glance. An optional human view, never a dependency (see [the memory model](concept/modele-memoire.md)).

> Next: the concrete rules are in [Implementation](implementation/Implementation.md), the verified sources in [`research/`](concept/research/index.md).
