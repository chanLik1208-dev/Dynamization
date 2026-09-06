# doc-index.md — 官方文件索引

本包收錄的是蒸餾後的判準與常用 API。需要官方原文（含冷門選項、完整 FAQ、最新變更）時，用 slug 抓：

```bash
curl -sL -H "Accept: text/markdown" https://motion.dev/docs/<slug>
# 或
bash ~/.claude/skills/motion/scripts/fetch-doc.sh <slug>
```

Motion 也提供索引檔 `https://motion.dev/llms.txt`（含教學與文章連結，本表未收）。


## React

| slug | 內容 |
|---|---|
| `react-motion-component` | **Motion component** — Animate elements with a declarative API. Supports variants, gestures, and layout animations. |
| `react-motion-plus-installation` | **Install Motion+** — Install Motion+ in your React project from the private registry, keeping your token out of source control. |
| `framer` | **Motion x Framer integration guide** — Add animations to your Framer project, in Code Components and Overrides. |
| `figma` | **Figma Motion: animate with Figma and export to Motion** — Animate in Figma Motion and export to real Motion code for React. Or use Motion directly inside Figma Sites. |
| `react-tailwind` | **Animating with Tailwind CSS** — Combine Motion with Tailwind CSS's utility-first workflow. |
| `base-ui` | **Base UI & Motion** — Animate Base UI components with Motion. |
| `radix` | **Radix UI & Motion** — Animate Radix UI components with Motion. |
| `react-use-curtains` | **useCurtains** — Page transitions for React with the useCurtains hook: cover the view with an effect, swap content while it's hidden, then reveal once React has committed. |
| `react-accessibility` | **Accessibility** — Respect users' Reduced Motion preferences with the reducedMotion option and useReducedMotion hook. |
| `react-animate-activity` | **AnimateActivity** — Add enter, exit, and layout animations to components inside React's Activity boundaries. |
| `react-animate-number` | **AnimateNumber** — Number ticker and countdown animations for React. |
| `react-animate-presence` | **AnimatePresence** — Run exit animations on React components when they're removed from the page. |
| `react-animate-view` | **AnimateView** — View transitions and page animations for React, with the AnimateView component. |
| `react-carousel` | **Carousel** — A performant, accessible, and infinitely scrollable carousel for React. |
| `cursor` | **Cursor** — Custom cursor and follow-along effects for React. |
| `react-drag` | **Drag animation** — Physics-based drag interactions for React. |
| `react-gestures` | **Gesture animation** — An overview of the gestures available in Motion for React. |
| `react` | **Get started with Motion for React** — Install Motion for React and animate elements with springs. |
| `react-hover-animation` | **Hover animation** — Hover animations and interactions for React. |
| `react-installation` | **Installation guide for Motion for React** — Install Motion in your React project. |
| `react-layout-animations` | **Layout animation** — Smoothly animate layout changes and shared element transitions. |
| `react-layout-group` | **LayoutGroup** — Coordinate React layout animations between Motion components. |
| `react-lazy-motion` | **LazyMotion** — Load Motion's animation features on demand, shrinking initial bundle size to as low as 4.6kb. |
| `react-courses` | **Motion Courses for React** — Motion-Certified courses and community resources for learning Motion for React. |
| `react-motion-value` | **Motion values overview** — Composable, animatable values that update styles without re-rendering React. |
| `react-motion-config` | **MotionConfig** — Configure default transition options and manage reduced motion preferences. |
| `react-animation` | **React animation** — An overview of animating React with motion components, variants, gestures, and keyframes. |
| `react-scroll-animations` | **React scroll animation** — Scroll-triggered and scroll-linked effects in React: parallax, progress, and more. |
| `react-reduce-bundle-size` | **Reduce bundle size** — Techniques for shrinking your Motion for React bundle. |
| `react-reorder` | **Reorder** — Drag-to-reorder lists and grids with automatic layout and exit animations. |
| `react-scramble-text` | **ScrambleText** — A scramble text animation component for React, with stagger and renderless control. |
| `react-svg-animation` | **SVG animation** — Animate SVGs in React, including line drawing and morphing effects. |
| `text-animation` | **Text animation** — A complete overview of text animation techniques: splitting, staggering, clipped reveals, rolling labels, scramble text, typewriters, numbers and scroll-linked words. |
| `react-ticker` | **Ticker** — Infinitely-scrolling ticker and marquee effects, driven by time, drag, or scroll. |
| `react-transitions` | **Transitions** — Control timing with duration, easing, springs, delay, and stagger. |
| `react-typewriter` | **Typewriter** — A typewriter component for React with human-like variance, stylable cursors, and accessibility. |
| `react-upgrade-guide` | **Upgrade guide** — Step-by-step upgrade notes between Motion for React versions. |
| `react-use-animate` | **useAnimate** — Manually start and control animations, scoped to the current React component. |
| `react-use-animation-frame` | **useAnimationFrame** — Run a callback every frame, with elapsed time and delta arguments. |
| `react-use-drag-controls` | **useDragControls** — Manually start and stop drag gestures, with snap to cursor and more. |
| `react-use-in-view` | **useInView** — Switch React state when an element enters or leaves the viewport. |
| `react-use-motion-template` | **useMotionTemplate** — Combine motion values into dynamic, interpolated strings. |
| `react-use-motion-value-event` | **useMotionValueEvent** — Fire events when the value of a motion value changes. |
| `react-use-page-in-view` | **usePageInView** — Pause animations when the document isn't visible. SSR-compatible. |
| `react-use-reduced-motion` | **useReducedMotion** — Adapt or disable animations based on the device's Reduced Motion setting. |
| `react-use-scroll` | **useScroll** — Track scroll progress as motion values, for parallax and progress bars. |
| `react-use-spring` | **useSpring** — A spring-powered motion value. Standalone, or attached to another motion value. |
| `react-use-time` | **useTime** — A motion value that returns elapsed time in milliseconds, every frame. |
| `react-use-transform` | **useTransform** — Transform the output of one motion value into a new motion value. |
| `react-use-velocity` | **useVelocity** — A motion value that outputs the velocity of another motion value. |

## JavaScript (vanilla)

| slug | 內容 |
|---|---|
| `animate` | **animate** — animate() runs easing and spring animations, hardware-accelerated where supported. |
| `motion-plus-installation` | **Install Motion+** — Install Motion+ in your project from the private registry, keeping your token out of source control. |
| `animate-view` | **View animations** — animateView() runs view transitions with spring animations and interruption handling. |
| `scroll` | **scroll** — scroll() binds animations to scroll progress, hardware-accelerated where supported. |
| `easing-functions` | **Easing functions** — Motion's built-in easing functions and modifiers, from cubicBezier to anticipate. |
| `layout-animations` | **Layout animations** — Animate complex layout changes and shared element transitions. |
| `curtains` | **Curtains** — curtains() runs a page transition that covers the viewport with an effect, swaps your content while it's hidden, then reveals it. |
| `3d-transforms` | **3D transforms and perspective** — How the z axis, perspective and preserve-3d work on the web, and how to animate them with Motion. |
| `squarespace` | **Add animations to your Squarespace site** — Add Motion to a Squarespace site for animations beyond what templates allow. |
| `wordpress` | **Add animations to your WordPress site** — Add Motion to a WordPress site for high-performance animations on any theme. |
| `performance` | **Animation performance** — How browsers render animations, and how to write ones that hit 120fps. |
| `arc` | **arc** — `arc` can change the path between two points from a straight line to a curved one. |
| `attr-effect` | **attrEffect** — attrEffect() applies motion values to HTML element attributes. |
| `css` | **CSS** — Spring animations as CSS, ready for React Server Components, Astro, Vue, and CSS-in-JS. |
| `delay` | **delay** — delay() is a setTimeout replacement that fires in tandem with Motion's frame loop. |
| `faqs` | **FAQs** — Find answers to common questions about Motion, including browser support and other troubleshooting. |
| `frame` | **frame** — frame() schedules tasks on Motion's animation loop, batching reads, updates, and renders. |
| `quick-start` | **Get started with Motion** — Install Motion and animate HTML, SVG, or WebGL with springs. |
| `gsap-vs-motion` | **GSAP vs Motion: Which should you use?** — Compare Motion (formerly Framer Motion) and GSAP across bundle size, performance, and licensing. |
| `hover` | **hover** — hover() fires callbacks when a hover gesture starts and ends. |
| `improvements-to-the-web-animations-api-dx` | **Improvements to Web Animations API** — Springs, custom easings, persistent state, and independent transforms on top of the Web Animations API. |
| `webflow` | **Integrate Motion with Webflow** — Add Motion to a Webflow site for hardware-accelerated animations beyond native capabilities. |
| `inview` | **inView** — inView() runs callbacks when elements enter and leave the viewport, built on IntersectionObserver. |
| `map-value` | **mapValue** — mapValue() maps a motion value's output range to numbers, colours, or complex strings. |
| `migrate-from-gsap-to-motion` | **Migrate from GSAP to Motion** — Move from GSAP to Motion: tweens, timelines, scroll, and React, mapped step by step. |
| `mix` | **mix** — mix() interpolates between two values: numbers, colours, complex strings, arrays, and objects. |
| `motion-value` | **motionValue** — Motion values track the state and velocity of an animated property. The reactive primitive at Motion's core. |
| `press` | **press** — press() detects press gestures, with keyboard support and pointer filtering built in. |
| `prop-effect` | **propEffect** — propEffect() applies motion values to JavaScript object properties, useful with libraries like Three.js. |
| `resize` | **resize** — resize() reacts to size changes on the viewport or any element, via ResizeObserver. |
| `scramble-text` | **scrambleText** — scrambleText() animates text by scrambling characters, with stagger and timing controls. |
| `split-text` | **splitText** — splitText() breaks text into characters, words, and lines for granular text animation. |
| `spring` | **spring** — spring() creates physics-based spring animations, configured by bounce, stiffness, damping, and mass. |
| `spring-value` | **springValue** — springValue() creates motion values driven by physics, with stiffness, damping, and mass. |
| `stagger` | **stagger** — stagger() distributes a delay across elements, with control over origin and easing. |
| `style-effect` | **styleEffect** — styleEffect() applies motion values to HTML element styles, with independent transforms. |
| `svg-animation` | **SVG animation: every technique compared** — There are four ways to animate SVG on the web: SMIL, CSS, the Web Animations API and JavaScript. Here's how each SVG animation technique actually works, and which one to reach for. |
| `svg-effect` | **svgEffect** — svgEffect() applies motion values to SVG styles and attributes, including pathLength for draw animations. |
| `transform` | **transform** — transform() maps an input range to numbers, colours, or complex strings. |
| `transform-value` | **transformValue** — transformValue() derives a new motion value by computing output from one or more existing values. |
| `tween` | **Tween animations** — A tween animates between a start and end value over a set duration, shaped by an easing curve. |
| `upgrade-guide` | **Upgrade guide** — Step-by-step upgrade notes between Motion versions. |
| `wrap` | **wrap** — wrap() constrains a value within a range, ideal for pagination and looping indices. |

## Vue

| slug | 內容 |
|---|---|
| `vue-motion-component` | **Motion component** — Animate Vue elements with a declarative API. Supports variants, gestures, and layout animations. |
| `vue-animate-number` | **AnimateNumber** — Create beautiful number animations like countdowns with AnimateNumber and Motion. Leverages Motion's layout animations and transitions. Lightweight at just 2.5kb. |
| `vue-animate-presence` | **AnimatePresence** — Run exit animations on Vue components via the exit prop. |
| `vue-carousel` | **Carousel** — A performant, accessible, and infinitely scrollable carousel for Vue. |
| `vue-cursor` | **Cursor** — Create custom cursors and follow-along effects in Vue with Motion+ Cursor. It auto-adapts to links, text, & buttons. Style with CSS, animate with Motion. |
| `vue-gestures` | **Gesture animation** — Hover, tap, pan, drag, and inView gestures for Motion for Vue. |
| `vue` | **Get started with Motion for Vue** — Install Motion for Vue and animate elements with springs. |
| `vue-radix` | **Integrate Motion with Reka** — Animate Reka-UI primitives with Motion for Vue. |
| `vue-layout-animations` | **Layout animation** — Animate layout changes between elements, including shared element transitions via layoutId. |
| `vue-layout-group` | **LayoutGroup** — Coordinate layout animations between Vue components, even when they aren't rendered together. |
| `vue-lazymotion` | **LazyMotion** — Load Motion's animation features on demand, shrinking initial bundle size to as low as 6kb. |
| `vue-directive` | **Motion Directive** — v-motion adds gestures, layout, and variants to any HTML or SVG element without a wrapper component. |
| `vue-motion-value` | **Motion values** — Composable, animatable values that update styles without re-rendering Vue. |
| `vue-motion-config` | **MotionConfig** — Configure default transitions and reduced motion preferences for all child Motion components. |
| `vue-reorder` | **Reorder** — Drag-to-reorder lists and grids with automatic layout and exit animations. |
| `vue-scroll-animations` | **Scroll animation** — Scroll-triggered and scroll-linked animations for Vue, via whileInView and useScroll. |
| `vue-ticker` | **Ticker** — Create infinitly-scrolling ticker and marquee effects with Motion for Vue's Ticker component. Looping, dragging and scrolling animations are all possible with this lightweight and performant component. |
| `vue-transitions` | **Transition options** — Control timing with duration, easing, springs, delay, and repeat. |
| `vue-typewriter` | **Typewriter** — A customizable typewriter animation component for Vue that creates realistic typing animations with human-like variance, stylable cursors and accessibility. |
| `vue-use-animate` | **useAnimate** — Manually start and control animations, scoped to the current Vue component. |
| `vue-use-animation-frame` | **useAnimationFrame** — Run a callback every frame, with elapsed time and delta arguments. |
| `vue-use-drag-controls` | **useDragControls** — Manually start and stop drag gestures, with snap-to-cursor and touch support. |
| `vue-use-in-view` | **useInView** — Switch Vue state when an element enters or leaves the viewport. 0.6kb. |
| `vue-use-motion-template` | **useMotionTemplate** — Combine motion values into dynamic, interpolated strings. |
| `vue-use-motion-value-event` | **useMotionValueEvent** — Subscribe to motion value events like change and animationComplete, with auto-cleanup. |
| `vue-use-reduced-motion` | **useReducedMotion** — Adapt or disable animations based on the device's Reduced Motion setting. |
| `vue-use-scroll` | **useScroll** — Track scroll progress as motion values, for parallax and progress bars. |
| `vue-use-spring` | **useSpring** — A spring-powered motion value. Standalone, or attached to another motion value. |
| `vue-use-time` | **useTime** — A motion value that returns elapsed time in milliseconds, every frame. |
| `vue-use-transform` | **useTransform** — Map a motion value's output to a new motion value, with clamp and easing options. |
| `vue-use-velocity` | **useVelocity** — A motion value that outputs the velocity of another motion value. |
| `vue-animation` | **Vue animation** — An overview of animating Vue with motion components, variants, gestures, and keyframes. |

## AI Kit (Motion+ 付費工具)

| slug | 內容 |
|---|---|
| `ai-kit-context` | **Docs & examples for your agent** — Give your AI editor always-current Motion docs to search, plus source code for every premium example on Motion+. |
| `motionscore-code-audit` | **MotionScore for Agents** — Find and fix animation performance issues in source code and running local sites with MotionScore for Agents. |
| `ai-kit-generate-css` | **Generate CSS** — Generate CSS spring and bounce easing curves directly from your LLM via the Motion AI Kit MCP. |
| `ai-kit-transition-editor` | **Transition editor** — Edit your CSS and Motion animations visually with the Motion AI Kit. |
| `ai-kit` | **Get started with the Motion AI Kit** — Make your AI agent a Motion expert with current docs, MotionScore for Agents, examples search, CSS springs and a transition editor. |
| `ai-kit-install` | **Install the Motion AI Kit** — Install the Motion AI Kit with our easy installer script. |
