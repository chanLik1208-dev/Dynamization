# pitfalls.md — Síntoma → causa → arreglo

Busca el síntoma y luego lee la sección. Las causas están agrupadas por *mecanismo*, no por API, así que
se transfieren entre runtimes: una animación de salida que no se reproduce tiene las mismas tres causas en un framework
web, en un motor de juego y en un toolkit nativo.

| Síntoma | Causa más probable |
|---|---|
| La animación de salida no se dispara nunca | la cosa fue destruida antes de poder animarse → §1 |
| La animación se reinicia desde el principio en cada disparo | el objeto animado se está recreando, o vuelves a apuntar desde el inicio nominal → §2 |
| La reversión tartamudea o se frena en seco | no se está arrastrando la velocidad; comportamiento Tier 2 → §2 |
| La animación de reflow no hace nada | nada le dijo al sistema que el layout cambió, o el tipo de elemento no se puede transformar → §3 |
| El contenido se estira o el radio de esquina se vuelve ovalado | se está escalando un rect sin contra-escalar su contenido → §3 |
| La página entera tiembla mientras se hace scroll | una barra de scroll o un área segura que aparece está disparando una animación de reflow → §3 |
| Frames perdidos, tirones | se está animando una propiedad de nivel layout o paint → §4 |
| Los valores vinculados al scroll dan escalones visibles | entrada de scroll cruda, sin suavizar → §5 |
| La pantalla barre desde arriba al cargar | un spring dirigido por scroll inicializado en cero → §5 |
| La distancia de arrastre no coincide con el puntero | un ancestro transformado o escalado cambió el espacio de coordenadas → §6 |
| El hover se queda «pegado» en dispositivos táctiles | eventos de hover sintetizados → §6 |
| La animación terminó pero el estado no cambió | había lógica colgada de un callback de finalización que nunca se disparó → §7 |
| La elevación desaparece en el tema oscuro | las sombras son invisibles sobre superficies oscuras → `contrast.md` §2 |
| El texto es ilegible a mitad de animación | contraste intermedio demasiado bajo → `contrast.md` §7 |

---

## 1. Salidas que nunca ocurren

Una animación de salida es una contradicción: estás animando algo que, lógicamente, ya no existe.
Cada runtime necesita un mecanismo para mantenerlo vivo durante ese tiempo, y **el fallo siempre es una
de tres cosas**:

1. **El mantenedor con vida está dentro de la cosa que se elimina.** Si el envoltorio responsable de aplazar
   la destrucción lo destruye la misma condición, no sobrevive nada que animar. El
   mantenedor con vida debe estar **fuera** del condicional, y la condición debe estar dentro de él.
2. **La identidad es inestable.** El sistema rastrea «qué ítem es cuál» mediante alguna clave. Si esa clave
   es un índice posicional, entonces eliminar el ítem 2 hace que el ítem 3 *se convierta* en el 2, y el sistema ve una
   actualización en lugar de una eliminación. Usa un id estable y único.
3. **La cosa que sale no es hija directa del mantenedor con vida.** Un envoltorio inerte de por medio y
   el mecanismo no la ve. Comprueba el árbol real, no el árbol del código fuente.

**Las salidas anidadas** son su propia trampa: cuando se elimina un subárbol entero de golpe, los hijos normalmente
**no** llegan a reproducir sus propias salidas: el padre termina primero y se los lleva con él. Si necesitas
que los hijos se vayan antes, secuéncialo explícitamente (`feel.md` §6: el contenido se despeja, *y luego* el
contenedor se cierra).

**Prueba de diseño:** si no sabes nombrar el mecanismo que mantiene vivo al elemento durante su salida, todavía
no tienes una animación de salida. Encuéntralo en tu adaptador antes de diseñar una.

---

## 2. Reinicios, recreación y velocidad perdida

**El objeto animado se está recreando.** Cualquier cosa construida dentro de una función de render/actualización es
un objeto nuevo en cada frame o en cada actualización, y no lleva nada del estado de animación del
anterior. Saca la construcción fuera. Ésta es la causa más común de «se anima la primera
vez y luego nunca más», y tiene la misma forma en todos los sistemas de UI declarativos.

**Estás volviendo a apuntar desde el inicio nominal.** Cuando una animación se vuelve a disparar en pleno vuelo, la
nueva animación debe empezar en el valor **actual**, no en el valor de inicio declarado. Lee primero el valor
actual. Cualquier cosa que diga «anima de A a B» cuando el elemento está actualmente en algún punto
intermedio saltará de vuelta a A, y el salto ocurre exactamente en el momento en que el usuario actuó.

**No se está arrastrando la velocidad.** Esto es comportamiento Tier 2 (`SKILL.md` §2) y no es un bug, es
una capacidad ausente. Tres salidas, en orden:

- Integra el spring a mano para las interacciones que realmente van dirigidas por gestos — `spring.md` §3.
- Mantén `b ≤ 0.15` para que un reinicio a velocidad cero no se distinga visiblemente de una continuación.
- Mantén las animaciones re-disparables en `dur ≤ 0.2s`, por debajo del umbral en el que un reinicio se nota.

**No mezcles sistemas de parámetros.** Si tu runtime acepta a la vez una duración y una rigidez, fijar
uno normalmente deja el otro inerte, y en silencio. Elige un vocabulario (`Dv`/`b`, convirtiendo en la
frontera) y no fijes nunca el otro.

---

## 3. Animaciones de reflow y de elemento compartido

**No pasa nada:**

- **El tipo de elemento no se puede transformar.** Las cajas de texto en línea, algunos contenedores gestionados por el layout y
  muchos nodos de UI 2D ignoran las transformaciones por completo. Cambia el elemento por uno que sí se pueda transformar.
- **Nada le dijo al sistema que el layout cambió.** Las animaciones de reflow funcionan comparando una medición
  *de antes* con una *de después*, y algo tiene que disparar esa comparación. Un cambio que se salta
  el ciclo de actualización del sistema no produce comparación y, por tanto, ninguna animación.
- **Dos elementos afectan al layout el uno del otro pero se actualizan por separado.** Hay que medirlos
  en la misma pasada, o uno animará hacia una posición que el otro todavía no ha dejado libre.

**Dirige el layout a través del layout, no a través del sistema de animación.** Fijar un tamaño mediante una animación
*y* dejar que el sistema de reflow anime ese mismo tamaño son dos sistemas peleándose por un número. Deja que
el cambio de layout ocurra al instante y que el mecanismo de reflow anime la diferencia visual.

**Contenido estirado (distorsión por escalado).** Un rect animado por escalado distorsiona todo lo que hay dentro:
el texto se estira, los radios de esquina se vuelven ovalados, los bordes cambian de grosor. Arreglos, en orden de preferencia:

- Contra-escala los hijos directos por el factor inverso.
- Para elementos cuya relación de aspecto cambia (imágenes, bloques de texto), anima **sólo la posición** y deja
  que el tamaño cambie al instante.
- **El radio de esquina y la sombra deben ser valores que el sistema de animación pueda ver** para poder
  corregirlos. Un radio enterrado en una hoja de estilos o en un recurso estático no se puede contra-escalar.
- Un borde no se puede corregir perfectamente: hay un suelo de un píxel. Usa como borde un padre con padding.

**Dentro de un contenedor con scroll o de una capa de posición fija**, las mediciones de antes/después se toman en
espacios de coordenadas distintos a menos que le hables al sistema del contenedor. Ambos casos suelen necesitar
una activación explícita.

**El temblor de página al hacer scroll** es casi siempre una barra de scroll o un margen de área segura que aparece y
desaparece, lo que cambia el ancho del contenido, lo que dispara una animación de reflow en todo.
Reserva el canal de forma permanente.

**Una nota sobre coordenadas:** un mecanismo de reflow que calcula posiciones **relativas al padre** mantiene a un
hijo retrasado enganchado a su padre en movimiento. Uno que calcula posiciones **absolutas a la página**
dejará al hijo atrás. Si tus transiciones de hijos parecen despegadas de su padre, es por esto.

---

## 4. Rendimiento

**Siempre seguro**: transform (translate / scale / rotate), opacidad
**Nivel paint — mídelo**: sombras, radio de esquina, color de fondo, filtros
**Nivel layout — evítalo**: width, height, top, left, margin, padding, grosor de borde

La sustitución universal: **no animes la propiedad cara, haz un fundido cruzado entre dos estados
pre-renderizados de ella.** Una sombra desenfocada se convierte en una capa superpuesta cuya opacidad se anima. Un radio de esquina
se convierte en dos máscaras. Un desenfoque de fondo se convierte en dos copias pre-desenfocadas. Esto cuesta memoria y compra
frames — `contrast.md` §6.

Donde haya un recorte o una máscara disponibles, suelen ser más baratos que la propiedad que sustituyen: recortar a un
rect redondeado le gana a animar un radio, y recortar un revelado le gana a animar una altura.

**Sé parco con las pistas de capa.** Cada pista de «promociona esto a su propia capa» cuesta memoria de GPU, y una
página llena de ellas es más lenta que una página sin ninguna. Añádelas sólo a elementos que hayas medido.

**El texto es el caso caro.** Dividir el texto en fragmentos infla el número de objetos *una vez*,
lo cual está bien. Reescribir el contenido del texto en cada frame dispara un layout de texto **continuo**, lo cual no lo está.
Reserva el tamaño final de antemano, y usa una fuente de avance fijo para los efectos de scramble para que la caja nunca
se vuelva a medir. **El desenfoque por carácter es una trampa concreta**: muchas capas pequeñas, cada una inflada por su
radio de desenfoque, se solapan mucho y cuestan bastante más que un solo desenfoque sobre el bloque entero.

---

## 5. Scroll

- La entrada de scroll es discreta. Atarla directamente a una transformación produce escalones. Suavízala siempre
  con un spring — `feel.md` §7.
- **Inicializa ese spring en el valor de scroll actual**, o la pantalla barrerá desde arriba al cargar.
  Esto llega a producción constantemente porque no se reproduce durante el desarrollo, donde
  ya estás en la parte de arriba de la página.
- Fija con el mecanismo sticky nativo de la plataforma, nunca escribiendo una posición desde un manejador de
  scroll. Una fijación dirigida por manejador va un frame por detrás del compositor y trepida a la vista.
- Las animaciones disparadas por scroll necesitan un flag explícito de **dispara-una-vez** y un **umbral** explícito
  (~30% visible). Ambos valores por defecto suelen estar mal.
- Sé preciso sobre qué significa «progreso». La mayoría de las APIs de scroll expresan el rango como dos pares de
  posiciones —un punto en el objetivo y un punto en el contenedor— y equivocar el emparejamiento
  te da una animación que termina antes de que el elemento esté en pantalla, o una que no se completa nunca.

---

## 6. Gestos y espacios de coordenadas

**El arrastre no sigue al puntero** → un ancestro lleva una transformación o un escalado, así que las coordenadas del puntero
y las del elemento están en espacios distintos. O divides el delta del puntero por el
escalado acumulado, o conviertes la posición del puntero al espacio local del elemento antes de usarla.
La misma causa rompe las animaciones de reflow dentro de un padre escalado.

**El hover «se pega» en dispositivos táctiles** → la entrada táctil sintetiza eventos de hover que nunca reciben una salida
correspondiente. Usa la señal de hover filtrada de la plataforma si la tiene; si no, limpia tú mismo el estado de hover al
terminar el toque, y condiciona los efectos de hover a una consulta de «el dispositivo tiene un puntero real».

**Un arrastre pelea con el scroll en táctil** → hay que decirle a la plataforma, antes de que empiece el gesto,
qué eje te pertenece. Decláralo de antemano; decidirlo después del primer evento de movimiento siempre es demasiado tarde,
porque el scroll ya ha empezado.

**El toque de un hijo se lo traga un gesto del padre** → los sistemas de gestos habitualmente aplazan su manejo
al final de la pasada de entrada, lo que significa que detener la propagación desde dentro de un callback de gesto es demasiado
tarde. Deténla en el pointer-down crudo, o usa la opción explícita de «no propagues este gesto» que
ofrezca el sistema.

**Toques disparándose al final de un arrastre** → cancela el toque en cuanto el puntero se haya movido más de unos 3px.
La mayoría de los sistemas lo hacen por ti; verifícalo, porque el fallo es un usuario arrastrando una tarjeta y
abriéndola sin querer.

**Arrastrar una imagen produce un fantasma** → el propio drag-and-drop de la plataforma está compitiendo con el tuyo.
Desactívalo en el elemento.

---

## 7. Estado, callbacks y ciclo de vida

**Nunca cuelgues lógica real de un callback de animación completada.** No se dispara cuando la animación
se interrumpe, se cancela o se salta con movimiento reducido, y las tres cosas son normales. Dirige el estado
desde el evento que causó la animación, y deja que la animación sea presentación. La regla general:
si borraras todas las animaciones del producto, toda la lógica debería seguir ejecutándose.

**La animación y el estado pueden discrepar.** Si la animación es la fuente de verdad de «el menú está
abierto», entonces una animación interrumpida te deja en un estado que no existe en tu modelo. Conserva
el booleano; anima hacia él.

**Cuidado con el objeto-nuevo-en-cada-actualización.** Pasar un objeto de configuración recién construido en cada
actualización hace que fallen las comprobaciones de igualdad, lo que o bien repite la animación constantemente o bien cuesta una
comparación para nada. Sácalo fuera, memoízalo o nómbralo como un token.

---

## 8. Lista de comprobación previa a la entrega

- [ ] ¿Está el movimiento reducido manejado de forma global? ¿Están el parallax y la reproducción automática ramificados aparte, además?
- [ ] ¿Las animaciones disparadas por scroll se disparan una vez, con un umbral sensato?
- [ ] ¿Estás animando una propiedad de nivel layout en algún sitio donde debería ser una transformación?
- [ ] ¿Las salidas se reproducen de verdad, con ids estables y con la condición dentro del mantenedor con vida?
- [ ] ¿La salida es 0.5–0.7× la duración de la entrada, sobre una distancia más corta?
- [ ] ¿Has hecho la aritmética del stagger (intervalo × cantidad ≤ 0.5s)?
- [ ] ¿Hay exactamente un valor de rebote en uso en todo el producto?
- [ ] **¿Lo has mirado en el tema oscuro?** ¿Sigue viéndose la elevación? ¿Y el anillo de foco?
- [ ] ¿Has vuelto a disparar rápidamente cada animación, cinco veces, para ver el comportamiento de interrupción?
- [ ] ¿Lo has ejecutado alguna vez en un dispositivo de gama baja, o con un estrangulamiento de CPU de 4×?
- [ ] ¿El texto dividido lleva una etiqueta accesible en condiciones, con los fragmentos ocultos?
- [ ] ¿Hay algún estado transmitido sólo por luminancia, o sólo por animación?
