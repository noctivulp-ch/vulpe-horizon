# Luz de superficie (subsistema 03)

Especificación: `../vulpe-horizon-spec/subsistemas/03-luz-de-superficie.md`. Capturas: `pruebas/capturas/luz-*.png`
(escena `pruebas/escenas/luz.ctl`).

## Qué hay y qué falta

Hecho en la etapa `material`: difusa directa del sol o la luna con el sombreado de vanilla quitado, SSS de
la lista de bloques o de LabPBR (directo y de cielo), luz de cielo hemisférica con su curva, luz de bloque
con refuerzo y color de `[[lights]]`, luz mínima, especular GGX del sol, reflejo del cielo aproximado para
superficies lisas y metales, LabPBR completo (suavidad, F0, metales predefinidos, SSS, porosidad, emisión,
normales), emisión sin PBR por téxeles brillantes, humedad y charcos, y `set_surface` para post.

Los **reflejos en espacio de pantalla** van en la pasada post de composición (05). La sombra y el grosor del
SSS vienen del 04 (`docs/efectos/sombras.md`).

**Luz de cielo ×1,8** (`OPC_LUZ_CIELO_BASE`): la tabla da cielo/sol ≈ 0,08 a mediodía y las sombras salían
oscuras; ×1,8 lo lleva al 0,1–0,2 de `convenciones.md` y deja las sombras azuladas, no negras.

## Por qué del código

### Composición (`etapas/material.wgsl`)

`difusa_directa (+ SSS) + albedo·(cielo + bloque + mínima) + SSS de cielo + especular + reflejo`, luego la
emisión mezcla hacia su color. En los metales la difusa se anula; en los dieléctricos lo que se refleja del
ambiente se le quita a la difusa (`1 − F`). Se escribe codificado (ADR 0004), con tramado IGN por píxel.

### Entrada (`adaptadores/material.wgsl`)

- **Sombreado por cara de vanilla:** el `tint` lo trae (arriba 1; abajo 0,5; norte/sur 0,8; este/oeste
  0,6) y se dividiría dos veces con el direccional real. Se divide por `select(0,5; 1; n.y > 0)·n_y² +
  0,8·n_z² + 0,6·n_x²`, que da el valor exacto en caras alineadas; las plantas cruzadas no llevan ese
  sombreado y no se dividen.
- **Albedo** = sRGB → lineal de `albedo × tinte`.
- **Sin paquete PBR:** suavidad 0,15, F0 0,04 (dieléctrico), sin emisión ni SSS del mapa.

### Escala

Una superficie blanca de Lambert al sol de mediodía vale 1 (la tabla da irradiancia π): directa =
`albedo · E/π · N·L`. Proporciones de partida, afinadas a ojo:

| Luz | Valor | Dónde |
|---|---|---|
| Luz de bloque junto a la fuente, antes del refuerzo | 0,012 (×3 de refuerzo pegado) | `OPC_LUZ_BLOQUE` |
| Luz mínima | 0,0004 × (opción + 20·visión nocturna) | `OPC_LUZ_MINIMA` |
| Emisión | 0,05 × 4 × albedo | `OPC_EMISION` |

La luz de bloque es débil frente al sol a propósito: con la **exposición previa de interior** (2^6,
`OPC_EV_INTERIOR`, que manda cuando `eye_light_smooth.y` es baja: `nucleo/color/exposicion.wgsl`) una
antorcha se ve bien en una cueva, y de día al sol apenas se nota, como en la realidad.

### Curvas

- Luz de cielo: `(l² + 2·l¹⁵)/3` (ponderación de 1/3 suave y 2/3 abrupta de grado 15, calibrada exactamente con la tabla de `paridad/03`).
- Luz de bloque: `(1 − √(1 − l))²` y por encima de 0,7 una mezcla cúbica hacia ×3.

### Difusa y ambiente

- Lambert con 0,05 de desplazamiento (`(N·L + 0,05)/1,05`): las caras rasantes no parpadean.
- Plantas cruzadas (ids 2 y 4): `N·L = 0,75` fijo.
- Modulación direccional de la luz de cielo (Overworld, `fino/03 §2` y `paridad/03`): normal en norma L1
  (`ny_l1 = n.y / (|nx| + |ny| + |nz|)`), con factor direccional que interpola entre 0,08 (inferior), 0,356
  (pared vertical) y 1,0 (superior). Interpola hacia 1,0 (isótropo) conforme la luz de cielo del bloque cae a
  cero en interiores y cuevas. El tope superior queda acotado por la oclusión ambiental (`min(f_dir, mix(0.356, 1.0, ao))`).
  No se utiliza color de suelo en Overworld; en dimensiones Nether y End se mantiene el modelo hemisférico `luz_hemisferica`.

### SSS

Familias por id de `[[materials]]` (manifiesto): 1 hojas, 2 plantas altas/retoños/algas, 3 hielo compacto
(fuerte, 0,9); 4 hierba/flores/lianas, 5 liquen/pétalos/amatista (medio, 0,6); 6 nieve/telaraña/coral/
champiñón (débil, 0,3). Con LabPBR, el canal azul por encima de 65/255 manda si la opción lo pide.
Perfil `e^(−grosor/alcance)·cantidad` con alcance de 0,05 a 1,5 bloques; color absorbido = albedo
saturado ×1,5 por lo que no pasa; fase de dos lóbulos de Henyey-Greenstein (g 0,85 y 0,4) normalizada a
~1 de lado y ~10 a contraluz. La directa total es `mix(SSS, albedo, N·L × sombra)`.

**Alfombras y capas de nieve (decidido: aceptarlo, la primera opción de A):** Horizon da el id por sprite
(`[[materials]] blocks` tampoco lo separa) y la alfombra usa el sprite de la lana y la capa de nieve el del
bloque de nieve. Las alfombras quedan sin SSS como la lana, y las capas de nieve con el débil del bloque.
Distinguirlas por la altura de la cara superior solo serviría para esa cara y se notaría poco.

### Especular y LabPBR

GGX + Smith correlacionado + Schlick (`nucleo/superficie/brdf.wgsl`); rugosidad lineal α = (1 − suavidad)²,
que es lo que entra tal cual en la GGX, la visibilidad de Smith y el muestreo VNDF. **Corregido el
2026-11-02** (lo hizo revisar el gestor): se volvía a elevar al cuadrado dentro del especular y del VNDF, con
lo que la α efectiva era (1 − s)⁴ y los brillos salían más estrechos y fuertes de lo debido. LabPBR
según su estándar público: verde < 230 F0 lineal, 230–237 los ocho metales predefinidos con su F0
calculado de n y k (tabla del estándar), 255 metal con el albedo de F0. **Reflejo del ambiente:** el color
del cielo en la dirección reflejada aproximado con la tabla (horizonte → cielo medio ×2 hacia arriba,
suelo hacia abajo) × Fresnel con rugosidad de Lagarde × curva de luz de cielo; solo con suavidad > 0,45
(se funde hasta 0,7) o en metales.

### Emisión

Sin PBR: emiten los téxeles cuyo canal máximo pasa de 0,35 (se funde hasta 0,75), × `input.emission`.
Con PBR: alfa LabPBR al cuadrado.

### Humedad

`frame.wetness` × exposición al cielo (`smoothstep(0,82; 0,92; luz_cielo + ruido)`); charcos en caras hacia
arriba donde un fBm de 3 octavas a 9 bloques queda bajo el nivel de mojado; en las verticales, ruido
estirado que baja con el tiempo. Mojado: albedo `^(1 + 0,7m)·(1 − 0,15m)` y suavidad hacia 0,85; charco:
suavidad 0,97, F0 0,02, normal de la cara. Ruido procedural (`nucleo/ruido`), sin textura.

### Datos para post

`set_surface(normal, suavidad, dato)`: `scene_surface` es de 32 bits por canal (Horizon guarda la normal
como bits de un f32), así que el dato lleva **F0, la fracción indirecta y la luz de cielo de Minecraft en 8
bits cada uno** (24 bits: entero exacto en un f32; `nucleo/superficie/datos.wgsl`). La especificación
proponía los dos primeros; la luz de cielo hace falta para el reflejo de cielo de los rayos que no impactan.

### Reflejos de pantalla

En la composición (`adaptadores/reflejo.wgsl`, `nucleo/superficie/reflejo_pantalla.wgsl`), para el terreno
sólido con suavidad ≥ 0,7 (`OPC_SUAVIDAD_REFLEJO_PANTALLA`): el material **no** pone su reflejo aproximado
del cielo en esas superficies (lo sustituye el trazado, no se suma). Trazado del rayo reflejado en el espacio
de la escena, 16 pasos (32 en «altos») crecientes al cuadrado hasta 48 bloques, el primero desplazado por
ruido, impacto cuando el rayo pasa por detrás de la profundidad de la escena con un grosor de 0,3 + 0,15·t
bloques, y 4 pasos de bisección; las posiciones se reconstruyen con `projection·view` y su inversa (datos de
`frame`). Se funde en el 8 % del borde de la pantalla. Sin impacto, el cielo aproximado de la tabla en la
dirección reflejada × curva de la luz de cielo del punto. Por Fresnel con rugosidad sobre el F0 del dato. Sin
paquete PBR solo lo usan los charcos.

**Rugosidad:** la normal de microfaceta se muestrea de la VNDF de GGX (Heitz 2018, `sup_muestrear_vndf`) con
dos números al azar por píxel y fotograma, en una base ortonormal alrededor de la normal (Duff et al. 2017);
el TAA (09) promediará el ruido. Los charcos (suavidad 0,97) son casi espejo y la desviación apenas se nota;
**no se ha podido ver en superficies rugosas** sin un paquete LabPBR.

## Opciones

«Luz mínima al aire libre» (`luz_minima_exterior`, 0–1, por defecto 0) es opción desde el punto 5 de la fase 2b
(ver `exposicion-tonemap-gradacion.md` §«Oscuridad mínima y máxima»).

Página «Luz» y página «Calidad» (ver `docs/efectos/calidad.md`): la opción `reflejos_pantalla` salió del menú para
integrarse en el preset `calidad_reflejos` (Baja: 8 pasos, rugosidad 0,2 / suavidad 0,8; Media: 15 pasos, rugosidad 0,3 /
suavidad 0,7; Alta: 30 pasos, rugosidad 0,4 / suavidad 0,6; Ultra: 50 pasos, rugosidad 0,5 / suavidad 0,5; SSR en
translúcidos pendiente). En la página «Luz» quedan luz de cielo y de bloque, mínimos de cuevas y exteriores, SSS y charcos.

## Coste

naga: material 3331 expresiones, 3 lecturas de textura (las lecturas se cuentan por sitio en el código, no
por ejecución: un bucle de 100 lecturas cuenta 1; medido con un pack de ensayo).

## Colores de la luz de bloque (fase 2, falta 03.1)

`[[lights]]` en el manifiesto con las familias de la especificación 03 §«Colores de la luz de bloque»: fuego normal
(el cálido por defecto), de almas (cian frío), velas teñidas, redstone (rojo), lámpara de redstone / piedra luminosa /
brillacho / calabaza (amarillo cálido claro), lava y magma (naranja intenso), linterna marina / conducto / faro / vara
del End (blanco frío), amatista / obsidiana llorosa / ancla / portal (violeta), liquen y bayas luminosas (verde
amarillento) y las tres ranaluces. `adp_color_luz_bloque` ya leía `block_light_color`; ahora tiene datos.

**Purkinje junto a las fuentes:** en una cueva a oscuras con antorchas, el efecto Purkinje (11) se llevaba todos los
colores al azul y la antorcha normal salía tan fría como la de almas. Se apaga con la luz de bloque en la cámara
(`1 − smoothstep(0,15; 0,6; eye_light_smooth.x)`): junto a una fuente el ojo no está en visión escotópica.

**Visto** (`hoja-luces.png`, escena `pruebas/escenas/luces.ctl`, sin y con el aislamiento de color): la antorcha de
almas cian y la lámpara de redstone amarilla, que tiñen el suelo cercano de su color. La antorcha normal y la
amatista quedaron fuera del encuadre en la captura final.

**Dato del motor:** `horizon-ctl fill` y `setblock` cambian solo el cliente (el servidor lo deshace, como el `tp`);
las escenas usan `command fill` / `command setblock`, de uno en uno con pausa.

## Estaciones (fase 2, falta 03.2)

`nucleo/superficie/estaciones.wgsl` + `adp_material_punto`: sobre el albedo de los bloques con color de bioma (tinte
no blanco), un tinte por estación (verano sin cambio, otoño, invierno con desaturación del 35 % y un leve malva,
primavera más fresca), 24 días por estación con el último cuarto fundido con la siguiente; las hojas (id 1) con su
propio tinte, más marcado. Un tinte multiplicativo no saca naranja de un verde (su rojo es bajo): en las hojas la mitad
del efecto lleva el color hacia el tono del tinte conservando su luminancia. La estación continua sale de `adp_mod().estacion` (`frame.mods[1].z`, formato v1: 0 Primavera, 1 Verano, 2 Otoño, 3 Invierno);
**sin mod nativo, fijo en la estación inicial** (opción, Verano por defecto). Solo en el Overworld.

**Visto** (`hoja-estaciones.png`, cambiando la estación inicial): verano tal cual; otoño con las hojas ocres y pardo
anaranjadas; invierno apagado y grisáceo; primavera verde más fresco. La hierba cambia poco (su tinte es suave a
propósito). Con el mod nativo (formato v1, corte comprobado en el juego), `sup_estacion_mod()` transiciona suavemente según el calendario estacional.

Opciones: estaciones sí/no y estación inicial, página «Luz». Van 53.

## Luz de bloque y mínima según paridad 03 (fase 3, 2026-11-04)

`paridad/03` mide la antorcha del original en la escala común: pegada a la fuente (nivel 15) ≈ 1,47 veces el sol de
mediodía, a 3 bloques (nivel 12) 0,23. La nuestra era 0,036 pegada (0,012 × refuerzo 3), unas 40 veces menos, y la
exposición previa de interior (`OPC_EV_INTERIOR` = 6) lo compensaba.

- **Curva:** la tabla medida de 16 niveles (canal R; con el color por defecto (1; 0,5; 0,25) G y B salen de él),
  interpolada (`LUZ_TABLA_BLOQUE` en `nucleo/luz/curvas.wgsl`); `OPC_LUZ_BLOQUE` = 1 la multiplica. Sale la fórmula
  `(1 − √(1 − l))²` con refuerzo cúbico.
- **Luz mínima de cueva:** `OPC_LUZ_MINIMA_CUEVA` = 0,00294 por unidad de la opción (con 0,6 da 0,001766, el del
  original; con nuestro 0,5 por defecto, 0,00147). Antes 0,0004, unas 7 veces menos. `OPC_LUZ_MINIMA` queda para los otros
  mínimos (agua, visión nocturna).
- **Exposición de interior:** `OPC_EV_INTERIOR` 6 → 3. Con la curva del original (`paridad/11`) una sala iluminada por
  una antorcha (paredes a nivel 8–11, L ≈ 0,05) se expondría ×2 y quedaría hacia 100/255.

**Visto** (`hoja-antorcha.png`, escena `antorcha-cueva`: antorcha en el suelo de una caja de piedra cerrada, a 16, 8, 4,
2 y 1 bloques, sin antorcha, y fuera de día y de noche; media del cuarto central): con la antorcha 55 / 108 / 123 / 127 /
131 (antes 41 / 56 / 66 / 72 / 75, con la sala casi negra salvo junto a la llama); ahora la luz cálida llena la sala y cae
con la distancia. Sin antorcha, 35 (las formas se distinguen). Fuera, día 170 y noche 19 en esa vista, sin cambios
(probado con EV de interior 4,5: 129–149 dentro; 3,5: 114–136). **Sin ver:** antorchas al aire libre de noche (ahora
dominan su entorno, como en el original) y las familias de color del 03.1.

## Luz de color en la mano (fase 4, 2026-11-08)

La especificación 03 §«Fuera de alcance / limitaciones en Horizon» daba por imposible la luz del objeto en la mano porque `Frame` no informaba sobre los objetos del jugador ni su iluminación dinámica.

Con las novedades de la API 0.1 de Horizon (nightly 2026-11-08, entrada de registro 2026-11-02), con las luces dinámicas activadas el motor entrega en `MaterialInput.colored_light` (`vec3<f32>`, 0..1) la luz de color de los objetos que se llevan en la mano o están en el suelo (en el color de su bloque según `[[lights]]`), así como de `[[particle_lights]]` y luces de mods.

- **Integración:** en `adaptadores/material.wgsl`, `adp_material_punto` extrae `input.colored_light` gobernado por la opción `luz_mano` (0: apagada; 1 o 2: activa).
- **Tratamiento en el material:** en `etapas/material.wgsl`, `p.luz_colorida` se suma a la luz de bloque del material (`(adp_color_luz_bloque(...) * luz_curva_bloque(...) + p.luz_colorida) * OPC_LUZ_BLOQUE * o.bloque`), compartiendo la escala `OPC_LUZ_BLOQUE` y el preset de intensidad `o.bloque`.

## Cueva a oscuras y compensación del fílmico (fase 4, 03.4)

En el commit `2041d82` (11.2) se activó el mapeo de tonos fílmico (Hejl 2015) por defecto con una escala de exposición
propia de ×0,5 (`OPC_TONEMAP_EXPOSICION = 0,5`). Al reducir a la mitad la luz que entra al tonemap y contar la curva de
Hejl con un pie pronunciado (se anula bajo ~0,00465 y comprime fuertemente los oscuros frente a la linealidad inicial
de Reinhard), la luz mínima de cueva (`OPC_LUZ_MINIMA_CUEVA = 0,00294`, calibrada en 03.3 con Reinhard) quedó
atrapada en la base de la curva: en una caja cerrada de piedra a medianoche (`time 18000`), el gestor midió una media de
3/255 y máximo de 15/255, dejando la cueva prácticamente negra.

- **Arreglo:** se eleva `OPC_LUZ_MINIMA_CUEVA` a `0,0071` (~2,41×). Con la opción por defecto (`0,5`), la irradiancia
  mínima de cueva pasa a `0,00355`. Tras la adaptación de la exposición automática y la escala ×0,5, el valor medio
  entregado al fílmico se sitúa en ~0,026, devolviendo la media de la imagen en el cuarto central a ~35/255 en sRGB
  (distinguiendo las formas de la cueva a oscuras sin antorchas).
- **Invarianza exterior:** al aire libre, `minima` se interpola con `o.minima_exterior` (0,0 por defecto), por lo que
  la iluminación exterior de día (≈146/255) y de noche (≈17–19/255) no sufre ninguna alteración.

## Cuevas y paridad del banco (B-17.9, 2026-11-09)

En el banco comparativo de paridad (`banco-2026-11-09.md`, escena `cueva-oscura`), Horizon mostraba el fondo, el techo
y el entibado con una luminosidad excesiva y un tinte azulado, mientras que en el original la galería está casi negra y
apenas se intuyen las tablas de madera del entibado más cercano.

- **Calibración de la luz mínima:** se devuelve `OPC_LUZ_MINIMA_CUEVA` a `0,0018` (medida exacta de `paridad/03`: `0,001766`
  en nivel de cielo 0), con `OPC_LUZ_MINIMA_CUEVAS_DEFECTO = 1,0` (antes 0,0071 con multiplicador 0,5, que daba ~0,00355).
- **Linterna de cámara frontal (`fino/03 §3`):** la luz mínima no es isótropa ni constante con la distancia: modula con el
  coseno entre la normal y la visual de cámara (`frontal = max(dot(n, p.vista), 0.0)`) y decae con la distancia
  `1 / (1 + dist · 0.22)`. Las superficies frontales a 1–2 bloques (entibado) reciben hasta ~75 % del aporte, mientras que
  las paredes del fondo a 12–16 bloques caen a menos del 20 % y desaparecen en la oscuridad profunda.
- **Transición con apertura y anulación de cielo:** combina la apertura de la cámara y del bloque
  `apertura = clamp(luz_cielo + cielo_camara · (1 - luz_cielo), 0.0, 1.0)` y se anula progresivamente con `(1 - luz_cielo)`
  como indica la tabla de paridad.
- **Protección de fugas solares y SSS en cuevas (`fino/03 §4`):** la luz solar directa y la dispersión subsuperficial
  directa se multiplican por un factor suave de protección `clamp(apertura² · 4, 0.0, 1.0)`, evitando que la vegetación
  o bloques translúcidos subterráneos brillen con sol exterior más allá del mapa de sombras.

## Correcciones de fino/03 del 2026-11-10 (F-9)

A corrigió dos puntos de `fino/03` en los que se basó B-17.9, al revés de lo medido:
- **Luz mínima direccional** (§3 y §Medidos): no es una linterna de cámara sino un **atenuador frontal**: de frente a la
  cámara 0,30, de canto 1,00 (tabla de 0° a 90°: exactamente `1 − 0,7·N·V`). Sin caída con la distancia (la de B-17.9,
  `1 / (1 + d·0,22)`, era inventada y se quita). `OPC_LUZ_MINIMA_FRENTE = 0,30`, con `OPC_LUZ_MINIMA_CUEVA = 0,0018`
  como base. En `cueva-oscura` el pack había quedado más oscuro que el original (1,6/1,2/1,3 frente a 3/4,3/6,8 de
  media): las paredes y el techo vistos de canto vuelven a recibir la luz mínima entera.
- **Fase del SSS de cielo** (§5 y §Medidos): depende de la componente vertical de la **dirección de vista**, no de la
  normal: 1 mirando hacia abajo, 1,58 al horizonte, 2 mirando hacia arriba (11 puntos en `SUP_SSS_FASE_CIELO`,
  `sup_sss_fase_cielo`). Escalada por `OPC_SSS_CIELO = 0,4` para conservar el tope anterior (0,8): el envés de las hojas
  visto desde abajo recibe el doble que la copa vista desde arriba. La escala absoluta del original no está medida.

## Ambiente medido (F-12, 2026-11-11)

**Antes:** la luz ambiente de cielo era la radiancia media de nuestro modelo (`adp_cielo_medio`) × 1,8
(`OPC_LUZ_CIELO_BASE`), con un gris añadido a mano con la lluvia y, en la niebla, una saturación ×5 de noche. Comparada con
la tabla «Luz directa y ambiente de cielo» de `paridad/01`: clavada con el sol alto (×0,96–1,03 a 30°–90°), pero con el sol
bajo le faltaba azul (×0,6 a 4°–10°, ×0,45 a 0°) y de noche valía cero (la tabla da (0,00004; 0,00012; 0,00055) a −12°).

**Ahora:**
- `atm_ambiente_cielo(elevación)` (`nucleo/atmosfera/astros.wgsl`) interpola las 19 filas medidas, como ya hacía
  `atm_luz_directa_sol` con la directa. `adp_ambiente_cielo()` la entrega a la superficie, a la niebla, al aire y a la
  lluvia. `adp_cielo_medio` queda para el cielo dibujado, el fractal y los reflejos.
- **La niebla toma 3/4 y el aire la mitad** de ese ambiente (`fino/05` P2–P3, medido): `OPC_NIEBLA_AMBIENTE_BASE` 0,26 →
  0,75 (por la fase cenital 0,5–2,5) y `OPC_AIRE_AMBIENTE` 0,5 sin mezclar con el suelo. Fuera la saturación nocturna
  (`OPC_NIEBLA_NOCHE_*`): el ambiente nocturno de la tabla ya es azul y tenue.
- **Cielo cubierto** (`adp_cielo_bajo_nubes`): el original ilumina con un «promedio de cielo con nubes» que aquí no se
  integra (`fino/01` §1, sin medir). Se aproxima: cada capa deja pasar `1 − densa·(1 − e^(−4·densidad))`, con `densa` la
  fracción de cielo con nube densa según la cobertura del perfil (`fino/05` P6); lo que pasa llega gris y no baja de
  0,25. Constantes `OPC_CUBIERTO_*` en `opciones/tiempo.wgsl`, **a ojo** del panel `lluvia-dia`: pregunta para A.
- **Con lluvia el sol ya no se multiplica por 0,1** (`adp_irradiancia_astro`): en el original no hay oscurecimiento de
  tormenta aparte (`fino/01` §7); el sol lo tapan las nubes con su sombra (F-13).

**Visto** en Horizon (`banco-f.ctl`, aislamiento a 0): la lluvia pasa de blanco azulado (100, 117, 143 de media en el
centro) a gris (82, 88, 96; el original, 66, 71, 76); la noche al horizonte baja de (6, 12, 25) a (4, 9, 15). De día sin
cambio apreciable.

## Caras hacia abajo (F-14, 2026-11-11)

En el panel `cielo-dia` el original pinta la cara inferior de los bloques flotantes en gris neutro oscuro; la nuestra salía
azul marino: recibía el 8 % de la luz ambiente de cielo con su color. Una cara que mira hacia abajo no ve el cielo: desde
una normal vertical de −0,5 (`OPC_LUZ_ABAJO_NEUTRA`) su luz ambiente va en gris (la luminancia). Aproximación: el original
ilumina con un «promedio de cielo con nubes» (`fino/01` §1, sin medir) que con nubes blancas es mucho menos azul; pregunta
para A.

## Ambiente con nubes (F-16, 2026-11-11)

Corrige el «cielo cubierto» de F-12, que solo sabía oscurecer. En el panel `cielo-dia` las caras inferiores del original
reciben unas 4 veces más luz de la que da el 8 % del ambiente despejado, y neutra: el «promedio de cielo con nubes» que usa
el original (`fino/01` §1) con cúmulos blancos al sol es **más claro y menos azul** que el cielo despejado; con las nubes de
lluvia, más oscuro (sombra del panel `lluvia-dia`: ambiente ≈ 0,02–0,03).

`adp_ambiente_cielo()` (en `adaptadores/tiempo.wgsl`): mezcla el ambiente despejado de la tabla con el de las nubes vistas
desde abajo, `luminancia de la directa · seno de la elevación · e^(−8·espesor) + ½ del despejado`, pesado por la fracción
de cielo con nube; `espesor` = Σ forma media × densidad del perfil. Las dos fracciones salen de la cobertura del perfil
con rampas ajustadas a `fino/05` P6. Al final, la compresión de Reinhard sobre la luminancia que dice `fino/01` §1.
Constantes `OPC_CUBIERTO_*` en `opciones/tiempo.wgsl`. **Todo a ojo de dos paneles**: pregunta para A (el promedio con
nubes medido a mediodía del día 0 y con lluvia).

**Visto:** caras inferiores gris oscuro con el ladrillo visible, como el original; niebla de lluvia gris azulada.

## Repaso contra los esqueletos de `implementacion/` (F-24, 2026-11-11)

Diferencias claras con `implementacion/01` (superficie) y `02` (volumen), corregidas:
- **Recorte de las luces de vanilla** (01 §0): a la luz de cielo y de bloque se le resta 0,05 y se reescala
  (`luz_recorte_vanilla`), antes de todo lo demás.
- **Lambert con margen** (01 §1.2): cero por debajo de un coseno de 0,06 y lineal hasta 1 (antes empezaba en −0,05).
- **Orientación de la luz de cielo** (01 §3.3): con luz de cielo 1, una cara vertical recibe 0,36 y desde −0,5 hacia abajo
  0,08 (antes bajaba en línea recta hasta −1 y a −0,5 daba 0,22).
- **Fugas** (01 §1.5): la luz directa por `min(luz de cielo de la cámara + la del punto, 1)²`, salvo bajo el agua (antes
  `clamp(apertura²·4)`).
- **Transmitancia del aire** (02 §4): la media de los tres canales, no la luminancia.
- **Ambiente de la niebla y del aire** (02 §3b): el del cielo **despejado** de la tabla por la luz de cielo suavizada de la
  cámara (bajo techo se apaga); el ambiente con nubes de F-16 queda solo para las superficies.

Las que no son claras van en `TODO.md` (orden de la nitidez, tope de la oclusión, alcance del rayo de la niebla, volumen
doble a través de translúcidos, pirámide del bloom).

**Visto** (`banco-f.ctl`, aislamiento a 0): sin cambios grandes; la noche mirando al horizonte, algo más oscura.

**Corrección (2026-11-11, respuesta 14 de A):** el tope por oclusión va con el **valor** de la AO (1 despejado): 1 → 1,
0,8 → 0,37, 0,6 → 0,31 y desde 0,4 → 0,30. `luz_direccion_cielo` usa `0,30 + 0,70·e^(−11,5·(1 − ao))` (antes
`mix(0,356; 1; ao)`, que con AO 0,8 dejaba 0,87). Con muy poca oclusión la cara ya recibe el cielo como si mirara de lado.

## Noche y otras dimensiones (F-45, 2026-11-12)

Decisión del dueño (observaciones 2.1 y 2.2): la noche, el Nether y el End estaban demasiado oscuros.

- **Noche:** se suma al ambiente del cielo nocturno (la tabla, casi nada sin luna alta) un mínimo azulado
  `OPC_LUZ_NOCHE_COLOR` (0,55; 0,7; 1) × `OPC_LUZ_NOCHE_CIELO` (0,006) × factor de noche, en `adp_luces`. Pasa por la
  curva de la luz de cielo como el resto del ambiente: en cuevas y bajo techo no llega. Criterio del dueño: a medianoche,
  a cielo abierto, el terreno a 20 bloques se distingue sin parecer de día.
- **Nether:** `OPC_AMBIENTE_NETHER` de 0,0035 a 0,035 (×10; con ×4 no se notaba porque la lava fija la exposición).
- **End:** `OPC_AMBIENTE_END` de 0,002 a 0,008 (×4).
- Son valores para que el dueño decida: capturas de antes y después en `pruebas/capturas/luz-*-antes.png` y
  `luz-*.png` (escena `pruebas/escenas/luz-dimensiones.ctl`).

## Sombra y sol bajo (F-53, F-54, 2026-11-13)

Spec `subsistemas/28-color-a-lo-largo-del-dia.md` §2: la cara a la sombra del cubo blanco es **gris azulada**, con una
relación sombra/arriba de 0,45 a 0,50 a lo largo del día. El pack daba 0,25 a 0,30 y un azul saturado (55°: 33, 66, 110
contra 98, 112, 136): la cara vertical a la sombra solo recibía la luz del cielo, que es azul.

Lo que faltaba es el **rebote del suelo iluminado**: una cara vertical ve medio suelo, y el suelo al sol es claro y
casi neutro. Se suma al ambiente del cielo `luces.suelo × OPC_LUZ_REBOTE_SUELO × (1 − n.y)/2`, con la misma curva de luz
de cielo y la misma oclusión de vértice que el ambiente, así que no entra en cuevas ni bajo techo. `(1 − n.y)/2` vale 0
en las caras hacia arriba (no ven el suelo), ½ en las verticales y 1 en las de abajo.

Medido con `pruebas/escenas/carta-color-dia.ctl` (perfil despejado fijo, hora congelada, `tools/carta-color/medir.py`),
cara norte, pack contra original:

| elevación (hora original) | sin rebote | 1,0 | 0,5 | **0,4** | original |
|---|---|---|---|---|---|
| ~3° (500) | — | 74, 82, 109 | 54, 71, 103 | 49, 68, 102 | 81, 94, 113 |
| ~10° (1000) | — | 114, 118, 136 | 84, 98, 126 | 76, 93, 123 | 106, 113, 126 |
| 35° (3000) | ~33, 66, 110 | 159, 160, 165 | 121, 127, 144 | **109, 118, 138** | 107, 120, 141 |
| 55° (6000) | 30, 64, 112 | 176, 177, 179 | 138, 143, 155 | 126, 133, 148 | 98, 112, 136 |
| sombra/arriba a 35° / 55° | 0,29 / 0,27 | 0,71 / 0,75 | 0,56 / 0,60 | 0,52 / 0,56 | 0,49 / 0,45 |

Se queda en **0,4**: clava los 35°, deja los 55° algo claros (+28) y el sol bajo algo oscuro (−30). El sol bajo no se
corrige aquí: ahí también la cara de arriba sale oscura y azul (−50 a −80), y eso es la ganancia y el tinte del sol por
elevación (la palanca siguiente); al subir la luz del suelo con el sol bajo, el rebote sube con ella.

### Sol bajo (F-54)

Con el sol entre 0° y ~20°, la sombra salía oscura y **azul** (6°: 49, 68, 102 contra 81, 94, 113) y la cara al sol, un
punto naranja (saturación 0,32; la spec pide crema, ≤ 0,25). El ambiente de cielo medido (`atm_ambiente_cielo`) es muy
azul con el sol bajo, y subirlo solo en brillo (primera prueba, ganancia 1,9) dio sombras más claras pero más azules
(66, 96, 138). Lo que falta es **color**, no solo nivel.

`adp_sol_bajo()` interpola tres tablas por la elevación del sol (`opciones/luz.wgsl`, `OPC_LUZ_SOL_BAJO_*`):
ganancia del ambiente de cielo, cuánto se acerca ese ambiente a gris de igual luminancia, y cuánto se acerca a gris la
luz directa. Las tres valen 1 / 0 / 0 a partir de 30° y por debajo de −6°, así que el día alto y la noche no cambian.
**Solo en `adp_luces`** (superficies y agua): las nubes y la niebla usan `atm_ambiente_cielo` directamente y no lo ven.

| elev. | ganancia cielo | gris cielo | gris sol |
|---|---|---|---|
| −6° | 1,0 | 0 | 0 |
| 0° | 1,4 | 0,5 | 0,25 |
| 6° | 1,9 | 0,6 | 0,28 |
| 12° | 1,6 | 0,5 | 0,2 |
| 20° | 1,2 | 0,25 | 0 |
| 30° | 1,0 | 0 | 0 |

Carta completa tras F-53 y F-54 (perfil despejado fijo), pack contra original:

| hora (elev.) | arriba | este | norte |
|---|---|---|---|
| 500 (6°) | 154,163,180 / 198,190,183 | 234,219,192 / 245,234,191 | **84,95,114 / 81,94,113** |
| 1000 (12°) | 194,194,199 / 234,226,210 | 244,237,220 / 251,245,220 | **100,110,130 / 106,113,126** |
| 1500 (18°) | 210,207,204 / 229,224,214 | 245,240,223 / 232,224,200 | 100,110,129 / 121,128,138 |
| 2000 (24°) | 220,216,212 / 243,239,228 | 244,239,225 / 247,242,225 | 102,113,133 / 137,142,145 |
| 3000 (35°) | 229,227,223 / 247,245,237 | 240,236,225 / 244,240,226 | **109,118,138 / 107,120,141** |
| 9000 (35°) | 229,227,223 / 245,242,233 | 109,119,137 / 104,116,135 | **110,119,138 / 104,116,135** |
| 11000 (12°, tarde) | 181,182,187 / 228,221,206 | 85,95,113 / 116,120,126 | 86,96,115 / 117,121,127 |

Lo que queda:

- **Cara de arriba con el sol bajo, −40 a −45.** En la captura del original el cielo de esa hora está lleno de cúmulos
  blancos al sol («despejado» en el original no es sin nubes), y la cara de arriba ve ese cielo entero. El pack se mide
  con el perfil despejado fijo, sin nubes. No se fuerza: sería ajustar a otra cobertura.
- **Tarde (11000–11500), −31 en la sombra.** El sol está detrás del cubo; el original tiene el cielo del sudoeste muy
  brillante (252, 250, 243), que con el sol bajo al oeste da más luz a las caras. Queda para el crepúsculo (F-55).
- **18–24°, −20 a −35 en la sombra**: la ganancia ya ha vuelto casi a 1; se puede subir en la fila de 20°.
