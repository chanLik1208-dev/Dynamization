# adapters/css.md — CSS only

**Tier: 2 for `transition`, 3 for `@keyframes`.**

A CSS transition retargets from the element's *current computed value*, so an interruption does not
snap back to the start — that is real Tier 2 behaviour and better than most people assume. What it
cannot do is carry velocity: the reversal restarts at zero speed and takes the full duration again.
A `@keyframes` animation is Tier 3 — restarting it replays from frame zero.

Consequences for design, from `SKILL.md` §2: keep `b ≤ 0.15`, and keep anything the user can
re-trigger at `dur ≤ 0.2s`.

---

## Mapping the vocabulary

| Spec | CSS |
|---|---|
| `dur 0.25` | `transition-duration: .25s` |
| `curve out` | `cubic-bezier(.25, .1, .35, 1)` — the shallow easeOut from `feel.md` §1 |
| `curve in` | `cubic-bezier(.4, 0, 1, 1)` |
| `curve inout` | `cubic-bezier(.4, 0, .2, 1)` |
| `curve linear` | `linear` |
| `spring(Dv, b)` | a baked `linear()` easing — see below |
| `stagger 0.04` | `transition-delay: calc(var(--i) * .04s)` with `--i` set per item |

Do not use the keyword `ease-out`. It is `cubic-bezier(0, 0, .58, 1)`, which is abrupt at the start;
the shallow curve above is what the tables in this pack are tuned against.

```css
:root {
  --e-out:  cubic-bezier(.25, .1, .35, 1);
  --e-in:   cubic-bezier(.4, 0, 1, 1);

  --t-feedback: .12s var(--e-out);
  --t-micro:    .2s  var(--e-out);
  --t-exit:     .15s var(--e-in);
  --t-lumin:    .13s var(--e-out);
}
```

---

## Springs: `linear()`

`linear()` takes a list of sampled progress values and interpolates between them linearly. That is
exactly the output of `spring.md` §5, and it is the only way to get overshoot out of CSS without
JavaScript.

```css
/* spring(0.3, 0.15) — Dv .3s, b .15, t_settle .32s */
--spring-enter: linear(
  0, 0.047, 0.156, 0.290, 0.427, 0.554, 0.663, 0.754, 0.826, 0.882, 0.923,
  0.953, 0.974, 0.988, 0.997, 1.002, 1.005, 1.006, 1.006, 1.006, 1
);
/* spring(0.35, 0) — the layout token, no overshoot, t_settle .41s */
--spring-layout: linear(
  0, 0.054, 0.171, 0.306, 0.438, 0.554, 0.653, 0.733, 0.797, 0.847, 0.885,
  0.915, 0.937, 0.953, 0.966, 0.975, 0.982, 0.987, 0.990, 0.993, 1
);

.panel { transition: translate .32s var(--spring-enter), scale .32s var(--spring-enter); }
```

Generate the stops with the closed form in `spring.md` §4 — never by hand, and never by copying a
curve whose parameters you cannot name. The two rules from that section apply in full:

- Play it over **`t_settle`**, not over `Dv`. Using `Dv` as the duration runs the whole curve fast.
- `linear()` accepts values above 1, so the overshoot survives. This is the one place CSS is *more*
  capable than a clamped tween API.

**A baked spring is a film of a spring.** It has no velocity, and interrupting it mid-flight and
retargeting gives you the spring curve applied to the *remaining* distance — which reads as a
strange double-settle. Below `0.2s` nobody notices; above it, they do.

---

## Exit animations

CSS has no keep-alive mechanism of its own, which is why `pitfalls.md` §1 exists. Three options,
in descending order of preference:

**1. `@starting-style` + `transition-behavior: allow-discrete`** — the modern answer. It lets a
`display` change participate in a transition, so an element can animate in from nothing and out to
nothing without any script.

```css
.toast {
  transition:
    opacity var(--t-micro),
    translate var(--t-micro),
    display .2s allow-discrete;
  opacity: 1;
  translate: 0;
}
@starting-style { .toast { opacity: 0; translate: 0 8px; } }  /* entry from */
.toast[hidden] { opacity: 0; translate: 0 4px; display: none; }
```

For anything in the top layer (`dialog`, popover) add `overlay .2s allow-discrete` to the same
transition list, or the element leaves the top layer instantly and the exit plays behind everything
else.

**2. A script that removes the node after the transition ends.** Listen for `transitionend`, and
**always pair it with a timeout fallback** — `transitionend` does not fire if the transition is
cancelled, interrupted, or removed by a reduced-motion query, and a node that never gets removed is
a leak (`pitfalls.md` §7).

**3. Keep it mounted and animate `visibility`.** `visibility` is discretely animatable and delays to
the end of the transition, which gets you a working fade-out with no script at all. It costs you the
element staying in the layout.

---

## Reflow / shared-element

CSS cannot measure, so a true reflow animation needs script (the measure-and-invert procedure in
`feel.md` §4). Two things CSS can do alone:

- **View Transitions** (`view-transition-name`, `::view-transition-*`) give you shared-element
  transitions declaratively. Note the constraint from `SKILL.md` §3.2: a view transition **snaps to
  the end state when interrupted**, so do not use it anywhere the user re-triggers quickly — a back
  button pressed twice, a tab bar. It is excellent for a route change and wrong for a toggle.
- `interpolate-size: allow-keywords` plus `calc-size()` lets `height: auto` be transitioned
  directly. That is a genuine improvement over measuring, but it is still a layout-tier animation
  (`pitfalls.md` §4) — fine for one accordion, not for a list of forty.

---

## Scroll

```css
@supports (animation-timeline: view()) {
  .reveal {
    animation: fade-up linear both;
    animation-timeline: view();
    animation-range: entry 20% entry 60%;
  }
}
```

Two things to know:

- `animation-timeline` is **scroll-linked**, not scroll-triggered. It runs backwards when the user
  scrolls back up. To get the fire-once behaviour of `recipes.md` §3 you need script.
- A scroll-driven animation is sampled from a real scroll position each frame, so it does not suffer
  the stepping described in `feel.md` §7 — the smoothing advice there applies to values you compute
  yourself in a scroll handler, not to this.

Always feature-query it. The fallback is the end state, visible, unanimated — never a permanent
`opacity: 0`.

---

## Performance

```css
/* ✅ transform and opacity */
.card { transition: translate var(--t-micro), scale var(--t-micro), opacity var(--t-micro); }

/* ⚠️ paint — fine here, measured on a long list */
.card { transition: box-shadow var(--t-lumin); }

/* ✅ the cross-fade workaround from contrast.md §6 */
.card { position: relative; box-shadow: var(--shadow-e2); }
.card::after {
  content: ""; position: absolute; inset: 0; border-radius: inherit;
  box-shadow: var(--shadow-e3);
  opacity: 0; transition: opacity var(--t-lumin);
  pointer-events: none;
}
.card:hover::after { opacity: 1; }
```

Use the individual `translate` / `scale` / `rotate` properties rather than the `transform`
shorthand. They compose without fighting each other, so a hover `scale` and a drag `translate` can
live in different rules.

Substitutions for the paint tier: `filter: drop-shadow()` instead of an animated `box-shadow`
(it composites in Chrome and Firefox), and `clip-path: inset(0 round Npx)` instead of an animated
`border-radius`.

`will-change` costs GPU memory per element. Never put it in a rule that matches a list.

---

## Reduced motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: .01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: .01ms !important;
    scroll-behavior: auto !important;
  }
}
```

**That blanket rule is a starting point, not the answer.** It violates `recipes.md` §25 by killing
the fade as well as the movement, which leaves the user with no signal that anything changed. Prefer
the targeted form: keep opacity and colour at full duration, and drop only the movement.

```css
@media (prefers-reduced-motion: reduce) {
  .panel { transition: opacity var(--t-micro); translate: none !important; scale: none !important; }
  .parallax { animation: none; }
}
```

---

## Gotchas specific to CSS

| Symptom | Cause |
|---|---|
| Transition does nothing on first paint | the element had no *previous* computed value to transition from — that is what `@starting-style` is for |
| Transition does nothing from `display: none` | needs `transition-behavior: allow-discrete` |
| `height: auto` won't transition | needs `interpolate-size: allow-keywords`, or measure and set a pixel value |
| A dialog's exit plays behind other content | missing `overlay ... allow-discrete` |
| The transition restarts when an unrelated class changes | you transitioned `all`; list the properties |
| A stagger via `transition-delay` also delays the *exit* | set the delay to `0s` in the exit rule, or the last item leaves last |
