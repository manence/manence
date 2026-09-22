# CLAUDE.md, <project name>

The system's identity is agent-neutral and lives in `AGENTS.md`. This file imports it, then adds what is specific to Claude Code.

@AGENTS.md

## Claude Code wiring
- **The hard part lives in `.claude/`**: `.claude/settings.json` declares the hooks and the denied permissions, `.claude/hooks/guard.sh` blocks, `.claude/hooks/lint.sh` reports. A rule written in prose only suggests; only these constrain.
- **A session-start hook points at the inbox**: `.claude/hooks/consignes.sh`, declared under `SessionStart` in `.claude/settings.json`, counts the inbox items with `type: instruction` and `status: deposee` and says so at the top of the session. It signals; you run the `consignes` skill. Other harnesses rely on the AGENTS.md line — the file is the channel, this hook only an accelerator (Spec §21).
- **Skills load from `.claude/skills/`** — their single home. A `skills/` link at the root, if the first setup installed one, is only a bridge for another agent: never write there.
