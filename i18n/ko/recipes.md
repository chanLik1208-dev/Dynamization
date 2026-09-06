# recipes.md — 바로 쓸 수 있는 레시피

각 항목에 **의도**를 적어두었습니다. 인자를 바꾸기 전에 그 줄을 읽고, 원하는 것이 같은지 확인하세요.

유료 Motion+ 컴포넌트에 의존하는 것은 하나도 없습니다. 원래 유료가 필요한 효과에는 자체 완결형
대체품을 제공합니다.

React 문법으로 작성했습니다. Vue 이식은 `references/vue.md` §7을 참조하세요.

---

## 0. 토대

> 의도: 제품 전체에 일관된 성격.

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

## 1. 요소 등장

> 의도: 새 콘텐츠가 **도착하는 것**. 날아 들어오는 것이 아닙니다.

```jsx
<motion.div
  initial={{ opacity: 0, y: 8 }}
  animate={{ opacity: 1, y: 0 }}
  transition={T.enter}
/>
```
이동은 `8px`. 강조하려면 `12~16px`, 다만 **24px를 넘기지 마세요**.

---

## 2. 리스트 stagger

> 의도: 눈에 읽을 순서를 준다.

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
**먼저 계산하세요**: `0.04 × 개수 + 0.3`이 `0.8s` 미만이어야 합니다. 넘으면 간격을 줄이세요.

---

## 3. 스크롤 트리거 페이드

> 의도: 읽는 속도에 맞춰 콘텐츠가 나타나고, 스크롤을 방해하지 않는다.

```jsx
<motion.section
  initial={{ opacity: 0, y: 16 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.3 }}
  transition={T.enter}
/>
```
`once: true`는 거의 필수입니다.

---

## 4. 버튼: 이동과 명암을 함께

> 의도: 누를 수 있다 → 눌렀다. **같은 방향의 두 속성이 실체감을 만듭니다**(`i18n/ko/contrast.md` §4).

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

## 5. 카드 hover 부상(긴 목록에서도 버팀)

> 의도: 사용자에게 가까워진다. 그림자는 `box-shadow`를 직접 움직이지 않고 의사 요소의 opacity를 거칩니다.

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

## 6. 모달(스크림 + 콘텐츠)

> 의도: 세상이 어두워지고 이것만 남는다.

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
스크림이 먼저(`0.2s`), 콘텐츠가 나중(`0.28s`) — `i18n/ko/contrast.md` §5 참조.

---

## 7. 카드가 모달로 확장(공유 요소)

> 의도: 이것은 새 창이 아니라 같은 것이 커진 것이다. **인과의 가장 강한 표명.**

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
- `layoutId`는 두 요소에서 동일하고 유일해야 합니다.
- 내부에만 있는 콘텐츠는 `0.15s` 늦춰서, 외곽이 자리를 잡은 뒤 페이드인시킵니다.
- 모서리 반경은 CSS 클래스가 아니라 `style`에 써야 왜곡 보정이 적용됩니다.

---

## 8. 드롭다운 / 팝오버(트리거에서 자라남)

> 의도: 이것은 그 버튼에서 나왔다.

```jsx
<AnimatePresence>
  {open && (
    <motion.div
      style={{ transformOrigin: "top left" }}   // 트리거 방향을 가리킴
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
`transformOrigin`은 열리는 방향에 맞춰 바꿉니다(위로 열리면 `bottom left`).

---

## 9. 아코디언(레이아웃을 흔들지 않는 높이 애니메이션)

> 의도: 콘텐츠가 공간을 밀어 열고, 나머지가 자리를 내준다.

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
서로 영향을 주는 아코디언이 여럿이면 `<LayoutGroup>`으로 감쌉니다.
제목은 `layout="position"`으로 두어 글자가 scale로 늘어나지 않게 합니다.

---

## 10. 탭 밑줄(깜빡이지 않고 미끄러진다)

> 의도: 하나의 밑줄이 움직이는 것이지, 둘이 교대하는 것이 아니다.

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
한 페이지에 탭 묶음이 여럿이면 `<LayoutGroup id="tabs-a">`로 `layoutId` 네임스페이스를 분리합니다.

---

## 11. 토스트 스택

> 의도: 머무를 모서리에서 오고, 떠날 때는 길을 막지 않는다.

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
`mode="popLayout"`으로 떠나는 토스트가 즉시 흐름에서 빠지고 나머지가 메웁니다.
컨테이너에는 `position: relative`가 필요합니다(popLayout이 내부에서 absolute를 씁니다).

---

## 12. 드래그 재정렬

> 의도: 잡을 수 있고, 놓을 수 있다.

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
자유 드래그:
```jsx
<motion.div drag dragConstraints={boxRef} dragElastic={0.2}
            whileDrag={{ scale: 1.04 }}
            dragTransition={{ power: 0.2, modifyTarget: v => Math.round(v / 50) * 50 }} />
```
`modifyTarget`으로 그리드에 흡착합니다.

---

## 13. 스크롤 진행 바

```jsx
const { scrollYProgress } = useScroll()
const scaleX = useSpring(scrollYProgress, { stiffness: 100, damping: 30, restDelta: 0.001 })
<motion.div style={{ scaleX, originX: 0, position: "fixed", top: 0, left: 0, right: 0, height: 3 }} />
```

## 14. 패럴랙스

> 의도: 깊이. 배경이 떠다니는 것이 아니다.

```jsx
const ref = useRef(null)
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] })
const bgY = useTransform(scrollYProgress, [0, 1], ["-12%", "12%"])   // 절제된 진폭
const prefersReduced = useReducedMotion()

<div ref={ref}>
  <motion.img style={{ y: prefersReduced ? 0 : bgY }} />
</div>
```
**패럴랙스는 reduced motion에서 반드시 분기해야 합니다.**

## 15. 가로 스크롤 섹션

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
바깥 컨테이너가 높을수록 가로 스크롤이 느리게 느껴집니다.

## 16. 스크롤 이미지 공개

```jsx
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "center center"] })
const clipPath = useTransform(scrollYProgress, [0, 1],
  ["inset(0% 50% 0% 50%)", "inset(0% 0% 0% 0%)"])
<motion.div ref={ref} style={{ clipPath }}><img src="…" /></motion.div>
```

---

## 17. 텍스트 분할(`splitText`의 무료 대체)

> 의도: 글자가 리듬을 가지고 나타난다. **접근성을 깨뜨리지 말 것.**

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
생략할 수 없는 다섯 가지:
1. **컨테이너가 `aria-label`에 원문을 갖고, 조각은 전부 `aria-hidden`.**
   그러지 않으면 스크린 리더가 한 글자씩 읽습니다.
2. 조각에는 `display: inline-block`이 필요합니다. inline 박스에는 transform이 적용되지 않습니다.
3. 글자 단위(`text.split("")`)는 짧은 제목에만. 긴 글은 반드시 단어 단위로. DOM이 폭발합니다.
4. 마운트 시 분할한다면 `document.fonts.ready`를 기다린 뒤 줄바꿈을 측정하세요.
5. 아랫부분이 잘리면 `padding-bottom: .15em`과 짝이 되는 `margin-bottom: -.15em`을 추가하세요.

## 18. 단어 단위 스크롤 공개

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
마지막 단어는 `0.8`에서 시작해 `1.0`에서 끝나므로, 스크롤이 끝나기 전에 공개가 완료됩니다.

## 19. 인간의 리듬을 가진 타자기(`Typewriter`의 무료 대체)

> 의도: 사람이 치는 것처럼 보일 것. **균등한 간격은 로봇처럼 보입니다 — 그것이 유일한 차이입니다.**

```jsx
function Typewriter({ text, cps = 22 }) {
  const [n, setN] = useState(0)
  const reduced = useReducedMotion()
  useEffect(() => {
    if (reduced) { setN(text.length); return }
    if (n >= text.length) return
    const ch = text[n]
    const base = 1000 / cps
    // 인간의 리듬: 단어 중간은 빠르게, 경계는 느리게, 문장 부호 뒤엔 멈춤, 거기에 흔들림
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
`contain: layout`이 재배치 범위를 제한합니다. 커서 깜빡임은 `times`를 이용한 사각파이며 페이드가
아닙니다.

## 20. 숫자 카운트(`AnimateNumber`의 무료 대체)

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
`tabular-nums`는 필수입니다. 없으면 자릿수 폭 변화로 레이아웃이 흔들립니다.

---

## 21. SVG 선 그리기

```jsx
<motion.path d="…" fill="none" stroke="currentColor"
  initial={{ pathLength: 0 }} animate={{ pathLength: 1 }}
  transition={{ duration: 1.2, ease: "easeInOut" }} />
```
`circle` `ellipse` `line` `path` `polygon` `polyline` `rect`를 지원합니다.
`pathSpacing`과 `pathOffset`(둘 다 0~1)으로 점선을 행진시킬 수 있습니다.

---

## 22. 스켈레톤 광택

> 의도: "아직 불러오는 중". **저대비, 느린 주기, 주의를 빼앗지 않을 것.**

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
`--surface-3`은 `--surface-2`에 가깝게(라이트 테마에서 명도 차 4~6% 정도, 다크에서는 더 작게).
reduced motion에서는 정적인 바탕색에 멈춥니다.

---

## 23. 페이지 전환(Next.js App Router)

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
`mode="wait"`와 들어올 때 `easeOut` / 나갈 때 `easeIn`의 조합으로 전체가 `easeInOut`이 됩니다.
전환 전체는 `0.4s` 이내로. 넘으면 내비게이션이 굼뜨게 느껴집니다.

---

## 24. CSS 스프링(런타임에 라이브러리를 싣지 않음)

```js
import { spring } from "motion"
console.log(spring(0.4, 0.2))   // visualDuration=0.4s, bounce=0.2
// → "400ms linear(0, 0.009, 0.036, …, 1.02, 1.005, 1)"
```
빌드 시 계산해 CSS에 붙입니다:
```css
.card { transition: scale 400ms linear(0, 0.009, …, 1); }
.card:hover { scale: 1.03; }
@supports not (transition-timing-function: linear(0, 1)) {
  .card { transition-timing-function: cubic-bezier(.2,.8,.2,1); }
}
```
런타임 JS가 0입니다. RSC, Astro, 정적 사이트에 적합합니다.

---

## 25. reduced motion 분기

```jsx
const reduced = useReducedMotion()

// 이동을 단순한 페이드로 대체
const variants = reduced
  ? { hidden: { opacity: 0 }, show: { opacity: 1 } }
  : { hidden: { opacity: 0, y: 16 }, show: { opacity: 1, y: 0 } }

<video autoPlay={!reduced} />
<motion.div style={{ y: reduced ? 0 : parallaxY }} />
```
`<MotionConfig reducedMotion="user">`가 사이트 전체를 담당해 transform과 layout을 끄고 opacity와
색은 유지합니다. 패럴랙스, 자동 재생, 무한 루프는 별도의 명시적 분기가 필요합니다.
