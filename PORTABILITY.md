# Portability

Manence lives in markdown files and a git repository. The agent that reads them is a replaceable part. That is one of the Manifesto's claims, and this page says exactly what it is worth, layer by layer, together with what has actually been tested and what is still a known gap.

## What carries over, layer by layer

| Layer | Portability | What to know |
|---|---|---|
| Knowledge, journal, production (KB, log, workstreams) | **Carries over unchanged** | Markdown and git. Nothing here depends on an agent. |
| Identity (`AGENTS.md`) | **Carries over unchanged** | Since 0.7, `AGENTS.md` holds the rules, and Codex and Grok Build both read it natively. `CLAUDE.md` is now just an import plus the wiring specific to Claude Code. |
| Skills (`SKILL.md`) | **Everything but the wiring** | The format follows the Agent Skills spec: `name` and `description` in the frontmatter, nothing proprietary. Skills live in `.claude/skills/`; other harnesses reach them through a bridge the BOOTSTRAP ritual puts in place (nothing for Grok, a `skills/` link for Codex). |
| Hard boundary (`guard.sh`) | **Everything but the dialect** | The mechanism is universal: a pre-tool hook reads the command and refuses it. The syntax varies — a snake_case payload (Claude Code, Codex) or camelCase (Grok Build) — and the guard shipped here reads both and answers in the caller's dialect. Each harness gets its own wiring file, around fifteen lines. |
| MCP connectors | **Everything but the file format** | The contents carry across (JSON or TOML, depending on the harness); the protocol is the same everywhere. |
| Subagents | **Does not carry over** | There is no standard. The framework ships none, and any pattern that relies on them (maker ≠ checker) has to be rewired for each harness. |

## What has actually been tested

The rule in this repository is that nothing is announced as supported before it has been tested. Here is exactly where things stand:

- **Claude Code** — the native path. The installation is qualified on macOS and Linux, and has been run for real on Windows.
- **OpenAI Codex** — a real session on macOS: it read the identity file, discovered and ran skills, and **a guard refusal was observed end to end** (a forced recursive delete refused, the reason displayed, the files left intact). Writes outside the working directory are held in check by Codex's own sandbox as well.
- **Grok Build (xAI)** — a real session on macOS: a full work cycle carried out under the framework's rules (Grok's Claude compatibility loads skills, permissions, and hooks with no wiring).
- **Multi-agent on Windows** — the wiring is documented (an NTFS junction, no admin rights needed), but **untested**. Claude Code on Windows remains the qualified path.

## The principle that governs all of it

**A hard boundary has to exist, identically, on every harness connected to the Manence OS — otherwise it does not exist.** A multi-agent system is only as secure as its weakest harness. The BOOTSTRAP ritual lays down the wiring for the harness you choose; if you connect a second one later, put its wiring in place before you trust it with anything risky, and never run two agents at the same time on the same container.

## Known gaps

- No standard specifies **automatic skill invocation**: it rests on the judgment of the model reading the `description`. The descriptions shipped here are written as triggers, but the behavior can differ from one model to the next.
- **Subagent formats** are not standardized anywhere.
- **Declarative deny lists** (`permissions.deny`) have one dialect per platform. The guard covers the critical actions in portable code, and each platform's sandbox adds a layer of its own.
