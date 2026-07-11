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
