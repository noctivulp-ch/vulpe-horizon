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
