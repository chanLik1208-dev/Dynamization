---
name: dynamization-core
description: A runtime-agnostic language pack for interfaces that move and read like the physical world. Two pillars — motion (the language of time: causality, springs, asymmetry, orchestration, interruption) and luminance contrast (the language of space: elevation, focus, state, and why light and dark themes express depth by different mechanisms). Every rule is stated as a physical quantity — seconds, pixels, damping ratio, luminance step — and then mapped onto whatever runtime you are in through an adapter. Use when writing any transition, keyframe, tween, spring, hover state, page transition, drag feedback, or elevation treatment — in CSS, the Web Animations API, Luau/Roblox, a game engine, a native toolkit, or any animation library — and when someone says an interface feels "stiff", "janky", "flat", "cheap", or "off" without being able to say why. Triggers on animation, transition, easing, spring, damping, stagger, parallax, scroll effect, drag, page transition, hover effect, skeleton, loading state, elevation, shadow, dark mode depth, tween, TweenService, TweenInfo, easing style — in any language, including 動畫/過場/緩動/彈簧/太生硬/沒層次, アニメーション/トランジション/硬い, 애니메이션/전환/딱딱하다, animación/transición/rígido.
---

# Dynamization Core

> Motion is the language of **time**: where a thing came from, where it went, whether you can touch it yet.
> Luminance is the language of **space**: what is on top, what is alive, where to look right now.
>
> Used separately, each does half a job. "Lifting" is not moving something up 4px — it is
> **displacement + a larger, softer shadow + a brighter surface, all at once.** Only then does the
> brain read it as *that came closer to me*.
>
> Interfaces that feel "stiff" or "flat" almost never suffer from an inelegant curve. They violate
> physical intuition, or they change only one property when they should change three.

**This pack owns no API.** Every judgment below is written as a number a human eye can verify —
a duration in seconds, a distance in pixels, a damping ratio, a luminance step. The runtime is a
detail you pick up in §2 and then stop thinking about.

## 0. Language

Every file in `references/` is English. Full translations of the judgment chapters
(this file, `feel`, `contrast`, `recipes`, `pitfalls`, `errata`) live in `i18n/<locale>/`:

| Locale | Path |
|---|---|
| 繁體中文 | `i18n/zh-TW/` |
| 日本語 | `i18n/ja/` |
| 한국어 | `i18n/ko/` |
| Español | `i18n/es/` |

**If you are answering the user in one of those languages, read that locale's files instead of the
English ones.** The adapters (`references/adapters/`) are English-only by design — they are mostly
code and API identifiers, where translation adds noise and drift.

## 1. The spec vocabulary

Everything in this pack is written in six terms. Learn them once; they are what gets ported.

| Term | Means | Written as |
|---|---|---|
| **dur** | how long, in seconds | `0.25s` |
| **curve** | `out` (fast then settling), `in` (slow then accelerating), `inout`, `linear` | `out` |
| **spring(Dv, b)** | a spring by **visual duration** `Dv` in seconds and **bounce** `b` in `0–1` | `spring(0.3, 0.15)` |
| **travel** | displacement, in px, from where the thing actually was | `y −4px` |
| **lumin** | a luminance step, in surface-value or shadow-tier terms | `surface +1 tier` |
| **stagger** | interval between siblings, in seconds | `0.04s` |

`spring(Dv, b)` is the load-bearing one. `Dv` is how long the movement **looks** like it takes,
excluding the settling tail — which is why a spring and a tween can be lined up against each other
at all. `b = 0` is no overshoot; `b = 1` is extremely bouncy. Never specify a spring in
stiffness/damping in a design conversation; nobody can picture those. Convert at the boundary →
`references/spring.md`.

## 2. Pick a runtime, then get out of its way

Read the adapter for the runtime you are in. **Read one. Not all of them.**

| Runtime | Adapter | Tier |
|---|---|---|
| CSS only — transitions, keyframes, `linear()` easing, view transitions | `references/adapters/css.md` | 3 |
| Web Animations API — `element.animate()`, `ScrollTimeline` | `references/adapters/waapi.md` | 2 |
| Luau / Roblox — `TweenService`, `TweenInfo`, `RunService` springs | `references/adapters/luau.md` | 2–1 |
| Anything else — a game engine, a native toolkit, an animation library | `references/adapters/porting.md` | — |

**Tier** is the one thing about a runtime that changes your *design*, not just your syntax:

| Tier | The runtime can | Consequence for what you design |
|---|---|---|
| **1** | interrupt an animation and carry **velocity** across the interruption | everything in this pack works as written |
| **2** | interrupt, but restarts from rest (velocity lost) | shorten reversals; prefer `b ≤ 0.15` so a restart is not visible as a hitch |
| **3** | only run to completion, or snap on interrupt | keep `dur ≤ 0.2s` on anything the user can re-trigger; fake springs with a sampled curve |

Most runtimes are Tier 2 by default and Tier 1 only if you hand-integrate the spring. The adapter
for your runtime says which, and how to climb a tier if the interaction needs it.

**Ask whether you need a library or a spring at all.** For one element, one state, and no
re-triggering, a plain tween is enough. Springs earn their complexity through interruptibility,
velocity handoff, and gesture handoff. If you use none of those, do not pay for them.

## 3. Five golden rules

Clear all five before writing any animation. Break one and the result feels *wrong* in a way people
usually cannot name.

### 1. Springs for position and size, tweens for opacity and colour

This is not taste, and it is not one library's opinion — it falls out of how the brain classifies
what it is looking at.

| What is animating | Use |
|---|---|
| position, rotation, skew — `x` `y` `rotate` and friends | `spring(0.28, 0.2)` — slight overshoot |
| the scale family | `spring(0.27, 0)` — **no overshoot, ever** |
| opacity, colour, blur, everything else | tween, `dur 0.3`, curve `out` |
| three or more keyframes | tween, `dur 0.8`, curve `inout` |

Why: things that occupy space (position, size) are read by the brain as **objects**, and objects
have mass and inertia. Opacity and colour are not objects — they are just *whether you can see it* —
so a spring there reads as a flicker.

**Corollary: never bounce a scale.** Bouncy growth reads as hitting glass.

Those four rows are a calibrated set. When you do not know what to use, use them unmodified.

### 2. Animations must be interruptible, and should carry velocity across the interruption

The single most important rule, and the one most often missed. Changing your mind mid-animation is
normal human behaviour.

- Use a spring where you can: a real spring integrator carries current velocity, so a reversal does
  not slam to a halt. **This — not bounciness — is the real reason springs beat tweens.**
- On a Tier 2/3 runtime, at minimum read the **current** value and animate from there, never from the
  nominal start. Snapping back to the start on every re-trigger is the classic stutter.
- Never chain animations with a timer that cannot be cancelled as a unit. Use a sequence or a
  parent-child orchestration that can be cancelled whole.
- Any "transition" mechanism that snaps to the end state when interrupted (many built-in
  page-transition APIs do) is unsuitable for anything the user can re-trigger quickly.

### 3. Entry and exit are not symmetric

Nobody should wait for something that is leaving.

```
enter:  opacity 0→1, y +8→0    dur 0.25   curve out
exit:   opacity 1→0, y 0→+4    dur 0.15   curve in
```

Exit runs at roughly **0.5–0.7×** the entry duration, over a **shorter distance**. A departing
element does not need to travel the full path — the eye only needs to know that it left.

### 4. Timing tiers: different jobs get different budgets

| Tier | dur | Where | Curve |
|---|---|---|---|
| Immediate feedback | `0.1–0.15s` | press scale, checkbox, focus ring | `out` or `spring(0.15, 0)` |
| Micro-interaction | `0.15–0.25s` | hover, tooltip, button colour | `out` |
| Component transition | `0.25–0.4s` | dropdown, modal, accordion, reflow | `spring(0.3, 0.15)` |
| Page / narrative | `0.4–0.8s` | route change, hero, multi-keyframe | `spring(0.5, 0.1)` + stagger |
| Over `1s` | almost certainly wrong | only loading, ambient, scroll-linked | — |

Hover animations **must not exceed 0.2s** — the cursor may already be gone.
Longer distances may run slightly longer, but **not linearly**: double the distance buys roughly
20–30% more time, not 100%.

> Full reasoning, the human semantics of spring parameters, orchestration rhythm, anti-patterns →
> `references/feel.md`

### 5. One event should change several properties in the same direction

A single property carries too little information. **Multiple properties moving together is what the
brain reads as one physical event.**

| To express | Change at least |
|---|---|
| Lift / approach (card hover) | `y` up + shadow larger and softer + surface brighter |
| Press / recess | scale down + shadow tightens + inner shadow + darker |
| Picked up (dragging) | scale up + wide shadow + raised depth order |
| Focus (modal opening) | content enters + **background dims** (the scrim must land first) |
| Disabled | a dedicated low-contrast colour token (**not** 50% opacity) |

Luminance is a *state signal*; displacement is a *process*. So **luminance changes faster than
movement** (roughly `0.12–0.15s` against `0.2–0.35s`).

In dark themes shadows are nearly invisible, so elevation has to be expressed by *brighter surfaces*
instead. Switching themes swaps the mechanism, not just the palette.

A third thing is sometimes on screen — **texture**: hatching, grain, a repeating rule. It is not a
channel and not a spec term. It is a modifier of `lumin` that reinforces the ground an object rests
on, and it must stay quieter than the smallest luminance step in your ladder, or it reads as noise
instead of material. Reinforcement and accent only → `contrast.md` §8.

> The optical model, light/dark token sets, the cost of animating each luminance property,
> accessibility floors → `references/contrast.md`

## 4. Routing table

Read the file for the job in front of you. **Do not read them all.**

| What you are doing | Read |
|---|---|
| Understanding what "natural" means; can't get the feel right; someone said it's "stiff" | `references/feel.md` ← **the time axis** |
| Elevation, shadow, dark mode, focus, scrim, contrast | `references/contrast.md` ← **the space axis** |
| Turning `spring(Dv, b)` into whatever numbers your runtime wants | `references/spring.md` |
| You want a finished effect to build from | `references/recipes.md` |
| Writing the actual calls in CSS / WAAPI / Luau | `references/adapters/<runtime>.md` |
| Your runtime has no adapter here | `references/adapters/porting.md` |
| Nothing animates, it janks, exit won't fire, the reversal stutters | `references/pitfalls.md` |
| **Nothing looks broken, and you are about to say you are done** | `references/errata.md` ← **read it before you ship** |

Non-English locales: substitute `i18n/<locale>/` for `feel`, `contrast`, `recipes`, `pitfalls`, `errata`.

## 5. Accessibility is not optional

Anything that **moves or scales a large element** must respect a reduced-motion preference. Every
platform exposes one; the adapter names it for your runtime.

The correct behaviour is not "turn animation off". It is: **disable displacement and scale, keep
opacity and colour.** The user still learns that the screen changed; it cross-fades instead of
sliding. Parallax, autoplaying video and infinite loops always need an explicit branch on top.

## 6. Performance red lines

The universal law: **compositing is cheap, painting is expensive, layout is ruinous.** Every runtime
has some version of these three tiers, even ones with no DOM.

- ✅ **Always safe**: transform (translate / scale / rotate) and opacity — they never reflow anything
- ⚠️ **Paint** (measure it): shadows, corner radius, background colour, blur — fine on small
  elements, dangerous on large ones or long lists
- ❌ **Layout** (avoid): width, height, top, left, margin, padding, border width — animating these
  re-solves the layout of everything around them, every frame

The standard escape hatch for an expensive property is to **pre-render both states and cross-fade
their opacity** rather than animating the expensive property itself. That trick appears in
`contrast.md` §6 for shadows and generalises to almost everything in the ⚠️ row.

## 7. Where the numbers come from

The parameter tables in this pack are a calibrated set, cross-checked against the defaults shipped by
widely used animation implementations and against the perceptual literature they were tuned on. They
are stated here as plain numbers precisely so that **you never have to fetch a vendor's
documentation to use this pack**, and so that nothing here rots when a library changes its API.

Where this pack and your runtime's own documentation disagree about *what an API does*, the
runtime's documentation wins — it is describing its own behaviour. Where they disagree about *what
feels right*, prefer this pack, then verify with your own eyes: a 0.3s spring either reads as an
object or it does not, and that is not a matter of opinion you need a citation for.
