# errata.md — Los errores que este pack invita a cometer

`pitfalls.md` es para cuando algo está visiblemente roto y estás buscando el síntoma. **Este
archivo es para cuando no hay nada que parezca roto.**

Cada entrada de abajo es un error cometido por alguien que había leído el capítulo correspondiente y lo estaba
siguiendo. Ésa es la cuestión: no son fallos de conocimiento, son fallos de verificación. Ninguno
de ellos lanza una excepción. Ninguno registra un aviso. La mayoría llega a producción.

Lee esto antes de escribir, y otra vez antes de decir que has terminado.

---

## Cómo usarlo

Cada entrada nombra primero el **síntoma silencioso**, porque es todo lo que vas a obtener. Luego el código
equivocado, luego por qué alguien competente lo escribe igualmente, luego el arreglo, y luego **una comprobación que puedes
ejecutar de verdad**.

Las comprobaciones son la parte que carga el peso. Una regla que no puedes verificar es una regla que vas a romper.

---

## A. Seguiste el capítulo, y el entorno se lo comió

### A1. Un ancestro que recorta anula la sombra pre-renderizada

**Síntoma silencioso:** el hover cambia la posición pero la elevación no llega nunca. En un tema claro, donde
`contrast.md` §2 pone *todas* las capas en la sombra, el hover acaba llevando movimiento a secas,
que es exactamente la media expresión contra la que avisa la §5 de `SKILL.md`.

```css
/* ❌ */
.card { border-radius: 4px; overflow: hidden; box-shadow: var(--e2); }
.card::after { inset: 0; box-shadow: var(--e3); opacity: 0; transition: opacity .13s; }
.card:hover::after { opacity: 1; }
```

**Por qué se escribe:** `contrast.md` §6 te dice que hagas un fundido cruzado de una sombra pre-renderizada en lugar de
animar `box-shadow`, y ese consejo es correcto. Por separado, una tarjeta redondeada con una imagen
arriba necesita que le recorten las esquinas, y `overflow: hidden` en la tarjeta es el reflejo automático. Ambas decisiones son
correctas por su cuenta. Una sombra pinta *fuera* de la caja del elemento, así que el recorte la borra, y la borra
en silencio, porque la transición sigue corriendo sobre una capa que nadie puede ver.

```css
/* ✅ recorta lo que necesita recorte, no lo que proyecta la sombra */
.card { border-radius: 4px; box-shadow: var(--e2); }          /* aquí no hay overflow */
.card .media { border-radius: 3px 3px 0 0; overflow: hidden; }
```

**La comprobación:** haz hover sobre el elemento y mira la *sombra*, no la tarjeta. Si no ves cambiar la sombra,
sube por los ancestros buscando `overflow: hidden`, `clip-path` o un envoltorio de composición al
estilo `CanvasGroup`. La misma trampa se aplica a un anillo de foco dibujado con `outline-offset`.

---

### A2. Un spring horneado reproducido durante `Dv` va rápido

**Síntoma silencioso:** el movimiento tiene la forma correcta pero se lee como apresurado, y el overshoot es un chasquido
en lugar de un asentamiento.

```css
/* ❌ la curva dura 0.32s; el reloj dice 0.3s */
transition: translate .3s var(--spring-enter);
```

**Por qué se escribe:** todas las demás filas de la tabla de tokens son una duración, así que `spring(0.3, 0.15)`
se lee como «0.3 segundos». No lo es. `Dv` es la duración *visual* —donde el movimiento parece
terminar— y la curva horneada incluye necesariamente la cola de asentamiento posterior. Los dos números difieren
más cuanto más rebotón es el spring: para `b = 0.4` la cola es el 35% del total.

```css
/* ✅ */
transition: translate .32s var(--spring-enter);   /* t_settle, de spring.md §4 */
```

**La comprobación:** en la tabla de tokens de `spring.md`, cada spring tiene tanto un `Dv` como un `t_settle`. Si la
duración de tu CSS es igual al `Dv`, está mal. Haz grep en tu hoja de estilos por los valores de `Dv` como
duraciones —`.3s`, `.35s`, `.5s`— junto a un easing `linear(`.

---

### A3. El progreso recortado elimina el rebote en silencio

**Síntoma silencioso:** `b` no marca ninguna diferencia. `spring(0.3, 0.15)` y `spring(0.3, 0.4)` se ven
idénticos, así que concluyes que el rebote es demasiado sutil para importar y dejas de usarlo.

**Por qué se escribe:** hiciste el muestreo correctamente, pero el runtime rechaza o recorta los valores de easing
fuera de `0–1`. El `linear()` de CSS los acepta; muchos sistemas basados en enumeraciones y en recursos de curva no,
y recortan en lugar de dar error.

**El arreglo:** averigua en cuál estás, una vez, y escríbelo en el adaptador. Si el progreso está recortado,
`b > 0` no está disponible a través de una curva horneada: o integras el spring (`spring.md` §3) o
aceptas `b = 0` y sacas tu viveza de la regla multipropiedad.

**La comprobación:** hornea `spring(0.3, 0.4)`, cuyo pico es `1.094`, y anima con él un translate de 400px.
Si el elemento nunca pasa de los 400px, tu progreso está recortado.

---

### A4. La transición vive en el estado de hover, así que salir es instantáneo

**Síntoma silencioso:** entrar en el hover es suave, salir corta de golpe. La mitad de tus interacciones se sienten bien
y no sabes decir por qué la otra mitad se sienten baratas.

```css
/* ❌ */
.card:hover { translate: 0 -4px; transition: translate .2s; }
```

**Por qué se escribe:** se lee de forma natural —«en hover, sube, tardando 0.2s»— y funciona en la
dirección en la que estabas probando. La declaración sólo existe mientras el selector coincide, así que al salir del hover
no hay ninguna transición que ejecutar.

```css
/* ✅ la transición pertenece al estado de reposo */
.card { transition: translate var(--t-micro); }
.card:hover { translate: 0 -4px; }
```

**La comprobación:** mueve el puntero *fuera* y mira. Prueba siempre la salida de cada estado, no la
entrada: esto es `feel.md` §5 aplicado a tus propias pruebas, y pilla A4, A5 y C1 de una sola vez.

---

### A5. Nada se anima al entrar, porque no había un valor previo

**Síntoma silencioso:** el elemento simplemente aparece. Sin error, sin animación a medio reproducir.

**Por qué se escribe:** una transición interpola entre dos valores computados, y un elemento que
acaba de insertarse —o que estaba en `display: none`— no tiene un primer valor del que partir. La declaración
está bien; no hay nada que pueda hacer.

**El arreglo:** en CSS, `@starting-style` más `transition-behavior: allow-discrete`
(`adapters/css.md`). Desde script, fija el valor inicial, fuerza un reflow y luego fija el valor final: la
línea `void el.offsetWidth` que parece un no-op y no lo es. En un runtime sin ninguno de esos mecanismos,
monta en el valor inicial y cámbialo en el frame siguiente.

**La comprobación:** si una animación de entrada implica un elemento que no existía hace un frame, necesitas
una de esas tres cosas. No hay una cuarta opción.

---

## B. Rompiste una regla que este pack enuncia con toda claridad

### B1. Mover algo con propiedades de layout

**Síntoma silencioso:** un movimiento de aspecto correcto que tira frames en un móvil de gama media y va bien en
tu máquina.

```js
/* ❌ — y esto lo escribió alguien que estaba implementando este mismo pack */
flier.style.transition = "left .32s var(--spring), top .32s var(--spring), width .32s, height .32s";
flier.style.left = to.left + "px";
```

**Por qué se escribe:** tienes dos rectángulos de `getBoundingClientRect()`, y vienen
expresados en `left`/`top`/`width`/`height`. Animar los números que ya tienes en la mano es el camino más corto
de la medición al movimiento, y la forma del resultado es correcta, así que nada te empuja a
mirar otra vez.

```js
/* ✅ colócalo en el destino, muévelo con una transformación */
flier.style.left = to.left + "px";
flier.style.top = to.top + "px";
flier.style.width = to.width + "px";
flier.style.height = to.height + "px";
flier.style.translate = (from.left - to.left) + "px " + (from.top - to.top) + "px";
flier.style.scale = from.width / to.width;
/* frame siguiente: anima ambos de vuelta a la identidad */
```

**La comprobación:** haz grep de `left`, `top`, `width`, `height`, `margin`, `padding` en cada animación que hayas
escrito. Cada resultado necesita una razón. El procedimiento de medir e invertir de `feel.md` §4 existe para que
la respuesta sea siempre una transformación.

---

### B2. Un evento, una propiedad

**Síntoma silencioso:** la interacción responde, pero nadie sabe decirte qué significa. «Se siente
barato», sin más detalle, es el informe habitual.

**Por qué se escribe:** cada propiedad se añade en un momento distinto. El movimiento entra cuando
construyes el componente; la sombra es una nota de revisión de diseño; el cambio de superficie se pierde en un refactor.
Ningún commit por separado parece equivocado.

**El arreglo:** trata las filas de `SKILL.md` §3.5 como un mínimo, no como un menú. La elevación es desplazamiento **y**
una sombra más grande y más suave **y** una superficie más brillante. La pulsación es scale hacia abajo **y** una sombra más ceñida
**y** más oscuro.

**La comprobación:** cuenta las propiedades que cambian por interacción. Menos de tres para una elevación o una
pulsación significa que está sin terminar; y si una de las tres es una sombra, vuelve a ejecutar la comprobación A1, porque es ahí
donde la sombra desaparece en silencio.

---

### B3. Salidas simétricas

**Síntoma silencioso:** la interfaz se siente ligeramente lenta en todas partes, sin un único momento lento al
que apuntar.

**Por qué se escribe:** la salida se escribe normalmente como espejo de la entrada, porque eso es una
edición en lugar de dos, y no está *mal*: sólo es un 40% demasiado larga, sobre más del doble de la distancia necesaria.

**El arreglo:** salida a `0.5–0.7×` la duración de la entrada, sobre la mitad de la distancia o menos, curve `in`.

**La comprobación:** busca cada duración de salida de tu set de tokens y compárala con su entrada. Ésta es
una auditoría de dos minutos y cambia cómo se siente el producto entero.

---

### B4. Mezclar los dos vocabularios de spring

**Síntoma silencioso:** uno de tus parámetros no hace nada. Cambias `bounce` y no ves ninguna diferencia,
así que asumes que el valor es demasiado pequeño y lo subes hasta que algo se mueve.

```js
/* ❌ */
{ type: "spring", visualDuration: 0.3, bounce: 0.2, stiffness: 400 }
```

**Por qué se escribe:** heredaste un spring escrito en `stiffness`, quisiste ajustar la sensación
y echaste mano del parámetro que entiendes, dejando el viejo en su sitio. La mayoría de las implementaciones
resuelven esto ignorando en silencio uno de los dos sistemas.

**El arreglo:** un vocabulario por proyecto. Prefiere `Dv`/`b`; convierte en la frontera con
`spring.md` §2.

**La comprobación:** haz grep de `stiffness` y `damping`. Cada resultado debería estar dentro de la función de
conversión, y en ningún otro sitio.

---

## C. Colgaste lógica de la animación

### C1. Eliminar un nodo en un evento de finalización

**Síntoma silencioso:** se acumulan elementos invisibles en el árbol, interceptando clicks. Sólo les pasa
a los usuarios que interactúan rápido, así que no se reproduce mientras lo estás mirando.

```js
/* ❌ */
el.addEventListener("transitionend", () => el.remove());
```

**Por qué se escribe:** es el evento documentado para exactamente esto, y funciona cada vez que lo
pruebas, porque pruebas haciendo un click y esperando.

```js
/* ✅ la animación es presentación; la eliminación no */
el.classList.add("leaving");
setTimeout(() => el.remove(), EXIT_MS);
```

**Por qué:** los eventos de finalización no se disparan cuando la animación se cancela, se interrumpe, se reemplaza o se
salta con movimiento reducido, y una API basada en promesas *rechazará* en esos casos, así que un
`await` sin capturar deja el nodo ahí para siempre. Las cuatro son condiciones normales, no casos límite.

**La comprobación:** dispara la salida y dispárala otra vez de inmediato, o inviértela en pleno vuelo. Luego
inspecciona el árbol. Además: activa el movimiento reducido y confirma que las cosas se siguen eliminando.

---

### C2. La animación es la fuente de verdad

**Síntoma silencioso:** un menú que no está ni abierto ni cerrado tras una transición interrumpida, y una
alternancia posterior que hace lo que no debe.

**Por qué se escribe:** el estado visual y el estado lógico parecen el mismo hecho, así que mantener
una sola variable parece buena higiene.

**El arreglo:** conserva el booleano. Anima hacia él. La prueba de `pitfalls.md` §7 es exacta: **si
borraras todas las animaciones del producto, toda la lógica debería seguir ejecutándose.**

**La comprobación:** pon todas las duraciones a `0.01ms` y usa el producto. Todo debería seguir funcionando.
Luego ponlas a `2s` e interrumpe cosas. La misma respuesta.

---

## D. Confiaste en algo que no verificaste

### D1. Un nombre de API de memoria

**Síntoma silencioso:** en una lectura protegida, nada en absoluto — la protección se lo traga y la funcionalidad queda
permanentemente apagada. En una lectura sin protección, un crash en una ruta de código que nadie ejercita.

```lua
-- ❌ la protección hace que un nombre equivocado sea indistinguible de uno ausente
local ok = pcall(function() reduced = GuiService.ReducedMotion end)
```

**Por qué se escribe:** el nombre está *casi* bien, y el código defensivo es un buen hábito. Juntos
producen una funcionalidad silenciosamente ausente: el peor desenlace posible, porque parece
resuelto.

**La comprobación:** lee el nombre en el propio listado de API de la plataforma antes de publicarlo, no en
tu memoria de él. Una protección es para una propiedad que puede estar *ausente en clientes antiguos*; no es un
sustituto de saberse el nombre. Si una lectura protegida falla, regístralo en desarrollo en lugar de
tirar de un valor por defecto en silencio.

---

### D2. Afirmar una garantía que la documentación no hace

**Síntoma silencioso:** ninguno, hasta que alguien construye sobre la afirmación. Entonces un bug que se rastrea hasta una
frase de un documento en lugar de hasta una línea de código.

**Por qué se escribe:** un componente que obviamente *debería* manejar un caso normalmente lo maneja, y escribir
«maneja X» es más corto que escribir «verifica X tú mismo».

**El arreglo:** enuncia lo que enuncia la documentación. Donde creas que algo es cierto pero no puedas
citarlo, dilo con esas palabras, y di cómo comprobarlo.

**La comprobación:** para cada afirmación de capacidad en lo que escribas, pregúntate dónde lo leíste. «Es de
cajón» no es una fuente.

---

### D3. Números que produjiste a mano

**Síntoma silencioso:** una curva *aproximadamente* correcta. Se anima, parece un spring, y
está mal de una forma que ningún revisor pillará leyendo.

**Por qué se escribe:** una tabla de easing de 21 valores parece la clase de cosa que se puede estimar a partir de
la forma, y el resultado es lo bastante plausible como para pasar un vistazo.

**El arreglo:** calcúlala. `spring.md` §4 da la forma cerrada por régimen de amortiguación; diez líneas de
script producen la tabla. Después comprueba los extremos y el pico contra los números publicados.

**La comprobación:** dos invariantes pillan casi todo: la tabla debe empezar exactamente en `0` y terminar
exactamente en `1`, y su pico debe coincidir con el overshoot de ese `b` en `spring.md` §1. Una curva «rebotona»
que nunca vuelve a bajar *por debajo* de 1 en el retorno no es un spring; es un arco dibujado a mano.

---

## E. Disciplina en el propio documento

### E1. Un identificador de librería en un archivo agnóstico del runtime

**Síntoma silencioso:** una frase que ya no se entiende, y un lector enviado a buscar una API que no
existe en su runtime.

> ❌ Los ítems de dentro: `stagger 0.03`, empezando después de que el contenedor esté en `beforeChildren`.

**Por qué se escribe:** la regla se aprendió de una implementación, y el nombre que le da esa implementación
es más corto que la regla. Cuando el texto de alrededor se reescribe para ser neutral, el
identificador sobrevive porque parece un término técnico.

> ✅ Los ítems de dentro: `stagger 0.03`, empezando sólo una vez que el contenedor haya terminado de abrirse — la
> regla de contenedor-antes-que-hijos de `feel.md` §6.

**La comprobación:** haz grep en los capítulos de criterio buscando el vocabulario de cualquier librería concreta. Un archivo que
abre prometiendo no nombrar ninguna API debería poder demostrarlo.

---

### E2. Una referencia cruzada a la sección equivocada

**Síntoma silencioso:** el lector sigue el puntero, encuentra material sin relación y deja de fiarse en
silencio también de las demás referencias.

**La comprobación:** por cada `§N` que escribas, abre §N. Mecánico, aburrido, y es la comprobación con mayor
tasa de aciertos de este archivo: las referencias cruzadas se pudren cada vez que se reorganiza un documento, y nada
en la cadena de herramientas se da cuenta.

---

## La lista previa al despegue

Recórrela antes de afirmar que una animación está terminada. Está ordenada por la frecuencia con la que cada comprobación salta.

- [ ] Probada la **salida** de cada estado, no sólo la entrada (A4, B3, C1)
- [ ] Mirada la **sombra** específicamente, en hover, en el tema claro (A1, B2)
- [ ] Contadas las propiedades por interacción — tres o más para elevación y pulsación (B2)
- [ ] Hecho grep en las animaciones por `left` / `top` / `width` / `height` (B1)
- [ ] Confirmado que toda duración de spring es `t_settle`, no `Dv` (A2)
- [ ] Vuelta a disparar cada animación cinco veces rápidamente, y luego inspeccionado el árbol (C1)
- [ ] Ejecutado el producto con las duraciones a `0.01ms`, y luego a `2s` (C2)
- [ ] Activado el movimiento reducido y confirmado que las cosas se siguen **eliminando**, y siguen haciendo **fundido** (C1)
- [ ] Leído cada nombre de API en el listado de la plataforma, no de memoria (D1)
- [ ] Recalculada cualquier tabla de números, y comprobados sus extremos y su pico (D3)
- [ ] Abierto cada `§N` que hayas citado (E2)
