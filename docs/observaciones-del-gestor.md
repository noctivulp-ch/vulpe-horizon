# Observaciones del gestor

Lo que el gestor (sesión principal) pasa al implementador fuera del repo de la especificación: solo
observaciones de lo que se ve en el juego, capturas y mediciones, nunca código (ADR 0001). Una entrada por
entrega, con fecha.

## 2026-11-01 — tras el paso 1

- Convenciones, 01 (cielo y atmósfera) y 02 (cielo fractal) revisados por la muralla: se pueden empezar en
  su orden.
- Las capturas que cita la especificación están en `../vulpe-horizon-spec/referencias/`; mirarlas solo ahí,
  nunca en `mediciones/` aunque algún enlace siga apuntando allí (avisar al gestor si se ve uno).
- El paso 1 cumple el ADR 0002 (las etapas solo componen, el núcleo no lee `frame`).
- Decisión del dueño: licencia **GPL-3.0 o posterior** (`LICENSE` en la raíz; `license` en el manifiesto y
  `LICENSE` dentro del pack montado), autor `noctivulp-ch`.
- La identidad git del repo pasa a `noctivulp-ch`; el gestor reescribió los commits anteriores.

## 2026-11-01 — revisión del 01 y el 02

Faltas respecto a la especificación (el gestor cita dónde, no cómo):
- 01, líneas 33, 87 y 127: la lluvia sobre el cielo con la cámara por encima de la capa de nubes. Depende
  del 05: pendiente hasta tenerlo.
- 02, líneas 84–85 y 190: falta el filtro de banda del dibujo Suave (la duda está con A).
- 02, línea 234: el relleno «salpicadura», pendiente de que A lo describa.
- 02, líneas 95–97: la referencia usa otro hash; si el cambio es intencionado, dejar el motivo escrito en
  `docs/efectos/cielo-fractal.md` (la misma semilla no da el mismo cielo que en Vulpe).

Observación visual (`hoja-fractal.png` frente a `referencias/forge_cielo.png` y `hoja-auto.png`): las figuras
se ven **más brillantes y opacas** que en la referencia; la especificación las pide tenues, del orden de las
estrellas tenues (02, líneas 27–30 y 197–200). El resto del 01 y del 02 cumple; el comprobador de
contaminación da 0.

Respuestas: Horizon **no aplica jitter** a la proyección ni lo expone (A lo tendrá en cuenta en el 09). Las
dudas 1, 2, 3 y 5 pasan a A. El 03, el 04 y el 05 están revisados por la muralla.

## 2026-11-02 — revisión del 03–05

Faltas que señala el gestor (cita la línea de la especificación, no dice cómo):
1. 03 §Reflejo en espacio de pantalla: la rugosidad (muestreo de la VNDF de GGX, Heitz 2018) no está.
2. 05 §Biomas: falta la tormenta de nieve (`precipitation == 2` y lluvia: densidad alta, blanca).
3. 05 §Pasos y §Más allá de la capa de nubes: la cámara por encima de la capa baja mirando hacia abajo
   (orden de nubes y niebla, y la niebla no se integra por encima del plano de nubes).
4. 05 §Opciones: «Nubes» pide sí/no **y por capa**.

Lo que se ve (`hoja-niebla.png`, `hoja-luz.png`):
- **Cúmulos:** estrías paralelas dentro de las nubes, como escalones; formas en gota o lágrima,
  inclinadas, en vez de base plana y techo en cúpula (05, objetivo visual y §Nubes).
- **Horizonte sobre el mar:** el mar lejano acaba en una franja gris clara, como un muro, en vez de
  fundirse con el cielo.
- **Lluvia:** bien (arena y piedra mojadas más oscuras, charcos).

Respuestas de la API (comprobadas por el gestor en el renderizador; para el 07):
- `reflection`: su alfa no distingue cielo de terreno: vale 1 en el cielo vanilla y en el terreno, y
  < 0,75 solo en píxeles emisivos (la marca de HDR del motor).
- El pase translúcido mezcla `Surface.color` con alfa estándar (src·a + dst·(1−a)), descarta a < 0,01 y
  luego aplica la niebla del motor si no está apagada.

Respuestas de A en la especificación (commit dd519dd, antes 9aa2fa7: el gestor reescribió el historial de la especificación; tabla en `../vulpe-horizon-spec/historial-reescrito.md`):
- **Presupuesto de opciones** (`convenciones.md`): 48 imprescindibles por subsistema; lo demás, constante.
- **Niebla nocturna:** tapa el cielo casi entero **a propósito** (la aurora, 06, existe por eso):
  transmitancia al cenit ≈ 10–15 % desde Y ≈ 70, < 3 % al horizonte; más oscura que el cielo nocturno
  despejado salvo en el halo de la luna. Volver a la densidad uniforme hasta la altura de caída y ajustar el
  brillo, no la densidad. Referencia nueva: `referencias/aurora_off_noche.png`.
- **Alfombras y capas de nieve:** `[[materials]] blocks` no lo resuelve (sigue siendo por sprite);
  preferencia: aceptarlo.

Las especificaciones 06, 07 y 08 han pasado la revisión del gestor.

## 2026-11-02 — revisión del 06 (aurora)

La rugosidad del 03 queda bien cerrada; el comprobador de contaminación sigue a 0.

Lo que se ve (`hoja-aurora.png` frente a `referencias/ruidov_noche.png`):
- En la referencia la luz llena **el cuerpo de la figura** (filamentos y textura fina dentro) y cuelgan
  **cortinas altas** (de altura en pantalla parecida a la anchura de la figura) con **vetas verticales**.
- En la nuestra: una franja estrecha que sigue el **borde** de la silueta, como un ribete, con el interior
  oscuro; sin extensión vertical ni vetas.
- El dorado frente al gris es normal (la referencia lleva el aislamiento de color del 13).

Partes de la especificación que el gestor cree incumplidas: el aspecto y el orden de brillo de arriba abajo;
qué guarda el rgb del mapa (el color en el interior de la figura, no solo en la línea); §3–4, de qué depende la
emisión de un punto frente a dónde la pone el gancho; y hacer las dos comprobaciones de las líneas 32–35 (conos
en rojo y sin/con ventana) con capturas en la hoja.

Dato del motor (especificación 16, comprobado por el gestor en el renderizador): la etapa `weather` no escribe
en `scene_depth`; la niebla de post no ve la lluvia.

A ha terminado las 16 especificaciones, todas revisadas. Recomendación del gestor: tras la aurora, el 09
(TAA), que limpia el grano del 04, el 05 y el 06.

## 2026-11-02 — revisión de 8287b4e (aurora)

Mejora clara: el cuerpo de la figura se ilumina, se ven las rayas que convergen hacia arriba y la vista de
conos se parece a `dbg_conos.png`. La semilla 8 escorzada no cuenta como fallo.

Observación (frente a `ruidov_noche.png`): en la referencia, dentro de la figura se distinguen **puntos y
filamentos brillantes sobre una cortina más oscura y translúcida**, que pierde brillo hacia abajo y deja ver el
fondo. En la nuestra el interior es una **lámina crema casi uniforme y opaca**, sin apenas variación entre
filamentos y relleno ni de arriba abajo. Mirar si el arreglo del peso dejó la cortina demasiado saturada (06,
líneas 25–27 y 37–38). No urge: volver a mirarlo con el TAA (09) y el aislamiento de color (13).

La duda de la ventana al cielo está con A. Siguiente: 09 (TAA), luego 07–16.

## 2026-11-02 — tras el 09

- 09 bien; la aurora deja ver las vetas con el TAA.
- Respuesta de A a la ventana al cielo: especificación 06 §7 (`8873b86`): usar el color del cono, no el de la
  dirección de vista. En §6, el peso de la luz de la cortina tiene que saturar en cada muestra (ya hecho).
- El gestor reescribió el historial de `vulpe-horizon-spec` (todo noctivulp-ch, firmado): los hashes viejos se
  traducen con `../vulpe-horizon-spec/historial-reescrito.md`.

## 2026-11-02 — revisión de df5e00e y a40893a

Ventana bien cerrada. Las tres desviaciones del 10–11 (exposición mezclada, Reinhard por defecto, bloom de niebla
al cuadrado) están con A: dejarlas así hasta que responda. La cuarta vista de `hoja-imagen.png` estaba negra (era
la casilla vacía de una hoja 2×2 con tres capturas): rehecha con la cueva construida con `fill`, como sugirió el
gestor.
