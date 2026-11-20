# El tiempo en los cristales (subsistema 27 v2, N-09)

Efecto propio de Vulpe para Horizon, reescrito en sala limpia desde la especificación v2
(`vulpe-horizon-spec/subsistemas/27-tiempo-en-los-cristales.md`). Base de detalle: **32 texeles por bloque**
(`OPC_CRISTAL_REJILLA = 32`, escalable a 16 / 32 / 64 con `k = texeles / 32`).

## Arquitectura y coste

### 1. Exposición, interior/exterior y bordes de la ventana entera (opción b + respaldo d)

En Horizon API 0.2 (`dd67b76`), `[material]` no tiene acceso directo a bloques vecinos, pero la API ofrece trazado de
rayos por hardware (`[ray_tracing]`, `trace_layers` y `trace_any_layers`, `shaders-reference-0.2.md:349-435`):

- **Por qué no se lanzan rayos desde `[material]`:** incluir `trace_layers` en `[material]` activa las canalizaciones
  RT en todo el terreno sólido y añade ~+0,30–0,67 ms de GPU incluso en un bosque sin cristales.
- **Caché 3D toroidal en `[[before_world]]` (`cristal_mapa`, 48×24×48 bloques = 55 296 vóxeles):**
  - [`etapas/cristal_mapa.wgsl`](../../etapas/cristal_mapa.wgsl) +
    [`adaptadores/cristal_mapa_escritura.wgsl`](../../adaptadores/cristal_mapa_escritura.wgsl) actualizan 2 planos Z
    por fotograma (`dispatch [48, 24, 2]`, ciclo completo en 24 cuadros), saliendo al instante si no hay clima ni
    efectos activos.
  - Sondea el borde opaco de 1 píxel (`y = 0,03` en caras verticales, `x = 0,03` arriba/abajo) para detectar cualquier
    bloque o panel de cristal (`[[tags]] id = "cristal"`), distinguir cristal transparente (`[[materials]] id = 11`,
    `glass` y `glass_pane`) y la orientación de los brazos del panel (`panel_x` / `panel_z`, descartando postes
    aislados sin brazos).
  - Calcula por cada cara: si está cerrada, si alcanza el cielo en ≤ 3 bloques (alero corto mojado, porche hondo seco),
    si es cara exterior o interior (búsqueda hasta 8 bloques a ambos lados), la **máscara de 4 bits de bordes de la
    ventana entera** y la **distancia en bloques al marco** (`dist_marco`, 0..7 en las 4 direcciones).
  - `[material]` solo lee `cristal_mapa` (0 ray queries en `[material]`), con respaldo automático (opción d: luz de
    cielo y AO de vértice) fuera de ±24/±12 bloques o en GPUs sin ray queries.

### 2. Cristal transparente (`glass` y `glass_pane`) sin coste global

Bajo `[material] coverage = "engine"` (`shaders-reference-0.2.md:103-111`), Horizon recorta los texeles con
`albedo.a < 0,5` en *cutout* y `< 0,01` en translúcidos; activar `coverage = "pack"` es global a todo el terreno y
añade +1,9 ms en bosque. También se probó sustituir `minecraft:block/glass` desde el mod nativo:

- La valla de recursos de Horizon prohíbe `assets/minecraft/textures/` en mods (`content-mods.md:802-806, 839`).
- En `assets/minecraft/atlases/blocks.json` (`content-mods.md:805-806`), `"type": "minecraft:filter"` es rechazado
  (`atlas minecraft:blocks skipped: sources[4]: malformed source`), y `"type": "minecraft:single"` añadido tras el
  directorio vanilla carga sin aviso pero no sobrescribe el sprite `minecraft:block/glass` ya registrado.

**Solución adoptada (coste ~0 ms en bosque):**

- `glass` y `glass_pane` se mantienen con `coverage = "engine"`: Horizon los dibuja en la pasada translúcida y
  recorta el cuerpo (alfa < 0,01); solo quedan el marco y los brillos (ver §«Marco y brillos del cristal transparente»).
- Cada workgroup `[8, 4, 1]` de `cristal_mapa` reduce un bit de presencia de cristal transparente (`1 728` baldosas)
  que `cristal_sim` resume en `cristal_sim[ADP_CS_RESUMEN]`.
- Al principio de [`etapas/post/06-taa.wgsl`](../../etapas/post/06-taa.wgsl) (`F-101`; antes en `03b-cristales`, `F-97`),
  [`adaptadores/cristales_post.wgsl`](../../adaptadores/cristales_post.wgsl) sale en una única rama uniforme si no hay
  cristales transparentes cerca o si el clima está inactivo. Cuando sí los hay, recorre `cristal_mapa` con un DDA
  entero (sin ray queries) hasta `scene_depth` (dejando intacto el marco opaco de 1 píxel y los brillos diagonales) y
  compone exactamente las mismas 7 capas del núcleo que `[material]` dibuja en los cristales tintados y ahumados.

### 3. Formato 4 de `frame.mods` y estado por fotograma

- El mod nativo (`vulpe-horizon-mod`) envía el **formato 4** (`mods[0].x = 1004.0`, bit 8 `FLAG_GLASS_VALID`) con las
  rampas lineales por tick (escarcha 90/150 s, repisa 60/240 s, arena 60/180 s, condensación 90/60 s), la máquina de
  estados del vaho (`ClientHost::crosshair_target()`) y las opciones `[cristales]` de `config/vulpe-horizon.toml`.
- [`adaptadores/cuadro_escritura.wgsl`](../../adaptadores/cuadro_escritura.wgsl) decodifica el formato 4 una sola vez
  por fotograma en `datos_cuadro[17..22]` y suaviza el viento (`τ = 1 s` lluvia, `τ = 5 s` arena). Sin mod, el pack
  aproxima los valores con `frame.rain`, `frame.temperature` y la hora del día.

## Capas del efecto

### 1. Lluvia global en cómputo (`F-91`, 27 v2 §Capa 1)

- **Pasadas:** [`etapas/cristal_sim.wgsl`](../../etapas/cristal_sim.wgsl) (`dispatch [16, 1, 1]`, un hilo por panel) y
  [`etapas/cristal_lienzo.wgsl`](../../etapas/cristal_lienzo.wgsl) (`dispatch [512, 512, 1]`, memoria compartida de
  workgroup) sobre `cristal_sim` y `cristal_clima` (`rgba16float`, 512×512, `keep = "view"`).
- **Núcleo puro:** [`nucleo/superficie/cristal_lluvia.wgsl`](../../nucleo/superficie/cristal_lluvia.wgsl).
- **Organización:** 4 paneles cardinales de 128×128 texeles (4×4 cuadros de 32×32) para caras laterales + 4 paneles
  para la cara de arriba. Las columnas de un mismo bloque son consecutivas en altura, de modo que una gota que baja
  cruza sin costuras al bloque inferior.
- **Física:** hasta 110 gotas por panel (~12/s con reparto de viento `0,2..1,8`), fusión por suma de áreas y centro por
  masa, arranque a tamaño 5 (o 4 en el 10 %) a 14–30 texeles/s (aceleración ×1,08 al fusionar, tope 45), bajada hacia
  abajo a tirones con pausas (22 % durante 3–12 ticks), desvío leve mezclado al 70 % con el viento (máx. ±0,9),
  microgotas de 1 texel, rastro mojado que se va en 1,6 s y secado escalonado de 6–26 s encogiendo el último 60 %.
  Incluye modo alternativo **regueros** (`OPC_CR_FLAG_REGUEROS`).
- **Paleta:** cuerpo `(109, 133, 189)`, brillo `(232, 240, 255)`, sombra `(60, 88, 166)`, con lágrima alargada y
  refracción óptica de `22`.

### 2. Escarcha de fuera y repisa de nieve (`F-92`, 27 v2 §Capa 2)

- **Núcleo puro:** [`nucleo/superficie/cristal_escarcha.wgsl`](../../nucleo/superficie/cristal_escarcha.wgsl).
- Crece exclusivamente desde el **marco de la ventana entera** (`dist_marco`) con `exp(−d / alcance)`,
  `alcance = max(0,5, escarcha · 6 · k)` texeles, ruido granular de 2 octavas (grupos de 1–2 texeles) cuantizado en 3
  niveles exactos: hielo `(161, 195, 255)` α 0,45 (> 0,6), cristal `(200, 220, 255)` α 0,65 (> 0,85) y denso
  `(236, 246, 255)` α 0,85 (> 1,25), más 4 % de destellos blancos (α 0,95).
- **Repisa de nieve:** solo en el borde inferior activo de la ventana entera, altura `repisa · 3 · k` texeles más alta
  en las esquinas inferiores, dos tonos `(244, 252, 252)` y blanco, α 0,95–0,96, dibujada por delante de la escarcha.

### 3. Copos pegados en 8 tiras globales (`F-93`, 27 v2 §Capa 3)

- **Núcleo puro:** [`nucleo/superficie/cristal_nieve.wgsl`](../../nucleo/superficie/cristal_nieve.wgsl); simulación y
  rasterización en los paneles 8..15 de `cristal_sim` y las filas `y = 256..511` de `cristal_clima`.
- 4 formas exactas: punto 1×1 blanco (α 0,9), pareja diagonal 2 texeles blanco + `(236, 250, 251)` (0,9 / 0,75), cruz
  3×3 (0,95 / 0,8) y estrella 5×5 con cruz interior blanca (0,95 / 0,85) y puntas/diagonales azul hielo
  `(188, 214, 255)` (0,7 / 0,6), con probabilidades según resolución (60/25/12/3 % a 32). Al dejar de nevar cada copo
  vive 20–60 s, se desvanece en el último 40 % y se reduce a punto o pareja en el último 25 %.

### 4. Arena tras tormenta (`F-94`, 27 v2 §Capa 4)

- **Núcleo puro:** [`nucleo/superficie/cristal_arena.wgsl`](../../nucleo/superficie/cristal_arena.wgsl).
- Paletas exactas de 5 tonos para arena de desierto y arena roja de mesas (`OPC_CRISTAL_ARENA_0..4` y
  `OPC_CRISTAL_ARENA_ROJA_0..4`), variación por orientación cardinal y factor de viento `1 − 0,3 · fuerza · (1 − hacia)`
  (0,4..1).
- A 32/64: manchas bilineales de 8 texeles más densas hacia abajo (`y²`) y bordes activos de la ventana, granos
  horizontales de 1–2 texeles (α 0,9) y duna sinusoidal inferior (α 0,97) más alta en las esquinas inferiores activas.
  Incluye modo específico a 16 texeles (`0,16 · a + 0,45 · a · exp(−d/2)`, 5 % granos, acumulación 2–5 texeles).

### 5. Condensación de dentro y borde helado (`F-95`, 27 v2 §Capa 5)

- **Núcleo puro:** [`nucleo/superficie/cristal_interior.wgsl`](../../nucleo/superficie/cristal_interior.wgsl).
- En caras interiores frías: color `(232, 240, 246)` aclarado por `blancura`, alfa base ~0,22 (±0,025 suave, ±0,015
  grano fino) × `min(1, escarcha · 1,25) · opacidad`, avanzando del marco de la ventana entera al centro en 16 pasos
  discretos.
- **Borde helado** con 4 variantes por cara y 3 estilos: `banda` (por defecto: 7 escalones de alfa 0,82 → 0,13 de denso
  a hielo, alcance `max(1,5, 0,9 · escarcha · 8 · k) · 1,35` texeles, 1,5 % destellos, contorno ondulado por 3 senos,
  visibilidad `max(0,45, condensación)`), `cristales` (escarcha de Capa 2 ondulada al 90 %) y `apagado`.

### 6. Vaho del aliento (`F-96`, 27 v2 §Capa 6)

- **Núcleo puro:** [`nucleo/superficie/cristal_aliento.wgsl`](../../nucleo/superficie/cristal_aliento.wgsl).
- En caras interiores donde la condensación local es < 0,5 (apagado en espectador): elipse suave de semiejes
  `0,26 × 0,22` bloques centrada en el punto mirado (ensanchada hasta 1,7× tras 5 exhalaciones repetidas a < 0,3
  bloques), retención de 35 s + desvanecimiento en 20 s, blancura 100 % y opacidad 150 % por defecto; funde escarcha,
  borde helado y copos debajo.

### 7. Desenfoque detrás del cristal empañado conservando las luces (`F-98`..`F-101`, 27 v2 §Capa 7)

- Máscara `min(1, escarcha · 1,25) · 0,95 · grosor` (condensación y vaho, < 48 bloques), aplicada en
  `adp_cristales_post` sobre la textura `composicion` al inicio de `06-taa.wgsl` (`F-101`, eliminando la pasada post
  intermedia `03b-cristales.wgsl` y dejando `[material]` en `11 298` expresiones sin lecturas de recursos de cristal),
  con desenfoque de caja separable 2D (`[-rx..rx] × [-ry..ry]`, rejilla 7×5) de radios `suave` (3, 2 px), `normal`
  (6, 4 px) y `fuerte` (11, 7 px), protección de profundidad delantera (`dm < d_cristal - 0,0002`) y conservación de
  luces:
  `brillo = max(nítido − borroso − 0,04, 0); visto = borroso + 0,8 · brillo; fondo = mix(nítido, visto, máscara)`.
- La condensación, el vaho y el borde helado se componen siempre **encima** del fondo desenfocado.
### Marco y brillos del cristal transparente (F-102, N-09c)

En `glass` y `glass_pane` Horizon dibuja en la pasada translúcida (`MaterialInput.translucent = true`, comprobado con
una vista de depuración en N-09c, `pruebas/capturas/n09c-dbg*`) solo los téxeles opacos: el marco y los brillos
diagonales. Esos los ilumina `[material]` como cualquier translúcido (sol, cielo y luz de bloque con su color de
`adp_color_luz_bloque`). El cuerpo lo pinta el DDA de `adp_cristales_post`, que también cubre el marco y los brillos con
las capas del clima (cambio de `t_max` de `a317499`, se conserva: sin él el marco quedaba sin escarcha encima).

- **F-100 se revierte** en lo que tocaba el color (rechazado por el dueño): ya no se quita el color a la luz de bloque
  de los cristales, ni se pinta gris el transparente, ni se baja al 0,45 la opacidad de los brillos. Con el efecto
  apagado, `[material]` vuelve a ser el de `e7ad1c4` en los cristales.
- **Se conserva de F-100** (`a317499`, cobertura del DDA): `t_hit > t_max + 0,02` como corte del recorrido y del panel
  (para que el DDA llegue a la superficie del marco, que escribe profundidad), y el desenfoque solo con muestras de
  detrás del cristal (`dm < d_cristal − 0,0002`) y sin la muestra central forzada, que metía el propio marco en el
  promedio.
- **Misma luz en las capas.** Las capas de escarcha, repisa, copos, arena, condensación, vaho y borde helado sumaban sol
  y cielo pero no luz de bloque (`luz_base`), así que junto a una antorcha el marco salía cálido y la escarcha de al lado
  fría. Ahora `luz_base` suma `color de bloque × curva de bloque × OPC_LUZ_BLOQUE × fuerza`, igual que `[material]`. La
  pasada post no tiene la luz del terreno: el nivel se lee de un téxel opaco del marco de la misma cara con un rayo corto
  de la capa translúcida (`adp_cristales_post_nivel_bloque`, centro del téxel del borde `OPC_CRISTAL_MARCO_TEXEL`, los
  4 bordes del más cercano al más lejano porque en los paneles unidos no todos tienen marco). Coste: de 1 a 4 rayos por
  píxel de cristal con el efecto activo; ninguno sin cristales cerca. La lluvia no cambia (`luz_lluvia` no lleva el
  término, por decisión del dueño).
- **Límite:** en post no existe `block_light_color`, así que las capas usan el color de bloque del estilo
  (`opc_luz().bloque_color`), no el de la rejilla de luces de colores (una antorcha de almas tiñe el marco de azul y la
  escarcha de cálido). Y el rayo lee la luz guardada del mundo, sin la luz dinámica de la mano.
- El trato del aislamiento de color se iguala en `docs/efectos/aislamiento-de-color.md` §«Marco y brillos del cristal
  transparente (F-102)».
