---
name: <skill-name>
description: <when to use it, one triggerable sentence. This is what the agent reads to decide whether to load this skill.>
---

# <Skill name>

## Purpose
<What this skill accomplishes, in one line.>

## When to use it
<Trigger conditions.>

## Procedure
1. <step>
2. <step>
3. <step>

## Inputs / outputs
- Input: <…>
- Output: <where the result goes, e.g. `knowledge-base/`, the current workstream (path passed as input)…>

## Guardrails
- Success condition: <one sentence, verifiable>.
- Limits: <max-turns / budget / stop if stuck>.
- Verification: external (script/test/judge), not self-assessment.
- Reading gate: <at least one criterion a machine cannot tick, next to the mechanical ones: a rereading under constraint, phrased so that anyone replays it identically (e.g. "hide the subtitles: the sequence of titles must stand on its own"). Any quality criterion left implicit disappears within a few dozen runs; a production skill writes at least one, and points at the copies to reread — with their path — for each dimension it means to preserve.>
- <If this skill WRITES at a third party (creating, publishing, sending): an explicit GO before writing; a dry-run (`validateOnly`) when the API offers one; before/after logged in the deliverable; create it paused/as a draft first, activate as a second step (Spec §12).>
