# feel.md — Qué hace que el movimiento se lea como real

Este archivo no trata de APIs. Trata de *por qué esa animación parece falsa*.

Ordenado aproximadamente según lo mucho que cada problema rompe la ilusión: **arregla los primeros;
los detalles posteriores solo importan una vez que aquellos están bien.**

---

## 0. El principio en una línea

> Una animación debe permitir que la gente sepa qué pasó **sin pensar en ello**.
> El usuario no debería notar la animación. Debería notar *que la cosa vino de ahí*.

Cualquier animación que haga que la gente se detenga a *admirarla* es, en un producto, casi siempre
demasiado larga.

---

## 1. Los valores por defecto de Motion ya son un criterio calibrado

Cuando no estés seguro de qué parámetros usar, **no escribas nada**. Motion elige su valor por
defecto según *qué tipo de valor se anima*, y esa lógica es en sí misma la respuesta.

Los números de abajo vienen del código fuente de `motion-dom`, `getDefaultTransition()` — no de las
páginas de documentación, cuyos valores por defecto de muelle son incorrectos:

```js
// tres o más fotogramas clave
{ type: "keyframes", duration: 0.8 }

// transforms, excluyendo scale: x / y / z / rotate* / skew*
{ type: "spring", stiffness: 500, damping: 25, restSpeed: 10 }   // subamortiguado, ligero rebote

// scale / scaleX / scaleY
{ type: "spring", stiffness: 550, damping: 30, restSpeed: 10 }   // amortiguamiento crítico, sin rebote
// caso especial: cuando el destino es 0, damping = 2*sqrt(550) ≈ 46.9
// (una parada más dura, para que encogerse hasta cero no tiemble)

// todo lo demás: opacity / color / backgroundColor / filter / width ...
{ type: "keyframes", ease: [0.25, 0.1, 0.35, 1], duration: 0.3 }
// esa curva es una versión más suave del ease por defecto del navegador:
// menos abrupta al principio, igual de suave al final
```

**Tres conclusiones que se leen directamente de esa tabla:**

1. Lo que ocupa espacio (posición, tamaño) → muelle. Lo que no (opacidad, color) → tween.
2. Crecer y encoger **no debería rebotar**. Moverse sí puede.
3. La duración por defecto es de solo `0.3s`. Si la tuya es mayor, necesitas una razón.

Los valores por defecto de la propia función `spring()` (`springDefaults`):
`stiffness: 100, damping: 10, mass: 1, velocity: 0, duration: 800ms, bounce: 0.3, visualDuration: 0.3s`

---

## 2. El verdadero valor de un muelle es el traspaso de velocidad, no lo rebotón

Casi todo el mundo piensa que muelle = rebotón. Falso. La propiedad que más importa en Motion es que
**cuando una animación se interrumpe, continúa desde la posición actual a la velocidad actual**, en
lugar de detenerse en seco y empezar de nuevo.

Esta es la línea entre *se siente como un objeto* y *se siente como una presentación de diapositivas*.

```jsx
// El usuario alterna rápidamente → un tween se reinicia de golpe cada vez y se lee como tartamudeo
<motion.div animate={{ x: open ? 200 : 0 }} transition={{ duration: 0.3 }} />

// Un muelle arrastra la velocidad; alternar rápido se siente como empujar algo con inercia
<motion.div
  animate={{ x: open ? 200 : 0 }}
  transition={{ type: "spring", visualDuration: 0.3, bounce: 0.2 }}
/>
```

**La prueba: ¿esta animación la dispara una acción directa del usuario?**

| Disparador | Usa | Por qué |
|---|---|---|
| Arrastre, deslizamiento, gesto, seguimiento del cursor | **muelle** (obligatorio) | hay velocidad real que arrastrar |
| Movimiento o escalado causado por clic / hover | **muelle** | puede interrumpirse repetidamente |
| Cambio de layout causado por un interruptor | **muelle** | igual |
| Fundidos de entrada / salida | **tween** | no hay velocidad que arrastrar; importa más el control del tiempo |
| Cualquier cosa que deba cuadrar en el tiempo (stagger, secuencia, vídeo) | **tween** | los muelles no tienen un final fiable |
| Enlace con el scroll | enlaza el valor y suaviza con `useSpring` | ver §7 |

---

## 3. Ajusta los muelles con `bounce` + `visualDuration`, nunca con `stiffness` / `damping`

Nadie puede imaginarse el resultado de `stiffness: 400, damping: 32, mass: 1.2`. Solo puedes adivinar
y volver a adivinar. Usa los dos parámetros que tienen significado humano:

```jsx
transition={{
  type: "spring",
  visualDuration: 0.3,  // segundos. Cuánto tarda en *parecer* que llegó (sin la cola rebotona)
  bounce: 0.2,          // 0 = sin rebote, 1 = extremadamente rebotón
}}
```

`visualDuration` existe exactamente para esto: **el grueso del movimiento termina dentro de ese
tiempo, y la cola rebotona ocurre después.** Por eso puede alinearse con la `duration` de un tween, y
por eso `duration` + muelle no puede.

**Qué significan los valores de bounce:**

| bounce | Sensación | Dónde |
|---|---|---|
| `0` | nítido, profesional, con peso | UI empresarial, tablas de datos, paneles, **cualquier `scale`** |
| `0.1 – 0.2` | vivo pero contenido | **la respuesta correcta la mayoría de las veces**: botones, tarjetas, menús |
| `0.3 – 0.4` | juguetón, de juguete | apps de consumo, gamificación, respuesta de éxito |
| `> 0.5` | teatral | solo cuando se busca deliberadamente el humor o captar la atención |

**Dos reglas firmes:**
- `scale` siempre con `bounce: 0`. El crecimiento con rebote se lee como chocar contra un cristal.
- Mantén el bounce consistente en una misma pantalla. Mezclarlos hace que la interfaz parezca
  ensamblada a partir de piezas sueltas.

> Establecer cualquiera de `stiffness` / `damping` / `mass` deja `bounce` y `duration`
> **completamente inertes**. No mezcles los dos sistemas.

---

## 4. Causalidad: las cosas vienen de donde vinieron

Rompe esto y ningún pulido de curvas lo salvará.

- Un desplegable se abre **desde el botón que lo abrió**, no apareciendo en el centro de la pantalla.
  Apunta `transformOrigin` al botón.
- Un modal crece desde la tarjeta en la que se hizo clic: usa `layoutId` para un elemento compartido,
  no un fundido.
- Una barra lateral entra deslizándose **desde su propio lado**, no desde abajo.
- Borrar un ítem de una lista hace que los demás **cierren el hueco** (prop `layout`), no que salten.
- Un toast entra desde la esquina en la que va a quedarse.

```jsx
// ❌ Se materializa de la nada
<motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} />

// ✅ Crece desde el botón
<motion.div
  style={{ transformOrigin: "top left" }}
  initial={{ opacity: 0, scale: 0.95, y: -4 }}
  animate={{ opacity: 1, scale: 1, y: 0 }}
/>

// ✅✅ Se convierte de verdad en ese elemento
<motion.button layoutId="card-3" />
{open && <motion.div layoutId="card-3" />}
```

**Sentido de la escala para las distancias:** microinteracciones `4–12px`, transiciones de componente
`16–40px`, porcentajes solo para movimientos a pantalla completa.

Aparecer desde `y: 100` es el error más común que existe: para un tooltip, esa distancia se lee como
*llegar desde otra habitación*.

---

## 5. Entrada y salida asimétricas

| | Entrada | Salida |
|---|---|---|
| Duración | `0.2 – 0.35s` | **0.5 – 0.7×** la entrada |
| Curva | `easeOut` / muelle | `easeIn` |
| Distancia | completa | **la mitad o menos** |
| Escala inicial | `0.95` (no `0`) | `0.98` (apenas encoge) |

La razón: al entrar, el usuario tiene que *atrapar* información nueva y necesita tiempo para
ubicarla. Al salir, la cosa ya le es irrelevante, y hacerle esperar le hace perder el tiempo.

`easeOut` al entrar y `easeIn` al salir se componen en un `easeInOut` a lo largo de toda la
experiencia: precisamente lo que la documentación oficial recomienda emparejar con
`AnimatePresence mode="wait"`.

Nunca entres desde `scale: 0`. Eso significa *de la nada al ser*, pero los elementos de UI casi
siempre vienen *de otro sitio*. `0.95` basta y sobra para decir «esto apareció».

---

## 6. Orquestación: el stagger es ritmo, no decoración

Diez cosas que aparecen a la vez se leen como una masa. Escalónalas y obtienes orden, y dirección.

```jsx
const list = {
  show: { transition: { delayChildren: stagger(0.04) } },
  hide: { transition: { delayChildren: stagger(0.02, { from: "last" }) } },
}
```

**Elegir el intervalo:**

| Nº de elementos | Intervalo | Presupuesto total |
|---|---|---|
| 3–6 (menú, fila de tarjetas) | `0.04 – 0.06s` | ≤ 0.35s |
| 7–15 (lista) | `0.02 – 0.04s` | ≤ 0.5s |
| Por carácter | `0.02 – 0.03s` | según la longitud; pasado 1s cambia a por palabra |
| > 20 | no escalones individualmente | agrúpalos, o funde el conjunto |

**El total es un techo estricto.** `stagger(0.1)` con 20 elementos son 2 segundos: para cuando aterriza
el último, el usuario ya está en otra cosa. Haz la cuenta antes de escribirlo.

**La dirección debe significar algo:**
- `from: "first"` (por defecto) — de arriba abajo, coincide con el orden de lectura, la opción segura
- `from: "last"` — al plegar, para que parezca enrollarse de vuelta
- `from: "center"` — abriéndose hacia fuera, ceremonial, bueno para un hero
- `from: <index>` — irradiando desde el ítem que el usuario acaba de tocar ← **la declaración de causalidad más fuerte disponible**

`when: "beforeChildren"` / `"afterChildren"`: el contenedor debe abrirse antes de que entre el
contenido (entrada), y el contenido debe salir antes de que el contenedor se cierre (salida).

---

## 7. Scroll: lo enlazado se suaviza, lo disparado ocurre una sola vez

**Disparado por scroll (se reproduce al entrar en el viewport)**
```jsx
<motion.div
  initial={{ opacity: 0, y: 12 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.3 }}
/>
```
`once: true` es **casi siempre correcto**. Las animaciones que se repiten cada vez que el usuario
sube y baja marean, y la segunda reproducción no aporta información alguna.

`amount: 0.3` dispara cuando es visible el 30%: el valor por defecto `"some"` (un píxel) es demasiado
pronto y termina mientras el elemento aún está en el borde de la pantalla.

**Enlazado al scroll (valor atado a la posición del scroll)**
```jsx
const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] })
const smooth = useSpring(scrollYProgress, {
  stiffness: 100, damping: 30, restDelta: 0.001, skipInitialAnimation: true,
})
```
La entrada de scroll es discreta, así que enlazarla directamente produce escalones visibles.
**Pasarla por `useSpring` es obligatorio, no un extra.**
`skipInitialAnimation: true` evita un barrido desde 0 hasta la posición actual al montar.

**Amplitud del parallax**: una capa de fondo que se mueva a `0.3–0.5×` la del primer plano es más que
suficiente. Más que eso deja de leerse como profundidad y empieza a leerse como *el fondo va a la
deriva*.

El parallax es lo primero que hay que desactivar con reduced motion.

---

## 8. La respuesta a un gesto debe empezar en menos de 100ms

La respuesta al toque y al clic es una **señal de confirmación**, no una animación.

```jsx
<motion.button
  whileHover={{ scale: 1.03 }}                 // apenas. 1.1 es un cartel, no un botón
  whileTap={{ scale: 0.97 }}                   // pulsar encoge, no agranda
  transition={{ type: "spring", visualDuration: 0.15, bounce: 0 }}
/>
```

- **Pulsar = más pequeño.** Un dedo que aprieta debería hundir la cosa. Agrandar es la física
  equivocada.
- Limita la escala de hover a `1.05`; más allá, los elementos vecinos parecen apartados a empujones.
- Los elementos grandes (tarjetas, paneles) necesitan una escala de hover *menor* (`1.01–1.02`),
  porque el desplazamiento real = escala × tamaño, así que la misma proporción mueve mucho más en un
  elemento grande.
- Arrastrar siempre necesita `whileDrag` (normalmente `scale: 1.03` más una sombra más profunda) para
  que el usuario sepa que lo tiene agarrado.
- `dragElastic` (por defecto `0.5`) expresa el límite: puedes tirar un poco más allá y vuelve, lo que
  se lee mejor que un muro rígido.
- Los elementos con `whileTap` se vuelven **accesibles por teclado automáticamente**
  (`onTapStart` → `onTap` con Enter). No lo reconstruyas.

---

## 9. Esperas e incertidumbre

- **Menos de 1 segundo**: nada de spinner. Un spinner que parpadea irrita más que una espera limpia.
- **1–5 segundos**: un esqueleto. Su brillo debe ser lento (`1.5–2s` por pasada) y de bajo contraste:
  señala *sigo aquí*, no debería competir por la atención.
- **Más de 5 segundos, o con progreso conocido**: una barra de progreso, y **nunca va hacia atrás**.
- Con actualizaciones optimistas, inserta el nuevo ítem en su forma final (opcionalmente con menos
  opacidad) y anima solo la reversión en caso de fallo. **Hacer invisible el camino del éxito es la
  mejor animación que existe.**

Efectos ambientales con `repeat: Infinity` (respiración, pulso, brillo): amplitud lo bastante pequeña
como para ser *perceptible pero no legible*, periodo `≥ 1.5s`, y siempre desactivados con reduced
motion.

---

## 10. Antipatrones

| Antipatrón | Por qué está mal | En su lugar |
|---|---|---|
| `duration: 0.5` para todo | sin escalones: si todo es igual de importante, nada lo es | usa los escalones de tiempo de SKILL.md |
| Aparecer desde `y: 100` / `scale: 0` | distancia excesiva; se lee como llegar de otra pantalla | `y: 8–16`, `scale: 0.95` |
| Hacer rebotar un `scale` | sensación de chocar con un cristal | `bounce: 0` |
| `ease: "linear"` para movimiento | nada en el mundo físico arranca y frena a velocidad constante | `easeOut` o un muelle; `linear` solo para enlace con scroll y rotación infinita |
| Salida tan larga como la entrada | hace esperar por algo ya irrelevante | recorta la salida a 0.5–0.7× |
| `whileInView` sin `once` | se repite en cada pasada de scroll | `viewport={{ once: true }}` |
| Stagger sin hacer la cuenta | el último ítem aterriza dos segundos después | intervalo × cantidad ≤ 0.5s |
| Animar `width` / `height` / `top` | dispara layout, pierde fotogramas | la prop `layout`, o transforms |
| Encadenar con `setTimeout` | no se puede cancelar ni interrumpir, y se desfasa | una secuencia, u orquestación con variants |
| Probado solo en modo claro | las sombras son invisibles sobre superficies oscuras | ver `contrast.md` |
| Sin tratar reduced motion | provoca vértigo en algunos usuarios | `<MotionConfig reducedMotion="user">` |
| bounce 0 y 0.4 en la misma página | la interfaz parece ensamblada de piezas | un solo juego de tokens para todo el producto |

---

## 11. Define tokens; deja de ajustar a mano

La otra mitad de sentirse natural es la **consistencia**. Dentro de un producto, las acciones que
significan lo mismo deberían compartir el mismo tiempo y la misma curva.

```js
// motion.tokens.js
export const T = {
  instant: { duration: 0.12, ease: "easeOut" },                    // respuesta
  micro:   { duration: 0.2,  ease: "easeOut" },                    // hover / tooltip
  enter:   { type: "spring", visualDuration: 0.3,  bounce: 0.15 }, // entrada de componente
  exit:    { duration: 0.15, ease: "easeIn" },                     // salida de componente
  layout:  { type: "spring", visualDuration: 0.35, bounce: 0 },    // reflujo
  page:    { type: "spring", visualDuration: 0.5,  bounce: 0.1 },  // cambio de ruta
  stagger: 0.04,
}
```

Configura el valor por defecto de todo el sitio una sola vez:
```jsx
<MotionConfig transition={T.enter} reducedMotion="user">
```
A partir de ahí, sobrescribe en un componente concreto solo cuando necesites desviarte — y solo
cuando puedas decir por qué.
