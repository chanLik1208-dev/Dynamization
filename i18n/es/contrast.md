# contrast.md — El poder expresivo de la luz y la oscuridad

El movimiento es el lenguaje del **tiempo**: de dónde vino una cosa, adónde se fue.
La luminancia es el lenguaje del **espacio**: qué está encima, qué está vivo, dónde hay que mirar ahora mismo.

Cada uno hace la mitad del trabajo por su cuenta. **«Elevar» no es mover algo 8px hacia arriba. Es 4px hacia arriba + una sombra
más grande y más suave + una superficie más brillante: tres cosas a la vez, que es cuando el cerebro por fin lee
*eso se me acercó*.** Este archivo va de cablear la luminancia dentro del movimiento.

La óptica de aquí no es específica de una plataforma. Sólo §6 menciona propiedades concretas, y sólo como
ejemplos de una jerarquía de coste que tiene todo renderizador.

---

## 1. El modelo mental: la luz viene de arriba

La visión humana asume que la fuente de luz está por encima. Toda decisión de luminancia se apoya en eso, y
violarlo resulta inquietante o barato.

| Para expresar | Disposición de la luminancia |
|---|---|
| **Elevado** (botón, tarjeta, popover) | borde superior tenue y brillante (luz de contorno) + sombra debajo |
| **Hundido** (input, ranura, estado pulsado) | sombra interior arriba + brillo tenue abajo |
| **A ras** (fondo, separadores) | ninguna sombra, sólo una diferencia en el valor de la superficie |
| **Flotando alto** (modal, en pleno arrastre) | una sombra amplia, de baja opacidad y muy desenfocada |

Mayor elevación significa una sombra **más grande, más suave y más tenue**, no más oscura.

El error de principiante es profundizar el negro de la sombra para expresar «más alto», lo que sólo se lee como
*más sucio*. La jugada correcta aumenta el **desenfoque** y el **desplazamiento en y** mientras **baja** el alfa.

Una escalera de cuatro niveles, como offset / blur / alfa — éstos son los números, los expreses como los expreses:

| Tier | Significado | Capa de contacto | Capa ambiental |
|---|---|---|---|
| **e1** | apoyado sobre la superficie | `0 1px 2px  / 8%` | — |
| **e2** | tarjeta | `0 1px 2px  / 5%` | `0 2px 6px  / 7%` |
| **e3** | popover, dropdown | `0 2px 6px  / 5%` | `0 8px 20px / 6%` |
| **e4** | modal, en pleno arrastre | `0 4px 12px / 4%` | `0 20px 48px / 5%` |

La estructura de dos capas es la clave: una capa ceñida (la **sombra de contacto**, que dice que el objeto
tiene grosor) y una capa amplia y difusa (**oclusión ambiental**, que dice a qué distancia está). Una
sombra de una sola capa siempre parece una pegatina.

**Si tu renderizador no tiene una primitiva de sombra** —la mayoría de los runtimes de juego y de UI 3D no la tienen— obtienes las
mismas dos capas con dos imágenes nine-slice apiladas detrás del elemento: una pequeña y ceñida al
propio rect del elemento más unos pocos píxeles, y una grande y desenfocada extendida bien más allá. Anima su
*alfa*, nunca su tamaño. Todo lo demás en este archivo se aplica sin cambios.

---

## 2. Los temas oscuros expresan la elevación con otro mecanismo — esto es lo que se hace mal

**Sobre una superficie oscura, las sombras son invisibles.** Una sombra negra proyectada sobre casi-negro no tiene contraste con el que
trabajar.

Portar las sombras de un tema claro directamente a un tema oscuro produce *que todas las capas desaparezcan y
la pantalla se quede plana*.

Los temas oscuros usan el mecanismo opuesto: **las superficies más altas son más brillantes.** (La intuición física:
una superficie más cercana a la luz recibe más luz.)

| Capa | Tema claro | Tema oscuro |
|---|---|---|
| Fondo | `#FFFFFF` | `#0E0E10` |
| Superficie / tarjeta | `#FFFFFF` + e2 | `#17171A` (≈5% más claro) |
| Popover / dropdown | `#FFFFFF` + e3 | `#1F1F23` (≈8% más claro) |
| Modal | `#FFFFFF` + e4 | `#26262B` (≈12% más claro) |

**Así que cambiar de tema no es cambiar una paleta: es cambiar el mecanismo que expresa las
capas.** Un set de tokens correcto cambia las dos cosas a la vez:

| Token | Claro | Oscuro |
|---|---|---|
| `surface` | `#FFFFFF` | `#0E0E10` |
| `elevated` | `#FFFFFF` (igual — la altura viene de la sombra) | `#1F1F23` (**distinto** — la altura viene de aquí) |
| `shadow-e2` | `0 2px 6px / 7%` + `0 1px 2px / 5%` | `0 2px 8px / 50%` — sigue anclando el objeto, ya no carga con las capas |
| `rim` | inset arriba `1px` blanco `60%` | inset arriba `1px` blanco `7%` — **mucho más débil** |

Esa fila de `rim` es la que se olvida la gente. Un borde superior brillante ajustado para un tema claro se convierte en un
filo blanco luminoso sobre una superficie oscura.

Tres reglas prácticas más para los temas oscuros:

- **No uses negro puro.** En OLED el límite entre contenido y fondo se emborrona, y el texto
  blanco sobre negro puro es duro a alto contraste. Algo en el rango `#0E–#14` es más fácil de
  sobrellevar.
- **No uses blanco puro para el texto de cuerpo.** Baja a alrededor de `#E8E8EA`; la lectura larga se hace mucho
  más fácil.
- **Desatura y aclara los colores saturados.** Un color de marca ajustado para un tema claro normalmente
  fluoresce contra uno oscuro.

---

## 3. Tres trabajos para el contraste — no los mezcles

| Trabajo | Técnica | Esto no |
|---|---|---|
| **Capas** (qué está encima) | brillo de la superficie + sombra | bordes (un borde dice *partición*, no *altura*) |
| **Foco** (dónde mirar) | atenuar todo lo demás (scrim) | hacer más brillante el objetivo (una carrera armamentística que acaba con todo brillante) |
| **Estado** (vivo / deshabilitado / seleccionado) | tokens de color explícitos | la opacidad por sí sola (ver abajo) |

**El foco funciona atenuando el entorno, no iluminando el objetivo.** Una pantalla sólo aguanta
unas pocas cosas brillantes, así que el enfoque de iluminar falla rápido. Atenuar siempre funciona, porque el
contraste es relativo.

**No expreses «deshabilitado» con un 50% de opacidad.** Un elemento translúcido recoge lo que tenga detrás,
así que se renderiza distinto sobre fondos distintos, y arrastra el contraste del texto por debajo de la legibilidad. Usa
un token `text-disabled` dedicado.

---

## 4. Cablear la luminancia dentro del movimiento: expresión compuesta

Esto es lo que significa realmente «expresión reforzada»: una sola propiedad carga con demasiada poca
información, y **sólo el cambio multipropiedad en la misma dirección se lee como un único evento físico.**

Cada una de éstas está escrita como una especificación que puedes entregarle a cualquier runtime.

### Elevación (hover de tarjeta)

| Canal | De → A | Tiempo |
|---|---|---|
| `y` | `0 → −4px` | `spring(0.2, 0)` |
| `scale` | `1 → 1.01` | `spring(0.2, 0)` |
| sombra | `e2 → e3` (más grande y más suave, **no más oscura**) | `dur 0.2  curve out` |
| superficie | `surface → surface-hover` (claro: apenas se mueve / oscuro: **más brillante**) | `dur 0.2  curve out` |

El movimiento quiere un spring, porque puede ser interrumpido por el cursor al salir. La luminancia no:
ahí un tween normal es lo correcto, y separar las dos cosas por esa línea es el menor trabajo en la mayoría de los
runtimes. Donde tu plataforma tenga una capa declarativa barata para cambios de estado (`:hover` de CSS, una hoja de
estilos, una máquina de estados de UI), pon la luminancia ahí y deja sólo el movimiento en código.

### Pulsación (hundimiento)

| Canal | De → A | Tiempo |
|---|---|---|
| `scale` | `1 → 0.97` | `spring(0.15, 0)` |
| sombra | `e2 → e1` **más** una sombra interior, arriba, `1–2px`, negro `12%` | `dur 0.1  curve out` |
| brillo | `1 → 0.96` | `dur 0.1  curve out` |

**Encoger + oscurecer + contracción de la sombra** juntos significan *empujado hacia dentro*. Encoger a solas sólo significa
*se hizo más pequeño*: una afirmación completamente distinta.

### Arrastre (agarrado)

| Canal | De → A | Tiempo |
|---|---|---|
| `scale` | `1 → 1.04` | `spring(0.2, 0)` |
| sombra | `e2 → e4`, exagerada: `0 24px 48px / 18%` | `dur 0.15  curve out` |
| orden de profundidad | elevado por encima de sus hermanos | inmediato |

El arrastre es el único sitio donde una sombra teatral es lo correcto: el objeto tiene que abandonar visiblemente el plano,
o el usuario no está seguro de tenerlo cogido.

### Apertura de modal (foco)

La atenuación y el contenido empiezan juntos, pero **el fondo llega primero**:

| Canal | De → A | Tiempo |
|---|---|---|
| opacidad del scrim | `0 → 1` | `dur 0.2  curve out` ← termina primero |
| opacidad del diálogo | `0 → 1` | `dur 0.2  curve out` |
| `scale` del diálogo | `0.96 → 1` | `spring(0.28, 0.1)` |
| `y` del diálogo | `+8px → 0` | `spring(0.28, 0.1)` |

La salida lo invierte con la asimetría de `feel.md` §5: `dur 0.15`, `scale → 0.98`, `y → +4px`, y
el scrim se va **el último**.

Valor del scrim: negro al `40–50%` en un tema claro. En un tema oscuro tiene que funcionar **de otra manera**: un 50%
de negro sobre casi-negro no consigue nada, así que o subes mucho la opacidad o sacas el contraste
iluminando el propio diálogo.

Un desenfoque de fondo es caro en todas partes (repinta o vuelve a muestrear toda la capa de debajo).
Va bien sobre un área pequeña; mídelo a pantalla completa, y plantéate publicar un scrim plano en dispositivos de gama
baja.

---

## 5. La luminancia cambia más rápido que el movimiento

La luminancia es una **señal de estado**; el desplazamiento es un **proceso**. El estado debe confirmarse de inmediato; al
proceso se le permite tomarse su tiempo.

| Cambio | Duración |
|---|---|
| brillo / cambio de color | `0.1 – 0.15s` |
| cambio de nivel de sombra | `0.15 – 0.2s` |
| aparición del scrim | `0.15 – 0.2s` (llega antes que el contenido) |
| movimiento simultáneo | `0.2 – 0.35s` |

Si la luminancia va tan lenta como el movimiento, se lee como *el color persiguiendo al objeto*.
**Deja que el brillo llegue primero y la posición segunda.**

---

## 6. Rendimiento: qué propiedades de luminancia se pueden animar de verdad

La jerarquía es la misma en todas partes, incluso cuando los nombres de las propiedades no lo son:

| Tipo de cambio | Coste | Recomendación |
|---|---|---|
| opacidad de una capa existente | ✅ composición | siempre seguro |
| un filtro de brillo/tinte sobre una capa | ✅ normalmente composición | la primera opción para brillo animado |
| color de relleno o de fondo | ⚠️ paint | bien en áreas pequeñas, mídelo a pantalla completa |
| una sombra, sobre todo desenfocada | ⚠️ paint, el coste escala con el radio de desenfoque **y** con el área | ver el rodeo de abajo |
| un desenfoque de fondo o de la capa de detrás | ❌ caro | sólo áreas pequeñas, o conmútalo en vez de animarlo |
| radio de esquina, grosor de trazo | ⚠️ paint, a menudo vuelve a teselar | prefiere un recorte o una máscara pre-renderizada |

**El rodeo estándar, y se generaliza:** nunca animes la propiedad cara. Pre-renderiza
**ambos** estados como capas apiladas y haz un fundido cruzado de su opacidad.

Para una sombra eso significa una capa superpuesta detrás del elemento que lleve el nivel *superior*, en reposo a
opacidad 0, subiendo a 1 en hover. La sombra en sí nunca se repinta; sólo cambia un valor de alfa. En
una lista larga —decenas de tarjetas con hover en secuencia— la diferencia es dramática.

**Una precondición, y es la razón por la que esta técnica suele fallar: el elemento no debe recortar.**
Una sombra pinta fuera de su propia caja, así que cualquier `overflow: hidden` —el reflejo automático ante una tarjeta redondeada con
una imagen arriba— borra la capa superpuesta por completo, y la borra en silencio, porque el fundido cruzado
sigue corriendo sobre una capa que nadie puede ver. Recorta el medio, no la tarjeta. → `errata.md` §A1

La misma jugada sirve para el radio de esquina (dos máscaras pre-renderizadas), para una rampa de color (dos rellenos) y
para un desenfoque (dos copias pre-desenfocadas). Cuesta memoria y compra frames.

---

## 7. Mínimos de accesibilidad

La luminancia es un medio de expresión, pero **no puede ser el único portador de información**, y tiene
límites numéricos que no puedes cruzar.

- Texto de cuerpo contra su fondo: **≥ 4.5:1**. Texto grande (18.66px en negrita, o 24px) y los
  límites de los componentes interactivos: **≥ 3:1**.
- **Nunca señalices un estado sólo con el brillo.** «El seleccionado es el más brillante» no existe para
  usuarios con baja visión o diferencias en la visión del color: acompáñalo siempre con forma, un icono, un borde
  o texto.
- El indicador de foco debe alcanzar **3:1** contra su entorno y **no debe depender sólo del
  brillo**. El fallo habitual en tema oscuro es un anillo de foco gris pálido que desaparece por completo sobre una superficie
  oscura. Verifica el anillo de foco por separado en ambos temas.
- Los estados intermedios durante una animación deben seguir siendo legibles. Un texto entrando en fundido a un contraste de 2:1 está,
  para parte de tu audiencia, en blanco durante toda esa duración. **Empezar una entrada en opacidad 0 está bien;
  lo que hay que evitar es aparcar en un valor «medio legible» como `0.3` como estado de reposo.**
- **Conserva los cambios de luminancia con movimiento reducido.** Es exactamente ahí donde se ganan su sitio: con
  el movimiento y el escalado apagados, el brillo y el color siguen comunicando *el estado cambió*,
  sin inducir vértigo.

---

## 8. Lista de comprobación

Recórrela después de construir cualquier cosa con capas o estados:

- [ ] ¿Lo has mirado en **tema oscuro**? ¿Siguen viéndose las capas? (Normalmente no: cambia a brillo de superficie.)
- [ ] ¿Las sombras son de dos capas (ceñida + difusa)? Una sola capa parece una pegatina.
- [ ] ¿«Más alto» se expresa como más grande y más suave, en lugar de más oscuro?
- [ ] ¿La luz de contorno está debilitada para el tema oscuro, en lugar de arrastrada tal cual?
- [ ] ¿El hover y la pulsación cambian **movimiento y luminancia juntos**? Uno solo reduce la expresión a la mitad.
- [ ] ¿El brillo cambia más rápido que el desplazamiento?
- [ ] ¿«Deshabilitado» es un token de color dedicado en lugar de un 50% de opacidad?
- [ ] ¿El anillo de foco llega a 3:1 en *ambos* temas?
- [ ] ¿Hay algún estado distinguido **sólo** por el brillo?
- [ ] En listas largas, ¿la sombra de hover es una capa superpuesta con fundido cruzado en lugar de una sombra animada?
- [ ] ¿El área de desenfoque de fondo está acotada?
