# pitfalls.md — 증상 → 원인 → 해결

먼저 증상으로 찾고, 해당 절을 읽으세요.

| 증상 | 가장 유력한 원인 |
|---|---|
| 퇴장 애니메이션이 전혀 안 나옴 | `AnimatePresence` 자신이 사라졌거나 자식 `key`가 불안정 → §1 |
| 매번 처음부터 다시 재생됨 | 컴포넌트가 재생성되고 있음(key 변경 / render 안의 `motion.create`) → §2 |
| layout 애니메이션이 반응 없음 | 요소가 `display: inline`이거나 리렌더가 없었음 → §3 |
| layout 애니메이션 중 콘텐츠가 일그러짐 | 자식에 `layout`이 없거나, 모서리/그림자가 `style`에 없음 → §3 |
| 스크롤 중 페이지 전체가 흔들림 | 스크롤바 출현이 layout 애니메이션을 유발 → §3 |
| 프레임 드랍, 끊김 | 레이아웃 유발 속성 또는 넓은 면적의 페인트 → §4 |
| 스크롤 연동이 계단처럼 보임 | `useSpring`을 거치지 않음 → §5 |
| 드래그 거리가 손가락과 안 맞음 | 조상에 transform / scale이 있음 → §6 |
| 터치 기기에서 hover가 "고착됨" | Motion의 `hover()` / `whileHover` 대신 네이티브 hover 사용 → §6 |
| SVG의 layout 애니메이션이 깨짐 | SVG는 layout 애니메이션 미지원 → §7 |
| 다크 모드에서 계층이 사라짐 | 어두운 표면에서 그림자가 안 보임 → `i18n/ko/contrast.md` §2 |
| 애니메이션 도중 글자를 읽을 수 없음 | 중간 상태의 대비 부족 → `i18n/ko/contrast.md` §7 |

---

## 1. `AnimatePresence`와 퇴장

**퇴장이 안 나오는 세 가지 이유:**

```jsx
// ❌ AnimatePresence 자신이 언마운트되어 자기 퇴장을 제어할 수 없음
{isVisible && <AnimatePresence><Component /></AnimatePresence>}

// ✅ 조건은 안쪽에
<AnimatePresence>{isVisible && <Component />}</AnimatePresence>
```

```jsx
// ❌ index를 key로: 재정렬 시 항목과 key의 대응이 깨짐
{items.map((item, i) => <Component key={i} />)}
// ✅ 안정적이고 유일한 id
{items.map(item => <Component key={item.id} />)}
```

**퇴장하는 컴포넌트는 `AnimatePresence`의 직계 자식**이어야 `exit`을 받습니다.
사이에 motion이 아닌 래퍼가 한 겹만 있어도 동작하지 않습니다.

**중첩된 `AnimatePresence`**: 바깥쪽이 제거될 때 안쪽 자식은 기본적으로 퇴장하지 않습니다.
안쪽에 `propagate`를 붙이세요.
```jsx
<AnimatePresence propagate>…</AnimatePresence>
```

**`mode="popLayout"`의 두 가지 요구 사항:**
- 커스텀 컴포넌트 자식은 `forwardRef`로, pop할 DOM 노드에 ref를 전달해야 합니다
- 애니메이션하는 부모는 `static`이 아닌 `position`을 가져야 합니다. popLayout은 내부에서
  `position: absolute`를 쓰고, transform을 가진 조상은 오프셋 부모가 되어버립니다

```jsx
<motion.ul layout style={{ position: "relative" }}>
  <AnimatePresence mode="popLayout">…</AnimatePresence>
</motion.ul>
```

**`mode="sync"`와 layout 애니메이션 혼용**: 그룹을 `<LayoutGroup>`으로 감싸 `AnimatePresence`
바깥의 컴포넌트에도 재배치를 알립니다.

---

## 2. 컴포넌트가 재생성되고 있음

```jsx
// ❌ 매 렌더마다 새 컴포넌트. 애니메이션 상태가 전부 사라짐
function Row() {
  const MotionCard = motion.create(Card)   // 재앙
  return <MotionCard animate={…} />
}
// ✅ 모듈 최상위로
const MotionCard = motion.create(Card)
```

`motion.create()`로 감싼 컴포넌트는 실제로 움직이는 DOM 노드에 `ref`를 전달해야 합니다
(React 18은 `forwardRef`, React 19는 `props.ref`). 전달하지 않으면 아무것도 움직이지 않습니다.

중단 시 애니메이션이 시작점으로 돌아간다면, 첫 키프레임을 `null`로 쓰세요.
```jsx
animate={{ x: [null, 100, 0] }}
```

---

## 3. layout 애니메이션

**반응하지 않음:**
- 요소가 `display: inline` — 브라우저는 inline 박스에 transform을 적용하지 않습니다.
  `inline-block` / `block` / `flex`로 바꾸세요.
- 리렌더가 일어나지 않았습니다. layout 애니메이션은 React 렌더로 촉발되므로 순수한 CSS 변경으로는
  일어나지 않습니다.
- 두 컴포넌트가 서로의 레이아웃에 영향을 주지만 따로 렌더됩니다 → `<LayoutGroup>`으로 감싸세요.

**레이아웃 변경은 `style` / `className`으로, `animate`로 하지 말 것:**
```jsx
// ❌ layout과 animate가 싸움
<motion.div layout animate={{ width: open ? 300 : 100 }} />
// ✅ layout에 맡김
<motion.div layout style={{ width: open ? 300 : 100 }} />
```

**콘텐츠가 늘어남(scale로 인한 왜곡):**
- 직계 자식에도 `layout`을 붙이세요. Motion이 역스케일로 보정합니다
- 종횡비가 바뀌는 요소(이미지, 글자)는 `layout="position"`으로
- **`borderRadius`와 `boxShadow`는 `style`에 써야 합니다.** CSS 클래스로는 보정되지 않습니다
- `border`는 완전히 보정할 수 없습니다(1px 하한) → padding을 가진 부모를 테두리 대용으로 쓰세요

```jsx
<motion.div layout style={{ borderRadius: 10, padding: 5, background: "#000" }}>
  <motion.div layout style={{ borderRadius: 5, background: "#fff" }} />
</motion.div>
```

**스크롤 컨테이너 안**: 컨테이너에 `layoutScroll`을 붙입니다.
**`position: fixed` 안**: `layoutRoot`를 붙입니다.

**창의 가로 방향 리사이즈 중에는 layout 애니메이션이 비활성화됩니다** —
의도적인 성능 보호이지 버그가 아닙니다.

**스크롤바 출현으로 페이지가 흔들림:**
```css
body { overflow-y: auto; scrollbar-gutter: stable; }
```

**중첩된 layout 애니메이션의 상대 위치**: Motion은 **부모 상대**로 계산합니다
(페이지 절대 좌표를 쓰는 View Transitions와 다릅니다). 따라서 `delay`를 가진 자식이 부모에게
뒤처지는 일이 없습니다. 앵커는 `layoutAnchor={{ x: 0.5, y: 0.5 }}`로 바꿀 수 있습니다.

---

## 4. 성능

**언제나 안전**: `transform`(독립된 `x` / `scale` / `rotate` 포함), `opacity`
**페인트 유발(실측할 것)**: `box-shadow`, `border-radius`, `background-color`, `filter`
**레이아웃 유발(피할 것)**: `width`, `height`, `top`, `left`, `margin`, `padding`, `border-width`

대체:
```js
animate(el, { boxShadow: "10px 10px black" })          // ❌ 페인트
animate(el, { filter: "drop-shadow(10px 10px black)" })// ✅ 컴포지터(Chrome/FF)

animate(el, { borderRadius: "50px" })                  // ❌
animate(el, { clipPath: "inset(0 round 50px)" })       // ✅
```
넓은 면적의 그림자 애니메이션은 의사 요소의 opacity로 → `i18n/ko/recipes.md` §5.

**하드웨어 가속의 함정**: Motion의 독립 transform(`x`, `scale`)은 CSS 변수로 구현되어 현재
**하드웨어 가속되지 않습니다**. 메인 스레드가 바쁘면 여전히 끊길 수 있습니다.
정말 중요한 상황에서는 전체 문자열을 쓰세요:
```js
animate(".box", { transform: "translateX(100px) scale(2)" })
```
또한 Chrome은 오랫동안 `%` 단위 transform을 가속하지 않았습니다.

**레이어 힌트는 아껴 쓸 것**: `will-change: transform`은 한 장마다 GPU 메모리를 씁니다.
실측해서 문제가 있었던 요소에만 붙이세요.

**텍스트 애니메이션**: 분할은 DOM을 부풀리지만(일회성 비용), 매 프레임 `innerText`를 갱신하는 것은
**지속적으로** 레이아웃 재계산을 유발합니다. 스크램블에는 고정폭 글꼴, 타자기에는 `contain: layout`을.
**글자 단위 blur는 성능의 함정입니다** — 작은 레이어가 흐림으로 커져 서로 겹치면서, 블록 전체에
blur를 한 번 거는 것보다 훨씬 비쌉니다.

---

## 5. 스크롤

- 스크롤 입력은 이산적이라 `scrollYProgress`를 style에 직접 묶으면 계단처럼 보입니다.
  반드시 `useSpring`을 거치세요.
- 스크롤 값을 스프링으로 따라갈 때는 `skipInitialAnimation: true`를 붙여 마운트 시 0부터 훑는 것을
  막으세요.
- 고정은 CSS `position: sticky`로. JS로 `top`을 고쳐 쓰지 마세요.
- `once: true`가 없는 `whileInView`는 반복 재생됩니다. 기본값 `amount: "some"`(1픽셀)은 대개
  너무 이르므로 `0.3`으로.
- `useScroll`의 `offset`은 `[시작, 끝]`이고, 각 요소는 `"<target 위치> <container 위치>"` 형식입니다.
  `"start end"`는 *target의 위쪽이 container의 아래쪽에 닿는* 순간을 뜻합니다.

---

## 6. 제스처

**드래그 거리가 포인터와 안 맞음** → 조상에 transform / scale이 있습니다.
transform을 가진 조상은 좌표계를 바꿉니다. 페이지 전체 확대는 `MotionConfig`의
`transformPagePoint`로 보정할 수 있습니다.

**스케일된 부모 안에서 layout 애니메이션이 이상함** → 같은 원인입니다.

**이미지를 드래그하면 브라우저의 고스트 이미지가 나옴** → `draggable={false}` 또는 CSS
`-webkit-user-drag: none`을 붙이세요.

**터치 기기에서 hover가 "고착됨"** → 브라우저가 터치용으로 hover 이벤트를 흉내 냅니다.
가짜 이벤트를 걸러내는 `whileHover` / `hover()`를 쓰고, 직접 `mouseenter`를 묶지 마세요.

**터치에서 pan / drag가 반응 없거나 스크롤과 싸움** → CSS `touch-action`이 필요합니다:
```css
.draggable-x { touch-action: pan-y; }   /* 가로는 드래그, 세로는 스크롤에 남김 */
.draggable   { touch-action: none; }
```

**자식의 클릭을 부모 제스처가 삼킴**:
```jsx
<button onPointerDownCapture={e => e.stopPropagation()} />  {/* 일반 React 컴포넌트 */}
<motion.button propagate={{ tap: false }} />                 {/* motion 컴포넌트, 현재 tap만 */}
```
Motion의 제스처 처리는 지연 실행이라 `onTapStart` 안에서 `e.stopPropagation()`을 호출해도
늦습니다.

**드래그 가능한 요소 안의 tap**은 포인터가 3px을 넘어 움직이면 자동으로 취소됩니다.

---

## 7. SVG

- **SVG는 layout 애니메이션을 지원하지 않습니다**(SVG에는 레이아웃 시스템이 없습니다).
  속성(`cx`, `x`, `width`…)이나 `viewBox`를 직접 움직이세요.
- SVG의 `filter` 계열 요소(`feGaussianBlur` 등)는 **이벤트를 받지 않습니다**.
  부모 `<motion.svg>`에 `whileHover`를 두고 variants로 필터 자식을 구동하세요.
- 선 그리기는 `pathLength` / `pathSpacing` / `pathOffset`(0~1)을
  `circle` `ellipse` `line` `path` `polygon` `polyline` `rect`에 사용합니다.

---

## 8. 흔한 오용

| 이렇게 쓰고 있음 | 문제 | 이렇게 |
|---|---|---|
| `import { motion } from "framer-motion"` | 구 패키지명 | `"motion/react"` |
| `transition={{ type: "spring", duration: .3, stiffness: 200 }}` | `stiffness`를 설정하면 `duration`/`bounce`가 무력화 | 하나만 고르기 |
| `spring({ duration: 0.3 })` | `spring()`을 직접 호출할 때는 **밀리초** | `spring({ duration: 300 })` |
| `.map()` 안의 `useTransform` | 훅 규칙 위반 | 자식 컴포넌트로 분리하거나 함수형 사용 |
| 매 렌더마다 새 `animate` 객체 | 값이 같으면 재생은 안 되지만 비교 비용은 남음 | `useMemo` 또는 variants |
| `setTimeout`으로 애니메이션 연결 | 취소 불가, 어긋남 | 시퀀스 또는 `delayChildren` |
| 중요한 로직을 `onAnimationComplete`에 의존 | 중단되면 발화하지 않음 | state로 구동. 애니메이션은 표현 계층 |
| RSC에서 `import { motion } from "motion/react"` | client boundary 필요 | `import * as motion from "motion/react-client"` 또는 `"use client"` |

---

## 9. 납품 전 체크리스트

- [ ] 사이트 전체에 `<MotionConfig reducedMotion="user">`가 있습니까? 패럴랙스와 자동 재생은 따로 분기했습니까?
- [ ] 모든 `whileInView`에 `once: true`가 있습니까?
- [ ] `layout`을 써야 할 곳에서 `width` / `height` / `top` / `left`를 움직이고 있지 않습니까?
- [ ] `AnimatePresence`의 key가 안정적이고 유일하며, 조건이 안쪽에 있습니까?
- [ ] 퇴장이 등장의 0.5~0.7배입니까?
- [ ] stagger 계산을 했습니까(간격 × 개수 ≤ 0.5s)?
- [ ] **다크 모드에서 봤습니까?** 계층이 보입니까? 포커스 링은요?
- [ ] 저사양 기기나 CPU 4배 스로틀링에서 한 번 돌려봤습니까?
- [ ] 분할 텍스트가 컨테이너에 `aria-label`, 조각에 `aria-hidden`을 갖고 있습니까?
- [ ] 명암만으로, 또는 애니메이션만으로 전달하는 상태가 있습니까?
