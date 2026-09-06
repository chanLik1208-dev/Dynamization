# feel.md — 自然感的判準

這份文件不講 API，講「為什麼這個動畫看起來假」。
排序大致依照造成不自然的嚴重程度：**前面的問題修好，後面的細節才有意義。**

---

## 0. 一句話原則

> 動畫要讓人**不需要思考**就知道發生了什麼。
> 使用者不該注意到動畫本身；他們該注意到的是「東西是從那裡來的」。

任何讓人停下來「欣賞」的動畫，在產品裡通常都太長了。

---

## 1. Motion 的預設值就是一套已調校的品味

不確定要用什麼參數時，**什麼都不寫**。Motion 的預設會按「動的是什麼值」自動選擇，這套邏輯本身就是答案。

以下數值取自 `motion-dom` 原始碼的 `getDefaultTransition()`（不是文件頁 — 文件頁的 spring 預設值有誤）：

```js
// 三個以上 keyframes
{ type: "keyframes", duration: 0.8 }

// transform 類，但不含 scale：x / y / z / rotate* / skew*
{ type: "spring", stiffness: 500, damping: 25, restSpeed: 10 }   // 欠阻尼，會些微過衝

// scale / scaleX / scaleY
{ type: "spring", stiffness: 550, damping: 30, restSpeed: 10 }   // 臨界阻尼，不過衝
// 特例：目標值為 0 時 damping = 2*sqrt(550) ≈ 46.9（更硬的煞停，避免縮到 0 時抖動）

// 其他所有值：opacity / color / backgroundColor / filter / width ...
{ type: "keyframes", ease: [0.25, 0.1, 0.35, 1], duration: 0.3 }
// 這條曲線是瀏覽器預設 ease 的「淺一點」版本 —— 起步不那麼陡，收尾一樣柔
```

**可以直接讀出來的三條結論：**

1. 佔空間的東西（位置、大小）＝彈簧；不佔空間的東西（透明度、顏色）＝補間。
2. 放大縮小**不該回彈**。位移可以。
3. 預設時長只有 `0.3s`。你寫的動畫如果比這長，要說得出理由。

`spring()` 函式本身的預設（`springDefaults`）：
`stiffness: 100, damping: 10, mass: 1, velocity: 0, duration: 800ms, bounce: 0.3, visualDuration: 0.3s`

---

## 2. spring 的真正價值是「承接速度」，不是「有彈性」

多數人以為 spring ＝ 會 Q 彈。錯。spring 在 Motion 裡最重要的性質是：**動畫被打斷時，它會從當前的位置與當前的速度繼續**，而不是急停再重來。

這是「感覺像實體」與「感覺像投影片」的分界線。

```jsx
// 使用者快速連點切換 → tween 會每次硬重啟，看起來像卡頓
<motion.div animate={{ x: open ? 200 : 0 }} transition={{ duration: 0.3 }} />

// spring 承接速度，連點時像推一個有慣性的東西
<motion.div
  animate={{ x: open ? 200 : 0 }}
  transition={{ type: "spring", visualDuration: 0.3, bounce: 0.2 }}
/>
```

**判準：這個動畫由使用者的直接動作觸發嗎？**

| 觸發來源 | 用什麼 | 為什麼 |
|---|---|---|
| 拖曳、滑動、手勢、游標跟隨 | **spring**（必須） | 有真實速度要承接 |
| 點擊 / hover 造成的位移或縮放 | **spring** | 可能被連續打斷 |
| 開關造成的 layout 改變 | **spring** | 同上 |
| 元素進場 / 退場的淡入淡出 | **tween** | 沒有速度可承接，時間可控更重要 |
| 要和其他東西對齊時間（stagger、sequence、影片） | **tween** | spring 沒有可靠的結束時間 |
| 滾動連動 | 直接綁值，外加 `useSpring` 平滑 | 見 §7 |

---

## 3. 調 spring 用 `bounce` + `visualDuration`，不要碰 `stiffness` / `damping`

`stiffness: 400, damping: 32, mass: 1.2` 這種寫法沒有人能在腦中想像出結果，只能瞎試。改用有人類語義的兩個參數：

```jsx
transition={{
  type: "spring",
  visualDuration: 0.3,  // 秒。看起來「到位」需要多久（不含尾巴的回彈）
  bounce: 0.2,          // 0 = 不回彈，1 = 極彈
}}
```

`visualDuration` 的定義就是為此存在：**大部分位移在這個時間內完成，回彈的尾巴在這之後**。所以它可以直接跟 tween 的 `duration` 對齊時間，而 `duration` + spring 不行。

**bounce 值的語義：**

| bounce | 感覺 | 用在哪 |
|---|---|---|
| `0` | 乾脆、專業、有重量 | 企業介面、資料表格、面板開合、**任何 scale** |
| `0.1 – 0.2` | 有生命但克制 | **大多數情況的正確答案**：按鈕、卡片、選單 |
| `0.3 – 0.4` | 活潑、玩具感 | 消費型 app、遊戲化、成功回饋 |
| `> 0.5` | 誇張 | 只有刻意搞笑或必須搶注意力時 |

**兩條硬規則：**
- `scale` 一律 `bounce: 0`。放大帶回彈＝撞到玻璃。
- 同一個畫面裡的 bounce 值要一致。混用會讓介面看起來是拼湊的。

> `bounce` / `duration` 一旦設了 `stiffness` / `damping` / `mass` 任一個就會**全部失效**。不要混寫。

---

## 4. 因果：東西要從它來的地方來

這條違反了，再漂亮的曲線也救不回來。

- Dropdown 從**觸發它的按鈕**展開，不是從畫面中央淡入。`transformOrigin` 要指向按鈕。
- Modal 從被點的卡片放大 → 用 `layoutId` 做共享元素，不要淡入。
- 側邊欄從**它所在的那一邊**滑入，不是從下面。
- 刪除一個 list item，其他項目要**填補它留下的空間**（`layout` prop），不是瞬間跳位。
- 通知從它會停留的角落進場。

```jsx
// ❌ 憑空出現
<motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} />

// ✅ 從按鈕長出來
<motion.div
  style={{ transformOrigin: "top left" }}
  initial={{ opacity: 0, scale: 0.95, y: -4 }}
  animate={{ opacity: 1, scale: 1, y: 0 }}
/>

// ✅✅ 真的從那個元素變過去
<motion.button layoutId="card-3" />
{open && <motion.div layoutId="card-3" />}
```

**位移距離的尺度感：** 微互動 `4–12px`，元件轉場 `16–40px`，全螢幕才用 `%`。
從 `y: 100` 淡入是最常見的錯誤 —— 那個距離對一個 tooltip 來說是「從另一個房間飛過來」。

---

## 5. 進退場不對稱

| | 進場 | 退場 |
|---|---|---|
| 時長 | `0.2 – 0.35s` | 進場的 **0.5 – 0.7 倍** |
| 曲線 | `easeOut` / spring | `easeIn` |
| 位移 | 完整距離 | 進場的 **1/2 或更少** |
| scale 起點 | `0.95`（不是 `0`） | `0.98`（幾乎不縮） |

理由：進場時使用者要「接住」新資訊，需要時間定位；退場時那個東西已經與他無關，讓他等於是浪費他的時間。

`easeOut` 進、`easeIn` 出，合起來整段體驗就是一個 `easeInOut` —— 這正是官方對 `AnimatePresence mode="wait"` 的建議搭配。

不要從 `scale: 0` 進場：那是「從無到有」，但 UI 元素幾乎都是「從別處來」。`0.95` 就足以表達出現。

---

## 6. 編排：stagger 是節奏，不是裝飾

同時出現的十個東西，眼睛只能當成「一坨」。錯開之後才有先後、才有指向。

```jsx
const list = {
  show: { transition: { delayChildren: stagger(0.04) } },
  hide: { transition: { delayChildren: stagger(0.02, { from: "last" }) } },
}
```

**間隔的選擇：**

| 元素數 | 間隔 | 總時長上限 |
|---|---|---|
| 3–6 個（選單、卡片列） | `0.04 – 0.06s` | ≤ 0.35s |
| 7–15 個（清單） | `0.02 – 0.04s` | ≤ 0.5s |
| 文字逐字 | `0.02 – 0.03s` | 看字數，超過 1s 就改逐詞 |
| > 20 個 | 別 stagger 個別元素 | 分組，或整體淡入 |

**總時長是硬上限。** `stagger(0.1)` 配 20 個項目 ＝ 2 秒，最後一個到位時使用者已經在做別的事了。算一下再寫。

**方向要有意義：**
- `from: "first"`（預設）＝ 由上而下，符合閱讀順序，安全牌
- `from: "last"` ＝ 收合時用，讓它「捲回去」
- `from: "center"` ＝ 向外開展，有儀式感，用在 hero
- `from: <index>` ＝ 從使用者剛點的那一項開始擴散 ← **最強的因果表達**

`when: "beforeChildren"` / `"afterChildren"`：容器要先開好再放內容進來（進場），內容要先收完容器才關（退場）。

---

## 7. 滾動：連動要平滑，觸發要一次

**scroll-triggered（進視窗才播）**
```jsx
<motion.div
  initial={{ opacity: 0, y: 12 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.3 }}
/>
```
`once: true` **幾乎永遠是對的**。上下捲動時反覆播放的動畫會讓人暈，而且第二次播放毫無資訊量。
`amount: 0.3` 表示露出三成才觸發 —— 預設的 `"some"`（一個像素）太早，元素還在畫面外緣就播完了。

**scroll-linked（值直接綁滾動）**
```jsx
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] })
const smooth = useSpring(scrollYProgress, {
  stiffness: 100, damping: 30, restDelta: 0.001, skipInitialAnimation: true,
})
```
滾輪是離散事件，直接綁會有階梯感。**過一層 `useSpring` 是必要的，不是加分項。**
`skipInitialAnimation: true` 避免掛載時從 0 掃到當前位置。

**視差幅度**：背景層位移量取前景的 `0.3–0.5` 倍就夠。超過就會變成「背景在漂」而不是「有景深」。
視差是 reduced motion 的頭號取消對象。

---

## 8. 手勢回饋要在 100ms 內開始

觸控與點擊的回饋是**確認訊號**，不是動畫。

```jsx
<motion.button
  whileHover={{ scale: 1.03 }}                 // 極輕微。1.1 是海報，不是按鈕
  whileTap={{ scale: 0.97 }}                   // 按下去要縮，不是放大
  transition={{ type: "spring", visualDuration: 0.15, bounce: 0 }}
/>
```

- **按下＝變小**。手指壓下去東西應該凹陷。放大是錯的物理。
- hover 的 scale 上限 `1.05`；超過會讓相鄰元素看起來被擠開。
- 大元素（卡片、面板）的 hover scale 要更小（`1.01–1.02`），因為實際位移量 ＝ scale × 尺寸，同樣比例在大元素上是大位移。
- 拖曳一定要 `whileDrag`（通常 `scale: 1.03` ＋ 陰影加深），讓人知道「抓起來了」。
- `dragElastic`（預設 `0.5`）表達邊界：拉到底還能拉一點但會回彈，比硬牆自然。
- 有 `whileTap` 的元素**自動支援鍵盤 Enter**（`onTapStart` → `onTap`），別自己重造。

---

## 9. 等待與不確定

- **< 1 秒**：不要放 spinner。閃一下的 loading 比直接等更煩。
- **1–5 秒**：skeleton。微光掃過要慢（`1.5–2s` 一輪）且低對比 —— 它是「還在」的訊號，不該搶注意力。
- **> 5 秒 / 有進度**：進度條，且**永不倒退**。
- 樂觀更新時，把新項目直接以最終樣式插入（可略降透明度），失敗才動畫地退回。**讓成功路徑無感是最好的動畫。**

`repeat: Infinity` 的環境動畫（呼吸、脈動、微光）：幅度要小到「看得到但看不清」，週期 `≥ 1.5s`，且必須被 reduced motion 關掉。

---

## 10. 反模式清單

| 反模式 | 為什麼錯 | 改成 |
|---|---|---|
| 什麼都 `duration: 0.5` | 沒有分級，全部一樣重要＝全部不重要 | 照 SKILL.md 的時間分級表 |
| 從 `y: 100` / `scale: 0` 淡入 | 距離過大，像從別的畫面飛來 | `y: 8–16`、`scale: 0.95` |
| `scale` 加 bounce | 撞玻璃感 | `bounce: 0` |
| `ease: "linear"` 做位移 | 現實中沒有東西等速啟停 | `easeOut` 或 spring；`linear` 只給滾動連動與無限旋轉 |
| 退場和進場一樣長 | 讓人等一個已經無關的東西 | 退場砍到 0.5–0.7 倍 |
| `whileInView` 沒有 `once` | 來回捲動反覆播放 | `viewport={{ once: true }}` |
| stagger 沒算總時長 | 最後一個要等兩秒 | 間隔 × 數量 ≤ 0.5s |
| 動 `width` / `height` / `top` | 觸發 layout，掉幀 | `layout` prop 或 transform |
| 用 `setTimeout` 串動畫 | 無法取消、無法打斷、會漂移 | sequence 或 variants 編排 |
| 只在淺色主題測過 | 陰影在深色底上完全看不見 | 見 `contrast.md` |
| 沒處理 reduced motion | 讓部分使用者感到暈眩 | `<MotionConfig reducedMotion="user">` |
| 同頁面混用 bounce 0 / 0.4 | 介面像拼湊的 | 全站定一組 token |

---

## 11. 建一組 token，不要每次現調

自然感的另一半是**一致性**。同一個產品裡，同樣意義的動作應該用同樣的時間與曲線。

```js
// motion.tokens.js
export const T = {
  instant: { duration: 0.12, ease: "easeOut" },                   // 回饋
  micro:   { duration: 0.2,  ease: "easeOut" },                   // hover / tooltip
  enter:   { type: "spring", visualDuration: 0.3,  bounce: 0.15 },// 元件進場
  exit:    { duration: 0.15, ease: "easeIn" },                    // 元件退場
  layout:  { type: "spring", visualDuration: 0.35, bounce: 0 },   // 版面重排
  page:    { type: "spring", visualDuration: 0.5,  bounce: 0.1 }, // 頁面轉場
  stagger: 0.04,
}
```

全站預設一次設定：
```jsx
<MotionConfig transition={T.enter} reducedMotion="user">
```
之後只有需要偏離時才在單一元件覆寫 —— 而且要說得出偏離的理由。
