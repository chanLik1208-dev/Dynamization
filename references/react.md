# react.md — Motion for React API

```bash
npm install motion
```
```jsx
import { motion, AnimatePresence, useScroll, stagger } from "motion/react"
import * as motion from "motion/react-client"   // React Server Component
```

> The package is `motion`, not `framer-motion`. Existing `framer-motion` projects still work and the
> API is nearly identical, but new projects should use `motion`.

---

## 1. The `<motion />` component

Every HTML and SVG tag has a motion counterpart: `motion.div`, `motion.button`, `motion.circle`,
`motion.path`… They behave exactly like the native element — same props, same semantics — with
animation capability added.

```jsx
<motion.div
  className="box"
  animate={{ scale: 2 }}
  whileInView={{ opacity: 1 }}
  layout
  style={{ x: 100 }}       // style supports independent transforms and motion values
/>
```

**Performance characteristic**: motion components **bypass React's render cycle entirely**. Animated
values are written to the browser's animation pipeline each frame and never trigger a re-render.
Updating `style` through a motion value also avoids re-renders.

**SSR**: fully supported. The `initial` state appears in the server output.
`<motion.div initial={false} animate={{ x: 100 }} />` emits `translateX(100px)` directly.

### Wrapping custom components

```jsx
const MotionCard = motion.create(Card)           // Card must forward its ref to the animated DOM node
motion.create(Card, { forwardMotionProps: true }) // let Card also receive animate etc.
motion.create('custom-element')                   // strings work too, producing custom DOM elements
```
- React 18: wrap `Card` in `React.forwardRef`
- React 19: `props.ref` is enough
- ⚠️ **Never call `motion.create()` inside a render function.** It creates a new component on every
  render and destroys all animation state.

---

## 2. Animation props

| Prop | Meaning |
|---|---|
| `initial` | Initial state. A target object, a variant name, an array of variant names, or `false` (disable the enter animation and render at `animate`'s values) |
| `animate` | Target on mount and whenever values change. Object or variant name |
| `exit` | Target when removed from the tree. **Must be a direct child of `AnimatePresence`** |
| `transition` | This component's default transition, used when an animation prop carries none of its own |
| `variants` | Named state set, propagated down the component tree |
| `style` | Native `style`, extended with motion values and independent transforms (`x` / `rotate` / `originX`…) |
| `custom` | Data passed to dynamic variant functions |
| `inherit` | `false` = do not inherit or propagate parent variant changes |
| `transformTemplate` | Custom transform string composition: `({x, rotate}, generated) => string` |

**Events**: `onUpdate(latest)` (per frame), `onAnimationStart(target)`, `onAnimationComplete(target)`

### Gesture props

| Prop | Events |
|---|---|
| `whileHover` | `onHoverStart(e)` / `onHoverEnd(e)` |
| `whileTap` | `onTapStart(e)` / `onTap(e)` / `onTapCancel(e)` |
| `whileFocus` | — (follows the CSS `:focus-visible` rules) |
| `whileDrag` | see the drag section |
| `whileInView` | `onViewportEnter(entry)` / `onViewportLeave(entry)` |
| — | `onPan` / `onPanStart` / `onPanEnd` (no matching `while-` prop) |

- Tap is keyboard accessible: the element becomes focusable, `Enter` fires `onTapStart` + `whileTap`,
  release fires `onTap`, and losing focus fires `onTapCancel`.
- Pan and drag `info` objects carry `point` / `delta` / `offset` / `velocity`, each with `x` and `y`.
- On touch devices pan needs CSS `touch-action` to disable scrolling on the relevant axis.
- To stop a child from triggering parent gestures: React components use
  `onPointerDownCapture={e => e.stopPropagation()}`; motion components use `propagate={{ tap: false }}`
  (currently tap only).
- SVG `filter` elements receive no events. Put `whileHover` on the parent and drive
  `feGaussianBlur` etc. through variants.

### Viewport options

```jsx
<motion.div whileInView={{ opacity: 1 }} viewport={{ once: true, amount: 0.3 }} />
```
| Option | Default | Meaning |
|---|---|---|
| `once` | `false` | `true` = stop observing after the first entry |
| `root` | `window` | ref of an ancestor scroll container |
| `margin` | `"0px"` | grow or shrink the detection area, e.g. `"0px -20px 0px 100px"` |
| `amount` | `"some"` | `"some"` / `"all"` / a number `0–1` |

### Drag props

| Prop | Default | Meaning |
|---|---|---|
| `drag` | `false` | `true` / `"x"` / `"y"` |
| `dragConstraints` | — | `{top,left,right,bottom}` or a `ref` to another element |
| `dragElastic` | `0.5` | how far past the constraints it may stretch; `0` = hard wall, `false` = immovable |
| `dragMomentum` | `true` | momentum after release |
| `dragTransition` | — | inertia parameters: `{ bounceStiffness, bounceDamping, power, timeConstant, modifyTarget }` |
| `dragSnapToOrigin` | `false` | spring back to the origin on release |
| `dragDirectionLock` | `false` | lock to the first detected axis |
| `dragPropagation` | `false` | allow propagation to children |
| `dragControls` | — | with `useDragControls()`, start dragging from a different element |
| `dragListener` | `true` | `false` = only `dragControls` can start a drag |

Events: `onDrag` / `onDragStart` / `onDragEnd` (all with `info`), `onDirectionLock(axis)`

### Layout props

| Prop | Meaning |
|---|---|
| `layout` | `true` = animate position and size; `"position"` = position only; `"size"` = size only |
| `layoutId` | Shared-element transition between elements with the same id; crossfades if the old one is still mounted |
| `layoutDependency` | Only measure when this value changes, reducing overhead |
| `layoutAnchor` | Default `{x:0, y:0}` (top-left). `0.5` = centred, `1` = bottom-right, `false` = disable relative projection |
| `layoutScroll` | Mark a scrollable ancestor so Motion accounts for scroll offset |
| `layoutRoot` | Mark a `position: fixed` element |

Events: `onLayoutAnimationStart` / `onLayoutAnimationComplete`

⚠️ During layout animations, change the layout through `style` or `className`, **not** through
`animate` / `whileHover` — `layout` handles it.

```jsx
// A transition just for the layout animation
<motion.div layout animate={{ opacity: .5 }}
  transition={{ ease: "linear", layout: { duration: 0.3 } }} />
```
In a shared-element transition, the transition on the **destination** element is the one that runs.

---

## 3. Transition

```js
{ type, duration, ease, times, delay, repeat, repeatType, repeatDelay, inherit, path }
```

### Common

| Option | Default | Meaning |
|---|---|---|
| `type` | dynamic (see feel.md §1) | `"tween"` / `"spring"` / `"inertia"` |
| `delay` | `0` | seconds. **Negative = start partway through** |
| `repeat` | `0` | `Infinity` for endless |
| `repeatType` | `"loop"` | `"loop"` / `"reverse"` / `"mirror"` |
| `repeatDelay` | `0` | wait between repetitions |
| `inherit` | `false` | `true` = merge values from lower-specificity transitions (e.g. `MotionConfig`) |
| `path` | — | pass `arc()` to curve x/y rather than moving in a straight line |

### Tween

| Option | Default |
|---|---|
| `duration` | `0.3` (`0.8` with multiple keyframes) |
| `ease` | name string / four-number cubic bezier / custom function / array (one per keyframe segment) |
| `times` | keyframe positions `0–1`, length must equal the keyframe count |

Built-in easing names: `linear`, `easeIn` / `easeOut` / `easeInOut`, `circIn` / `circOut` /
`circInOut`, `backIn` / `backOut` / `backInOut`, `anticipate`

### Spring

**Time-oriented (prefer this set)**

| Option | Default | Meaning |
|---|---|---|
| `visualDuration` | — | seconds. Time until it *looks* arrived; overrides `duration` |
| `bounce` | `0.25` (docs) / `0.3` (source `springDefaults`) | `0` none → `1` extreme |
| `duration` | `0.3` | total time including the bouncy tail |

**Physics-oriented**

| Option | Default | Meaning |
|---|---|---|
| `stiffness` | `100` (⚠️ the docs pages wrongly say `1`) | higher = more sudden |
| `damping` | `10` | opposing force. `0` = oscillates forever |
| `mass` | `1` | higher = more lethargic |
| `velocity` | current velocity | initial velocity |
| `restSpeed` | `0.1` | end when speed drops below this and delta is under `restDelta` |
| `restDelta` | `0.01` | as above |

⚠️ **Setting any of `stiffness` / `damping` / `mass` makes `bounce` and `duration` completely inert.**

### Inertia (post-drag momentum; also used by `dragTransition`)

| Option | Default | Meaning |
|---|---|---|
| `power` | `0.8` | higher = travels further |
| `timeConstant` | `700` | deceleration time constant |
| `modifyTarget` | — | `target => newTarget`, e.g. snap to a grid |
| `min` / `max` | — | boundaries, sprung on contact |
| `bounceStiffness` | `500` | boundary spring stiffness |
| `bounceDamping` | `10` | boundary spring damping |

### Orchestration (variants only)

| Option | Default | Meaning |
|---|---|---|
| `when` | `false` | `"beforeChildren"` / `"afterChildren"` |
| `delayChildren` | `0` | seconds, or a `stagger(...)` |

### Per-value transitions and inheritance

```jsx
<motion.li animate={{ x: 0, opacity: 1, transition: {
  default: { type: "spring" },
  opacity:  { ease: "linear" },
}}} />
```
Higher-specificity transitions **replace** lower ones entirely by default. Add `inherit: true` to
merge instead.

---

## 4. Variants

```jsx
const list = {
  hidden: { opacity: 0, transition: { when: "afterChildren" } },
  show:   { opacity: 1, transition: { when: "beforeChildren", delayChildren: stagger(0.05) } },
}
const item = { hidden: { opacity: 0, x: -20 }, show: { opacity: 1, x: 0 } }

<motion.ul variants={list} initial="hidden" whileInView="show">
  <motion.li variants={item} />
</motion.ul>
```
- Variant names **propagate automatically down the tree**: children with a matching variant animate
  along without needing their own `animate` prop.
- Apply several at once with an array: `animate={["visible", "danger"]}`
- **Dynamic variants**: write the value as a function; its argument comes from the `custom` prop.
  ```jsx
  const v = { show: (i) => ({ opacity: 1, transition: { delay: i * 0.1 } }) }
  items.map((it, i) => <motion.div key={it.id} custom={i} variants={v} />)
  ```

---

## 5. `AnimatePresence`

```jsx
<AnimatePresence mode="wait" initial={false}>
  {open && <motion.div key="modal" exit={{ opacity: 0 }} />}
</AnimatePresence>
```

| Prop | Default | Meaning |
|---|---|---|
| `mode` | `"sync"` | `"sync"` simultaneous / `"wait"` the old one leaves before the new arrives (single child only) / `"popLayout"` the leaving element drops out of layout flow so the rest reflow immediately |
| `initial` | `true` | `false` = no enter animation on first render |
| `custom` | — | pass data to children already removed from the tree (read with `usePresenceData()`) |
| `onExitComplete` | — | fires when every exiting node has finished |
| `propagate` | `false` | `true` = when removed by an outer `AnimatePresence`, still fire its own children's exits |
| `root` | `document.head` | where `popLayout` injects styles (for Shadow DOM) |

**Hard requirements:**
- Direct children need **stable, unique** `key`s. Array `index` as key is wrong.
- The condition goes **inside** `AnimatePresence`, never `isVisible && <AnimatePresence>…` — in that
  form it unmounts itself and cannot control the exit.
- Under `popLayout`, custom-component children must `forwardRef`, and the animating parent needs a
  non-`static` `position`.

Related hooks: `useIsPresent()`, `usePresence()` → `[isPresent, safeToRemove]`, `usePresenceData()`

---

## 6. Hooks

### Motion values (animatable values that never re-render)

```jsx
const x = useMotionValue(0)
<motion.div style={{ x }} />
x.set(100)   // no re-render
```
Methods: `get()` / `set(v)` / `jump(v)` (set without animating) / `getVelocity()` / `isAnimating()` /
`stop()` / `on(event, cb)` / `destroy()`

| Hook | Purpose |
|---|---|
| `useMotionValue(init)` | create a motion value |
| `useSpring(source, opts)` | a spring-driven motion value. `source` may be a number, unit string, or another motion value. Extra option: `skipInitialAnimation` |
| `useTransform(mv, input[], output[], opts?)` | range mapping. `opts.clamp` (default `true`; `false` extrapolates indefinitely) |
| `useTransform(() => expr)` | function form: any motion value read via `.get()` is subscribed automatically |
| `useMotionTemplate` | build strings: `` useMotionTemplate`blur(${v}px)` `` |
| `useMotionValueEvent(mv, "change", cb)` | observe changes |
| `useVelocity(mv)` | a motion value carrying velocity |
| `useTime()` | elapsed milliseconds, every frame |

`useTransform` can produce several outputs at once:
```jsx
const { opacity, scale, filter } = useTransform(offset, [100, 600], {
  opacity: [1, 0.4], scale: [1, 0.6], filter: ["blur(0px)", "blur(10px)"],
})
```

### Scroll and viewport

| Hook | Meaning |
|---|---|
| `useScroll({ container, target, offset, axis })` | returns `scrollX` / `scrollY` (px) and `scrollXProgress` / `scrollYProgress` (0–1) |
| `useInView(ref, opts)` | returns a boolean (does re-render; use it to drive React state) |
| `usePageInView()` | false when the tab is hidden, for pausing animations. SSR-safe |

`offset` syntax: `["start end", "end start"]` means *from the target's top meeting the container's
bottom, to the target's bottom meeting the container's top*.

### Control and misc

| Hook | Meaning |
|---|---|
| `useAnimate()` | returns `[scope, animate]`. Animates any HTML/SVG element (not just motion components), supports sequences and playback control |
| `useAnimationFrame(cb)` | runs per frame with `(time, delta)` |
| `useDragControls()` | start a drag manually: `controls.start(event, { snapToCursor: true })` |
| `useReducedMotion()` | whether the user prefers reduced motion |

```jsx
const [scope, animate] = useAnimate()
useEffect(() => {
  const controls = animate([
    [scope.current, { x: "100%" }],
    ["li", { opacity: 1 }, { delay: stagger(0.05) }],
  ])
  controls.speed = 0.8
  return () => controls.stop()
}, [])
return <ul ref={scope}>…</ul>
```

---

## 7. Global configuration and bundle size

```jsx
<MotionConfig
  transition={{ duration: 0.3, ease: "easeOut" }}  // site-wide default transition
  reducedMotion="user"                              // "user" | "always" | "never"
  nonce="…"                                         // CSP
  transformPagePoint={fn}                           // correct coordinates when the page is scaled
>
```

**Shrinking the bundle**: the mini `useAnimate` is smallest; motion components can be lazily loaded
down to 4.6kb with `LazyMotion`.
```jsx
import { LazyMotion, domAnimation, m } from "motion/react"
<LazyMotion features={domAnimation} strict>
  <m.div animate={{ opacity: 1 }} />   {/* under strict, use m rather than motion */}
</LazyMotion>
```
`features` accepts `domAnimation` (animation + gestures) or `domMax` (adds layout and drag), or a
function returning a promise for dynamic loading.

---

## 8. Animatable values

- **Independent transforms**: `x` `y` `z` `scale` `scaleX` `scaleY` `rotate` `rotateX` `rotateY`
  `rotateZ` `skewX` `skewY` `transformPerspective` `originX` `originY` `originZ`
- Numbers, unit strings (`px` `%` `vh`…), colours (hex / rgba / hsla), composite strings
  (`box-shadow`, `filter`, gradients)
- **CSS variables**: `animate={{ "--rotate": "360deg" }}`, and they can be animation targets
- **SVG**: attributes (`cx` `r` `pathLength`…) and path drawing via `pathLength` / `pathSpacing` /
  `pathOffset` (0–1; supports `circle` `ellipse` `line` `path` `polygon` `polyline` `rect`)
- **Keyframes**: `animate={{ x: [0, 100, 0] }}`. A leading `null` continues from the current value
  (**always write it this way when interruption is possible**); a `null` in the middle repeats the
  previous frame
- **Motion values as text content**: `<motion.pre>{count}</motion.pre>` updates the DOM text node
  directly, with zero re-renders

---

## 9. Motion+ components (paid, not required)

`AnimateNumber`, `Typewriter`, `ScrambleText`, `Ticker`, `Carousel`, `Cursor`, `AnimateView`,
`AnimateActivity`, `splitText`, `useCurtains`. They need a `motion-plus` private-registry token.

**Unless the user is already a Motion+ member, do not reference these in code** — use the
self-contained equivalents in `recipes.md`.
