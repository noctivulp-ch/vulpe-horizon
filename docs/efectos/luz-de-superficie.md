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
