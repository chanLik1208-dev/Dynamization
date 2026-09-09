# recipes.md — 26 patrones, como especificaciones

Cada receta enuncia primero su **intención**, luego una especificación que puedes implementar en cualquier runtime, y luego lo único
que suele salir mal. Ninguna receta de aquí nombra una API; lleva los números a tu adaptador.

La notación es la de `SKILL.md` §1: `dur` en segundos, `curve` es `out`/`in`/`inout`/`linear`,
`spring(Dv, b)` es duración visual y rebote, `travel` en px.

---

## 0. Los cimientos

Antes que todo lo demás: define el set de tokens una vez, según `feel.md` §11.

```
feedback :  dur 0.12   curve out
micro    :  dur 0.2    curve out
enter    :  spring(0.3,  0.15)
exit     :  dur 0.15   curve in
layout   :  spring(0.35, 0)
page     :  spring(0.5,  0.1)
stagger  :  0.04
lumin    :  dur 0.13   curve out
```

Todas las recetas de abajo están escritas con estos tokens allí donde encaja alguno. **Si te descubres tecleando una
duración que no está en esta lista, pregúntate por qué este caso es especial**: normalmente no lo es.

---

## 1. Entrada de un elemento

**Intención:** algo nuevo apareció, y vino de un poco más abajo.

| Canal | De → A | Tiempo |
|---|---|---|
| opacidad | `0 → 1` | `dur 0.25  curve out` |
| `y` | `+8px → 0` | `enter` |

La salida es el espejo con `dur 0.15  curve in`, `y → +4px`.

**Ojo con:** `y: +8px` y no `+40px`. La distancia es una afirmación sobre de dónde vino la cosa,
y 40px afirma que vino de fuera de la pantalla.

---

## 2. Stagger de lista

**Intención:** estos ítems son una secuencia, se leen de arriba abajo.

Por ítem: receta 1. Intervalo `stagger` (`0.04`). El contenedor entra en fundido primero, `dur 0.15`.

Invierte la dirección y reduce el intervalo a la mitad en la salida (`0.02`, desde el último) para que la lista se enrolle hacia arriba.

**Ojo con:** haz la aritmética. `intervalo × cantidad ≤ 0.5s`. Pasados los 20 ítems, deja de hacer stagger
individual y haz un fundido del bloque.

---

## 3. Fundido disparado por scroll

**Intención:** esta sección está llegando a medida que llegas a ella.

| Canal | De → A | Tiempo |
|---|---|---|
| opacidad | `0 → 1` | `dur 0.4  curve out` |
| `y` | `+12px → 0` | `dur 0.4  curve out` |

Dispara al **30% visible**. Dispara **una vez** y nunca más.

**Ojo con:** los dos valores por defecto que te da la mayoría de las librerías están mal aquí: disparan a un píxel
de visibilidad, y se repiten en cada pasada. Fija ambos explícitamente.

---

## 4. Botón: movimiento y luminancia juntos

**Intención:** responde al puntero, y se hunde al pulsarlo.

| Estado | Canales | Tiempo |
|---|---|---|
| hover | `scale 1.02` + superficie un paso más brillante | `spring(0.15, 0)` / `lumin` |
| pulsación | `scale 0.97` + brillo `0.96` + sombra `e2 → e1` + sombra interior arriba | `feedback` |
| foco | anillo, ≥ 3:1 contra el entorno | `feedback` |

**Ojo con:** la pulsación debe encoger, no crecer. Y el estado de pulsación debe dispararse también con la activación por teclado,
no sólo con el puntero.

---

## 5. Elevación de tarjeta en hover (que sobreviva a una lista larga)

**Intención:** esta tarjeta se me acercó.

| Canal | De → A | Tiempo |
|---|---|---|
| `y` | `0 → −4px` | `spring(0.2, 0)` |
| `scale` | `1 → 1.01` | `spring(0.2, 0)` |
| sombra | `e2 → e3` | `lumin` |
| superficie | un paso más brillante | `lumin` |

**Ojo con:** no animes la sombra en sí en una lista de tarjetas. Apila detrás de la tarjeta una segunda capa que lleve
`e3` a opacidad 0 y haz un fundido cruzado con ella — `contrast.md` §6. Y mantén el scale en
`1.01`, no en `1.05`: en una tarjeta de 400px, un 5% son 20px de crecimiento empujando a sus vecinas.

---

## 6. Modal (scrim + contenido)

**Intención:** todo lo demás dejó de importar.

Especificación en `contrast.md` §4, «Apertura de modal». Resumen: el scrim con `dur 0.2 curve out` y llega **primero**;
el diálogo con `spring(0.28, 0.1)` desde `scale 0.96`, `y +8px`. Salida a `dur 0.15`, el scrim se va el último.

**Ojo con:** el diálogo no debe empezar en `scale 0`. Y comprueba el scrim en el tema oscuro: un 45%
de negro sobre `#0E0E10` no separa nada.

---

## 7. Tarjeta que se expande en un modal (elemento compartido)

**Intención:** este modal *es* esa tarjeta.

Usa el procedimiento de medir e invertir de `feel.md` §4:

```
1. mide el rect de la tarjeta
2. monta el diálogo en su posición y tamaño finales
3. mídelo
4. transforma el diálogo de vuelta sobre el rect de la tarjeta (translate + scale)
5. anima esa transformación hasta la identidad con `layout`
```

Haz un fundido cruzado entre la salida del contenido de la tarjeta y la entrada del del diálogo durante el primer 60% del movimiento.

**Ojo con:** escalar un rect distorsiona su radio de esquina y su texto. Contra-escala el contenido interior
por el factor inverso, o anima sólo la posición y deja que el tamaño cambie por layout. Si tu
runtime tiene un mecanismo integrado de elemento compartido, prefiérelo: hace ese contra-escalado por ti.

---

## 8. Dropdown / popover (crecido desde el disparador)

**Intención:** esto salió de ese botón.

| Canal | De → A | Tiempo |
|---|---|---|
| origen de la transformación | la esquina más cercana al disparador | — |
| `scale` | `0.95 → 1` | `spring(0.25, 0.1)` |
| opacidad | `0 → 1` | `dur 0.15  curve out` |
| `y` | `−4px → 0` | `spring(0.25, 0.1)` |

Los ítems de dentro: `stagger 0.03`, empezando sólo una vez que el contenedor haya terminado de abrirse — la
regla de contenedor-antes-que-hijos de `feel.md` §6.

**Ojo con:** el origen de la transformación es la receta entera. Un popover que crece desde su propio centro
mientras está bajo un botón se lee como si no tuviera relación con el botón.

---

## 9. Acordeón (altura sin machacar el layout)

**Intención:** el panel se desenrolló.

Mide la altura natural del contenido, luego anima el contenedor de `0` a esa altura, pero hazlo
como una **transformación**, no como una altura, siempre que el runtime lo permita: escala un envoltorio en Y y
contra-escala el contenido, o recorta con una máscara cuya extensión sea una transformación.

El contenido de dentro: opacidad `0 → 1`, `dur 0.2`, retrasado al último 40% de la apertura.

**Ojo con:** si tienes que animar una altura real, al menos mídela una vez y cachéala; medir en cada
frame es donde van los acordeones a morir. Devuelve la altura a `auto` cuando la animación termine, o
el panel no responderá a los cambios de contenido.

---

## 10. Subrayado de pestañas (se desliza, no parpadea)

**Intención:** la selección se movió de allí a aquí.

Un único elemento de subrayado, compartido. Al cambiar la selección, anima su `x` y su `width` hasta el rect de la
nueva pestaña con `layout` — `spring(0.35, 0)`.

**Ojo con:** `width` es una propiedad de layout. Usa `scaleX` sobre una barra de ancho fijo con el origen de la transformación a la
izquierda, y no contra-escales nada (un subrayado no tiene contenido que distorsionar). Éste es el único sitio donde escalar
un rect sale gratis.

---

## 11. Pila de toasts

**Intención:** llegó un mensaje a la esquina en la que vive.

| Canal | De → A | Tiempo |
|---|---|---|
| `x` (para una pila a la derecha) | `+24px → 0` | `enter` |
| opacidad | `0 → 1` | `dur 0.2 curve out` |
| toasts existentes | se desplazan hacia abajo la altura del nuevo | `layout` |

Salida: `x → +16px`, opacidad `→ 0`, token `exit`, y los toasts restantes cierran el hueco con `layout`.

**Ojo con:** el *cierre del hueco* es la parte que hace que una pila se sienta real. Los toasts que se desvanecen y
dejan a los demás teletransportándose a su sitio deshacen todo el efecto.

---

## 12. Arrastrar para reordenar

**Intención:** estoy sujetando esto, y los demás están haciendo sitio.

| Canal | Valor |
|---|---|
| ítem sujetado | `scale 1.03`, sombra `e4`, elevado por encima de sus hermanos, sigue al puntero **1:1** |
| otros ítems | se desplazan una ranura con `layout` — `spring(0.35, 0)` |
| soltar | spring hasta la ranura de destino, sembrado con la velocidad del puntero al soltar |
| más allá de los bordes | resistencia elástica, la mitad de la entrada, vuelve con spring |

**Ojo con:** el ítem sujetado debe seguir al puntero exactamente, sin ningún easing. Cualquier suavizado
entre dedo y objeto destruye la ilusión de sujetarlo: el spring va en los *otros*
ítems, y en el momento de soltar.

---

## 13. Barra de progreso de scroll

**Intención:** cuánto llevo recorrido.

`scaleX` de `0 → 1`, origen de la transformación a la izquierda, atado directamente al progreso del scroll, `curve linear`,
suavizado con `spring(0.2, 0)`.

**Ojo con:** ésta es la única animación que debería ser `linear`. Es una medición, no un
movimiento.

---

## 14. Parallax

**Intención:** esa capa está más lejos.

La `y` del fondo se mueve a `0.3–0.5×` el delta de scroll del primer plano. Suaviza la entrada de scroll con
`spring(0.35, 0)`.

**Ojo con:** inicializa el spring en la posición de scroll actual al montar, o la página barrerá
desde arriba al cargar. Y ramifica esto por completo con movimiento reducido: el parallax es el peor
infractor de todos para el malestar vestibular.

---

## 15. Sección de scroll horizontal

**Intención:** el scroll vertical impulsa el recorrido horizontal.

Fija la sección con el mecanismo sticky nativo de la plataforma. Mapea el progreso de scroll de la región fijada
`0 → 1` sobre la `x` de la pista, `0 → −(trackWidth − viewportWidth)`, `curve linear`, suavizado con
`spring(0.3, 0)`.

**Ojo con:** la fijación debe ser nativa. Escribir una posición en cada frame desde un manejador de scroll va un
frame por detrás del compositor y trepida a la vista.

---

## 16. Revelado de imagen por scroll

**Intención:** la imagen se va destapando mientras haces scroll.

Anima un **recorte** de `inset 100% 0 0 0` a `inset 0`, mapeado al progreso de scroll a lo largo de la entrada del
elemento, `curve linear`. Opcionalmente escala la imagen `1.1 → 1` en el mismo rango para que el
contenido se mueva a un ritmo distinto que la máscara.

**Ojo con:** el recorte es barato; animar la altura del elemento no lo es. Y limita el contra-escalado: un
arranque en `1.3` se ve visiblemente blando al principio.

---

## 17. Texto dividido

**Intención:** la frase se ensambló sola.

Divide en caracteres o palabras, luego aplica la receta 1 por fragmento con `stagger 0.02` (caracteres) o
`0.04` (palabras).

| Cantidad | Dividir por |
|---|---|
| ≤ 40 caracteres | caracteres |
| más | palabras |
| un párrafo | líneas, o no dividir |

**Ojo con:** la accesibilidad. El contenedor lleva el texto completo como etiqueta accesible y los
fragmentos quedan ocultos a la tecnología asistiva, o un lector de pantalla leerá tu titular letra
a letra. Además: dividir infla el número de elementos una vez, lo cual está bien, pero volver a dividir
en cada cambio de tamaño no lo está.

---

## 18. Revelado palabra a palabra por scroll

**Intención:** me están leyendo el párrafo mientras hago scroll.

La opacidad de cada palabra va de `0.2 → 1`, mapeada al progreso de scroll a lo largo del párrafo, con el rango de cada
palabra desfasado por su índice para que una ola recorra el texto.

**Ojo con:** el valor de reposo es `0.2`, no `0`, para que la forma del párrafo sea visible antes de que se
resuelva. Pero ver `contrast.md` §7: aquí `0.2` es un estado *transitorio*, que pasa en menos de un segundo.
Nunca dejes texto aparcado en una opacidad medio legible.

---

## 19. Máquina de escribir con ritmo humano

**Intención:** alguien está escribiendo esto.

Intervalo base de `0.045s` por carácter, con:
- `× 0.5` para un carácter repetido
- `+ 0.12s` después de una coma, `+ 0.3s` después de un punto
- `± 30%` de jitter aleatorio por carácter

Una máquina de escribir perfectamente regular se lee como una máquina, que es lo contrario de la intención.

**Ojo con:** reescribir el contenido del texto en cada frame fuerza un re-layout de texto en cada frame. Reserva
el tamaño final de antemano (una altura fija, o una copia oculta del texto completo que fije la caja) para que el
layout de alrededor no haga reflow 40 veces.

---

## 20. Número animado

**Intención:** el valor subió.

Haz un tween del número, `dur 0.6  curve out`, redondeando para mostrarlo. Formatea con un **estilo de cifras tabular /
monoespaciado** para que los anchos de los dígitos no cambien.

Para un rodillo por dígito, traslada verticalmente una tira de `0–9` por cada posición decimal con `spring(0.4, 0.1)`,
con stagger de `0.03` desde el dígito menos significativo.

**Ojo con:** sin cifras tabulares el número tiembla visiblemente de ancho mientras cuenta, lo que se lee
como roto en lugar de como vivo.

---

## 21. Dibujo de línea

**Intención:** el trazo se está dibujando.

Anima el desplazamiento del guionado del trazo de «totalmente oculto» a «totalmente dibujado» — `dur 0.8  curve out`, o
mapeado al scroll. Con varios trazados: `stagger 0.1`.

**Ojo con:** necesitas la longitud total del trazado. Mídela en lugar de adivinarla, y vuelve a medirla si
el trazado es responsive.

---

## 22. Brillo de skeleton

**Intención:** sigo aquí, sigo trabajando.

Una banda de degradado barriendo el marcador de posición, `dur 1.5–2s`, `curve linear`, en repetición, con la
banda a muy bajo contraste contra el marcador: alrededor de un 4% de diferencia de luminancia.

**Ojo con:** un brillo de alto contraste o rápido compite con el contenido al que está sustituyendo. Y
no muestres nada por debajo de 1 segundo: un skeleton que parpadea es peor que un momento quieto.

---

## 23. Transición de ruta / pantalla

**Intención:** me moví a otro sitio.

Saliente: opacidad `1 → 0`, `y → −8px`, `dur 0.15  curve in`.
Entrante: opacidad `0 → 1`, `y +8px → 0`, token `page` — **después** de que la saliente haya terminado.

**Ojo con:** correr las dos a la vez hace un fundido cruzado de dos pantallas completas, que queda turbio a cualquier duración.
Secuéncialas. Y si el mecanismo de transición que te da tu plataforma salta al estado final al ser
interrumpido, no lo uses para un botón de atrás que la gente pulsa dos veces.

---

## 24. Límite elástico

**Intención:** has llegado al borde, y el borde es una regla en lugar de un muro.

Pasado el tope, aplica **la mitad** del delta de entrada (`offset = overshoot × 0.5`), con la resistencia creciendo
a medida que crece el overshoot si quieres ponerte fino. Al soltar, `spring(0.4, 0)` de vuelta al tope,
sembrado con la velocidad de soltado.

**Ojo con:** el factor de resistencia es toda la sensación. En `1.0` no hay límite; en `0.1`
se siente roto. `0.5` es el valor al que convergieron casi todas las plataformas.

---

## 26. Resalte a primera vista

**Intención:** esta frase es el punto del párrafo, y te la estás encontrando por primera vez.

Un bloque sólido del color de acento barre la frase, se mantiene, y luego cae a un tinte claro que se queda.
Las palabras no están ahí durante el barrido: llegan con el fundido.

| Fase | Canal | De → A | Tiempo |
|---|---|---|---|
| barrido | ancho del bloque | `0% → 100%`, desde la izquierda | `dur 0.42  curve out` |
| espera | — | acento sólido, sin texto | `0.13s` — un compás, no una pausa |
| asentamiento | bloque | acento → acento al `20–30%` — sigue siendo obviamente el color de acento, no un gris | `dur 0.45  curve inout` |
| asentamiento | texto | transparente → tinta | termina en torno al 88% del conjunto |

El estado en reposo —tinte claro más texto enfatizado— es el estilo **base**. La animación es aditiva, así
que un lector sin script, sin `IntersectionObserver` o con movimiento reducido recibe igualmente el énfasis
y sólo pierde el trazo.

Dispárala una vez, según `recipes.md` §3. Como mucho cuatro o cinco frases en una página entera: esta
animación no transporta información, sólo dirige la atención, y la atención dirigida a todas partes no está
dirigida a ninguna.

**Ojo con:** cuatro cosas, y cada una de ellas ha mordido a la implementación de referencia de este mismo
pack.

- **Nunca animes el grosor de la fuente.** Los cambios de grosor alteran los anchos de avance y rehacen el
  flujo de la línea. Fija el grosor del énfasis una vez, de forma estática, y anima sólo el bloque.
- **Un bloque sólido esconde el texto en tinta.** O calas el texto al token de fondo de la página —que es
  claro en un tema claro y casi oscuro en uno oscuro, así que un solo token es correcto en ambos— o, como se
  especifica arriba, no muestras texto en absoluto durante la fase sólida. Lo que no puedes hacer es dejar
  texto oscuro sobre un bloque oscuro, ni siquiera durante 200ms.
- **Si el estado en reposo esconde el texto, una frase que nunca recibe su animación simplemente falta en la
  oración.** Ponle una guarda: si el observador no ha disparado en unos segundos y la frase está en
  pantalla, ejecútala igualmente → `errata.md` §A7.
- **Una frase dentro de una sección que hace fundido de entrada tiene que esperarla** → `errata.md` §A6.
- **Suaviza cada segmento, incluido el asentamiento.** Una animación de varias fases se suele escribir
  como una sola forma abreviada con una única función de tiempo, y si esa función es `linear` el conjunto
  entero se arrastra a velocidad constante salvo allí donde un fotograma clave la sobrescribe. El barrido
  es el segmento que la gente se acuerda de suavizar; el asentamiento es el que olvida, y un asentamiento
  que se para en seco es lo que significa «el fundido se ve mal». Fija la curva por segmento, en los
  fotogramas clave.
- **Una espera es un compás, no una pausa, y el asentamiento tiene que salir suavizado de ella.** Dos
  errores que producen la misma queja: *se queda pegado y luego desaparece*. Una espera lo bastante
  larga como para ser del todo estática (bastante más allá de `0.15s`) deja de leerse como énfasis y
  empieza a leerse como un tirón. Y `curve out` en el asentamiento es un error aquí aunque sea lo
  correcto casi en todas partes: easeOut carga su cambio al principio, así que el color se vuelca en el
  primer quinto del segmento y el bloque parece desaparecer en vez de calmarse. Usa `curve inout`: sale
  de la espera con suavidad y decelera hasta el reposo.
- **Deja que las palabras aterricen antes de que el bloque termine.** Una señal de estado llega más
  rápido que la superficie que la transporta (`contrast.md` §5): termina el texto en torno al 85% de la
  animación y deja que el bloque siga suavizando hasta el 100%. Hacer un fundido cruzado de ambos al
  mismo ritmo queda turbio.

## 25. Ramificar según el movimiento reducido

**Intención:** la misma información, sin el coste vestibular.

| Normal | Reducido |
|---|---|
| cambios de `y`, `x`, `scale` | eliminados por completo |
| opacidad, color, brillo | **conservados**, a las mismas duraciones |
| parallax, movimiento vinculado al scroll | eliminados; muestra el estado final |
| bucles infinitos, vídeo con reproducción automática | detenidos, con un control para iniciarlos |
| transiciones de elemento compartido | reemplazadas por un fundido cruzado |

**Ojo con:** «reducido» no significa «ninguno». Quitar todas las transiciones deja al usuario sin
señal alguna de que la pantalla cambió, lo cual es un fallo de accesibilidad por sí mismo. Conserva el fundido.
