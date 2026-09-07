# spring.md — `spring(Dv, b)` on any runtime

This file exists so the rest of the pack can say `spring(0.3, 0.15)` and mean something exact,
whatever you are writing in. It is the piece a library would normally hide from you.

---

## 1. Why not stiffness and damping

Nobody can picture the result of `stiffness: 400, damping: 32, mass: 1.2`. You can only guess and
re-guess, and the two numbers interact — raising stiffness makes a spring both faster *and* bouncier,
so "a bit quicker" turns into a redesign.

The two parameters that carry human meaning are orthogonal:

| Parameter | Symbol | Means | Range |
|---|---|---|---|
| **visual duration** | `Dv` | how long the movement *looks* like it takes, ignoring the settling tail | `0.1 – 0.8s` |
| **bounce** | `b` | how much it overshoots | `0` – `1` |

Change one, the other stays. That is the whole reason to work in these terms.

**What bounce actually buys you**, as a percentage the eye can check — this is peak overshoot past
the target:

| b | ζ | Overshoot | Feel | Where |
|---|---|---|---|---|
| `0` | 1.00 | 0% | crisp, professional, weighty | enterprise UI, data tables, panels, **any scale** |
| `0.1` | 0.90 | 0.2% | barely alive | subtle reflow |
| `0.15` | 0.85 | 0.6% | alive but restrained | **the right answer most of the time** — buttons, cards, menus |
| `0.2` | 0.80 | 1.5% | confident | component entry, layout |
| `0.3` | 0.70 | 4.6% | playful | consumer apps, success feedback |
| `0.4` | 0.60 | 9.5% | toy-like | gamification |
| `0.5` | 0.50 | 16% | theatrical | deliberately funny, or grabbing attention |
| `0.7` | 0.30 | 37% | cartoon | almost never |

**Two hard rules:**
- Scale is always `b = 0`. Bouncy growth reads as hitting glass.
- Keep `b` consistent across a screen. Mixed values make an interface look assembled from parts.

---

## 2. The conversion

A spring is a second-order system. Take unit mass (`m = 1`) — mass is redundant with the other two
parameters, and carrying it around only creates a third knob that does nothing new.

```
ζ  = 1 − b                 damping ratio
ω₀ = 2π / Dv               undamped natural frequency, rad/s

k = ω₀²                    stiffness
c = 2 ζ ω₀                 damping coefficient
```

Worked, for the tokens this pack uses:

| Token | Dv | b | ω₀ | k | c |
|---|---|---|---|---|---|
| feedback | `0.15` | `0` | 41.9 | 1755 | 83.8 |
| micro | `0.2` | `0.1` | 31.4 | 987 | 56.5 |
| enter | `0.3` | `0.15` | 20.9 | 439 | 35.6 |
| layout | `0.35` | `0` | 18.0 | 322 | 35.9 |
| page | `0.5` | `0.1` | 12.6 | 158 | 22.6 |

Going the other way, when you inherit a spring written in `k` and `c` and want to know what it
actually does:

```
ω₀ = √(k / m)      Dv = 2π / ω₀      ζ = c / (2 √(k m))      b = 1 − ζ
```

**Use it on anything you are handed.** A commonly shipped default for transforms is
`k = 500, c = 25, m = 1`, which reads back as `Dv = 0.28s, ζ = 0.56, b = 0.44` — a **12% overshoot**.
That is considerably more playful than most product UI wants, and it is a good example of why you
should convert before trusting a number you copied. The same source's scale default,
`k = 550, c = 30`, reads back as `ζ = 0.64` — about **7% overshoot**, despite being described as
critically damped. Per §1, scale should be `b = 0`. Convert, look at the overshoot column, then
decide.

**Do not mix the two systems.** If you set `k` and `c` directly, `Dv` and `b` are no longer
describing anything. Pick one vocabulary per project — preferably `Dv`/`b`, converting at the
boundary.

---

## 3. Integrating it yourself (Tier 1)

This is about fifteen lines and it is what buys you velocity handoff. If the interaction involves
dragging, flinging, or rapid toggling, write this and stop looking for a library.

```
state: x (current), v (velocity), target

step(dt):
    # clamp and substep: a stiff spring integrated at a long frame time will explode
    dt = min(dt, 1/30)
    steps = ceil(dt / (1/240))
    h = dt / steps
    repeat steps times:
        a = -k * (x - target) + -c * v
        v = v + a * h
        x = x + v * h          # semi-implicit Euler: v updated first, then x

at_rest():
    return |x - target| < restDelta and |v| < restSpeed
```

**Semi-implicit Euler** (update velocity, *then* position with the new velocity) is stable where
plain Euler is not, and it is one line of difference. Use it.

**Rest thresholds**, expressed relative to the total distance `D = |x_start − target|` so they work
at any scale:

```
restDelta = 0.005 * D        # within half a percent of the target
restSpeed = 0.05 * D / Dv    # and moving slowly relative to the trip
```

When at rest, **snap `x` to `target` exactly** and stop stepping. Leaving a spring running at
sub-pixel amplitude burns a frame budget forever and is the most common cause of "the profiler says
this screen never idles".

**Velocity handoff — the entire point.** When the target changes mid-flight, change `target` and
touch nothing else. `x` and `v` carry over, and the reversal reads as shoving something with
inertia rather than a hard restart. When a drag ends, seed `v` with the pointer's release velocity
(in the same units per second) and the throw is free.

---

## 4. Closed form, for when you cannot own the frame loop

If your runtime only lets you supply *a function of time*, you need `x(t)` rather than an
integrator. Let `d = x − target` (so `d₀ = x_start − target`, and `v₀` is the initial velocity):

**Underdamped** (`ζ < 1`, i.e. `b > 0`), with `ω_d = ω₀√(1 − ζ²)`:
```
d(t) = e^(−ζω₀t) · [ d₀·cos(ω_d·t) + ((v₀ + ζω₀·d₀) / ω_d)·sin(ω_d·t) ]
```

**Critically damped** (`ζ = 1`, i.e. `b = 0`):
```
d(t) = e^(−ω₀t) · [ d₀ + (v₀ + ω₀·d₀)·t ]
```

**Overdamped** (`ζ > 1`), with `r₁,₂ = ω₀(−ζ ± √(ζ² − 1))`:
```
A = (v₀ − r₂·d₀) / (r₁ − r₂)      B = d₀ − A
d(t) = A·e^(r₁t) + B·e^(r₂t)
```

Then `x(t) = target + d(t)`.

**How long until it is over** — the number you need to size a keyframe track or a `linear()` stop
list. Take "over" as within 0.5% of the target:

```
ζ < 1   t_settle ≈ ln( 1 / (0.005 · √(1 − ζ²)) ) / (ζ ω₀)     upper bound: the decay envelope
ζ = 1   t_settle ≈ 7.43 / ω₀                                   the (1 + ω₀t) term decays slower
```

The `ζ < 1` form bounds the envelope rather than the oscillation inside it, so it overshoots the
true answer by up to 25% when the last peak happens to fall early. When you are baking a curve and
the exact number matters, **solve it numerically** — walk `t` forward until `|d(t)|` stays under the
threshold — and only use the closed form as a sanity check.

The tokens from `feel.md` §11, solved:

| Token | Dv | b | ζ | ω₀ | k | c | t_settle | overshoot |
|---|---|---|---|---|---|---|---|---|
| feedback | `0.15` | `0` | 1.00 | 41.9 | 1755 | 83.8 | `0.18s` | 0% |
| micro | `0.2` | `0.1` | 0.90 | 31.4 | 987 | 56.5 | `0.18s` | 0.2% |
| enter | `0.3` | `0.15` | 0.85 | 20.9 | 439 | 35.6 | `0.32s` | 0.6% |
| layout | `0.35` | `0` | 1.00 | 18.0 | 322 | 35.9 | `0.41s` | 0% |
| page | `0.5` | `0.1` | 0.90 | 12.6 | 158 | 22.6 | `0.44s` | 0.2% |
| playful | `0.3` | `0.4` | 0.60 | 20.9 | 439 | 25.1 | `0.44s` | 9.4% |

Compare the last two rows: **same `Dv`, and the tail is 35% longer** for the bouncy one. That gap is
exactly what `Dv` is for — the movement reads as finishing at 0.3s in both cases, and only the
settling differs. It is also why you cannot line a spring up against a tween using `t_settle`, and
can using `Dv`.

---

## 5. Baking a spring into a curve (Tier 3)

When the runtime accepts only a fixed easing curve, sample the closed form from rest
(`d₀ = −1`, `v₀ = 0`, `target = 1`) and emit the values.

```
N     = 20                       # 20 is enough below 0.3s; 40–60 for long, bouncy springs
T     = t_settle
for i in 0..N:
    t      = i/N * T
    out[i] = 1 + d(t)            # normalised progress, may exceed 1 where it overshoots
out[N] = 1                       # pin the endpoint exactly
```

Two baked, so you can check your implementation against them:

```
spring(0.3, 0.15) over 0.32s
0.000, 0.047, 0.156, 0.290, 0.427, 0.554, 0.663, 0.754, 0.826, 0.882, 0.923,
0.953, 0.974, 0.988, 0.997, 1.002, 1.005, 1.006, 1.006, 1.006, 1.000

spring(0.3, 0.4) over 0.44s
0.000, 0.086, 0.279, 0.503, 0.712, 0.877, 0.993, 1.061, 1.090, 1.094, 1.081,
1.061, 1.039, 1.021, 1.007, 0.998, 0.993, 0.991, 0.991, 0.993, 1.000
```

The second one shows what bounce looks like as data: it crosses 1 at about 30% of the track, peaks
9.4% past the target, and then comes back *under* — a real spring undershoots on the way back, and
leaving that out is what makes hand-drawn "bouncy" curves look wrong.

Then `out` is your easing table, played over a total duration of `T` — **not** `Dv`. Two things go
wrong here and both are avoidable:

- **Play it over `Dv` and the whole thing runs fast**, because you dropped the tail from the clock
  but not from the curve.
- **Clamp the values into `0–1` and the overshoot disappears**, leaving you a slightly odd easeOut.
  Any runtime that rejects out-of-range progress cannot express `b > 0` this way; use `b = 0` there
  and get your liveliness from the multi-property rule (SKILL §3.5) instead.

A baked curve is not interruptible in any meaningful sense — it is a fixed film of a spring. That is
the whole content of "Tier 3". Keep those animations at `dur ≤ 0.2s` so a restart is not visible.

---

## 6. Choosing not to use a spring

A spring is the right default for position and size. It is the wrong tool for:

| Situation | Why | Use instead |
|---|---|---|
| Opacity, colour, blur | not objects; a spring reads as a flicker | tween, `dur 0.3`, curve `out` |
| Anything that must land on a beat — stagger, sequences, audio/video sync | springs have no reliable end time | tween |
| Scroll-linked values | the input is already a position, not an impulse | bind directly, then **smooth** with a spring driven toward the scroll value |
| Endless rotation, marquees, shimmer | there is no target to converge on | linear tween, repeating |

The scroll row is the subtle one: you are not springing *to* the scroll position, you are running a
spring whose `target` is continuously reset to it. That is what removes the stepping from discrete
scroll input — see `feel.md` §7.
