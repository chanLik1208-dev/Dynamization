# pitfalls.md — Symptom → cause → fix

Look up the symptom, then read the section.

| Symptom | Most likely cause |
|---|---|
| Exit animation never fires | `AnimatePresence` unmounted itself, or the child `key` is unstable → §1 |
| Animation restarts from scratch every time | the component is being recreated (key changed, or `motion.create` inside render) → §2 |
| Layout animation does nothing | the element is `display: inline`, or there was no re-render → §3 |
| Content stretches during a layout animation | children lack `layout`, or radius/shadow are not in `style` → §3 |
| The whole page jitters while scrolling | the scrollbar appearing triggers a layout animation → §3 |
| Dropped frames, jank | animating a layout-triggering property, or a large paint → §4 |
| Scroll-linked values step visibly | not passed through `useSpring` → §5 |
| Drag distance doesn't match the finger | a transformed / scaled ancestor → §6 |
| Hover gets "stuck" on touch devices | native hover events instead of Motion's `hover()` / `whileHover` → §6 |
| SVG layout animation is broken | SVG does not support layout animations → §7 |
| Elevation disappears in dark mode | shadows are invisible on dark surfaces → `contrast.md` §2 |
| Mid-animation text is unreadable | intermediate contrast too low → `contrast.md` §7 |

---

## 1. `AnimatePresence` and exits

**Three reasons an exit never fires:**

```jsx
// ❌ AnimatePresence unmounts itself and cannot animate its own departure
{isVisible && <AnimatePresence><Component /></AnimatePresence>}

// ✅ The condition goes inside
<AnimatePresence>{isVisible && <Component />}</AnimatePresence>
```

```jsx
// ❌ index as key: reordering breaks the item↔key association
{items.map((item, i) => <Component key={i} />)}
// ✅ stable, unique id
{items.map(item => <Component key={item.id} />)}
```

**The exiting component must be a direct child of `AnimatePresence`** to receive `exit`. One
non-motion wrapper in between and it stops working.

**Nested `AnimatePresence`**: when the outer one is removed, inner children do **not** play their
exits by default. Add `propagate` to the inner one:
```jsx
<AnimatePresence propagate>…</AnimatePresence>
```

**Two requirements for `mode="popLayout"`:**
- Custom-component children must `forwardRef` and pass the ref to the node being popped
- The animating parent needs a non-`static` `position` — popLayout uses `position: absolute`
  internally, and any transformed ancestor becomes the offset parent

```jsx
<motion.ul layout style={{ position: "relative" }}>
  <AnimatePresence mode="popLayout">…</AnimatePresence>
</motion.ul>
```

**Mixing `mode="sync"` with layout animations**: wrap the group in `<LayoutGroup>` so components
outside the `AnimatePresence` know to reflow.

---

## 2. Components being recreated

```jsx
// ❌ a brand-new component every render; all animation state is lost
function Row() {
  const MotionCard = motion.create(Card)   // disaster
  return <MotionCard animate={…} />
}
// ✅ hoist to module scope
const MotionCard = motion.create(Card)
```

A `motion.create()` wrapper must forward `ref` to the DOM node that actually animates (React 18:
`forwardRef`; React 19: `props.ref`). Without it, nothing moves.

Animation snapping back to the start on interruption: write `null` as the first keyframe.
```jsx
animate={{ x: [null, 100, 0] }}
```

---

## 3. Layout animations

**Nothing happens:**
- The element is `display: inline` — browsers do not apply transforms to inline boxes. Use
  `inline-block` / `block` / `flex`.
- There was no re-render. Layout animations are triggered by React renders; a pure CSS change does
  not trigger one.
- Two components affect each other's layout but render separately → wrap them in `<LayoutGroup>`.

**Change layout through `style` / `className`, not `animate`:**
```jsx
// ❌ layout and animate fight each other
<motion.div layout animate={{ width: open ? 300 : 100 }} />
// ✅ let layout handle it
<motion.div layout style={{ width: open ? 300 : 100 }} />
```

**Content stretching (scale distortion):**
- Add `layout` to direct children too — Motion applies inverse scaling
- For elements whose aspect ratio changes (images, text), use `layout="position"`
- **`borderRadius` and `boxShadow` must be set in `style`** to be scale-corrected; in a CSS class
  they will not be
- `border` cannot be corrected perfectly (a 1px floor) → use a padded parent as the border instead

```jsx
<motion.div layout style={{ borderRadius: 10, padding: 5, background: "#000" }}>
  <motion.div layout style={{ borderRadius: 5, background: "#fff" }} />
</motion.div>
```

**Inside a scroll container**: add `layoutScroll` to the container.
**Inside `position: fixed`**: add `layoutRoot`.

**Layout animations are disabled during horizontal window resize** — that is deliberate performance
protection, not a bug.

**Page jitter when the scrollbar appears:**
```css
body { overflow-y: auto; scrollbar-gutter: stable; }
```

**Relative positioning in nested layout animations**: Motion computes **parent-relative** positions
(unlike View Transitions, which use page-absolute coordinates), so a delayed child is never left
behind by its parent. Change the anchor with `layoutAnchor={{ x: 0.5, y: 0.5 }}`.

---

## 4. Performance

**Always safe**: `transform` (including independent `x` / `scale` / `rotate`), `opacity`
**Triggers paint (measure it)**: `box-shadow`, `border-radius`, `background-color`, `filter`
**Triggers layout (avoid)**: `width`, `height`, `top`, `left`, `margin`, `padding`, `border-width`

Substitutions:
```js
animate(el, { boxShadow: "10px 10px black" })          // ❌ paint
animate(el, { filter: "drop-shadow(10px 10px black)" })// ✅ compositor (Chrome/FF)

animate(el, { borderRadius: "50px" })                  // ❌
animate(el, { clipPath: "inset(0 round 50px)" })       // ✅
```
For large-area shadow animation, use the pseudo-element opacity trick → `recipes.md` §5.

**A surprise about hardware acceleration**: Motion's independent transforms (`x`, `scale`) are
implemented with CSS variables and are **not** hardware accelerated today. On a busy main thread
they can still stutter. When it truly matters, write the full string:
```js
animate(".box", { transform: "translateX(100px) scale(2)" })
```
Chrome also spent a long time refusing to accelerate `%`-based transforms.

**Be sparing with layer hints**: every `will-change: transform` costs GPU memory. Add it only to
elements you have measured.

**Text animation**: splitting text inflates the DOM (a one-time cost), but updating `innerText`
every frame triggers **continuous** layout recalculation. Use a monospace font for scramble effects
and `contain: layout` for typewriters. **Per-character blur is a performance trap** — small layers
blown up by a blur overlap each other, costing far more GPU than one blur on the whole block.

---

## 5. Scroll

- Scroll input is discrete; binding `scrollYProgress` straight to a style produces stepping. Always
  pass it through `useSpring`.
- When springing a scroll value, add `skipInitialAnimation: true` to avoid sweeping from 0 on mount.
- Pin with CSS `position: sticky`, never by mutating `top` in JS.
- `whileInView` without `once: true` replays constantly; the default `amount: "some"` (one pixel) is
  usually too early — use `0.3`.
- `useScroll`'s `offset` is `[start, end]`, each written as `"<target position> <container position>"`.
  `"start end"` means *the target's top meets the container's bottom*.

---

## 6. Gestures

**Drag distance doesn't track the pointer** → a transformed or scaled ancestor. Any ancestor with a
transform changes the coordinate system. `MotionConfig`'s `transformPagePoint` can correct a
whole-page zoom.

**Layout animations misbehaving inside a scaled parent** → same cause.

**Browser ghost image when dragging an image** → add `draggable={false}` or CSS
`-webkit-user-drag: none`.

**Hover "sticks" on touch devices** → browsers emulate hover events for touch. Use `whileHover` /
`hover()`, which filter the fakes. Do not bind `mouseenter` yourself.

**Pan / drag unresponsive or fighting the scroll on touch** → you need CSS `touch-action`:
```css
.draggable-x { touch-action: pan-y; }   /* horizontal drag, vertical left to scrolling */
.draggable   { touch-action: none; }
```

**A child's click swallowed by a parent gesture**:
```jsx
<button onPointerDownCapture={e => e.stopPropagation()} />  {/* plain React component */}
<motion.button propagate={{ tap: false }} />                 {/* motion component, tap only for now */}
```
Motion's gesture handling is deferred, so calling `e.stopPropagation()` inside `onTapStart` is too
late.

**Tap inside a draggable** is cancelled automatically once the pointer moves more than 3px.

---

## 7. SVG

- **SVG does not support layout animations** (SVG has no layout system). Animate attributes directly
  (`cx`, `x`, `width`…) or the `viewBox`.
- SVG `filter` elements (`feGaussianBlur` etc.) **receive no events**. Put `whileHover` on the parent
  `<motion.svg>` and drive the filter children through variants.
- Path drawing uses `pathLength` / `pathSpacing` / `pathOffset` (0–1) on `circle` `ellipse` `line`
  `path` `polygon` `polyline` `rect`.

---

## 8. Common misuse

| Written as | Problem | Should be |
|---|---|---|
| `import { motion } from "framer-motion"` | old package name | `"motion/react"` |
| `transition={{ type: "spring", duration: .3, stiffness: 200 }}` | setting `stiffness` makes `duration`/`bounce` inert | pick one system |
| `spring({ duration: 0.3 })` | calling `spring()` directly takes **milliseconds** | `spring({ duration: 300 })` |
| `useTransform` inside `.map()` | violates the rules of hooks | extract a child component, or use the function form |
| new `animate` object every render | equal values won't replay, but the comparison still costs | `useMemo` or variants |
| chaining animations with `setTimeout` | cannot be cancelled, and drifts | a sequence or `delayChildren` |
| relying on `onAnimationComplete` for critical logic | never fires if interrupted | drive it from state; animation is presentation |
| `import { motion } from "motion/react"` in an RSC | needs a client boundary | `import * as motion from "motion/react-client"`, or add `"use client"` |

---

## 9. Pre-delivery checklist

- [ ] Is there a site-wide `<MotionConfig reducedMotion="user">`? Are parallax and autoplay branched separately?
- [ ] Does every `whileInView` have `once: true`?
- [ ] Are you animating `width` / `height` / `top` / `left` anywhere that should use `layout`?
- [ ] Are `AnimatePresence` keys stable and unique, with the condition inside?
- [ ] Is exit 0.5–0.7× the entry duration?
- [ ] Have you done the stagger arithmetic (interval × count ≤ 0.5s)?
- [ ] **Have you looked at it in dark mode?** Is elevation still visible? Is the focus ring?
- [ ] Have you run it once on a low-end device, or with 4× CPU throttling?
- [ ] Does split text carry `aria-label` on the container and `aria-hidden` on the fragments?
- [ ] Is any state conveyed by luminance alone, or by animation alone?
