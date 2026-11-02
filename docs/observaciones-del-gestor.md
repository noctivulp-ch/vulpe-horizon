# Observaciones del gestor

Lo que el gestor (sesión principal) pasa al implementador fuera del repo de la especificación: solo
observaciones de lo que se ve en el juego, capturas y mediciones, nunca código (ADR 0001). Una entrada por
entrega, con fecha.

## 2026-11-01 — tras el paso 1

- Convenciones, 01 (cielo y atmósfera) y 02 (cielo fractal) revisados por la muralla: se pueden empezar en
  su orden.
- Las capturas que cita la especificación están en `../vulpe-horizon-spec/referencias/`; mirarlas solo ahí,
  nunca en `mediciones/` aunque algún enlace siga apuntando allí (avisar al gestor si se ve uno).
- El paso 1 cumple el ADR 0002 (las etapas solo componen, el núcleo no lee `frame`).
- Decisión del dueño: licencia **GPL-3.0 o posterior** (`LICENSE` en la raíz; `license` en el manifiesto y
  `LICENSE` dentro del pack montado), autor `noctivulp-ch`.
- La identidad git del repo pasa a `noctivulp-ch`; el gestor reescribió los commits anteriores.

## 2026-11-01 — revisión del 01 y el 02

Faltas respecto a la especificación (el gestor cita dónde, no cómo):
- 01, líneas 33, 87 y 127: la lluvia sobre el cielo con la cámara por encima de la capa de nubes. Depende
  del 05: pendiente hasta tenerlo.
- 02, líneas 84–85 y 190: falta el filtro de banda del dibujo Suave (la duda está con A).
- 02, línea 234: el relleno «salpicadura», pendiente de que A lo describa.
- 02, líneas 95–97: la referencia usa otro hash; si el cambio es intencionado, dejar el motivo escrito en
  `docs/efectos/cielo-fractal.md` (la misma semilla no da el mismo cielo que en Vulpe).

Observación visual (`hoja-fractal.png` frente a `referencias/forge_cielo.png` y `hoja-auto.png`): las figuras
se ven **más brillantes y opacas** que en la referencia; la especificación las pide tenues, del orden de las
estrellas tenues (02, líneas 27–30 y 197–200). El resto del 01 y del 02 cumple; el comprobador de
contaminación da 0.

Respuestas: Horizon **no aplica jitter** a la proyección ni lo expone (A lo tendrá en cuenta en el 09). Las
dudas 1, 2, 3 y 5 pasan a A. El 03, el 04 y el 05 están revisados por la muralla.
