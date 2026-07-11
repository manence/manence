---
type: reference
title: Loops
description: Work runs in a loop (discover→plan→execute→verify→iterate). Bounded loops by default, maker≠checker, external verification, single before the agent group. A loop multiplies the judgment in your rubric, it does not create it.
tags: [ai-os, loops, verification, orchestration]
timestamp: 2026-06-30
---

# Loops

## What it is

The *execution* layer: **how work actually runs**. The building block is an "augmented LLM" that calls tools and reads feedback in a loop (the shared cycle **discover → plan → execute → verify → iterate**). Loops are *what you actually write* (the OS workflows, see [modele-ordinateur](modele-ordinateur.md)).

The reminder that deflates the myth: a loop **multiplies the judgment you put into your rubric, it does not create it**. Bad taste just ships faster. The vocabulary is new, the idea is not ("a cron job wearing a hat"); the real engineering increments are **structured feedback** and the **maker/checker separation**.

## How it works (at the model level)

### Bounded by default (open vs closed)
An *open* loop has a goal and loose constraints, good for **discovery**, but harsh on tokens, and it risks spinning without making progress. A *closed* loop has a defined path, an eval at each step, an **explicit stopping condition**. For a markdown+git+Claude Code setup, **closed loops are the default**; open-ended exploration is reserved for actual research.

A loop does not start without **three stops** set in advance: **success** (observable, binary), **failure** (retry cap / "stuck" signal), **budget** (turns / cost / time). Leaving out the failure stop means the loop spins; leaving out the budget stop means a slow failure gets expensive. You **never** let the agent edit its own stopping logic (that is a boundary, see [frontiere-dure](frontiere-dure.md)).

### Maker ≠ checker, and external verification (law L4)
The agent that produced the work is the **worst judge** of it, not through lying, but through blindness to its own mistakes. The verifier is **separate** ("it doesn't have to be smarter, just different") and above all **external**: it reports what a **script/test/judge** says, not what it believes. For non-code work (content, ops), you replace `exit 0` with a **fixed-rubric LLM-as-judge** plus an evaluation of the **final state** (judge the artifact, not each turn).

### Single before the agent group
A **single** loop handles most of the work. An **agent group** (orchestrator + subagents) is only warranted for **parallelizable breadth-first work** where independent threads exceed one window: it wins (+90% vs single on that specific shape) but at **~15× the tokens**. Avoid it for code or shared context. Key hygiene, even in single mode: the **executor subagent** (the main session speaks, the agent runs in its isolated context and returns only its conclusion).

## Why this discipline

Without bounds, a loop causes a **runaway loop** and **comprehension debt** (content in your repo that nobody has read). Without an external verifier, self-evaluation validates its own blind spots. The discipline does not cap what loops can do, it is what makes their multiplication **safe** instead of costly.

## → Source (verified)
[research/05 : Loops, vérification & orchestration](research/05-loops-orchestration.md) (open/closed, maker≠checker, stopping conditions, non-code evals, pragmatic solo defaults) and [research/02 : Anthropic](research/02-anthropic-architecture.md) (single before the agent group, few sharp tools).

## → Alongside (the how)
- [templates/agent.template.md](../implementation/mos/templates/agent.template.md): the two canonical subagents, **executor** (context hygiene) and **checker** (maker≠checker).
- The **guardrails** of the skills, e.g. the *success condition* of [`kb-ingest`](../implementation/mos/.claude/skills/kb-ingest/SKILL.md) ("no contradiction left silent").

Related concepts: [The double value](double-valeur.md) (every loop leaves a trace, L8) · [The hard boundary](frontiere-dure.md) (the stop and autonomy under guard) · [The computer model](modele-ordinateur.md) · [Manifesto](../Manifesto.md).
