---
type: reference
title: Double value
description: "Every useful interaction does two things at once: it moves the work forward AND leaves behind a reusable trace. Law L8, the bridge between Execution and Memory, borrowed from LIVING REFERENCE / CANON FLOTANT (JP Noto)."
tags: [ai-os, double-valeur, living-reference, jp-noto]
timestamp: 2026-07-02
---

# Double value

## What it is

The "**one stone, two birds**" principle: every useful interaction does **two things at once**: it moves the work forward **and** leaves a **reusable trace** (a decision, a validation, a canonized item). This is the framework's **law L8**.

A loop never emits *just* a deliverable: it **writes to memory by design**. This is the **bridge** between the **Execution layer (4)** and the **Memory layer (6)**, and it keeps the work from evaporating into the chat.

> Borrowed from **LIVING REFERENCE / CANON FLOTANT** (**JP Noto**), a parallel line of thought coming from a different angle (the design of guided assistants), with a striking convergence on the core. Named credit, the same way Karpathy gets credit for the wiki method. LIVING REFERENCE is a private project of JP Noto's: credited here without publishing its source.

## How it works

### The trace is not a by-product, it is half the work
You design each interaction so that it leaves behind the artifact that will be useful later: a good answer becomes a page ([methode-wiki](methode-wiki.md)), a decision becomes an entry in `log.md`, a validated fact becomes a reference you can build on.

### Human validation is an artifact (not a go/no-go)
A validation captures **who chose, what, why, and what was set aside**. One gesture, four benefits: **traceability**, **accountability**, **personalization** (the system learns your real preferences), **reuse**.
- **Notable overlap**: this is the **effective human oversight** that the GDPR (Art. 22) and the AI Act require the moment an AI assists a decision, a compliance invariant reached here from a purely creative angle.

### The status cycle (the trace matures)
Not everything the AI produces is usable. An item carries a **status** that evolves: `proposal → evaluated → validated → canonized → archived | rejected`. The step **proposal → canon** is *where the value is born*: `canon` = a reusable reference you can build on. You never treat a `proposal` as a fact.

## Why it is central

Without double value, an assistant **answers**: every session starts from scratch, and the experience never compounds. With it, the system **works alongside a workflow and banks the choices**: dynamic memory fills itself as the work happens, instead of being a separate documentation chore (that never gets done). This is what turns a series of interactions into an asset that grows.

## → Source (verified)
LIVING REFERENCE / CANON FLOTANT (JP Noto): private project, credited without publication. The 3 concepts drawn from it: double value (L8), traced validation (Spec §11), status cycle (Spec §6).

## → Alongside (the how)
- [Spec §11: Human validation = trace](../implementation/Spec.md): the `log.md` block that captures who/what/why/set-aside.
- [Spec §6: Status, freshness & expiry](../implementation/Spec.md): the `status:` field and the life cycle.

Related concepts: [Loops](loops.md) (what produces the trace) · [The memory model](modele-memoire.md) (where the trace is filed) · [Manifesto](../Manifesto.md).
