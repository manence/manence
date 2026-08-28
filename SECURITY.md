# Security Policy

Manence is a young, open framework: markdown + git, a small set of shipped hooks, no server and no runtime of its own. This policy states what the framework protects, what it does not, and how to reach the maintainers.

## Reporting a vulnerability

Please report suspected vulnerabilities through **GitHub's private vulnerability reporting** on this repository (`manence/manence`): the **Security** tab, then **Report a vulnerability**. This keeps the report private until a fix is available.

Where you can, include what you observed, how to reproduce it, and the impact you expect. Please don't open a public issue for a security matter, and please allow a reasonable window before any public disclosure.

**Response time — best effort.** This is a young project maintained on a modest cadence. We will acknowledge a valid report as soon as we reasonably can and keep you posted as we look into it. We can't promise a fixed SLA, and we would rather say so than pretend otherwise.

## Scope — what the shipped guardrails are, and are not

Manence ships one hard guardrail: the `PreToolUse` hook `guard.sh` (`implementation/mos/.claude/hooks/guard.sh`; see the Spec, §12). It is deliberately modest, and it matters that you read it that way.

> `guard.sh` is an **anti-mistake barrier, not a hostile-proof boundary**: it matches common destructive forms by regex, fails closed when `jq` is missing, and documents its exact scope in its header.

It is there to stop an agent — or a human — from fat-fingering an `rm -rf` or a force-push to `main`: the everyday accidents. It is **not** designed to withstand an adversary who is actively working around it. An unusual phrasing of a destructive command can slip past a regex.

For strong guarantees, do not lean on the regex. Use the two hard mechanisms the framework points to (Spec §12), because a hard constraint runs through a boundary, not a flag an agent can ignore:

- **`permissions.deny`** in `.claude/settings.json` — a denial the agent cannot talk its way out of;
- **the runtime's sandbox** — the physical boundary around what the agent can touch.

Confidentiality follows the same doctrine. What must never leak lives in a **separate repository** gated by clone access, never behind a `visibility:` field in a shared file. A Manence core keeps secrets only in gitignored files (`.env`, `CLAUDE.local.md`); what you publish is a curated release, never a working tree with its history.

## In scope for a report

- A shipped hook (`guard.sh`, `lint.sh`) behaving clearly wrong — for instance `guard.sh` letting an obvious destructive form through, or failing open instead of closed.
- The default MOS or the install ritual (`BOOTSTRAP.md`) leading an installer into an unsafe state.
- Anything in this repository that could expose a secret or mislead an operator about what is protected.

## Out of scope

- The general fact that a soft rule in `AGENTS.md` can be ignored: that is by design (soft versus hard, law L9), not a vulnerability.
- That the regex guard can be bypassed by an unusual command form: a documented limitation, not a defect. Concrete improvements to the patterns are welcome as pull requests.
- Third-party components you run alongside Manence (your AI runtime, `git`, `jq`, `python3`): report those to their own maintainers.

Thanks for helping keep Manence honest about what it does, and does not, protect.
