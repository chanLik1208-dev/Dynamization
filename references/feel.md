# feel.md — What makes motion read as real

This file is not about APIs. It is about *why that animation looks fake*.

Roughly ordered by how badly each problem breaks the illusion: **fix the earlier ones first — the
later details only matter once they are right.**

---

## 0. The one-line principle

> An animation should let people know what happened **without thinking about it**.
> The user should not notice the animation. They should notice *that the thing came from there*.

Any animation people stop to *admire* is, in a product, almost always too long.

---

## 1. Motion's defaults are already a calibrated set of taste

When you are not sure what parameters to use, **write nothing**. Motion picks its default by *what
kind of value is animating*, and that logic is itself the answer.

The numbers below are from the `motion-dom` source, `getDefaultTransition()` — not the docs pages,
whose spring defaults are wrong:

```js
// three or more keyframes
{ type: "keyframes", duration: 0.8 }

// transforms, excluding scale: x / y / z / rotate* / skew*
{ type: "spring", stiffness: 500, damping: 25, restSpeed: 10 }   // underdamped, slight overshoot

// scale / scaleX / scaleY
{ type: "spring", stiffness: 550, damping: 30, restSpeed: 10 }   // critically damped, no overshoot
// special case: when the target is 0, damping = 2*sqrt(550) ≈ 46.9
// (a harder stop, so shrinking to zero does not judder)

// everything else: opacity / color / backgroundColor / filter / width ...
{ type: "keyframes", ease: [0.25, 0.1, 0.35, 1], duration: 0.3 }
// that curve is a shallower version of the browser default ease —
// less abrupt at the start, equally soft at the end
```

**Three conclusions you can read straight off that table:**

1. Things that occupy space (position, size) → spring. Things that do not (opacity, colour) → tween.
2. Growing and shrinking **should not bounce**. Moving may.
3. The default duration is only `0.3s`. If yours is longer, you need a reason.

The `spring()` function's own defaults (`springDefaults`):
`stiffness: 100, damping: 10, mass: 1, velocity: 0, duration: 800ms, bounce: 0.3, visualDuration: 0.3s`

---

## 2. The real value of a spring is velocity handoff, not bounciness

Most people think spring = springy. Wrong. The property that matters most in Motion is that
**when an animation is interrupted, it continues from the current position at the current
velocity** — rather than stopping dead and starting over.

This is the line between *feels like an object* and *feels like a slideshow*.

```jsx
// User toggles rapidly → a tween hard-restarts every time and reads as stutter
<motion.div animate={{ x: open ? 200 : 0 }} transition={{ duration: 0.3 }} />

// A spring carries velocity; rapid toggling feels like shoving something with inertia
<motion.div
  animate={{ x: open ? 200 : 0 }}
  transition={{ type: "spring", visualDuration: 0.3, bounce: 0.2 }}
/>
```

**The test: is this animation triggered by a direct user action?**

| Trigger | Use | Why |
|---|---|---|
| Drag, swipe, gesture, cursor following | **spring** (mandatory) | there is real velocity to carry |
| Movement or scaling caused by click / hover | **spring** | it can be interrupted repeatedly |
| Layout change caused by a toggle | **spring** | same |
| Enter / exit fades | **tween** | no velocity to carry; controllable timing matters more |
| Anything that must line up in time (stagger, sequence, video) | **tween** | springs have no reliable end time |
| Scroll linkage | bind the value directly, smooth with `useSpring` | see §7 |

---

## 3. Tune springs with `bounce` + `visualDuration`, never `stiffness` / `damping`

Nobody can picture the result of `stiffness: 400, damping: 32, mass: 1.2`. You can only guess and
re-guess. Use the two parameters that carry human meaning:

```jsx
transition={{
  type: "spring",
  visualDuration: 0.3,  // seconds. How long it looks like it takes to arrive (excluding the bouncy tail)
  bounce: 0.2,          // 0 = no bounce, 1 = extremely bouncy
}}
```

`visualDuration` exists exactly for this: **the bulk of the movement finishes within that time, and
the bouncy tail happens after.** That is why it can be lined up against a tween's `duration`, and
why `duration` + spring cannot.

**What bounce values mean:**

| bounce | Feel | Where |
|---|---|---|
| `0` | crisp, professional, weighty | enterprise UI, data tables, panels, **any `scale`** |
| `0.1 – 0.2` | alive but restrained | **the right answer most of the time** — buttons, cards, menus |
| `0.3 – 0.4` | playful, toy-like | consumer apps, gamification, success feedback |
| `> 0.5` | theatrical | only when being deliberately funny or grabbing attention |

**Two hard rules:**
- `scale` is always `bounce: 0`. Bouncy growth reads as hitting glass.
- Keep bounce consistent across a screen. Mixed values make an interface look assembled from parts.

> Setting any of `stiffness` / `damping` / `mass` makes `bounce` and `duration` **completely
> inert**. Do not mix the two systems.

---

## 4. Causality: things come from where they came from

Break this and no amount of curve polish will save it.

- A dropdown expands **from the button that opened it**, not fading in from screen centre. Point
  `transformOrigin` at the button.
- A modal grows from the card that was clicked — use `layoutId` for a shared element, do not fade.
- A sidebar slides in from **its own side**, not from below.
- Deleting a list item makes the others **close the gap it left** (`layout` prop), not jump.
- A toast enters from the corner it will rest in.

```jsx
// ❌ Materialises from nowhere
<motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} />

// ✅ Grows out of the button
<motion.div
  style={{ transformOrigin: "top left" }}
  initial={{ opacity: 0, scale: 0.95, y: -4 }}
  animate={{ opacity: 1, scale: 1, y: 0 }}
/>

// ✅✅ Actually becomes that element
<motion.button layoutId="card-3" />
{open && <motion.div layoutId="card-3" />}
```

**A sense of scale for travel distance:** micro-interactions `4–12px`, component transitions
`16–40px`, percentages only for full-screen moves.

Fading in from `y: 100` is the most common mistake there is — for a tooltip, that distance reads as
*arriving from another room*.

---

## 5. Asymmetric entry and exit

| | Enter | Exit |
|---|---|---|
| Duration | `0.2 – 0.35s` | **0.5 – 0.7×** the entry |
| Curve | `easeOut` / spring | `easeIn` |
| Distance | full | **half or less** |
| Starting scale | `0.95` (not `0`) | `0.98` (barely shrinks) |

The reason: on entry the user has to *catch* new information and needs time to locate it. On exit
the thing is already irrelevant to them, and making them wait wastes their time.

`easeOut` in and `easeIn` out compose into an overall `easeInOut` across the whole experience —
which is precisely what the official docs recommend pairing with `AnimatePresence mode="wait"`.

Never enter from `scale: 0`. That means *from nothing into being*, but UI elements almost always
come *from somewhere else*. `0.95` is plenty to say "this appeared".

---

## 6. Orchestration: stagger is rhythm, not decoration

Ten things appearing simultaneously read as one blob. Offset them and you get order, and direction.

```jsx
const list = {
  show: { transition: { delayChildren: stagger(0.04) } },
  hide: { transition: { delayChildren: stagger(0.02, { from: "last" }) } },
}
```

**Choosing the interval:**

| Item count | Interval | Total budget |
|---|---|---|
| 3–6 (menu, card row) | `0.04 – 0.06s` | ≤ 0.35s |
| 7–15 (list) | `0.02 – 0.04s` | ≤ 0.5s |
| Per character | `0.02 – 0.03s` | depends on length; past 1s switch to per word |
| > 20 | don't stagger individually | group them, or fade the whole thing |

**The total is a hard ceiling.** `stagger(0.1)` across 20 items is 2 seconds — by the time the last
one lands, the user is doing something else. Do the arithmetic before you write it.

**Direction should mean something:**
- `from: "first"` (default) — top to bottom, matches reading order, the safe choice
- `from: "last"` — for collapsing, so it appears to roll back up
- `from: "center"` — opening outward, ceremonial, good for a hero
- `from: <index>` — radiating from the item the user just touched ← **the strongest causal statement available**

`when: "beforeChildren"` / `"afterChildren"`: the container should open before content pours in
(entry), and content should clear out before the container closes (exit).

---

## 7. Scroll: linked must be smoothed, triggered must fire once

**Scroll-triggered (play on entering the viewport)**
```jsx
<motion.div
  initial={{ opacity: 0, y: 12 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.3 }}
/>
```
`once: true` is **almost always correct**. Animations that replay as the user scrolls back and
forth are nauseating, and the second play carries no information anyway.

`amount: 0.3` fires when 30% is visible — the default `"some"` (one pixel) is too early, firing
while the element is still at the edge of the screen.

**Scroll-linked (value bound to scroll position)**
```jsx
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] })
const smooth = useSpring(scrollYProgress, {
  stiffness: 100, damping: 30, restDelta: 0.001, skipInitialAnimation: true,
})
```
Scroll input is discrete, so binding it directly produces visible stepping. **Passing it through
`useSpring` is required, not a nicety.**
`skipInitialAnimation: true` prevents a sweep from 0 to the current position on mount.

**Parallax amplitude**: a background layer moving at `0.3–0.5×` the foreground is plenty. More than
that stops reading as depth and starts reading as *the background is drifting*.

Parallax is the number one thing to disable under reduced motion.

---

## 8. Gesture feedback must begin within 100ms

Touch and click feedback is a **confirmation signal**, not an animation.

```jsx
<motion.button
  whileHover={{ scale: 1.03 }}                 // barely. 1.1 is a poster, not a button
  whileTap={{ scale: 0.97 }}                   // pressing shrinks, it does not grow
  transition={{ type: "spring", visualDuration: 0.15, bounce: 0 }}
/>
```

- **Press = smaller.** A finger pushing down should depress the thing. Growing is the wrong physics.
- Cap hover scale at `1.05`; beyond that, neighbouring elements look shoved aside.
- Large elements (cards, panels) need *smaller* hover scale (`1.01–1.02`), because actual
  displacement = scale × size, so the same ratio moves much further on a big element.
- Dragging always needs `whileDrag` (typically `scale: 1.03` plus a deeper shadow) so the user knows
  they have hold of it.
- `dragElastic` (default `0.5`) expresses the boundary: you can pull a little past the limit and it
  springs back, which reads better than a hard wall.
- Elements with `whileTap` become **keyboard accessible automatically** (`onTapStart` → `onTap`
  on Enter). Do not rebuild that.

---

## 9. Waiting and uncertainty

- **Under 1 second**: no spinner. A spinner that flashes is more irritating than a plain wait.
- **1–5 seconds**: a skeleton. Its shimmer should be slow (`1.5–2s` per pass) and low contrast — it
  signals *still here*, it should not compete for attention.
- **Over 5 seconds, or with known progress**: a progress bar, and it **never goes backwards**.
- With optimistic updates, insert the new item in its final form (optionally at reduced opacity) and
  only animate a rollback on failure. **Making the success path invisible is the best animation
  there is.**

Ambient `repeat: Infinity` effects (breathing, pulsing, shimmer): amplitude small enough to be
*noticeable but not readable*, period `≥ 1.5s`, and always disabled under reduced motion.

---

## 10. Anti-patterns

| Anti-pattern | Why it's wrong | Instead |
|---|---|---|
| `duration: 0.5` on everything | no tiering: if everything is equally important, nothing is | use the timing tiers in SKILL.md |
| Fading in from `y: 100` / `scale: 0` | distance too large; reads as arriving from another screen | `y: 8–16`, `scale: 0.95` |
| Bouncing a `scale` | hitting-glass feel | `bounce: 0` |
| `ease: "linear"` for movement | nothing in the physical world starts and stops at constant speed | `easeOut` or a spring; `linear` is for scroll linkage and endless rotation only |
| Exit as long as entry | makes people wait for something already irrelevant | cut exit to 0.5–0.7× |
| `whileInView` without `once` | replays on every scroll pass | `viewport={{ once: true }}` |
| Stagger without doing the arithmetic | the last item lands two seconds later | interval × count ≤ 0.5s |
| Animating `width` / `height` / `top` | triggers layout, drops frames | the `layout` prop, or transforms |
| Chaining with `setTimeout` | cannot be cancelled or interrupted, and drifts | a sequence, or variant orchestration |
| Only tested in light mode | shadows are invisible on dark surfaces | see `contrast.md` |
| No reduced-motion handling | causes vertigo for some users | `<MotionConfig reducedMotion="user">` |
| bounce 0 and 0.4 on the same page | the interface looks assembled from parts | one token set for the whole product |

---

## 11. Define tokens; stop tuning by hand

The other half of feeling natural is **consistency**. Within a product, actions that mean the same
thing should share the same timing and curve.

```js
// motion.tokens.js
export const T = {
  instant: { duration: 0.12, ease: "easeOut" },                    // feedback
  micro:   { duration: 0.2,  ease: "easeOut" },                    // hover / tooltip
  enter:   { type: "spring", visualDuration: 0.3,  bounce: 0.15 }, // component entry
  exit:    { duration: 0.15, ease: "easeIn" },                     // component exit
  layout:  { type: "spring", visualDuration: 0.35, bounce: 0 },    // reflow
  page:    { type: "spring", visualDuration: 0.5,  bounce: 0.1 },  // route change
  stagger: 0.04,
}
```

Set the site-wide default once:
```jsx
<MotionConfig transition={T.enter} reducedMotion="user">
```
After that, override in a single component only when you need to deviate — and only when you can
say why.
