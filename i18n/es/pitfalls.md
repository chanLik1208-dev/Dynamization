# pitfalls.md — Síntoma → causa → solución

Busca el síntoma y luego lee la sección.

| Síntoma | Causa más probable |
|---|---|
| La animación de salida nunca se dispara | `AnimatePresence` se desmontó a sí mismo, o la `key` del hijo es inestable → §1 |
| La animación reinicia desde cero cada vez | el componente se está recreando (cambió la key, o `motion.create` dentro del render) → §2 |
| La animación de layout no hace nada | el elemento es `display: inline`, o no hubo re-render → §3 |
| El contenido se estira durante una animación de layout | los hijos no tienen `layout`, o el radio/sombra no están en `style` → §3 |
| Toda la página tiembla al hacer scroll | la aparición de la barra de scroll dispara una animación de layout → §3 |
| Fotogramas perdidos, tirones | animar una propiedad que dispara layout, o un pintado extenso → §4 |
| Los valores enlazados al scroll van a saltos | no pasaron por `useSpring` → §5 |
| La distancia de arrastre no coincide con el dedo | un ancestro con transform / escala → §6 |
| El hover se queda «pegado» en dispositivos táctiles | eventos de hover nativos en lugar de `hover()` / `whileHover` de Motion → §6 |
| La animación de layout de un SVG está rota | SVG no admite animaciones de layout → §7 |
| La elevación desaparece en modo oscuro | las sombras son invisibles sobre superficies oscuras → `i18n/es/contrast.md` §2 |
| El texto a mitad de animación es ilegible | contraste intermedio demasiado bajo → `i18n/es/contrast.md` §7 |

---

## 1. `AnimatePresence` y las salidas

**Tres razones por las que una salida nunca se dispara:**

```jsx
// ❌ AnimatePresence se desmonta a sí mismo y no puede animar su propia partida
{isVisible && <AnimatePresence><Component /></AnimatePresence>}

// ✅ La condición va dentro
<AnimatePresence>{isVisible && <Component />}</AnimatePresence>
```

```jsx
// ❌ index como key: reordenar rompe la asociación ítem↔key
{items.map((item, i) => <Component key={i} />)}
// ✅ un id estable y único
{items.map(item => <Component key={item.id} />)}
```

**El componente que sale debe ser hijo directo de `AnimatePresence`** para recibir `exit`. Con un
solo envoltorio que no sea motion en medio, deja de funcionar.

**`AnimatePresence` anidados**: cuando se elimina el exterior, los hijos interiores **no** ejecutan
sus salidas por defecto. Añade `propagate` al interior:
```jsx
<AnimatePresence propagate>…</AnimatePresence>
```

**Dos requisitos para `mode="popLayout"`:**
- Los hijos que sean componentes propios deben usar `forwardRef` y pasar la ref al nodo que se extrae
- El padre que anima necesita un `position` distinto de `static`: popLayout usa
  `position: absolute` internamente, y cualquier ancestro con transform se convierte en el padre de
  desplazamiento

```jsx
<motion.ul layout style={{ position: "relative" }}>
  <AnimatePresence mode="popLayout">…</AnimatePresence>
</motion.ul>
```

**Mezclar `mode="sync"` con animaciones de layout**: envuelve el grupo en `<LayoutGroup>` para que
los componentes fuera del `AnimatePresence` sepan que deben recolocarse.

---

## 2. Componentes que se recrean

```jsx
// ❌ un componente nuevo en cada render; se pierde todo el estado de animación
function Row() {
  const MotionCard = motion.create(Card)   // desastre
  return <MotionCard animate={…} />
}
// ✅ elévalo al ámbito del módulo
const MotionCard = motion.create(Card)
```

Un componente envuelto con `motion.create()` debe reenviar la `ref` al nodo DOM que realmente se
anima (React 18: `forwardRef`; React 19: `props.ref`). Sin eso, nada se mueve.

Si la animación vuelve de golpe al inicio al interrumpirse, escribe `null` como primer fotograma.
```jsx
animate={{ x: [null, 100, 0] }}
```

---

## 3. Animaciones de layout

**No pasa nada:**
- El elemento es `display: inline`: los navegadores no aplican transforms a las cajas inline. Usa
  `inline-block` / `block` / `flex`.
- No hubo re-render. Las animaciones de layout las dispara el render de React; un cambio puramente
  CSS no dispara ninguno.
- Dos componentes se afectan mutuamente el layout pero renderizan por separado → envuélvelos en
  `<LayoutGroup>`.

**Cambia el layout con `style` / `className`, no con `animate`:**
```jsx
// ❌ layout y animate se pelean
<motion.div layout animate={{ width: open ? 300 : 100 }} />
// ✅ deja que layout se ocupe
<motion.div layout style={{ width: open ? 300 : 100 }} />
```

**El contenido se estira (distorsión por escala):**
- Añade `layout` también a los hijos directos: Motion aplica el escalado inverso
- Para elementos cuya relación de aspecto cambia (imágenes, texto), usa `layout="position"`
- **`borderRadius` y `boxShadow` deben ir en `style`** para que se corrija la escala; en una clase CSS
  no se corregirán
- `border` no se puede corregir del todo (mínimo de 1px) → usa un padre con padding a modo de borde

```jsx
<motion.div layout style={{ borderRadius: 10, padding: 5, background: "#000" }}>
  <motion.div layout style={{ borderRadius: 5, background: "#fff" }} />
</motion.div>
```

**Dentro de un contenedor con scroll**: añade `layoutScroll` al contenedor.
**Dentro de `position: fixed`**: añade `layoutRoot`.

**Las animaciones de layout se desactivan durante el redimensionado horizontal de la ventana**: es
una protección de rendimiento deliberada, no un fallo.

**Temblor de página cuando aparece la barra de scroll:**
```css
body { overflow-y: auto; scrollbar-gutter: stable; }
```

**Posicionamiento relativo en animaciones de layout anidadas**: Motion calcula posiciones
**relativas al padre** (a diferencia de View Transitions, que usa coordenadas absolutas de página),
así que un hijo con `delay` nunca se queda atrás respecto a su padre. Cambia el ancla con
`layoutAnchor={{ x: 0.5, y: 0.5 }}`.

---

## 4. Rendimiento

**Siempre seguro**: `transform` (incluidos los `x` / `scale` / `rotate` independientes), `opacity`
**Dispara pintado (mídelo)**: `box-shadow`, `border-radius`, `background-color`, `filter`
**Dispara layout (evítalo)**: `width`, `height`, `top`, `left`, `margin`, `padding`, `border-width`

Sustituciones:
```js
animate(el, { boxShadow: "10px 10px black" })          // ❌ pintado
animate(el, { filter: "drop-shadow(10px 10px black)" })// ✅ compositor (Chrome/FF)

animate(el, { borderRadius: "50px" })                  // ❌
animate(el, { clipPath: "inset(0 round 50px)" })       // ✅
```
Para animar sombras en áreas grandes, usa el truco de la opacidad del pseudoelemento →
`i18n/es/recipes.md` §5.

**Una sorpresa sobre la aceleración por hardware**: los transforms independientes de Motion (`x`,
`scale`) están implementados con variables CSS y **hoy no** tienen aceleración por hardware. Con el
hilo principal ocupado pueden dar tirones. Cuando de verdad importe, escribe la cadena completa:
```js
animate(".box", { transform: "translateX(100px) scale(2)" })
```
Chrome también pasó mucho tiempo negándose a acelerar transforms basados en `%`.

**Sé moderado con las pistas de capa**: cada `will-change: transform` cuesta memoria de GPU. Añádelo
solo a elementos que hayas medido.

**Animación de texto**: dividir el texto infla el DOM (un coste puntual), pero actualizar `innerText`
en cada fotograma dispara recálculo de layout **continuo**. Usa una fuente monoespaciada para efectos
de scramble y `contain: layout` para máquinas de escribir. **El desenfoque por carácter es una trampa
de rendimiento**: capas pequeñas ampliadas por el desenfoque se solapan y cuestan mucho más GPU que
un solo desenfoque sobre todo el bloque.

---

## 5. Scroll

- La entrada de scroll es discreta; enlazar `scrollYProgress` directamente a un estilo produce
  escalones. Pásala siempre por `useSpring`.
- Al aplicar un muelle a un valor de scroll, añade `skipInitialAnimation: true` para evitar un barrido
  desde 0 al montar.
- Fija con CSS `position: sticky`, nunca mutando `top` desde JS.
- `whileInView` sin `once: true` se repite constantemente; el valor por defecto `amount: "some"`
  (un píxel) suele ser demasiado pronto: usa `0.3`.
- El `offset` de `useScroll` es `[inicio, fin]`, cada uno escrito como
  `"<posición del target> <posición del container>"`. `"start end"` significa *la parte superior del
  target toca la inferior del contenedor*.

---

## 6. Gestos

**La distancia de arrastre no sigue al puntero** → un ancestro con transform o escala. Cualquier
ancestro con un transform cambia el sistema de coordenadas. `transformPagePoint` de `MotionConfig`
puede corregir un zoom de página completa.

**Animaciones de layout que se portan mal dentro de un padre escalado** → misma causa.

**Imagen fantasma del navegador al arrastrar una imagen** → añade `draggable={false}` o el CSS
`-webkit-user-drag: none`.

**El hover se queda «pegado» en dispositivos táctiles** → los navegadores emulan eventos de hover
para el táctil. Usa `whileHover` / `hover()`, que filtran los falsos. No enlaces `mouseenter` a mano.

**Pan / drag que no responde o pelea con el scroll en táctil** → necesitas el CSS `touch-action`:
```css
.draggable-x { touch-action: pan-y; }   /* arrastre horizontal, vertical para el scroll */
.draggable   { touch-action: none; }
```

**El clic de un hijo se lo traga un gesto del padre**:
```jsx
<button onPointerDownCapture={e => e.stopPropagation()} />  {/* componente React normal */}
<motion.button propagate={{ tap: false }} />                 {/* componente motion, de momento solo tap */}
```
El manejo de gestos de Motion es diferido, así que llamar a `e.stopPropagation()` dentro de
`onTapStart` llega tarde.

**El tap dentro de un elemento arrastrable** se cancela automáticamente en cuanto el puntero se mueve
más de 3px.

---

## 7. SVG

- **SVG no admite animaciones de layout** (SVG no tiene sistema de layout). Anima atributos
  directamente (`cx`, `x`, `width`…) o el `viewBox`.
- Los elementos `filter` de SVG (`feGaussianBlur`, etc.) **no reciben eventos**. Pon `whileHover` en
  el `<motion.svg>` padre y acciona los hijos del filtro mediante variants.
- El trazado de líneas usa `pathLength` / `pathSpacing` / `pathOffset` (0–1) sobre `circle` `ellipse`
  `line` `path` `polygon` `polyline` `rect`.

---

## 8. Usos incorrectos habituales

| Escrito como | Problema | Debería ser |
|---|---|---|
| `import { motion } from "framer-motion"` | nombre de paquete antiguo | `"motion/react"` |
| `transition={{ type: "spring", duration: .3, stiffness: 200 }}` | fijar `stiffness` deja inertes `duration`/`bounce` | elige un sistema |
| `spring({ duration: 0.3 })` | llamar a `spring()` directamente usa **milisegundos** | `spring({ duration: 300 })` |
| `useTransform` dentro de `.map()` | viola las reglas de los hooks | extrae un componente hijo, o usa la forma de función |
| Objeto `animate` nuevo en cada render | con valores iguales no se reproduce, pero la comparación cuesta igual | `useMemo` o variants |
| Encadenar animaciones con `setTimeout` | no se puede cancelar y se desfasa | una secuencia o `delayChildren` |
| Apoyar lógica crítica en `onAnimationComplete` | no se dispara si hay interrupción | gobiérnalo con estado; la animación es presentación |
| `import { motion } from "motion/react"` en un RSC | necesita un límite de cliente | `import * as motion from "motion/react-client"`, o añade `"use client"` |

---

## 9. Lista de comprobación antes de entregar

- [ ] ¿Hay un `<MotionConfig reducedMotion="user">` para todo el sitio? ¿El parallax y la reproducción automática tienen su propia rama?
- [ ] ¿Todos los `whileInView` tienen `once: true`?
- [ ] ¿Estás animando `width` / `height` / `top` / `left` en algún sitio donde debería usarse `layout`?
- [ ] ¿Las keys de `AnimatePresence` son estables y únicas, con la condición dentro?
- [ ] ¿La salida dura 0.5–0.7× la entrada?
- [ ] ¿Has hecho la cuenta del stagger (intervalo × cantidad ≤ 0.5s)?
- [ ] **¿Lo has mirado en modo oscuro?** ¿Se ve la elevación? ¿Y el anillo de foco?
- [ ] ¿Lo has ejecutado una vez en un dispositivo de gama baja, o con la CPU limitada 4×?
- [ ] ¿El texto dividido lleva `aria-label` en el contenedor y `aria-hidden` en los fragmentos?
- [ ] ¿Hay algún estado transmitido solo por luminancia, o solo por animación?
