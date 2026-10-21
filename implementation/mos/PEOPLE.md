---
type: reference
title: "People: who works in this MOS"
description: "One section per person: name, role, the perimeters their GO covers, whether they give the admin GO. Read at every session start."
tags: [people]
timestamp: <YYYY-MM-DD>
---

# People

Who works in this MOS. Each person is a section whose heading is their **handle**: lowercase letters, digits and hyphens only (`a-z`, `0-9`, `-`). The handle is their name everywhere else: `awaiting.who`, the author of a decision, the `auteur` of a `go` item, the `pour` of an inbox capture (who sorts it; a capture without one is the owner's), the ` · @handle` ending a log heading, and `.claude/operator`, the gitignored one-line file that says who is at the screen on this machine.

Keys, one per line: `name`; `role`; `authority`, the perimeters on which this person's GO counts (named like the routing table or the connectors: `site`, `release`, a production domain such as `offers/`), or `*` for everything; `admin`, `yes` or `no`, whether this person gives the admin GO; `notes`, constraints worth knowing. The owner (the person with `*`) decides who joins and with what authority, and edits this file. To add a person: the section "Add a person" of `BOOTSTRAP.md`, in the framework's repository (`implementation/mos/BOOTSTRAP.md`).

## <handle>
- name: <Full name>
- role: <What they do here>
- authority: *
- admin: yes
- notes: <Constraints worth knowing, or nothing>
