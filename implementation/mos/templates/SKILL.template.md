---
name: <skill-name>
description: <when to use it and what it produces, one triggerable sentence; it is the only text the agent reads to decide whether to load this skill. Don't quote an everyday phrase that belongs to another gesture.>
---

# <Skill name>

<!-- Skeleton. The method (where each sentence lives, the four fates of a rule, "done", the routing test, the review) is the base skill `skill-craft`: load it before writing here. -->

## Purpose
<What this gesture accomplishes, in one line.>

## Context
<Links to the homes (AGENTS.md, the Spec, knowledge-base pages, the connector's page for a third-party system). Link, don't copy.>

## Procedure
<What must be true at each step, not the sequence of clicks. The role (fresh context, subagent, human GO) is written only where it is the mechanism of the step.>

## Inputs / outputs
- Input: <…>
- Output: <where the result goes>

## Done
- Success condition: <an observable state, verifiable from outside, one sentence>.
- Reading criterion: <at least one criterion a machine cannot tick, replayable identically>.
- Trace: <what the gesture leaves behind: About, log, knowledge base>.
- Stops: <destructive or irreversible action, scope change, information only the human holds; writing at a third party = GO, dry run, before/after, draft first (Spec §12), in one line that points at AGENTS.md>.
