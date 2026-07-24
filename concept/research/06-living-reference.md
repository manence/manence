---
type: research
title: "LIVING REFERENCE (JP Noto): the mechanisms carried over"
description: "Source record for LIVING REFERENCE, JP Noto's method for human-AI production. What Manence carried over in two waves (2026-06-30 and 2026-07-24, the second under written agreement), what converged independently, and what was deliberately left out."
tags: [ai-os, research, living-reference, source-externe]
timestamp: 2026-07-24
---

# LIVING REFERENCE

> **Source**: **LIVING REFERENCE** (formerly circulated as *CANON FLOTANT*), by **JP Noto** — a method for human-AI production on long-running projects, developed independently of this framework and in parallel with it. State at the time of writing: SPEC 0.18, corpus 0.9.109, status Public Draft; **the repository will be made public shortly**, and its canonical URL will be added here at that point. Method texts CC BY-NC-SA 4.0; using the method is expressly free.

## What it is

Nothing an AI produces carries authority on its own: every output is a **proposal**, and only an explicit user **validation** (what, how far, on what) promotes it to a **reference** — dated, scoped, revisable. The working context of each step is then built by rule (a sliding window of the last validated items + the project's invariants), never by accumulation. Around that core: a status model on three axes (maturity, scope, freshness), the **double-value principle** (each useful interaction advances the work *and* leaves its trace), a **trace sieve** that bounds what gets recorded, partial validation with facet inheritance, and five verifiable **drift tests**. Every claim in the corpus carries its own evidence rank, and the method states its falsification conditions.

## Carried over — first wave (2026-06-30, from an early extract)

1. **Double value** → law **L8**: every useful interaction moves the work forward and emits a reusable trace. An architectural adoption: the bridge between the Execution and Memory layers.
2. **Human validation as a traced artifact** → **Spec §11**: who chose, what, why, what was set aside.
3. **The status cycle** (`proposal → validated → canon → archived | rejected`) → the `status:` field of **Spec §6**. Precision owed to the record: only the *lifecycle* comes from this source — the freshness fields of §6 (`valid_from`, `superseded_by`) came from the bi-temporal model of Zep/Graphiti ([source 03](03-memory-architectures.md)); the two lines of thought converged on freshness independently.

## Carried over — second wave (2026-07-24, from the full corpus, under written agreement with the author)

4. **The trace sieve** → **Spec §11**: a trace is emitted iff the interaction changes a status, a scope or a constraint, or if losing it would force a redo. It replaces "important" — an adjective — with a test, and it is the bound that keeps L8 from degenerating into a journal.
5. **The pruning test** → **Spec §8**: what no living decision ties and whose loss would force nothing to be redone gets consolidated or archived.
6. **The forward-looking revision trigger** → the optional `review_when:` field of **Spec §6**: a date or event after which a page stops being authoritative on its own. The missing third leg next to `valid_from` (the past) and `superseded_by` (the succession).
7. **The drift tests** → the weekly review's drift checks: five questions answered against the referential, never against an impression (contradiction of a canon, a rejected option coming back, a local decision applied beyond its scope, a proposal treated as settled, a validated constraint ignored).

## Converged independently (not borrowed)

Active vs global referential ≈ static/dynamic + context-as-RAM (L1, L3) · "no XXL prompt, structured context" ≈ context engineering · "a reference stays living" ≈ §6 freshness (via Graphiti, see above). Two independent derivations of the same core — a robustness signal both ways; LIVING REFERENCE's own LINEAGE documents the Manence side of this relationship, with the reuse held to its exact rank.

## Deliberately not carried over

Facet inheritance (partial validation), the formal sliding window, and declared profiles: built for content *generation* pipelines, where the near-miss is the normal regime. An operations OS validates deliverables and decisions, not facets of an image; importing the vocabulary machinery would add exactly the bureaucracy the sieve exists to forbid. If Manence one day hosts a generation workflow, the right move is a LIVING REFERENCE profile next to the OS, not a merge into it.

## Sources

- LIVING REFERENCE, JP Noto — canonical repository: *to be made public shortly; URL will be added here* (SPEC, whitepaper, seven operational sheets, SLIDING CANON profile, LINEAGE with prior-art journal).
- Reuse agreement: written agreement of 2026-07-24 covering the second wave; the citation will be completed with the canonical URL once the repository is public.
