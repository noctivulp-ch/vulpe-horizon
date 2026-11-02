# Sombras (subsistema 04)

Especificación: `../vulpe-horizon-spec/subsistemas/04-sombras.md`. Capturas: `pruebas/capturas/sombras-*.png`
(escena `pruebas/escenas/sombras.ctl`).

## Qué hay y qué falta

Mapa de Horizon pedido con `[shadow]` (2048 texels, 128 bloques de semilado). PCSS completo (búsqueda de
ocluyentes, penumbra por distancia, PCF con disco de Vogel girado por píxel y fotograma), PCF fijo como
opción «básica», sesgo por la normal, corrección de fugas en interiores, sombras de color de agua y cristal,
y fundido a la sombra aproximada por la luz de cielo al borde del mapa. La sombra da también el **grosor**
hasta el ocluyente, que usa el SSS del 03.

**Sombras de nubes** (§5): con el 05, el material multiplica la luz del sol por `vol_sombra_nubes` (la
cobertura donde el rayo hacia la luz cruza la mitad de cada capa baja, `e^(−3·c²)`), escalada por la opción.
**Pendiente:** el tinte del agua es un color fijo hasta el 07 (absorción y profundidad del agua).

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
   tercera fila de `shadow_view_proj`: la proyección es ortográfica) × tan(1,5°), el sol aparente algo
   mayor que el real. Acotada entre la mínima y la máxima de las opciones.
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

## Opciones

Página «Sombras»: penumbra básica/variable, penumbra mínima (0–10) y máxima (0–40 texels), muestras del
filtro (4–16), sombras de color. La resolución y la distancia del mapa son del manifiesto y el jugador no
puede cambiarlas (limitación de Horizon que recoge la especificación).

## Coste medido

Plano de terreno a mediodía con árboles (1830×1040, RTX 3050 Ti portátil, sin límite de FPS): material de
vanilla sin mapa 2,35 ms de GPU; con mapa (lo dibuja el motor) 3,66; con el material del 03 y el PCSS **6,0**
(búsqueda de 12 lecturas: 6,6; PCF básico: 5,6). Sin la sombra, el resto del material del 03 cuesta ~0,9 ms
sobre vanilla. naga: material 3736 expresiones, 7 lecturas de textura (por sitio en el código).

Probado sin efecto: salir antes en los téxeles que el test de alfa descarta (Horizon ya no los ilumina).
