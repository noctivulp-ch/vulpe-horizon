# Niebla volumétrica y nubes (subsistema 05)

Especificación: `../vulpe-horizon-spec/subsistemas/05-niebla-y-nubes.md`. Capturas: `pruebas/capturas/niebla-*.png`
y `hoja-niebla.png` (escena `pruebas/escenas/niebla.ctl`).

## Qué hay y qué falta

Pasada 1 a media resolución con destino propio `volumen` (rgb luz ya expuesta, a transmitancia): aire
(perspectiva aérea, también sobre el cielo desde F-2), niebla global uniforme y en manchas con su horario, caída con
la altura desde Y = 320, y tres capas de nubes (cúmulos pequeños y grandes, altoestratos) con perfiles de
tiempo sorteados por día y de lluvia, en un solo raymarch con una sola transmitancia. Sombra del mapa en
cada paso de la niebla y sombras de nubes. Pasada 2 de composición: decodifica la escena (ADR 0004),
reescalado bilateral por profundidad, niebla de borde. `[material] fog = false`: la niebla de Horizon ya no
se aplica. También cierra dos pendientes: las **sombras de nubes** del 04 en el material, y la **lluvia
sobre el cielo, que se desvanece por encima de la capa de nubes** (01).

**Ganchos:** el de la aurora (06) está en `vol_tramo_niebla` (ver `docs/efectos/aurora.md`); los rayos del
fractal (14) ya no van en este bucle (son un desenfoque radial de la pasada final). **Fuera por ahora:** el primer paso se desplaza con
ruido azul desplazado con R2 (09, `adp_ruido_azul`). Con IGN se veían **estrías paralelas** dentro de las nubes
(observación del gestor): su estructura diagonal se alineaba entre píxeles vecinos.

## Por qué del código

### Pasadas

`etapas/post/02-volumen.wgsl` (`output = "volumen"`, `scale = 0.5`), `03-composicion.wgsl`, `04-final.wgsl`
(la 01 es el mapa de la aurora, 06).
La composición lee la escena de `scene_color`, no de `input.color`: tras una pasada con destino propio no
está claro qué le llega en `previous`, y así no depende de ello. Sale **luz lineal en coma flotante**; la
final ya no decodifica, solo expone, grada y mapea.

### Ruido

`tools/ruido/generar_ruido.py` escribe `texturas/ruido2d.png` (256², repite: fBm de gradiente a tres escalas y
Worley) y `texturas/ruido3d.png` (atlas de 32 cortes de 32×32 de un volumen que repite en los tres ejes:
Perlin-Worley, dos Worley y un fBm). Con ruido por hash puro (`nucleo/ruido`) cada muestra de nube costaba
decenas de hashes; leído de textura, una lectura. El 3D se lee con trilineal a mano (`textureLoad`, 8
lecturas) para que repita exacto sin sangrar entre cortes del atlas. Las lecturas cuentan por sitio en el
código (medido): el presupuesto de 64 por etapa no aprieta.

### Raymarch (`nucleo/volumen/raymarch.wgsl`)

- **Niebla y aire:** de la cámara a la escena o al **alcance** (512 bloques por defecto, no la distancia de
  renderizado), y nunca por encima del plano de nubes si la cámara está debajo. 8 pasos con reparto
  exponencial `(f^u − 1)/(f − 1)` con f = 10, el primero desplazado por ruido. Integración analítica por
  tramo (Hillaire 2015) con extinción gris.
- **El aire también sobre el cielo** (F-2, antes solo delante del terreno): ver §Perspectiva aérea (F-2).
- **Sombra** del mapa (una comparación por paso) con la posición del mapa calculada en el núcleo con la
  fórmula documentada de la distorsión (`luz_posicion_mapa`); **sombra de nubes** evaluada en los dos
  extremos del tramo e interpolada (varía despacio y evaluarla en cada paso costaba).
- **Tramos ordenados:** la niebla solo existe por debajo del plano de nubes bajas; cada capa de nubes, en su
  losa. Los cuatro tramos (niebla y tres capas) no se solapan: se calculan sus entradas y se integran en el
  orden en que el rayo los cruza, esté la cámara por debajo, dentro o por encima de cada capa
  (`vol_integrar`). Visto en el juego desde Y = 420 (cúmulos grandes encima) y Y = 900 (cúmulos grandes
  debajo, con la cima iluminada, por delante del suelo).
- **Píxeles de cielo mirando hacia abajo** (más allá de la distancia de renderizado): el rayo acaba en el plano
  del mar. Antes seguía 512 bloques bajo el mundo, donde las manchas ya no caen con la altura, y desde encima
  de las nubes daba un velo opaco ruidoso (lo vio el gestor; la causa la encontró una sonda: `manchas` > 0
  por el término de bioma húmedo, `downfall` 0,8 del bosque).
- **Nubes:** 14 pasos por capa baja (8/14/20 por calidad), 3 en los altoestratos. El tramo integrado dentro de cada
  capa baja se acota a `OPC_NUBES_TRAMO_MAX` (900 bloques) y, cuando el tramo supera 250 bloques (mirada rasante o
  cámara dentro de la capa), el reparto de pasos se curva (`mix(u, u², 0,7)`) para concentrar pasos de 20–30 bloques
  cerca de la cámara en lugar de dar saltos uniformes de más de 400 bloques. Luz: Beer con
  dos muestras hacia el astro a 8 y 28 bloques **sin erosión** (solo cobertura y forma, como prevé la
  especificación para el presupuesto), fase con «powder», ambiente más oscuro en la base. Hasta 6000
  bloques, fundidas desde la mitad: cerca del horizonte cada paso abarcaba miles de bloques y dejaba vetas.

### Medios (`nucleo/volumen/medios.wgsl`)

- **Aire:** la extinción por bloque medida en `paridad/05` (F-2): ver §Perspectiva aérea (F-2).
- **Niebla nocturna (respuesta de A, 2026-11-02):** tapa el cielo casi entero a propósito (la aurora, 06,
  existe por eso). Uniforme hasta Y = 320 (sin pegarla al suelo: se probó y se deshizo), densidad relativa
  0,38 de noche: σ = 0,0076 por bloque, que da τ ≈ 2,2 al cenit desde Y = 70 (≈11 % de transmitancia; A pide
  10–15 %) y τ ≈ 3,9 hacia el horizonte en los 512 bloques del alcance (≈2 %; A pide < 3 %). **Brillo:** la
  niebla tiene una fase propia (`vol_fase_niebla`: 98,5 % de Henyey-Greenstein con g = 0,95, el resto difuso y
  hacia atrás) y ambiente ×0,005–0,015 del cielo (oscurecida otra vez por el 06 §7 bis): fuera del halo de la luna queda más oscura que el cielo
  despejado. Medido en el juego: 16–34/255 lejos del halo frente a 3–17 de `aurora_off_noche.png`; aún algo
  más clara y gris que la referencia.
- **Niebla:** extinción 0,02 por bloque con densidad relativa 1; manchas de ruido 3D (celdas de 96×40×96
  bloques) umbralizadas, que caen por encima del mar + 24; caída global `exp(−0,025·(y − 320))`.
  Luz: sol × sombra × fase + ambiente ×0,1–0,25 (más mirando arriba). El ambiente es bajo a propósito:
  la referencia de noche (`nch_base.png`) es casi negra, con el resplandor de la luna; con más ambiente la
  niebla nocturna salía gris azulada clara.
- **Nubes (corregidas en 05.4 frente a las formas de palo):**
  - **Causa de los «palos»:** se juntaban tres cosas:
    1. En `vol_cobertura`, el peso dominante (0,7) venía del canal G de `ruido2d.png` (fBm de 16 a 128 celdas en 3200
       bloques: lóbulos de 25–50 bloques en XZ, constantes en Y), y la combinación `v` apenas tenía rango dinámico
       (percentil 90 en 0,495 y 99 en 0,602), por lo que `smoothstep` solo recortaba crestas estrechas de 25–40 bloques
       de diámetro horizontal frente a 100–200 bloques de espesor vertical (relación ancho/alto ≈ 0,2: columnas
       verticales). Además, las oscilaciones de 50 bloques del canal G en 2D hendían cada nube de abajo arriba en
       rebanadas paralelas (`|||`).
    2. En `vol_nube`, `gradiente = base * techo` valía `1,0` en toda la franja central (`h ∈ [0,125; 0,55]`), de modo
       que `d = (cob − (1 − gradiente)) / gradiente` no reducía la altura donde `cob` era pequeña: cualquier mota con
       `cob = 0,1` se estiraba en vertical a lo largo de todo el centro de la capa y perdía la base (`1 − base > cob`),
       quedando como un palo colgante; y donde `cob` saturaba rápido a `1,0` (`smoothstep` de ancho 0,18), las paredes
       quedaban verticales.
    3. La capa grande (`VOL_ESPESOR = 200`) usaba la misma escala horizontal que la pequeña (`100`), duplicando el
       estiramiento vertical.
  - **Solución y paridad (`paridad/05`):**
    1. **Cobertura 2D ancha y suave (`vol_cobertura`):** las zonas de varios kilómetros leen el canal B (fBm de 2
       celdas, escala `OPC_NUBES_ESCALA_ZONAS = 12000` bloques) y la forma de los cúmulos combina el canal R (fBm suave
       de 4 celdas, 75 %) con el canal A (domos celulares de Worley de 8 celdas, 25 %), sin el confeti de alta
       frecuencia del canal G en 2D, y con escala proporcional al espesor de cada capa (`OPC_NUBES_ESCALA_FORMA =
       (3600, 6400)` bloques). La señal combinada se normaliza a `[0, 1]` y se umbraliza con una rampa ancha (`0,48`) y
       raíz cuadrada para que `cob` crezca suavemente del borde al centro del cúmulo (mediana de ancho 240 y 370
       bloques; relación ancho/alto ≈ 4,5–5,4).
    2. **Perfil vertical y cúpula (`vol_nube`):** el techo local de la nube escala con su cobertura horizontal `cob`
       (`h < cob`, `h_c = h / cob`), manteniendo la base anclada en `Y = 250` y `Y = 500`. La envolvente vertical es
       `base · exp(−0,5 · h) · techo`, con `base = 1 − (1 − dy / (25 · cob))⁵` y `techo = 1 − ((h_c − 0,78) / 0,22)^{1,7}`.
       Con la forma horizontal llena (`cob = 1`) reproduce los 40 puntos del vector de `paridad/05` §«Perfil vertical de
       los cúmulos» (cúmulos pequeños Y = 252,5..347,5 y grandes Y = 505..695) con error medio `0,0006` y máximo `0,0050`.
       Donde `cob < 1` (bordes y nubes menores), la nube se queda baja y pegada a la base plana en vez de formar palos.
    3. **Erosión 3D, sombras inter-capa y neblina interna (fino/05 §5):** la escala horizontal de forma se
       ajustó a cientos de bloques (`OPC_NUBES_ESCALA_FORMA = (900, 1800)`) y la escala de erosión a `(110, 180)` con
       detalle fino en `35` bloques y fuerza reforzada (`0,60` y `0,45`), generando cúmulos fragmentados con bordes rotos
       y claros de cielo entre nubes en lugar de bandas continuas. Se incorporó la sombra proyectada entre estratos: los
       altoestratos proyectan sombra solar sobre ambas capas de cúmulos, y los cúmulos grandes proyectan sombra solar
       y reducen la luz ambiental de cielo sobre los cúmulos pequeños situados debajo. Por último, las nubes lejanas se
       funden con el horizonte mediante extinción atmosférica en línea hacia el color del cielo.
- **Capas:** base 187 / 437 / 1937 bloques sobre el mar (`VOL_MAR = 63` → Y = 250 / 500 / 2000, como en `paridad/05`),
  espesor 100 / 200 / 12.

### Sombra de los altoestratos

`vol_sombra_nubes` sumaba solo las dos capas de cúmulos. `fino/04 §6` pide las tres, y la de altoestratos reforzada
con el sol rasante (C-08.1, 2026-11-09). La lámina tiene 12 bloques de espesor y σ = 0,06 por bloque
(`OPC_NUBES_SIGMA.z`): su espesor óptico vertical a cobertura y densidad plenas es 0,72, y el rayo hacia el sol la
cruza con un camino 1 / sen(elevación) veces más largo. A mediodía sombrea poco (T ≈ 0,5); a 12° de elevación,
T ≈ 0,03. Así el velo pálido del atardecer apaga la luz directa del suelo, que es lo que se ve en el original en
`atardecer-oeste`. Sin constantes nuevas salvo `OPC_NUBES_SOMBRA_ALTO` (multiplicador, 1,0); el divisor se recorta a
0,05 (unos 3°) para que no se dispare en el horizonte. Como el volumen usa la misma función, la niebla y el aire bajo
el velo también pierden la luz del sol (menos halo bajo un cielo cubierto).

### Tiempo (`nucleo/volumen/tiempo.wgsl`)

Los once perfiles medidos en `paridad/05` §«Tiempo diario: perfiles sorteados» (con sus coberturas `0..2` y densidades
`0,1..0,5` por capa) y la secuencia por cuarto de día `dia + cuarto` centrada en `3000, 9000, 15000, 21000` (que
reproduce exactamente las 64 filas de la tabla de paridad, y en `6000` mezcla el primer y segundo cuarto). Con lluvia se
mezcla hacia los perfiles de lluvia por día de `paridad/05` §«Con lluvia». **Horario de la niebla** (relativo): amanecer
uniforme 0,06 y manchas 0,5; mediodía 0; atardecer uniforme 0,1; noche uniforme 0,38 y manchas 0,15;
transiciones de 0,08 de día. Lluvia: +0,5 uniforme y +0,4 manchas (× opción). Biomas húmedos: más manchas
con `downfall` por encima de 0,85 (pantanos, junglas, manglares; el bosque normal, 0,8, ya no: sus manchas a
mediodía salían como grano en el halo del sol) y temperatura templada. **Tormenta de nieve** (`precipitation == 2` y lluvia): +1,2
uniforme, +0,5 manchas y luz ambiente ×8 (niebla blanca). Vista en un bioma nevado (escena). En cuevas (luz de cielo en la cámara baja) la niebla queda al 5 %.

### Composición y borde

**Cielo bajo el horizonte y borde:** la niebla de borde y el cielo bajo el horizonte (01) usan el mismo peso
por ángulo (`cie_peso_bruma_horizonte`: bruma hasta ~9° bajo el horizonte, suelo más allá de ~30°), así el
terreno que acaba antes del horizonte casa con lo que el cielo pinta detrás, a cualquier altura de cámara.

Reescalado bilateral: los 4 texels vecinos de media resolución pesados por bilineal × `1/(ε + |Δd|/d)` con
la distancia de cada texel reconstruida con `depth_at` y `view_position`. Niebla de borde: el último tercio de
la distancia de renderizado (cilíndrica), solo cerca del horizonte (no mirando arriba ni abajo), nunca en
cuevas, hacia el color del cielo aproximado de la tabla. `color = escena · T + L`.

## Opciones

Página «Niebla y nubes» y página «Calidad» (ver `docs/efectos/calidad.md`): las opciones sueltas `niebla_pasos` y
`nubes_calidad` salieron del menú al integrarse en los presets `calidad_niebla` (4, 6, 12, 24 pasos y alcance de 256,
512, 1024, 2048 bloques) y `calidad_nubes` (7, 14, 28, 42 pasos y desactivación de la capa baja en Baja). La página
«Niebla y nubes» mantiene niebla sí/no, cantidad, niebla con lluvia, capas de nubes y niebla de dimensiones.
Las sombras de nubes van en la página de sombras (04). Bruma, caída, viento y tiempo aleatorio pasan a constantes
(`opciones/volumen.wgsl`).

## Coste medido

RTX 3050 Ti portátil, 1830×1040, sin límite de FPS. Vista de mañana mirando las nubes con algo de terreno:
4,5–4,8 ms de GPU con todo; volumen ~0,9 ms y composición ~0,2 sobre la misma vista con las pasadas
vacías. Plano de terreno de día: 7,1 ms (6,0 sin el 05). Noche con niebla: +0,9 ms.

## Lava y nieve en polvo (fase 2, falta 05.1)

Con la niebla de vanilla apagada desaparecía también la de inmersión. `adp_niebla_inmersion` (composición, tras el
volumen): niebla exponencial por distancia sobre todo, escena y cielo; en lava (`in_lava` o `eye_in == 2`) naranja
intenso con escala de 0,5 bloques; en nieve en polvo (`eye_in == 3`) blanco azulado con 1,2 bloques. El brillo lo
compensa en parte la exposición automática.

**Visto** (`hoja-inmersion.png`, dentro de una caja de cristal rellena con `command fill`, aislamiento de color
apagado): en lava, todo naranja a un bloque (encima, el fuego de vanilla); en nieve en polvo, gris azulado claro con la
escarcha de vanilla en los bordes.

## Niebla nocturna con el tono de la noche (fase 2, falta 05.2)

La niebla de noche salía gris: su ambiente era el color medio del cielo, casi neutro. De noche (`adp_factor_noche`,
sin lluvia) ese ambiente se lleva hacia su versión saturada ×5 y ×2 de brillo (`adp_volumen_luz`), como pide el 05
§«Cuánto cielo deja ver la niebla de noche» (el ambiente es el color del cielo nocturno, no un gris). La exposición de
noche baja (`OPC_EV_NOCHE` 4,3) para seguir en el objetivo del 11: **17,3/255** a las 18000.

**Visto** (`hoja-niebla-noche.png`, a las 14000 mirando al sur, sin aurora ni aislamiento, frente a
`aurora_off_noche.png`): antes, arriba (8; 11; 15) y gris; ahora (14; 21; 26), azul marino oscuro. La referencia
arriba es (25; 40; 60): sigue algo más oscura y menos azul que ella, pero ya no gris.

## Erosión (fase 2b, punto 6)

Observación del dueño (2026-11-03): tras 99d1de4 las nubes quedaron «demasiado blandas, sin borde ni erosión».
**Causa:** la erosión de 05.4 restaba `(1 − ruido) · 0,32 · (1 − d)` con un solo ruido de periodo 220–360 bloques (vóxel
de 7–11 bloques): apenas mordía y no tenía detalle fino; con la cobertura en rampa ancha y raíz, la densidad crecía
suave desde el borde y la nube se veía como una mancha difusa.

**Ahora** (`vol_nube` en `nucleo/volumen/medios.wgsl`), la erosión de Schneider y Vos (2015) con `remap(d, ruido·k, 1)`,
que recorta la envolvente y deja el borde nítido, en dos frecuencias:
1. **gruesa** (canal R, Perlin-Worley, al periodo de antes `OPC_NUBES_ESCALA_EROSION`), fuerza 0,45
   (`OPC_NUBES_EROSION_FUERZA`): los lóbulos. Con 0,55 se comía demasiada cobertura;
2. **fina** (Worley G·0,625 + B·0,25 + fBm A·0,125, periodo 70 bloques, `OPC_NUBES_ESCALA_DETALLE`), fuerza 0,35
   (`OPC_NUBES_DETALLE_FUERZA`): abajo tal cual (jirones) y desde el 10–60 % del alto del cúmulo invertida
   (coliflores), como en Schneider;
3. en la base solo un 40 % de las dos (`OPC_NUBES_EROSION_BASE`), para que siga plana.

La fina solo se lee donde la gruesa deja densidad. Visto en `hoja-nubes-erosion.png` (recorrido `nubes-recorrido`,
aislamiento encendido): cúmulos con lóbulos y borde definido desde el suelo en los seis rumbos y al cruzar la capa;
las nubes grandes y lejanas siguen más lisas. **Presupuesto:** la pasada final queda en 62 de 64 lecturas de textura (el
volumen va en `shared`); la siguiente lectura en `shared` habrá que pagarla quitando otra.

## Tiempo como datos (fase 3, 2026-11-04)

`paridad/05` (a): en el original el horario de la niebla (densidad uniforme y en manchas al amanecer, a mediodía, al
atardecer y de noche: 8 ajustes) y el tiempo diario (perfiles propios de cobertura y densidad por capa) son ajustables; en
el nuestro estaban escritos dentro de `nucleo/volumen/tiempo.wgsl`. Con el criterio de flexibilidad del dueño pasan a
**constantes con nombre en `opciones/tiempo.wgsl`**, listas para un preset o para el mod nativo:

- `OPC_NIEBLA_HORARIO_UNIFORME` y `OPC_NIEBLA_HORARIO_MANCHAS` (vec4: amanecer, mediodía, atardecer, noche) y
  `OPC_NIEBLA_HORARIO_TRANSICION` (0,08 del día). Se añade la franja de mediodía (0, como antes; el original también da 0).
- `OPC_TIEMPO_COBERTURA` y `OPC_TIEMPO_DENSIDAD` (los once perfiles), `OPC_TIEMPO_SECUENCIA` (el orden por cuarto de
  día y desde dónde se repite) y `OPC_TIEMPO_FUNDIDO` (tramo del cuarto en que se funden; el original tiene una
  «velocidad de la transición»).
- El núcleo solo decide qué perfiles mezclar (`vol_sorteo`) y cómo (`vol_perfil_del_momento`, `vol_horario` con los
  datos por parámetro); el adaptador (`adp_nubes`, `adp_horario`) lee las tablas. Con el mod nativo (formato v1, B-14),
  `adp_momento()` lee el día acumulado real (`adp_mod().dia`) avanzando la secuencia del tiempo atmosférico a lo largo de los días.
- **Sin opciones de menú:** van 58 de 64 y los 8 + 36 ajustes del original no caben; la fusión propuesta por A («cantidad»
  + un preset de reparto) queda para la fase 4. Los perfiles de lluvia siguen en el núcleo (su lógica depende del día).

**Visto** (escena `tiempo-horario`, amanecer, mediodía, atardecer y noche desde la pradera): mismo resultado que antes del
cambio, medias de 89,3 / 147,4 / 107,4 / 12,8 antes y 89,7 / 147,5 / 107,4 / 12,8 después, ~1 nivel por píxel de
diferencia (tramado y TAA).

## Niebla de cueva (05.3, 2026-11-09)

En cuevas, la niebla volumétrica estándar se atenuaba al 5 % sin aportar tinte propio, dejando las galerías profundas
sin referencia de distancia.

**Implementación:**
- `nucleo/volumen/cueva.wgsl` (`vol_niebla_cueva`): función pura que calcula una niebla tenue casi neutra
  (`OPC_NIEBLA_CUEVA_COLOR` = (0,50, 0,50, 0,52), corregido en B-17.9 desde el azul saturado previo para paridad con el
  banco) aditiva y muy débil, sin iluminar la pared del fondo
  (`OPC_NIEBLA_CUEVA_BRILLO` = 0,0004 × `mult_luz`, calibrado para mantenerse por debajo del pie de la luz mínima).
- Depende de la distancia mediante crecimiento exponencial `1.0 - exp(-d / (distancia_escala / caida))` con
  `OPC_NIEBLA_CUEVA_DISTANCIA` = 32 bloques, de modo que en 4, 8 y 16 bloques se aprecie la lectura de profundidad.
- Modulada por la dirección de vista (`mix(1.0, 0.25, clamp(dir_y, 0.0, 1.0))`): más fuerte mirando al frente y hacia
  abajo que hacia arriba.
- Integrada en `adaptadores/volumen.wgsl` (`adp_niebla_cueva`) y compuesta en `etapas/post/03-composicion.wgsl` sobre
  la geometría de la cueva (no sobre el cielo ni con la cámara sumergida en fluidos).
- Respeta el preset `estilo_cuevas`:
  - «Abiertas» (0): niebla desactivada (`niebla_cueva = false`).
  - «Por defecto» (1): caída 1,0, intensidad 1,0.
  - «Oscuras» (2): caída 2,0, intensidad ×0,33.
  - «Muy oscuras» (3): intensidad 0,0 (mantiene la oscuridad total).

## Niebla y perfiles de lluvia (B-16.2)

Paridad con el banco de 2026-11-09 (`fino/05 §4`, `fino/01 §7` y `paridad/05`).
- **Densidad cúbica:** en `vol_niebla` (`nucleo/volumen/medios.wgsl`) la densidad uniforme y de manchas se calculan como el cubo del parámetro horario/climático (`fino/05 §1, §4`). Al mediodía despejado vale 0; de noche y con lluvia sube a 0,2³ = 0,008 bloques⁻¹ uniforme, más manchas de 0,4³ = 0,064.
- **Perfiles de lluvia:** `vol_perfil_lluvia` conmuta a los seis perfiles de lluvia tabulados en `paridad/05` (días 0–7), asignando cobertura/densidad de cúmulos y altoestratos, así como los parámetros de niebla uniforme y manchas.
- **Aporte ambiental de la niebla:** se corrige la fuente ambiental de la niebla (`nucleo/volumen/raymarch.wgsl`), sustituyendo el atenuador erróneo de 0,01 por la fase cenital física que cuadruplica la luz hacia el cenit (`mix(0,25, 1,0, ...)`), permitiendo que la niebla densa brille con el tono gris azulado del cielo en vez de quedar como un vacío negro.
- **Cielo y luz en lluvia:** en `nucleo/cielo/composicion.wgsl`, `cie_aplicar_lluvia` implementa las Tablas A y B de `fino/01 §7`: peso exactamente nulo en el cenit (último cuarto de bóveda) y atenuación lineal por encima de la base de cúmulos bajos (238 m), mezclando hacia el promedio despejado teñido por transmitancia sin oscurecimiento destructivo de tormenta. La luz ambiental de superficie (`adaptadores/material.wgsl`) se mantiene clara y suave en lugar de caer en carbón oscuro.


## Perspectiva aérea (F-2, 2026-11-10)

Síntoma en el banco (`cielo-dia`, `nubes-dia`, `agua-orilla`): el cielo del pack sale más oscuro y saturado que el
original (media 91/106/123 frente a 120/129/140 en `cielo-dia`) y sin la aureola blanca ancha alrededor del sol. El
modelo del cielo no era la causa (F-1: a 0,3 EV de la tabla). `fino/05 §3` y su lista «Lo que B hizo distinto» (2 y 3)
lo sitúan en la perspectiva aérea: el original integra el aire **también en los píxeles de cielo**, hasta el alcance
de la niebla o la primera nube, con la extinción de `paridad/05` §«Perspectiva aérea», que es unas tres veces la que
llevaba el pack en el molecular.

- **Extinción** (`vol_aire`, `nucleo/volumen/medios.wgsl`): molecular (1,45; 3,375; 8,275)·10⁻⁴ por bloque en Y = 62
  con altura de escala 1900 bloques; aerosoles 7,6·10⁻⁵ con altura de escala 265 más un suelo de 2·10⁻⁶. Comprobado con
  `tools/paridad/aire.py` contra los 13 puntos de la tabla: error medio 0,014 EV (máximo 0,07). La misma herramienta
  compara la fase: Elek exacta; la bimodal de aerosoles a 0,12 EV de media (×0,77–0,82 entre 50° y 90°, ×1,15 a 10°);
  un ajuste de tres lóbulos no mejora, así que se deja.
- **Sobre el cielo**: `vol_tramo_niebla` ya no anula la bruma cuando `rayo.cielo`. El tramo de niebla sigue acabando en
  el plano de la base de los cúmulos (ordenación de tramos), no en la primera nube real como pide `fino/05 §1`: queda
  pendiente. Lo que se espera: mirando al cenit a mediodía el aire añade ≈ +40 % de radiancia con el mismo tono
  (τ_azul ≈ 0,13 hasta el plano de nubes) y un halo cerrado alrededor del sol (τ_Mie ≈ 0,013 × fase 12,5 × sol ≈ 0,17,
  el doble del cenit).
- **Ambiente del aire**: `OPC_AIRE_AMBIENTE = 0,55` deshace la ganancia de superficie `OPC_LUZ_CIELO_BASE` (1,8): el
  aire dispersa la radiancia media del cielo tal cual (`fino/05 §3` solo dice «una fracción»; preguntado a A). Con la
  luz de superficie entera el velo que se vio en el juego la primera vez (y que llevó a apagar el aire sobre el
  cielo) sería 1,8 veces mayor.
- Riesgo: `atardecer-oeste` y `niebla-amanecer` ganan bruma clara cerca del horizonte; con el sol a ≤ 1° la luz directa
  del aire es nula (rampa de `atm_luz_directa_sol`), así que el halo bajo no debería crecer por esto.

## Ambiente de la niebla (F-3, 2026-11-10)

Síntoma: en `noche-fractal` (hora 18000, cenit) el fondo del pack es un azul claro (media 41/55/81) frente al azul
grisáceo oscuro del original (32/37/41); la niebla nocturna ya se había medido más clara que `aurora_off_noche.png`
(16–34 frente a 3–17). `fino/05 §2` y su tabla medida dan la **fase cenital del ambiente**: 0,5 en el nadir, 1,97 a
−30°, 2,46 en el horizonte y 2,5 hacia arriba; el pack llevaba `mix(0,25, 1, smoothstep(−0,2, 0,8, y))`, que casi
duplicaba el cenit respecto al horizonte.

- `vol_fase_cenital` (`nucleo/volumen/fase.wgsl`): `2,5 − 2·max(−y, 0)²`, a menos de 0,04 de los cinco puntos.
- `OPC_NIEBLA_AMBIENTE_BASE = 0,26` escala la luz de cielo antes de la fase: deja el horizonte donde estaba (0,64 frente
  a 0,63) y baja el cenit de 1,0 a 0,65 y el nadir de 0,25 a 0,13. La escala fija del original no está medida
  (preguntado a A).
- De noche, `OPC_NIEBLA_NOCHE_BRILLO` pasa de 2,0 a 1,0 (la saturación ×5 de 05.2 se queda, como constante
  `OPC_NIEBLA_NOCHE_SATURACION`). Juntas, la niebla nocturna mirando arriba baja a un tercio y al horizonte a la mitad:
  lo que separaba la medida del gestor de la referencia.
- Lo que se espera: `noche-fractal` con el fondo mucho más oscuro; `lluvia-dia` y la niebla de día apenas cambian
  mirando al horizonte y se oscurecen algo mirando arriba o abajo.

## Cobertura (F-4, 2026-11-10)

Síntoma: en `cielo-dia` y `nubes-dia` (hora 6000, día 0: mezcla de los perfiles «cúmulos pequeños 1 / 0,5» y «grandes
1 / 0,5 + altoestratos 1 / 0,5») el original cubre más de la mitad del cielo con cúmulos densos; el pack, un cuarto
con nubes finas. `paridad/05` dice que las coberturas > 1 «cubren de más»: con el parámetro 1 el original ya cubre mucho.
Medido sobre `texturas/ruido2d.png` con la combinación de `vol_cobertura` (rejilla de 8000×8000 bloques cada 10):
con el umbral `0,68 − cob·0,22` y rampa 0,48 el parámetro 1 cubría el 41 % del plano (30 % con c > 0,3; 15 % con
c > 0,7). Con `OPC_NUBES_UMBRAL = (0,58; 0,28)` y `OPC_NUBES_RAMPA = 0,45`: 64 % (54 %; 34 %); con 0,5: 44 %; con 1,9:
91 %. La erosión 3D recorta después parte de eso. Los altoestratos no cambian. Lo que se espera: más cúmulos y más
grandes en las cuatro escenas de día; las sombras de nubes en el suelo, más frecuentes.

### Halo solar del aire: la fase se aplica dos veces (F-5, 2026-11-10)

La tabla nueva de `fino/05` «Halo solar de la perspectiva aérea» (dispersión del sol por bloque a Y = 62 y 300, por
ángulo al sol) no cuadra con `(σ_r·Elek + σ_m·Mie)`: el halo es ×1700 el valor a 90° y de espaldas queda en ×0,07–0,16.
Dividiendo la tabla entre esa suma sale, ángulo a ángulo, la propia fase de aerosoles («aire Mie»: 12,5; 4,1; 1,7;
0,24; 0,07): el original modula la dispersión del sol en el aire **otra vez** por la fase de aerosoles (la «fase solar
directa» de `fino/05 §3`). Así el halo es un pincho estrecho y, lejos del sol, el aire apenas dispersa luz directa, que
es lo que permite integrarlo sobre todo el cielo sin lavarlo (y lo que faltaba en F-2, que a 90° daba ×4 la tabla).
`vol_tramo_niebla`: `(σ_r·Elek + σ_m·Mie) × Mie × sol + (σ_r + σ_m) × ambiente`. La fase de aerosoles se reajustó
contra esa tabla con una rejilla de tres lóbulos: `0,5·HG(0,9) + 5·HG(0,55) + 1·HG(0,3)` (error medio 0,35 EV frente a
0,55 con la anterior; a 1°–4° sigue ×1,4–1,6 porque la tabla se divide por dos ya a 1°, más estrecho que cualquier HG
de la rejilla). `tools/paridad/aire.py` comprueba la tabla del halo.

### Fase medida de niebla y nubes (F-6, 2026-11-10)

`fino/05 §Medidos` trae la fase total del original por densidad local (0,001–0,5 por bloque) y ángulo (0–180°): la
misma función para niebla y nubes, con el «powder» dentro. Las nuestras no se le parecían: la de la niebla
(`HG 0,95 × 0,985`) daba 61 en el centro del astro y **0,0045 de lado** (la tabla: 20 y 0,17: 38 veces más de luz
lateral); la de las nubes era una mezcla a ojo. Ahora `vol_fase_medida(cos, densidad)` interpola la tabla (9 × 7
valores en `VOL_FASE_TABLA`, lineal en ángulo y en log de la densidad); `vol_fase_niebla` y `vol_fase` son alias con la
extinción local del paso (σ de la niebla; σ_nube · forma en las nubes; luminancia de σ bajo el agua). Lo que se
espera: halo del sol y de la luna en la niebla tres veces menos puntiagudo; la niebla de día iluminada de lado y de
espaldas mucho más clara (`lluvia-dia`: la bruma que faltaba; `niebla-amanecer`), y los cúmulos con el borde
retroiluminado más marcado. Riesgo: la niebla nocturna con luna gana luz lateral (×38 sobre 0,003 de irradiancia:
sigue siendo poco frente al ambiente). Los rayos del fractal (14) usan la fila de 0,01.

**Escala del término solar de las nubes (F-6, visto en Horizon):** con la tabla a escala 1 los cúmulos salían blancos
quemados (de lado y de espaldas la tabla da 0,8–2,6 donde la fase anterior daba ≈ 0,05). `OPC_NUBES_FASE_ESCALA = 0,05`
deja el brillo donde estaba y conserva la forma medida; la escala absoluta del original en las nubes no está medida
(pregunta para A). Comprobado en `pruebas/escenas/banco-f.ctl` (las ocho escenas del banco, con el aislamiento de color
apagado en el manifiesto solo para mirar): cúmulos blancos con sombra propia, no quemados.

## Nubes y niebla con lo medido el 2026-11-10 (F-13)

Respuestas de A en `fino/05` (P1, P5, P6) y `fino/04` (tabla B), y lo visto en los paneles `banco-2026-11-10`.

### Cobertura areal de los cúmulos
`tools/paridad/cobertura.py` evalúa `vol_cobertura` sobre `texturas/ruido2d.png` como el shader y la compara con la tabla
de P6 (fracción del plano con nube, con nube densa y forma media, con el parámetro a 0,5 / 1 / 1,5 / 1,9). La de F-4
(umbral 0,58 − 0,28·cob, rampa 0,45, raíz) daba con 0,5 un 52 % de cielo con nube (original 5–12 %) y con 1 un 51 % de nube
**densa** (original 5–12 %): demasiada nube y casi binaria. Ajuste por rejilla: `smoothstep(u, u + 1,2, señal)^0,75` con
`u = 1,2 − 0,9·cob` (`OPC_NUBES_UMBRAL`, `_RAMPA`, `_EXPONENTE`); error medio 0,03 en las 24 celdas. Con 1 hay nube en el
71 % del plano pero densa solo en el 9 %: mucha nube tenue y pocos núcleos, como el original.

### Luz de las nubes (P1)
- **Autosombra:** `exp(−5 · acumulado · (1 − |seno de la elevación|))`, con el acumulado en tres tomas de forma × densidad
  cada 20 bloques hacia el astro (`OPC_NUBES_AUTOSOMBRA`, `_PASO`; en los altoestratos, dos tomas a 80 y 240). Sustituye a
  las dos tomas con Beer de antes. Es lo que quemaba las nubes: sin ella la fuente era 12–150 veces mayor.
- **Fase total** con la densidad adimensional (forma × densidad del perfil), que es la que usa el original, y **sin** el
  0,05 de F-6b (`OPC_NUBES_FASE_ESCALA` = 1).
- **Luz de cielo dentro de la nube:** el ambiente de la niebla (3/4 del de superficie) × refuerzo con la elevación del
  astro (1 → 2; ajuste `2 − e^(−(elev/22°)³)`) × oscurecimiento con la forma local (1 → 0,76; ajuste
  `0,7578 + 0,2422·e^(−4·forma)`), las dos tablas de P1 con error < 0,07 y < 0,01.

### Sombra de las nubes sobre el suelo y la niebla (`fino/04` tabla B)
Transmitancia `exp(−200·d²)` (0,61 con d = 0,05; 0,135 con 0,1), con `d` la suma por capa de (cobertura − umbral) ×
densidad del perfil. El umbral «medio» que resta la erosión no está medido: 0,35 (`OPC_NUBES_SOMBRA_UMBRAL`), pregunta para
A. Los altoestratos siguen con su espesor oblicuo.

### Cuartos del día (P5)
El perfil sorteado vale para **todo su cuarto** (0–6000, 6000–12000, 12000–18000, 18000–24000) y se funde con el siguiente
solo en el último 5 % (`OPC_TIEMPO_FUNDIDO`); antes los sorteos iban centrados en 3000/9000/15000/21000 y a las horas del
banco (6000, 12000, 18000) salía la mezcla a medias de dos perfiles. Ahora, día 0: a las 6000 cúmulos grandes y altoestratos
(1 / 0,5), a las 12000 altoestratos (2 / 0,3), a las 18000 cúmulos grandes (1,9 / 0,2), como mide P5.

### Aire sobre el cielo y manchas
- Vuelve la perspectiva aérea sobre los píxeles de cielo (`fino/05` §1 y §3): F-6b dejó commiteada una línea de prueba
  («PRUEBA A/B») que la anulaba. Con ella vuelve la aureola del sol de F-5.
- Niebla en manchas: fuera el ×2 sin base y rampa del ruido 0,3–0,9 (`VOL_MANCHAS_RAMPA`, antes 0,45–0,7): con lluvia
  (parámetro 0,4) tapaba un muro a 16 bloques que en el original se ve. A ojo del panel `lluvia-dia`.

**Visto** en Horizon (`banco-f.ctl`, aislamiento a 0, frente a los paneles): `cielo-dia` y `nubes-dia` con nubes blancas de
borde claro, vetas altas y cielo azul, mucho más cerca del original; `atardecer-oeste` con el velo alto pálido del original
(el color cálido que queda es del sol, ver observaciones); `lluvia-dia` gris, con el muro visible. **Sin arreglar:** las
nubes siguen más lisas que las del original (les falta detalle fino), y con lluvia el suelo queda sin sol directo donde el
original lo tiene (depende de dónde cae la nube).

## Niebla hasta la primera nube (F-17, 2026-11-11)

`fino/05` §1: el original traza primero las nubes, anota en cada píxel la distancia al primer punto con nube de verdad, y
después integra el aire y la niebla desde la cámara hasta la geometría, el alcance de la niebla o esa nube; las nubes se
componen detrás. Nosotros cortábamos la niebla en el **plano de la base de los cúmulos** (unos 170 bloques hacia el cenit),
así que sobre el cielo despejado el aire se integraba la mitad o menos de lo que toca y la aureola del sol quedaba corta.

- `vol_integrar` integra las tres capas en un resultado aparte (`vol_tramo_nubes` anota el primer paso con densidad mayor
  que `OPC_NUBES_IMPACTO_UMBRAL`, 0,02: el «umbral tenue» no está medido), después la niebla de 0 a
  `min(escena, alcance, impacto)` y compone las nubes detrás con la transmitancia de la niebla.
- **La sombra de las nubes ya no apaga el sol del aire** (sí el de la niebla): con el sol detrás de un cúmulo la aureola
  desaparecía entera, y en el original se ve alrededor del borde que lo tapa (panel `cielo-dia`). Sin confirmar en la
  especificación: pregunta para A.

**Visto** (`pruebas/escenas/destello-sol.ctl`, mirando al sol en el cenit y a 35° y 55° de él; `banco-f.ctl`): aureola clara
de unos 10°–15° alrededor del sol donde antes había azul liso; sigue siendo menor y más azul que la del original, que además
tiene el velo de altoestratos encendido alrededor del sol. `noche-fractal` queda muy cerca del panel (rayos a los dos lados
sobre fondo oscuro); el resto del banco, sin cambios a la vista.

## Sombra de nubes y manchas con las respuestas 9 y 11 (F-19, 2026-11-11)

- **Sombra de nubes** (`fino/04` «Respuesta a la pregunta 9»): los cúmulos pierden 0,13 de cobertura antes de multiplicar
  por la densidad (`OPC_NUBES_SOMBRA_UMBRAL`; antes 0,35 a ojo), y los altoestratos **entran en la misma suma**, sin umbral y
  por 1 − |seno de la elevación| (antes iban aparte con un espesor oblicuo). Transmitancia `exp(−200·d²)` como en F-13.
  Comprobado en Python con `cobertura.py`: transmitancia media 0,72 con pequeños 1 / 0,5 (original 0,65), 0,71 con grandes
  1 / 0,5 (0,72), 0,06 con la lluvia (0,05); con grandes 1,9 / 0,2 sale 0,06 frente a 0,125.
- **Manchas** (`fino/05` «Respuesta a la pregunta 11»): forma = rampa² del canal A de `ruido3d` entre 0,46 y 0,76
  (`VOL_MANCHAS_RAMPA`), que da mancha en el 53 % del volumen con forma media 0,22 (medido 53 % y 0,213); mitad cada 14
  bloques por encima de Y = 60 (`VOL_MANCHAS_DESDE`, `VOL_MANCHAS_ALTURA`). Sustituye la rampa a ojo de F-13.

**Visto** (`banco-f.ctl`, aislamiento a 0): `lluvia-dia` con niebla más ligera y el suelo en sombra de nubes; el resto sin
cambio a la vista.

## Fase de cielo corregida (F-22, 2026-11-11)

El gestor corrigió la tabla de la fase ambiental de la niebla de `fino/05`: **0,53 a −30°, 0,97 en el horizonte y 1,95 a
+30°** (antes 1,97, 2,46 y 2,50; el nadir 0,5 y el cenit 2,5 no cambian). F-3 ajustó `vol_fase_cenital` a la tabla mala
(`2,5 − 2·max(−y, 0)²`), así que el ambiente de la niebla salía unas 2,5 veces más claro mirando al horizonte. Ahora
`0,5 + 2·smoothstep(t)²` con `t = (y + 1)/2`, error < 0,03 en los cinco puntos.

**Visto** (`banco-f.ctl`, aislamiento a 0, hora congelada): la niebla de `lluvia-dia` baja de (74, 85, 101) a (59, 70, 88) de
media en el centro; las escenas sin niebla, sin cambio a la vista.

## Grano del borde (F-23, 2026-11-11)

Observación del dueño (2026-11-11, 2): «los bordes superiores de las nubes tienen un ruido de grano que no estaba en el
original». **Visto** en `cielo-dia` ampliado: motas de un píxel en los bordes tenues de las nubes pequeñas y lejanas, que
cambian de un fotograma a otro (la diferencia entre dos capturas seguidas se concentra ahí). En el original el borde es
deshilachado (jirones de 25–60 bloques, `formas/nubes.md` §5), no granulado: el grano es tramado sin acumular (`fino/05` §6).

Dos causas y dos arreglos:
1. **Ruido de erosión más fino que el píxel:** el ruido fino tiene vóxeles de ~1 bloque (35 bloques / 32) y el grueso de
   ~3–6; a cientos de bloques un píxel del volumen cubre varios. `vol_nube` recibe la huella del píxel
   (`t × OPC_NUBES_HUELLA`, 0,0023 bloques por bloque de distancia a ½ resolución) y, entre 0,5 y 1,5 vóxeles por píxel
   (`VOL_NUBES_LOD`), cambia cada ruido por su valor medio (0,5), para que la nube no engorde a lo lejos.
2. **Tramado del trazado sin acumular:** el original acumula el volumen en el tiempo con recorte de vecindario. Aquí no hay
   destino libre para un historial del volumen (los cuatro de Horizon están ocupados), así que el reescalado del volumen
   en la composición usa, **sobre el cielo**, una tienda 3×3 de texeles que también sean cielo (`adp_volumen_reescalado`). En
   el terreno sigue el bilateral de 4 tomas que respeta la profundidad. La composición pasa de 26 a 28 lecturas.

**Visto** (`cielo-dia` ampliado, aislamiento a 0): las motas del borde casi desaparecen y queda un borde suave. Pendiente
(lote 2, formas): el ruido fino de erosión no es anisótropo como pide `formas/nubes.md` §5 (25 × 6 bloques).

## Nieblas analíticas (F-29, 2026-11-12, subsistema 23)

- **Orden de la composición** (23): borde, **cueva**, volumen, inmersión. La de cueva iba después del volumen.
- **Detector de cueva** (`adp_detector_cueva`, en `adaptadores/marco.wgsl`): sin luz de cielo en la cámara (suavizada
  por Horizon, 0,005–0,03, `OPC_CUEVA_DETECTOR`); lo comparten la niebla de cueva y la de borde. El «ánimo de cueva» de
  vanilla no está en `Frame`.
- **Niebla de cueva:** con la fracción de la distancia de renderizado, cuadrática con la caída 1, y con la vista
  `e^(−3,4·(1 + y))` (1 mirando a una sima, 0,031 al frente, 0,002 al techo), tablas de 23 §1. Antes, exponencial con
  32 bloques y casi igual al frente que abajo.
- **Niebla de borde:** `smoothstep(0,67; 1)` de la distancia horizontal entre la de renderizado y, con la vista, total al
  frente y abajo y nula hacia 15° arriba (`e^(−(y/0,079)²)`). Antes también se apagaba mirando abajo. Por `1 − detector`.
- **Inmersión y efectos:** lava, nieve en polvo, **ceguera y oscuridad**, con el color de niebla de vanilla
  (`frame.fog_color` en lineal), mezclado con `smoothstep` de la fracción del fin de la niebla; la oscuridad lleva la
  densidad a 1 con el doble de su pulso. **Medido:** dentro de la lava `frame.fog_end` de Horizon pasa de 4 bloques (no
  es el de la lava), así que se acota con los de vanilla: 1 bloque en lava, 2 en nieve en polvo y 5 con ceguera
  (`OPC_INMERSION_FIN`). Sale de la pasada final la ceguera propia que había (oscurecer con la distancia).

**Visto** (`pruebas/escenas/nieblas-analiticas.ctl`, aislamiento a 0): en la lava, todo rojo a un bloque; en la nieve en
polvo, velo azul grisáceo; con ceguera y oscuridad, negro (el color de vanilla); en campo abierto, el borde se funde con el
cielo y no hay velo mirando 15° arriba. **Sin ver:** la niebla de cueva mirando a una sima.
