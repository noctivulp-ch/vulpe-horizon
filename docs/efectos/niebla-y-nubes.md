# Niebla volumétrica y nubes (subsistema 05)

Especificación: `../vulpe-horizon-spec/subsistemas/05-niebla-y-nubes.md`. Capturas: `pruebas/capturas/niebla-*.png`
y `hoja-niebla.png` (escena `pruebas/escenas/niebla.ctl`).

## Qué hay y qué falta

Pasada 1 a media resolución con destino propio `volumen` (rgb luz ya expuesta, a transmitancia): aire
(perspectiva aérea, solo delante del terreno), niebla global uniforme y en manchas con su horario, caída con
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
- **El aire solo delante del terreno:** el cielo (01) ya lleva su atmósfera; integrarlo también en los
  píxeles de cielo lo tapaba con una bruma (visto en el juego).
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

- **Aire:** Rayleigh (0,5; 1,2; 2,9)·10⁻⁴ y Mie 1·10⁻⁴ por bloque al nivel del mar, altura de escala 600
  bloques. Afinado a ojo: azula y aclara lo lejano sin velar lo cercano.
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
    3. **Erosión 3D e inclinación:** la erosión 3D (`OPC_NUBES_ESCALA_EROSION = (220, 360)`) se atenúa en la base
       (`smoothstep(0, 0,25, h) · (1 − d)`) para conservar la base plana y esculpir coliflores 3D en los flancos y la
       cúpula. La inclinación por el viento se modera a `OPC_NUBES_INCLINACION = 0,12` del espesor.
- **Capas:** base 187 / 437 / 1937 bloques sobre el mar (`VOL_MAR = 63` → Y = 250 / 500 / 2000, como en `paridad/05`),
  espesor 100 / 200 / 12.

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

Presupuesto de `convenciones.md` (2026-11-02): niebla sí/no, calidad (pasos 4–16), cantidad, con lluvia,
**nubes por capas** (apagadas, todas, solo cúmulos, solo altoestratos) y calidad de nubes. Las sombras de
nubes van en la página de sombras (04). Bruma, caída, alcance, viento y tiempo aleatorio pasan a constantes
(`opciones/volumen.wgsl`, en mayúsculas) con su valor por defecto.

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
  datos por parámetro); el adaptador (`adp_nubes`, `adp_horario`) lee las tablas.
- **Sin opciones de menú:** van 58 de 64 y los 8 + 36 ajustes del original no caben; la fusión propuesta por A («cantidad»
  + un preset de reparto) queda para la fase 4. Los perfiles de lluvia siguen en el núcleo (su lógica depende del día).

**Visto** (escena `tiempo-horario`, amanecer, mediodía, atardecer y noche desde la pradera): mismo resultado que antes del
cambio, medias de 89,3 / 147,4 / 107,4 / 12,8 antes y 89,7 / 147,5 / 107,4 / 12,8 después, ~1 nivel por píxel de
diferencia (tramado y TAA).
