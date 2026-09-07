# adapters/porting.md — Writing an adapter for any runtime

If your runtime is not one of the three with an adapter here, this file is the procedure. It takes
about an hour and the result is reusable forever.

An adapter answers seven questions. Nothing else in this pack changes.

---

## 1. What tier is it?

Run this test, because it determines what you are allowed to *design*, not just how you write it.

> Start an animation. Halfway through, change the target to somewhere else. What happens?

| Observation | Tier |
|---|---|
| It continues smoothly from where it is, at the speed it was going | **1** |
| It continues from where it is, but visibly restarts at zero speed | **2** |
| It jumps back to the start, or snaps to the old end, before starting again | **3** |

Most runtimes are **Tier 2**. A few "transition" mechanisms — usually the ones that work by
screenshotting before and after — are Tier 3 even in an otherwise capable environment, and that is
worth calling out separately in your adapter because it is genuinely surprising.

**Every runtime can reach Tier 1** by hand-integrating a spring (`spring.md` §3) against its frame
callback. The question is only whether it is worth it, and the answer is yes for gesture-driven
interactions and no for everything else.

Then apply the consequences from `SKILL.md` §2: Tier 2 wants `b ≤ 0.15`, Tier 3 wants
`dur ≤ 0.2s` on anything re-triggerable.

---

## 2. What are the four curves?

Find the runtime's expression for `out`, `in`, `inout`, `linear`, and write them down once as
constants. Two rules:

- **The target for `out` is a shallow easeOut**, cubic-bezier `(0.25, 0.1, 0.35, 1)`. If your
  runtime offers a named set, pick the *gentlest* plausible member — a "quadratic out" or "sine out",
  not a "quintic" or "exponential". Every table in this pack is tuned against the shallow curve, and
  substituting an aggressive one makes everything read as snapping.
- **If the runtime accepts an arbitrary curve, use the bezier directly.** If it accepts a sampled
  table, bake it. If it accepts only an enum, pick the closest and note the discrepancy in the
  adapter so the next person does not rediscover it.

---

## 3. How do you express a spring?

In descending order of preference:

1. **A native spring parameterised by duration and bounce** — pass `Dv` and `b` through unchanged.
2. **A native spring parameterised by stiffness and damping** — convert with `spring.md` §2:
   `k = ω₀²`, `c = 2ζω₀`, where `ω₀ = 2π/Dv` and `ζ = 1 − b`. State the mass convention; if the
   runtime has a mass parameter, set it to 1 and never touch it again.
3. **An arbitrary easing curve** — bake per `spring.md` §5, and play it over `t_settle`, **not**
   `Dv`. This is the step everyone gets wrong once.
4. **Nothing** — integrate it yourself. Forty lines, and it upgrades you to Tier 1 as a side effect.

Check whether the runtime **clamps progress to 0–1**. If it does, option 3 cannot express overshoot,
so `b > 0` is unavailable through that path — use option 4 or accept `b = 0`.

---

## 4. What is safe to animate?

Find the runtime's three tiers. They always exist, even with no DOM:

| Tier | The question to ask | Usually |
|---|---|---|
| ✅ composite | does changing this re-draw anything? | transform, opacity, layer tint |
| ⚠️ paint | does it re-draw one element? | colour, shadow, radius, blur, stroke |
| ❌ layout | does it re-solve the position of *other* elements? | width, height, position within a layout container |

The last row is the one to get right, and the test is behavioural: **change the property and see
whether a sibling moves.** If a sibling moves, you are on the layout tier, and animating it every
frame will cost you the frame.

Then find the runtime's **escape hatches** — its equivalent of "scale a wrapper instead of resizing"
and "cross-fade two pre-rendered states instead of animating the expensive property"
(`contrast.md` §6). Write those into the adapter; they are what the rest of the pack assumes exists.

---

## 5. How does an element survive its own removal?

`pitfalls.md` §1 in concrete terms. Find the mechanism — a promise you can await, a completion
callback, a presence wrapper, a manual "don't destroy until" flag — and write down:

- how you keep the thing alive,
- what happens if the exit is **interrupted** (this is the case that leaks),
- whether children get to play their own exits when a parent is removed (usually: no).

If you cannot answer these, you do not have exit animations yet, and you should find out before
designing one rather than after.

---

## 6. Where do the numbers live?

Write the token table from `feel.md` §11 in the runtime's own idiom — a constants table, a theme
object, a style sheet, a config asset. **One place, named tokens, no inline durations.**

Include the `lumin` token. It is the one people leave out, and its absence is why brightness ends up
sharing a duration with movement and reads as the colour chasing the object (`contrast.md` §5).

---

## 7. What is the reduced-motion signal?

Every platform has one. Find it, find its change notification, and implement the branch from
`recipes.md` §25 — **drop movement, keep the fade**. If the platform genuinely has no signal, expose
your own setting; shipping nothing is not an option.

---

## Conformance checklist

An adapter is done when someone holding only this pack and your adapter can build every recipe.

- [ ] Tier established by the retarget test, with the design consequence stated
- [ ] `out` / `in` / `inout` / `linear` named, with `out` verified as the *shallow* curve
- [ ] `spring(Dv, b)` mapped, including whether overshoot survives
- [ ] Composite / paint / layout tiers identified by the sibling-moves test
- [ ] The two escape hatches named: scale-a-wrapper, and cross-fade-two-states
- [ ] Transform origin / anchor point named — `recipes.md` §8 is impossible without it
- [ ] Exit lifecycle named, including the interrupted case
- [ ] Frame callback named, for hand-integrated springs and scroll smoothing
- [ ] Reduced-motion signal named, with its change notification
- [ ] Token table written in the runtime's idiom, `lumin` included
- [ ] Elevation translated: if there is no shadow primitive, say what replaces it
- [ ] A gotchas table, because every runtime has five and they cost everyone a day each

---

## Quick orientation for common runtimes

Not adapters — starting points, to be verified against the current version of each. The tier is the
default behaviour; every one of them reaches Tier 1 with a hand-integrated spring.

| Runtime | Tier | Spring | Notes |
|---|---|---|---|
| **SwiftUI** | 1 | native, and already parameterised by duration + bounce | the vocabulary in this pack matches its own almost exactly; `.animation` is interruptible and carries velocity |
| **Jetpack Compose** | 1 | native, `spring(dampingRatio, stiffness)` | `dampingRatio` **is** ζ, so pass `1 − b` directly; `Animatable` carries velocity across a retarget |
| **Flutter** | 2 | `SpringSimulation` via `AnimationController.animateWith` | the default `Tween` + `Curves` path is Tier 2; springs need the simulation API, which does take an initial velocity |
| **UIKit** | 2 | `UIViewPropertyAnimator`, or a spring initialiser taking initial velocity | the older `animateWithDuration` family is Tier 3 for practical purposes |
| **Unity (UI Toolkit / uGUI)** | 3 | none | animate from `Update`, or integrate; `AnimationCurve` is a baked curve and clamping is opt-in |
| **Godot** | 2 | none in `Tween` | `Tween` has `TRANS_*` enums, `EASE_*` directions; integrate in `_process` for springs |
| **GSAP** | 2 | plugin, or `CustomEase` from a baked table | `overwrite: "auto"` is the retarget mechanism; it restarts at zero velocity |
| **Terminal / TUI** | 3 | none | the frame rate is your constraint, not the curve; use `dur ≤ 0.2s` and `b = 0` throughout |

The pattern to notice: **the runtimes with the best motion are the ones that adopted duration +
bounce as the public vocabulary.** That is not a coincidence, and it is the reason this pack is
written that way rather than in stiffness and damping.
