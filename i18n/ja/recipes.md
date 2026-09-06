# recipes.md — そのまま使えるレシピ

各項目に**意図**を書いてあります。引数を変える前にその行を読み、自分が求めているものと同じかを確認してください。

有料の Motion+ コンポーネントに依存するものはありません。通常なら必要な効果には、自己完結した代替を用意しています。

React 記法で書いています。Vue への移植は `references/vue.md` §7 を参照してください。

---

## 0. 土台

> 意図：プロダクト全体で一貫した性格。

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

## 1. 要素の登場

> 意図：新しい内容が**到着する**こと。飛び込んでくることではありません。

```jsx
<motion.div
  initial={{ opacity: 0, y: 8 }}
  animate={{ opacity: 1, y: 0 }}
  transition={T.enter}
/>
```
移動は `8px`。強調したければ `12〜16px`、ただし **24px は超えないこと**。

---

## 2. リストの stagger

> 意図：目に読む順序を与える。

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
**先に計算すること**：`0.04 × 個数 + 0.3` が `0.8s` 未満に収まること。超えるなら間隔を縮めます。

---

## 3. スクロールトリガーのフェード

> 意図：読む速度に合わせて内容が現れ、スクロールを妨げない。

```jsx
<motion.section
  initial={{ opacity: 0, y: 16 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.3 }}
  transition={T.enter}
/>
```
`once: true` はほぼ必須です。

---

## 4. ボタン：移動と明暗を同時に

> 意図：押せる → 押した。**同じ向きの 2 プロパティが実体感を生みます**（`i18n/ja/contrast.md` §4）。

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

## 5. カードの hover 浮上（長いリストでも耐える）

> 意図：ユーザーに近づく。影は `box-shadow` を直接動かさず、擬似要素の opacity を通します。

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

## 6. モーダル（スクリム＋内容）

> 意図：世界が暗くなり、これだけが残る。

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
スクリムが先（`0.2s`）、内容が後（`0.28s`）—— `i18n/ja/contrast.md` §5 参照。

---

## 7. カードがモーダルへ展開（共有要素）

> 意図：これは新しいウィンドウではなく、同じものが大きくなったのだ。**因果の最も強い表明。**

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
- `layoutId` は 2 つの要素で一致し、かつ一意であること。
- 内部にしかない内容は `0.15s` 遅らせて、外枠が収まってからフェードインさせます。
- 角丸は CSS クラスではなく `style` に書くこと。そうしないと歪み補正が効きません。

---

## 8. ドロップダウン / ポップオーバー（トリガーから生える）

> 意図：これはそのボタンから出てきた。

```jsx
<AnimatePresence>
  {open && (
    <motion.div
      style={{ transformOrigin: "top left" }}   // トリガーの方向を指す
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
`transformOrigin` は開く方向に合わせて変えます（上に開くなら `bottom left`）。

---

## 9. アコーディオン（レイアウトを揺らさない高さアニメーション）

> 意図：内容が空間を押し広げ、他が場所を譲る。

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
互いに影響し合うアコーディオンが複数あるときは `<LayoutGroup>` で包みます。
見出しは `layout="position"` にして、文字が scale で引き伸ばされないようにします。

---

## 10. タブの下線（点滅ではなく滑る）

> 意図：1 本の下線が動いているのであって、2 本が交代しているのではない。

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
1 ページに複数のタブ群があるときは `<LayoutGroup id="tabs-a">` で `layoutId` の名前空間を分けます。

---

## 11. トーストの積み重ね

> 意図：留まる角から来て、去るときは邪魔にならない。

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
`mode="popLayout"` で去るトーストが即座にフローから外れ、残りが詰めます。
コンテナには `position: relative` が必要です（popLayout は内部で absolute を使います）。

---

## 12. ドラッグ並べ替え

> 意図：掴めて、置ける。

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
自由ドラッグ：
```jsx
<motion.div drag dragConstraints={boxRef} dragElastic={0.2}
            whileDrag={{ scale: 1.04 }}
            dragTransition={{ power: 0.2, modifyTarget: v => Math.round(v / 50) * 50 }} />
```
`modifyTarget` でグリッドに吸着します。

---

## 13. スクロール進捗バー

```jsx
const { scrollYProgress } = useScroll()
const scaleX = useSpring(scrollYProgress, { stiffness: 100, damping: 30, restDelta: 0.001 })
<motion.div style={{ scaleX, originX: 0, position: "fixed", top: 0, left: 0, right: 0, height: 3 }} />
```

## 14. パララックス

> 意図：奥行き。背景が漂っているのではない。

```jsx
const ref = useRef(null)
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] })
const bgY = useTransform(scrollYProgress, [0, 1], ["-12%", "12%"])   // 抑制的な振幅
const prefersReduced = useReducedMotion()

<div ref={ref}>
  <motion.img style={{ y: prefersReduced ? 0 : bgY }} />
</div>
```
**パララックスは reduced motion で必ず分岐すること。**

## 15. 横スクロールセクション

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
外側のコンテナが高いほど横スクロールは遅く感じます。

## 16. スクロールによる画像の露出

```jsx
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "center center"] })
const clipPath = useTransform(scrollYProgress, [0, 1],
  ["inset(0% 50% 0% 50%)", "inset(0% 0% 0% 0%)"])
<motion.div ref={ref} style={{ clipPath }}><img src="…" /></motion.div>
```

---

## 17. テキスト分割（`splitText` の無料代替）

> 意図：文字がリズムを持って現れる。**アクセシビリティを壊さないこと。**

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
省略できない 5 点：
1. **コンテナが `aria-label` に原文を持ち、断片はすべて `aria-hidden`。**
   さもないとスクリーンリーダーが一文字ずつ読み上げます。
2. 断片は `display: inline-block` が必要。inline ボックスには transform が効きません。
3. 一文字単位（`text.split("")`）は短い見出しだけに。長文は必ず単語単位。DOM が爆発します。
4. マウント時に分割するなら、`document.fonts.ready` を待ってから行の測定をすること。
5. 下部が切れるときは `padding-bottom: .15em` と対になる `margin-bottom: -.15em` を追加。

## 18. 単語単位のスクロール露出

```jsx
function ScrollReveal({ text }) {
  const ref = useRef(null)
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start 0.9", "start 0.25"] })
  const words = text.split(" ")
  return (
    <p ref={ref} aria-label={text}>
      {words.map((w, i) => {
        const start = words.length === 1 ? 0 : (i / (words.length - 1)) * 0.8
        const opacity = useTransform(scrollYProgress, [start, start + 0.2], [0.15, 1])
        return <motion.span aria-hidden key={i} style={{ opacity }}>{w}{" "}</motion.span>
      })}
    </p>
  )
}
```
最後の単語は `0.8` で始まり `1.0` で終わるので、スクロールが終わる前に露出が完了します。

## 19. 人間のリズムを持つタイプライター（`Typewriter` の無料代替）

> 意図：人が打っているように見えること。**等間隔はロボットに見える —— それが唯一の差です。**

```jsx
function Typewriter({ text, cps = 22 }) {
  const [n, setN] = useState(0)
  const reduced = useReducedMotion()
  useEffect(() => {
    if (reduced) { setN(text.length); return }
    if (n >= text.length) return
    const ch = text[n]
    const base = 1000 / cps
    // 人間のリズム：語中は速く、語境界は遅く、句読点の後は間を置き、さらに揺らぎを加える
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
`contain: layout` が再レイアウトの範囲を限定します。カーソルの点滅は `times` による矩形波で、
フェードではありません。

## 20. 数値カウント（`AnimateNumber` の無料代替）

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
`tabular-nums` は必須です。無いと桁幅の変化でレイアウトが揺れます。

---

## 21. SVG の線描画

```jsx
<motion.path d="…" fill="none" stroke="currentColor"
  initial={{ pathLength: 0 }} animate={{ pathLength: 1 }}
  transition={{ duration: 1.2, ease: "easeInOut" }} />
```
`circle` `ellipse` `line` `path` `polygon` `polyline` `rect` に対応。
`pathSpacing` と `pathOffset`（いずれも 0〜1）で破線を進ませられます。

---

## 22. スケルトンの光沢

> 意図：「まだ読み込み中」。**低コントラスト、ゆっくりした周期、注意を奪わないこと。**

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
`--surface-3` は `--surface-2` に近づけます（ライトテーマで明度差 4〜6% 程度、ダークではさらに小さく）。
reduced motion では静的な下地色で止めます。

---

## 23. ページ遷移（Next.js App Router）

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
`mode="wait"` と、入り `easeOut` / 出 `easeIn` の組み合わせで全体が `easeInOut` になります。
遷移全体は `0.4s` 以内に。それを超えるとナビゲーションが鈍く感じられます。

---

## 24. CSS スプリング（実行時にライブラリを積まない）

```js
import { spring } from "motion"
console.log(spring(0.4, 0.2))   // visualDuration=0.4s, bounce=0.2
// → "400ms linear(0, 0.009, 0.036, …, 1.02, 1.005, 1)"
```
ビルド時に計算して CSS に貼ります：
```css
.card { transition: scale 400ms linear(0, 0.009, …, 1); }
.card:hover { scale: 1.03; }
@supports not (transition-timing-function: linear(0, 1)) {
  .card { transition-timing-function: cubic-bezier(.2,.8,.2,1); }
}
```
実行時 JS はゼロ。RSC、Astro、静的サイトに向いています。

---

## 25. reduced motion での分岐

```jsx
const reduced = useReducedMotion()

// 移動を単純なフェードに置き換える
const variants = reduced
  ? { hidden: { opacity: 0 }, show: { opacity: 1 } }
  : { hidden: { opacity: 0, y: 16 }, show: { opacity: 1, y: 0 } }

<video autoPlay={!reduced} />
<motion.div style={{ y: reduced ? 0 : parallaxY }} />
```
`<MotionConfig reducedMotion="user">` はサイト全体を担当し、transform と layout を止め、
opacity と色は残します。パララックス、自動再生、無限ループは別途明示的な分岐が必要です。
