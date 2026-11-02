# 0004 — El «picture» del mundo guarda la escena codificada con el mapeo de tonos

**Fecha:** 2026-11-01 · **Estado:** aceptada · Responde a la duda abierta de
`../vulpe-horizon-spec/convenciones.md` §«Escala de luz».

## Lo medido (2026-11-01, Horizon nightly-2026-11-01-c9d474d)

Pack de ensayo desechable: el `sky` escribía valores conocidos y una pasada post los leía de
`scene_color` y los amplificaba.

| Prueba | Resultado | Conclusión |
|---|---|---|
| `sky` escribe 2,0; post lee ÷4 | 64/255 (0,25) | el mundo recorta en 1 |
| `sky` escribe −1; post lee +0,5 | 127/255 | recorta en 0 |
| `sky` escribe 0,004; post lee ×100 | 100/255 (0,39 = 1/255·100) | cuantiza a 1/255 |
| `sky` escribe 0,0005 y 0,002; post ×1000, ×250 | 0 y 0 | **8 bits lineal**, sin curva sRGB que dé precisión en los oscuros |
| pasada A escribe v·4, v·0,01, v·1000; pasada B deshace | exacto en los tres | los destinos **entre pasadas post son de coma flotante con signo** |
| la última pasada escribe v | se ve v·255 recortado | la ventana no añade curva: lo que sale es el valor mostrado |

Además, lo que Horizon dibuja por su cuenta en ese mismo «picture» (entidades, partículas, la luna, la
mano no: va después) llega **en espacio de pantalla**, como en vanilla.

## Decisión

El `sky` y el `material` no escriben luz lineal sino **el valor que se mostraría**:

```
codificar(L) = sRGB( T( L · E ) )        decodificar(v) = T⁻¹( lineal(v) ) / E
```

- `L`: luz lineal de la escena en la escala común (una superficie blanca de Lambert al sol de mediodía
  ≈ 1; ver `docs/efectos/cielo-y-atmosfera.md` §Escala).
- `E`: **exposición previa**, función analítica de `frame` (altura del sol y de la luna) idéntica en todas
  las etapas (`adp_exposicion_previa`, en `shared`).
- `T`: Reinhard extendido **sobre el canal máximo** con punto blanco `W` (Reinhard et al. 2002, ec. 4): se
  calcula la curva sobre `max(r, g, b)` y los tres canales se escalan por el mismo factor. Invertible en
  forma cerrada (el canal máximo de la salida es la curva del de la entrada). Es también el mapeo de tonos
  final por defecto.

La composición decodifica a luz lineal en coma flotante; todo el post trabaja ahí; la última aplica la exposición
(desde el 11, automática mezclada con `E`), la gradación y el mapeo de tonos elegido.

## Por qué así

1. **Lo que dibuja Horizon por su cuenta sale intacto.** Entidades, partículas y la luna están en
   espacio de pantalla. Con esta codificación, decodificar y volver a codificar con la misma `E` y la misma
   `T` es la identidad: se ven exactamente como Horizon las dibujó. Con cualquier otra codificación
   reversible (`c/(1+c)`, logarítmica) quedarían con otro brillo y contraste.
2. **La precisión de 8 bits cae donde se mira:** la escena ya va expuesta, así que los oscuros de la noche
   (×30 de exposición) no se quedan en 0–2 niveles. Es la precisión de una imagen normal de 8 bits.
3. **Lo brillante no se pierde del todo:** `T` comprime hasta `W/E` de luz (con W = 32 y E ≈ 1,5 de día,
   unas 20 veces el blanco), lo que deja algo para el bloom.
4. Mientras la etapa `material` sea la de vanilla (hasta el subsistema 03) su salida pasa tal cual: ya es
   un valor de pantalla y la ida y vuelta la deja igual.

**Por qué el canal máximo y no por canal (cambio del 2026-11-01, al encender la luz de superficie):** con
Reinhard por canal la hierba al sol salía gris verdosa y las hojas pálidas: cada canal se comprime por su
cuenta y lo brillante pierde saturación (el cielo necesitaba un refuerzo de saturación ×1,5 para
disimularlo). Sobre el canal máximo se conservan tono y saturación y ningún canal pasa de 1; el refuerzo del
cielo ya no hace falta. Queda como opción «Reinhard (por canal)».

## Consecuencias

- El tramado se aplica al codificar (en `sky` con un hash de la dirección, que no tiene píxel).
- La niebla de Horizon mezclaría en espacio de pantalla sobre la escena codificada: aceptable mientras la
  escena sea la de vanilla; con el subsistema 05 se pondrá `[material] fog = false` y la niebla será propia.
- Las opciones de mapeo de tonos distintas de `T` cambian también el aspecto de entidades y luna (como
  cambiaría cualquier mapeo).
- Si un día Horizon da un «picture» de coma flotante, basta con hacer `T` la identidad en la codificación.
