---
type: research
title: "Loops, verification & orchestration: a skeptic's brief"
description: The discover→plan→execute→verify→iterate cycle, open vs closed, mono vs fleet, maker≠checker, stopping conditions, and the pragmatic defaults for a solo operator.
tags: [ai-os, research, loops, orchestration]
timestamp: 2026-06-30
---

# Loops, verification & orchestration (research brief)

## The loop model

The shared cycle: **discover → plan → execute → verify → iterate** (Anthropic: the building block is an "augmented LLM" that calls tools and reads the feedback in a loop). The distinction that carries weight: **open vs closed (bounded)**. An *open* loop has a goal and loose constraints — good for discovery, brutal on tokens, prone to thrashing. A *closed* loop has a defined path, a per-step eval, and an explicit stopping condition; results are scored against the same rubric on every run. For a markdown+git+Claude Code setup, **closed loops are the default**; keep open exploration for genuine research.

**Mono vs fleet**: a single loop handles most of the work. A *fleet* (orchestrator plus specialist sub-agents) only pays off on **parallelizable breadth-first** work where the independent threads exceed one context window: Anthropic's Research system beats mono Opus by 90.2% on exactly this shape — but at roughly 15× the tokens.

**Hype vs substance**: the cycle is real engineering; the vocabulary is not new ("a cron job wearing a hat"). The real gains: **structured feedback** and the **maker/checker split**. The hype is letting people believe loops improve judgment — they don't. A loop "multiplies the judgment you put into the rubric"; bad taste just ships faster.

## Verification

**Maker ≠ checker.** The agent that produced the work is the worst judge of it — not through dishonesty, but through blindness to its own mistakes. Use a *separate* checker; it "doesn't have to be smarter, just different." Above all: **external validators beat self-assessment**. The agent reports what a script or test says, not what it believes. Three levels: action (the write or command succeeded), iteration (a light progress check), terminal (the full success gate).

**Stopping conditions** that are observable, binary, and bounded ("the tests in `/tests` pass, exit 0, no files outside `/src`"). Always all three: success, failure (retry cap, a "stuck" signal), and budget (turns/cost/time). Drop the failure-stop and you get thrashing; drop the budget-stop and a slow failure turns expensive. Never let the agent edit its own stopping logic.

**Evals for non-code work** (content, research, ops): you lose `exit 0`, so use **LLM-as-judge** with a fixed rubric (accuracy, citations, completeness, source quality) → a 0–1 score plus pass/fail, together with **final-state evaluation** (judge the finished artifact, not each turn). Start with about 20 real cases; the first few prompt fixes often jump from 30% to 80%.

## Automation & triggers

Automate only when **all three** hold: repetitive/frequent, "done" is objectively checkable, and value exceeds the floor cost. Triggers: **cron / scheduled agents** (a "heartbeat" that runs until a stopping condition), and **hooks** (on-file-change, on-commit, on-PR) to "run until the tests pass." The heartbeat is the honest core; the rest is feedback quality. Automating too early buys you a runaway loop and **comprehension debt** (content in your repo that nobody has read).

## Orchestration patterns & failure modes

Orchestrator-worker: the lead plans → spawns 3–5 specialists in parallel → synthesizes. **Git worktrees**: each parallel agent gets its own checkout/branch (no races over files). Failure modes (observed by Anthropic): over-spawning for trivial requests; duplicated work from vague specs; recursive spawning that 10×'s a bill already at 15×; coordination that breaks down on interdependent tasks. Mitigations: a *specific* objective plus a per-sub-agent output format; have them **write to shared files and return a pointer** rather than dumping through the lead's context; resume-from-checkpoint.

## Pragmatic defaults (solo operator)

1. **Bounded mono loop first.** If a task needs more than 30 turns, the scope or the success condition is wrong: break it down.
2. **A one-sentence success condition before you launch**, held in immutable code or prompt.
3. **External verification** (script/test/judge), never self-assessment.
4. **Three hard limits from day one**: `--max-turns` (15–20), a $/token cap, and no-progress detection.
5. **Model tiering**: route reads and diffs to Haiku (60–80% cheaper).
6. **Connectors are the hands.** MCP turns a "suggested reply" into "work done," but each tool = one distinct goal plus a clear description.
7. **Fleet only** for breadth-first research that is worth the 15×.

## Sources
- https://www.anthropic.com/research/building-effective-agents
- https://www.anthropic.com/engineering/multi-agent-research-system
- https://code.claude.com/docs/en/agent-sdk/agent-loop · /agents
- https://www.firecrawl.dev/blog/loop-engineering
- https://www.channel.tel/blog/claude-code-subagents-orchestrator-pattern
- https://claudefa.st/blog/guide/development/worktree-guide
