# contrast.md — El poder expresivo de la luz y la sombra

El movimiento es el lenguaje del **tiempo**: de dónde vino algo, adónde fue.
La luminancia es el lenguaje del **espacio**: qué está encima, qué está vivo, dónde mirar ahora.

Cada uno por separado hace la mitad del trabajo. **«Elevarse» no es mover algo 8px hacia arriba. Es
4px de desplazamiento + una sombra más grande y difusa + una superficie más clara — tres cosas a la
vez, que es cuando el cerebro por fin lee *eso se acercó a mí*.** Este archivo trata de cómo conectar
la luminancia con el movimiento.

---

## 1. El modelo mental: la luz viene de arriba

La visión humana asume que la fuente de luz está por encima. Toda decisión de luminancia se apoya en
eso, y violarlo resulta inquietante o barato.

| Para expresar | Disposición de luminancia |
|---|---|
| **Elevado** (botón, tarjeta, popover) | borde superior levemente claro (luz de contorno) + sombra abajo |
| **Hundido** (campo de entrada, ranura, estado pulsado) | sombra interior arriba + leve claridad abajo |
| **A ras** (fondo, separadores) | ninguna sombra, solo una diferencia de valor de superficie |
| **Flotando alto** (modal, en pleno arrastre) | una sombra amplia, de baja opacidad y muy difuminada |

Más elevación significa una sombra **más grande, más suave y más tenue**, no más oscura.

El error de principiante es oscurecer el negro de `box-shadow` para expresar «más alto», lo que
simplemente se lee como *más sucio*. El movimiento correcto aumenta `blur` y `y-offset` mientras
**baja** el alfa.

```css
--shadow-1: 0 1px 2px  rgb(0 0 0 / .08);                              /* apoyado en la superficie */
--shadow-2: 0 2px 6px  rgb(0 0 0 / .07), 0 1px 2px rgb(0 0 0 / .05);  /* tarjeta */
--shadow-3: 0 8px 20px rgb(0 0 0 / .06), 0 2px 6px rgb(0 0 0 / .05);  /* popover */
--shadow-4: 0 20px 48px rgb(0 0 0 / .05), 0 4px 12px rgb(0 0 0 / .04);/* modal */
```

La estructura de dos capas es lo esencial: una capa ceñida (la sombra de contacto, que dice que el
objeto tiene grosor) y una amplia y difusa (oclusión ambiental, que dice a qué distancia está). Una
sombra de una sola capa siempre parece una pegatina.

---

## 2. Los temas oscuros expresan la elevación con otro mecanismo — aquí es donde más se falla

**Sobre una superficie oscura, las sombras son invisibles.** Una sombra negra proyectada sobre un
casi-negro no tiene contraste con el que trabajar.

Trasladar las sombras de un tema claro directamente a uno oscuro produce *la desaparición de todas
las capas y una pantalla plana*.

Los temas oscuros usan el mecanismo opuesto: **las superficies más altas son más claras.**
(La intuición física: una superficie más cercana a la luz recibe más luz.)

| Capa | Tema claro | Tema oscuro |
|---|---|---|
| Fondo | `#FFFFFF` | `#0E0E10` |
| Superficie / tarjeta | `#FFFFFF` + shadow-2 | `#17171A` (≈5% más claro) |
| Popover / desplegable | `#FFFFFF` + shadow-3 | `#1F1F23` (≈8% más claro) |
| Modal | `#FFFFFF` + shadow-4 | `#26262B` (≈12% más claro) |

**Por tanto cambiar de tema no es intercambiar una paleta, es intercambiar el mecanismo que expresa
la estratificación.** Un juego de tokens correcto cambia ambas cosas a la vez:

```css
:root {
  --surface:   #ffffff;
  --elevated:  #ffffff;
  --shadow-e2: 0 2px 6px rgb(0 0 0 / .07), 0 1px 2px rgb(0 0 0 / .05);
  --rim:       inset 0 1px 0 rgb(255 255 255 / .6);   /* borde superior claro */
}
:root:not([data-theme="light"]) {
  @media (prefers-color-scheme: dark) {
    --surface:   #0e0e10;
    --elevated:  #1f1f23;                              /* elevación mediante brillo */
    --shadow-e2: 0 2px 8px rgb(0 0 0 / .5);            /* la sombra sigue anclando, pero ya no carga la estratificación */
    --rim:       inset 0 1px 0 rgb(255 255 255 / .07); /* el contorno debe ser mucho más débil */
  }
}
[data-theme="dark"] { /* repítelo, para que un cambio explícito gane en ambas direcciones */ }
```

Tres reglas prácticas más para los temas oscuros:

- **No uses negro puro `#000`.** En OLED el límite entre contenido y fondo se emborrona, y el texto
  blanco sobre negro puro resulta agresivo por exceso de contraste. Algo en el rango `#0E–#14` es más
  llevadero.
- **No uses blanco puro `#FFF` para el texto de cuerpo.** Baja a alrededor de `#E8E8EA`; la lectura
  larga se vuelve mucho más cómoda.
- **Desatura y aclara los colores saturados.** Un color de marca ajustado para un tema claro suele
  fluorescer contra uno oscuro.

---

## 3. Tres funciones del contraste — no las mezcles

| Función | Técnica | Esto no |
|---|---|---|
| **Estratificación** (qué está encima) | brillo de superficie + sombra | bordes (un borde dice *partición*, no *altura*) |
| **Foco** (dónde mirar) | atenuar todo lo demás (velo) | aclarar el objetivo (una carrera armamentística que acaba con todo brillante) |
| **Estado** (vivo / deshabilitado / seleccionado) | tokens de color explícitos | solo `opacity` (ver abajo) |

**El foco funciona atenuando el entorno, no aclarando el objetivo.** Una pantalla solo admite un
número limitado de cosas brillantes, así que el enfoque de aclarar fracasa rápido. Atenuar siempre
funciona, porque el contraste es relativo.

**No expreses «deshabilitado» con `opacity: 0.5`.** Un elemento translúcido recoge lo que hay detrás,
así que se renderiza distinto sobre fondos distintos, y arrastra el contraste del texto por debajo de
lo legible. Usa un token `--text-disabled` dedicado.

---

## 4. Conectar la luminancia con el movimiento: expresión compuesta

Esto es lo que significa realmente «reforzar la expresión»: una sola propiedad transporta demasiada
poca información, y **solo el cambio multi-propiedad en la misma dirección se lee como un único
suceso físico.**

### Elevación (hover de tarjeta)

```jsx
<motion.article
  initial={false}
  whileHover={{ y: -4, scale: 1.01 }}
  transition={{ type: "spring", visualDuration: 0.2, bounce: 0 }}
  className="card"     // el CSS se encarga de la transición de sombra y brillo
/>
```
```css
.card {
  background: var(--surface);
  box-shadow: var(--shadow-2);
  transition: box-shadow .2s ease-out, background-color .2s ease-out;
}
.card:hover {
  box-shadow: var(--shadow-3);          /* más grande y difusa, no más oscura */
  background: var(--surface-hover);     /* tema claro: apenas cambia / tema oscuro: más claro */
}
```
El movimiento va a Motion (debe ser interrumpible y accionado por muelle); la luminancia va al CSS
(una transición simple, sin lógica de interrupción). Ese reparto es el que menos trabajo da en la
mayoría de los casos.

### Pulsación (hundimiento)

```jsx
whileTap={{ scale: 0.97 }}
```
```css
.btn:active {
  box-shadow: var(--shadow-1), inset 0 1px 2px rgb(0 0 0 / .12);  /* la sombra se contrae + sombra interior */
  filter: brightness(0.96);                                        /* y se oscurece */
}
```
**Encoger + oscurecer + contraer la sombra** juntos significan *empujado hacia dentro*. Solo encoger
significa *se hizo más pequeño*, una afirmación completamente distinta.

### Arrastrando (levantado)

```jsx
whileDrag={{ scale: 1.04, boxShadow: "0 24px 48px rgb(0 0 0 / .18)" }}
```
El arrastre es el único lugar donde una sombra teatral es correcta: el objeto tiene que abandonar el
plano de forma visible, o el usuario no está seguro de haberlo agarrado.

### Apertura de modal (foco)

La atenuación y el contenido empiezan juntos, pero **el fondo aterriza primero**:

```jsx
<AnimatePresence>
  {open && (
    <>
      <motion.div className="scrim"
        initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
        transition={{ duration: 0.2, ease: "easeOut" }} />
      <motion.div className="dialog"
        initial={{ opacity: 0, scale: 0.96, y: 8 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.98, y: 4 }}
        transition={{ type: "spring", visualDuration: 0.28, bounce: 0.1 }} />
    </>
  )}
</AnimatePresence>
```
```css
.scrim { background: rgb(0 0 0 / .45); backdrop-filter: blur(2px); }
```
Opacidad del velo: `0.4–0.5` en un tema claro. En un tema oscuro tiene que funcionar **de otra
manera**: un 50% de negro sobre casi-negro no consigue nada, así que o subes mucho la opacidad o
generas el contraste aclarando el propio diálogo.

`backdrop-filter: blur()` es caro (repinta toda la capa). Está bien en un área pequeña; mídelo a
pantalla completa, y plantéate enviar un velo plano en dispositivos de gama baja.

---

## 5. La luminancia cambia más rápido que el movimiento

La luminancia es una **señal de estado**; el desplazamiento es un **proceso**. El estado debería
confirmarse de inmediato; al proceso se le permite tomarse su tiempo.

| Cambio | Duración |
|---|---|
| `filter: brightness` / cambio de color | `0.1 – 0.15s` |
| Cambio de elevación con `box-shadow` | `0.15 – 0.2s` |
| Aparición del velo | `0.15 – 0.2s` (aterriza antes que el contenido) |
| Movimiento simultáneo | `0.2 – 0.35s` |

Si la luminancia corre tan lenta como el movimiento, se lee como *el color persiguiendo al objeto*.
**Deja que el brillo llegue primero y la posición después.**

---

## 6. Rendimiento: qué propiedades de luminancia se pueden animar de verdad

| Propiedad | Coste | Recomendación |
|---|---|---|
| `opacity` | ✅ compositor | siempre segura |
| `filter: brightness / drop-shadow` | ✅ compositor en Chrome/Firefox | la primera opción para animar brillo |
| `background-color` | ⚠️ pintado; Chrome está añadiendo soporte en el compositor | bien en áreas pequeñas, mide a pantalla completa |
| `box-shadow` | ⚠️ pintado, y el coste escala con el radio de desenfoque y el área | ver el apaño estándar abajo |
| `backdrop-filter` | ❌ caro | solo áreas pequeñas, o no lo animes (conmútalo) |

**El apaño estándar para sombras animadas**: prerrenderiza un pseudoelemento con sombra y anima solo
su `opacity`:

```css
.card { position: relative; box-shadow: var(--shadow-2); }
.card::after {
  content: ""; position: absolute; inset: 0; border-radius: inherit;
  box-shadow: var(--shadow-4);
  opacity: 0; transition: opacity .2s ease-out;
  pointer-events: none;
}
.card:hover::after { opacity: 1; }
```
La sombra en sí nunca se repinta; solo cambia un valor de alfa. En una lista larga —decenas de
tarjetas recorridas con el hover— la diferencia es enorme.

---

## 7. Mínimos de accesibilidad

La luminancia es un medio de expresión, pero **no puede ser el único portador de información**, y
tiene límites numéricos que no se pueden cruzar.

- Texto de cuerpo contra su fondo: **≥ 4.5:1**. Texto grande (18.66px en negrita, o 24px) y bordes de
  componentes de UI: **≥ 3:1** (WCAG 2.2 AA).
- **Nunca señalices un estado solo con el brillo.** «El seleccionado es más brillante» no existe para
  usuarios con baja visión o diferencias en la percepción del color: acompáñalo siempre de forma,
  icono, borde o texto.
- El indicador de foco (`:focus-visible`) debe alcanzar **3:1** contra su entorno y **no puede
  depender solo del brillo**. El fallo habitual en tema oscuro es un anillo de foco gris pálido que
  desaparece por completo sobre una superficie oscura. Verifica el anillo de foco por separado en
  ambos temas.
- Los estados intermedios durante una animación también deben ser legibles. Un texto que aparece con
  un contraste de 2:1 es, para parte de tu audiencia, un espacio en blanco durante todo ese tiempo.
  **Empezar una entrada en `opacity: 0` está bien; lo que hay que evitar es quedarse en un valor
  "medio legible" como `0.3` como estado de reposo.**
- **Mantén los cambios de luminancia con reduced motion.** Ahí es precisamente donde se ganan su
  lugar: con el movimiento y el escalado desactivados, el brillo y el color siguen comunicando *el
  estado cambió*, sin inducir vértigo. Eso es también lo que hace `MotionConfig reducedMotion="user"`:
  desactiva transform y layout, conserva opacidad y color.

---

## 8. Lista de comprobación

Repásala después de construir cualquier cosa con estratificación o estados:

- [ ] ¿Lo has mirado en **tema oscuro**? ¿Sigue viéndose la estratificación? (Normalmente no → cambia a brillo de superficie.)
- [ ] ¿Las sombras son de dos capas (ceñida + difusa)? Una sola capa parece una pegatina.
- [ ] ¿«Más alto» se expresa como más grande y más suave, en lugar de más oscuro?
- [ ] ¿El hover y la pulsación cambian **movimiento y luminancia a la vez**? Solo uno reduce a la mitad la expresión.
- [ ] ¿El brillo cambia más rápido que el desplazamiento?
- [ ] ¿«Deshabilitado» es un token de color dedicado y no `opacity: 0.5`?
- [ ] ¿El anillo de foco alcanza 3:1 en *ambos* temas?
- [ ] ¿Hay algún estado distinguido **solo** por el brillo?
- [ ] En listas largas, ¿la sombra de hover pasa por la opacidad de `::after` en lugar de animar `box-shadow` directamente?
- [ ] ¿Está acotada el área del `backdrop-filter`?
