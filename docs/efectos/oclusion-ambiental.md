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
  mitad pasados 50 bloques). Por muestra: rechazo estricto si `s.w >= 1.0` (cielo: nunca ocluye ni genera halos)
  y corte cuadrático exacto `1 − |v|²/r²` hasta el radio límite (`fino/08 §2`). `AO = max(1 − fuerza · media · escala, 0)`.
- **La posición del punto se reconstruye igual que la de las muestras** (`luz_ao_posicion`, con
  `view_inverse · projection_inverse`), no con el ayudante `view_position`: con los dos métodos mezclados, una
  diferencia mínima entre ellos oscurecía un 26 % las caras planas (medido en la cueva de prueba).
- **Aplicación** (`adaptadores/oclusion.wgsl`): solo sobre la luz indirecta del terreno sólido, con la fracción del
  dato de `set_surface` (03): `color · (1 − indirecta · (1 − AO^4,0))`. Donde `surface_at().present` es falso,
  nada. Curva de respuesta a la cuarta potencia según `fino/08 §1` y `paridad/08`.
- Sin GTAO: «alta» son 20 muestras. Sin «apertura hacia arriba» (opcional).

## Opciones

Página «Sombras» y página «Calidad» (ver `docs/efectos/calidad.md`): la opción `ao` salió del menú para integrarse
en el preset `calidad_ao` (Baja: 0 muestras, vanilla; Media: 7 muestras, filtrada; Alta: 20 muestras, alta calidad;
Ultra: 20 muestras, trazado con rebote pendiente). La `ao_fuerza` se mantiene en el menú directo en «Sombras». Radio
y curva van como constantes (`opciones/oclusion.wgsl`).

## Coste

Plano de terreno de día: 8,23 ms con normal, alta o apagada: por debajo del ruido de medida.

## Visto y no visto

- **Visto:** con la AO sacada a pantalla, oscurecimiento en la base de las paredes de los bloques y alrededor de las
  matas; la fracción indirecta alta en las caras en sombra y baja al sol. Encendida frente a apagada (`hoja-ao.png`):
  más oscuro el rincón al pie del bloque de tierra y el suelo en sombra junto a las matas.
- **No del todo limpio:** las dos capturas de la comparación no tienen la misma exposición (se adapta entre una y
  otra) ni la misma posición de la hierba, que se mueve: parte de la diferencia no es AO.

## Paridad 08 (2026-11-04)

`paridad/08` mide, con la función del original sobre un rincón suelo–pared sintético, la AO **cruda**: ~0,77 en la arista,
que vuelve a 1 a unos 0,6, 1,5 y 2 bloques de la arista con la pared a 3, 8 y 20 bloques, y se aplica como **x⁴** a la luz
indirecta. La nuestra dejaba la arista en ~0,3–0,4 con radio fijo de 1,5 bloques y x^2,5.

**Herramienta:** `tools/paridad/ao_rincon.py` replica `luz_ao` en numpy sobre el mismo rincón (cámara a 1,62, campo de
70°, 1920×1080, columna central, 16 giros promediados como el TAA) e imprime nuestra AO junto a la del original. Con ella
se ajustó por rejilla (error cuadrático medio 0,029, máximo 0,063 sobre las 52 celdas de la tabla):

- **escala** de la suma 2,5 → 0,8 (`OPC_AO_ESCALA`);
- **radio** en el mundo que crece con la distancia: `clamp(0,19 · d, 0,3, 3)` bloques (`OPC_AO_RADIO_K`, `_MIN`, `_MAX`),
  como el del original, que es adaptativo; antes 1,5 fijo;
- **curva** x^2,5 → x⁴ (`OPC_AO_CURVA`).

**Visto** (`hoja-ao-rincon.png`, escena `ao-rincon`: pared de piedra sobre suelo liso a 16, 8, 4 y 2 bloques, por la
mañana; el suelo al sol solo cambia en su luz indirecta): en la columna central, la pared junto a la arista pasa de 50–66
a 70–77/255 y recupera el valor abierto a la misma altura que antes; el suelo, casi igual (está al sol). **Sin ver:**
rincones interiores sin sol directo y matas de hierba.
