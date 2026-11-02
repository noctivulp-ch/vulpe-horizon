# Oclusión ambiental (subsistema 08)

Especificación: `../vulpe-horizon-spec/subsistemas/08-oclusion-ambiental.md`. Capturas: `pruebas/capturas/ao-*.png` y
`hoja-ao.png` (izquierda apagada, derecha normal; escena `pruebas/escenas/ao.ctl`).

## Dónde va (desviación)

La especificación la pone en una pasada propia a media resolución con destino `oclusion`. **Horizon admite 4
destinos propios por pack** (`horizon-shader check`: «a pack may write 4») y ya están el mapa de la aurora, el
volumen y los dos de bloom. Va **dentro de la pasada de composición, a resolución completa**: 7 lecturas de
profundidad por píxel (20 en «alta») son baratas y así no hace falta el reescalado bilateral. El TAA limpia el
ruido.

## Por qué del código

- `nucleo/luz/oclusion.wgsl`: disco de Vogel en pantalla girado por ruido azul (canal 3) por píxel y fotograma,
  con radio de 1,5 bloques proyectado al plano del punto (acotado entre 2 píxeles y el 8 % de la pantalla, la
  mitad pasados 50 bloques). Por muestra: `max(0, cos(v, N) − 0,15) · max(0, 1 − |v|²/(4r²))`; el sesgo evita que
  una cara plana se ocluya y el corte por distancia quita los halos. `AO = max(1 − fuerza · media · 2,5, 0)`.
- **La posición del punto se reconstruye igual que la de las muestras** (`luz_ao_posicion`, con
  `view_inverse · projection_inverse`), no con el ayudante `view_position`: con los dos métodos mezclados, una
  diferencia mínima entre ellos oscurecía un 26 % las caras planas (medido en la cueva de prueba).
- **Aplicación** (`adaptadores/oclusion.wgsl`): solo sobre la luz indirecta del terreno sólido, con la fracción del
  dato de `set_surface` (03): `color · (1 − indirecta · (1 − AO^2,5))`. Donde `surface_at().present` es falso,
  nada.
- Sin GTAO: «alta» son 20 muestras. Sin «apertura hacia arriba» (opcional).

## Opciones

Oclusión (apagada, normal, alta) y fuerza (imprescindibles), en la página «Sombras». Radio y curva, constantes
(`opciones/oclusion.wgsl`). Van 41 opciones.

## Coste

Plano de terreno de día: 8,23 ms con normal, alta o apagada: por debajo del ruido de medida.

## Visto y no visto

- **Visto:** con la AO sacada a pantalla, oscurecimiento en la base de las paredes de los bloques y alrededor de las
  matas; la fracción indirecta alta en las caras en sombra y baja al sol. Encendida frente a apagada (`hoja-ao.png`):
  más oscuro el rincón al pie del bloque de tierra y el suelo en sombra junto a las matas.
- **No del todo limpio:** las dos capturas de la comparación no tienen la misma exposición (se adapta entre una y
  otra) ni la misma posición de la hierba, que se mueve: parte de la diferencia no es AO.
