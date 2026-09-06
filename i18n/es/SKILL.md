# Dynamization (Español)

> Esta es la versión en español de `SKILL.md`. El canon en inglés está en el `SKILL.md` de la raíz
> del repositorio. Las referencias de API (react / javascript / vue / doc-index) existen solo en
> inglés, en `references/`.

> El movimiento es el lenguaje del **tiempo**: de dónde vino algo, adónde fue, si ya se puede tocar.
> La luminancia es el lenguaje del **espacio**: qué está encima, qué está vivo, dónde mirar ahora.
>
> Por separado, cada uno hace la mitad del trabajo. «Elevarse» no es mover algo 4px hacia arriba: es
> **desplazamiento + una sombra más grande y difusa + una superficie más clara, todo a la vez.**
> Solo entonces el cerebro lo lee como *eso se acercó a mí*.
>
> Las interfaces que se sienten «rígidas» o «planas» casi nunca sufren de una curva poco elegante.
> Violan la intuición física, o cambian una sola propiedad donde deberían cambiar tres.

## 1. Primero elige el runtime

| Situación | Usa | Import |
|---|---|---|
| React / Next.js | Motion for React | `npm i motion` → `import { motion } from "motion/react"` |
| React Server Component | igual, otra ruta | `import * as motion from "motion/react-client"` |
| Vue / Nuxt | Motion for Vue | `npm i motion-v` → `import { motion } from "motion-v"` |
| JS puro / Webflow / Astro | vanilla | `npm i motion` → `import { animate } from "motion"` |
| Solo un cambio de color en hover | **CSS puro**, sin librería | — |
| Curvas de muelle sin librería | genera `linear()` de CSS | `i18n/es/recipes.md` §muelles CSS |

**Pregúntate primero si necesitas una librería.** Para un elemento, un estado y sin necesidad de
interrupción, una `transition` de CSS basta. Motion se gana sus bytes con la interrumpibilidad, el
traspaso de velocidad, las animaciones de layout, los gestos, la orquestación y el enlace con el
scroll. Si no usas ninguno de esos, no envíes 18kb.

## 2. Cinco reglas de oro

Supéralas todas antes de escribir cualquier animación. Romper una produce un resultado que se siente
*mal* de una manera que la gente normalmente no sabe nombrar.

### 1. Muelles para posición y tamaño; tweens para opacidad y color

Esto no es cuestión de gusto. Es la propia lógica por defecto de Motion, verificada en el código
fuente de `motion-dom`:

| Qué se anima | Qué te da Motion |
|---|---|
| `x` `y` `rotate` `skew` y otros transforms | spring, `stiffness: 500, damping: 25` (ligero rebote) |
| la familia `scale` | spring, `stiffness: 550, damping: 30` (amortiguamiento crítico, **sin rebote**) |
| `opacity` `color` `filter` y todo lo demás | tween, `ease: [0.25, 0.1, 0.35, 1]`, `duration: 0.3` |
| tres o más fotogramas clave | tween, `duration: 0.8` |

Por qué: lo que ocupa espacio (posición, tamaño) el cerebro lo lee como **objetos**, y los objetos
tienen masa e inercia. La opacidad y el color no son objetos —son solo *si se ve o no*—, así que un
muelle allí se lee como un parpadeo.

**Corolario: nunca hagas rebotar un `scale`.** El crecimiento con rebote se lee como chocar contra un
cristal. Por eso exactamente Motion amortigua críticamente la escala.

### 2. Las animaciones deben poder interrumpirse, y arrastrar la velocidad al hacerlo

La regla más importante y la que más se pasa por alto. Cambiar de opinión a mitad de una animación es
comportamiento humano normal.

- Usa un muelle: Motion arrastra la velocidad actual automáticamente, así que una inversión no frena
  en seco. **Esta —y no lo rebotón— es la verdadera razón por la que los muelles superan a los tweens.**
- Con fotogramas clave, escribe `null` como primer fotograma: `animate={{ x: [null, 100, 0] }}` —
  continúa desde el **valor actual** en lugar de saltar de vuelta al inicio.
- Nunca encadenes animaciones con `setTimeout`. Usa una secuencia (`animate([...])`) o la
  orquestación de variants (`when` / `delayChildren`): eso se puede cancelar como una unidad.
- La View Transitions API **no** es interrumpible (interrumpirla salta al estado final). Si necesitas
  interrupción, usa `layout` de Motion.

### 3. La entrada y la salida no son simétricas

Nadie debería esperar por algo que se está yendo.

```jsx
// Entrada: más lenta, easeOut (rápido y luego asentándose, como deslizarse y detenerse)
initial={{ opacity: 0, y: 8 }}
animate={{ opacity: 1, y: 0, transition: { duration: 0.25, ease: "easeOut" } }}
// Salida: rápida, easeIn (lento y luego acelerando al irse)
exit={{ opacity: 0, y: 4, transition: { duration: 0.15, ease: "easeIn" } }}
```

La salida dura aproximadamente **0.5–0.7×** lo que la entrada, y recorre **menos distancia**. Un
elemento que se va no necesita recorrer todo el camino: el ojo solo necesita saber que se fue.

### 4. Escalones de tiempo: cada trabajo tiene su presupuesto

| Escalón | Duración | Dónde | Curva |
|---|---|---|---|
| Respuesta inmediata | `0.1–0.15s` | escala al pulsar, checkbox, anillo de foco | `easeOut` o un muelle |
| Microinteracción | `0.15–0.25s` | hover, tooltip, color de botón | `easeOut` |
| Transición de componente | `0.25–0.4s` | desplegable, modal, acordeón, layout | spring, `visualDuration: 0.3` |
| Página / narrativa | `0.4–0.8s` | cambio de ruta, hero, multi-fotograma | spring o tween + stagger |
| Más de `1s` | casi seguro está mal | solo carga, ambiente, enlace con scroll | — |

Las animaciones de hover **no deben pasar de 0.2s**: el cursor puede haberse ido ya.
Distancias mayores pueden durar algo más, pero **no linealmente**: el doble de distancia compra
alrededor de un 20–30% más de tiempo, no el 100%.

> Razonamiento completo, la semántica humana de los parámetros del muelle, ritmo de orquestación,
> antipatrones → `i18n/es/feel.md`

### 5. Un mismo suceso debe cambiar varias propiedades en la misma dirección

Una sola propiedad transporta demasiada poca información. **Varias propiedades moviéndose juntas es
lo que el cerebro lee como un único suceso físico.**

| Para expresar | Cambia al menos |
|---|---|
| Elevación / acercamiento (hover de tarjeta) | `y` hacia arriba + sombra más grande y difusa + superficie más clara |
| Pulsación / hundimiento | `scale` menor + sombra que se contrae + sombra interior + más oscuro |
| Levantado (arrastrando) | `scale` mayor + sombra amplia + z elevado |
| Foco (modal abriéndose) | el contenido entra + **el fondo se oscurece** (el velo debe llegar primero) |
| Deshabilitado | un token de color de bajo contraste dedicado (**no** `opacity: 0.5`) |

La luminancia es una *señal de estado*; el desplazamiento es un *proceso*. Por eso **la luminancia
cambia más rápido que el movimiento** (en torno a `0.12–0.15s` frente a `0.2–0.35s`).

En temas oscuros las sombras son casi invisibles, así que la elevación debe expresarse con
*superficies más claras*. Cambiar de tema intercambia el mecanismo, no solo la paleta.

> El modelo óptico, los tokens para tema claro y oscuro, el coste de animar cada propiedad de
> luminancia, los mínimos de accesibilidad → `i18n/es/contrast.md`

## 3. Tabla de enrutamiento

Lee el archivo del trabajo que tienes delante. **No los leas todos.**

| Lo que estás haciendo | Lee |
|---|---|
| Entender qué significa «natural»; no logras el efecto; te dijeron que es «rígido» | `i18n/es/feel.md` ← **el eje del tiempo** |
| Elevación, sombra, modo oscuro, foco, velo, contraste | `i18n/es/contrast.md` ← **el eje del espacio** |
| Escribir React: props, hooks, componentes | `references/react.md` (inglés) |
| Escribir JS puro: `animate()`, `scroll()`, motion values | `references/javascript.md` (inglés) |
| Escribir Vue, o portar un ejemplo de React | `references/vue.md` (inglés) |
| Quieres un efecto terminado para pegar | `i18n/es/recipes.md` |
| No anima, da saltos, se traba, `exit` no dispara, el layout se deforma | `i18n/es/pitfalls.md` |
| Necesitas el texto oficial, o una API que no está aquí | `references/doc-index.md` + §6 |

## 4. La accesibilidad no es opcional

Todo lo que **mueva o escale un elemento grande** debe atender reduced motion. Una línea para todo
el sitio:

```jsx
import { MotionConfig } from "motion/react"
<MotionConfig reducedMotion="user">{children}</MotionConfig>
```

`reducedMotion="user"` desactiva automáticamente las animaciones de transform y layout mientras
**conserva** la opacidad y el color: exactamente lo que hace iOS. Sigue diciéndole al usuario que la
pantalla cambió; simplemente hace un fundido cruzado en lugar de deslizar.

Para control fino usa `useReducedMotion()` (mismo nombre en Vue). El parallax, el vídeo con
reproducción automática y los bucles infinitos siempre necesitan una rama explícita.

## 5. Líneas rojas de rendimiento

Solo `transform` y `opacity` llegan al compositor en todos los navegadores. Esas son siempre seguras.

- ❌ Animar `width` / `height` / `top` / `left` / `margin` / `border-width` dispara layout: perderá fotogramas
- ⚠️ `box-shadow` / `border-radius` / `background-color` disparan pintado: bien en elementos pequeños, mide en los grandes
- ✅ Para sombras animadas usa `filter: drop-shadow(...)`; para esquinas animadas usa `clip-path: inset(0 round Npx)`
- ✅ Para animar tamaño o posición usa la prop `layout`: Motion lo implementa con transforms, y esa es una de las principales razones por las que la librería existe
- ⚠️ Los transforms independientes de Motion (`x`, `scale`) se apoyan en variables CSS y **no** tienen aceleración por hardware. Cuando importe, escribe `transform: "translateX(100px) scale(2)"`

## 6. Obtener el texto oficial actual

El sitio de documentación admite negociación de contenido, así que la fuente autorizada está siempre
a un comando de distancia (y será más reciente que este paquete):

```bash
curl -sL -H "Accept: text/markdown" https://motion.dev/docs/<slug>
# p. ej. https://motion.dev/docs/react-transitions
```

O `scripts/fetch-doc.sh react-transitions`. Todos los slugs están en `references/doc-index.md`.

**Donde este paquete y la documentación oficial discrepen, gana el texto oficial** — con una
excepción conocida: las páginas de la documentación indican que el valor por defecto de `stiffness`
del muelle es `1`, y eso es **incorrecto**. El código fuente dice `100`. Seguir la documentación ahí
te da un muelle que apenas se mueve.
