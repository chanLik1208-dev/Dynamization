# Dynamization（繁體中文）

> 這是 `SKILL.md` 的繁體中文版。英文正典在 repo 根目錄的 `SKILL.md`。
> API 參考（react / javascript / vue / doc-index）只有英文版，在 `references/`。

> 動畫的目的不是「有動」，是讓介面的**因果關係**看得見：東西從哪來、去了哪、現在能不能碰。
> 明暗的目的不是「好看」，是讓介面的**空間關係**看得見：什麼在上面、什麼是活的、現在該看哪裡。
>
> 兩者分開用都只有一半效果。「上浮」不是把東西往上移 4px，是**位移＋陰影變大變散＋表面變亮同時發生** —— 人腦才會解讀成「它靠近我了」。
> 讓人覺得「生硬」或「平」的介面，幾乎都不是曲線調得不夠漂亮，而是違反了物理直覺、或只動了一個屬性。

## 一、先選 runtime

| 情境 | 用什麼 | 匯入 |
|---|---|---|
| React / Next.js | Motion for React | `npm i motion` → `import { motion } from "motion/react"` |
| React Server Component | 同上，改路徑 | `import * as motion from "motion/react-client"` |
| Vue / Nuxt | Motion for Vue | `npm i motion-v` → `import { motion } from "motion-v"` |
| 原生 JS / Webflow / Astro | vanilla | `npm i motion` → `import { animate } from "motion"` |
| 只要 hover 變色這種單點效果 | **純 CSS**，不要裝函式庫 | — |
| 要 spring 曲線但不想裝函式庫 | 產 CSS `linear()` | 見 `i18n/zh-TW/recipes.md` §CSS spring |

**先問自己該不該用函式庫。** 單一元素、單一狀態、不需要被打斷的效果，CSS `transition` 就夠了。Motion 的價值在於：可打斷、承接速度、layout 動畫、手勢、編排、滾動連動 —— 用不到這些就別引入 18kb。

## 二、五條黃金律

寫任何動畫之前先過這五關。違反其中任何一條，動畫就會「怪」，而且怪在哪通常說不上來。

### 1. 位置與大小用彈簧，透明度與顏色用補間

這不是風格偏好，是 Motion 自己的預設邏輯（已從 `motion-dom` 原始碼驗證）：

| 動的是什麼 | Motion 預設給你 |
|---|---|
| `x` `y` `rotate` `skew` 等 transform | spring，`stiffness: 500, damping: 25`（略帶回彈） |
| `scale` 系列 | spring，`stiffness: 550, damping: 30`（臨界阻尼，**不回彈**） |
| `opacity` `color` `filter` 等其他 | tween，`ease: [0.25, 0.1, 0.35, 1]`, `duration: 0.3` |
| 三個以上 keyframes | tween，`duration: 0.8` |

理由：會佔據空間的東西（位置、大小）人腦當成**實體**，實體要有質量與慣性；透明度和顏色不是實體，它只是「顯不顯示」，加彈簧只會讓人覺得閃爍。
**推論：`scale` 放大時不要加 bounce。** 放大帶回彈 = 東西撞到玻璃，這是 Motion 對 scale 用臨界阻尼的原因。

### 2. 動畫必須可以被打斷，而且要承接速度

自然感最關鍵、也最常被忽略的一條。人在動畫跑到一半時改主意是常態。

- 用 spring：Motion 自動承接當前速度，反向時不會急停回彈。**這是 spring 相對 tween 最大的價值，不是「有彈性」。**
- 用 keyframes 時，第一格寫 `null` 當萬用格：`animate={{ x: [null, 100, 0] }}` —— 從**當前值**接續，而不是硬跳回起點。
- 不要用 `setTimeout` 串動畫。用 sequence（`animate([...])`）或 variants 的 `when` / `delayChildren`，它們可被統一取消。
- View Transitions API 不可打斷（中斷會瞬跳到終點），需要打斷就用 Motion 的 `layout`。

### 3. 進場與退場不對稱

離開的東西不值得使用者等。

```jsx
// 進場：慢一點，easeOut(先快後慢，像滑進來停住)
initial={{ opacity: 0, y: 8 }}
animate={{ opacity: 1, y: 0, transition: { duration: 0.25, ease: "easeOut" } }}
// 退場：快，easeIn(先慢後快,像加速離開)
exit={{ opacity: 0, y: 4, transition: { duration: 0.15, ease: "easeIn" } }}
```

退場約為進場的 **0.5–0.7 倍時間**。位移距離也要小於進場 —— 走的東西不需要走完全程，眼睛只需要知道「它走了」。

### 4. 時間分級：不同用途有不同的時間預算

| 級別 | 時長 | 用在哪 | 曲線 |
|---|---|---|---|
| 即時回饋 | `0.1–0.15s` | press 縮放、checkbox、focus ring | `easeOut` 或直接 spring |
| 微互動 | `0.15–0.25s` | hover、tooltip、按鈕變色 | `easeOut` |
| 元件轉場 | `0.25–0.4s` | dropdown、modal、accordion、layout | spring `visualDuration: 0.3` |
| 頁面/敘事 | `0.4–0.8s` | 頁面切換、大型 hero、多段 keyframes | spring 或 tween + stagger |
| 超過 `1s` | 幾乎一定錯了 | 只有 loading / ambient / 滾動連動可以 | — |

hover 動畫**不要超過 0.2s**：游標可能已經移走了。
移動距離越遠可以稍微久一點，但**不是線性**——距離變兩倍，時間大約只加 20–30%。

> 完整判準、spring 參數的人類語義、編排節奏、反模式清單 → `i18n/zh-TW/feel.md`

### 5. 一個事件要有多個屬性同向變化

單一屬性的變化資訊量太低。**同向的多屬性變化才會被解讀成一個物理事件。**

| 想表達 | 至少要動這些 |
|---|---|
| 上浮 / 靠近（hover 卡片） | `y` 上移 ＋ 陰影變大變散 ＋ 表面提亮 |
| 壓下 / 凹陷（press） | `scale` 縮小 ＋ 陰影收縮 ＋ 內陰影 ＋ 變暗 |
| 抬起（drag 中） | `scale` 放大 ＋ 大範圍陰影 ＋ 提高 z |
| 聚焦（modal 開啟） | 內容進場 ＋ **背景壓暗**（scrim 要比內容早到位） |
| 停用 | 專屬的低對比色 token（**不是** `opacity: 0.5`） |

亮度是狀態訊號、位移是過程，所以**亮度變化要比位移快**（約 `0.12–0.15s` vs `0.2–0.35s`）。
深色主題下陰影幾乎不可見，層級要改用「表面越高越亮」表達 —— 主題切換換的是機制，不只是色票。

> 完整的光學模型、深/淺主題 token、可動畫的明暗屬性成本、無障礙底線 → `i18n/zh-TW/contrast.md`

## 三、路由表

按你現在要做的事讀對應檔案，**不要一次全讀**：

| 你要做的事 | 讀 |
|---|---|
| 理解「怎樣才自然」、調不出想要的感覺、有人說「太生硬」 | `i18n/zh-TW/feel.md` ← **時間維度的核心** |
| 層級、陰影、elevation、深色模式、聚焦、scrim、對比 | `i18n/zh-TW/contrast.md` ← **空間維度的核心** |
| 寫 React 程式碼，查 prop / hook / 元件 | `references/react.md` |
| 寫 vanilla JS，查 `animate()` / `scroll()` / motion value | `references/javascript.md` |
| 寫 Vue，或從 React 範例改寫成 Vue | `references/vue.md` |
| 要一個現成可貼的效果（進場、modal、視差、拖曳、文字…） | `i18n/zh-TW/recipes.md` |
| 動畫沒反應、跳動、卡頓、exit 不觸發、layout 變形 | `i18n/zh-TW/pitfalls.md` |
| 需要官方原文或這裡沒收錄的冷門 API | `references/doc-index.md` ＋ 下方抓取指令 |

## 四、無障礙不是選配

任何會**位移或縮放大面積元素**的動畫，都必須處理 reduced motion。全站一行搞定：

```jsx
import { MotionConfig } from "motion/react"
<MotionConfig reducedMotion="user">{children}</MotionConfig>
```

`reducedMotion="user"` 會自動停掉 transform 與 layout 動畫，但**保留** opacity / backgroundColor —— 這正是 iOS 的做法：仍然告訴使用者「畫面換了」，只是用淡入淡出而不是滑動。
細部控制用 `useReducedMotion()`（Vue 同名）。視差、自動播放影片、無限捲動一律要判斷。

## 五、效能紅線

只有 `transform` 和 `opacity` 在所有瀏覽器都走合成器（compositor），是永遠安全的。

- ❌ 動 `width` / `height` / `top` / `left` / `margin` / `border-width` → 觸發 layout，必定掉幀
- ⚠️ `box-shadow` / `border-radius` / `background-color` → 觸發 paint，小元素可以，大面積要實測
- ✅ 需要陰影動畫改用 `filter: drop-shadow(...)`；需要圓角動畫改用 `clip-path: inset(0 round Npx)`
- ✅ 要動尺寸/位置就用 `layout` prop —— Motion 內部改用 transform 實現，這是它存在的最大理由之一
- ⚠️ Motion 的獨立 transform（`x`, `scale`）底層走 CSS variable，**不會**硬體加速。極端在意時寫成 `transform: "translateX(100px) scale(2)"`

## 六、抓官方最新原文

文件站支援 markdown 內容協商，隨時可取得權威原文（比本包更新）：

```bash
curl -sL -H "Accept: text/markdown" https://motion.dev/docs/<slug>
# 例：https://motion.dev/docs/react-transitions
```

也可用 `scripts/fetch-doc.sh react-transitions`。全部 slug 在 `references/doc-index.md`。
**本包與官方文件衝突時，以官方原文為準**，但注意官方文件頁的 spring `stiffness` 預設值標示為 `1` 是**錯的**（原始碼實際為 `100`）。
