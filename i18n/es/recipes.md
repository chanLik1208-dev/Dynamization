# recipes.md — Patrones listos para usar

Cada receta declara su **intención**. Lee esa línea antes de cambiar parámetros, para comprobar que
quieres lo mismo que ella quiere.

Ninguna depende de componentes de pago de Motion+; donde un efecto normalmente necesita uno, se
ofrece un reemplazo autónomo.

Sintaxis de React en todo el archivo; para Vue, ver `references/vue.md` §7.

---

## 0. Los cimientos

> Intención: un carácter consistente en todo el producto.

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
// raíz de la app
import { MotionConfig } from "motion/react"
import { T } from "./motion.tokens"

<MotionConfig transition={T.enter} reducedMotion="user">
  <App />
</MotionConfig>
```

---

## 1. Entrada de un elemento

> Intención: que el contenido nuevo **llegue**, no que entre volando.

```jsx
<motion.div
  initial={{ opacity: 0, y: 8 }}
  animate={{ opacity: 1, y: 0 }}
  transition={T.enter}
/>
```
`8px` de recorrido. Sube a `12–16px` si lo quieres más marcado, pero **nunca pases de 24px**.

---

## 2. Stagger de lista

> Intención: darle al ojo un orden de lectura.

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
**Haz la cuenta primero**: `0.04 × cantidad + 0.3` debe quedar por debajo de `0.8s`. Si no, reduce el
intervalo.

---

## 3. Aparición disparada por scroll

> Intención: que el contenido aparezca al ritmo de la lectura, sin interrumpir el scroll.

```jsx
<motion.section
  initial={{ opacity: 0, y: 16 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.3 }}
  transition={T.enter}
/>
```
`once: true` es prácticamente obligatorio.

---

## 4. Botón: movimiento y luminancia juntos

> Intención: pulsable → pulsado. **Dos propiedades en la misma dirección son las que crean la
> sensación de objeto físico** (ver `i18n/es/contrast.md` §4).

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

## 5. Elevación de tarjeta en hover (que sobrevive a una lista larga)

> Intención: acercarse al usuario. La sombra pasa por la opacidad de un pseudoelemento en lugar de
> animar `box-shadow` directamente.

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

## 6. Modal (velo + contenido)

> Intención: el mundo se atenúa; solo queda esto.

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
El velo aterriza primero (`0.2s`), el contenido después (`0.28s`) — ver `i18n/es/contrast.md` §5.

---

## 7. Tarjeta que se expande en modal (elemento compartido)

> Intención: esto no es una ventana nueva, es el mismo objeto agrandado. **La declaración de
> causalidad más fuerte disponible.**

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
- El `layoutId` debe ser idéntico y único entre los dos elementos.
- El contenido que solo existe dentro aparece `0.15s` después, cuando el marco ya se ha asentado.
- Pon `borderRadius` en `style` (no en una clase CSS) para que se aplique la corrección de escala.

---

## 8. Desplegable / popover (nacido del disparador)

> Intención: esto salió de ese botón.

```jsx
<AnimatePresence>
  {open && (
    <motion.div
      style={{ transformOrigin: "top left" }}   // apunta al disparador
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
`transformOrigin` debe seguir la dirección de apertura (`bottom left` cuando se abre hacia arriba).

---

## 9. Acordeón (animación de altura sin castigar el layout)

> Intención: el contenido abre espacio a empujones y todo lo demás cede.

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
Envuelve varios acordeones que se afecten mutuamente en `<LayoutGroup>`.
Usa `layout="position"` en el encabezado para que el texto no lo estire la escala.

---

## 10. Subrayado de pestañas (se desliza, no parpadea)

> Intención: un subrayado que se mueve, no dos que se alternan.

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
Con varios juegos de pestañas en una página, aísla el espacio de nombres del `layoutId` con
`<LayoutGroup id="tabs-a">`.

---

## 11. Pila de toasts

> Intención: llegar desde la esquina donde va a quedarse; apartarse al irse.

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
`mode="popLayout"` saca del flujo al toast que se va para que el resto se cierren de inmediato.
El contenedor necesita `position: relative` (popLayout usa absolute internamente).

---

## 12. Arrastrar para reordenar

> Intención: se puede coger, y se puede soltar.

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
Arrastre libre:
```jsx
<motion.div drag dragConstraints={boxRef} dragElastic={0.2}
            whileDrag={{ scale: 1.04 }}
            dragTransition={{ power: 0.2, modifyTarget: v => Math.round(v / 50) * 50 }} />
```
`modifyTarget` ajusta a una rejilla.

---

## 13. Barra de progreso de scroll

```jsx
const { scrollYProgress } = useScroll()
const scaleX = useSpring(scrollYProgress, { stiffness: 100, damping: 30, restDelta: 0.001 })
<motion.div style={{ scaleX, originX: 0, position: "fixed", top: 0, left: 0, right: 0, height: 3 }} />
```

## 14. Parallax

> Intención: profundidad, no un fondo a la deriva.

```jsx
const ref = useRef(null)
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] })
const bgY = useTransform(scrollYProgress, [0, 1], ["-12%", "12%"])   // amplitud contenida
const prefersReduced = useReducedMotion()

<div ref={ref}>
  <motion.img style={{ y: prefersReduced ? 0 : bgY }} />
</div>
```
**El parallax debe ramificar según reduced motion.**

## 15. Sección de scroll horizontal

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
Cuanto más alto el contenedor exterior, más lento se siente el scroll horizontal.

## 16. Revelado de imagen con scroll

```jsx
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "center center"] })
const clipPath = useTransform(scrollYProgress, [0, 1],
  ["inset(0% 50% 0% 50%)", "inset(0% 0% 0% 0%)"])
<motion.div ref={ref} style={{ clipPath }}><img src="…" /></motion.div>
```

---

## 17. Texto dividido (reemplazo gratuito de `splitText`)

> Intención: que el texto llegue con ritmo. **La accesibilidad tiene que sobrevivir.**

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
Cinco detalles que no son opcionales:
1. **El contenedor lleva la cadena original en `aria-label` y todos los fragmentos son
   `aria-hidden`** — si no, un lector de pantalla lo deletrea letra a letra.
2. Los fragmentos necesitan `display: inline-block`; los transforms no se aplican a cajas inline.
3. Por carácter (`text.split("")`) solo para titulares cortos. Los textos largos deben ir por palabra
   o el DOM explota.
4. Si divides al montar, espera a `document.fonts.ready` antes de medir los saltos de línea.
5. Si se recortan los descendentes, añade `padding-bottom: .15em` con un `margin-bottom: -.15em`
   correspondiente.

## 18. Revelado palabra a palabra con scroll

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
La última palabra empieza en `0.8` y termina en `1.0`, de modo que el revelado acaba antes que el
scroll.

## 19. Máquina de escribir con ritmo humano (reemplazo gratuito de `Typewriter`)

> Intención: que parezca una persona escribiendo. **Los intervalos regulares se leen como un robot;
> esa es toda la diferencia.**

```jsx
function Typewriter({ text, cps = 22 }) {
  const [n, setN] = useState(0)
  const reduced = useReducedMotion()
  useEffect(() => {
    if (reduced) { setN(text.length); return }
    if (n >= text.length) return
    const ch = text[n]
    const base = 1000 / cps
    // ritmo humano: rápido dentro de la palabra, más lento en los límites, pausa real tras la puntuación, más jitter
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
`contain: layout` acota el reflujo. El cursor parpadea como una onda cuadrada mediante `times`, no
como un fundido.

## 20. Número animado (reemplazo gratuito de `AnimateNumber`)

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
`tabular-nums` es obligatorio: sin él, el ancho cambiante de los dígitos hace temblar el layout.

---

## 21. Trazado de líneas SVG

```jsx
<motion.path d="…" fill="none" stroke="currentColor"
  initial={{ pathLength: 0 }} animate={{ pathLength: 1 }}
  transition={{ duration: 1.2, ease: "easeInOut" }} />
```
Compatible con `circle` `ellipse` `line` `path` `polygon` `polyline` `rect`.
`pathSpacing` y `pathOffset` (ambos 0–1) producen guiones en marcha.

---

## 22. Brillo de esqueleto

> Intención: «sigue cargando». **Bajo contraste, periodo lento, sin competir por la atención.**

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
Mantén `--surface-3` cerca de `--surface-2` (unos 4–6% de diferencia de luminosidad en tema claro;
aún menos en oscuro). Con reduced motion, quédate en el color base plano.

---

## 23. Transición de página (Next.js App Router)

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
`mode="wait"` más `easeOut` al entrar / `easeIn` al salir se componen en un `easeInOut` global.
Mantén toda la transición por debajo de `0.4s` o la navegación empieza a sentirse lenta.

---

## 24. Muelles en CSS (sin librería en tiempo de ejecución)

```js
import { spring } from "motion"
console.log(spring(0.4, 0.2))   // visualDuration=0.4s, bounce=0.2
// → "400ms linear(0, 0.009, 0.036, …, 1.02, 1.005, 1)"
```
Calcúlalo en tiempo de compilación y pégalo en el CSS:
```css
.card { transition: scale 400ms linear(0, 0.009, …, 1); }
.card:hover { scale: 1.03; }
@supports not (transition-timing-function: linear(0, 1)) {
  .card { transition-timing-function: cubic-bezier(.2,.8,.2,1); }
}
```
Cero JS en tiempo de ejecución: ideal para RSC, Astro y sitios estáticos.

---

## 25. Ramificar según reduced motion

```jsx
const reduced = useReducedMotion()

// sustituir el desplazamiento por un fundido simple
const variants = reduced
  ? { hidden: { opacity: 0 }, show: { opacity: 1 } }
  : { hidden: { opacity: 0, y: 16 }, show: { opacity: 1, y: 0 } }

<video autoPlay={!reduced} />
<motion.div style={{ y: reduced ? 0 : parallaxY }} />
```
`<MotionConfig reducedMotion="user">` cubre el caso general del sitio desactivando las animaciones de
transform y layout mientras conserva opacidad y color. El parallax, la reproducción automática y los
bucles infinitos siguen necesitando una rama explícita.
