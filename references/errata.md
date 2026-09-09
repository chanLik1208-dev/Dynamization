# errata.md — The mistakes this pack invites

`pitfalls.md` is for when something is visibly broken and you are looking up the symptom. **This
file is for when nothing looks broken at all.**

Every entry below is a mistake made by someone who had read the relevant chapter and was following
it. That is the point: these are not failures of knowledge, they are failures of verification. None
of them throws. None of them logs a warning. Most of them ship.

Read this before you write, and again before you say you are done.

---

## How to use it

Each entry names the **silent symptom** first, because that is all you will get. Then the wrong
code, then why a competent implementer writes it anyway, then the fix, then **one check you can
actually run**.

The checks are the load-bearing part. A rule you cannot verify is a rule you will break.

---

## A. You followed the chapter, and the environment ate it

### A1. A clipping ancestor cancels the pre-rendered shadow

**Silent symptom:** hover changes position but the elevation never arrives. In a light theme, where
`contrast.md` §2 puts *all* the layering in the shadow, the hover ends up carrying movement alone —
which is exactly the half-expression §5 of `SKILL.md` warns about.

```css
/* ❌ */
.card { border-radius: 4px; overflow: hidden; box-shadow: var(--e2); }
.card::after { inset: 0; box-shadow: var(--e3); opacity: 0; transition: opacity .13s; }
.card:hover::after { opacity: 1; }
```

**Why it gets written:** `contrast.md` §6 tells you to cross-fade a pre-rendered shadow rather than
animate `box-shadow`, and that advice is correct. Separately, a rounded card with an image at the
top needs its corners clipped, and `overflow: hidden` on the card is the reflex. Both decisions are
right on their own. A shadow paints *outside* the element's box, so the clip erases it — and erases
it silently, because the transition still runs on a layer nobody can see.

```css
/* ✅ clip the thing that needs clipping, not the thing casting the shadow */
.card { border-radius: 4px; box-shadow: var(--e2); }          /* no overflow here */
.card .media { border-radius: 3px 3px 0 0; overflow: hidden; }
```

**The check:** hover the element and watch the *shadow*, not the card. If you cannot see the shadow
change, walk up the ancestors looking for `overflow: hidden`, `clip-path`, or a `CanvasGroup`-style
compositing wrapper. The same trap applies to a focus ring drawn with `outline-offset`.

---

### A2. A baked spring played over `Dv` runs fast

**Silent symptom:** the motion is right in shape but reads as hurried, and the overshoot is a snap
rather than a settle.

```css
/* ❌ the curve is 0.32s long; the clock says 0.3s */
transition: translate .3s var(--spring-enter);
```

**Why it gets written:** every other row in the token table is a duration, so `spring(0.3, 0.15)`
reads as "0.3 seconds". It is not. `Dv` is the *visual* duration — where the movement appears to
finish — and the baked curve necessarily includes the settling tail after it. The two numbers differ
by more the bouncier the spring: for `b = 0.4` the tail is 35% of the total.

```css
/* ✅ */
transition: translate .32s var(--spring-enter);   /* t_settle, from spring.md §4 */
```

**The check:** in `spring.md`'s token table, every spring has both a `Dv` and a `t_settle`. If the
duration in your CSS equals the `Dv`, it is wrong. Grep your stylesheet for the `Dv` values as
durations — `.3s`, `.35s`, `.5s` — next to a `linear(` easing.

---

### A3. Clamped progress silently removes the bounce

**Silent symptom:** `b` makes no difference. `spring(0.3, 0.15)` and `spring(0.3, 0.4)` look
identical, so you conclude bounce is too subtle to matter and stop using it.

**Why it gets written:** you did the sampling correctly, but the runtime rejects or clamps easing
values outside `0–1`. CSS `linear()` accepts them; many enum-based and curve-asset systems do not,
and they clamp rather than error.

**The fix:** find out which you are on, once, and write it in the adapter. If progress is clamped,
`b > 0` is unavailable through a baked curve — either integrate the spring (`spring.md` §3) or
accept `b = 0` and get your liveliness from the multi-property rule instead.

**The check:** bake `spring(0.3, 0.4)`, whose peak is `1.094`, and animate a 400px translate with
it. If the element never travels past 400px, your progress is clamped.

---

### A4. The transition lives on the hover state, so leaving is instant

**Silent symptom:** entering the hover is smooth, leaving snaps. Half your interactions feel fine
and you cannot say why the other half feel cheap.

```css
/* ❌ */
.card:hover { translate: 0 -4px; transition: translate .2s; }
```

**Why it gets written:** it reads naturally — "on hover, move up, taking 0.2s" — and it works in the
direction you were testing. The declaration only exists while the selector matches, so on hover-out
there is no transition to run.

```css
/* ✅ the transition belongs to the resting state */
.card { transition: translate var(--t-micro); }
.card:hover { translate: 0 -4px; }
```

**The check:** move the pointer *away* and watch. Always test the exit of every state, not the
entry — this is `feel.md` §5 applied to your own testing, and it catches A4, A5 and C1 at once.

---

### A5. Nothing animates in, because there was no previous value

**Silent symptom:** the element simply appears. No error, no half-played animation.

**Why it gets written:** a transition interpolates between two computed values, and an element that
has just been inserted — or was `display: none` — has no first value to leave from. The declaration
is fine; there is nothing for it to do.

**The fix:** in CSS, `@starting-style` plus `transition-behavior: allow-discrete`
(`adapters/css.md`). In script, set the start value, force a reflow, then set the end value — the
`void el.offsetWidth` line that looks like a no-op and is not. In a runtime with no such mechanism,
mount at the start value and change it on the next frame.

**The check:** if an entry animation involves an element that did not exist a frame ago, you need
one of those three. There is no fourth option.

---

### A6. The animation plays inside a container that is still transparent

**Silent symptom:** an effect that provably runs — you can see the class applied, the timing is
right, a screenshot mid-flight shows it — and that no reader ever sees. It is finished by the time
the thing containing it becomes visible.

**Why it gets written:** two scroll observers, written weeks apart, each correct alone. The section
fades in at one threshold; the element inside it animates at another. Nothing in either piece of
code mentions the other, and the bug only appears where the two overlap — so the element above the
fold, which has no fading ancestor, works perfectly and gets used as the test case.

**The fix:** sequence them. The container's entrance starts first; the contents follow it, offset by
enough that the container is actually on screen. Where a runtime has parent/child orchestration,
this is what `beforeChildren` is for (`feel.md` §6); where it does not, it is one delay.

**The check:** for every entrance animation, ask what its ancestors are doing at that moment. If any
of them is mid-fade, mid-scale, or still at opacity 0, you have this bug. **Test the animation in
the place it will ship, not in the first place on the page that was convenient.**

---

### A7. A threshold a wrapped phrase can never satisfy

**Silent symptom:** the effect fires for some elements and not others, with no pattern you can see
at first — and the ones that fail are the longer ones.

```js
/* ❌ */
new IntersectionObserver(fn, { threshold: 0.5 }).observe(inlinePhrase)
```

**Why it gets written:** `0.5` is the reflexive value, and it is right for a block. But an inline
element that wraps across two lines has a bounding box spanning from the start of the first fragment
to the end of the second — and most of that box is the empty gutter beside the two line fragments.
The observed ratio is computed against that box, so a phrase can be entirely on screen and still
never reach the threshold you asked for.

**The fix:** low thresholds for inline targets — `0.1–0.25` — or observe a block-level wrapper
instead. And where the consequence of not firing is invisible content (§A7's neighbour above),
add the timeout guard.

**The check:** make one of your test phrases long enough to wrap. Almost nobody does, which is why
this survives review.

---

## B. You broke a rule this pack states plainly

### B1. Moving something with layout properties

**Silent symptom:** correct-looking motion that drops frames on a mid-range phone and is fine on
your machine.

```js
/* ❌ — and this was written by someone implementing this very pack */
flier.style.transition = "left .32s var(--spring), top .32s var(--spring), width .32s, height .32s";
flier.style.left = to.left + "px";
```

**Why it gets written:** you have two rectangles from `getBoundingClientRect()`, and they are
expressed in `left`/`top`/`width`/`height`. Animating the numbers you already hold is the shortest
path from measurement to motion, and the shape of the result is right, so nothing prompts you to
look again.

```js
/* ✅ place it at the destination, move it with a transform */
flier.style.left = to.left + "px";
flier.style.top = to.top + "px";
flier.style.width = to.width + "px";
flier.style.height = to.height + "px";
flier.style.translate = (from.left - to.left) + "px " + (from.top - to.top) + "px";
flier.style.scale = from.width / to.width;
/* next frame: animate both back to identity */
```

**The check:** grep every animation you wrote for `left`, `top`, `width`, `height`, `margin`,
`padding`. Each hit needs a reason. The measure-and-invert procedure in `feel.md` §4 exists so that
the answer is always a transform.

---

### B2. One event, one property

**Silent symptom:** the interaction responds, but nobody can tell you what it means. "It feels
cheap" with no further detail is the usual report.

**Why it gets written:** each property is added at a different moment. Movement goes in when you
build the component; the shadow is a design review note; the surface change gets lost in a refactor.
No single commit looks wrong.

**The fix:** treat the rows in `SKILL.md` §3.5 as a minimum, not a menu. Lift is displacement **and**
a larger softer shadow **and** a brighter surface. Press is scale down **and** a tighter shadow
**and** darker.

**The check:** count the properties changing per interaction. Fewer than three for a lift or a
press means it is unfinished — and if one of the three is a shadow, re-run check A1, because that is
where the shadow silently goes missing.

---

### B3. Symmetric exits

**Silent symptom:** the interface feels slightly sluggish everywhere, with no single slow moment to
point at.

**Why it gets written:** the exit is usually written as a mirror of the entry, because that is one
edit rather than two, and it is not *wrong* — just 40% too long, over twice the necessary distance.

**The fix:** exit at `0.5–0.7×` the entry duration, over half the distance or less, curve `in`.

**The check:** find every exit duration in your token set and compare it against its entry. This is
a two-minute audit and it changes how the whole product feels.

---

### B4. Mixing the two spring vocabularies

**Silent symptom:** one of your parameters does nothing. You change `bounce` and see no difference,
so you assume the value is too small and push it until something moves.

```js
/* ❌ */
{ type: "spring", visualDuration: 0.3, bounce: 0.2, stiffness: 400 }
```

**Why it gets written:** you inherited a spring written in `stiffness`, wanted to adjust the feel,
and reached for the parameter you understand — leaving the old one in place. Most implementations
resolve this by silently ignoring one system.

**The fix:** one vocabulary per project. Prefer `Dv`/`b`; convert at the boundary with
`spring.md` §2.

**The check:** grep for `stiffness` and `damping`. Every hit should be inside the conversion
function, and nowhere else.

---

## C. You hung logic on the animation

### C1. Removing a node on a completion event

**Silent symptom:** invisible elements accumulate in the tree, intercepting clicks. It only happens
to users who interact quickly, so it does not reproduce while you are looking at it.

```js
/* ❌ */
el.addEventListener("transitionend", () => el.remove());
```

**Why it gets written:** it is the documented event for exactly this, and it works every time you
test it — because you test by clicking once and waiting.

```js
/* ✅ the animation is presentation; the removal is not */
el.classList.add("leaving");
setTimeout(() => el.remove(), EXIT_MS);
```

**Why:** completion events do not fire when the animation is cancelled, interrupted, replaced, or
skipped under reduced motion — and a promise-based API will *reject* in those cases, so an
un-caught `await` leaves the node forever. All four are normal conditions, not edge cases.

**The check:** trigger the exit, then immediately trigger it again, or reverse it mid-flight. Then
inspect the tree. Also: turn on reduced motion and confirm things still get removed.

---

### C2. The animation is the source of truth

**Silent symptom:** a menu that is neither open nor closed after an interrupted transition, and a
subsequent toggle that does the wrong thing.

**Why it gets written:** the visual state and the logical state look like the same fact, so keeping
one variable seems like good hygiene.

**The fix:** keep the boolean. Animate toward it. The test from `pitfalls.md` §7 is exact: **if you
deleted every animation from the product, all the logic should still run.**

**The check:** set every duration to `0.01ms` and use the product. Everything should still work.
Then set them to `2s` and interrupt things. Same answer.

---

## D. You trusted something you did not verify

### D1. An API name from memory

**Silent symptom:** on a guarded read, nothing at all — the guard swallows it and the feature is
permanently off. On an unguarded read, a crash in a code path nobody exercises.

```lua
-- ❌ the guard makes a wrong name indistinguishable from an absent one
local ok = pcall(function() reduced = GuiService.ReducedMotion end)
```

**Why it gets written:** the name is *nearly* right, and defensive code is a good habit. Together
they produce a feature that is silently absent — the worst outcome available, because it looks
handled.

**The check:** read the name out of the platform's own API listing before you ship it, not out of
your memory of it. A guard is for a property that may be *missing on old clients*; it is not a
substitute for knowing the name. If a guarded read fails, log it in development rather than
defaulting quietly.

---

### D2. Claiming a guarantee the documentation does not make

**Silent symptom:** none, until someone builds on the claim. Then a bug that traces back to a
sentence in a document rather than to any line of code.

**Why it gets written:** a component that obviously *should* handle a case usually does, and writing
"handles X" is shorter than writing "verify X yourself".

**The fix:** state what the documentation states. Where you believe something is true but cannot
source it, say so in those words, and say how to check.

**The check:** for each capability claim in anything you write, ask where you read it. "It stands to
reason" is not a source.

---

### D3. Numbers you produced by hand

**Silent symptom:** a curve that is *approximately* right. It animates, it looks like a spring, and
it is wrong in a way no reviewer will catch by reading.

**Why it gets written:** a 21-value easing table looks like the kind of thing you can estimate from
the shape, and the result is plausible enough to pass a glance.

**The fix:** compute it. `spring.md` §4 gives the closed form per damping regime; ten lines of
script produce the table. Then check the endpoints and the peak against the published numbers.

**The check:** two invariants catch almost everything — the table must start at exactly `0` and end
at exactly `1`, and its peak must match the overshoot for that `b` in `spring.md` §1. A "bouncy"
curve that never dips back *below* 1 on the return is not a spring; it is a hand-drawn arc.

---

## E. Discipline in the document itself

### E1. A library identifier in a runtime-agnostic file

**Silent symptom:** a sentence that no longer parses, and a reader sent looking for an API that does
not exist in their runtime.

> ❌ Items inside: `stagger 0.03`, starting after the container is `beforeChildren`.

**Why it gets written:** the rule was learned from one implementation, and the implementation's name
for it is shorter than the rule. When the surrounding text is rewritten to be neutral, the
identifier survives because it looks like a term of art.

> ✅ Items inside: `stagger 0.03`, beginning only once the container has finished opening — the
> container-before-children rule in `feel.md` §6.

**The check:** grep the judgment chapters for the vocabulary of any specific library. A file that
opens by promising to name no API should be able to prove it.

---

### E2. A cross-reference to the wrong section

**Silent symptom:** the reader follows the pointer, finds unrelated material, and quietly stops
trusting the other references too.

**The check:** for every `§N` you write, open §N. Mechanical, boring, and it is the single highest
hit-rate check in this file — cross-references rot every time a document is reorganised, and nothing
in the toolchain notices.

---

## The pre-flight list

Run this before claiming an animation is done. It is ordered by how often the check fires.

- [ ] Tested the **exit** of every state, not just the entry (A4, B3, C1)
- [ ] Watched the **shadow** specifically, on hover, in the light theme (A1, B2)
- [ ] Counted the properties per interaction — three or more for lift and press (B2)
- [ ] Grepped the animations for `left` / `top` / `width` / `height` (B1)
- [ ] Confirmed every spring duration is `t_settle`, not `Dv` (A2)
- [ ] Re-triggered every animation five times rapidly, then inspected the tree (C1)
- [ ] Ran the product with durations at `0.01ms`, then at `2s` (C2)
- [ ] Turned on reduced motion and confirmed things still get **removed**, and still **fade** (C1)
- [ ] Read every API name out of the platform's listing, not from memory (D1)
- [ ] Recomputed any table of numbers, and checked its endpoints and peak (D3)
- [ ] Opened every `§N` you cited (E2)
- [ ] Asked, for each entrance, what its ancestors were doing at that moment (A6)
- [ ] Made one test phrase long enough to wrap onto a second line (A7)
