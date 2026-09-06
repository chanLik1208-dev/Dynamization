# recipes.md — 可直接使用的配方

每則都標了**感覺目標**。改參數前先看那一行，確認你要的是不是同一件事。
全部不依賴 Motion+ 付費元件 —— 需要付費元件才能做的效果，這裡給自足的替代版本。

React 語法為主；Vue 改寫規則見 `vue.md` §7。

---

## 0. 全站底座

> 感覺目標：整個產品的動態有一致的性格。

```jsx
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

## 1. 元素進場

> 感覺目標：新內容「到位」，而不是「飛進來」。

```jsx
<motion.div
  initial={{ opacity: 0, y: 8 }}
  animate={{ opacity: 1, y: 0 }}
  transition={T.enter}
/>
```
位移只用 `8px`。要更明顯就 `12–16px`，**不要超過 24px**。

---

## 2. 清單 stagger

> 感覺目標：有先後順序，眼睛知道從哪開始讀。

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
**先算總時長**：`0.04 × 項目數 + 0.3` 要 ≤ `0.8s`。超過就把間隔調小。

---

## 3. 滾動觸發淡入

> 感覺目標：內容跟著閱讀節奏出現，不干擾捲動。

```jsx
<motion.section
  initial={{ opacity: 0, y: 16 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.3 }}
  transition={T.enter}
/>
```
`once: true` 幾乎永遠要加。

---

## 4. 按鈕：位移 + 明暗一起變

> 感覺目標：可按 → 按下去了。**兩個屬性同向變化才有實體感**（見 `contrast.md` §4）。

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

## 5. 卡片 hover 抬升（長清單也不掉幀）

> 感覺目標：靠近使用者。陰影用偽元素的 opacity，不直接動 `box-shadow`。

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

## 6. Modal（scrim + 內容 + 焦點管理）

> 感覺目標：世界暗下來，只剩這一件事。

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
scrim 先到位（`0.2s`），內容後到（`0.28s`）—— 見 `contrast.md` §5。

---

## 7. 從卡片展開成 Modal（共享元素）

> 感覺目標：這不是新視窗，是同一個東西放大了。**因果表達的最強形式。**

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
- `layoutId` 要跨兩個元素**一致且唯一**。
- 內部才有的內容延後 `0.15s` 淡入，等外框先就位。
- 圓角要寫在 `style` 裡（不是 CSS class）才會被反畸變修正。

---

## 8. Dropdown / Popover（從觸發點長出來）

> 感覺目標：是那顆按鈕生出來的。

```jsx
<AnimatePresence>
  {open && (
    <motion.div
      style={{ transformOrigin: "top left" }}   // 指向觸發按鈕的方位
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
`transformOrigin` 要隨開啟方向改（往上開就 `bottom left`）。

---

## 9. Accordion（高度動畫，零 layout thrash）

> 感覺目標：內容把空間推開，其他東西順勢讓位。

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
多個 accordion 互相影響版面時，外層包 `<LayoutGroup>`。
標題用 `layout="position"` 避免文字被 scale 拉扯。

---

## 10. Tab 底線（滑過去，不是閃過去）

> 感覺目標：同一條底線移動，不是兩條在交替。

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
多組 tab 在同一頁時，用 `<LayoutGroup id="tabs-a">` 隔開 `layoutId` 命名空間。

---

## 11. Toast / 通知堆疊

> 感覺目標：從它會停留的角落來，走的時候不擋路。

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
`mode="popLayout"` 讓移除者立刻脫離版面，其他 toast 馬上遞補。
容器要 `position: relative`（`popLayout` 內部用 absolute）。

---

## 12. 拖曳排序

> 感覺目標：抓得起來、放得下去。

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
自由拖曳版：
```jsx
<motion.div drag dragConstraints={boxRef} dragElastic={0.2}
            whileDrag={{ scale: 1.04 }}
            dragTransition={{ power: 0.2, modifyTarget: v => Math.round(v / 50) * 50 }} />
```
`modifyTarget` ＝ 吸附網格。

---

## 13. 捲動進度條

```jsx
const { scrollYProgress } = useScroll()
const scaleX = useSpring(scrollYProgress, { stiffness: 100, damping: 30, restDelta: 0.001 })
<motion.div style={{ scaleX, originX: 0, position: "fixed", top: 0, left: 0, right: 0, height: 3 }} />
```

## 14. 視差

> 感覺目標：有景深，不是背景在漂。

```jsx
const ref = useRef(null)
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] })
const bgY = useTransform(scrollYProgress, [0, 1], ["-12%", "12%"])   // 幅度克制
const prefersReduced = useReducedMotion()

<div ref={ref}>
  <motion.img style={{ y: prefersReduced ? 0 : bgY }} />
</div>
```
**視差必須判斷 reduced motion。**

## 15. 水平捲動區

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
外層越高，橫向捲動感覺越慢。

## 16. 圖片捲動揭示

```jsx
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "center center"] })
const clipPath = useTransform(scrollYProgress, [0, 1],
  ["inset(0% 50% 0% 50%)", "inset(0% 0% 0% 0%)"])
<motion.div ref={ref} style={{ clipPath }}><img src="…" /></motion.div>
```

---

## 17. 分割文字（免費替代 `splitText`）

> 感覺目標：文字有節奏地出現。**必須保留無障礙可讀性。**

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
          {wi < words.length - 1 && " "}
        </span>
      ))}
    </span>
  )
}
```
三個非做不可的細節：
1. **容器 `aria-label` 放原文，切片全部 `aria-hidden`** —— 否則螢幕閱讀器會逐字唸。
2. 切片要 `display: inline-block`，否則 transform 對 inline 元素無效。
3. 逐字（`text.split("")`）只用在短標題；長文一律逐詞，否則 DOM 會爆。
4. 若在掛載時分割，要等 `document.fonts.ready` 再量測換行。
5. 底部被切到時：加 `padding-bottom: .15em` 配 `margin-bottom: -.15em`。

## 18. 逐詞捲動揭示

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
最後一個字在 `0.8` 開始、`1.0` 結束 —— 讓揭示在捲完之前完成。

## 19. 打字機（有人類節奏，免費替代 `Typewriter`）

> 感覺目標：像人在打字。**等間隔＝機器人，這是關鍵差異。**

```jsx
function Typewriter({ text, cps = 22 }) {
  const [n, setN] = useState(0)
  const reduced = useReducedMotion()
  useEffect(() => {
    if (reduced) { setN(text.length); return }
    if (n >= text.length) return
    const ch = text[n]
    const base = 1000 / cps
    // 人類節奏:詞中快、詞界慢、標點後停頓、加上隨機抖動
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
`contain: layout` 限制重排範圍。游標閃爍用 `times` 做方波（不是淡入淡出）。

## 20. 數字計數（免費替代 `AnimateNumber`）

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
`tabular-nums` 是必要的 —— 否則數字寬度變化會讓版面抖動。

---

## 21. SVG 線條繪製

```jsx
<motion.path d="…" fill="none" stroke="currentColor"
  initial={{ pathLength: 0 }} animate={{ pathLength: 1 }}
  transition={{ duration: 1.2, ease: "easeInOut" }} />
```
支援 `circle` `ellipse` `line` `path` `polygon` `polyline` `rect`。
另有 `pathSpacing` / `pathOffset`（皆 0–1）可做虛線行進。

---

## 22. Skeleton 微光

> 感覺目標：「還在載入」。**低對比、慢週期，不搶注意力。**

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
`--surface-3` 與 `--surface-2` 的差距要小（淺色主題約 4–6% 明度）。深色主題要更小。
reduced motion 時直接停在靜態底色。

---

## 23. 頁面轉場（Next.js App Router）

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
`mode="wait"` ＋ 進 `easeOut` / 出 `easeIn` ＝ 整體 `easeInOut`。
頁面轉場總時長控制在 `0.4s` 內，否則導航會感覺遲鈍。

---

## 24. CSS spring（不載入函式庫的執行期）

```js
import { spring } from "motion"
console.log(spring(0.4, 0.2))   // visualDuration=0.4s, bounce=0.2
// → "400ms linear(0, 0.009, 0.036, …, 1.02, 1.005, 1)"
```
build 時算好貼進 CSS：
```css
.card { transition: scale 400ms linear(0, 0.009, …, 1); }
.card:hover { scale: 1.03; }
@supports not (transition-timing-function: linear(0, 1)) {
  .card { transition-timing-function: cubic-bezier(.2,.8,.2,1); }
}
```
執行期零 JS，適合 RSC / Astro / 靜態站。

---

## 25. Reduced motion 的分支寫法

```jsx
const reduced = useReducedMotion()

// 位移改成純淡入
const variants = reduced
  ? { hidden: { opacity: 0 }, show: { opacity: 1 } }
  : { hidden: { opacity: 0, y: 16 }, show: { opacity: 1, y: 0 } }

<video autoPlay={!reduced} />
<motion.div style={{ y: reduced ? 0 : parallaxY }} />
```
全站層級用 `<MotionConfig reducedMotion="user">` 就會自動停掉 transform 與 layout 動畫、保留 opacity 與顏色。個別視差、自動播放、無限迴圈仍要手動判斷。
