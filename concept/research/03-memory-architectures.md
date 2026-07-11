---
type: research
title: AI agent memory architectures
description: The CoALA taxonomy, temporal memory (Zep/Graphiti), Letta/mem0, and the decision guide for markdown+git versus heavier infrastructure.
tags: [ai-os, research, memory, graphiti]
timestamp: 2026-06-30
---

# Memory architectures (research brief)

## Taxonomy

Two orthogonal cuts. **Static vs dynamic**: static is configuration and identity that rarely changes (persona, rules, voice); dynamic is state that accumulates and goes stale (learned facts, events, refined skills).

The useful split comes from cognitive science, formalized for LLMs by **CoALA** (arXiv:2309.02427) and adopted by Letta, mem0, and LangChain:

| Type | Holds | When/where | Lightweight home |
|---|---|---|---|
| **Working / short-term** | live reasoning (the window itself) | now | the prompt; compaction |
| **Semantic** | facts, definitions, policies, *what is true* | timeless | markdown notes / KV / graph |
| **Episodic** | events, decisions, "what happened" | dated | append-only markdown + git log |
| **Procedural** | how to do things: skills, routing, tool logic | timeless | SKILL.md / CLAUDE.md / code |

## Temporal memory (Zep / Graphiti)

**Graphiti** (Zep's open source engine): an LLM extracts entities (nodes) and relations (edges) into a graph where **every edge carries temporal metadata**. It is **bi-temporal**, with two timelines across four timestamps: `valid_at`/`invalid_at` (when a fact was true *in the world*) and `created_at`/`expired_at` (when the system *learned or replaced* it). This keeps "true now" apart from "true back then."

The key move: **invalidate, don't overwrite**. A customer moves from Starter to Enterprise: the old edge's validity window closes, a new one opens, and the history stays queryable. Backends: **Neo4j** (primary), FalkorDB, Amazon Neptune.

**Benchmarks (as reported, arXiv:2501.13956 / getzep blog):** on **DMR**, Zep scores 94.8% vs MemGPT's 93.4% (but a *full-context* GPT-4-Turbo baseline reaches 98.2%, so DMR is a weak test for recent models). On the harder **LongMemEval**, Zep reports gains "up to 18.5%" and roughly **90% lower latency**. One caveat: some cells show full-context *beating* Zep on raw accuracy, so Zep's edge is latency, cost, and scaling, not always accuracy. Treat these as "reported."

**Warranted when**: facts change over time and *the history matters* (CRM state, evolving preferences, queries like "last quarter"), and there are many overlapping or contradictory facts at scale.

## Other systems (worth borrowing from conceptually)

**Letta (MemGPT, Berkeley 2023)**: the LLM as an operating system with a memory hierarchy: **core** (small, in-context, the RAM), **recall** (searchable history), and **archival** (long-term, reached through a tool). The big idea is **self-edited memory**. The agent edits labeled **memory blocks** through tool calls inside its own loop. *Worth borrowing*: let the agent decide what deserves to be persisted and rewrite its own core context; the boundary between "in the window" and "on disk" is explicit.

**mem0**: a lightweight memory layer that extracts the salient facts from each turn and stores and retrieves them (vector, with an optional graph). It reports (LOCOMO) roughly 26% higher accuracy than OpenAI's memory and about 90% fewer tokens. *Worth borrowing*: the extract-the-salient-facts-then-retrieve pattern without committing to a full graph. (Caveat: LOCOMO is short and synthetic.)

## Context engineering = memory management

Anthropic (*Effective context engineering*) names the tactics: **compaction** (distill the window into a high-fidelity summary); **structured note-taking** (the agent writes notes to external files, which is exactly the markdown approach); and **sub-agent isolation** (each has its own context, returns only its conclusion, and avoids *context rot*). **RAG vs structured memory**: RAG retrieves similar *chunks* (good for static reference docs); structured memory stores *resolved facts and relations* (good for evolving truth).

## Lightweight vs heavy: a decision guide

| Memory type | markdown + git is enough when… | real infrastructure is needed when… |
|---|---|---|
| **Procedural** | almost always (SKILL.md/scripts; git for versions) | rarely |
| **Semantic** | few facts, curated, few conflicts | thousands of facts, frequent contradictions, relation traversal |
| **Episodic** | **strongly**, dated append-only markdown; **git history IS the audit trail** | high-volume semantic search over a long horizon |
| **Temporal/bi-temporal** | falsifiable: `valid_from`/`valid_to`/`superseded_by` + git; fine for dozens of slow-moving facts | many overlapping facts that shift often, "as of this date" queries at scale → **Graphiti** |
| **Working** | compaction + note files (the Claude Code default) | almost never a separate infrastructure |

**The tension, resolved**: git already gives you one of the two temporal axes, *ingestion time* (commit history). The frontmatter gives you the other, *validity time*. So for a personal or small-business OS, the lightweight path covers procedural, episodic, and working out of the box, and it covers semantic plus bi-temporal up to the point where **fact volume × contradiction rate × traversal need** forces a graph. Reach for Graphiti/Zep only for the "what did this customer believe in March vs now" case across many evolving entities, and not before.

## Sources
- CoALA, https://arxiv.org/abs/2309.02427
- Zep (benchmarks, bi-temporal), https://arxiv.org/abs/2501.13956
- Zep TKG, https://www.getzep.com/ai-agents/temporal-knowledge-graph/
- Graphiti, https://github.com/getzep/graphiti · Neo4j×Graphiti, https://neo4j.com/blog/developer/graphiti-knowledge-graph-memory/
- Letta, https://www.letta.com/blog/agent-memory/
- mem0, https://arxiv.org/abs/2504.19413 · https://mem0.ai/blog/ai-memory-benchmarks-in-2026
- Anthropic context engineering, https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
