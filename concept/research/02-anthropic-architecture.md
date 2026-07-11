---
type: research
title: "Anthropic / Claude Code architecture: building blocks & principles"
description: The canonical building blocks (CLAUDE.md, skills, subagents, hooks, MCP) and the agent-engineering principles Anthropic has published.
tags: [ai-os, research, anthropic, claude-code]
timestamp: 2026-06-30
---

# Anthropic / Claude Code architecture (research brief)

## Building blocks

**CLAUDE.md: a 5-level hierarchy** (read from the filesystem root down to the cwd, closest wins): (1) **Enterprise** (`/Library/Application Support/ClaudeCode/CLAUDE.md`…); (2) **User** `~/.claude/CLAUDE.md` (your preferences, across all projects); (3) **Project** `./CLAUDE.md` or `./.claude/CLAUDE.md` (shared, committed); (4) **Local** `./CLAUDE.local.md` (gitignored, deprecated in favor of imports); (5) **Subdirectory** (loaded on demand when you read files there). Put build commands, conventions, architecture, and "always do" rules here. **< ~200 lines**, bullets over prose, specific. Import with `@path` (up to 4 hops). Add with `#`, edit with `/memory`.

**Skills (SKILL.md)**, on-demand capability packages: a folder holding `SKILL.md` (YAML `name`/`description` plus a body) and optional scripts/files, under `~/.claude/skills/<name>/` or `.claude/skills/<name>/`. **Progressive disclosure (3 levels)**: metadata always loaded (~tens of tokens), body loaded when the skill triggers, bundled files only when referenced. Body < ~500 lines. A **skill** is reusable knowledge or a procedure; a **slash command** is the legacy single-file form; a **subagent** is for when you need an isolated context or a restricted set of tools.

**Subagents**, specialized assistants with their own context window, system prompt, tool allowlist, and model. Markdown+YAML in `.claude/agents/` (project) or `~/.claude/agents/` (user). Delegate for: context isolation, tool restriction, cost (route to Haiku), **parallel fan-out**. Supports **maker/checker**.

**Hooks**, shell commands triggered deterministically on events (`.claude/settings.json`): `SessionStart/End`, `UserPromptSubmit`, `PreToolUse` (**can block or rewrite a call**), `PostToolUse`, `Stop`, `SubagentStop`, `Notification`, `PreCompact`. Use them for: auto-format, lint, guardrails, context injection, anything that must *always* happen rather than depend on the model's choice.

**MCP / connectors**, an open protocol that exposes external tools and data; transports are stdio (local subprocess), SSE, and HTTP (remote). Scopes: local (`~/.claude.json`), **project** (`.mcp.json`, committed/shared), user. Tools: `mcp__<server>__<tool>`.

**Slash commands / output styles**, commands in `.claude/commands/*.md`; the file name is the command name; frontmatter carries `description`/`allowed-tools`/`argument-hint`; they support `$ARGUMENTS`, `@file`, and `!`bash. Output styles swap the system prompt (persona/behavior).

## Engineering principles

- **Context is finite, "context rot."** Accuracy degrades as the token count grows; curate the **smallest high-signal set**.
- **The right altitude.** Specific enough to guide, flexible enough not to be brittle, neither hardcoded nor vague.
- **Just-in-time context.** Keep lightweight identifiers (paths, queries) and retrieve dynamically rather than preloading everything.
- **Long-horizon discipline.** Compaction, structured note-taking, subagent isolation (return a 1–2k-token summary).
- **Simplest thing first.** Prefer a single augmented LLM call; add the patterns (chaining, routing, parallelization, orchestrator-workers, evaluator-optimizer) only as needed. Distinguish predictable **workflows** from autonomous **agents**.
- **Single agent before the fleet.** Multi-agent (orchestrator-worker) wins on breadth-first search that is parallelizable and token-heavy (+90% vs Opus alone) but at **~15× more tokens**, so avoid it for code or shared context. Tokens explain ~80% of the variance in performance.
- **Delegate with detailed specs.** Vague instructions lead to duplicated work.
- **Few tools, sharp ones.** A small, consolidated, non-overlapping set with high-signal results.
- **Verification loops.** Give the agent tests/linters/exit codes/screenshots so it can iterate on its own.

## Reference conventions

- **Layout**: a lean `CLAUDE.md` committed at the root; `.claude/{skills,agents,commands,settings.json}`, `.mcp.json`. Global equivalents live under `~/.claude/`.
- **What goes where**: per-session facts → CLAUDE.md; on-demand procedures/knowledge → skills; isolated/restricted work → subagents; deterministic automation → hooks; external tools → MCP. A CLAUDE.md section that grows into a multi-step procedure → pull it out into a skill.
- **Context budget**: CLAUDE.md < 200 lines, SKILL.md < 500; `@import` instead of duplicating; prune regularly.
- **Workflow**: Explore → Plan → Code → Commit; subagents for investigation; `/clear` between tasks; worktrees for parallel multi-Claude.

## Sources
- https://code.claude.com/docs/en/memory · /skills · /sub-agents · /hooks · /mcp · /best-practices
- https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- https://www.anthropic.com/engineering/building-effective-agents
- https://www.anthropic.com/engineering/multi-agent-research-system
- https://www.anthropic.com/engineering/writing-tools-for-agents
- https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
