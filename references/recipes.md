# recipes.md — Ready-to-use patterns

Each recipe states its **intent**. Read that line before changing parameters, to check you want the
same thing it wants.

None of these depend on paid Motion+ components — where an effect normally needs one, a
self-contained replacement is given.

React syntax throughout; for Vue, see `vue.md` §7.

---

## 0. The foundation

> Intent: one consistent character across the whole product.

```js
// motion.tokens.js
export const T = {
  instant: { duration: 0.12, ease: "easeOut" },
  micro:   { duration: 0.2,  ease: "easeOut" },
  enter:   { type: "spring", visualDuration: 0.3,  bounce: 0.15 },
  exit:    { duration: 0.15, ease: "easeIn" },
  layout:  { type: "spring", visualDuration: 0.35, bounce: 0 },
  page:    { type: "spring", visualDuration: 0.5,  bounce: 0.1 },
  stagger: 0.04,
}
```
```jsx
// app root
import { MotionConfig } from "motion/react"
import { T } from "./motion.tokens"

<MotionConfig transition={T.enter} reducedMotion="user">
  <App />
</MotionConfig>
```

---

## 1. Element entry

> Intent: new content **arrives**, rather than flying in.

```jsx
<motion.div
  initial={{ opacity: 0, y: 8 }}
  animate={{ opacity: 1, y: 0 }}
  transition={T.enter}
/>
```
`8px` of travel. Go to `12–16px` if you want it more pronounced, but **never past 24px**.

---

## 2. List stagger

> Intent: give the eye an order to read in.

```jsx
import { motion, stagger } from "motion/react"

const list = {
  hidden: {},
  show: { transition: { delayChildren: stagger(0.04) } },
}
const item = {
  hidden: { opacity: 0, y: 8 },
  show:   { opacity: 1, y: 0 },
}

<motion.ul variants={list} initial="hidden" animate="show">
  {items.map(i => <motion.li key={i.id} variants={item} />)}
</motion.ul>
```
**Do the arithmetic first**: `0.04 × count + 0.3` should stay under `0.8s`. If it doesn't, shrink
the interval.

---

## 3. Scroll-triggered fade

> Intent: content appears in step with reading, without interrupting the scroll.

```jsx
<motion.section
  initial={{ opacity: 0, y: 16 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.3 }}
  transition={T.enter}
/>
```
`once: true` is nearly always required.

---

## 4. Button: movement and luminance together

> Intent: pressable → pressed. **Two properties in the same direction is what creates the sense of a
> physical object** (see `contrast.md` §4).

```jsx
<motion.button
  className="btn"
  whileHover={{ y: -1 }}
  whileTap={{ scale: 0.97, y: 0 }}
  transition={{ type: "spring", visualDuration: 0.15, bounce: 0 }}
/>
```
```css
.btn {
  background: var(--surface);
  box-shadow: var(--shadow-1);
  transition: box-shadow .15s ease-out, filter .12s ease-out;
}
.btn:hover  { box-shadow: var(--shadow-2); }
.btn:active { box-shadow: var(--shadow-1), inset 0 1px 2px rgb(0 0 0 / .12);
              filter: brightness(.96); }
```

---

## 5. Card hover lift (that survives a long list)

> Intent: come closer to the user. The shadow goes through a pseudo-element's opacity rather than
> animating `box-shadow` directly.

```jsx
<motion.article className="card" whileHover={{ y: -4 }}
  transition={{ type: "spring", visualDuration: 0.2, bounce: 0 }} />
```
```css
.card { position: relative; box-shadow: var(--shadow-2); }
.card::after {
  content: ""; position: absolute; inset: 0; border-radius: inherit;
  box-shadow: var(--shadow-4); opacity: 0;
  transition: opacity .2s ease-out; pointer-events: none;
}
.card:hover::after { opacity: 1; }
```

---

## 6. Modal (scrim + content)

> Intent: the world dims; only this remains.

```jsx
<AnimatePresence>
  {open && (
    <>
      <motion.div className="scrim" onClick={close}
        initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
        transition={{ duration: 0.2, ease: "easeOut" }} />
      <motion.div className="dialog" role="dialog" aria-modal="true"
        initial={{ opacity: 0, scale: 0.96, y: 8 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.98, y: 4, transition: T.exit }}
        transition={{ type: "spring", visualDuration: 0.28, bounce: 0.1 }} />
    </>
  )}
</AnimatePresence>
```
```css
.scrim  { position: fixed; inset: 0; background: rgb(0 0 0 / .45); }
.dialog { position: fixed; inset: 0; margin: auto; background: var(--elevated); }
```
The scrim lands first (`0.2s`), the content second (`0.28s`) — see `contrast.md` §5.

---

## 7. Card expanding into a modal (shared element)

> Intent: this is not a new window, it is the same object enlarged. **The strongest statement of
> causality available.**

```jsx
{cards.map(c => (
  <motion.div key={c.id} layoutId={`card-${c.id}`} onClick={() => setSel(c.id)}>
    <motion.h3 layoutId={`title-${c.id}`}>{c.title}</motion.h3>
  </motion.div>
))}

<AnimatePresence>
  {sel && (
    <motion.div className="dialog" layoutId={`card-${sel}`}
                transition={{ type: "spring", visualDuration: 0.35, bounce: 0 }}>
      <motion.h3 layoutId={`title-${sel}`}>…</motion.h3>
      <motion.p initial={{ opacity: 0 }} animate={{ opacity: 1 }}
                transition={{ delay: 0.15 }}>…</motion.p>
    </motion.div>
  )}
</AnimatePresence>
```
- `layoutId` must be identical and unique across the two elements.
- Interior-only content fades in `0.15s` later, after the frame has settled.
- Put `borderRadius` in `style` (not a CSS class) so scale correction applies.

---

## 8. Dropdown / popover (grown from the trigger)

> Intent: this came out of that button.

```jsx
<AnimatePresence>
  {open && (
    <motion.div
      style={{ transformOrigin: "top left" }}   // point at the trigger
      initial={{ opacity: 0, scale: 0.95, y: -4 }}
      animate={{ opacity: 1, scale: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.97, y: -2, transition: T.exit }}
      transition={{ type: "spring", visualDuration: 0.2, bounce: 0 }}
    >
      <motion.ul variants={{ show: { transition: { delayChildren: stagger(0.02) } } }}
                 initial="hidden" animate="show">…</motion.ul>
    </motion.div>
  )}
</AnimatePresence>
```
`transformOrigin` must follow the opening direction (`bottom left` when it opens upward).

---

## 9. Accordion (height animation without layout thrash)

> Intent: content pushes space open and everything else gives way.

```jsx
<motion.div layout onClick={() => setOpen(!open)}>
  <motion.h3 layout="position">{title}</motion.h3>
  <AnimatePresence initial={false}>
    {open && (
      <motion.div key="body" layout
        initial={{ opacity: 0, height: 0 }}
        animate={{ opacity: 1, height: "auto" }}
        exit={{ opacity: 0, height: 0 }}
        style={{ overflow: "hidden" }}
        transition={T.layout} />
    )}
  </AnimatePresence>
</motion.div>
```
Wrap several mutually-affecting accordions in `<LayoutGroup>`.
Use `layout="position"` on the heading so the text is not stretched by scale.

---

## 10. Tab underline (it slides, it doesn't blink)

> Intent: one underline moving, not two alternating.

```jsx
{tabs.map(t => (
  <button key={t.id} onClick={() => setActive(t.id)} style={{ position: "relative" }}>
    {t.label}
    {active === t.id && (
      <motion.div layoutId="tab-underline"
        style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 2 }}
        transition={{ type: "spring", visualDuration: 0.25, bounce: 0.15 }} />
    )}
  </button>
))}
```
With several tab sets on one page, isolate the `layoutId` namespace with `<LayoutGroup id="tabs-a">`.

---

## 11. Toast stack

> Intent: arrive from the corner it will rest in; get out of the way when leaving.

```jsx
<AnimatePresence mode="popLayout">
  {toasts.map(t => (
    <motion.div key={t.id} layout
      initial={{ opacity: 0, x: 24, scale: 0.96 }}
      animate={{ opacity: 1, x: 0, scale: 1 }}
      exit={{ opacity: 0, x: 24, scale: 0.96, transition: T.exit }}
      transition={T.enter} />
  ))}
</AnimatePresence>
```
`mode="popLayout"` drops the leaving toast out of flow so the rest close up immediately.
The container needs `position: relative` (popLayout uses absolute internally).

---

## 12. Drag to reorder

> Intent: it can be picked up, and it can be put down.

```jsx
import { Reorder } from "motion/react"

<Reorder.Group axis="y" values={items} onReorder={setItems}>
  {items.map(item => (
    <Reorder.Item key={item.id} value={item}
      whileDrag={{ scale: 1.03, boxShadow: "0 16px 32px rgb(0 0 0 / .18)", zIndex: 1 }}>
      {item.label}
    </Reorder.Item>
  ))}
</Reorder.Group>
```
Free dragging:
```jsx
<motion.div drag dragConstraints={boxRef} dragElastic={0.2}
            whileDrag={{ scale: 1.04 }}
            dragTransition={{ power: 0.2, modifyTarget: v => Math.round(v / 50) * 50 }} />
```
`modifyTarget` snaps to a grid.

---

## 13. Scroll progress bar

```jsx
const { scrollYProgress } = useScroll()
const scaleX = useSpring(scrollYProgress, { stiffness: 100, damping: 30, restDelta: 0.001 })
<motion.div style={{ scaleX, originX: 0, position: "fixed", top: 0, left: 0, right: 0, height: 3 }} />
```

## 14. Parallax

> Intent: depth — not a drifting background.

```jsx
const ref = useRef(null)
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] })
const bgY = useTransform(scrollYProgress, [0, 1], ["-12%", "12%"])   // restrained amplitude
const prefersReduced = useReducedMotion()

<div ref={ref}>
  <motion.img style={{ y: prefersReduced ? 0 : bgY }} />
</div>
```
**Parallax must branch on reduced motion.**

## 15. Horizontal scroll section

```jsx
const ref = useRef(null)
const { scrollYProgress } = useScroll({ target: ref, offset: ["start start", "end end"] })
const x = useTransform(scrollYProgress, [0, 1], ["0%", "-75%"])

<div ref={ref} style={{ height: "300vh" }}>
  <div style={{ position: "sticky", top: 0, height: "100vh", overflow: "hidden" }}>
    <motion.div style={{ x, display: "flex", gap: 20 }}>…</motion.div>
  </div>
</div>
```
A taller outer container makes the horizontal scroll feel slower.

## 16. Scroll image reveal

```jsx
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "center center"] })
const clipPath = useTransform(scrollYProgress, [0, 1],
  ["inset(0% 50% 0% 50%)", "inset(0% 0% 0% 0%)"])
<motion.div ref={ref} style={{ clipPath }}><img src="…" /></motion.div>
```

---

## 17. Split text (free replacement for `splitText`)

> Intent: text arrives with rhythm. **Accessibility must survive it.**

```jsx
function SplitText({ text, className, stagger: s = 0.03 }) {
  const words = text.split(" ")
  return (
    <span aria-label={text} className={className}>
      {words.map((w, wi) => (
        <span key={wi} style={{ display: "inline-block", overflow: "hidden", verticalAlign: "bottom" }}>
          <motion.span aria-hidden style={{ display: "inline-block" }}
            initial={{ y: "110%" }} animate={{ y: "0%" }}
            transition={{ delay: wi * s, type: "spring", visualDuration: 0.5, bounce: 0.15 }}>
            {w}
          </motion.span>
          {wi < words.length - 1 && " "}
        </span>
      ))}
    </span>
  )
}
```
Five details that are not optional:
1. **The container carries the original string in `aria-label`; every fragment is `aria-hidden`** —
   otherwise a screen reader spells it out letter by letter.
2. Fragments need `display: inline-block`; transforms do not apply to inline boxes.
3. Per-character (`text.split("")`) is for short headings only. Long copy must go per word or the
   DOM explodes.
4. When splitting on mount, wait for `document.fonts.ready` before measuring line breaks.
5. If descenders clip, add `padding-bottom: .15em` with a matching `margin-bottom: -.15em`.

## 18. Word-by-word scroll reveal

```jsx
// One hook per component: useTransform must not be called inside .map()
function RevealWord({ word, progress, start }) {
  const opacity = useTransform(progress, [start, start + 0.2], [0.15, 1])
  return <motion.span aria-hidden style={{ opacity }}>{word}{" "}</motion.span>
}

function ScrollReveal({ text }) {
  const ref = useRef(null)
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start 0.9", "start 0.25"] })
  const words = text.split(" ")
  return (
    <p ref={ref} aria-label={text}>
      {words.map((w, i) => (
        <RevealWord
          key={i}
          word={w}
          progress={scrollYProgress}
          start={words.length === 1 ? 0 : (i / (words.length - 1)) * 0.8}
        />
      ))}
    </p>
  )
}
```
The last word starts at `0.8` and finishes at `1.0`, so the reveal completes before the scroll does.

## 19. Typewriter with human rhythm (free replacement for `Typewriter`)

> Intent: it looks like a person typing. **Even intervals read as a robot — that is the whole
> difference.**

```jsx
function Typewriter({ text, cps = 22 }) {
  const [n, setN] = useState(0)
  const reduced = useReducedMotion()
  useEffect(() => {
    if (reduced) { setN(text.length); return }
    if (n >= text.length) return
    const ch = text[n]
    const base = 1000 / cps
    // human rhythm: fast mid-word, slower at boundaries, a real pause after punctuation, plus jitter
    const mult = /[.,!?;:]/.test(ch) ? 6 : ch === " " ? 2.2 : 1
    const jitter = 0.6 + Math.random() * 0.8
    const id = setTimeout(() => setN(n + 1), base * mult * jitter)
    return () => clearTimeout(id)
  }, [n, text, cps, reduced])
  return (
    <span aria-label={text} style={{ contain: "layout" }}>
      <span aria-hidden>{text.slice(0, n)}</span>
      <motion.span aria-hidden animate={{ opacity: [1, 1, 0, 0] }}
        transition={{ repeat: Infinity, duration: 1, times: [0, .5, .5, 1], ease: "linear" }}>▍</motion.span>
    </span>
  )
}
```
`contain: layout` bounds the reflow. The cursor blinks as a square wave via `times`, not a fade.

## 20. Animated number (free replacement for `AnimateNumber`)

```jsx
function Counter({ value, format = {} }) {
  const mv = useMotionValue(0)
  const ref = useRef(null)
  const fmt = useMemo(() => new Intl.NumberFormat(undefined, format), [format])
  useEffect(() => {
    const controls = animate(mv, value, { duration: 0.8, ease: "easeOut" })
    const unsub = mv.on("change", v => { if (ref.current) ref.current.textContent = fmt.format(v) })
    return () => { controls.stop(); unsub() }
  }, [value])
  return <span ref={ref} style={{ fontVariantNumeric: "tabular-nums" }} />
}
```
`tabular-nums` is mandatory — without it the changing digit widths make the layout jitter.

---

## 21. SVG line drawing

```jsx
<motion.path d="…" fill="none" stroke="currentColor"
  initial={{ pathLength: 0 }} animate={{ pathLength: 1 }}
  transition={{ duration: 1.2, ease: "easeInOut" }} />
```
Supports `circle` `ellipse` `line` `path` `polygon` `polyline` `rect`.
`pathSpacing` and `pathOffset` (both 0–1) produce marching dashes.

---

## 22. Skeleton shimmer

> Intent: "still loading". **Low contrast, slow period, no competition for attention.**

```jsx
<motion.div className="skeleton"
  animate={{ backgroundPosition: ["200% 0", "-200% 0"] }}
  transition={{ repeat: Infinity, duration: 1.8, ease: "linear" }} />
```
```css
.skeleton {
  background: linear-gradient(90deg,
    var(--surface-2) 25%, var(--surface-3) 37%, var(--surface-2) 63%);
  background-size: 400% 100%;
}
```
Keep `--surface-3` close to `--surface-2` (about 4–6% lightness apart in a light theme; even closer
in dark). Under reduced motion, settle on the flat base colour.

---

## 23. Page transition (Next.js App Router)

```jsx
"use client"
import { usePathname } from "next/navigation"
import { AnimatePresence, motion } from "motion/react"

export function PageTransition({ children }) {
  const pathname = usePathname()
  return (
    <AnimatePresence mode="wait" initial={false}>
      <motion.main key={pathname}
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0, transition: { duration: 0.25, ease: "easeOut" } }}
        exit={{ opacity: 0, y: -4, transition: { duration: 0.15, ease: "easeIn" } }}>
        {children}
      </motion.main>
    </AnimatePresence>
  )
}
```
`mode="wait"` plus `easeOut` in / `easeIn` out composes to an overall `easeInOut`.
Keep the whole transition under `0.4s` or navigation starts to feel sluggish.

---

## 24. CSS springs (no library at runtime)

```js
import { spring } from "motion"
console.log(spring(0.4, 0.2))   // visualDuration=0.4s, bounce=0.2
// → "400ms linear(0, 0.009, 0.036, …, 1.02, 1.005, 1)"
```
Compute at build time and paste into CSS:
```css
.card { transition: scale 400ms linear(0, 0.009, …, 1); }
.card:hover { scale: 1.03; }
@supports not (transition-timing-function: linear(0, 1)) {
  .card { transition-timing-function: cubic-bezier(.2,.8,.2,1); }
}
```
Zero runtime JS — ideal for RSC, Astro, and static sites.

---

## 25. Branching on reduced motion

```jsx
const reduced = useReducedMotion()

// replace displacement with a plain fade
const variants = reduced
  ? { hidden: { opacity: 0 }, show: { opacity: 1 } }
  : { hidden: { opacity: 0, y: 16 }, show: { opacity: 1, y: 0 } }

<video autoPlay={!reduced} />
<motion.div style={{ y: reduced ? 0 : parallaxY }} />
```
`<MotionConfig reducedMotion="user">` handles the site-wide case by disabling transform and layout
animations while preserving opacity and colour. Parallax, autoplay and infinite loops still need an
explicit branch.
