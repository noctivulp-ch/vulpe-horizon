# Cámara y efectos de juego (subsistema 19)

Especificación: `vulpe-horizon-spec/subsistemas/19-camara-y-efectos-de-juego.md`. Código: `nucleo/imagen/gotas.wgsl`
(puro, sin lecturas de textura), `adp_gotas_camara`, `adp_calor` y la codificación del cruce en `adaptadores/imagen.wgsl`,
el estado en `adaptadores/bloom_estado.wgsl`; constantes en `opciones/gotas.wgsl`; el orden en `etapas/post/07-final.wgsl`.

## Agua en la cámara (sustituye a las gotas de B-15)

- **Memoria**: el téxel (4,0) de `bloom2` guarda en un solo valor el tiempo desde el cruce, si fue salida o entrada y la
  rapidez: `±(1 + 8·nivel + t)`, positivo al salir, 0 sin cruce, con t < 8 s y la rapidez en 8 niveles de 2 bloques/s.
  El (5,0) guarda si la cámara estaba en el agua (`eye_in == 1`) el fotograma anterior: el cruce es el cambio de ese
  valor. La rapidez es `|camera_motion| / delta_time` en ese fotograma. Un solo téxel porque la pasada final iba por
  63 lecturas.
- **Dirección**: la especificación pide la velocidad del cruce proyectada en pantalla y congelada. No cabe en el
  téxel con precisión de 16 bits; se usa el sentido vertical (al salir el agua escurre hacia abajo, al entrar sube).
- **Salida**: dos octavas de ruido de valor a baja frecuencia, estiradas en esa dirección, que escurren; el umbral
  sube de 0,25 a 0,85 en los 5 s y solo quedan las gotas gruesas. Cada punto se acerca al centro una fracción
  `fuerza · gota · rapidez · vida`, con tope 0,5 (la gota más gruesa con el ajuste 50). Un leve oscurecido en el
  borde de las gotas.
- **Entrada**: una onda que se abre desde el centro a 0,5 de pantalla por segundo, de amplitud 0,06 · fuerza.
- **Duración**: 5 s; después nada.

## Calor

`frame.in_lava` (ya suavizado por Horizon con media vida de 0,25 s) o, con el mod, `mods[3].z` («en llamas»). Ruido
que sube a 0,3 de la altura por segundo, cuadrático hacia abajo y nulo en el tercio superior, más un acercamiento al
centro del 2 %. Fuerza 0,7 (el ajuste 70).
- Diferencia: la especificación pide que se apague en unos 3 s; con `in_lava` se apaga en ~1 s. Hacerlo bien pide
  otro téxel de estado (cabe ahora: la final quedó en 60 lecturas). Pendiente si el gestor lo ve necesario.

## Lecturas de la pasada final

El validador cuenta las lecturas de todo el módulo, no solo las alcanzables desde `post`. Las funciones de las pasadas
de bloom (bajada y ancho, con su estado) se movieron a `adaptadores/bloom_estado.wgsl`, que la final no incluye, y el
alfa de la niebla se toma de la muestra central de la nitidez en lugar de leerlo aparte. La final pasó de 63 a 60.

## Comprobado en Horizon (2026-11-12)

Escena `pruebas/escenas/camara-juego.ctl`: al salir del agua (con `tp`, rapidez máxima) las gotas deforman media
pantalla a 0,3 s, quedan pocas a 1,5 s y ninguna a 3,5 s; la onda de entrada es suave; en lava la imagen ondula
abajo y queda quieta arriba.
