# contrast.md — 明暗對比的表達力

動態是**時間**維度的語言：東西從哪來、往哪去。
明暗是**空間**維度的語言：什麼在上面、什麼是活的、現在該看哪裡。

兩者分開用都只有一半效果。**「上浮」不是把東西往上移 8px，是往上移 4px＋陰影變大變散＋表面變亮 —— 三件事同時發生，人腦才會解讀成「它靠近我了」。** 這份文件講怎麼把明暗接進動態裡。

---

## 1. 光的心智模型：光從上方來

人類視覺系統預設「光源在上」。所有明暗表達都建立在這一條上，違反了就會看起來詭異或廉價。

| 想表達 | 明暗配置 |
|---|---|
| **凸起**（按鈕、卡片、浮層） | 上緣微亮（rim light）＋下方投影 |
| **凹陷**（輸入框、槽、被按下） | 上緣內陰影＋下緣微亮 |
| **平貼**（背景、分隔線） | 無投影，只用色階差 |
| **懸浮很高**（modal、drag 中） | 大範圍、低不透明度、模糊的投影 |

高度越高 → 陰影**越大、越散、越淡**，而不是越黑。
新手的錯誤是把 `box-shadow` 的黑度加深來表達「更高」，結果看起來是「更髒」。正確做法是加大 `blur` 與 `y-offset`，同時**降低** alpha。

```css
--shadow-1: 0 1px 2px  rgb(0 0 0 / .08);                              /* 貼著 */
--shadow-2: 0 2px 6px  rgb(0 0 0 / .07), 0 1px 2px rgb(0 0 0 / .05);  /* 卡片 */
--shadow-3: 0 8px 20px rgb(0 0 0 / .06), 0 2px 6px rgb(0 0 0 / .05);  /* 浮層 */
--shadow-4: 0 20px 48px rgb(0 0 0 / .05), 0 4px 12px rgb(0 0 0 / .04);/* modal */
```

雙層陰影是關鍵：一層小而緊（接觸陰影，說明它有厚度），一層大而散（環境遮蔽，說明它離得多遠）。只有一層的陰影永遠看起來像貼紙。

---

## 2. 深色主題的層級機制完全不同 —— 這是最常被做錯的一件事

**在深色底上，陰影是看不見的。** 黑影投在近黑的背景上沒有對比可言。
把淺色主題的陰影直接搬到深色主題，結果是「所有層級都消失了，畫面變成一片平的」。

深色主題用**相反的機制表達高度：越高的表面越亮。**（物理直覺：越靠近光源的表面接收到越多光。）

| 層級 | 淺色主題 | 深色主題 |
|---|---|---|
| 背景 | `#FFFFFF` | `#0E0E10` |
| 表面 / 卡片 | `#FFFFFF` ＋ shadow-2 | `#17171A`（提亮 ~5%） |
| 浮層 / dropdown | `#FFFFFF` ＋ shadow-3 | `#1F1F23`（提亮 ~8%） |
| Modal | `#FFFFFF` ＋ shadow-4 | `#26262B`（提亮 ~12%） |

**所以主題切換不是換色票而已，是換「表達層級的機制」。** 一組正確的 token 應該讓兩件事同時變：

```css
:root {
  --surface:   #ffffff;
  --elevated:  #ffffff;
  --shadow-e2: 0 2px 6px rgb(0 0 0 / .07), 0 1px 2px rgb(0 0 0 / .05);
  --rim:       inset 0 1px 0 rgb(255 255 255 / .6);   /* 上緣亮邊 */
}
:root:not([data-theme="light"]) {
  @media (prefers-color-scheme: dark) {
    --surface:   #0e0e10;
    --elevated:  #1f1f23;                              /* 靠提亮表達高度 */
    --shadow-e2: 0 2px 8px rgb(0 0 0 / .5);            /* 陰影仍在，但只負責「錨定」不負責層級 */
    --rim:       inset 0 1px 0 rgb(255 255 255 / .07); /* 亮邊要弱很多 */
  }
}
[data-theme="dark"] { /* 同上，讓手動切換也贏 */ }
```

深色主題還有三條實務規則：

- **不要用純黑 `#000`。** OLED 上純黑與內容的邊界會有拖影感，且純黑上的白字對比過強會刺眼。`#0E–#14` 區間比較舒服。
- **不要用純白 `#FFF` 當內文色。** 降到 `#E8E8EA` 左右，長文閱讀負擔小很多。
- **飽和色要降飽和、提亮度。** 淺色主題用的品牌色搬到深色底上通常會「發螢光」。

---

## 3. 對比的三個用途，不要混用

| 用途 | 手法 | 不要用 |
|---|---|---|
| **層級**（誰在上面） | 表面亮度 ＋ 陰影 | 邊框（邊框表達的是「分區」不是「高度」） |
| **聚焦**（現在該看哪） | 壓暗其他一切（scrim / dim） | 把目標變得更亮（會逐步軍備競賽，最後全部都亮） |
| **狀態**（活的 / 停用 / 選中） | 明確的顏色 token | 只調 `opacity`（見下） |

**聚焦要靠「壓暗周圍」而不是「提亮目標」。** 一個畫面裡能被提亮的東西有限，提亮法很快就會失效；壓暗法永遠有效，因為對比是相對的。

**停用狀態不要只用 `opacity: 0.5`。** 半透明的元素會透出背景，在不同背景上呈現不同顏色，而且會讓文字對比度掉到不可讀。用專屬的 `--text-disabled` 色 token。

---

## 4. 把明暗接進動態：組合表達

這是「強化表達感」的實際做法 —— 單一屬性的變化資訊量太低，**同向的多屬性變化才會被解讀成一個物理事件**。

### 上浮（hover 卡片）

```jsx
<motion.article
  initial={false}
  whileHover={{ y: -4, scale: 1.01 }}
  transition={{ type: "spring", visualDuration: 0.2, bounce: 0 }}
  className="card"     // CSS 負責陰影與亮度的過場
/>
```
```css
.card {
  background: var(--surface);
  box-shadow: var(--shadow-2);
  transition: box-shadow .2s ease-out, background-color .2s ease-out;
}
.card:hover {
  box-shadow: var(--shadow-3);          /* 更大更散,不是更黑 */
  background: var(--surface-hover);     /* 淺色主題:幾乎不變 / 深色主題:提亮 */
}
```
位移交給 Motion（要可打斷、要 spring），明暗交給 CSS（純過場、不需要打斷邏輯）。這個分工在多數情況下最省事。

### 按下（凹陷）

```jsx
whileTap={{ scale: 0.97 }}
```
```css
.btn:active {
  box-shadow: var(--shadow-1), inset 0 1px 2px rgb(0 0 0 / .12);  /* 陰影收縮 + 內陰影 */
  filter: brightness(0.96);                                        /* 同時變暗 */
}
```
**縮小＋變暗＋陰影收縮** 三件事一起 ＝ 「壓進去了」。只做縮小是「變小了」，語意完全不同。

### 拖曳中（抬起）

```jsx
whileDrag={{ scale: 1.04, boxShadow: "0 24px 48px rgb(0 0 0 / .18)" }}
```
拖曳是唯一適合誇張陰影的場合 —— 它必須明顯脫離平面，否則使用者不確定自己抓到了沒。

### Modal 開啟（聚焦）

背景壓暗與內容進場要**同時開始，但背景先到位**：

```jsx
<AnimatePresence>
  {open && (
    <>
      <motion.div className="scrim"
        initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
        transition={{ duration: 0.2, ease: "easeOut" }} />
      <motion.div className="dialog"
        initial={{ opacity: 0, scale: 0.96, y: 8 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.98, y: 4 }}
        transition={{ type: "spring", visualDuration: 0.28, bounce: 0.1 }} />
    </>
  )}
</AnimatePresence>
```
```css
.scrim { background: rgb(0 0 0 / .45); backdrop-filter: blur(2px); }
```
scrim 的不透明度：淺色主題 `0.4–0.5`；深色主題**要更低**（`0.5–0.6` 的黑疊在近黑背景上沒有效果，改為疊更高不透明度或改用提亮 dialog 本身來拉開對比）。

`backdrop-filter: blur()` 很貴（整層重繪）。小面積可以，全螢幕要實測；低階裝置上建議只留純色 scrim。

---

## 5. 明暗變化的時間比位移短

亮度是**狀態訊號**，位移是**過程**。狀態該立刻確認，過程可以慢慢走。

| 變化 | 建議時長 |
|---|---|
| `filter: brightness` / 顏色切換 | `0.1 – 0.15s` |
| `box-shadow` 層級變化 | `0.15 – 0.2s` |
| scrim 淡入 | `0.15 – 0.2s`（比內容早到位） |
| 同時發生的位移 | `0.2 – 0.35s` |

明暗如果跟位移一樣慢，會有「顏色在追東西」的脫節感。**讓亮度先到，位置後到。**

---

## 6. 效能：哪些明暗屬性動得起

| 屬性 | 成本 | 建議 |
|---|---|---|
| `opacity` | ✅ 合成器 | 永遠安全 |
| `filter: brightness/drop-shadow` | ✅ Chrome/Firefox 走合成器 | 首選的亮度動畫手段 |
| `background-color` | ⚠️ paint，Chrome 正在加入合成器支援 | 小面積可以，全螢幕要測 |
| `box-shadow` | ⚠️ paint，且成本隨模糊半徑與面積上升 | 見下方替代法 |
| `backdrop-filter` | ❌ 很貴 | 小面積、或不動畫（直接切） |

**box-shadow 動畫的標準替代法** —— 預先疊一層帶陰影的偽元素，只動它的 `opacity`：

```css
.card { position: relative; box-shadow: var(--shadow-2); }
.card::after {
  content: ""; position: absolute; inset: 0; border-radius: inherit;
  box-shadow: var(--shadow-4);
  opacity: 0; transition: opacity .2s ease-out;
  pointer-events: none;
}
.card:hover::after { opacity: 1; }
```
陰影本身不重繪，只有一層 alpha 在變 —— 這條在長清單（幾十張卡片同時 hover 過去）上差別非常明顯。

---

## 7. 無障礙的硬底線

明暗是表達手段，但**不能是唯一的資訊來源**，而且有不可跨越的數值下限。

- 內文與背景的對比度 **≥ 4.5:1**；大字（18.66px bold 或 24px 以上）與 UI 元件邊界 **≥ 3:1**（WCAG 2.2 AA）。
- **不要只靠亮度傳達狀態。** 「選中的那個比較亮」對低視力與色覺差異使用者是不存在的訊號 —— 一定要同時有形狀、圖示、邊框或文字。
- 焦點指示器（`:focus-visible`）必須與周圍達到 **3:1**，且**不能只用亮度**變化 —— 深色主題常見的失敗是焦點環用了淡灰，在深色底上完全消失。焦點環在兩個主題都要各自驗一次。
- 動畫過程中的中間狀態也要可讀。淡入到一半的文字如果對比只有 2:1，那段時間對部分使用者就是空白。**進場的 opacity 起點不要低於 `0`（直接 0 反而好），但不要用 `0.3` 這種「半可讀」的停留狀態當常態。**
- reduced motion 下**保留**明暗變化。這正是它有價值的地方：關掉位移與縮放後，亮度與顏色仍能表達「狀態變了」，而且不會誘發暈眩。這也是 `MotionConfig reducedMotion="user"` 的行為（停 transform / layout，留 opacity / color）。

---

## 8. 檢查清單

寫完任何有層級或狀態的介面，過一遍：

- [ ] 在**深色主題**下看過了嗎？陰影還看得見層級嗎？（多半看不見 → 改用表面提亮）
- [ ] 陰影是不是雙層（緊＋散）？只有一層會像貼紙
- [ ] 「更高」是用更大更散的陰影表達，不是更黑？
- [ ] hover / press 是不是**位移＋明暗一起變**？只有一個的話表達力減半
- [ ] 亮度變化是不是比位移快？
- [ ] 停用狀態是專屬色 token，不是 `opacity: 0.5`？
- [ ] 焦點環在兩個主題都達到 3:1？
- [ ] 有沒有任何狀態**只**靠亮度區分？
- [ ] 長清單裡的 hover 陰影是不是走 `::after` opacity 而非直接動 `box-shadow`？
- [ ] `backdrop-filter` 的面積可控嗎？
