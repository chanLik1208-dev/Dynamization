# feel.md — What makes motion read as real

This file is not about APIs. It is about *why that animation looks fake*.

Roughly ordered by how badly each problem breaks the illusion: **fix the earlier ones first — the
later details only matter once they are right.**

Everything here is written in the spec vocabulary from `SKILL.md` §1. Nothing in it is specific to a
platform.

---

## 0. The one-line principle

> An animation should let people know what happened **without thinking about it**.
> The user should not notice the animation. They should notice *that the thing came from there*.

Any animation people stop to *admire* is, in a product, almost always too long.

---

## 1. Let the value being animated pick the parameters

When you are not sure what to use, **do not invent something**. Choose by *what kind of value is
moving*, and the choice is already made for you:

| What is animating | Use |
|---|---|
| three or more keyframes | tween, `dur 0.8`, curve `inout` |
| position and rotation — `x` `y` `z` `rotate` `skew` | `spring(0.28, 0.2)` — slight overshoot |
| the scale family | `spring(0.27, 0)` — **no overshoot** |
| everything else — opacity, colour, blur, filters | tween, `dur 0.3`, curve `out` |

The curve for that last row is worth naming precisely: a **shallower easeOut** than a platform
default — less abrupt at the start, equally soft at the end. In cubic-Bézier terms `(0.25, 0.1,
0.35, 1)`; in a runtime with named curves, "sine out" or "quad out" rather than "quint out".

**Three conclusions you can read straight off that table:**

1. Things that occupy space (position, size) → spring. Things that do not (opacity, colour) → tween.
2. Growing and shrinking **should not bounce**. Moving may.
3. The default duration is only `0.3s`. If yours is longer, you need a reason.

---

## 2. The real value of a spring is velocity handoff, not bounciness

Most people think spring = springy. Wrong. The property that matters most is that **when an
animation is interrupted, it continues from the current position at the current velocity** — rather
than stopping dead and starting over.

This is the line between *feels like an object* and *feels like a slideshow*.

Consider a value being toggled between two targets faster than either animation completes:

- A **tween** hard-restarts on every toggle. Each restart begins at zero velocity, so the motion
  visibly hitches at the moment the user acted — the exact moment they are watching.
- A **spring** with a moved target keeps its position and velocity. Reversing feels like shoving
  something with inertia, because that is literally what the integration is doing.

**The test: is this animation triggered by a direct user action?**

| Trigger | Use | Why |
|---|---|---|
| Drag, swipe, gesture, cursor following | **spring** (mandatory) | there is real velocity to carry |
| Movement or scaling caused by click / hover | **spring** | it can be interrupted repeatedly |
| Layout change caused by a toggle | **spring** | same |
| Enter / exit fades | **tween** | no velocity to carry; controllable timing matters more |
| Anything that must line up in time (stagger, sequence, video) | **tween** | springs have no reliable end time |
| Scroll linkage | bind directly, then smooth | see §7 |

On a **Tier 2** runtime (see `SKILL.md` §2) you can still interrupt, but velocity is lost. Two
mitigations, in order of preference: hand-integrate the spring for the handful of interactions that
are actually gesture-driven (`spring.md` §3 — it is fifteen lines), and everywhere else read the
**current** value at the moment of interruption and animate from there with `b ≤ 0.15`, which keeps
the restart small enough not to read as a hitch.

On **Tier 3**, do not fight it. Keep re-triggerable animations at `dur ≤ 0.2s`; below that threshold
a hard restart is under the perceptual floor and nobody sees it.

---

## 3. Tune with `Dv` + `b`, never with raw coefficients

Nobody can picture `stiffness: 400, damping: 32`, and the two knobs interact — so "make it a bit
quicker" turns into a redesign. Work in visual duration and bounce, convert once at the boundary.

The full conversion, the overshoot each bounce value actually produces, and the integrator →
`references/spring.md`.

The short version:

- `b` is *how much it overshoots*: `0.15` is about 0.6% past the target, `0.4` is about 9.5%.
- `Dv` is *how long it looks like it takes* — the tail happens after, which is why a spring and a
  tween can be lined up against each other at all.
- Scale is always `b = 0`.
- One `b` per product. Mixed bounce is the single clearest tell of an interface built by several
  people who never spoke.

---

## 4. Causality: things come from where they came from

Break this and no amount of curve polish will save it.

- A dropdown expands **from the control that opened it**, not fading in from screen centre. Put the
  transform origin (or anchor point) on the control.
- A modal grows from the card that was clicked. If your runtime can animate one element into
  another's position, do that; if it cannot, at minimum start the modal at the card's position and
  size and move it, rather than fading.
- A sidebar slides in from **its own side**, not from below.
- Deleting a list item makes the others **close the gap it left**, not jump.
- A toast enters from the corner it will rest in.

**The general procedure for a shared element**, in a runtime that has no built-in for it:

```
1. measure the source rect before the change      (position, size)
2. let the layout change happen instantly
3. measure the destination rect
4. apply the inverse transform to put it visually back at the source
5. animate that transform to identity
```

Only transforms move, so this is compositor-cheap even though it looks like a layout animation. It
works in any runtime that can measure a rectangle and apply a transform, which is all of them.

**A sense of scale for travel distance:** micro-interactions `4–12px`, component transitions
`16–40px`, percentages only for full-screen moves.

Fading in from `y: 100` is the most common mistake there is — for a tooltip, that distance reads as
*arriving from another room*.

---

## 5. Asymmetric entry and exit

| | Enter | Exit |
|---|---|---|
| Duration | `0.2 – 0.35s` | **0.5 – 0.7×** the entry |
| Curve | `out` / spring | `in` |
| Distance | full | **half or less** |
| Starting scale | `0.95` (not `0`) | `0.98` (barely shrinks) |

The reason: on entry the user has to *catch* new information and needs time to locate it. On exit
the thing is already irrelevant to them, and making them wait wastes their time.

`out` in and `in` out compose into an overall `inout` across the whole experience.

Never enter from `scale: 0`. That means *from nothing into being*, but UI elements almost always
come *from somewhere else*. `0.95` is plenty to say "this appeared".

**Exit is the one that needs a mechanism.** Entry animations are easy — the thing exists, animate
it. Exit requires keeping something alive after it has logically been removed. Every runtime solves
this differently, and it is the number one source of "the exit animation never plays". Find the
mechanism in your adapter *before* you design an exit, not after.

---

## 6. Orchestration: stagger is rhythm, not decoration

Ten things appearing simultaneously read as one blob. Offset them and you get order, and direction.

**Choosing the interval:**

| Item count | Interval | Total budget |
|---|---|---|
| 3–6 (menu, card row) | `0.04 – 0.06s` | ≤ 0.35s |
| 7–15 (list) | `0.02 – 0.04s` | ≤ 0.5s |
| Per character | `0.02 – 0.03s` | depends on length; past 1s switch to per word |
| > 20 | don't stagger individually | group them, or fade the whole thing |

**The total is a hard ceiling.** A `0.1s` stagger across 20 items is 2 seconds — by the time the last
one lands, the user is doing something else. Do the arithmetic before you write it.

**Direction should mean something:**
- **from first** — top to bottom, matches reading order, the safe choice
- **from last** — for collapsing, so it appears to roll back up
- **from centre** — opening outward, ceremonial, good for a hero
- **from the item the user just touched** — radiating outward ← **the strongest causal statement
  available**, and almost nobody uses it

**Container before children, children before container.** The container should open before content
pours in, and content should clear out before the container closes. If your runtime has no
parent/child orchestration, this is just two delays and one arithmetic check: the container's exit
must not start until the children's exit has finished.

---

## 7. Scroll: linked must be smoothed, triggered must fire once

**Scroll-triggered** (play on entering the viewport)

Fire **once**. This is almost always correct — animations that replay as the user scrolls back and
forth are nauseating, and the second play carries no information anyway.

Fire at about **30% visible**, not at the first pixel. A one-pixel threshold fires while the element
is still at the very edge of the screen, so the animation is over before it is properly in view.

**Scroll-linked** (a value bound to scroll position)

Scroll input is discrete — a wheel notch, a trackpad event, a frame of touch delta. Binding it
straight to a transform produces visible stepping. **Passing it through a spring is required, not a
nicety**: run a spring whose `target` is reset to the scroll value every frame, and animate from the
spring's output.

Use a *soft* spring here — around `spring(0.35, 0)`. It is a filter, not a movement; overshoot on a
scroll-linked value reads as the page fighting the user.

Two details that always bite:

- On mount, the spring must be **initialised at the current scroll value**, not at zero, or the page
  sweeps from the top on load.
- Pin things with whatever the platform's native sticky/anchor mechanism is, never by writing a
  position every frame from the scroll handler.

**Parallax amplitude**: a background layer moving at `0.3–0.5×` the foreground is plenty. More than
that stops reading as depth and starts reading as *the background is drifting*.

Parallax is the number one thing to disable under reduced motion.

---

## 8. Gesture feedback must begin within 100ms

Touch and click feedback is a **confirmation signal**, not an animation.

```
hover:  scale 1.03      spring(0.15, 0)
press:  scale 0.97      spring(0.15, 0)
drag:   scale 1.03  +  wide shadow  +  raised depth order
```

- **Press = smaller.** A finger pushing down should depress the thing. Growing is the wrong physics.
- Cap hover scale at `1.05`; beyond that, neighbouring elements look shoved aside.
- Large elements (cards, panels) need *smaller* hover scale (`1.01–1.02`), because actual
  displacement = scale × size, so the same ratio moves much further on a big element.
- Dragging always needs a distinct held state, so the user knows they have hold of it.
- Express a boundary **elastically**: let the user pull a little past the limit — resistance rising
  with distance, typically half the input past the edge — and spring back on release. A hard wall
  reads as a bug; elastic resistance reads as a rule.
- Whatever your press-feedback mechanism is, make sure it also fires for **keyboard activation**.
  A button that visibly depresses on click and does nothing on Enter is worse than one that never
  depresses at all.

---

## 9. Waiting and uncertainty

- **Under 1 second**: no spinner. A spinner that flashes is more irritating than a plain wait.
- **1–5 seconds**: a skeleton. Its shimmer should be slow (`1.5–2s` per pass) and low contrast — it
  signals *still here*, it should not compete for attention.
- **Over 5 seconds, or with known progress**: a progress bar, and it **never goes backwards**.
- With optimistic updates, insert the new item in its final form (optionally at reduced opacity) and
  only animate a rollback on failure. **Making the success path invisible is the best animation
  there is.**

Ambient looping effects (breathing, pulsing, shimmer): amplitude small enough to be *noticeable but
not readable*, period `≥ 1.5s`, and always disabled under reduced motion.

---

## 10. Anti-patterns

| Anti-pattern | Why it's wrong | Instead |
|---|---|---|
| `dur 0.5` on everything | no tiering: if everything is equally important, nothing is | the timing tiers in `SKILL.md` §3.4 |
| Fading in from `y: 100` / `scale: 0` | distance too large; reads as arriving from another screen | `y 8–16px`, `scale 0.95` |
| Bouncing a scale | hitting-glass feel | `b = 0` |
| `linear` for movement | nothing in the physical world starts and stops at constant speed | `out` or a spring; `linear` is for scroll linkage and endless rotation only |
| Exit as long as entry | makes people wait for something already irrelevant | cut exit to 0.5–0.7× |
| Scroll-triggered animations that replay | nauseating, and carries no information the second time | fire once |
| Stagger without doing the arithmetic | the last item lands two seconds later | interval × count ≤ 0.5s |
| Animating width / height / top / left | triggers layout, drops frames | transforms, plus the measure-and-invert trick in §4 |
| Chaining with uncancellable timers | cannot be interrupted, and drifts | a sequence that can be cancelled as a unit |
| Only tested in the light theme | shadows are invisible on dark surfaces | see `contrast.md` |
| No reduced-motion handling | causes vertigo for some users | `SKILL.md` §5 |
| `b = 0` and `b = 0.4` on the same page | the interface looks assembled from parts | one token set for the whole product |
| Relying on an "animation finished" callback for real logic | never fires if interrupted | drive state independently; animation is presentation |

---

## 11. Define tokens; stop tuning by hand

The other half of feeling natural is **consistency**. Within a product, actions that mean the same
thing should share the same timing and curve. Write this once, in whatever your runtime's config
format is:

```
feedback :  dur 0.12   curve out          # press, checkbox, focus ring
micro    :  dur 0.2    curve out          # hover, tooltip
enter    :  spring(0.3,  0.15)            # component entry
exit     :  dur 0.15   curve in           # component exit
layout   :  spring(0.35, 0)               # reflow
page     :  spring(0.5,  0.1)             # route change
stagger  :  0.04
lumin    :  dur 0.13   curve out          # brightness, colour, shadow tier
```

Note the last row: luminance gets its own token because it must be **faster** than the movement it
accompanies (`contrast.md` §5). If your token set has no luminance entry, brightness will end up
sharing the movement duration and read as *the colour chasing the object*.

After that, override in a single component only when you need to deviate — and only when you can
say why.
