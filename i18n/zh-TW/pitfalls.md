# pitfalls.md — 症狀 → 原因 → 修法

先用症狀查表，再看下面的分區詳解。

| 症狀 | 最可能的原因 |
|---|---|
| 退場動畫完全沒觸發 | `AnimatePresence` 自己被移除了，或子代 `key` 不穩定 → §1 |
| 動畫每次都從頭跳一次 | 元件被重建（key 變了 / `motion.create` 在 render 裡）→ §2 |
| layout 動畫沒反應 | 元素是 `display: inline`，或該次沒有 re-render → §3 |
| 內容在 layout 動畫中被拉扯變形 | 子元素沒加 `layout`，或圓角/陰影沒寫在 `style` → §3 |
| 捲動時整頁抖動 | 捲軸出現/消失觸發 layout 動畫 → §3 |
| 動畫掉幀、卡頓 | 動到 layout 觸發屬性，或大面積 paint → §4 |
| 滾動連動有階梯感 | 沒過 `useSpring` → §5 |
| 拖曳距離跟手指對不上 | 父層有 transform / scale → §6 |
| hover 在觸控裝置上「卡住」 | 用了原生 hover 事件而非 Motion 的 `hover()` / `whileHover` → §6 |
| SVG 的 layout 動畫壞掉 | SVG 不支援 layout 動畫 → §7 |
| 深色模式下層級消失 | 陰影在深色底看不見 → `contrast.md` §2 |
| 動畫一半的文字讀不到 | 中間態對比不足 → `contrast.md` §7 |

---

## 1. `AnimatePresence` / exit

**exit 不觸發，三個原因：**

```jsx
// ❌ AnimatePresence 自己被卸載了,它無法控制自己的退場
{isVisible && <AnimatePresence><Component /></AnimatePresence>}

// ✅ 條件要在裡面
<AnimatePresence>{isVisible && <Component />}</AnimatePresence>
```

```jsx
// ❌ index 當 key:重排時 key 對不上項目
{items.map((item, i) => <Component key={i} />)}
// ✅ 穩定唯一 id
{items.map(item => <Component key={item.id} />)}
```

**退場元件必須是 `AnimatePresence` 的直接子代**才拿得到 `exit`。中間隔了一層非 motion 的 wrapper 就會失效。

**巢狀 AnimatePresence**：外層移除時，內層的子代預設**不會**播退場。要傳播就給內層加 `propagate`：
```jsx
<AnimatePresence propagate>…</AnimatePresence>
```

**`mode="popLayout"` 的兩個要求**：
- 自訂元件子代必須 `forwardRef` 且把 ref 傳到要 pop 的 DOM 節點
- 動畫父層要有非 `static` 的 `position`（popLayout 內部用 `position: absolute`，而任何有 transform 的祖先都會變成 offset parent）

```jsx
<motion.ul layout style={{ position: "relative" }}>
  <AnimatePresence mode="popLayout">…</AnimatePresence>
</motion.ul>
```

**`mode="sync"` 混 layout 動畫**時，外面包一層 `<LayoutGroup>`，讓 `AnimatePresence` 之外的元件也知道要重排。

---

## 2. 元件被重建

```jsx
// ❌ 每次 render 都是新元件,動畫狀態全丟
function Row() {
  const MotionCard = motion.create(Card)   // 災難
  return <MotionCard animate={…} />
}
// ✅ 提到模組層級
const MotionCard = motion.create(Card)
```

`motion.create()` 包裝的元件必須把 `ref` 傳到真正要動的 DOM 節點（React 18 用 `forwardRef`，React 19 用 `props.ref`），否則什麼都不會動。

動畫在打斷時「跳回起點」：keyframes 第一格改寫 `null`。
```jsx
animate={{ x: [null, 100, 0] }}
```

---

## 3. Layout 動畫

**沒反應：**
- 元素是 `display: inline` → 瀏覽器不對 inline 元素套 transform。改 `inline-block` / `block` / `flex`。
- 該次沒有 re-render。layout 動畫由 React render 觸發，純 CSS 改變不會觸發。
- 兩個元件互相影響版面但不同時 render → 包 `<LayoutGroup>`。

**版面改變要走 `style` / `className`，不要走 `animate`：**
```jsx
// ❌ layout 和 animate 打架
<motion.div layout animate={{ width: open ? 300 : 100 }} />
// ✅ layout 自己處理
<motion.div layout style={{ width: open ? 300 : 100 }} />
```

**內容被拉扯（scale 畸變）：**
- 直接子元素也加 `layout`，Motion 會做反向縮放補償
- 長寬比會變的元素（圖片、文字）改用 `layout="position"`
- **`borderRadius` 與 `boxShadow` 必須寫在 `style` 裡**才會被反畸變修正，寫在 CSS class 裡不會
- `border` 無法完美補償（最小 1px 限制）→ 改用「父層加 padding 當邊框」

```jsx
<motion.div layout style={{ borderRadius: 10, padding: 5, background: "#000" }}>
  <motion.div layout style={{ borderRadius: 5, background: "#fff" }} />
</motion.div>
```

**捲動容器內**：捲動容器要加 `layoutScroll`。
**`position: fixed` 內**：加 `layoutRoot`。

**視窗水平縮放時 layout 動畫被停用** —— 這是刻意的效能保護，不是 bug。

**捲軸出現造成整頁抖動：**
```css
body { overflow-y: auto; scrollbar-gutter: stable; }
```

**巢狀 layout 動畫的相對定位**：Motion 用**父層相對**計算（不像 View Transitions 用頁面絕對座標），所以子層有 `delay` 也不會被父層「拋下」。要改變錨點用 `layoutAnchor={{ x: 0.5, y: 0.5 }}`。

---

## 4. 效能

**永遠安全**：`transform`（含獨立的 `x` / `scale` / `rotate`）、`opacity`
**觸發 paint（要實測）**：`box-shadow`、`border-radius`、`background-color`、`filter`
**觸發 layout（避免）**：`width`、`height`、`top`、`left`、`margin`、`padding`、`border-width`

替代寫法：
```js
animate(el, { boxShadow: "10px 10px black" })          // ❌ paint
animate(el, { filter: "drop-shadow(10px 10px black)" })// ✅ 合成器(Chrome/FF)

animate(el, { borderRadius: "50px" })                  // ❌
animate(el, { clipPath: "inset(0 round 50px)" })       // ✅
```
大面積 `box-shadow` 動畫改用偽元素 opacity → `recipes.md` §5。

**硬體加速的意外**：Motion 的獨立 transform（`x`、`scale`）底層走 CSS 變數，**目前不會被硬體加速**。主執行緒很忙時仍可能卡。極端在意時寫完整字串：
```js
animate(".box", { transform: "translateX(100px) scale(2)" })
```
另外 Chrome 對 `%` 為單位的 transform 曾長期不加速。

**圖層提示要克制**：`will-change: transform` 每一層都佔 GPU 記憶體，只在確認有問題的元素上加。

**文字動畫**：分割文字會讓 DOM 暴增（一次性成本），但 `innerText` 逐幀更新會**持續**觸發 layout 重算。scramble 用等寬字型、typewriter 用 `contain: layout`。**per-character 的 blur 是效能陷阱** —— 小圖層放大模糊後互相重疊，GPU 成本遠高於對整塊做一次 blur。

---

## 5. 捲動

- 滾輪是離散事件，`scrollYProgress` 直接綁 style 會有階梯感 → 一律過 `useSpring`。
- `useSpring` 追蹤捲動值時加 `skipInitialAnimation: true`，避免掛載時從 0 掃過去。
- 釘住用 CSS `position: sticky`，不要用 JS 改 `top`。
- `whileInView` 沒有 `once: true` 會反覆播放；`amount` 預設 `"some"`（一個像素）通常太早，改 `0.3`。
- `useScroll` 的 `offset` 順序是 `[起點, 終點]`，字串格式為 `"<target位置> <container位置>"`，例如 `"start end"` ＝ target 的頂端碰到 container 的底端。

---

## 6. 手勢

**拖曳距離與手指對不上** → 父層有 `transform` / `scale`。任何有 transform 的祖先都會改變座標系。`MotionConfig` 的 `transformPagePoint` 可修正整頁縮放的情況。

**縮放父層裡的 layout 動畫異常** → 同上原因。

**拖曳圖片出現瀏覽器的殘影** → 給 `<img>` 加 `draggable={false}` 或 CSS `-webkit-user-drag: none`。

**觸控裝置 hover「卡住」** → 瀏覽器會為觸控模擬 hover 事件。用 `whileHover` / `hover()`（會過濾假事件），不要自己綁 `mouseenter`。

**pan / drag 在觸控上沒反應或與捲動打架** → 需要 CSS `touch-action`：
```css
.draggable-x { touch-action: pan-y; }   /* 橫向拖曳,縱向留給捲動 */
.draggable   { touch-action: none; }
```

**子元素的點擊被父層手勢吃掉**：
```jsx
<button onPointerDownCapture={e => e.stopPropagation()} />  {/* 一般 React 元件 */}
<motion.button propagate={{ tap: false }} />                 {/* motion 元件,目前僅支援 tap */}
```
motion 的手勢處理是延遲的，在 `onTapStart` 裡呼叫 `e.stopPropagation()` 來不及。

**可拖曳元件內的 tap**：指標移動超過 3px 就會自動取消 tap。

---

## 7. SVG

- **SVG 不支援 layout 動畫**（SVG 沒有 layout 系統）。改直接動屬性（`cx`、`x`、`width`…）或 `viewBox`。
- SVG `filter` 系元素（`feGaussianBlur` 等）**收不到事件**。把 `whileHover` 掛在父層 `<motion.svg>`，用 variants 驅動 filter 子元素。
- 路徑繪製用 `pathLength` / `pathSpacing` / `pathOffset`（0–1），支援 `circle` `ellipse` `line` `path` `polygon` `polyline` `rect`。

---

## 8. 常見誤用

| 寫法 | 問題 | 改成 |
|---|---|---|
| `import { motion } from "framer-motion"` | 舊套件名 | `"motion/react"` |
| `transition={{ type: "spring", duration: .3, stiffness: 200 }}` | 設了 stiffness，`duration`/`bounce` 全失效 | 二選一 |
| `spring({ duration: 0.3 })` | 直接呼叫 `spring()` 時 duration 單位是**毫秒** | `spring({ duration: 300 })` |
| `useTransform` 寫在 `.map()` 裡 | React hook 規則 | 抽成子元件，或用函式型 `useTransform(() => …)` |
| `animate` 每 render 傳新物件 | 值相同時不會重播，但物件比較成本存在 | 用 `useMemo` 或 variants |
| 動畫用 `setTimeout` 串接 | 無法取消、會漂移 | sequence 或 variants 的 `delayChildren` |
| 依賴 `onAnimationComplete` 做關鍵邏輯 | 動畫被打斷時不會觸發 | 用 state，動畫只是表現層 |
| RSC 裡 `import { motion } from "motion/react"` | 需要 client boundary | `import * as motion from "motion/react-client"` 或加 `"use client"` |

---

## 9. 交付前檢查

- [ ] 全站有 `<MotionConfig reducedMotion="user">`？視差與自動播放另外判斷了？
- [ ] 所有 `whileInView` 都有 `once: true`？
- [ ] 有沒有動到 `width` / `height` / `top` / `left`？該用 `layout` 的地方用了嗎？
- [ ] `AnimatePresence` 的 key 穩定唯一？條件在裡面？
- [ ] 退場時長是進場的 0.5–0.7 倍？
- [ ] stagger 總時長算過了（間隔 × 數量 ≤ 0.5s）？
- [ ] **深色主題看過了嗎？** 層級還在嗎？焦點環還看得見嗎？
- [ ] 在低階裝置或 CPU 降速 4× 下跑過一次？
- [ ] 分割文字有 `aria-label` 且切片 `aria-hidden`？
- [ ] 有沒有任何狀態只靠亮度或只靠動畫傳達？
