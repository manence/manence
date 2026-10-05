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

**Mechanical** — the framework's machinery: `.claude/hooks/guard.sh`, `test-guard.sh`, `lint.sh` and `consignes.sh`, `scripts/log-rotate.py`, `templates/**`, and the eleven base skills (`open-work`, `close-work`, `weekly-review`, `kb-ingest`, `kb-lint`, `connect-adapter`, `outward-watch`, `checkpoint`, `consignes`, `skill-craft`, `upgrade`). These are **merged three ways**, exactly as git merges a branch: your file, the version you had, the version you are moving to. Your local edits survive; the framework's edits arrive; where both changed the same lines, the script stops. The verdicts read:

| Verdict | What happened |
|---|---|
| `up to date` | your file already matches the new version |
| `diverges` | the new version leaves the organ as the version you had, and your file differs from it — a local edit, or the prototype of a skill the framework has since shipped. Nothing is written; the difference is named at every run until you keep it, upstream it, or take the shipped file |
| `replaced` | you had never touched it — the new version simply lands |
| `merged` | both sides moved, in different places; your edits are kept |
| `created` | the new version ships a file you don't have yet |
| `CONFLICT` | both sides changed the same lines — nothing is written to the file; the merged text, with markers, is left beside it as `<file>.upgrade-conflict` for you to resolve |
| `CONFLICT (local skill predates the shipped one)` | the new version ships a file you already had under that name, with no common ancestor — a skill your system wrote before the framework had one. Nothing is written to your file; the framework's version waits beside it as `<file>.upgrade-conflict`, and you decide what the name means here |
| `resolved` | with `--resolved` only: the merge still conflicts, but you resolved it by hand — no `.upgrade-conflict` file, no marker left — so your file stands as it is |
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

## 0.13.0 — The admin GO, local guard rules, and what moved since the last session

The guardrail can be opened by the user's own words for one session, a MOS's guard rules get a file of their own, and each session opens with what moved since the last one.

**Automatic**

- `guard.sh` is replaced or merged: the admin GO (rule 4 opens for a session that holds a grant, each write traced), rule 4bis, `touch`/`mv`/`chmod` on its files refused, and the call to `.claude/hooks/guard.local.sh` when it exists. If your `guard.sh` carries rules of your own, you get a conflict: see the first manual touch below, do not re-merge.
- `test-guard.sh` is replaced or merged (132 cases): BLOCK cases now name their rule, cases lifted by your local file are skipped and named, `test-guard.local.sh` is played when it exists.
- New organs, `created`: `admin-go.sh` (the admin GO, on `UserPromptSubmit` and `SessionStart`), `since-last-session.sh` (`SessionStart`), `verify-go.sh` (the signed-GO check, called by nothing yet).
- `lint.sh` and `consignes.sh` are replaced or merged: English messages and finding codes, same behavior. A core that kept local edits in `lint.sh` will likely get a conflict, since nearly every comment line changed: take the shipped file and re-apply your edit.
- The dry run now says whether a local guard exists (`local guard` lines), and hints when `guard.sh` still differs from the shipped organ.
- A "predates" conflict now lays the shipped organ itself beside your file (it used to be a merge full of markers).

<!-- manual v0.13.0 -->
- `guard.sh` hand-merged with rules of your own (a CONFLICT here, or the `hint` line): move those rules into `.claude/hooks/guard.local.sh` (refusals in `local_file_rules` / `local_shell_rules`, each setting `REASON` and `RULE`; a shipped rule you override goes in `GUARD_LIFT`, plus a narrower local rule if you keep part of it), their cases into `.claude/hooks/test-guard.local.sh` (`local_cases`, `local_edits`), take the shipped `guard.sh` and `test-guard.sh` as they are, then run `test-guard.sh` until it is green.
- **For this upgrade itself, every touch under `.claude/` is the user's hand.** The admin GO does not exist yet: the 0.12 guard already refuses the agent in `.claude/hooks/`, the 0.12 deny rules still stand, and the new hooks are only read by a new session once `settings.json` wires them. So the user resolves the conflicts under `.claude/hooks/` (the agent prepares the merged file elsewhere and shows it), makes the `settings.json` touch below, then opens a new session; from there on, an admin GO lets the agent do such touches. Never install a `.upgrade-conflict` file without opening it (a merge full of markers was installed as is on a core, 2026-10-05).
- `.claude/settings.json` (by the user's hand, one last time): add the `UserPromptSubmit` entry running `admin-go.sh`, and two `SessionStart` commands, `since-last-session.sh` and `admin-go.sh --session-start` (copy them from the shipped `settings.json`); remove `Edit(./.claude/hooks/**)`, `Edit(./.claude/settings.json)` and `Edit(./.claude/settings.local.json)` from `permissions.deny`: a deny outranks every hook, and under Claude Code it would keep these files shut even after an admin GO.
- `.gitignore`: add `.claude/hooks/grants/` (the session grants stay local).
- Codex: in `.codex/config.toml`, add a `[[hooks.UserPromptSubmit]]` running `admin-go.sh` and a `[[hooks.SessionStart]]` running the two start hooks, in the same form as your `PreToolUse` entry. Not observed under Codex yet: until it is, treat the admin GO there as absent (the guard simply stays shut). Grok reads `.claude/settings.json`; same status.
- `AGENTS.md`: replace the line on the guardrail's own files with the shipped one (it names the admin GO and `guard.local.sh`).
- Every harness you use: `bash .claude/hooks/test-guard.sh` green, then, in a real session, ask for a write to `.claude/hooks/lint.sh` without the words (refused, and the refusal tells the agent how to ask), then with "admin GO" (passes, a `guard-files-granted` line in `.claude/guard-refusals.log`), then in a new session again (refused). Under Claude Code in bypass mode no harness prompt appears on these writes (observed 2026-10-05); in another permission mode the harness may still ask its own question for a file under `.claude/`: that one is the harness's, not the framework's.
<!-- /manual -->

## 0.12.0 — The guardrail guards itself, and the journal rotates

The guardrail refuses to rewrite its own files and leaves a trace of every refusal; the journal gets its direction written down and a script to rotate it; the base skills take the fixes of their first month in use.

**Automatic**

- `guard.sh` is replaced (`replaced`, or `merged` if you touched it): pushes are read by segment, only when the segment begins with the git command; rule 4 refuses the agent's writes to `.claude/hooks/` and `.claude/settings*.json`, by file tool and by shell; every refusal appends a line to `.claude/guard-refusals.log`. A core that rewrote the push block locally gets a three-way merge on this file: the upstream version already contains that fix, take upstream.
- `test-guard.sh` arrives next to it (`created`; 64 cases). A core that copied an earlier version by hand sees `CONFLICT (local file predates the shipped one)`: take the shipped file.
- `lint.sh` gains two structural checks in standalone mode: an `in-progress/` or `done/` nested below another, and the two sizes the Spec bounds (`log.md` over 150 KB, `AGENTS.md` over 200 lines). A core whose journal is already over the threshold gets one finding until it is rotated.
- `scripts/log-rotate.py` arrives (`created`): from this version it is a mechanical organ, merged like the hooks.
- The eleven base skills are replaced or merged; `templates/log.template.md` and `templates/SKILL.template.md` too.
- A new verdict, `diverges`: an organ the new version leaves as it was, but that differs locally. Nothing is written; it is named at every run until you keep it, upstream it, or take the shipped file.
- `.claude/mos.json`: nothing. The shipped file no longer carries `sommet`; yours may keep it, readers ignore it (no schema change).

<!-- manual v0.12.0 -->
- `.claude/settings.json` (your hand: the new guard refuses the agent there): add `Edit(./.claude/hooks/**)`, `Edit(./.claude/settings.json)` and `Edit(./.claude/settings.local.json)` to `permissions.deny`, and a second `PreToolUse` entry with matcher `Edit|Write|MultiEdit|NotebookEdit` running `guard.sh` (copy both from the shipped `settings.json`). Without them, shell writes are refused but the file tools pass.
- `.gitignore`: add `.claude/guard-refusals.log` (the refusal trace stays local, never committed).
- Every harness you use: run `bash .claude/hooks/test-guard.sh` (64 cases conform), then, in a real session, ask the agent to edit `.claude/hooks/guard.sh` and see the refusal; that end-to-end observation is what the shipped `AGENTS.md` asks for before the first risky gesture.
- `AGENTS.md`: under "Security, hard vs soft", the line on the guardrail's own files; under "Conventions", the journal's direction (entries prepended under the H1, newest first; you add, you never rewrite) and the subagent budget; copy the three from the shipped `AGENTS.md`.
- `CLAUDE.md`: nothing to do. If yours holds nothing but the `@AGENTS.md` import, you may delete it (Spec §9).
- `log.md` over 150 KB (the lint says so): `python3 scripts/log-rotate.py --out <a temporary folder>` to read the plan and the files, then, on the user's GO, `python3 scripts/log-rotate.py --apply`; commit `log.md` and `log-archive/` together.
- A skill your MOS wrote that the framework has since shipped (`CONFLICT (local skill predates the shipped one)` or `diverges`): take the shipped file; what your prototype held beyond it is your MOS's content (a knowledge-base page) or gone on purpose (`Implementation.md` §10).
<!-- /manual -->

## 0.11.0 — The upgrade has its skill, and two fixes

- **A new base skill, `upgrade`**, arrives as a new file (`created`). It carries the judgment the script cannot have: reading the dry run, the user's GO before `--apply`, the fate of each conflict (dropped, moved into a page of the MOS's knowledge base, or rewritten in English for upstreaming), the manual touches, the `event |` trace. By hand: add `upgrade` to the list of base skills in your `AGENTS.md` — there are **eleven** now.
- `upgrade.sh` runs again with the default (public) source on macOS, and exits 0 once no conflict is left even when manual touches remain (they are listed; the script cannot check them).
- `outward-watch` and `weekly-review` read the watch folder from the MOS's scope page instead of hard-coding `knowledge-base/watch/`. If your MOS keeps its reports elsewhere, say so in that page and in the `outward-watch` line of `AGENTS.md`.

## 0.10.0 — Every core moves to the English organs

The French install set (`implementation/mos/fr/`) is retired. From 0.10 on, every core receives the English organs — base skills (the new `skill-craft` among them), templates, hooks — whatever language it was installed in. A core's working language stays its own: `AGENTS.md` says it, and the skills write in it.

**Automatic**

- `skill-craft`, the tenth base skill, lands in `.claude/skills/skill-craft/` (`created`).
- A core installed in French (detected, or `--lang fr`) is merged from its French base to the English target, file by file. A skill or template you never touched is replaced by the English one: `replaced — moved to the English organ`. One you did retouch is not merged across languages — that would conflict on every line: the English file is written in place, and your French file waits beside it as `<file>.upgrade-conflict`, with the verdict `CONFLICT — this core's local edits to it were written in French; the organ is now English`. The stamp stays at 0.9 until those are settled.
- The French workstream template `templates/chantier/` is no longer shipped; `templates/workstream/` arrives beside it (`created`), and the old one is named `left` — yours until you remove it.
- Hooks, `AGENTS.md`, `CLAUDE.md` and every identity organ are untouched by the switch: hooks were always one language, and the identity is never merged.

<!-- manual v0.10.0 -->
- French core: for each `<file>.upgrade-conflict` the switch left, re-apply your local edits by hand, in English, in the English file; remove the conflict file; then rerun with `--resolved` (dry run first) — the verdict reads `resolved` and the stamp is written.
- `AGENTS.md` / `CLAUDE.md`: add `skill-craft` to the list of base skills — there are **ten** of them now. A French core keeps its "Langue" section: the working language does not change with the organs.
- French core: once nothing points to `templates/chantier/` any more (your own skills, `AGENTS.md`), remove it.
<!-- /manual -->

---

## 0.9.0 — The channel

A MOS gains a human → agent channel, and it is a file: an inbox item the user drops from Manence UI, read first by a new base skill.

**Automatic**

- The `consignes` skill lands in `.claude/skills/consignes/` (`created`), and the session-start hook in `.claude/hooks/consignes.sh` (`created`). Nothing else moves: the channel is an inbox item, and the inbox is yours.

<!-- manual v0.9.0 -->
- `.claude/settings.json`: declare the hook — add a `SessionStart` block to `hooks` with `bash "${CLAUDE_PROJECT_DIR}/.claude/hooks/consignes.sh"` (copy it from the shipped `implementation/mos/.claude/settings.json`). Without it, Claude Code sessions do not announce deposited items; the AGENTS.md line still applies.
- `AGENTS.md` / `CLAUDE.md`: under "At session start", add the line that runs `consignes` first when `inbox/` holds an item with `type: instruction` and `status: deposee` (copy it from the shipped `AGENTS.md`), and add `consignes` to the list of base skills.
- Manence UI ≥ 0.2.0 writes these items; an older reader simply shows nothing to answer from. Nothing to do in the core for that.
<!-- /manual -->

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

1. **Resolve the conflicts.** Open each `<file>.upgrade-conflict`, keep what you mean to keep, write it over the original, delete the conflict file. Then rerun with `--resolved` (dry run first, then `--resolved --apply`): if you kept a local change inside a hunk the new version also changed, the merge conflicts again — the base is still the version you had — and the script cannot tell a resolved conflict from an unresolved one on its own; `--resolved` is you telling it, and it takes such a file as it stands (verdict `resolved`, the stamp can then be written) only if no `<file>.upgrade-conflict` is left beside it and no conflict marker is left in it. Without the flag a missing conflict file proves nothing — a first run has none either — so the conflict is reported as before.
2. **Take the new version whole** on a file whose local edits you no longer care about: copy it from the clone, and note in your `log.md` what you dropped.
3. **Undo.** The script commits nothing, so `git checkout -- <file>` puts you back. If the core is not a git repository — it should be — the migrations are the only irreversible-looking step, and even those only ever *move* things, into `.upgrade-removed/`.

A MOS that skipped several versions walks them in order: the migrations of each traversed version run, and the manual list is printed version by version, oldest first. There is no shortcut that skips the human half.
