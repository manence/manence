---
type: reference
title: The computer model
description: "An LLM is a new kind of computer (Karpathy, Software 3.0): CPU/RAM/disk/programs/workflows. The mental model the whole framework rests on: organizing your projects means designing this OS."
resource: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
tags: [ai-os, software-3, karpathy, mental-model]
timestamp: 2026-06-30
---

# The computer model

## What it is

The framework's starting premise: **you don't "use" AI, you run an operating system (OS).** Karpathy (*Software 3.0*, "LLM as OS") argues that an LLM is a **new kind of computer** whose parts map directly onto familiar ones:

| Classic hardware | AI counterpart | What it means in practice |
|---|---|---|
| **CPU** | the model you run | you leave it alone |
| **RAM** | the context window | scarce, valuable, kept to the **useful minimum** rather than filled |
| **Disk** | your files (markdown + git) | the real memory; what you organize |
| **Programs** | skills (stored capabilities) | what you install |
| **Workflows** | loops (the sequence that runs) | what you actually write |

Hence the framework's claim: **organizing your projects for AI means designing the disk and programs of an OS whose RAM is tiny and expensive.**

## How it works (the consequences that guide the design)

The model isn't a decorative metaphor: each mapping dictates a discipline.

- **RAM is scarce → context engineering.** Anything "on disk" (notes, docs, databases) shapes the reasoning only if you **load** it into the window on purpose. The window is not a bag: overfilling it degrades accuracy (*context rot*). You aim for the **smallest set of high-signal tokens** (law L1), pulled in **just-in-time** rather than all preloaded.
- **The disk is the real memory → you organize it.** What lasts lives not in the chat but in versioned files. That is what the framework is about: what goes where (the 7 layers).
- **Programs get installed → skills.** You store a reusable capability once and load it when needed, instead of re-explaining it every time.
- **Workflows are what you write → loops.** The real engineering work is the sequence that runs (discover→plan→execute→verify), not the isolated prompt.
- **The CPU is replaceable → independence from the model.** "You leave it alone" has a corollary: like a processor you swap without throwing away the disk, the model is an **interchangeable part**. Everything else (identity, knowledge, memory, skills) is in plain text (markdown + git) and **belongs to you**. You move from a proprietary model to an open-source, sovereign, or self-hosted AI **without rewriting anything**. That is the difference between an OS you *own* and a "project" hosted by a vendor: the latter is at best exportable, never really yours. This decoupling is the reason to separate the layers instead of handing everything to one integrated assistant.

Karpathy's corollary: more and more of your token throughput goes into **working with knowledge** (not code), which is why knowledge is handled *as* code (see [methode-wiki](methode-wiki.md)).

## Why this model rather than another

Because it **puts everything in its place**: every question of organization ("where does this go?", "why is my prompt overflowing?", "do I need a skill?") becomes a question of OS architecture, with a determinate answer. Without this framing, you reinvent an organization for each project; with it, you design a single system that holds up over time.

## → Source (verified)
[research/01: Karpathy & practitioners](research/01-karpathy-practitioners.md) (Software 3.0, gist `llm-wiki.md`) and [research/02: Anthropic architecture](research/02-anthropic-architecture.md) (*context rot*, just-in-time context, "simplest first").

## → Alongside (the how)
- [Spec §9: Context budget](../implementation/Spec.md): the concrete rules for "RAM" (`CLAUDE.md` < 200 lines, `@import`, `/clear`).
- The **physical layout** in the [Manifesto](../Manifesto.md): how disk/programs translate into a directory tree.

Related concepts: [The memory model](modele-memoire.md) (what you store on disk) · [The loops](loops.md) (the workflows) · [The wiki method](methode-wiki.md) (knowledge = code) · [Manifesto](../Manifesto.md).
