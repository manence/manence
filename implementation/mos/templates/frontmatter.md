---
type: reference
title: Frontmatter by type
description: The frontmatter format for each file type, conforming to Google's OKF v0.1 spec. Copy the block you need.
tags: [ai-os, template, frontmatter, okf]
timestamp: 2026-06-30
---

# Frontmatter by type

Conforms to **OKF v0.1** (Open Knowledge Format, Google). **Only `type:` is required**; the other OKF fields are *recommended*. A consumer preserves keys it doesn't know and doesn't reject a file over a missing field.

## OKF fields (in the spec's priority order)

```yaml
type:        # REQUIRED, the routing key (reference, runbook, partner…)
title:       # human-readable title
description: # one sentence, used to judge relevance on recall
resource:    # URI of the underlying asset (source URL, dashboard, file), if relevant
tags: [a, b]
timestamp: 2026-06-30   # ISO 8601, last substantive change
```

## Manence extensions (outside OKF, but allowed)

For facts that can go stale:

```yaml
valid_from: 2026-06-30        # since when it's true
superseded_by: ../path/v2.md  # when superseded (instead of overwriting)
status: canon                 # proposal | validated | canon | archived | rejected
```

For a workstream (`type: work`) only, its stable identity:

```yaml
work_id: 20260712-meta-back-to-school-campaign   # the folder name, as it stood at birth
```

- `work_id` is what a reader, a map or another MOS refers this workstream by: written at birth, identical to the folder name, and **never renamed** — closing moves the folder, and one day the folder may move again; the id doesn't follow.
- **No retrofit**: a workstream opened before this field simply hasn't got one, and nothing invents one for it after the fact.

For a workstream (`type: work`) only, what is waiting on a human:

```yaml
awaiting:
  - who: alexandre          # short stable handle within the MOS, no email, no full name
    what: authorize client quotes in ads
    kind: decision          # decision = a choice only this person can make | action = a gesture only this person can perform (click, pay, call)
    since: 2026-09-08       # the day the wait was born, not the last reminder
    blocks: going live      # optional: what the wait prevents
```

- `who`, `what`, `kind` and `since` are required on every entry; `blocks` is optional.
- `kind` takes exactly two values: `decision` or `action`.
- An absent field or an empty list (`awaiting: []`) means nothing is waiting; a settled wait is **removed** from the list (it is a present state, not a history) and its resolution is written in the About's Decisions section, and in the log if it changes a status.

## Reserved OKF files

- **`index.md`**, a folder listing, **without frontmatter** (see `index.template.md`).
- **`log.md`**, an append-only chronological log (a small `type: log` frontmatter is still tolerated).

## Ready-to-copy templates

### `reference`, a stable fact
```yaml
---
type: reference
title: <title>
description: <one sentence>
tags: []
timestamp: 2026-06-30
---
```

### `runbook`, a procedure
```yaml
---
type: runbook
title: <what to do>
description: <when to use it>
timestamp: 2026-06-30
---
```

### `log`, a journal (reserved name `log.md`)
```yaml
---
type: log
title: "Log: <project or folder>"
description: Append-only history.
timestamp: 2026-06-30
---
```
