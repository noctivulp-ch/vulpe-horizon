# El tiempo en los cristales (subsistema 27, N-08)

Efecto propio de Vulpe para Horizon. Especificación: `vulpe-horizon-spec/subsistemas/27-tiempo-en-los-cristales.md`.

## Arquitectura y separación por función

- **Etiqueta de sprites (`horizon-shaders.toml`):** `[[tags]] id = "cristal"` (bit 0 de `MaterialInput.tags`) agrupa
  `block/glass`, `block/*_stained_glass` y `block/tinted_glass`, cubriendo bloques y paneles (los paneles usan el mismo
  sprite en sus caras).
- **Cobertura del material (`coverage = "engine"` por defecto, `OPC_CRISTAL_CUTOUT_INTERIOR = false`):** el cristal
  transparente vanilla (`glass` y `glass_pane`) se dibuja en la pasada *cutout* (`input.translucent == false`), donde su
  textura tiene alfa 0 en el interior. En Horizon API 0.2 (`dd67b76`):
  - `[material] coverage` es global a todo el terreno (`shaders-reference-0.2.md:101-111`, `shaders.md:212-216`), sin
    opción por etiqueta ni por material; activarlo añade ~+1,9 ms de GPU en bosque sin cristales al desactivar *early-Z*.
  - Mover `block/glass` con `[[materials]] translucent = true` (`shaders.md:100`, `572`) bajo `coverage = "engine"`
    tampoco permite dibujar en el interior transparente, porque Horizon sigue descartando los texeles con `albedo.a <
    0,01` en la pasada translúcida (`shaders-reference-0.2.md:105-106`, comprobado en `vulpe-pruebas`).
  - Por ello, desde `F-84` el pack usa `coverage = "engine"` por defecto: el efecto corre completo (con refracción,
    desenfoque y composición suave) en todos los cristales tintados, paneles tintados (`*_stained_glass`,
    `*_stained_glass_pane`) y cristal ahumado (`tinted_glass`) con coste **≤ 0 ms** en escenas sin cristal. El soporte
    para el interior *cutout* de `glass` y `glass_pane` queda detrás de `OPC_CRISTAL_CUTOUT_INTERIOR` en
    `opciones/cristales.wgsl` (requiere descomentar `coverage = "pack"` en `[material]` de `horizon-shaders.toml`).
- **Estado una vez por fotograma (`datos_cuadro[17..21]`):** `[[before_world]]` llama a `adp_mod_cristales()` (separada
  de `adp_mod()` desde `F-84` para no encarecer las lecturas por píxel) y decodifica `frame.mods[6..7]` (formato 3,
  firma `1003.0`, bandera bit 8 `FLAG_GLASS_VALID`) o calcula el respaldo sin mod. En píxeles que no son cristal el
  coste añadido es nulo.
- **Rejilla de 32 texeles por bloque (`OPC_CRISTAL_REJILLA = 32`):** todas las formas (gotas, rastros, escarcha, copos,
  montón, arena) se evalúan en coordenadas de mundo cuantizadas a 32×32 por cara, cruzando bloques contiguos sin saltos;
  las normales ópticas, la luz, los reflejos y la refracción no se cuantizan.
- **Sin opciones nuevas en el menú (64/64):** todos los parámetros son constantes con nombre en `opciones/cristales.wgsl`,
  y las intensidades por parte (`apagada` / `ligera` / `normal` / `intensa`) más `aliento` y `escarcha_interior` se leen
  de la sección `[cristales]` de `config/vulpe-horizon.toml` a través del mod nativo.

## 1. Lluvia y secado (`F-74` / `N-08.1`)

- **Núcleo puro:** [`nucleo/superficie/cristal_lluvia.wgsl`](../../nucleo/superficie/cristal_lluvia.wgsl).
- **Adaptador:** [`adaptadores/cristales.wgsl`](../../adaptadores/cristales.wgsl).
- **Exposición:** solo caras exteriores (`normal_cara.y >= -0,5`) con luz de cielo casi plena (`OPC_CRISTAL_CIELO_MIN..MAX`,
  0,85–0,93 ≈ niveles 14–15): bajo un alero de 1–2 bloques se moja y bajo un porche hondo queda seco.
- **Viento (`26`):** proyecta la dirección del viento que envía el mod (o `OPC_VIENTO` sin mod) sobre la normal de la cara
  (barlovento recibe hasta ×1,45 gotas, sotavento baja a ×0,35) y sobre la tangente horizontal de la cara para inclinar las
  gotas que bajan hacia donde sopla el viento.
- **Gotas a tirones y fusión:** dos capas de gotas que bajan con `sup_cristal_tiron` (quietas ~68 % del ciclo y resbalan de
  golpe varios texeles) más una capa de gotas quietas (1–2 texeles). Al cruzar zonas con gotas quietas su radio aumenta
  (hasta ~3–4 texeles en tormenta). Cada gota tiene forma de lágrima, cúpula refractiva fuerte (`OPC_CRISTAL_GOTA_REFRACCION`),
  brillo especular directo + cenital (visible también en lluvia nublada), cáustica inferior y borde oscuro (`F-79`). Cuando el
  efecto está apagado o en despejado (`!cr.activo`), `translucido` sigue exactamente el camino previo de `22`.
- **Secado escalonado (~30 s):** el mod recuerda `lluvia_pico` y el avance del secado en `mods[6].x`. Primero desaparecen
  los rastros (`0–8 s`), después las gotas pequeñas (`5–18 s`) y por último las grandes (`15–30 s`). Sin mod, el efecto
  sigue `frame.rain` sin secado gradual.
- **Estilo alternativo:** `OPC_CRISTAL_ESTILO_REGUEROS` cambia a regueros verticales animados en la misma rejilla de 32.

## 2. Escarcha en el frío (`F-75`, `F-80` / `N-08.2`)

- **Núcleo puro:** [`nucleo/superficie/cristal_escarcha.wgsl`](../../nucleo/superficie/cristal_escarcha.wgsl).
- **Cuándo:** temperatura efectiva por debajo del umbral de nieve (`0,15`, incluyendo la caída de `0,00125` por bloque
  sobre Y = 80). El mod acumula y retira la escarcha de forma gradual (`16 s` al crecer, más rápida mientras nieva, y
  `24 s` al calentarse), con refuerzo de noche y nevando. Sin mod se evalúa en vivo en `[[before_world]]`.
- **Forma de helecho y bordes del conjunto:** dos ejes girados de ruido en cresta en la rejilla de 32 texeles por bloque
  (suavizada a < 2 bloques de distancia) crecen de forma delicada desde los bordes y esquinas con modulación orgánica
  multibloque para no encerrar cada bloque en una cuadrícula gruesa.
- **Óptica y composición (`F-80`):** blanca azulada cristalina (`OPC_CRISTAL_ESCARCHA_COLOR`), translúcida (`opacidad`
  hasta `0,48`) con composición Porter-Duff «sobre» (`adp_cristal_sobre`) para no oscurecer bordes semitransparentes,
  destellos especulares de facetas con la luz diurna/nocturna y desenfoque detrás de 4 muestras protegidas por profundidad
  (`adp_cristal_refraccion`). Las gotas de lluvia se atenúan sobre la escarcha gruesa.
- **Interior opcional:** `[cristales].escarcha_interior` (o `OPC_CRISTAL_ESCARCHA_INTERIOR` sin mod) añade escarcha más
  ligera en las caras interiores de ventanas que reciben luz de cielo del exterior.

## 3. Copos y montón de nieve (`F-76` / `N-08.3`)

- **Núcleo puro:** [`nucleo/superficie/cristal_nieve.wgsl`](../../nucleo/superficie/cristal_nieve.wgsl).
- **Copos pegados:** copos blancos de 1–2 texeles (rejilla de 32) en las caras exteriores expuestas (luz de cielo 14–15),
  con más densidad a barlovento. El mod los retira en ~8 s tras parar de nevar (`mods[6].y` bits 8..15); sin mod siguen
  `frame.rain`.
- **Montón inferior:** franja ondulada de `4–6` texeles de alto en la base de cada cara exterior (completa sobre alféizar
  sólido, más baja en juntas superiores sin bloque debajo). El mod lo acumula en ~18 s mientras nieva y lo funde despacio
  (`~45 s` en frío, más rápido al calentarse, `mods[6].y` bits 16..23). Se compone por encima de la escarcha y bloquea
  las gotas de lluvia.

## 4. Vaho del aliento (`F-77`, `F-81` / `N-08.4`)

- **Núcleo puro:** [`nucleo/superficie/cristal_aliento.wgsl`](../../nucleo/superficie/cristal_aliento.wgsl).
- **Cuándo:** solo en cristales con escarcha y con la cámara a menos de `1,5` bloques (por dentro o por fuera). El mod
  comprueba el modo de juego del jugador local (`ClientSession::client_tab_list`) y apaga el efecto en modo espectador
  (`bit 9` de `mods[6].z`, `vaho_w < 0` en `datos_cuadro`).
- **Empañado suave, memoria de 5 s y pulso (`F-81`):** el mod busca el punto más cercano de cristal en los bloques
  adyacentes, suaviza su peso (sube en ~6 s y se desvanece en `5 s` al alejarse) y envía la posición relativa a la cámara
  en `mods[7].xyz`. El shader evalúa ruido continuo interpolado (`5,5`, `16` y `32` ciclos/bloque) con envolvente radial
  gaussiana y pulso de respiración cada `3,5 s` hasta `~1` bloque de radio, sin bloques pixelados ni borde duro. Sin mod
  funciona en vivo sin memoria.
- **Fusión con la escarcha y los copos:** una máscara amplia (`aliento.derrite`) disuelve gradualmente tanto el dibujo de
  helecho y las facetas de la escarcha como los copos pegados (`nieve.copo`, `F-84`) para dejar condensación lisa y
  borrosa detrás (`27` §4).

## 5. Arena tras tormenta en bioma seco (`F-78`, `F-82` / `N-08.5`)

- **Núcleo puro:** [`nucleo/superficie/cristal_arena.wgsl`](../../nucleo/superficie/cristal_arena.wgsl).
- **Cuándo:** solo en biomas secos del Overworld (`!has_precipitation && temperature >= 1,0`: desierto, sabana, mesas y
  biomas secos de mods), gestionado por el mod nativo. Acumula durante lluvia/tormenta (más fuerte y rápido con tormenta
  eléctrica) y el viento se la lleva en `~3 min` tras despejar (`mods[6].z` bits 12..23). Sin el mod queda apagada.
- **Velo fino de polvo y granos sutiles (`F-82`):** velo continuo de polvo arrastrado por el viento en coordenadas de mundo
  (sin bandas horizontales repetidas por bloque), más denso hacia la base y a barlovento, mezclado con granos sutiles en la
  rejilla de 32. Polvo amarillo (`OPC_CRISTAL_ARENA_COLOR_AMARILLA`) en desierto/sabana y terracota polvoriento
  (`OPC_CRISTAL_ARENA_COLOR_ROJA`, `bit 8`) en mesas (`badlands`), mate y sin reflejo donde se acumula.
