# El tiempo en los cristales (subsistema 27, N-08)

Efecto propio de Vulpe para Horizon. Especificación: `vulpe-horizon-spec/subsistemas/27-tiempo-en-los-cristales.md`.

## Arquitectura y separación por función

- **Etiqueta de sprites (`horizon-shaders.toml`):** `[[tags]] id = "cristal"` (bit 0 de `MaterialInput.tags`) agrupa
  `block/glass`, `block/*_stained_glass` y `block/tinted_glass`, cubriendo bloques y paneles (los paneles usan el mismo
  sprite en sus caras).
- **Cobertura del material (`[material] coverage = "pack"`):** el cristal transparente vanilla (`glass` y `glass_pane`)
  se dibuja en la pasada *cutout* (`input.translucent == false`), donde su textura tiene alfa 0 en el interior. Bajo
  `coverage = "engine"` Horizon descarta esos texeles antes de devolver color. Con `coverage = "pack"`, los texeles con
  efecto del tiempo devuelven alfa 1 y se dibujan en la rejilla de 32×32; el resto conserva `p.alfa`, igual que antes.
  Nota de API: en la pasada *cutout* `opaque_color` no es válido (`shaders-reference-0.2.md`), así que en cristal
  transparente las gotas usan reflejo de cielo/nubes (`22`), brillo especular y borde oscuro, mientras que en todos los
  cristales tintados y ahumados (`input.translucent == true`) aplican además refracción completa con dispersión cromática.
- **Estado una vez por fotograma (`datos_cuadro[17..21]`):** `[[before_world]]` decodifica `frame.mods[6..7]` (formato 3,
  firma `1003.0`, bandera bit 8 `FLAG_GLASS_VALID`) o calcula el respaldo sin mod, de modo que ningún píxel de `material`
  paga desempaquetado ni lectura de `adp_mod()`. En píxeles que no son cristal el coste añadido es una comprobación de bit.
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
  (hasta ~3–4 texeles en tormenta). Cada gota deja un rastro fino detrás y desvía la normal en espacio tangente para
  refracción (`adp_cristal_refraccion`), especular (sol, luna y luz de bloque) y reflejo (`adp_agua_reflejo`).
- **Secado escalonado (~30 s):** el mod recuerda `lluvia_pico` y el avance del secado en `mods[6].x`. Primero desaparecen
  los rastros (`0–8 s`), después las gotas pequeñas (`5–18 s`) y por último las grandes (`15–30 s`). Sin mod, el efecto
  sigue `frame.rain` sin secado gradual.
- **Estilo alternativo:** `OPC_CRISTAL_ESTILO_REGUEROS` cambia a regueros verticales animados en la misma rejilla de 32.

## 2. Escarcha en el frío (`F-75` / `N-08.2`)

- **Núcleo puro:** [`nucleo/superficie/cristal_escarcha.wgsl`](../../nucleo/superficie/cristal_escarcha.wgsl).
- **Cuándo:** temperatura efectiva por debajo del umbral de nieve (`0,15`, incluyendo la caída de `0,00125` por bloque
  sobre Y = 80). El mod acumula y retira la escarcha de forma gradual (`16 s` al crecer, más rápida mientras nieva, y
  `24 s` al calentarse), con refuerzo de noche y nevando. Sin mod se evalúa en vivo en `[[before_world]]`.
- **Forma de helecho y bordes del conjunto:** dos ejes girados de ruido en cresta en la rejilla de 32 texeles por bloque
  crecen desde los bordes y con mayor radio desde las esquinas. La oclusión de vértice (`p.ao_vertice`) distingue el
  perímetro pegado a bloques sólidos del marco (AO reducido, escarcha gruesa) de las juntas interiores entre cristales
  contiguos (AO ≈ 1, escarcha reducida a `OPC_CRISTAL_ESCARCHA_JUNTA_PESO` y modulada en gran escala para evitar una
  cuadrícula).
- **Óptica:** blanca azulada (`OPC_CRISTAL_ESCARCHA_COLOR`), translúcida con dispersión frontal a contraluz y destellos
  de facetas cristalinas; en cristales translúcidos emborrona lo que hay detrás con 4 lecturas protegidas por profundidad
  (`adp_cristal_refraccion`). Las gotas de lluvia se atenúan sobre la escarcha gruesa.
- **Interior opcional:** `[cristales].escarcha_interior` (o `OPC_CRISTAL_ESCARCHA_INTERIOR` sin mod) añade escarcha más
  ligera en las caras interiores de ventanas que reciben luz de cielo del exterior.
