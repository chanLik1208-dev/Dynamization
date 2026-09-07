# pitfalls.md — Symptom → cause → fix

Look up the symptom, then read the section. The causes are grouped by *mechanism*, not by API, so
they transfer between runtimes — a dropped exit animation has the same three causes in a web
framework, a game engine, and a native toolkit.

| Symptom | Most likely cause |
|---|---|
| Exit animation never fires | the thing was destroyed before it could animate → §1 |
| Animation restarts from the beginning on every trigger | the animated object is being recreated, or you re-target from the nominal start → §2 |
| Reversal stutters or slams to a halt | velocity is not being carried; Tier 2 behaviour → §2 |
| Reflow animation does nothing | nothing told the system the layout changed, or the element type cannot be transformed → §3 |
| Content stretches or the corner radius goes oval | a rect is being scaled without counter-scaling its content → §3 |
| The whole page jitters while scrolling | a scrollbar or safe-area appearing is triggering a reflow animation → §3 |
| Dropped frames, jank | animating a layout- or paint-tier property → §4 |
| Scroll-linked values step visibly | raw scroll input, not smoothed → §5 |
| The screen sweeps from the top on load | a scroll-driven spring initialised at zero → §5 |
| Drag distance doesn't match the pointer | a transformed or scaled ancestor changed the coordinate space → §6 |
| Hover gets "stuck" on touch devices | synthesised hover events → §6 |
| The animation finished but the state didn't change | logic hung off a completion callback that never fired → §7 |
| Elevation disappears in the dark theme | shadows are invisible on dark surfaces → `contrast.md` §2 |
| Mid-animation text is unreadable | intermediate contrast too low → `contrast.md` §7 |

---

## 1. Exits that never happen

An exit animation is a contradiction: you are animating something that, logically, no longer exists.
Every runtime needs a mechanism to keep it alive for the duration, and **the failure is always one
of three things**:

1. **The keep-alive is inside the thing being removed.** If the wrapper responsible for deferring
   the destruction is itself destroyed by the same condition, nothing survives to animate. The
   keep-alive must sit **outside** the conditional, and the condition must sit inside it.
2. **Identity is unstable.** The system tracks "which item is which" by some key. If that key is a
   positional index, then removing item 2 makes item 3 *become* item 2, and the system sees an
   update rather than a removal. Use a stable, unique id.
3. **The exiting thing is not a direct child of the keep-alive.** One inert wrapper in between and
   the mechanism cannot see it. Check the actual tree, not the source tree.

**Nested exits** are their own trap: when a whole subtree is removed at once, children usually do
**not** get to play their own exits — the parent finishes first and takes them with it. If you need
the children to leave first, sequence it explicitly (`feel.md` §6: content clears, *then* the
container closes).

**Design test:** if you cannot name the mechanism that keeps the element alive during its exit, you
do not have an exit animation yet. Find it in your adapter before designing one.

---

## 2. Restarts, recreation, and lost velocity

**The animated object is being recreated.** Anything constructed inside a render/update function is
a new object every frame or every update, and it carries none of the previous one's animation
state. Hoist the construction out. This is the single most common cause of "it animates the first
time and then never again", and it has the same shape in every declarative UI system.

**You are re-targeting from the nominal start.** When an animation is re-triggered mid-flight, the
new animation must begin at the **current** value, not at the declared start value. Read the current
value first. Anything that says "animate from A to B" when the element is currently at some point
between them will snap back to A, and the snap is exactly at the moment the user acted.

**Velocity is not being carried.** This is Tier 2 behaviour (`SKILL.md` §2) and it is not a bug, it
is a missing capability. Three ways out, in order:

- Hand-integrate the spring for the interactions that are actually gesture-driven — `spring.md` §3.
- Keep `b ≤ 0.15` so a zero-velocity restart is not visibly different from a continuation.
- Keep re-triggerable animations at `dur ≤ 0.2s`, below the threshold where a restart is noticeable.

**Do not mix parameter systems.** If your runtime accepts both a duration and a stiffness, setting
one usually makes the other inert — silently. Pick one vocabulary (`Dv`/`b`, converting at the
boundary) and never set the other.

---

## 3. Reflow and shared-element animations

**Nothing happens:**

- **The element type cannot be transformed.** Inline text boxes, some layout-managed containers, and
  many 2D UI nodes ignore transforms entirely. Change the element to one that can be transformed.
- **Nothing told the system the layout changed.** Reflow animations work by comparing a *before* and
  an *after* measurement, and something must trigger that comparison. A change that bypasses the
  system's update cycle produces no comparison and therefore no animation.
- **Two elements affect each other's layout but are updated separately.** They need to be measured
  in the same pass, or one will animate to a position the other has not yet vacated.

**Drive layout through layout, not through the animation system.** Setting a size via an animation
*and* letting the reflow system animate the same size is two systems fighting over one number. Let
the layout change instantly and let the reflow mechanism animate the visual difference.

**Content stretching (scale distortion).** A rect animated by scaling distorts everything inside it:
text stretches, corner radii go oval, borders change width. Fixes, in order of preference:

- Counter-scale the direct children by the inverse factor.
- For elements whose aspect ratio changes (images, text blocks), animate **position only** and let
  the size change instantly.
- **Corner radius and shadow must be values the animation system can see** to be corrected. A radius
  buried in a stylesheet or a static asset cannot be counter-scaled.
- A border cannot be corrected perfectly — there is a one-pixel floor. Use a padded parent as the
  border instead.

**Inside a scroll container or a fixed-position layer**, the before/after measurements are taken in
different coordinate spaces unless you tell the system about the container. Both cases usually need
an explicit opt-in.

**Page jitter while scrolling** is almost always a scrollbar or safe-area inset appearing and
disappearing, which changes the content width, which triggers a reflow animation on everything.
Reserve the gutter permanently.

**A note on coordinates:** a reflow mechanism that computes **parent-relative** positions keeps a
delayed child attached to its moving parent. One that computes **page-absolute** positions will
leave the child behind. If your child transitions look detached from their parent, this is why.

---

## 4. Performance

**Always safe**: transform (translate / scale / rotate), opacity
**Paint tier — measure it**: shadows, corner radius, background colour, filters
**Layout tier — avoid**: width, height, top, left, margin, padding, border width

The universal substitution: **do not animate the expensive property, cross-fade two pre-rendered
states of it.** A blurred shadow becomes a stacked overlay whose opacity animates. A corner radius
becomes two masks. A backdrop blur becomes two pre-blurred copies. This costs memory and buys
frames — `contrast.md` §6.

Where a clip or mask is available it is usually cheaper than the property it replaces: clipping to a
rounded rect beats animating a radius, and clipping a reveal beats animating a height.

**Be sparing with layer hints.** Every "promote this to its own layer" hint costs GPU memory, and a
page full of them is slower than a page with none. Add them only to elements you have measured.

**Text is the expensive case.** Splitting text into fragments inflates the object count *once*,
which is fine. Rewriting text content every frame triggers **continuous** text layout, which is not.
Reserve the final size up front, and use a fixed-advance font for scramble effects so the box never
re-measures. **Per-character blur is a specific trap** — many small layers, each blown up by its
blur radius, overlap heavily and cost far more than one blur over the whole block.

---

## 5. Scroll

- Scroll input is discrete. Binding it straight to a transform produces stepping. Always smooth it
  through a spring — `feel.md` §7.
- **Initialise that spring at the current scroll value**, or the screen sweeps from the top on load.
  This one ships to production constantly because it does not reproduce during development, where
  you are already at the top of the page.
- Pin with the platform's native sticky mechanism, never by writing a position from a scroll
  handler. A handler-driven pin is one frame behind the compositor and visibly judders.
- Scroll-triggered animations need an explicit **fire-once** flag and an explicit **threshold**
  (~30% visible). Both defaults are usually wrong.
- Be precise about what "progress" means. Most scroll APIs express the range as two pairs of
  positions — a point on the target and a point on the container — and getting the pairing backwards
  gives you an animation that is over before the element is on screen, or one that never completes.

---

## 6. Gestures and coordinate spaces

**Drag doesn't track the pointer** → an ancestor carries a transform or a scale, so pointer
coordinates and element coordinates are in different spaces. Either divide the pointer delta by the
accumulated scale, or convert the pointer position into the element's local space before using it.
The same cause breaks reflow animations inside a scaled parent.

**Hover "sticks" on touch devices** → touch input synthesises hover events that never get a matching
exit. Use the platform's filtered hover signal if it has one; otherwise clear the hover state on
touch-end yourself, and gate hover effects on a "device has a real pointer" query.

**A drag fights the scroll on touch** → the platform needs to be told, before the gesture starts,
which axis you own. Declare it up front; deciding after the first move event is always too late,
because the scroll has already begun.

**A child's tap is swallowed by a parent gesture** → gesture systems commonly defer their handling
to the end of the input pass, which means stopping propagation from inside a gesture callback is too
late. Stop it at the raw pointer-down, or use whatever explicit "do not propagate this gesture"
option the system offers.

**Taps firing at the end of a drag** → cancel the tap once the pointer has moved more than about 3px.
Most systems do this for you; verify it, because the failure is a user dragging a card and
accidentally opening it.

**Dragging an image produces a ghost** → the platform's own drag-and-drop is competing with yours.
Disable it on the element.

---

## 7. State, callbacks and lifecycle

**Never hang real logic off an animation-completed callback.** It does not fire when the animation
is interrupted, cancelled, or skipped under reduced motion — and all three are normal. Drive state
from the event that caused the animation, and let the animation be presentation. The rule of thumb:
if you deleted every animation from the product, all the logic should still run.

**Animations and state can disagree.** If the animation is the source of truth for "is the menu
open", then an interrupted animation leaves you in a state that does not exist in your model. Keep
the boolean; animate toward it.

**Beware new-object-every-update.** Passing a freshly constructed configuration object on every
update makes equality checks fail, which either replays the animation constantly or costs a
comparison for nothing. Hoist it, memoise it, or name it as a token.

---

## 8. Pre-delivery checklist

- [ ] Is reduced motion handled globally? Are parallax and autoplay branched separately on top?
- [ ] Do scroll-triggered animations fire once, at a sensible threshold?
- [ ] Are you animating a layout-tier property anywhere that should be a transform?
- [ ] Do exits actually play — with stable ids, and the condition inside the keep-alive?
- [ ] Is exit 0.5–0.7× the entry duration, over a shorter distance?
- [ ] Have you done the stagger arithmetic (interval × count ≤ 0.5s)?
- [ ] Is there exactly one bounce value in use across the product?
- [ ] **Have you looked at it in the dark theme?** Is elevation still visible? Is the focus ring?
- [ ] Have you re-triggered every animation rapidly, five times, to see the interruption behaviour?
- [ ] Have you run it once on a low-end device, or with a 4× CPU throttle?
- [ ] Does split text carry a proper accessible label, with the fragments hidden?
- [ ] Is any state conveyed by luminance alone, or by animation alone?
