# Upgrading a MOS

`install.sh` puts a Manence OS on disk once. This page is the other half: what to do when the framework has moved and your system has been living its own life in the meantime — with its own skills, its own guard lines, its own knowledge.

The gesture is two commands:

```sh
bash upgrade.sh /path/to/core                # dry run: says everything, writes nothing
bash upgrade.sh /path/to/core --apply        # writes, and still commits nothing
```

Read the dry run. It names every file it would touch and what it would do to it. When the plan suits you, run it again with `--apply`, then reread the diff (`git diff`) and commit it yourself. The script never commits, never pushes, and never deletes.

If your core lives at a different framework version than its stamp claims, or you want a specific target:

```sh
bash upgrade.sh ~/my-activity/core --from v0.6.1 --to v0.8.0 --apply
bash upgrade.sh ~/my-activity/core --source ../manence --to HEAD     # from a local clone
```

**The guardrail reads whole commands.** A core's `guard.sh` scans the full text of every shell command, quoted text and heredocs included. When you write the manual touches — an `AGENTS.md` that names the forbidden commands, for instance — write the text through a file-editing tool, or save a script and run it by its path; a heredoc that merely *quotes* `rm -rf` is refused like the command itself. (Lived at the first three upgrades, 2026-09-20.)

## Three classes of organ

An upgrade is not one gesture but three, and the script is explicit about which one it is playing on each file.

**Mechanical** — the framework's machinery: `.claude/hooks/guard.sh` and `lint.sh`, `templates/**`, and the eight base skills (`open-work`, `close-work`, `weekly-review`, `kb-ingest`, `kb-lint`, `connect-adapter`, `outward-watch`, `checkpoint`). These are **merged three ways**, exactly as git merges a branch: your file, the version you had, the version you are moving to. Your local edits survive; the framework's edits arrive; where both changed the same lines, the script stops. The verdicts read:

| Verdict | What happened |
|---|---|
| `up to date` | your file already matches the new version |
| `replaced` | you had never touched it — the new version simply lands |
| `merged` | both sides moved, in different places; your edits are kept |
| `created` | the new version ships a file you don't have yet |
| `CONFLICT` | both sides changed the same lines — nothing is written to the file; the merged text, with markers, is left beside it as `<file>.upgrade-conflict` for you to resolve |
| `CONFLICT (local skill predates the shipped one)` | the new version ships a file you already had under that name, with no common ancestor — a skill your system wrote before the framework had one. Nothing is written to your file; the framework's version waits beside it as `<file>.upgrade-conflict`, and you decide what the name means here |
| `SKIPPED` | a symlink, which the script never follows |

Skills you wrote yourself are never touched, and never counted — the script names them and leaves them alone.

**Identity** — `AGENTS.md`, `CLAUDE.md`, `CLAUDE.local.md`, `SOUL.md`, `STRATEGY.md`, `.claude/settings.json`, `.env*`, `log.md`, `knowledge-base/**`, `inbox/**`. **Never touched, ever.** These files are your system, not the framework's. What a version expects of them is listed below, per version, and the script prints that list for every version it walks over.

**Declared migrations** — the gestures a version needs on your data, played in version order, each idempotent, each announced before it runs. They are listed below, per version, under *Automatic*.

The version stamp, `.claude/manence-version`, is written **last**, and only when nothing was left hanging: a conflict anywhere means the stamp stays where it was, because a system that half-landed a version is not at that version. A target that is not a released version (`--to HEAD`, a branch) never writes a stamp either — the stamp names releases.

## What the script never does

- It never writes to your identity files, and never to `knowledge-base/` or `inbox/`.
- It never deletes anything. A retired organ moves to `<core>/.upgrade-removed/`, keeping its path; you delete it when you are satisfied, or you don't.
- It never commits and never pushes. Reading the diff is your gesture; so is the commit message.
- It never touches another system: everything it writes is under the core you named (and under the production root that core declares).
- It never resolves a conflict for you. `<file>.upgrade-conflict` is a proposal with markers, next to an untouched original.

## How to read the per-version sections

Each version below has two halves.

*Automatic* is what the script plays for you. *By hand* is what it can only tell you about, because the files are yours.

The *By hand* list sits between two machine-readable markers so that `upgrade.sh` can print it without you opening this page:

```
<!-- manual vX.Y.Z -->
- one bullet per retouch, one line each
<!-- /manual -->
```

(Written with the real version number, of course — the markers above are spelled with a placeholder so that this explanation is not itself read as a version's list.)

Each bullet is one line. When you add a version here, add it to the `KNOWN_VERSIONS` list in `upgrade.sh` too — the script walks that list and reads its manual blocks from this file.

---

## 0.8.3 — Hotfix

*Automatic.* `lint.sh` merges mechanically; nothing else changes.

<!-- manual v0.8.3 -->
- Nothing to do by hand. If your weekly review reported `awaiting-structure` findings on `awaiting: []   # …` lines, they disappear with this lint.
<!-- /manual -->

## 0.8.2 — The handover before a clear

`checkpoint`, the eighth base skill: what a session writes down before its context is wiped, so the next one picks up without being told everything again.

**Automatic**

- The `checkpoint` skill lands through the mechanical merge — `created` if you don't have it, merged if you do.
- If your system already had a skill of its own under that name, written before the framework shipped one, nothing of yours is overwritten: the verdict reads `CONFLICT (local skill predates the shipped one)` and the framework's version waits beside yours as `.claude/skills/checkpoint/SKILL.md.upgrade-conflict`.

<!-- manual v0.8.2 -->
- `AGENTS.md` / `CLAUDE.md`: add `checkpoint` to the list of base skills — there are **eight** of them now.
- If you had a local `checkpoint` skill, merge it by hand: read the `.upgrade-conflict` file beside it, keep what your system actually needs, write the result over the original, and remove the conflict file.
<!-- /manual -->

---

## 0.8.1 — Housekeeping

*Automatic.* Seven base skills, the skill template and Spec text change; they merge mechanically. Nothing changes in the format a reader relies on.

<!-- manual v0.8.1 -->
- Nothing to do by hand: reread the merged skills once (`weekly-review` now measures `log.md` and `AGENTS.md` and can run as a signal-only routine; `outward-watch` declares a fallback path for blocked domains).
<!-- /manual -->

## 0.8.0 — The observable MOS

The map retires in favour of a separate reader, a workstream declares what it is waiting for, and a routine says where the proof of its running lands.

**Automatic**

- `.claude/mos-map.json` → `.claude/mos.json` (`git mv` when the core is a repository, a plain `mv` otherwise). Same content, same meaning; only the cartographic name goes.
- `.claude/mos.json` moves to `"schema": 3`, and every routine that has no `proof_glob` gets an empty one. Your comment keys (`//`, `//routines`) and everything else are left as they stand. This step needs `python3`; without it, the script says so and leaves it to you.
- The `mos-map` skill is set aside in `.upgrade-removed/.claude/skills/mos-map/` (untracked from git with `git rm -r --cached`, never deleted).
- `awaiting: []` is inserted right under `status:` in the frontmatter of every `<production>/<domain>/in-progress/<slug>/About.md` that has no such key. The script prints how many it touched.

<!-- manual v0.8.0 -->
- `AGENTS.md` / `CLAUDE.md`: remove `mos-map` from the list of base skills — the map retires with this version, and the list is one shorter.
- `AGENTS.md` / `CLAUDE.md`: remove the map from the routing table and from the connector map; seeing the MOS is Manence UI's business now, a separate read-only reader, not a skill.
- `AGENTS.md` / `CLAUDE.md`: if the identity mentions a `mos-map` routine ("the map is regenerated every…"), remove it — and remove that routine from `.claude/mos.json` as well.
- `.claude/mos.json`: fill in the `proof_glob` the migration left empty — where the evidence of each routine actually lands (a French install writes its watch reports to `knowledge-base/veille/*.md`, an English one to `knowledge-base/watch/*.md`; `weekly-review` proves itself from `log.md` with `proof_marker: "] review |"`).
- `.claude/mos.json`: `cadence` is now a closed list — `daily | weekly | biweekly | monthly | quarterly`. Rewrite any prose cadence ("every Saturday morning") into one of those, and keep the prose in `desc`.
- Production: `awaiting: []` is a claim that nothing waits. Reread each in-progress workstream and write the real waits — `who`, `what`, `kind` (`decision` or `action`), `since` (the day the wait was born, not the last reminder).
- `work_id`: **no retrofit**. Workstreams opened before the field simply have none, and nothing complains. New ones get it from `open-work`.
<!-- /manual -->

---

## 0.7.0 — Multi-AI

The identity moves to the shared `AGENTS.md` standard, read natively by OpenAI Codex and Grok Build; `CLAUDE.md` becomes an import plus the Claude Code wiring.

**Automatic**

- Nothing on your data. `guard.sh` gains its two payload dialects and `lint.sh` its fixes through the mechanical merge — if you added guard patterns of your own, the merge keeps them, and where the framework rewrote the very lines you touched you get a conflict to read.

<!-- manual v0.7.0 -->
- Invert your identity files: move the rules out of `CLAUDE.md` into a new `AGENTS.md` (this is the file every agent reads first), and leave `CLAUDE.md` holding `@AGENTS.md` plus the Claude Code wiring addendum — hooks, settings, skills, and anything only this harness does.
- Keep the addendum honest: what lives in `CLAUDE.md` must be the mechanisms that exist only under Claude Code. Another harness reads their products, not their channels.
- If you drive this system with a second agent, wire it at the core root — a `skills` link to `.claude/skills` and a `.codex/config.toml` for Codex. Never commit the symlink: the wiring is posed on the machine, not carried by the repository.
- Before any risky gesture from a newly wired harness, watch the guard refuse something for real in a session of *that* harness. A boundary that exists on one harness and not the others does not exist.
- If your `AGENTS.md` sends a stranger agent to the doctrine, give the URL in full: a foreign agent has none of your context.
<!-- /manual -->

---

## 0.6.2 — The door

The public repository becomes something a stranger can open: `install.sh`, a README without frontmatter, the three objections named.

**Automatic**

- Nothing. This version changed the way a MOS is *installed*, not the way an installed one runs.

<!-- manual v0.6.2 -->
- Nothing to do on an installed system. The door is for newcomers.
<!-- /manual -->

---

## 0.6.1 — A MOS looks outward

`outward-watch`, the organ that faces out: substrate (Anthropic, Claude Code, agentic practice) shipped complete, and a trade slot each system fills for itself.

**Automatic**

- The `outward-watch` skill lands through the mechanical merge — `created` if you don't have it, merged if you do.

<!-- manual v0.6.1 -->
- Fill the **trade slot** of `.claude/skills/outward-watch/SKILL.md`: the skill ships its substrate half complete and its trade half empty, because only this system knows what its trade is. An unfilled slot means half a watch.
- Add the watch to `.claude/mos.json` as a routine (weekly), and say where its reports land — `knowledge-base/watch/` in English, `knowledge-base/veille/` in French.
- `AGENTS.md` / `CLAUDE.md`: add `outward-watch` to the list of base skills, and the watch folder to the routing table (a dated report is a time series: consolidated knowledge, not a workstream).
- Run the watch **before** the weekly review, not after: the review now reads the latest report and picks up what the inbox triage did not route.
<!-- /manual -->

---

## 0.6.0 — A MOS can be seen

`mos-map` and its declaration `.claude/mos-map.json` (schema 2).

**Automatic**

- Nothing, and deliberately so: `upgrade.sh` knows the base skills of the version you are taking, where the map has already retired. Walking over this version installs no `mos-map`, and the 0.8.0 migration renames the declaration if you have one.

<!-- manual v0.6.0 -->
- Nothing to do: the map retired in 0.8.0 and Manence UI reads a MOS from outside now. If you stop before 0.8.0 and want the map, take it from the v0.6.x tag by hand.
<!-- /manual -->

---

## 0.5.1 — The first real Windows install

The guard was silently absent on Windows: under PowerShell, invoking a `.sh` file directly runs nothing and reports nothing, so a fail-closed guard was fail-open.

**Automatic**

- `lint.sh`'s runnable-`python3` probe arrives through the mechanical merge.

<!-- manual v0.5.1 -->
- `.claude/settings.json` is yours and is never touched: check by hand that every hook command goes through bash — `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/guard.sh"`, not the bare path. A bare path is a guard that does nothing on Windows, silently.
- If anyone runs this system on Windows: install Git for Windows first, play the moves from Git Bash, and beware the Microsoft Store `python3` stub that answers `command -v` and runs nothing.
<!-- /manual -->

---

## 0.5.0 — A MOS knows whether it is up to date

`.claude/manence-version`, stamped at release time, and the weekly review's freshness step.

**Automatic**

- The freshness step arrives with the merged `weekly-review` skill.

<!-- manual v0.5.0 -->
- If your core has no `.claude/manence-version`, the install predates 0.5.0 and the script cannot read where you stand: pass `--from vX.Y.Z` with the version your core actually matches (the review proposes one when it can).
- `AGENTS.md` / `CLAUDE.md`: nothing required. The stamp is data, not identity.
<!-- /manual -->

---

## When an upgrade goes wrong

Nothing is lost by construction: an upgrade that leaves conflicts leaves every original file untouched, with the proposed merge beside it. Three ways out, in order of preference:

1. **Resolve the conflicts.** Open each `<file>.upgrade-conflict`, keep what you mean to keep, write it over the original, delete the conflict file, rerun the dry run: it should come back clean and stamp the version.
2. **Take the new version whole** on a file whose local edits you no longer care about: copy it from the clone, and note in your `log.md` what you dropped.
3. **Undo.** The script commits nothing, so `git checkout -- <file>` puts you back. If the core is not a git repository — it should be — the migrations are the only irreversible-looking step, and even those only ever *move* things, into `.upgrade-removed/`.

A MOS that skipped several versions walks them in order: the migrations of each traversed version run, and the manual list is printed version by version, oldest first. There is no shortcut that skips the human half.
