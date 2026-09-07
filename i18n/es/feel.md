# feel.md — Qué hace que el movimiento se lea como real

Este archivo no va de APIs. Va de *por qué esa animación parece falsa*.

Ordenado aproximadamente por lo mal que cada problema rompe la ilusión: **arregla primero los primeros; los
detalles posteriores sólo importan una vez que aquéllos están bien.**

Todo lo de aquí está escrito con el vocabulario de la especificación de `SKILL.md` §1. Nada en él es específico de una
plataforma.

---

## 0. El principio de una línea

> Una animación debería dejar que la gente sepa qué pasó **sin pensar en ello**.
> El usuario no debería notar la animación. Debería notar *que la cosa vino de allí*.

Cualquier animación que la gente se pare a *admirar* es, en un producto, casi siempre demasiado larga.

---

## 1. Deja que el valor que se anima elija los parámetros

Cuando no estés seguro de qué usar, **no te inventes nada**. Elige según *qué tipo de valor se
está moviendo*, y la elección ya está hecha por ti:

| Qué se anima | Usa |
|---|---|
| tres o más keyframes | tween, `dur 0.8`, curve `inout` |
| posición y rotación — `x` `y` `z` `rotate` `skew` | `spring(0.28, 0.2)` — overshoot ligero |
| la familia de scale | `spring(0.27, 0)` — **sin overshoot** |
| todo lo demás — opacidad, color, desenfoque, filtros | tween, `dur 0.3`, curve `out` |

Vale la pena nombrar con precisión la curva de esa última fila: un **easeOut más plano** que el
predeterminado de la plataforma — menos abrupto al principio, igual de suave al final. En términos de cubic-Bézier, `(0.25, 0.1,
0.35, 1)`; en un runtime con curvas nombradas, «sine out» o «quad out» antes que «quint out».

**Tres conclusiones que se leen directamente en esa tabla:**

1. Las cosas que ocupan espacio (posición, tamaño) → spring. Las que no (opacidad, color) → tween.
2. Crecer y encoger **no deberían rebotar**. Moverse puede.
3. La duración por defecto es sólo `0.3s`. Si la tuya es más larga, necesitas una razón.

---

## 2. El valor real de un spring es el traspaso de velocidad, no el rebote

La mayoría cree que spring = rebotón. Falso. La propiedad que más importa es que **cuando una
animación se interrumpe, continúa desde la posición actual a la velocidad actual** — en lugar
de pararse en seco y empezar de nuevo.

Ésta es la línea entre *se siente como un objeto* y *se siente como un pase de diapositivas*.

Piensa en un valor que se alterna entre dos objetivos más rápido de lo que ninguna de las dos animaciones tarda en completarse:

- Un **tween** se reinicia en duro en cada alternancia. Cada reinicio empieza a velocidad cero, así que el movimiento
  da un tirón visible justo en el momento en que el usuario actuó: exactamente el momento que está mirando.
- Un **spring** con el objetivo desplazado conserva su posición y su velocidad. Revertir se siente como empujar
  algo con inercia, porque es literalmente lo que la integración está haciendo.

**La prueba: ¿esta animación la dispara una acción directa del usuario?**

| Disparador | Usa | Por qué |
|---|---|---|
| Arrastre, swipe, gesto, seguimiento del cursor | **spring** (obligatorio) | hay velocidad real que arrastrar |
| Movimiento o escalado causado por click / hover | **spring** | puede interrumpirse repetidamente |
| Cambio de layout causado por un toggle | **spring** | igual |
| Fundidos de entrada / salida | **tween** | no hay velocidad que arrastrar; importa más un tiempo controlable |
| Cualquier cosa que deba cuadrar en el tiempo (stagger, secuencia, vídeo) | **tween** | los springs no tienen un tiempo de fin fiable |
| Vinculación al scroll | vincula directamente, luego suaviza | ver §7 |

En un runtime **Tier 2** (ver `SKILL.md` §2) todavía puedes interrumpir, pero se pierde la velocidad. Dos
mitigaciones, en orden de preferencia: integrar el spring a mano para el puñado de interacciones que
realmente van dirigidas por gestos (`spring.md` §3 — son quince líneas), y en todo lo demás leer el
valor **actual** en el momento de la interrupción y animar desde ahí con `b ≤ 0.15`, lo que mantiene
el reinicio lo bastante pequeño como para que no se lea como un tirón.

En **Tier 3**, no pelees. Mantén las animaciones re-disparables en `dur ≤ 0.2s`; por debajo de ese umbral
un reinicio en duro queda bajo el suelo perceptivo y nadie lo ve.

---

## 3. Ajusta con `Dv` + `b`, nunca con coeficientes crudos

Nadie puede imaginarse `stiffness: 400, damping: 32`, y los dos mandos interactúan, así que «hazlo un poco
más rápido» se convierte en un rediseño. Trabaja en duración visual y rebote, convierte una vez en la frontera.

La conversión completa, el overshoot que produce realmente cada valor de rebote, y el integrador →
`references/spring.md`.

La versión corta:

- `b` es *cuánto hace overshoot*: `0.15` es como un 0.6% más allá del objetivo, `0.4` es como un 9.5%.
- `Dv` es *cuánto parece que tarda* — la cola sucede después, y por eso es posible alinear un spring y un
  tween entre sí.
- El scale siempre es `b = 0`.
- Un `b` por producto. El rebote mezclado es la señal más clara que existe de una interfaz construida por varias
  personas que nunca hablaron entre sí.

---

## 4. Causalidad: las cosas vienen de donde vinieron

Rompe esto y ningún pulido de curvas lo salvará.

- Un dropdown se expande **desde el control que lo abrió**, no apareciendo en fundido desde el centro de la pantalla. Pon
  el origen de la transformación (o el punto de anclaje) en el control.
- Un modal crece desde la tarjeta que se pulsó. Si tu runtime puede animar un elemento hasta la posición de
  otro, hazlo; si no puede, como mínimo arranca el modal en la posición y el tamaño de la tarjeta y muévelo,
  en lugar de hacer un fundido.
- Una barra lateral entra deslizándose **desde su propio lado**, no desde abajo.
- Borrar un elemento de una lista hace que los demás **cierren el hueco que dejó**, no que salten.
- Un toast entra desde la esquina en la que va a quedarse.

**El procedimiento general para un elemento compartido**, en un runtime que no tiene nada integrado para ello:

```
1. mide el rect de origen antes del cambio          (posición, tamaño)
2. deja que el cambio de layout ocurra instantáneamente
3. mide el rect de destino
4. aplica la transformación inversa para dejarlo visualmente de vuelta en el origen
5. anima esa transformación hasta la identidad
```

Sólo se mueven transformaciones, así que esto es barato para el compositor aunque parezca una animación de layout. Funciona
en cualquier runtime que sepa medir un rectángulo y aplicar una transformación, que son todos.

**Un sentido de escala para la distancia de travel:** microinteracciones `4–12px`, transiciones de componente
`16–40px`, porcentajes sólo para movimientos a pantalla completa.

Entrar en fundido desde `y: 100` es el error más común que existe: para un tooltip, esa distancia se lee como
*llegar desde otra habitación*.

---

## 5. Entrada y salida asimétricas

| | Entrada | Salida |
|---|---|---|
| Duración | `0.2 – 0.35s` | **0.5 – 0.7×** la entrada |
| Curve | `out` / spring | `in` |
| Distancia | completa | **la mitad o menos** |
| Scale inicial | `0.95` (no `0`) | `0.98` (apenas encoge) |

La razón: en la entrada el usuario tiene que *atrapar* información nueva y necesita tiempo para localizarla. En la salida
la cosa ya le es irrelevante, y hacerle esperar es hacerle perder el tiempo.

`out` al entrar e `in` al salir se componen en un `inout` global a lo largo de toda la experiencia.

Nunca entres desde `scale: 0`. Eso significa *de la nada al ser*, pero los elementos de UI casi siempre
vienen *de otro sitio*. `0.95` sobra para decir «esto apareció».

**La salida es la que necesita un mecanismo.** Las animaciones de entrada son fáciles: la cosa existe, anímala. La
salida requiere mantener algo vivo después de haber sido lógicamente eliminado. Cada runtime resuelve
esto de forma distinta, y es la causa número uno de «la animación de salida nunca se reproduce». Encuentra el
mecanismo en tu adaptador *antes* de diseñar una salida, no después.

---

## 6. Orquestación: el stagger es ritmo, no decoración

Diez cosas apareciendo simultáneamente se leen como un borrón. Desfásalas y obtienes orden, y dirección.

**Elegir el intervalo:**

| Número de ítems | Intervalo | Presupuesto total |
|---|---|---|
| 3–6 (menú, fila de tarjetas) | `0.04 – 0.06s` | ≤ 0.35s |
| 7–15 (lista) | `0.02 – 0.04s` | ≤ 0.5s |
| Por carácter | `0.02 – 0.03s` | depende del largo; pasado 1s cambia a por palabra |
| > 20 | no hagas stagger individual | agrúpalos, o haz un fundido del conjunto |

**El total es un techo duro.** Un stagger de `0.1s` sobre 20 ítems son 2 segundos: para cuando aterriza el último,
el usuario está haciendo otra cosa. Haz la aritmética antes de escribirlo.

**La dirección debería significar algo:**
- **desde el primero** — de arriba abajo, coincide con el orden de lectura, la opción segura
- **desde el último** — para plegar, así parece que se enrolla hacia arriba
- **desde el centro** — abriéndose hacia fuera, ceremonial, bueno para un hero
- **desde el ítem que el usuario acaba de tocar** — irradiando hacia fuera ← **la afirmación causal más fuerte
  disponible**, y casi nadie la usa

**El contenedor antes que los hijos, los hijos antes que el contenedor.** El contenedor debería abrirse antes de que el contenido
se vierta dentro, y el contenido debería salir antes de que el contenedor se cierre. Si tu runtime no tiene
orquestación padre/hijo, esto son sólo dos retardos y una comprobación aritmética: la salida del contenedor
no debe empezar hasta que la salida de los hijos haya terminado.

---

## 7. Scroll: lo vinculado hay que suavizarlo, lo disparado debe dispararse una vez

**Disparado por scroll** (se reproduce al entrar en el viewport)

Dispara **una vez**. Esto es casi siempre lo correcto: las animaciones que se repiten mientras el usuario baja y sube
dan náuseas, y la segunda reproducción no lleva información de todos modos.

Dispara alrededor del **30% visible**, no en el primer píxel. Un umbral de un píxel dispara mientras el elemento
sigue en el borde mismo de la pantalla, así que la animación termina antes de que esté bien a la vista.

**Vinculado al scroll** (un valor atado a la posición de scroll)

La entrada de scroll es discreta: una muesca de rueda, un evento de trackpad, un frame de delta táctil. Atarla
directamente a una transformación produce escalones visibles. **Pasarla por un spring es obligatorio, no un
lujo**: corre un spring cuyo `target` se reinicia al valor de scroll en cada frame, y anima desde la
salida del spring.

Usa aquí un spring *blando* — alrededor de `spring(0.35, 0)`. Es un filtro, no un movimiento; el overshoot en un
valor vinculado al scroll se lee como que la página pelea con el usuario.

Dos detalles que siempre muerden:

- Al montar, el spring debe **inicializarse en el valor de scroll actual**, no en cero, o la página
  barrerá desde arriba al cargar.
- Fija las cosas con el mecanismo nativo de sticky/anclaje de la plataforma, nunca escribiendo una
  posición en cada frame desde el manejador de scroll.

**Amplitud del parallax**: una capa de fondo moviéndose a `0.3–0.5×` la del primer plano sobra. Más
que eso deja de leerse como profundidad y empieza a leerse como *el fondo está a la deriva*.

El parallax es lo primero que hay que desactivar con movimiento reducido.

---

## 8. El feedback de gesto debe empezar dentro de los 100ms

El feedback táctil y de click es una **señal de confirmación**, no una animación.

```
hover:  scale 1.03      spring(0.15, 0)
press:  scale 0.97      spring(0.15, 0)
drag:   scale 1.03  +  sombra amplia  +  orden de profundidad elevado
```

- **Pulsar = más pequeño.** Un dedo empujando hacia abajo debería hundir la cosa. Crecer es física equivocada.
- Limita el scale de hover a `1.05`; más allá de eso, los elementos vecinos parecen apartados a empujones.
- Los elementos grandes (tarjetas, paneles) necesitan un scale de hover *menor* (`1.01–1.02`), porque el desplazamiento
  real = scale × tamaño, así que la misma proporción mueve mucho más en un elemento grande.
- Arrastrar siempre necesita un estado de agarre distinto, para que el usuario sepa que lo tiene cogido.
- Expresa un límite **elásticamente**: deja que el usuario tire un poco más allá del tope —con la resistencia creciendo
  con la distancia, típicamente la mitad de la entrada pasado el borde— y que vuelva con un spring al soltar. Un muro duro
  se lee como un bug; la resistencia elástica se lee como una regla.
- Sea cual sea tu mecanismo de feedback de pulsación, asegúrate de que también se dispare con la **activación por teclado**.
  Un botón que se hunde visiblemente al hacer click y no hace nada con Enter es peor que uno que no se hunde nunca.

---

## 9. Espera e incertidumbre

- **Menos de 1 segundo**: sin spinner. Un spinner que parpadea irrita más que una espera a secas.
- **1–5 segundos**: un skeleton. Su brillo debería ser lento (`1.5–2s` por pasada) y de bajo contraste: señala
  *sigo aquí*, no debería competir por la atención.
- **Más de 5 segundos, o con progreso conocido**: una barra de progreso, y **nunca va hacia atrás**.
- Con actualizaciones optimistas, inserta el nuevo ítem en su forma final (opcionalmente con opacidad reducida) y
  anima únicamente la reversión en caso de fallo. **Hacer invisible el camino del éxito es la mejor animación
  que existe.**

Efectos ambientales en bucle (respiración, pulso, brillo): amplitud lo bastante pequeña como para ser *perceptible pero
no legible*, periodo `≥ 1.5s`, y siempre desactivados con movimiento reducido.

---

## 10. Antipatrones

| Antipatrón | Por qué está mal | En su lugar |
|---|---|---|
| `dur 0.5` en todo | sin niveles: si todo es igual de importante, nada lo es | los niveles de tiempo de `SKILL.md` §3.4 |
| Entrar en fundido desde `y: 100` / `scale: 0` | distancia demasiado grande; se lee como llegar desde otra pantalla | `y 8–16px`, `scale 0.95` |
| Hacer rebotar un scale | sensación de chocar contra un cristal | `b = 0` |
| `linear` para el movimiento | nada en el mundo físico arranca y para a velocidad constante | `out` o un spring; `linear` es sólo para vinculación al scroll y rotación sin fin |
| Salida tan larga como la entrada | hace esperar a la gente por algo ya irrelevante | recorta la salida a 0.5–0.7× |
| Animaciones disparadas por scroll que se repiten | dan náuseas, y la segunda vez no llevan información | dispara una vez |
| Stagger sin hacer la aritmética | el último ítem aterriza dos segundos después | intervalo × cantidad ≤ 0.5s |
| Animar width / height / top / left | provoca layout, tira frames | transformaciones, más el truco de medir e invertir de §4 |
| Encadenar con temporizadores no cancelables | no se puede interrumpir, y deriva | una secuencia que se pueda cancelar como unidad |
| Probado sólo en el tema claro | las sombras son invisibles sobre superficies oscuras | ver `contrast.md` |
| Sin manejo de movimiento reducido | provoca vértigo a algunos usuarios | `SKILL.md` §5 |
| `b = 0` y `b = 0.4` en la misma página | la interfaz parece ensamblada a partir de piezas | un único set de tokens para todo el producto |
| Confiar en un callback de «animación terminada» para lógica real | no se dispara nunca si hay interrupción | dirige el estado de forma independiente; la animación es presentación |

---

## 11. Define tokens; deja de ajustar a mano

La otra mitad de sentirse natural es la **consistencia**. Dentro de un producto, las acciones que significan lo
mismo deberían compartir el mismo tiempo y la misma curva. Escribe esto una vez, en el formato de configuración que
sea el de tu runtime:

```
feedback :  dur 0.12   curve out          # pulsación, checkbox, anillo de foco
micro    :  dur 0.2    curve out          # hover, tooltip
enter    :  spring(0.3,  0.15)            # entrada de componente
exit     :  dur 0.15   curve in           # salida de componente
layout   :  spring(0.35, 0)               # reflow
page     :  spring(0.5,  0.1)             # cambio de ruta
stagger  :  0.04
lumin    :  dur 0.13   curve out          # brillo, color, nivel de sombra
```

Fíjate en la última fila: la luminancia tiene su propio token porque debe ser **más rápida** que el movimiento al que
acompaña (`contrast.md` §5). Si tu set de tokens no tiene una entrada de luminancia, el brillo acabará
compartiendo la duración del movimiento y se leerá como *el color persiguiendo al objeto*.

Después de eso, sobrescribe en un solo componente sólo cuando necesites desviarte, y sólo cuando puedas
decir por qué.
