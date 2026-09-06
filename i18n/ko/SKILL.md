# Dynamization (한국어)

> 이 문서는 `SKILL.md`의 한국어판입니다. 영어 정본은 저장소 루트의 `SKILL.md`에 있습니다.
> API 레퍼런스(react / javascript / vue / doc-index)는 영어만 제공되며 `references/`에 있습니다.

> 모션은 **시간**의 언어입니다. 그것이 어디서 왔고, 어디로 갔으며, 지금 만질 수 있는지를 말합니다.
> 명암은 **공간**의 언어입니다. 무엇이 위에 있고, 무엇이 살아 있으며, 지금 어디를 봐야 하는지를 말합니다.
>
> 둘을 따로 쓰면 각각 절반의 일밖에 하지 못합니다. "떠오른다"는 것은 요소를 4px 위로 옮기는 것이
> 아니라 **이동 + 그림자가 더 크고 부드러워짐 + 표면이 밝아짐이 동시에 일어나는 것**입니다.
> 그래야 비로소 뇌가 *저것이 나에게 가까워졌다*고 읽습니다.
>
> "딱딱하다", "밋밋하다"고 느껴지는 인터페이스의 원인은 거의 언제나 곡선이 덜 우아해서가 아닙니다.
> 물리적 직관을 어겼거나, 셋을 바꿔야 할 곳에서 하나만 바꿨기 때문입니다.

## 1. 런타임부터 고른다

| 상황 | 사용할 것 | import |
|---|---|---|
| React / Next.js | Motion for React | `npm i motion` → `import { motion } from "motion/react"` |
| React Server Component | 동일, 경로만 변경 | `import * as motion from "motion/react-client"` |
| Vue / Nuxt | Motion for Vue | `npm i motion-v` → `import { motion } from "motion-v"` |
| 순수 JS / Webflow / Astro | vanilla | `npm i motion` → `import { animate } from "motion"` |
| hover 시 색만 바뀌는 정도 | **순수 CSS**, 라이브러리 불필요 | — |
| 라이브러리 없이 스프링 곡선이 필요 | CSS `linear()` 생성 | `i18n/ko/recipes.md` §CSS 스프링 |

**애초에 라이브러리가 필요한지 먼저 물으세요.** 요소 하나, 상태 하나, 중단될 필요가 없다면 CSS
`transition`으로 충분합니다. Motion의 가치는 중단 가능성, 속도 인계, 레이아웃 애니메이션, 제스처,
오케스트레이션, 스크롤 연동에 있습니다. 그중 아무것도 쓰지 않는다면 18kb를 배포할 이유가 없습니다.

## 2. 다섯 가지 황금률

애니메이션을 쓰기 전에 이 다섯 개를 통과시키세요. 하나라도 어기면 **왜인지는 말할 수 없지만
이상한** 결과가 나옵니다.

### 1. 위치와 크기는 스프링, 불투명도와 색은 트윈

취향의 문제가 아니라 Motion 자체의 기본 로직입니다(`motion-dom` 소스에서 확인).

| 무엇이 움직이는가 | Motion이 주는 것 |
|---|---|
| `x` `y` `rotate` `skew` 등 transform | spring, `stiffness: 500, damping: 25`(약간의 오버슈트) |
| `scale` 계열 | spring, `stiffness: 550, damping: 30`(임계 감쇠, **오버슈트 없음**) |
| `opacity` `color` `filter` 등 나머지 전부 | tween, `ease: [0.25, 0.1, 0.35, 1]`, `duration: 0.3` |
| 키프레임 3개 이상 | tween, `duration: 0.8` |

이유: 공간을 차지하는 것(위치, 크기)을 뇌는 **실체**로 읽고, 실체에는 질량과 관성이 있습니다.
불투명도와 색은 실체가 아니라 그저 *보이는가 아닌가*이므로, 거기에 스프링을 넣으면 깜빡임으로 읽힙니다.

**따름정리: `scale`에는 절대 바운스를 주지 마세요.** 튕기는 확대는 유리에 부딪히는 것처럼 보입니다.
Motion이 scale을 임계 감쇠로 두는 이유가 바로 이것입니다.

### 2. 애니메이션은 중단 가능해야 하고, 중단 시 속도를 이어받아야 한다

가장 중요하면서 가장 많이 놓치는 규칙입니다. 사람이 도중에 마음을 바꾸는 것은 정상적인 행동입니다.

- 스프링을 쓰세요: Motion이 현재 속도를 자동으로 이어받아, 방향을 뒤집어도 급정지하지 않습니다.
  **이것이 스프링이 트윈보다 나은 진짜 이유이지, "탱탱함"이 아닙니다.**
- 키프레임에서는 첫 프레임에 `null`을 쓰세요: `animate={{ x: [null, 100, 0] }}` —
  시작점으로 튕겨 돌아가지 않고 **현재 값**에서 이어집니다.
- `setTimeout`으로 애니메이션을 엮지 마세요. 시퀀스(`animate([...])`)나 variants의
  `when` / `delayChildren`을 쓰면 한꺼번에 취소할 수 있습니다.
- View Transitions API는 중단할 수 없습니다(중단하면 끝 상태로 튑니다). 중단이 필요하면 Motion의
  `layout`을 쓰세요.

### 3. 등장과 퇴장은 대칭이 아니다

떠나는 것을 사람이 기다리게 해서는 안 됩니다.

```jsx
// 등장: 조금 느리게, easeOut(빠르게 들어와 자리를 잡음)
initial={{ opacity: 0, y: 8 }}
animate={{ opacity: 1, y: 0, transition: { duration: 0.25, ease: "easeOut" } }}
// 퇴장: 빠르게, easeIn(가속하며 떠남)
exit={{ opacity: 0, y: 4, transition: { duration: 0.15, ease: "easeIn" } }}
```

퇴장은 등장의 **0.5~0.7배** 시간에, **이동 거리도 더 짧게**. 떠나는 것은 전체 경로를 갈 필요가 없고,
눈은 "떠났다"는 사실만 알면 됩니다.

### 4. 시간 계층: 용도마다 시간 예산이 다르다

| 계층 | 길이 | 용도 | 곡선 |
|---|---|---|---|
| 즉각 피드백 | `0.1~0.15s` | 누름 축소, 체크박스, 포커스 링 | `easeOut` 또는 스프링 |
| 마이크로 인터랙션 | `0.15~0.25s` | hover, 툴팁, 버튼 색 | `easeOut` |
| 컴포넌트 전환 | `0.25~0.4s` | 드롭다운, 모달, 아코디언, layout | spring `visualDuration: 0.3` |
| 페이지 / 서사 | `0.4~0.8s` | 화면 전환, 큰 히어로, 다단 키프레임 | spring 또는 tween + stagger |
| `1s` 초과 | 거의 확실히 잘못됨 | loading / ambient / 스크롤 연동만 허용 | — |

hover 애니메이션은 **0.2s를 넘기면 안 됩니다** — 커서는 이미 떠났을 수 있습니다.
거리가 멀면 조금 길어져도 되지만 **비례하지는 않습니다**. 거리가 2배가 되면 시간은 20~30% 정도만 늘립니다.

> 완전한 판단 기준, 스프링 인자의 인간적 의미, 리듬 설계, 안티패턴 목록 → `i18n/ko/feel.md`

### 5. 하나의 사건에서는 여러 속성이 같은 방향으로 변해야 한다

단일 속성의 변화는 정보량이 부족합니다. **같은 방향의 다중 속성 변화만이 하나의 물리적 사건으로
읽힙니다.**

| 표현하려는 것 | 최소한 이만큼은 바꾼다 |
|---|---|
| 부상·접근(카드 hover) | `y` 위로 + 그림자가 크고 부드럽게 + 표면이 밝게 |
| 누름·함몰 | `scale` 축소 + 그림자 수축 + 내부 그림자 + 어두워짐 |
| 들어올림(드래그 중) | `scale` 확대 + 넓은 그림자 + z 상승 |
| 집중(모달 열림) | 콘텐츠 등장 + **배경 어둡게**(스크림이 먼저 도착) |
| 비활성 | 전용 저대비 색 토큰(**`opacity: 0.5`가 아님**) |

밝기는 *상태 신호*이고 이동은 *과정*입니다. 따라서 **밝기 변화가 이동보다 빠릅니다**
(대략 `0.12~0.15s` 대 `0.2~0.35s`).

다크 테마에서는 그림자가 거의 보이지 않으므로 높이를 *표면을 밝게 하는 것*으로 표현합니다.
테마 전환은 팔레트가 아니라 **표현 메커니즘 자체를 바꾸는 일**입니다.

> 광학 모델, 명암 테마 토큰, 명암 속성의 애니메이션 비용, 접근성 하한선 → `i18n/ko/contrast.md`

## 3. 라우팅 표

지금 눈앞의 일에 해당하는 파일만 읽으세요. **전부 읽지 마세요.**

| 하려는 일 | 읽을 것 |
|---|---|
| "자연스럽다"가 무엇인지 이해. 느낌이 안 남. "딱딱하다"는 말을 들음 | `i18n/ko/feel.md` ← **시간축** |
| 계층, 그림자, 다크 모드, 집중, 스크림, 대비 | `i18n/ko/contrast.md` ← **공간축** |
| React 작성. prop / hook / 컴포넌트 조회 | `references/react.md`(영어) |
| 순수 JS 작성. `animate()` / `scroll()` / motion value | `references/javascript.md`(영어) |
| Vue 작성, 또는 React 예제 이식 | `references/vue.md`(영어) |
| 바로 붙여 쓸 효과가 필요 | `i18n/ko/recipes.md` |
| 안 움직임, 튐, 끊김, exit 미발동, layout 왜곡 | `i18n/ko/pitfalls.md` |
| 공식 원문, 또는 여기 없는 API | `references/doc-index.md` + 6절 |

## 4. 접근성은 선택 사항이 아니다

**큰 요소를 이동하거나 확대·축소하는** 모든 애니메이션은 reduced motion을 처리해야 합니다.
사이트 전체라면 한 줄입니다.

```jsx
import { MotionConfig } from "motion/react"
<MotionConfig reducedMotion="user">{children}</MotionConfig>
```

`reducedMotion="user"`는 transform과 layout 애니메이션을 자동으로 끄면서 opacity와 색은
**유지합니다** — iOS와 같은 방식입니다. "화면이 바뀌었다"는 것은 여전히 알려주되, 슬라이드 대신
크로스페이드를 씁니다.

세밀한 제어에는 `useReducedMotion()`(Vue도 같은 이름). 패럴랙스, 동영상 자동 재생, 무한 루프는
언제나 명시적 분기가 필요합니다.

## 5. 성능의 레드라인

모든 브라우저에서 컴포지터에 올라가는 것은 `transform`과 `opacity`뿐입니다. 이 둘은 언제나 안전합니다.

- ❌ `width` / `height` / `top` / `left` / `margin` / `border-width`는 레이아웃을 유발하며 반드시 프레임을 떨어뜨립니다
- ⚠️ `box-shadow` / `border-radius` / `background-color`는 페인트를 유발합니다. 작은 요소는 괜찮지만 넓은 면적은 실측하세요
- ✅ 그림자 애니메이션은 `filter: drop-shadow(...)`로, 모서리는 `clip-path: inset(0 round Npx)`로
- ✅ 크기나 위치를 움직이려면 `layout` prop을 쓰세요. Motion이 내부적으로 transform으로 구현합니다. 이 라이브러리가 존재하는 주된 이유 중 하나입니다
- ⚠️ Motion의 독립 transform(`x`, `scale`)은 CSS 변수 기반이라 **하드웨어 가속되지 않습니다**. 중요한 상황에서는 `transform: "translateX(100px) scale(2)"`로 쓰세요

## 6. 공식 최신 원문 가져오기

문서 사이트가 콘텐츠 협상을 지원하므로, 권위 있는 원문은 언제나 명령 하나로 얻을 수 있습니다
(이 팩보다 최신일 것입니다).

```bash
curl -sL -H "Accept: text/markdown" https://motion.dev/docs/<slug>
# 예: https://motion.dev/docs/react-transitions
```

또는 `scripts/fetch-doc.sh react-transitions`. 전체 slug는 `references/doc-index.md`에 있습니다.

**이 팩과 공식 문서가 어긋나면 공식이 우선**입니다. 다만 알려진 예외가 하나 있습니다.
공식 페이지는 스프링의 `stiffness` 기본값을 `1`로 적고 있는데 **이는 틀렸습니다**. 소스는 `100`입니다.
문서대로 쓰면 거의 움직이지 않는 스프링이 됩니다.
