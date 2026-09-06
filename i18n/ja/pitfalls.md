# pitfalls.md — 症状 → 原因 → 対処

まず症状で引き、それから該当の節を読んでください。

| 症状 | 最も可能性の高い原因 |
|---|---|
| 退場アニメーションがまったく出ない | `AnimatePresence` 自身が外れた、または子の `key` が不安定 → §1 |
| 毎回最初から再生し直される | コンポーネントが作り直されている（key が変わった / render 内の `motion.create`）→ §2 |
| layout アニメーションが反応しない | 要素が `display: inline`、または再レンダリングが起きていない → §3 |
| layout アニメーション中に内容が歪む | 子に `layout` が無い、または角丸／影が `style` に無い → §3 |
| スクロール中にページ全体が揺れる | スクロールバーの出現が layout アニメーションを誘発 → §3 |
| コマ落ち、カクつき | レイアウトを誘発するプロパティ、または広範囲のペイント → §4 |
| スクロール連動が階段状になる | `useSpring` を通していない → §5 |
| ドラッグの距離が指と合わない | 祖先に transform / scale がある → §6 |
| タッチ端末で hover が「固まる」 | Motion の `hover()` / `whileHover` ではなくネイティブの hover を使っている → §6 |
| SVG の layout アニメーションが壊れる | SVG は layout アニメーション非対応 → §7 |
| ダークモードで階層が消える | 暗い面では影が見えない → `i18n/ja/contrast.md` §2 |
| アニメーション途中の文字が読めない | 中間状態のコントラスト不足 → `i18n/ja/contrast.md` §7 |

---

## 1. `AnimatePresence` と退場

**退場が出ない 3 つの理由：**

```jsx
// ❌ AnimatePresence 自身がアンマウントされ、自分の退場を制御できない
{isVisible && <AnimatePresence><Component /></AnimatePresence>}

// ✅ 条件は内側に置く
<AnimatePresence>{isVisible && <Component />}</AnimatePresence>
```

```jsx
// ❌ index を key に：並べ替えで項目と key の対応が壊れる
{items.map((item, i) => <Component key={i} />)}
// ✅ 安定した一意の id
{items.map(item => <Component key={item.id} />)}
```

**退場するコンポーネントは `AnimatePresence` の直接の子**でなければ `exit` を受け取れません。
間に motion でないラッパーが 1 枚入るだけで効かなくなります。

**入れ子の `AnimatePresence`**：外側が外れたとき、内側の子は既定では退場しません。
内側に `propagate` を付けます。
```jsx
<AnimatePresence propagate>…</AnimatePresence>
```

**`mode="popLayout"` の 2 つの要件：**
- カスタムコンポーネントの子は `forwardRef` で、pop する DOM ノードに ref を渡すこと
- アニメーションする親は `static` 以外の `position` を持つこと。popLayout は内部で
  `position: absolute` を使い、transform を持つ祖先はオフセット親になってしまいます

```jsx
<motion.ul layout style={{ position: "relative" }}>
  <AnimatePresence mode="popLayout">…</AnimatePresence>
</motion.ul>
```

**`mode="sync"` と layout アニメーションの併用**：グループを `<LayoutGroup>` で包み、
`AnimatePresence` の外側のコンポーネントにも再レイアウトを知らせます。

---

## 2. コンポーネントが作り直されている

```jsx
// ❌ 毎レンダリングで新しいコンポーネント。アニメーションの状態が全部消える
function Row() {
  const MotionCard = motion.create(Card)   // 破滅
  return <MotionCard animate={…} />
}
// ✅ モジュールのトップレベルへ
const MotionCard = motion.create(Card)
```

`motion.create()` で包んだコンポーネントは、実際に動く DOM ノードへ `ref` を渡す必要があります
（React 18 は `forwardRef`、React 19 は `props.ref`）。渡さないと何も動きません。

中断時にアニメーションが始点へ戻る場合は、先頭のキーフレームを `null` にします。
```jsx
animate={{ x: [null, 100, 0] }}
```

---

## 3. layout アニメーション

**反応しない：**
- 要素が `display: inline` —— ブラウザは inline ボックスに transform を適用しません。
  `inline-block` / `block` / `flex` にします。
- 再レンダリングが起きていない。layout アニメーションは React のレンダリングで起動するので、
  純粋な CSS の変更では起動しません。
- 2 つのコンポーネントが互いのレイアウトに影響するが別々にレンダリングされる → `<LayoutGroup>` で包む。

**レイアウトの変更は `style` / `className` で行い、`animate` では行わない：**
```jsx
// ❌ layout と animate が喧嘩する
<motion.div layout animate={{ width: open ? 300 : 100 }} />
// ✅ layout に任せる
<motion.div layout style={{ width: open ? 300 : 100 }} />
```

**内容が引き伸ばされる（scale による歪み）：**
- 直接の子にも `layout` を付ける。Motion が逆スケールで補正します
- 縦横比が変わる要素（画像、文字）は `layout="position"` に
- **`borderRadius` と `boxShadow` は `style` に書くこと。** CSS クラスでは補正されません
- `border` は完全には補正できません（1px の下限）→ padding を持つ親を枠線代わりにします

```jsx
<motion.div layout style={{ borderRadius: 10, padding: 5, background: "#000" }}>
  <motion.div layout style={{ borderRadius: 5, background: "#fff" }} />
</motion.div>
```

**スクロールコンテナの内側**：コンテナに `layoutScroll` を付けます。
**`position: fixed` の内側**：`layoutRoot` を付けます。

**ウィンドウの横方向リサイズ中は layout アニメーションが無効になります** ——
これは意図的な性能保護であって不具合ではありません。

**スクロールバーの出現でページが揺れる：**
```css
body { overflow-y: auto; scrollbar-gutter: stable; }
```

**入れ子の layout アニメーションにおける相対位置**：Motion は**親相対**で計算します
（ページ絶対座標を使う View Transitions とは異なります）。したがって `delay` を持つ子が
親に置き去りにされることはありません。アンカーは `layoutAnchor={{ x: 0.5, y: 0.5 }}` で変えられます。

---

## 4. パフォーマンス

**常に安全**：`transform`（独立した `x` / `scale` / `rotate` を含む）、`opacity`
**ペイントを誘発（実測すること）**：`box-shadow`、`border-radius`、`background-color`、`filter`
**レイアウトを誘発（避ける）**：`width`、`height`、`top`、`left`、`margin`、`padding`、`border-width`

置き換え：
```js
animate(el, { boxShadow: "10px 10px black" })          // ❌ ペイント
animate(el, { filter: "drop-shadow(10px 10px black)" })// ✅ コンポジタ（Chrome/FF）

animate(el, { borderRadius: "50px" })                  // ❌
animate(el, { clipPath: "inset(0 round 50px)" })       // ✅
```
広い面積の影のアニメーションは擬似要素の opacity へ → `i18n/ja/recipes.md` §5。

**ハードウェアアクセラレーションの落とし穴**：Motion の独立 transform（`x`、`scale`）は
CSS 変数で実装されており、現時点では**ハードウェアアクセラレーションされません**。
メインスレッドが忙しいとカクつきます。本当に重要な場面では完全な文字列を書いてください：
```js
animate(".box", { transform: "translateX(100px) scale(2)" })
```
また Chrome は長い間 `%` 単位の transform を加速しませんでした。

**レイヤーのヒントは控えめに**：`will-change: transform` は 1 枚ごとに GPU メモリを消費します。
実測して問題があった要素にだけ付けてください。

**テキストアニメーション**：分割は DOM を膨らませますが（一度きりのコスト）、
毎フレーム `innerText` を更新するのは**継続的に**レイアウト再計算を誘発します。
スクランブルには等幅フォント、タイプライターには `contain: layout` を。
**一文字ごとの blur は性能の罠です** —— 小さなレイヤーがぼかしで拡大されて重なり合い、
ブロック全体に 1 回 blur をかけるより遥かに高くつきます。

---

## 5. スクロール

- スクロール入力は離散的なので、`scrollYProgress` を直接 style に束縛すると階段状になります。
  必ず `useSpring` を通してください。
- スクロール値をスプリングで追うときは `skipInitialAnimation: true` を付け、
  マウント時に 0 から走査するのを防ぎます。
- 固定は CSS の `position: sticky` で。JS で `top` を書き換えないこと。
- `once: true` の無い `whileInView` は繰り返し再生されます。既定の `amount: "some"`（1 ピクセル）は
  たいてい早すぎるので `0.3` に。
- `useScroll` の `offset` は `[開始, 終了]` で、各要素は `"<target の位置> <container の位置>"` の形式です。
  `"start end"` は*target の上端が container の下端に接する*瞬間を意味します。

---

## 6. ジェスチャー

**ドラッグ距離がポインタと合わない** → 祖先に transform / scale があります。
transform を持つ祖先は座標系を変えます。ページ全体のズームは `MotionConfig` の
`transformPagePoint` で補正できます。

**スケールされた親の内側で layout アニメーションがおかしい** → 同じ原因です。

**画像をドラッグするとブラウザのゴースト画像が出る** → `draggable={false}` か
CSS の `-webkit-user-drag: none` を付けます。

**タッチ端末で hover が「固まる」** → ブラウザがタッチ用に hover イベントを疑似生成します。
偽イベントを除去する `whileHover` / `hover()` を使い、自分で `mouseenter` を束縛しないこと。

**タッチで pan / drag が反応しない、スクロールと喧嘩する** → CSS の `touch-action` が必要です：
```css
.draggable-x { touch-action: pan-y; }   /* 横方向をドラッグ、縦はスクロールに残す */
.draggable   { touch-action: none; }
```

**子のクリックが親のジェスチャーに食われる**：
```jsx
<button onPointerDownCapture={e => e.stopPropagation()} />  {/* 通常の React コンポーネント */}
<motion.button propagate={{ tap: false }} />                 {/* motion コンポーネント、現状 tap のみ */}
```
Motion のジェスチャー処理は遅延実行なので、`onTapStart` の中で `e.stopPropagation()` を呼んでも
間に合いません。

**ドラッグ可能な要素の内側の tap** は、ポインタが 3px を超えて動いた時点で自動的にキャンセルされます。

---

## 7. SVG

- **SVG は layout アニメーションに対応していません**（SVG にはレイアウトシステムがありません）。
  属性（`cx`、`x`、`width`…）や `viewBox` を直接動かしてください。
- SVG の `filter` 系要素（`feGaussianBlur` など）は**イベントを受け取りません**。
  親の `<motion.svg>` に `whileHover` を置き、variants でフィルタの子要素を駆動します。
- 線描画は `pathLength` / `pathSpacing` / `pathOffset`（0〜1）を
  `circle` `ellipse` `line` `path` `polygon` `polyline` `rect` に対して使います。

---

## 8. よくある誤用

| こう書いている | 問題 | こうする |
|---|---|---|
| `import { motion } from "framer-motion"` | 旧パッケージ名 | `"motion/react"` |
| `transition={{ type: "spring", duration: .3, stiffness: 200 }}` | `stiffness` を設定すると `duration`/`bounce` が無効 | どちらか一方を選ぶ |
| `spring({ duration: 0.3 })` | `spring()` を直接呼ぶときは**ミリ秒** | `spring({ duration: 300 })` |
| `.map()` の中の `useTransform` | フックのルール違反 | 子コンポーネントに切り出すか、関数形式を使う |
| 毎レンダリングで新しい `animate` オブジェクト | 値が同じなら再生はされないが、比較のコストは残る | `useMemo` か variants |
| `setTimeout` でアニメーションを連結 | キャンセルできず、ずれる | シーケンスか `delayChildren` |
| 重要なロジックを `onAnimationComplete` に依存 | 中断されると発火しない | state で駆動する。アニメーションは表現層 |
| RSC で `import { motion } from "motion/react"` | client boundary が必要 | `import * as motion from "motion/react-client"` か `"use client"` |

---

## 9. 納品前チェックリスト

- [ ] サイト全体に `<MotionConfig reducedMotion="user">` がありますか？ パララックスと自動再生は個別に分岐しましたか？
- [ ] すべての `whileInView` に `once: true` が付いていますか？
- [ ] `layout` を使うべき場所で `width` / `height` / `top` / `left` を動かしていませんか？
- [ ] `AnimatePresence` の key は安定して一意で、条件は内側にありますか？
- [ ] 退場は登場の 0.5〜0.7 倍ですか？
- [ ] stagger の計算をしましたか（間隔 × 個数 ≤ 0.5s）？
- [ ] **ダークモードで見ましたか？** 階層は見えますか？ フォーカスリングは？
- [ ] 低スペック機、または CPU 4 倍スロットリングで一度動かしましたか？
- [ ] 分割テキストはコンテナに `aria-label`、断片に `aria-hidden` が付いていますか？
- [ ] 明暗だけ、またはアニメーションだけで伝えている状態はありませんか？
