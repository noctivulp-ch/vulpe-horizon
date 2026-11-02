# Agua (subsistema 07)

Especificación: `../vulpe-horizon-spec/subsistemas/07-agua.md`. Capturas: `pruebas/capturas/agua-*.png` y `hoja-agua.png`
(escena `pruebas/escenas/agua.ctl`, en la playa de (150, 225) y bajo el agua en (125, 58, 245)).

## Qué hay

- **Superficie** (`agua()` en `etapas/material.wgsl`, pase translúcido con `fluid == 1`): olas, refracción con
  profundidad real, absorción y dispersión, absorción mínima en cuevas, reflejo (espejo de Horizon con su cielo
  vanilla sustituido por el del pack) con Fresnel, especular del sol con sombra; desde abajo, la ventana de Snell.
  Sale con alfa 1: lo de detrás ya va dentro (Horizon mezcla con alfa estándar, dato del gestor).
- **Fondo bajo el agua** (`adaptadores/sombras.wgsl`): donde el mapa translúcido marca agua (alfa 1 de
  `shadow_color`), la luz directa se absorbe por los bloques de agua hacia el sol (diferencia de profundidades de
  los dos mapas) y lleva cáusticas, fundidas en el primer bloque. Sustituye al tinte fijo del 04.
- **Cámara bajo el agua** (`nucleo/volumen/agua.wgsl`, en la pasada del volumen): raymarch de 8 pasos hasta 96
  bloques con absorción, dispersión y la luz del sol absorbida desde la superficie con la sombra del mapa.
- `[reflection]` en el manifiesto sin opción: el espejo se dibuja siempre que el material lo lee.

## Por qué del código

- **Olas** (`nucleo/agua/olas.wgsl`): 3 octavas del canal G de `ruido2d` con escalas anisótropas (220×90, 70×160,
  60×60 bloques), giradas 137,5° entre sí y desplazadas con el tiempo; oleaje en parches con el canal R a 1800
  bloques curvado en S. Normal por diferencias finitas con paso que crece con la distancia y 2 octavas pasados 48
  bloques. En caras verticales (cascadas), la normal geométrica. Fuerza × (1 + 0,8·lluvia).
- **Refracción falsa** (Sousa 2005): desplazamiento en pantalla por la normal tangente × opción × 0,0006,
  decreciente con la distancia y en el 10 % del borde; si lo desplazado está delante del agua (profundidad
  invertida mayor que la de la superficie), sin desplazar. Profundidad a lo largo de la vista con `opaque_depth`
  reconstruida con `view_inverse · projection_inverse`. `opaque_color` y el espejo se **decodifican** (ADR 0004):
  son terreno dibujado por nuestro material.
- **Absorción** (`nucleo/agua/optica.wgsl`): σ_a = (0,55; 0,13; 0,085) por bloque / claridad, la del agua pura
  (Pope y Fry 1997) reforzada en verde y azul para que a 1 bloque sea casi incolora, a 3–5 verde azulada y a 10
  azul oscura. Dispersión 0,035 gris con color (0,08; 0,45; 0,55) × ambiente. Absorción mínima de 4 bloques sin
  luz de cielo.
- **Reflejo:** Fresnel de Schlick F0 = 0,02. El alfa del espejo no distingue el cielo (dato del gestor): se detecta
  por el **parecido de color** con el degradado vanilla esperado (`frame.sky_color` arriba, `frame.fog_color` al
  horizonte) y la **elevación** reflejada, con la elevación sola si todo es oscuro (noche); ahí se pone el cielo del
  pack (horizonte → cielo medio de la tabla). Alfa < 0,75 (bloque emisivo): ×3. Sin espejo o fuera de su plano,
  solo el cielo del pack. El reflejo se apaga bajo techo con la curva de la luz de cielo.
- **Especular del sol:** GGX con rugosidad 0,02 sobre la normal de las olas (el reguero del atardecer).
- **Desde abajo:** Fresnel desde dentro con el ángulo crítico de n = 1,333; fuera, reflexión total hacia un color
  de agua profunda.
- **Niebla bajo el agua:** absorción × 0,45 a lo largo de la vista (con la de la superficie se cerraba en pocos
  bloques: un muro azul), dispersión con la luz del sol × 0,5 y ambiente teñido. La transmitancia que se guarda es
  la luminancia (el volumen tiene un solo canal de transmitancia): el tinte de lo que se ve a través sale de la luz
  dispersada, no de una transmitancia por canal (simplificación).
- Las funciones del agua van solo en material, volumen y composición, no en `shared`: las lecturas de textura
  cuentan por etapa aunque la función no se use, y la final ya va por 49.

## Opciones

Fuerza de las olas, claridad y refracción (imprescindibles), página «Agua». Velocidad, cáusticas, brillo mínimo
bajo el agua y textura vanilla (apagada), constantes en `opciones/agua.wgsl`. Van 39 opciones.

## Coste

Playa mirando al mar (1830×1040, RTX 3050 Ti portátil): 8,3 ms de GPU con todo (incluye el espejo de Horizon,
que el motor dibuja a media resolución).

## Visto y no visto

- **Visto:** orilla casi incolora con cáusticas que pasa a azul al ganar profundidad; la orilla reflejada; la sombra
  de una nube en el fondo; al atardecer, el reguero del sol; de noche, agua oscura y azul; bajo el agua, el fondo y
  las algas a una decena de bloques en niebla verde azulada.
- **No visto:** la ventana de Snell desde abajo (mirando arriba solo se distingue el resplandor), los rayos de luz
  bajo el agua, la lluvia sobre el agua, el agua en cuevas, la detección del cielo en el espejo de noche.

## Dato del motor

`horizon-ctl tp` mueve al jugador solo en el cliente y el servidor lo devuelve a los pocos segundos: las escenas
usan `command tp @s X Y Z` (anotado en `tools/probar.sh`).
