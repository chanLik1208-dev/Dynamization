# Dynamization Core (Español)

> Esta es la versión en español de `SKILL.md`. El texto canónico en inglés está en `SKILL.md`, en la raíz del repositorio.
> Los adaptadores de runtime (`css` / `waapi` / `luau` / `porting`) y `spring.md` sólo existen en inglés, en `references/`.

> El movimiento es el lenguaje del **tiempo**: de dónde vino una cosa, adónde se fue, si ya puedes tocarla.
> La luminancia es el lenguaje del **espacio**: qué está encima, qué está vivo, dónde hay que mirar ahora mismo.
>
> Por separado, cada uno hace la mitad del trabajo. «Elevar» no es mover algo 4px hacia arriba: es
> **desplazamiento + una sombra más grande y más suave + una superficie más brillante, todo a la vez.** Sólo entonces
> el cerebro lo lee como *eso se me acercó*.
>
> Las interfaces que se sienten «rígidas» o «planas» casi nunca sufren de una curva poco elegante. Violan
> la intuición física, o cambian una sola propiedad cuando deberían cambiar tres.

**Este pack no es dueño de ninguna API.** Todo juicio de aquí abajo está escrito como un número que un ojo humano puede verificar:
una duración en segundos, una distancia en píxeles, un factor de amortiguación, un paso de luminancia. El runtime es un
detalle que recoges en §2 y en el que después dejas de pensar.

## 0. Idioma

Todos los archivos de `references/` están en inglés. Las traducciones completas de los capítulos de criterio
(este archivo, `feel`, `contrast`, `recipes`, `pitfalls`, `errata`) viven en `i18n/<locale>/`:

| Locale | Ruta |
|---|---|
| 繁體中文 | `i18n/zh-TW/` |
| 日本語 | `i18n/ja/` |
| 한국어 | `i18n/ko/` |
| Español | `i18n/es/` |

**Si le estás respondiendo al usuario en uno de esos idiomas, lee los archivos de ese locale en lugar de los
ingleses.** Los adaptadores (`references/adapters/`) son sólo en inglés por diseño: son sobre todo
código e identificadores de API, donde traducir añade ruido y desviación.

## 1. El vocabulario de la especificación

Todo en este pack está escrito con seis términos. Apréndelos una vez; son lo que se porta.

| Término | Significa | Se escribe como |
|---|---|---|
| **dur** | cuánto dura, en segundos | `0.25s` |
| **curve** | `out` (rápido y luego asentándose), `in` (lento y luego acelerando), `inout`, `linear` | `out` |
| **spring(Dv, b)** | un spring definido por **duración visual** `Dv` en segundos y **rebote** `b` en `0–1` | `spring(0.3, 0.15)` |
| **travel** | desplazamiento, en px, desde donde la cosa realmente estaba | `y −4px` |
| **lumin** | un paso de luminancia, en valor de superficie o en nivel de sombra | `surface +1 tier` |
| **stagger** | intervalo entre hermanos, en segundos | `0.04s` |

`spring(Dv, b)` es el que carga el peso. `Dv` es cuánto **parece** que tarda el movimiento,
excluyendo la cola de asentamiento, y por eso es posible alinear un spring y un tween
entre sí. `b = 0` es sin overshoot; `b = 1` es extremadamente rebotón. Nunca especifiques un spring en
rigidez/amortiguación dentro de una conversación de diseño; nadie puede imaginarse esos valores. Convierte en la frontera →
`references/spring.md`.

## 2. Elige un runtime y luego quítate de en medio

Lee el adaptador del runtime en el que estás. **Lee uno. No todos.**

| Runtime | Adaptador | Tier |
|---|---|---|
| Sólo CSS — transiciones, keyframes, easing `linear()`, view transitions | `references/adapters/css.md` | 3 |
| Web Animations API — `element.animate()`, `ScrollTimeline` | `references/adapters/waapi.md` | 2 |
| Luau / Roblox — `TweenService`, `TweenInfo`, springs con `RunService` | `references/adapters/luau.md` | 2–1 |
| Cualquier otra cosa — un motor de juego, un toolkit nativo, una librería de animación | `references/adapters/porting.md` | — |

**Tier** es lo único de un runtime que cambia tu *diseño*, no sólo tu sintaxis:

| Tier | El runtime puede | Consecuencia para lo que diseñas |
|---|---|---|
| **1** | interrumpir una animación y arrastrar la **velocidad** a través de la interrupción | todo en este pack funciona tal como está escrito |
| **2** | interrumpir, pero reinicia desde el reposo (se pierde la velocidad) | acorta las reversiones; prefiere `b ≤ 0.15` para que el reinicio no se vea como un tirón |
| **3** | sólo correr hasta el final, o cortar de golpe al interrumpir | mantén `dur ≤ 0.2s` en cualquier cosa que el usuario pueda volver a disparar; falsifica los springs con una curva muestreada |

La mayoría de los runtimes son Tier 2 por defecto, y Tier 1 sólo si integras el spring a mano. El adaptador
de tu runtime dice cuál es, y cómo subir de tier si la interacción lo necesita.

**Pregúntate si necesitas una librería o un spring siquiera.** Para un elemento, un estado y ningún
re-disparo, un tween normal basta. Los springs se ganan su complejidad con la interrumpibilidad,
el traspaso de velocidad y el traspaso de gesto. Si no usas ninguna de esas cosas, no pagues por ellas.

## 3. Cinco reglas de oro

Cumple las cinco antes de escribir cualquier animación. Rompe una y el resultado se siente *mal* de una forma
que la gente normalmente no sabe nombrar.

### 1. Springs para posición y tamaño, tweens para opacidad y color

Esto no es cuestión de gusto, y no es la opinión de una librería: se desprende de cómo clasifica el cerebro
lo que está mirando.

| Qué se anima | Usa |
|---|---|
| posición, rotación, sesgo — `x` `y` `rotate` y compañía | `spring(0.28, 0.2)` — overshoot ligero |
| la familia de scale | `spring(0.27, 0)` — **sin overshoot, nunca** |
| opacidad, color, desenfoque, todo lo demás | tween, `dur 0.3`, curve `out` |
| tres o más keyframes | tween, `dur 0.8`, curve `inout` |

Por qué: las cosas que ocupan espacio (posición, tamaño) las lee el cerebro como **objetos**, y los objetos
tienen masa e inercia. La opacidad y el color no son objetos —son sólo *si puedes verlo o no*—,
así que un spring ahí se lee como un parpadeo.

**Corolario: nunca hagas rebotar un scale.** El crecimiento rebotón se lee como chocar contra un cristal.

Esas cuatro filas son un conjunto calibrado. Cuando no sepas qué usar, úsalas sin modificar.

### 2. Las animaciones deben ser interrumpibles, y deberían arrastrar la velocidad a través de la interrupción

La regla más importante de todas, y la que más se pasa por alto. Cambiar de opinión a mitad de una animación es
comportamiento humano normal.

- Usa un spring donde puedas: un integrador de spring real arrastra la velocidad actual, así que una reversión no
  se frena en seco. **Esto —y no el rebote— es la verdadera razón por la que los springs le ganan a los tweens.**
- En un runtime Tier 2/3, como mínimo lee el valor **actual** y anima desde ahí, nunca desde el
  inicio nominal. Volver de golpe al inicio en cada re-disparo es el tartamudeo clásico.
- Nunca encadenes animaciones con un temporizador que no se pueda cancelar como unidad. Usa una secuencia o una
  orquestación padre-hijo que se pueda cancelar entera.
- Cualquier mecanismo de «transición» que salte al estado final al ser interrumpido (muchas APIs integradas
  de transición de página lo hacen) no sirve para nada que el usuario pueda volver a disparar rápido.

### 3. La entrada y la salida no son simétricas

Nadie debería esperar por algo que se está yendo.

```
enter:  opacity 0→1, y +8→0    dur 0.25   curve out
exit:   opacity 1→0, y 0→+4    dur 0.15   curve in
```

La salida corre a aproximadamente **0.5–0.7×** la duración de la entrada, sobre una **distancia más corta**. Un
elemento que se va no necesita recorrer el camino entero: el ojo sólo necesita saber que se fue.

### 4. Niveles de tiempo: cada trabajo tiene su presupuesto

| Tier | dur | Dónde | Curve |
|---|---|---|---|
| Feedback inmediato | `0.1–0.15s` | scale al pulsar, checkbox, anillo de foco | `out` o `spring(0.15, 0)` |
| Microinteracción | `0.15–0.25s` | hover, tooltip, color de botón | `out` |
| Transición de componente | `0.25–0.4s` | dropdown, modal, acordeón, reflow | `spring(0.3, 0.15)` |
| Página / narrativa | `0.4–0.8s` | cambio de ruta, hero, multi-keyframe | `spring(0.5, 0.1)` + stagger |
| Más de `1s` | casi con seguridad está mal | sólo carga, ambiente, vinculado al scroll | — |

Las animaciones de hover **no deben superar los 0.2s**: puede que el cursor ya no esté.
Distancias más largas pueden durar algo más, pero **no linealmente**: doblar la distancia compra aproximadamente
un 20–30% más de tiempo, no un 100%.

> Razonamiento completo, la semántica humana de los parámetros de spring, ritmo de orquestación, antipatrones →
> `references/feel.md`

### 5. Un evento debería cambiar varias propiedades en la misma dirección

Una sola propiedad carga con demasiada poca información. **Que varias propiedades se muevan juntas es lo que el
cerebro lee como un único evento físico.**

| Para expresar | Cambia al menos |
|---|---|
| Elevación / acercamiento (hover de tarjeta) | `y` hacia arriba + sombra más grande y suave + superficie más brillante |
| Pulsación / hundimiento | scale hacia abajo + sombra que se cierra + sombra interior + más oscuro |
| Agarrado (arrastrando) | scale hacia arriba + sombra amplia + orden de profundidad elevado |
| Foco (modal abriéndose) | el contenido entra + **el fondo se atenúa** (el scrim debe llegar primero) |
| Deshabilitado | un token de color de bajo contraste dedicado (**no** 50% de opacidad) |

La luminancia es una *señal de estado*; el desplazamiento es un *proceso*. Por eso **la luminancia cambia más rápido que
el movimiento** (aproximadamente `0.12–0.15s` frente a `0.2–0.35s`).

En los temas oscuros las sombras son casi invisibles, así que la elevación tiene que expresarse con *superficies más brillantes*.
Cambiar de tema intercambia el mecanismo, no sólo la paleta.

A veces hay una tercera cosa en pantalla: la **textura** —trama de líneas, grano, una regla que se repite—. No es un
canal ni un término de la especificación. Es un modificador de `lumin` que refuerza el fondo sobre el que se apoya un
objeto, y tiene que quedarse más callada que el paso de luminancia más pequeño de tu escalera, o se lee como ruido
en lugar de como material. También pierde siempre contra el texto: nada tramado se sitúa detrás de texto corrido, y en
cualquier región con palabras la textura no debe ser lo primero que alcanza el ojo. Sólo refuerzo y acento →
`contrast.md` §8.

> El modelo óptico, los sets de tokens claro/oscuro, el coste de animar cada propiedad de luminancia,
> los mínimos de accesibilidad → `references/contrast.md`

## 4. Tabla de rutas

Lee el archivo del trabajo que tienes delante. **No los leas todos.**

| Qué estás haciendo | Lee |
|---|---|
| Entender qué significa «natural»; no consigues acertar la sensación; alguien dijo que está «rígido» | `references/feel.md` ← **el eje del tiempo** |
| Elevación, sombra, tema oscuro, foco, scrim, contraste | `references/contrast.md` ← **el eje del espacio** |
| Convertir `spring(Dv, b)` en los números que quiera tu runtime | `references/spring.md` |
| Quieres un efecto terminado del que partir | `references/recipes.md` |
| Escribir las llamadas reales en CSS / WAAPI / Luau | `references/adapters/<runtime>.md` |
| Tu runtime no tiene adaptador aquí | `references/adapters/porting.md` |
| No se anima nada, da tirones, la salida no se dispara, la reversión tartamudea | `references/pitfalls.md` |
| **Nada parece roto, y estás a punto de decir que has terminado** | `references/errata.md` ← **léelo antes de publicar** |

Locales no ingleses: sustituye `feel`, `contrast`, `recipes`, `pitfalls`, `errata` por los de `i18n/<locale>/`.

## 5. La accesibilidad no es opcional

Cualquier cosa que **mueva o escale un elemento grande** debe respetar la preferencia de movimiento reducido. Toda
plataforma expone una; el adaptador la nombra para tu runtime.

El comportamiento correcto no es «apagar la animación». Es: **desactivar desplazamiento y scale, conservar
opacidad y color.** El usuario sigue aprendiendo que la pantalla cambió; hace un fundido cruzado en lugar de
deslizarse. El parallax, el vídeo con reproducción automática y los bucles infinitos siempre necesitan además una rama explícita.

## 6. Líneas rojas de rendimiento

La ley universal: **componer es barato, pintar es caro, el layout es ruinoso.** Todo runtime
tiene alguna versión de estos tres niveles, incluso los que no tienen DOM.

- ✅ **Siempre seguro**: transform (translate / scale / rotate) y opacidad — nunca provocan reflow de nada
- ⚠️ **Paint** (mídelo): sombras, radio de esquina, color de fondo, desenfoque — bien en elementos
  pequeños, peligroso en los grandes o en listas largas
- ❌ **Layout** (evítalo): width, height, top, left, margin, padding, grosor de borde — animar esto
  vuelve a resolver el layout de todo lo que hay alrededor, en cada frame

La salida de emergencia estándar para una propiedad cara es **pre-renderizar ambos estados y hacer un fundido cruzado
de su opacidad** en lugar de animar la propiedad cara en sí. Ese truco aparece en
`contrast.md` §6 para las sombras y se generaliza a casi todo lo de la fila ⚠️.

## 7. De dónde salen los números

Las tablas de parámetros de este pack son un conjunto calibrado, contrastado con los valores por defecto que traen
implementaciones de animación de uso extendido y con la literatura perceptiva sobre la que se ajustaron. Están
enunciados aquí como números simples precisamente para que **nunca tengas que ir a buscar la documentación de un
proveedor para usar este pack**, y para que nada de aquí se pudra cuando una librería cambie su API.

Donde este pack y la documentación de tu runtime discrepen sobre *qué hace una API*, gana la
documentación del runtime: está describiendo su propio comportamiento. Donde discrepen sobre *qué
se siente bien*, prefiere este pack y luego verifícalo con tus propios ojos: un spring de 0.3s o se lee como un
objeto o no, y eso no es una cuestión de opinión para la que necesites una cita.
