# Dynamization Core

**A runtime-agnostic language pack for interfaces that move and read like the physical world.**

An [Agent Skill](https://docs.claude.com/en/docs/claude-code/skills) for Claude Code — and a
readable design document for anyone else. It states what makes motion feel real as **numbers a human
eye can verify**, and leaves the API to a swappable adapter.

<sub>
<a href="SKILL.md">English</a> ·
<a href="i18n/zh-TW/SKILL.md">繁體中文</a> ·
<a href="i18n/ja/SKILL.md">日本語</a> ·
<a href="i18n/ko/SKILL.md">한국어</a> ·
<a href="i18n/es/SKILL.md">Español</a>
</sub>

---

## Why this exists

Most animation documentation tells you *what the API does*. Almost none tells you **what makes an
animation feel real** — and that is where the work actually goes wrong.

Dynamization Core is built on two pillars:

- **Motion** — the language of **time**: where a thing came from, where it went, whether you can
  touch it yet.
- **Luminance contrast** — the language of **space**: what is on top, what is alive, where to look
  right now.

Used separately, each does half a job. *Lifting* is not moving something up 4px — it is
**displacement + a larger, softer shadow + a brighter surface, all at once.** Only then does the
brain read it as *that came closer to me*.

Interfaces that feel "stiff" or "flat" almost never suffer from an inelegant curve. They violate
physical intuition, or they change one property where they should change three.

## What makes this one different

This is a derivative of [Dynamization](https://github.com/chanLik1208-dev/Dynamization), which
distilled one specific animation library into judgment. **This version owns no API and depends on no
vendor.**

Everything is stated in six terms — a duration in seconds, a curve, a spring by visual duration and
bounce, a travel distance in pixels, a luminance step, a stagger interval — and then mapped onto
whatever you are actually writing in through an adapter. The judgment chapters never mention a
library.

Three consequences:

1. **It works in Luau, in a game engine, in a native toolkit, in a terminal.** The web is one target
   among several, not the assumption.
2. **Nothing here rots when a library changes its API.** The numbers are the artefact.
3. **The spring is explained rather than imported.** `references/spring.md` gives the conversion,
   the integrator, the closed form and the baking procedure — about sixty lines of maths that
   replace the main reason people reach for a library in the first place.

It also adds a concept the original had no need for: a **tier**, which is what a runtime can do
about interruption. Tier 1 carries velocity across a retarget, Tier 2 restarts at zero speed, Tier 3
cannot be interrupted at all. That single fact changes what you are allowed to *design*, not just
how you write it, and every adapter states it first.

## What's inside

```
SKILL.md                    Spec vocabulary, runtime tiers, five golden rules, routing table
references/
  feel.md                   The time axis — what makes motion read as real
  contrast.md               The space axis — the expressive power of light and dark
  spring.md                 spring(Dv, b) on any runtime: conversion, integrator,
                            closed form, and how to bake one into a curve
  recipes.md                26 patterns, each as an intent and a specification
  pitfalls.md               Symptom → cause → fix, grouped by mechanism
  errata.md                 The mistakes this pack invites — failures that throw nothing,
                            log nothing, and ship
  adapters/
    css.md                  CSS only — transitions, linear() springs, @starting-style
    waapi.md                Web Animations API — retargeting, composite modes, timelines
    luau.md                 Luau / Roblox — TweenService, UIScale, CanvasGroup,
                            nine-slice elevation, a Luau spring
    porting.md              Write an adapter for any runtime: seven questions and a
                            conformance checklist
i18n/<locale>/              Full translations of the judgment chapters
                            (zh-TW, ja, ko, es)
```

The judgment chapters — `SKILL`, `feel`, `contrast`, `recipes`, `pitfalls`, `errata` — are translated. The
adapters stay English-only by design: they are mostly code and API identifiers, where translation
adds noise and invites drift.

## Seeing it

Three reference implementations are published from `docs/`:
**https://chanlik1208-dev.github.io/Dynamization/**

The exhibition site is the substantive one — every transition on it is built from the tokens in
`feel.md` §11, and most of the entries in `errata.md` were found by building it. The comparison
sheet plots a spring from the closed form in `spring.md` and runs the baked CSS `linear()` springs
as themselves. The test bench isolates one effect with a replay button and a live timing readout,
so an argument about timing can be measured rather than described.

## Using it

Drop the directory into your skills folder:

```bash
git clone <this repo> ~/.claude/skills/dynamization-core
```

Claude Code picks it up from the frontmatter in `SKILL.md`. Or just read it — it is a design
document that happens to be machine-readable.

**Read one adapter, not all of them.** The routing table in `SKILL.md` §4 is there to stop you
loading the whole pack for a hover state.

## Adding a runtime

`references/adapters/porting.md` is the procedure, and it is short. An adapter answers seven
questions — tier, curves, springs, property cost tiers, exit lifecycle, where the tokens live, and
the reduced-motion signal — and then the other five files apply unchanged.

If you write one, the conformance checklist at the end of that file is what "done" means.

## Licence

MIT, inherited from the original. See `LICENSE`.
