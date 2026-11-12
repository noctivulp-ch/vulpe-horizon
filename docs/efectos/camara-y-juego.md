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

## Ajustes de cámara (apagados por defecto)

Constantes en `opciones/imagen.wgsl` (`OPC_CAM_*`), funciones puras en `nucleo/imagen/camara.wgsl`, aplicación en
`adp_desenfoque_movimiento` y `adp_camara_final` (`adaptadores/imagen.wgsl`). Cada uno va tras un `if` sobre su
constante: en 0 el compilador lo quita.

- **Zoom** (`OPC_CAM_ZOOM`, 0..1 → ×1..×4): lo primero, antes del agua y el calor.
- **Desenfoque de movimiento**: la opción del menú `desenfoque_movimiento` ya existía y no hacía nada. Reproyección del
  píxel con la profundidad (`view_position`) y `previous_view_projection` + `camera_motion` (el cielo, a 10 000
  bloques); desplazamiento normalizado a un fotograma de 60 Hz y comprimido `v/(1+4|v|)`; tres muestras más con
  tramado de ruido azul (la cuarta es la central de la nitidez). La mano (más cerca de 0,6 bloques) no se desenfoca.
  Solo mueve la cámara: las entidades que se mueven solas no (Horizon no da vectores de movimiento).
- **Viñeta** (`OPC_CAM_VINETA`): `1 − f·smoothstep(0,5; 1; r)²`, con r 1 en las esquinas; el tramado final evita bandas.
- **Grano** (`OPC_CAM_GRANO`): ruido blanco por canal (hash por píxel y fotograma, ciclo de 60), × brillo, tras el
  tonemap.
- **Bandas de cine** (`OPC_CAM_BANDAS_ALTO` / `_ANCHO`): fracción de pantalla.
- **Líneas de encuadre** (`OPC_CAM_TERCIOS`): regla de tercios de un píxel.
- **No hechos**: la **aberración cromática** (dos lecturas más; cabe, pero se dejó para no cargar la final sin
  pedirlo) y la **profundidad de campo** (la última de la lista; necesita su propia pasada: hay 7 de 8). El modo de
  captura de la profundidad de campo queda fuera (Horizon no tiene jitter).

Comprobado en Horizon (2026-11-12) con todo encendido a mano (`pruebas/escenas/camara-ajustes.ctl`): bandas, viñeta,
grano y zoom visibles; con la cámara quieta el desenfoque no cambia nada. Devueltos a 0 antes del commit.
