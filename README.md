---
type: project
title: Manence
description: "The work system that makes your AI reliable on long-running projects. The knowledge that holds true, the real world wired in, the gesture carried through: markdown + git — code and templates open source (MIT), doctrine free to read and share (CC BY-NC-SA) — installs in one conversation."
tags: [ai-os, knowledge-management, claude-code, method]
timestamp: 2026-07-09
---

# Manence

> 🌐 **Français** : [lire en français](README.fr.md) — Manence was **born in French**. The doctrine now lives in English; a French presentation set ships with the repo (README, [Manifesto](Manifesto.fr.md), [QUICKSTART](QUICKSTART.fr.md)), and your own system installs in French if you ask.

**Manence makes your AI reliable on long-running projects.** An AI, whether in chat or agentic mode, knows only its context: what it has in front of it right now, nothing else. So whatever needs to last needs a place that outlives the session — and a way of working that keeps that place true. Manence is both: a work system where **every exchange does the work *and* tidies the system**. Order as a by-product, not a chore.

## The problem

With an AI, it's great at the start. It understands fast, produces fast, gets things right. Then the project runs on: conversations grow longer, drafts end up looking like decisions, mistakes you'd fixed come back.

**It's not that the AI forgets (it has a memory): it's that everything piles up and nothing gets put away.** An AI knows only its context, what it loads in the moment; the larger the corpus grows, the harder it is for the AI to grab the right piece at the right time. A chat is subject to this. Agentic work, where the AI reads and writes your files continuously, experiences it tenfold.

The problem is neither your prompt nor your model: it's that there's no system around it. And "you should tidy up" is no answer: tidying treated as a chore always loses to what's urgent. Companies have been paying for internal wikis for twenty years; they're never up to date.

## The answer: the system does the tidying

Manence is a work system where **working already produces order**. It rests on three organs:

1. **The knowledge that holds true.** A knowledge base where what's written is true: your products, your rules, your validated decisions. One fact, one home; never polluted by the day's work.
2. **The real world, wired in.** All work starts in a **workstream**, in its own space, with its context already linked, connected to your real tools (CRM, analytics, site, repositories). Your AI works on your real data, not on stale memories.
3. **The gesture carried through.** The rule that holds it all together: every exchange does the work **and** updates the system.
    - A decision made? Recorded, with its why.
    - A piece of information changed? The base is updated.
    - A mistake spotted? The fix is created, explained.

Then the curve reverses: every hour of work leaves the system healthier than it found it, and your AI always starts again from what's correct, the best context at the best moment. Tidying isn't a task: it's a by-product. On old Windows machines, you had to defragment the disk, a chore you'd put off for months; on Linux, the system tidies as it writes, and the notion of a defrag doesn't exist. That's the logic of Manence.

And you own it all: the code and templates are open source (MIT) — what the installation copies into your project is yours, no strings attached — and the doctrine is free to read, share, and adapt ([CC BY-NC-SA](LICENSE-docs.md)). Markdown + git, in plain text, at home: the AI model is an interchangeable component, you switch to an open source, sovereign, or self-hosted AI without rewriting a thing. *(A ChatGPT or Claude "project," by contrast, lives on their side: exportable, never truly yours.)*

## The mental model: you're running an OS

The framework builds on Karpathy's model (*Software 3.0*): the AI model is the **processor**, context the **RAM** (scarce and expensive, to load at the useful minimum), your files (markdown + git) the **disk**, skills the **programs**. Organizing your projects for the AI means designing the disk and programs of an OS whose RAM is tiny. The full plan: [Manifesto.md](Manifesto.md).

## Installation

Get the framework, copy the default MOS, and let the agent finish the job:

```bash
git clone https://github.com/manence/manence.git
cp -R manence/implementation/mos ~/my-project
```

Then open Claude Code in the new folder and say: **"run my first startup"**. The agent reads `BOOTSTRAP.md` — the one-time ritual: it asks your language (English or French), interviews you, fills in your identity files from your answers, checks the guardrails, then deletes itself. Installing the system is already using it. Details: [QUICKSTART.md](QUICKSTART.md).

## The proof: it already runs on real work

This framework isn't a theory: it was built in production and runs there every day — on **its author's own three activities**, stated plainly. Proof of practice, not yet of adoption:

- **a SaaS company** (SMB, 18 employees): strategy, CRM, lead pipeline, support, daily monitoring, all journaled;
- **Manence itself**: this repository, its doctrine, and the [manence.ai](https://manence.ai) site are built and run under Manence;
- **a media outlet**: [declic.media](https://declic.media), 122 articles in three languages, complete editorial workflows.

A real trace, as it sits in the first one's journal — one morning, a lead lands in the CRM labeled "DIRECT, no source"; the system doesn't swallow it:

```
## [2026-06-14] fix | Web lead attribution
Lead "DIRECT, no source": CRM × analytics cross-check
→ true origin reconstructed: Brave Search, ~11 am (tracker blocked by an adblocker).
Measured: 39% of web leads (28/71) mislabeled for weeks.
Analysis delivered. Fix deployed the same day.
```

A real example. Six months after a workstream closes, someone asks: "why did we rule out option B again?" No need to dig up the conversation: the workstream's folder says who decided what, what was ruled out, and why. The AI reads it and answers in thirty seconds, with sources. Six months on, you understand what happened, not just the outcome. That's the gesture carried through.

## What Manence is not

- **One more "memory."** Memory layers store everything that passes through: accumulation sold as progress. Manence does the opposite: it keeps a place where what's written is true, and protects it from the rest.
- **A bundle of connectors.** An MCP grants access; Manence gives you a way of working with that access. Isolated connectors can't see that an absurd figure in the CRM is glaring once you set it against the same client's accounting.
- **A well-configured assistant.** A raw agent is powerful, but nothing in it structures duration: no opening or closing of a project, no log of decisions, no boundary between the true and the draft. Manence is that structure, on top.

## Portable, by construction

The examples in this repository use **Claude Code**, the most direct path today. But your system doesn't depend on it: switching to another agent (Codex, Gemini CLI, and the equivalents that keep appearing) comes down, in the main, to one or two identity files (`CLAUDE.md` → `AGENTS.md`, `GEMINI.md`…). **Tested** adaptation guides, platform by platform, are the framework's next workstream.

## The map

- **[QUICKSTART.md](QUICKSTART.md)**: the way in if you're new (who it's for, what it is, 3 moves).
- **[Manifesto.md](Manifesto.md)**: *the why*. The synthesis of the framework (mental model, 7 layers, hexagonal architecture, 9 laws, maturity) + the index of concepts. **Start here.**
- **[concept/](concept/index.md)**: each idea unfolded into a file, + [`research/`](concept/research/index.md) (the verified sources: Karpathy, OKF, Anthropic, PKM, loops, JP Noto's LIVING REFERENCE, credited private source).
- **[implementation/](implementation/index.md)**: *the how*, with [Spec](implementation/Spec.md) (the rules), [Implementation](implementation/Implementation.md) (the playbook), [`mos/`](implementation/mos/BOOTSTRAP.md) (the default MOS, ready to copy: identity files, the 6 base skills, hooks, the startup ritual), and [`example/`](implementation/example/index.md) (a minimal KB that runs).
- **[CHANGELOG.md](CHANGELOG.md)**: the versions.

## The name

*Manence*, from the Latin *manere* (to remain), the root of **permanence**, **remanence**, and **immanence**: what stays when the conversation clears, what persists when the session closes, what remains with you when the model is unplugged. *Manence, like permanence without the “per”.*

## Lineage and credits

Manence synthesizes and builds tooling around ideas whose sources are named and documented in [`concept/research/`](concept/research/index.md): the computer model of **Andrej Karpathy** (*Software 3.0*), the **OKF** spec (Google), the **CoALA** memory model, the context-engineering practices of **Anthropic**, the identity conventions of the open source project **OpenClaw**, and **LIVING REFERENCE / CANON FLOTANT** by **JP Noto** (dual value, traced validation, status cycle). The hexagonal framing and the 9 laws are original syntheses of the framework.

Created by **Alexandre Noto** ([Alex Déclic](https://www.youtube.com/@alexdeclic)), a SaaS executive who runs his own company with this framework.

## Licenses

Dual license, see [LICENSE](LICENSE) and [LICENSE-docs.md](LICENSE-docs.md):

- **Code and templates** (`implementation/mos/`, `implementation/example/`): **MIT**. What you copy into your project **is yours, no strings attached**.
- **Doctrine** (README, QUICKSTART, Manifesto, `concept/`, Spec, Implementation): **CC BY-NC-SA 4.0**. Free to read, share, and adapt with attribution; **commercial use of the text is prohibited** (reselling this doctrine in a paid course, for instance). For a commercial license: contact via [manence.ai](https://manence.ai).

---

**With an AI, the beginning is great. With Manence, it's only the beginning.**

*Site: [manence.ai](https://manence.ai) · Canonical repository: [github.com/manence/manence](https://github.com/manence/manence)*
