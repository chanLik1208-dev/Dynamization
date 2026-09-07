# adapters/waapi.md — Web Animations API

**Tier: 2 by default, 1 if you own the frame loop.**

`element.animate()` gives you real animation objects you can inspect, retarget and cancel — which is
more than CSS offers — but it still interpolates a fixed track from a start value to an end value.
Velocity is not carried across a retarget unless you compute it.

The trade against a library: no dependency, no bundle, and everything in this pack maps onto it
directly. What you give up is exit lifecycle management, reflow animations, and gesture handling —
all three of which you write yourself, and all three of which are described generically in
`feel.md` and `pitfalls.md`.

---

## Mapping the vocabulary

| Spec | WAAPI |
|---|---|
| `dur 0.25` | `{ duration: 250 }` — **milliseconds**, unlike everything else in this pack |
| `curve out` | `easing: "cubic-bezier(.25,.1,.35,1)"` |
| `curve in` | `easing: "cubic-bezier(.4,0,1,1)"` |
| `curve linear` | `easing: "linear"` |
| `spring(Dv, b)` | `easing: "linear(...)"` baked per `spring.md` §5, `duration: t_settle * 1000` |
| `stagger 0.04` | `{ delay: i * 40 }` |

```js
const E = {
  out: "cubic-bezier(.25,.1,.35,1)",
  in:  "cubic-bezier(.4,0,1,1)",
}
const T = {
  feedback: { duration: 120, easing: E.out },
  micro:    { duration: 200, easing: E.out },
  exit:     { duration: 150, easing: E.in  },
  lumin:    { duration: 130, easing: E.out },
  enter:    { duration: 320, easing: SPRING_ENTER },   // the linear() string from spring.md
}
```

Note the unit trap in the first row. Every duration in this pack is in seconds; every duration in
WAAPI is in milliseconds. Convert once, in the token table, and never inline.

---

## Interruption: the whole game

**Do not start a second animation on a property that is already animating.** You get two tracks
compositing against each other, and the result is neither.

```js
function retarget(el, keyframes, options) {
  for (const a of el.getAnimations()) {
    a.commitStyles()   // write the current computed value onto the element
    a.cancel()
  }
  return el.animate(keyframes, { ...options, fill: "both" })
}
```

`commitStyles()` then `cancel()` is the Tier 2 move from `pitfalls.md` §2: it freezes the element at
where it actually is, so the new animation starts from there instead of snapping back. Write the
keyframes with an **implicit start** (a one-entry array, or `null` as the first value) so the new
animation picks up the committed value:

```js
retarget(el, { translate: ["0 100px"] }, T.enter)   // one keyframe = "from wherever you are"
```

**Reversal is free and better.** If the target is simply the previous start, do not build a new
animation — flip the existing one:

```js
anim.playbackRate = -anim.playbackRate
```

This preserves `currentTime`, so a half-open menu closes from half-open, over the remaining half of
the duration. It is the closest thing WAAPI has to velocity handoff, and it costs one line.

**Climbing to Tier 1.** When an interaction is genuinely gesture-driven — drag, fling, cursor
following — stop using `animate()` and run the integrator from `spring.md` §3 on
`requestAnimationFrame`, writing `el.style.translate` each frame. Fifteen lines, and you get
velocity handoff and mid-flight retargeting for free. Use WAAPI for everything else.

---

## Fill, and the leak it causes

`fill: "forwards"` keeps the end value applied after the animation finishes — which is what you
want visually and a slow leak in practice, because every filling animation stays attached to the
element and to the style resolution for that element, forever.

```js
const a = el.animate(kf, { ...T.enter, fill: "forwards" })
await a.finished
a.commitStyles()
a.cancel()          // now the value lives in an inline style, and the animation is gone
```

**`a.finished` rejects with an `AbortError` when the animation is cancelled**, which is exactly the
behaviour `pitfalls.md` §7 warns about — so either `catch` it or use it only for cleanup, never for
application logic.

---

## Exit animations

WAAPI's advantage over CSS here: `finished` is a promise, so the keep-alive is just an `await`.

```js
async function remove(el) {
  const a = el.animate(
    { opacity: [1, 0], translate: ["0", "0 4px"] },
    { ...T.exit, fill: "forwards" }
  )
  try { await a.finished } catch {}   // cancelled: fall through and remove anyway
  el.remove()
}
```

The `catch` is load-bearing. Without it, an interrupted exit leaves the node in the tree forever.

Under reduced motion, or when the tab is backgrounded and the animation never runs, the same
`catch` keeps the removal correct.

---

## Scroll

```js
const timeline = new ViewTimeline({ subject: el, axis: "block" })
el.animate(
  { opacity: [0, 1], translate: ["0 12px", "0"] },
  { timeline, rangeStart: "entry 20%", rangeEnd: "entry 60%", fill: "both" }
)
```

`ScrollTimeline` and `ViewTimeline` are **scroll-linked**: the animation runs backwards when the
user scrolls up. For the fire-once behaviour of `recipes.md` §3, use an `IntersectionObserver` with
`threshold: 0.3` and `unobserve` on the first hit — that is the correct tool, and it is two lines.

Feature-detect. The fallback is the end state, visible.

---

## Composite modes

`composite: "add"` layers an animation on top of whatever else is animating the same property
instead of replacing it. This is the clean answer to the classic conflict where a hover scale and a
press scale fight:

```js
el.animate({ scale: [1, 1.02] }, { ...T.micro, fill: "forwards", composite: "add" })
```

Use it sparingly and deliberately. Additive animations are hard to reason about in aggregate, and
`getAnimations()` cleanup has to account for them.

---

## Performance

The property tiers are the same as `SKILL.md` §6. Two WAAPI specifics:

- Animations on `transform`, `translate`, `scale`, `rotate`, `opacity` and `filter` can run **off the
  main thread**, but only if the animation is not touching anything else. Adding a single
  `backgroundColor` keyframe to the same `animate()` call demotes the whole animation to the main
  thread. **Split them into two calls.**
- Check with `anim.effect.getComputedTiming()` and, in Chrome DevTools, the Animations panel, which
  reports whether an animation was composited and why not.

---

## Reduced motion

```js
const reduced = matchMedia("(prefers-reduced-motion: reduce)")

function enter(el) {
  const kf = reduced.matches
    ? { opacity: [0, 1] }                              // keep the fade
    : { opacity: [0, 1], translate: ["0 8px", "0"] }   // fade and move
  return el.animate(kf, reduced.matches ? T.micro : T.enter)
}
```

Listen for changes on the query (`reduced.addEventListener("change", …)`) — the preference can be
toggled while your page is open, and a parallax that keeps running after the user turns it on is
worse than one that never respected it.

---

## Gotchas specific to WAAPI

| Symptom | Cause |
|---|---|
| The animation snaps back at the end | no `fill`, and no inline style holding the end value |
| A promise rejection appears in the console on every interruption | `finished` rejects on `cancel()`; catch it |
| Two animations on one property produce garbage | the second did not cancel the first — see `retarget()` above |
| The element is stuck at the end value and CSS no longer affects it | a filling animation is still attached; `commitStyles()` + `cancel()` |
| It runs on the main thread despite only animating transforms | a non-compositable property is in the same keyframe set |
| Durations are 1000× off | WAAPI is milliseconds; this pack is seconds |
| `easing` applies per-keyframe, not overall | `easing` in the *options* is the overall curve; `easing` on a *keyframe* applies to the segment that starts there |
