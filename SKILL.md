---
name: dynamization
description: A language pack for interfaces that move and read like the physical world. Two pillars — motion (the Motion / motion.dev API for React, Vue and vanilla JS, plus the judgment for what makes an animation feel real) and luminance contrast (elevation, focus, state, and why light and dark themes express depth by different mechanisms). Use when writing any transition, @keyframes, animate(), whileHover, AnimatePresence, layout animation, or box-shadow elevation — and when someone says an interface feels "stiff", "janky", "flat", "cheap", or "off" without being able to say why. Triggers on animation, transition, easing, spring, stagger, parallax, scroll effect, drag, page transition, hover effect, skeleton, loading state, elevation, shadow, dark mode depth, framer-motion, motion.dev — in any language, including 動畫/過場/太生硬/沒層次, アニメーション/トランジション/硬い, 애니메이션/전환/딱딱하다, animación/transición/rígido.
---

# Dynamization

> Motion is the language of **time**: where a thing came from, where it went, whether you can touch it yet.
> Luminance is the language of **space**: what is on top, what is alive, where to look right now.
>
> Used separately, each does half a job. "Lifting" is not moving something up 4px — it is
> **displacement + a larger, softer shadow + a brighter surface, all at once.** Only then does the
> brain read it as *that came closer to me*.
>
> Interfaces that feel "stiff" or "flat" almost never suffer from an inelegant curve. They violate
> physical intuition, or they change only one property when they should change three.

## 0. Language

Every file in `references/` is English. Full translations of the judgment chapters
(this file, `feel`, `contrast`, `recipes`, `pitfalls`) live in `i18n/<locale>/`:

| Locale | Path |
|---|---|
| 繁體中文 | `i18n/zh-TW/` |
| 日本語 | `i18n/ja/` |
| 한국어 | `i18n/ko/` |
| Español | `i18n/es/` |

**If you are answering the user in one of those languages, read that locale's files instead of the
English ones.** The API references (`react`, `javascript`, `vue`, `doc-index`) are English-only by
design — they are mostly code and API identifiers, where translation adds noise and drift.

## 1. Pick a runtime first

| Situation | Use | Import |
|---|---|---|
| React / Next.js | Motion for React | `npm i motion` → `import { motion } from "motion/react"` |
| React Server Component | same, different path | `import * as motion from "motion/react-client"` |
| Vue / Nuxt | Motion for Vue | `npm i motion-v` → `import { motion } from "motion-v"` |
| Vanilla JS / Webflow / Astro | vanilla | `npm i motion` → `import { animate } from "motion"` |
| A single hover colour change | **plain CSS**, no library | — |
| Spring curves without a library | generate CSS `linear()` | `references/recipes.md` §CSS springs |

**Ask whether you need a library at all.** For one element, one state, and no need for
interruption, a CSS `transition` is enough. Motion earns its bytes through interruptibility,
velocity handoff, layout animation, gestures, orchestration, and scroll linkage. If you use none
of those, do not ship 18kb.

## 2. Five golden rules

Clear all five before writing any animation. Break one and the result feels *wrong* in a way people
usually cannot name.

### 1. Springs for position and size, tweens for opacity and colour

This is not taste. It is Motion's own default logic, verified against the `motion-dom` source:

| What is animating | What Motion gives you |
|---|---|
| `x` `y` `rotate` `skew` and other transforms | spring, `stiffness: 500, damping: 25` (slight overshoot) |
| the `scale` family | spring, `stiffness: 550, damping: 30` (critically damped, **no overshoot**) |
| `opacity` `color` `filter`, everything else | tween, `ease: [0.25, 0.1, 0.35, 1]`, `duration: 0.3` |
| three or more keyframes | tween, `duration: 0.8` |

Why: things that occupy space (position, size) are read by the brain as **objects**, and objects
have mass and inertia. Opacity and colour are not objects — they are just *whether you can see it* —
so a spring there reads as a flicker.

**Corollary: never bounce a `scale`.** Bouncy growth reads as hitting glass. That is exactly why
Motion critically damps scale.

### 2. Animations must be interruptible, and must carry velocity across the interruption

The single most important rule, and the one most often missed. Changing your mind mid-animation is
normal human behaviour.

- Use a spring: Motion carries current velocity automatically, so a reversal does not slam to a halt.
  **This — not bounciness — is the real reason springs beat tweens.**
- With keyframes, write `null` as the first frame: `animate={{ x: [null, 100, 0] }}` — continue from
  the **current value** instead of snapping back to the start.
- Never chain animations with `setTimeout`. Use a sequence (`animate([...])`) or variant
  orchestration (`when` / `delayChildren`) — those can be cancelled as a unit.
- The View Transitions API is **not** interruptible (interrupting snaps to the end state). If you
  need interruption, use Motion's `layout`.

### 3. Entry and exit are not symmetric

Nobody should wait for something that is leaving.

```jsx
// Enter: slower, easeOut (fast then settling — like sliding in and stopping)
initial={{ opacity: 0, y: 8 }}
animate={{ opacity: 1, y: 0, transition: { duration: 0.25, ease: "easeOut" } }}
// Exit: fast, easeIn (slow then accelerating away)
exit={{ opacity: 0, y: 4, transition: { duration: 0.15, ease: "easeIn" } }}
```

Exit runs at roughly **0.5–0.7×** the entry duration, over a **shorter distance**. A departing
element does not need to travel the full path — the eye only needs to know that it left.

### 4. Timing tiers: different jobs get different budgets

| Tier | Duration | Where | Curve |
|---|---|---|---|
| Immediate feedback | `0.1–0.15s` | press scale, checkbox, focus ring | `easeOut` or a spring |
| Micro-interaction | `0.15–0.25s` | hover, tooltip, button colour | `easeOut` |
| Component transition | `0.25–0.4s` | dropdown, modal, accordion, layout | spring, `visualDuration: 0.3` |
| Page / narrative | `0.4–0.8s` | route change, hero, multi-keyframe | spring or tween + stagger |
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
| Press / recess | `scale` down + shadow tightens + inner shadow + darker |
| Picked up (dragging) | `scale` up + wide shadow + raised z |
| Focus (modal opening) | content enters + **background dims** (the scrim must land first) |
| Disabled | a dedicated low-contrast colour token (**not** `opacity: 0.5`) |

Luminance is a *state signal*; displacement is a *process*. So **luminance changes faster than
movement** (roughly `0.12–0.15s` against `0.2–0.35s`).

In dark themes shadows are nearly invisible, so elevation has to be expressed by *brighter surfaces*
instead. Switching themes swaps the mechanism, not just the palette.

> The optical model, light/dark token sets, the cost of animating each luminance property,
> accessibility floors → `references/contrast.md`

## 3. Routing table

Read the file for the job in front of you. **Do not read them all.**

| What you are doing | Read |
|---|---|
| Understanding what "natural" means; can't get the feel right; someone said it's "stiff" | `references/feel.md` ← **the time axis** |
| Elevation, shadow, dark mode, focus, scrim, contrast | `references/contrast.md` ← **the space axis** |
| Writing React — props, hooks, components | `references/react.md` |
| Writing vanilla JS — `animate()`, `scroll()`, motion values | `references/javascript.md` |
| Writing Vue, or porting a React example | `references/vue.md` |
| You want a finished effect to paste | `references/recipes.md` |
| Nothing animates, it janks, exit won't fire, layout distorts | `references/pitfalls.md` |
| You need the official text, or an API not covered here | `references/doc-index.md` + §6 |

Non-English locales: substitute `i18n/<locale>/` for the first two, plus `recipes` and `pitfalls`.

## 4. Accessibility is not optional

Anything that **moves or scales a large element** must handle reduced motion. One line, site-wide:

```jsx
import { MotionConfig } from "motion/react"
<MotionConfig reducedMotion="user">{children}</MotionConfig>
```

`reducedMotion="user"` automatically disables transform and layout animations while **preserving**
opacity and colour — exactly what iOS does. It still tells the user the screen changed; it just
cross-fades instead of sliding.

For finer control use `useReducedMotion()` (same name in Vue). Parallax, autoplaying video and
infinite loops always need an explicit branch.

## 5. Performance red lines

Only `transform` and `opacity` reach the compositor in every browser. Those are always safe.

- ❌ Animating `width` / `height` / `top` / `left` / `margin` / `border-width` triggers layout — it will drop frames
- ⚠️ `box-shadow` / `border-radius` / `background-color` trigger paint — fine on small elements, measure on large ones
- ✅ For animated shadows use `filter: drop-shadow(...)`; for animated corners use `clip-path: inset(0 round Npx)`
- ✅ To animate size or position, use the `layout` prop — Motion implements it with transforms, which is one of the main reasons the library exists
- ⚠️ Motion's independent transforms (`x`, `scale`) are backed by CSS variables and are **not** hardware accelerated. When that matters, write `transform: "translateX(100px) scale(2)"`

## 6. Fetching the current official text

The docs site supports content negotiation, so the authoritative source is always one command away
(and will be newer than this pack):

```bash
curl -sL -H "Accept: text/markdown" https://motion.dev/docs/<slug>
# e.g. https://motion.dev/docs/react-transitions
```

Or `scripts/fetch-doc.sh react-transitions`. Every slug is listed in `references/doc-index.md`.

**Where this pack and the official docs disagree, the official text wins** — with one known
exception: the docs pages state the spring `stiffness` default as `1`, which is **wrong**. The
source says `100`. Following the docs there gives you a spring that barely moves.
