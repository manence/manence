---
name: upgrade
description: Use it when the weekly review reports a newer version of the framework than the core's `.claude/manence-version`, or when the user asks to bring the MOS up to date. Runs `upgrade.sh` as a dry run, gets the user's GO, applies, gives each conflict its fate (dropped, moved into the MOS's own files, rewritten in English for upstreaming, or held for the user when a local override contradicts a framework rule), confirms with `--resolved`, does the manual touches the script lists, and leaves an `event |` entry in the log. Not for changing the framework itself: that happens in its repository.
---

# upgrade, bring a MOS onto a newer version of the framework

## Purpose
That a core moves to the version the framework ships **without losing what the MOS had added, and without keeping in an installed organ what belongs to the MOS**. The mechanics are the script's: `upgrade.sh` (three-way merge of the hooks, templates and base skills; its header lists the options) and `UPGRADING.md` in the framework's repository (the three classes of organ, what each version asks by hand). This skill carries the judgment the script cannot have: reading the plan, deciding the fate of each conflict, and the trace.

## Read before you act
- `.claude/manence-version` (the version you have) and the framework's `CHANGELOG.md` and `UPGRADING.md` for the versions between it and the target.
- `AGENTS.md` of the MOS: its Skills line (which base skills point to a MOS page for their local content) and whether it reserves the push of the core to the user.
- The workstreams in progress, so that an organ replaced mid-gesture does not surprise the session.

## Procedure
1. **Dry run first, nothing written**: `bash <framework>/upgrade.sh <absolute path of the core>` (add `--source <local clone>` when the public repository is out of reach). Read the plan line by line; the verdicts are defined in `UPGRADING.md` "Three classes of organ".
2. **The user's GO before `--apply`** (`AGENTS.md` "Security, hard vs soft"): the upgrade rewrites the core's organs; that is the user's call, with the plan in front of them.
3. **Apply**, then **sort every conflict**. What a `CONFLICT` leaves on disk depends on its kind (`UPGRADING.md` "Three classes of organ"): an ordinary conflict keeps your file and writes the merge with markers into `<file>.upgrade-conflict`; an organ that predates the framework's keeps yours and puts the framework's beside it; a language switch puts the framework's file in place and yours beside it. Read the verdict before deciding which file is which. Compare your version with the one the installed version shipped (`.claude/manence-version`; `--from` names another base when the stamp is wrong), and give each local change one of four fates:
   - **already covered** by the new version → drop it;
   - **content of the MOS** (a watch scope, paths, routines, a section about the MOS's own trade) → it never lives in an installed organ, which the next upgrade replaces: move it into a page of the MOS's knowledge base and point to that page from the skill's line in `AGENTS.md` Skills;
   - **guidance useful to every MOS** → rewrite it in English in the English organ, and file an inbox item for upstreaming (see `skill-craft`, "Base skills"); an installed copy is never the place to fix the framework;
   - **a local override that contradicts a framework rule** (a dated decision of the user that departs from the Spec or a base skill) → a stop: it is neither dropped nor filed away by the agent; the user decides, and the outcome is recorded in a page of the MOS's knowledge base with its date.
   Then remove the `.upgrade-conflict` files and rerun with `--resolved --apply`: the stamp is written only when no conflict file and no conflict marker remain (the script's header says so).
4. **The manual touches** the script lists for the target version (`UPGRADING.md`): do them, or say which ones you leave and why. Check what the upgrade retired (`.upgrade-removed/`, a renamed template folder): nothing in the core points to it any more before it goes.
5. **Check**: `lint.sh` clean on the files touched; every skill's line in `AGENTS.md` still points to something that exists; the workstreams in progress untouched.
6. **Trace**: an `event |` entry in the log — from which version to which, how many organs replaced and created, each conflict and its fate, what was retired, the manual touches done or left. Commit the core; push unless the MOS's `AGENTS.md` reserves the push to the user, and ask when it says nothing. If a replaced organ breaks something in use afterwards, an `incident |` entry names it: that is the trace the framework's method feeds on.

## Done
- Success condition: `.claude/manence-version` carries the target version; no `.upgrade-conflict` and no conflict marker left; `lint.sh` clean; the `event |` entry exists and names every conflict's fate.
- Reading criterion: a fresh context reads the `event |` entry and can say, for each conflict, where its content went and why, without opening the files.
- Trace: the `event |` entry; the inbox items for upstreaming, if any; the knowledge-base pages that now hold the MOS's own content or its recorded overrides.
- Stops: no `--apply` without the user's GO; a local override against a framework rule is the user's decision; no push where the push is the user's gesture; nothing written in the framework's repositories from here (the framework is fixed at its source: `skill-craft`, "Base skills").
