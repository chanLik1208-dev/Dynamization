# javascript.md — Motion vanilla JS API

```bash
npm install motion
```
```js
import { animate, scroll, inView, hover, press, stagger, spring } from "motion"
```
CDN:
```html
<script type="module">
  import { animate } from "https://cdn.jsdelivr.net/npm/motion@12/+esm"
</script>
<!-- or as a global -->
<script src="https://cdn.jsdelivr.net/npm/motion@12/dist/motion.js"></script>
<script>const { animate } = Motion</script>
```
> Pin an exact version in production. Never ship `@latest`.

---

## 1. Two builds: mini vs hybrid

| | mini `motion/mini` | hybrid `motion` |
|---|---|---|
| Size | **2.3kb** | 18kb |
| HTML / SVG styles | ✅ | ✅ |
| Independent transforms (`x`, `rotate`) | ❌ (write the full `transform` string) | ✅ |
| CSS variables | registered properties only | ✅ all browsers |
| SVG path drawing | ❌ | ✅ |
| Sequence timelines | ❌ | ✅ |
| Numbers / colours / objects / WebGL | ❌ | ✅ |
| Springs | import `spring` and pass it as `type` | built in via `type: "spring"` |
| `repeatDelay` | ❌ | ✅ |

```js
// mini + spring
import { animate } from "motion/mini"
import { spring } from "motion"
animate(el, { transform: "translateX(100px)" }, { type: spring, bounce: 0.3, duration: 0.8 })
```

---

## 2. `animate()`

```js
animate(target, keyframes, options?)  →  AnimationPlaybackControls
```

`target` may be a CSS selector string, an Element, an array/NodeList of Elements, a motion value,
any JS object, or a sequence array.

```js
animate(".box", { rotate: 360 })
animate(document.querySelectorAll("li"), { opacity: 1 }, { delay: stagger(0.05) })
animate(element, { "--hue": "360deg" })                    // CSS variable
animate("path", { pathLength: [0, 1] }, { duration: 2 })   // SVG line drawing
animate(camera.rotation, { y: Math.PI * 2 }, { duration: 10 })   // Three.js
animate(0, 100, { onUpdate: v => el.textContent = Math.round(v) })  // single number
animate("#fff", "#000", { duration: 2, onUpdate: c => … })         // colour
animate(x /* motion value */, 200, { duration: 0.5 })
```

**Options** are identical to the React transition object (`type` / `duration` / `ease` / `times` /
`bounce` / `visualDuration` / `stiffness` / `damping` / `mass` / `velocity` / `restSpeed` /
`restDelta` / `delay` / `repeat` / `repeatType` / `repeatDelay` / `path`) — see `react.md` §3.

Per-value overrides:
```js
animate(el, { x: 100, rotate: 0 }, { duration: 1, rotate: { duration: 0.5, ease: "easeOut" } })
```

### Playback controls (the return value)

| Member | Meaning |
|---|---|
| `.duration` | read-only, one iteration (excluding delay and repeats) |
| `.time` | read/write current time in seconds → **use this to scrub** |
| `.speed` | read/write. `1` normal, `0.5` half, `2` double, `-1` reverse |
| `.play()` | paused → resume; finished → restart |
| `.pause()` | pause |
| `.complete()` | jump to the end immediately |
| `.cancel()` | cancel and revert to the initial state |
| `.stop()` | stop and commit current values to `style`. **A stopped animation cannot restart** |
| `await animation` / `.then()` | promise-like, resolves on completion |

---

## 3. Sequence timelines (hybrid only)

```js
animate([
  ["ul", { opacity: 1 }, { duration: 0.5 }],
  ["li", { x: [-100, 0] }, { delay: stagger(0.05) }],
  "label-a",                                    // label definition
  ["a", { scale: 1.2 }, { at: "label-a" }],
], { defaultTransition: { duration: 0.2 }, repeat: 2 })
```

By default each segment follows the previous one. `at` changes the start:

| `at` value | Meaning |
|---|---|
| `0.5` | 0.5 seconds into the whole timeline |
| `"my-label"` | at that label's time |
| `"<"` | **at the same time** as the previous segment |
| `"+0.5"` | 0.5s **after** the previous segment ends |
| `"-0.2"` | 0.2s **before** the previous segment ends |
| `"<0.5"` | 0.5s **after** the previous segment starts |
| `"<-0.2"` | 0.2s **before** the previous segment starts |

- Each segment accepts every `animate` option except `repeatDelay` / `repeatType`.
- Different subject types can share one timeline: DOM elements, motion values, Three.js objects.
- Callback segments: `[(progress) => …]` (0–1 by default), or `[(color) => …, ["#000","#fff"]]`.
- For a callback that should "fire once", write it as a reversible toggle — animations are stateless
  and scrubbable:
  ```js
  function toggle(onFwd, onBack) {
    let done = false
    return p => { if (p >= 1 && !done) { done = true; onFwd() }
                  else if (p < 1 && done) { done = false; onBack() } }
  }
  animate([[toggle(() => el.classList.add("on"), () => el.classList.remove("on")), { duration: 0 }]])
  ```

---

## 4. `stagger()`

```js
animate("li", { opacity: 1 }, { delay: stagger(0.05, { from: "center", ease: "easeOut" }) })
```

| Option | Default | Meaning |
|---|---|---|
| `startDelay` | `0` | initial delay. **May be negative**, starting every element partway through (common for looping loaders) |
| `from` | `"first"` | `"first"` / `"center"` / `"last"` / an index |
| `ease` | `"linear"` | redistributes the delays, producing accelerating or decelerating waves |

In React, pass `stagger()` to a variant's `transition.delayChildren`.
Two-dimensional grid stagger is not supported yet — compute distances yourself.

---

## 5. Scroll: `scroll()`

```js
scroll(progress => console.log(progress))                  // callback, progress 0–1
scroll(animate("div", { transform: ["none", "rotate(90deg)"] }, { ease: "linear" }))  // bind an animation
scroll(cb, { axis: "x" })
scroll(cb, { container: document.getElementById("scroller") })
scroll(anim, { target: el, offset: ["start end", "end start"] })
scroll((p, info) => …)                                     // info carries detailed scroll data
```
- 5.1kb. Uses the browser's native `ScrollTimeline` where available (hardware accelerated, no
  per-frame measurement).
- When binding an animation, `ease: "linear"` is almost always right — the curve comes from the
  scroll position itself.
- **Pin with CSS `position: sticky`**, not JavaScript. Use a tall outer container to define the
  scroll distance and pass it as `target`.

---

## 6. Events and observers

| Function | Size | Meaning |
|---|---|---|
| `inView(target, cb, opts)` | 0.5kb | built on IntersectionObserver. The function `cb` returns runs on exit |
| `hover(target, cb)` | — | **filters out the fake hover events browsers emulate on touch** (which cause "stuck" UI). The returned function is the hover-end handler |
| `press(target, cb)` | — | filters secondary pointers and right clicks; **makes the element keyboard focusable with Enter automatically** |
| `resize(target?, cb)` | — | one shared `ResizeObserver`. Omit target to watch the viewport |

```js
inView("section", (el) => {
  const anim = animate(el, { opacity: 1, y: 0 })
  return () => animate(el, { opacity: 0 })   // on leaving the viewport
})
hover(".card", el => { animate(el, { scale: 1.03 }); return () => animate(el, { scale: 1 }) })
```
All accept selectors or elements and manage listener lifecycles automatically.

---

## 7. Motion values (vanilla)

```js
import { motionValue, springValue, transformValue, mapValue,
         styleEffect, attrEffect, svgEffect, propEffect } from "motion"

const x = motionValue(0)
x.on("change", v => …)
animate(x, 100)

const smooth = springValue(x)                                  // spring follower
const filter = transformValue(() => `blur(${x.get()}px)`)      // combine / compute
const opacity = mapValue(x, [-100, 0, 100, 200], [0, 1, 1, 0]) // range mapping

styleEffect("div", { x, filter })      // bind to CSS style (independent transforms, default units)
attrEffect("rect", { width })          // bind to HTML attributes (auto kebab-case for aria-/data-)
svgEffect("circle", { cx })            // SVG; supports 0–1 drawing progress; attrWidth forces attribute
propEffect(obj, { x })                 // bind to any JS object property (this is what Three.js uses)
```
Every effect writes to the DOM at most once per frame, during the frameloop's render step.
Calling the function an effect returns unbinds it.

---

## 8. Utilities

| Function | Purpose |
|---|---|
| `transform([in], [out])` | build a mapping function without motion values: `transform([0,100],["#000","#fff"])(50)` |
| `mix(a, b)` | returns a mixer. Numbers, colours, composite strings, arrays and objects. **RGB mixes in linear colour space**, avoiding CSS's grey dip |
| `wrap(min, max, v)` | wrap a value through a range, for next/prev paging |
| `delay(cb, seconds)` | frameloop-aligned setTimeout; returns a cancel function |
| `frame.read/update/render(cb)` | staged scheduling that avoids layout thrashing; all callbacks share one rAF |
| `spring({ keyframes, ... })` | returns a generator; `gen.next(ms)` → `{value, done}`. For visualisation or CSS generation |
| `arc({ strength, peak, direction, rotate })` | pass to `transition.path` to curve x/y. **Not supported in mini** |
| easing | `cubicBezier` / `easeIn\|Out\|InOut` / `backIn\|Out\|InOut` / `circIn\|Out\|InOut` / `anticipate` / `linear` / `steps(n, "start"?)` / `reverseEasing` / `mirrorEasing` |

⚠️ When calling `spring()` directly, `duration` is in **milliseconds** (historical). Everywhere else
it is seconds.

---

## 9. Generating CSS springs (animation without shipping the library)

`spring()` can emit a CSS `linear()` easing, giving plain CSS a spring feel:

```js
import { spring } from "motion"
element.style.transition = "all " + spring(0.5)     // 0.5 = visualDuration in seconds
```
Producing something like:
```css
transition: scale 200ms linear(0, 0.009, 0.036, 0.084, …, 1.052, 1.038, …, 1);
```
Compute it at build time and paste it into CSS or a Tailwind config for **zero runtime JS** — ideal
for RSC, Astro, and static sites. Older browsers without `linear()` fall back to linear, so guard
with `@supports`.

---

## 10. Platform integrations

There are dedicated pages for Webflow, WordPress, Squarespace, Framer and Figma. The approach is
always the same: import the ESM build via a script tag, then `animate()` a selector.
Fetch the official text with `scripts/fetch-doc.sh <slug>` when you need specifics.
