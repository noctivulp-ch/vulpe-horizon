# TAA (subsistema 09)

Especificación: `../vulpe-horizon-spec/subsistemas/09-taa.md`. Capturas: `pruebas/capturas/taa-*.png` y
`hoja-taa.png` (escena `pruebas/escenas/taa.ctl`).

## Qué hay

Pasada 4, **penúltima** (`etapas/post/04-taa.wgsl`): `history` es su propia salida del fotograma anterior. Las
pasadas: 01 mapa de la aurora, 02 volumen, 03 composición, 04 TAA, 05 final. Más el ruido azul para todo el
pack y el jitter propio del fractal en el cielo.

## Por qué del código

- **Reproyección** (`adaptadores/taa.wgsl`): profundidad más cercana en cruz (Karis 2014), posición con
  `view_position` y uv anterior con `previous_view_projection · (p + camera_motion)`; el cielo, solo con la
  dirección (w = 0, sin traslación).
- **Historial:** Catmull-Rom en 5 lecturas bilineales (Jimenez 2016), mezclado con el bilineal por la opción de
  nitidez (0,5).
- **Recorte por varianza** (Salvi 2016) en YCoCg del espacio comprimido, caja μ ± γσ con γ = 1,1 quieto y 0,75
  moviéndose; recorte hacia el centro (conserva el tono), no pinzado por canal.
- **Mezcla** en espacio comprimido `c/(1 + luma)` (Karis 2014): α = 1/8 quieto, hasta 1/3 con movimiento.
- **Historial no válido** (fuera de pantalla, `delta_time` = 0, `history` negro): el fotograma actual.
- **FXAA** (Lottes 2009, versión de consola, simplificada) sobre la imagen **antes** de acumular: donde la
  luminancia tiene contraste, dos lecturas a lo largo del borde. Horizon no desplaza la cámara: sin esto el TAA
  no suaviza los bordes geométricos.
- Sin rechazo por profundidad (opcional en la especificación).

### Ruido azul

`tools/ruido/generar_ruido_azul.py` escribe `texturas/ruido_azul.png` (64², cuatro canales independientes) por
el método de vacío y cúmulo (Ulichney 1993) con núcleo gaussiano σ = 1,5 en un toro. `adp_ruido_azul(píxel,
canal)` lo lee y lo desplaza por fotograma con R2 (Roberts 2018). Lo usan el primer paso del volumen (canal 0),
el giro del disco de las sombras (1) y el VNDF y el trazado de los reflejos (2, 3, 0). Sustituye al ruido blanco
PCG y al IGN.

### Jitter del cielo

`adp_cielo_jitter` (02 §5 bis): la dirección de vista del fractal se desplaza `(R2 − ½)` píxeles en los ejes de
la vista (`view_inverse`), con el tamaño del píxel de `projection[1][1]` y la resolución. Solo el fractal.

## Opciones

TAA sí/no y nitidez (imprescindibles del presupuesto), en la página «Imagen». Mezclas, γ y FXAA, constantes
(`opciones/taa.wgsl`). Van 35 opciones.

## Coste

25 lecturas de textura en la pasada (por sitio en el código). Plano de terreno de día: 6,92 ms de GPU con todo,
frente a ~7,1 antes del cambio (ruido de medida: la pasada es barata).

## Visto y no visto

- **Visto:** nubes limpias con la cámara quieta frente al grano sin TAA (mismo encuadre, encendido y apagado);
  girando la cámara a ~60°/s no aparecen estelas ni doble imagen y la vista sigue nítida; de noche, la aurora
  muestra las vetas verticales que el grano tapaba.
- **No visto:** el centelleo de los filamentos del fractal con la cámara en movimiento (quieto no centellea);
  entidades en movimiento (sin vectores de movimiento, pueden dejar estela leve: no probado).

## Paridad 09 (2026-11-04)

Contra `paridad/09` (el TAA del original ejecutado fotograma a fotograma):

- **Mezcla en movimiento** 0,33 → **0,125** (`OPC_TAA_MEZCLA_MOVIMIENTO`): con sus valores por defecto el original no
  cambia la mezcla al moverse.
- **Caja de recorte** 1,1 → **1,25 σ** del vecindario 3×3 (`OPC_TAA_GAMMA`), y ya no se estrecha a 0,75 con el
  movimiento (`OPC_TAA_GAMMA_MOVIMIENTO` = 1,25): el original usa siempre 1,25 (su ajuste del menú no tiene efecto).
- **Remuestreo del historial:** Catmull-Rom con nitidez 0,75 en el original; la opción «Nitidez del TAA» pasa de 0,5 a
  0,75 por defecto.
- **Compresión por luminancia** (`c / (1 + L)` antes de mezclar, deshecha después): ya era la del original.
- **FXAA: añadido de Vulpe para Horizon**, el original no tiene antialiasing espacial (`OPC_TAA_FXAA`). Se queda.
- **Sin hacer:** la vuelta a la media del vecindario proporcional a cuánto movió el recorte el historial (anti-estelas
  del original); la tabla no da su constante.

**Visto** (`hoja-taa-movimiento.png`, escena `taa-movimiento`): varianza de la laplaciana (más = más nítido) quieta
902 → 788 al llegar y 721 → 731 asentada; tras cinco giros de 3° seguidos, 642 → 493: con menos peso del fotograma nuevo
el movimiento emborrona más, como en el original. `horizon-ctl` no captura a mitad de un giro continuo: lo de «girando»
es justo después de los giros. **Sin ver:** estelas en movimiento real con el ratón.
