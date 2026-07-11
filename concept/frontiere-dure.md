---
type: reference
title: The hard boundary
description: A hard constraint (security OR confidentiality) runs through a physical boundary, never through a flag an agent can ignore. Law L9, hard vs soft, which unifies blocking actions (hook/permission) and isolating data (separate repo + git).
tags: [ai-os, security, confidentiality, L9]
timestamp: 2026-07-02
---

# The hard boundary

## What it is

The distinction people most often get wrong: **"soft" suggests, "hard" prevents.** The framework states it as **law L9**: *a hard constraint (security OR confidentiality) = a physical boundary, never a flag.*

- **Soft** (`CLAUDE.md`, the `rules/`): these only **suggest**. The agent reads them, tries to follow them, and **can depart from them**. Good for preferences and conventions; **useless for actually forbidding something**.
- **Hard**: a boundary the agent **cannot cross**, whatever it decides.

The common mistake is to write "never do X" in a context file and believe that guarantees it. It does not: it is a suggestion.

## How it works (two kinds of constraint, two boundaries)

### Actions → hook / permission
To **block an action** whatever the agent decides: a **`PreToolUse` hook** that returns `permissionDecision: "deny"`, or `permissions.deny` in `.claude/settings.json`. The hook intercepts the call *before* it runs and can refuse or rewrite it; this is deterministic and does not depend on the model's judgment. Examples: never `rm -rf`, never push to `main`, no sending without approval.

### Data → separate repo + git access
So that a piece of data **never leaks**: no `visibility:` field (which an agent can read and ignore), but a **separate repo**. **Clearance = who can clone.** This is the *confidentiality* side of the same law, and it is exactly the **confidentiality by composition** of the [hexagonal architecture](architecture-hexagonale.md): **additive** parts (shared bundle + confidential delta), plugged in according to role.

**Zero-knowledge (the subtle trap).** The boundary also protects the *knowledge that a thing exists*. The shared core must therefore **not mention** the confidential adapter: no "confidential connector: …" line in its `CLAUDE.md`, no entry in its log, no trace in its history. The adapter **describes itself** (its own `CLAUDE.md`) and appears only once it is plugged in by whoever can clone it. An employee who opens the core does not even know the sensitive folder exists.

**What you share is a release, not the repository.** An operational corollary: the working tree and git history can carry sensitive material (a migration, logs, drafts, a copy made by mistake). What you *share/deploy* is a **curated subset** (the static layer), never the raw repo. Concretely: you ship a **clean release** (`git clone --depth 1` or a squashed commit), not the operational history. *(Real case: a confidential file copied by mistake ended up in the pushed history; the fix was to rebuild a clean release, not to patch the repo.)*

### Writing outside → the guardrail for external writes
Reading the outside world is **free** (you query it and persist only the conclusion). **Writing to a third party** (creating a campaign, publishing, sending) engages the real world: the guardrail comes down to four reflexes plus one boundary.

The four reflexes (the protocol):
1. an **explicit GO** from the operator before any write;
2. **`validateOnly`/dry-run** when the API offers it, before the real write;
3. a **before/after record** in the deliverable (the state of the third-party system before the action, and after);
4. **create it paused/as a draft first**, then activate it as a **second step**.

The boundary (the **hard** side, the one that belongs to L9): **separating read and write credentials**. The measurement bundle stays **read-only**; write capability is added **deliberately, by decision**, never by default. An agent that holds only the read key *cannot* write, whatever it decides. *(Field experience: creating and activating real objects at an ad network, driven by the agent, with no incident, thanks to these reflexes.)*

### The single thread
Both cases are the **same idea**: a constraint that must *actually* hold takes shape in the system (a hook, a repo boundary), not in text the model is free to interpret. L9 unifies security (actions) and confidentiality (data) under this single principle.

## Why it is non-negotiable

An autonomous agent acts; sooner or later it will encounter the dangerous command or the sensitive data. If the only barrier is a sentence in `CLAUDE.md`, it will give way, not out of malice, but through plausible reasoning that works around it. The physical boundary turns "I hope it won't do that" into "it can't." This is also what makes autonomy *safe*: you can leave the rest soft precisely because the hard part is locked down elsewhere.

## → Source (verified)
[research/02: Anthropic](research/02-anthropic-architecture.md) grounds the *actions* side: `PreToolUse` hooks **block/rewrite** a call deterministically, where context (soft) only suggests. The **L9 formulation** (unifying security and confidentiality under "a hard constraint = a physical boundary") is a **synthesis specific to the framework**; no research note carries it as such.

## → Alongside (the how)
- [Spec §12: Security & confidentiality: hard vs soft](../implementation/Spec.md): the full rule.
- [templates/hooks/guard.sh](../implementation/mos/.claude/hooks/guard.sh) (`PreToolUse` blocking) + [templates/settings.example.json](../implementation/mos/.claude/settings.json): the guardrail ready to plug in.

Related concepts: [The hexagonal architecture](architecture-hexagonale.md) (confidentiality = composition) · [The loops](loops.md) (stopping a loop is a boundary) · [Manifesto](../Manifesto.md).
