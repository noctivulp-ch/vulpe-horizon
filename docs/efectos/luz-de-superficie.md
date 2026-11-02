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

- Luz de cielo: `(l² + l¹⁵)/2` (muy cerrada al principio, casi lineal al final).
- Luz de bloque: `(1 − √(1 − l))²` y por encima de 0,7 una mezcla cúbica hacia ×3.

### Difusa y ambiente

- Lambert con 0,05 de desplazamiento (`(N·L + 0,05)/1,05`): las caras rasantes no parpadean.
- Plantas cruzadas (ids 2 y 4): `N·L = 0,75` fijo.
- Ambiente hemisférico: `mix(suelo, cielo, N.y/2 + ½) · mix(0,55; 1; …)`, con cielo y suelo de la tabla
  de la atmósfera (01). Con lluvia el sol se apaga al 10 % y el cielo se vuelve gris.

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

Página «Luz» (presupuesto de `convenciones.md`): luz de cielo y de bloque (0–2), luz mínima en cuevas, SSS
(apagado, lista, LabPBR, ambas), reflejos de pantalla (apagados, bajos, altos) y charcos. Color de la luz de
bloque, luz mínima al aire libre, brillo del SSS, especular del sol y emisión LabPBR pasan a constantes
(`opciones/luz.wgsl`).

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
