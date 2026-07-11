---
type: reference
title: The memory model
description: The two questions (static/dynamic · what) that yield the 4 CoALA memory types, their lightweight home (markdown + git), bi-temporal freshness, and the threshold beyond which a graph (Graphiti) earns its place.
tags: [ai-os, memory, coala, graphiti]
timestamp: 2026-07-02
---

# The memory model

## What it is

The way to decide **where each thing you write down lives**. Two questions are enough to place any file:

1. **Static or dynamic?** What rarely changes (identity, rules, facts) **vs** what piles up and goes stale (events, ideas, drafts).
2. **What?** *who* I am / *what is true* / *how* to do something / *what happened*.

These two axes reconstruct the **4 memory types** from cognitive science, formalized for LLMs by **CoALA** (adopted by Letta, mem0, LangChain):

| Type | Holds | Static/dynamic | Lightweight home |
|---|---|---|---|
| **Procedural** | how to do things (skills, routines) | static | `SKILL.md` / `CLAUDE.md` |
| **Semantic** | what is true (facts, brand, product) | static-but-evolving | markdown notes (the wiki) |
| **Episodic** | what happened, and when | dynamic | dated markdown + git log |
| **Working** | the reasoning in progress | ephemeral | the window itself |

These 4 types **underpin layers 2, 3, 4 and 6** of the framework (knowledge, capability, execution, memory). Layers 1 (identity), 5 (automation) and 7 (connection) do **not** come from the memory model: they belong to the [architecture](architecture-hexagonale.md) (what the core owns, what it automates, what it plugs in).

## How it works

### Two clocks, not one (freshness)
A fact can expire. The framework separates **two temporal axes** (Graphiti's bi-temporal idea), in a lightweight form:
- **"when I learned it"**: free, it's the git history (the commit).
- **"from/until when it holds true"**: the frontmatter (`timestamp`, `valid_from`, `superseded_by`).

Guiding rule: you **invalidate, you don't overwrite**. When a fact changes, you close its validity and open a new one: the history stays queryable, like an edge in a temporal graph.

### Working memory = memory management
The window is the RAM (see [modele-ordinateur](modele-ordinateur.md)). You keep it clean with the tactics Anthropic names: **compaction** (distill into a summary), **structured note-taking** (write to external files — exactly the markdown approach), **sub-agent isolation** (each with its own context, returning only its conclusion).

### The optional human view (the graph)
Semantic memory is a markdown folder; opened in Obsidian, it becomes a **graph of links** you use to *explore* (clusters, orphans, gaps). Division of labor: **the agent writes (it searches within the files), you explore**, a human layer laid over the knowledge, not something the machine needs.

## Why the lightweight approach is enough (and its threshold)

Markdown + git covers **procedural, episodic and working** right away, and covers **semantic + bi-temporal** up to a precise threshold: **volume of facts × rate of contradiction × need to traverse relationships**. As long as you have dozens of hand-kept facts that move slowly, the lightweight approach wins (zero infra, clean diffs, free audit trail). You reach for a **temporal graph (Graphiti/Zep)** only when many overlapping facts change often and you need to ask "what we believed on a given date" at scale, **not before**. It's the same discipline as "single agent before the group of agents": you add infra only when reality demands it.

## → Source (verified)
[research/03: Memory architectures](research/03-memory-architectures.md) (CoALA, bi-temporal Graphiti, Letta/mem0, lightweight-vs-heavy guide) and [research/02: Anthropic](research/02-anthropic-architecture.md) (context engineering = memory management).

## → During (the how)
- [Spec §5: Static vs dynamic](../implementation/Spec.md) and [§6: Status, freshness & expiry](../implementation/Spec.md): the fields and the invalidation mechanics.
- [Spec §10: Deciding: markdown+git or heavy infra?](../implementation/Spec.md): the threshold's decision table.

Related concepts: [The computer model](modele-ordinateur.md) · [The wiki method](methode-wiki.md) (semantic memory) · [The OKF format](okf.md) · [Double value](double-valeur.md) (the episodic feeds on the loops) · [Manifesto](../Manifesto.md).
