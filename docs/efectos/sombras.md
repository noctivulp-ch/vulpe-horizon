# Sombras (subsistema 04)

Especificación: `../vulpe-horizon-spec/subsistemas/04-sombras.md`. Capturas: `pruebas/capturas/sombras-*.png`
(escena `pruebas/escenas/sombras.ctl`).

## Qué hay y qué falta

Mapa de Horizon pedido con `[shadow]` (2048 texels y 128 bloques de semilado por defecto, elegibles con `sombras_resolucion` y `sombras_distancia`). PCSS completo (búsqueda de
ocluyentes, penumbra por distancia, PCF con disco de Vogel girado por píxel y fotograma), PCF fijo como
opción «básica», sesgo por la normal, corrección de fugas en interiores, sombras de color de agua y cristal,
y fundido a la sombra aproximada por la luz de cielo al borde del mapa. La sombra da también el **grosor**
hasta el ocluyente, que usa el SSS del 03.

**Sombras de nubes** (§5): con el 05, el material multiplica la luz del sol por `vol_sombra_nubes` (la
cobertura donde el rayo hacia la luz cruza la mitad de cada capa baja, `e^(−3·c²)`), escalada por la opción.
**Agua:** desde el 07, absorción por el grosor de agua hacia la luz y cáusticas (ver `docs/efectos/agua.md`).

## Por qué del código

### Dónde va

- `nucleo/luz/sombras.wgsl` (en `shared`): el PCSS, que recibe los mapas como **parámetros**
  (`texture_depth_2d`, `sampler_comparison`): el núcleo no conoce los nombres del motor. Lo usará también la
  niebla volumétrica (05) desde post.
- `adaptadores/sombras.wgsl` va solo en `material` (y en post cuando haga falta): usa `shadow_position`,
  que la etapa `sky` no tiene.

### Densidad del mapa por la distorsión

Horizon guarda un punto de clip `xy` en `xy/(|xy|·k + 1 − k)`. La derivada radial `(1 − k)/(r·k + 1 − k)²`
por `resolución/2` y dividida por `shadow_distance` da los **texels por bloque** en cada punto
(`adp_texeles_por_bloque`): en el centro coincide con `1/shadow_center_texel`. Con eso el sesgo y el radio
del filtro van en bloques y valen lo mismo cerca que lejos.

### Sesgo

Por la normal geométrica 0,35 texels (en bloques) y 0,15 hacia la luz (Holbert, *normal offset shadows*).
Sin sesgo de profundidad aparte: en las capturas de cerca no hay acné ni la sombra se despega del pie.

### Fugas de luz

En interiores (luz de cielo de Minecraft baja) la posición de muestreo se acerca un 60 % al centro del
bloque, y la luz directa se multiplica por `smoothstep(0,02; 0,35; luz de cielo)`: sin cielo, sin sol.

### PCSS

1. Búsqueda: 8 lecturas crudas (`textureLoad`) en un disco de 1,5 bloques (2–24 texels); se promedian las
   que están delante del punto. Sin ocluyentes, iluminado sin filtrar.
2. Penumbra = distancia al ocluyente (profundidad × bloques por unidad de profundidad, que se saca de la
   tercera fila de `shadow_view_proj`: la proyección es ortográfica) × 0,0197 más 0,051 bloques (desde 04.1;
   antes × tan 1,5°, ver §«Paridad 04»). Acotada entre 1 y 30 texels.
3. PCF: `muestras` comparaciones (8) en un disco de Vogel; cada una ya es un PCF bilineal 2×2.

El disco gira con el ruido IGN por píxel desplazado por fotograma (secuencia áurea): el TAA (09) lo
promediará. Hasta entonces el borde de la penumbra se ve algo granulado.

**Penumbra mínima:** la opción (0–10, 5 en el centro) son cuartos de texel más uno: 2,25 texels por
defecto, que tapa los 0,125 bloques por texel del centro del mapa con 2048/128.

### Translúcidos

Si el sólido deja pasar la luz y `shadow_map_translucent` no, la luz atraviesa agua o cristal: se lee
`shadow_color` y el cristal tiñe con su color normalizado al cuadrado según su opacidad (alfa); el agua (alfa
1) con un tinte fijo verde azulado (`OPC_AGUA_TINTE`) hasta el 07.

### Borde del mapa

En el último 20 % del cuadrado que cubre el mapa (en clip, `max(|x|, |y|)`) se funde hacia la sombra
aproximada por la luz de cielo; no con la cámara bajo el agua.

### Dónde se busca

Solo en caras hacia la luz, en plantas cruzadas o con SSS, y con algo de luz de cielo
(`etapas/material.wgsl`): las caras de espaldas ya están en sombra por N·L.

### Sombra planetaria del horizonte

`luz_sombra_horizonte` (`nucleo/luz/sombras.wgsl`), aplicada en `adp_sombra` junto a la sombra de nubes (C-08.1,
2026-11-09). Sigue `fino/04 §6`: con el sol rasante, el terreno por debajo de una cota no recibe sol directo, y el
efecto se desvanece al subir el sol. Es lo que faltaba para el banco `atardecer-oeste` (hora 12000, sol a unos 12°):
en el original el suelo y la cara del bloque flotante quedan en sombra fría aunque el disco se ve, y en el pack salía
una franja amarilla de luz directa. La tabla de luz directa de `paridad/01` no podía explicarlo (a 12° da 0,85 de
luma): la anulación tiene que venir de una sombra, no del color de la luz.

- Forma: cota base `cota − elevación × por_grado`; iluminado por encima de ella, en sombra por debajo, con una
  transición vertical de ±`transicion` bloques; todo vuelve a 1 entre `fin.x` y `fin.y` grados.
- **Valores estimados, no medidos** (`OPC_SOMBRA_HORIZONTE`: 220, 10 bloques/°, ±24, 18°–26°): la cota del original
  está en «apuntados para medir» de `fino/04`. Se eligieron para que un suelo a Y ≈ 64–80 quede en sombra a la hora
  12000 (sol a ~12,4° con la curva de vainilla: cota 96) y casi del todo iluminado a la hora 300 (sol a ~17°: cota 50),
  donde el original sí tiene el suelo cálido y soleado. Si la medida llega, se cambian las cuatro cifras.
- Alternativa descartada: adelantar la rampa de visibilidad de `atm_luz_directa_sol` hasta ~13°. Rompería la tabla de
  `paridad/01` (que manda) y apagaría también el disco y las nubes, que en el original siguen iluminados.
- La niebla y el aire del volumen no la usan todavía (solo superficies).

## Opciones

Página «Calidad (presets)» y página «Niebla y nubes» (ver `docs/efectos/calidad.md`): la opción `sombras_penumbra` salió del menú
para integrarse en el preset `calidad_sombras` (Baja: penumbra fija con filtro 4; Media: variable con búsqueda 4 y filtro 8;
Alta: búsqueda 8 y filtro 16; Ultra: búsqueda 16 y filtro 32; sombras de contacto pendientes). Como `resolution_option` y
`distance_option` de `[shadow]` exigen una opción `int` o un `choice` de números y no pueden colgar de un preset con niveles con
nombre ni heredar de `calidad_general`, el tamaño y el alcance del mapa se eligen directamente en la página de Calidad mediante
dos opciones `choice` de números: `sombras_resolucion` (`"1024"`, `"2048"`, `"4096"`, por defecto `"2048"`) conectada a
`resolution_option`, y `sombras_distancia` (`"64"`, `"128"`, `"192"`, `"256"`, por defecto `"128"`) conectada a `distance_option`.
El motor actualiza `frame.shadow_resolution` y `frame.shadow_distance` sin requerir `override` en WGSL, y `adaptadores/sombras.wgsl`
adapta la densidad de texels por bloque (`adp_texeles_por_bloque`) y el sesgo en vivo. Las sombras de nubes (`nubes_sombras`) se
mantienen en la página «Niebla y nubes».

## Coste medido

Plano de terreno a mediodía con árboles (1830×1040, RTX 3050 Ti portátil, sin límite de FPS): material de
vanilla sin mapa 2,35 ms de GPU; con mapa (lo dibuja el motor) 3,66; con el material del 03 y el PCSS **6,0**
(búsqueda de 12 lecturas: 6,6; PCF básico: 5,6). Sin la sombra, el resto del material del 03 cuesta ~0,9 ms
sobre vanilla. naga: material 3736 expresiones, 7 lecturas de textura (por sitio en el código).

Probado sin efecto: salir antes en los téxeles que el test de alfa descarta (Horizon ya no los ilumina).

## Paridad 04 (2026-11-04)

`paridad/04` mide la sombra de un borde recto con el código del original sobre un mapa sintético: la anchura de la
penumbra 10–90 % va de 0,075 bloques (ocluyente a 0,5) a 0,5 (a 16), casi lineal: **0,07 + 0,027·h**. El radio de filtro
satura en 30 texels.

- **Radio en bloques:** `mínimo + crecimiento · distancia al ocluyente`, 0,051 + 0,0197·h (`OPC_SOMBRA_PENUMBRA_MIN`,
  `OPC_SOMBRA_PENUMBRA_CRECE`), pasado a texels con la densidad del mapa en el punto. Antes, `tan 1,5° · h` con un mínimo
  de 2,25 texels: igual a 8 bloques, más dura con ocluyentes bajos y dependiente de la resolución.
- **Tope** 20 → 30 texels (`SOMBRAS_PENUMBRA_MAX`), el del original.
- **Herramienta:** `tools/paridad/penumbra.py` replica nuestro PCF (8 muestras de Vogel, 16 giros, comparación bilineal) y
  da 0,085 / 0,097 / 0,125 / 0,179 / 0,285 / 0,501 bloques a h = 0,5 / 1 / 2 / 4 / 8 / 16 con 53 texels por bloque (cerca
  de la cámara), frente a 0,075 / 0,1 / 0,125 / 0,2 / 0,325 / 0,5.
- **El sesgo no se copia:** en el original un ocluyente a 0,25 bloques no da sombra, por su sesgo con un mapa de 512
  texels; la propia tabla dice que manda la anchura. El nuestro (0,35 texels por la normal, 0,15 hacia la luz, con un
  mapa de 2048) deja las sombras de contacto.
- La opción «Penumbra» básica usa ahora el radio mínimo en bloques (0,051).

**Visto** (`hoja-sombras-borde.png`, escena `sombras-borde`: losas a 1, 2, 4 y 8 bloques sobre piedra lisa a
mediodía, desde arriba y de cerca): las cuatro sombras con borde de anchura creciente con la altura; frente a antes, casi
igual a 4–8 bloques y algo más suave la de 1. **Sin ver:** la penumbra lejos de la cámara, donde pesa el tope de 30.

## Paridad de sombras suaves de follaje (banco 2026-11-09, punto 8, encargo B-17.8)

Discrepancias identificadas en la escena `niebla-amanecer`:
1. **Borde dentado y escalonado por corte prematuro:** en `nucleo/luz/sombras.wgsl`, si la búsqueda no hallaba ocluyentes (`cuenta == 0.0`), el código devolvía 1,0 inmediatamente (`LuzSombra(1.0, 0.0)`). En bordes de copas de árboles y ramas dispersas, esto creaba saltos abruptos de 0,4 a 1,0 sin filtrado alguno, provocando sombras duras y pixeladas en el suelo. Se elimina el corte prematuro: cuando `cuenta == 0`, se ejecuta el bucle PCF completo con el radio mínimo de penumbra (`a.penumbra_min`), produciendo una caída suave y continua en las siluetas del follaje (`fino/04 §Lo que está mal 1`).
2. **Distribución lineal en búsqueda y cuadrática en filtrado:** en la búsqueda de ocluyentes se adopta distribución radial lineal con el índice de muestra (`luz_vogel_lineal`) para densificar muestras cerca del centro y estimar con mayor precisión el bloqueo cercano (`fino/04 §1`), mientras el PCF conserva el espaciado por raíz cuadrada para cobertura superficial uniforme.
3. **Crecimiento de penumbra en follaje a distancia:** se incrementa la tasa de crecimiento de penumbra `OPC_SOMBRA_PENUMBRA_CRECE` a 0,024 y el radio de búsqueda máxima a 36 texels, ampliando la penumbra del follaje a baja elevación solar sin perder la definición de contacto en troncos.
4. **Antialiasing temporal en bordes y follaje (`adaptadores/taa.wgsl`):** se añade el retroceso adaptativo hacia el primer momento (media del vecindario 3×3, Salvi 2016) proporcional al exceso del recorte por varianza, suprimiendo estelas residuales y aliasing parpadeante en hojas en movimiento.


### Sombra planetaria del horizonte medida (F-8, 2026-11-10)

`fino/04 §Medidos` trae la tabla del original (Y −64..256 × sol 0°..45°). Nueva forma de `luz_sombra_horizonte`:
`max(piso, smoothstep(centro ± 50, Y))` con `centro = 560 / elevación − 55` bloques y `piso = 1 − exp(−0,0003·elev²)`
(`OPC_SOMBRA_HORIZONTE = (560, 55, 50, 0,0003)`). Contra la tabla: 0 exacto a 0°; a 2° Y = 256 da 0,90 (0,82); a 3°
Y = 128 da 0,45 (0,36); a 5° Y = 32/63/90 dan 0,16/0,59/0,92 (0,11/0,54/0,88); a 10° Y = 0/32 dan 0,49/0,91
(0,46/0,88); a 20° Y = −32 da 0,43 (0,46); a 45° Y = −64 da 0,46 (0,58). Frente a la estimación de C-08.1 (cota 220,
10 bloques/°, se apagaba del todo a 26°): el efecto dura más (a 10° el terreno a Y ≤ 0 sigue a medias) y a 5° la cota
de luz es 60, no 170. En `atardecer-oeste` (sol ≈ 12°) el suelo a Y ≈ 75 ya está iluminado por esta sombra; lo que
lo apaga en el original a esa hora es la sombra de los altoestratos (C-08.1), no esta.

## Sol rasante (F-40, 2026-11-12)

Observación del dueño 2.4: bandas en una cara iluminada con el sol bajo.

- **Por qué:** el PCF reúne muestras en un disco de 1 a 30 texels del mapa y las comparaba todas con la profundidad del
  centro. En una cara casi paralela a la luz, la superficie misma está más cerca de la luz en un lado del disco que en
  el centro: esas muestras la ven como ocluyente y la cara se sombrea a sí misma en rayas (acné de filtro). El
  desplazamiento por la normal, fijo en 0,35 texels, tampoco crecía con el ángulo, como pide `04` §Sesgo.
- **Arreglo:** sesgo de plano receptor por muestra: la profundidad de cada muestra baja `|desplazamiento|` (bloques) ×
  tangente del ángulo entre la normal y la luz (recortada a 10, unos 84°; `OPC_SOMBRA_PENDIENTE_MAX`). Y el
  desplazamiento por la normal pasa a `0,35 + 1,0 × seno` texels (`OPC_SOMBRA_SESGO_NORMAL`). De frente al sol no
  cambia nada; la sombra de contacto se conserva.
- **Comprobado** (`pruebas/escenas/sombra-rasante.ctl`, hora 12000, caras de arriba de hormigón con el sol bajo): con un
  filtro de paso alto, las rayas diagonales que tenían antes las caras desaparecen.
