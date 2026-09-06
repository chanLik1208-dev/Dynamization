# vue.md — Motion for Vue

```bash
npm install motion-v
```
```vue
<script setup>
import { motion, AnimatePresence, useScroll, stagger } from "motion-v"
</script>
```

> The package is **`motion-v`** — not `motion`, and not `motion-vue`.

---

## 1. Differences from React — this is the complete list

**The API surface is 95% identical.** Use `react.md` as the primary reference and remember only
this table:

| Item | React | Vue |
|---|---|---|
| Package | `motion` / `motion/react` | `motion-v` |
| Press gesture | `whileTap` | **`whilePress`** |
| Press events | `onTapStart` / `onTap` / `onTapCancel` | **`onPressStart` / `onPress` / `onPressCancel`** |
| Passing props | `animate={{...}}` | `:animate="{...}"` (must be bound) |
| Conditional rendering | `{show && <div/>}` | `v-if` **or `v-show`** (both are detected) |
| Wrapping an existing element | `motion.create(C)` | the **`v-motion` directive** (see §3) |
| DOM refs | `useRef` | `useDomRef` (provided by Motion) or a plain `ref` |

Everything else — `initial` / `animate` / `exit` / `transition` / `variants` / `whileHover` /
`whileFocus` / `whileDrag` / `whileInView` / `layout` / `layoutId` / `drag*` — has the same name and
the same meaning.

---

## 2. Basic usage

```vue
<script setup>
import { motion } from "motion-v"
import { ref } from "vue"
const open = ref(false)
</script>

<template>
  <motion.button
    :initial="{ scale: 0 }"
    :animate="{ scale: 1 }"
    :while-hover="{ scale: 1.03 }"
    :while-press="{ scale: 0.97 }"
    :transition="{ type: 'spring', visualDuration: 0.3, bounce: 0.15 }"
    @click="open = !open"
  />
</template>
```
`:initial="false"` disables the enter animation.

Both kebab-case (`:while-hover`) and camelCase (`:whileHover`) work in templates.

---

## 3. The `v-motion` directive — Vue only

Use it when you do not want to wrap something in `<motion.div>`, or when animating a third-party
component.

```js
// global registration
import { MotionPlugin } from "motion-v"
app.use(MotionPlugin)
```
```vue
<script setup>import { vMotion } from "motion-v"</script>  <!-- or locally -->
```

Three syntaxes, which can be mixed — **element props win over the binding value**:

```vue
<!-- A. Binding value: everything in one object -->
<div v-motion="{ initial: { opacity: 0, x: -30 }, animate: { opacity: 1, x: 0 },
                 transition: { duration: 0.6 } }">Slide In</div>

<!-- B. As a marker, options as props -->
<div v-motion :initial="{ opacity: 0, y: 30 }" :animate="{ opacity: 1, y: 0 }" />

<!-- C. Mixed: props override the binding -->
<div v-motion="{ initial: { opacity: 0.5 } }" :initial="{ opacity: 0.2 }" />
<!-- result: initial = { opacity: 0.2 } -->
```
It supports every animation prop the `<motion>` component has (including `exit`, gestures and
`whileInView`) and works with `AnimatePresence`.

---

## 4. `AnimatePresence`

```vue
<AnimatePresence mode="wait" :initial="false">
  <motion.div v-if="show" key="modal" :exit="{ opacity: 0 }" />
</AnimatePresence>
```
- Both `v-if` and **`v-show`** are detected (React only has unmounting).
- Direct children still need stable, unique `key`s.
- `mode`: `"sync"` (default) / `"wait"` / `"popLayout"`, same semantics as React.
- The condition must be **inside** `AnimatePresence`.

---

## 5. Composables

Same names and usage as the React hooks, imported from `motion-v`:

`useMotionValue` `useSpring` `useTransform` `useMotionTemplate` `useMotionValueEvent` `useVelocity`
`useTime` `useScroll` `useInView` `useAnimate` `useAnimationFrame` `useDragControls`
`useReducedMotion` `useDomRef`

```vue
<script setup>
import { motion, useScroll, useSpring } from "motion-v"
const { scrollYProgress } = useScroll()
const scaleX = useSpring(scrollYProgress, { stiffness: 100, damping: 30, restDelta: 0.001 })
</script>
<template>
  <motion.div class="bar" :style="{ scaleX, originX: 0 }" />
</template>
```

Other components — `MotionConfig`, `LayoutGroup`, `LazyMotion`, `AnimatePresence` — work as in React.

```vue
<MotionConfig :transition="{ duration: 0.3 }" reduced-motion="user">
  <App />
</MotionConfig>
```

---

## 6. Nuxt

```ts
// nuxt.config.ts
export default defineNuxtConfig({
  modules: ['motion-v/nuxt'],
  motionV: { directives: true },   // only if you need v-motion
})
```
This auto-imports all components.

**`unplugin-vue-components`:**
```ts
import Components from 'unplugin-vue-components/vite'
import MotionResolver from 'motion-v/resolver'

Components({ dts: true, resolvers: [MotionResolver()] })
```
⚠️ Auto-import does **not** currently cover the `<motion />` component itself — import that manually.

---

## 7. Checklist for porting a React example

When moving a React Motion snippet to Vue, walk through these:

- [ ] `whileTap` → `whilePress`
- [ ] `onTap*` → `onPress*`
- [ ] Add `:` binding to every prop
- [ ] `{cond && <X/>}` → `v-if`
- [ ] `useRef` → `ref` / `useDomRef`, and make sure the template ref name matches
- [ ] `motion.create(Component)` → the `v-motion` directive
- [ ] Change every import to `motion-v`
- [ ] `v-for` `:key` must be unique and stable

Everything else — transition parameters, variants, layout, drag, scroll — carries over unchanged.
