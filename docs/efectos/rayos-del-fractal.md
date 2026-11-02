# Rayos del fractal (subsistema 14, PROPIO)

Especificación: `../vulpe-horizon-spec/subsistemas/14-rayos-del-fractal.md`. Capturas: `pruebas/capturas/rayos-*.png` y
`hoja-rayos.png` (apagados, de frente, de espaldas; de noche, semilla 8). **Apagado por defecto**, como en Vulpe.

## Por qué del código

- `nucleo/imagen/rayos.wgsl`: el desenfoque radial de Mitchell (GPU Gems 3 cap. 13) con las correcciones de Vulpe:
  recorrido medido en pantalla y acotado, arranque desplazado por ruido azul, caída por distancia normalizada por la
  serie geométrica (no por muestra), sin cortar al salir de la pantalla (sigue el borde y se desvanece), oclusión de
  nubes (lo oscuro tapa lo que viene detrás), núcleo con codo y concentración. Suma, no media.
- `adaptadores/rayos.wgsl`: centro de la instancia 0 (el eje de su matriz de colocación, del sorteo compartido del 02);
  con el centro detrás de la cámara, el polo es la antípoda y se camina alejándose; cerca de 90° el polo se empuja
  hacia delante y se desvanece. Fase de la niebla del 05 (`vol_fase_niebla`) normalizada a su valor de frente más
  un lóbulo trasero. Las muestras de `previous` pasan por la exposición y `c/(1 + c)`.
- En la pasada final, **tras el tonemap y antes del aislamiento de color** (13), como pide la especificación.
- **Recalibrado (la especificación lo pide):** en nuestra escala el rayo acumulado ronda 0,05 (en Vulpe, ~1), y la
  concentración (una potencia de exponente 1 + 3·foco) lo dejaba invisible. La potencia se aplica al rayo
  normalizado por el nivel del núcleo, y el núcleo se toma en milésimas (0,1 de frente, 0,04 de espaldas) en vez de
  centésimas.

## Opciones

Rayos sí/no (apagado) e intensidad (200), en la página «Cielo fractal». El resto, constantes con los valores de
Vulpe (`opciones/rayos.wgsl`). Van 48.

## Visto y no visto

- **Visto:** de frente, haces que convergen hacia el centro de la figura, concentrados en sus zonas brillantes; con el
  efecto apagado, nada.
- **De espaldas** (polo en la antípoda, mirando al norte con la semilla 8): no se distingue nada (diferencia media
  2,4/255 con el efecto apagado, casi todo ruido). Alrededor de la antípoda no hay nada brillante que desenfocar:
  la niebla nocturna es oscura y la única zona clara es el halo de la luna, lejos del polo. No sé si es lo esperado
  con la niebla de noche o si el umbral de espaldas (0,04 mapeado) es alto en nuestra escala: duda para A.
- **No visto:** el corte por nubes.
