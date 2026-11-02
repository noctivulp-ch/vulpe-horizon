# Vegetación ondulante (subsistema 15)

Especificación: `../vulpe-horizon-spec/subsistemas/15-vegetacion-ondulante.md`.

## Estado: escrito y validado, desactivado

`horizon-shader check` acepta la etapa `[vertex]`, pero **el juego instalado (nightly-2026-11-01-c9d474d, de las 17:07)
es anterior a ella** (entró a las 17:17, PR #5928; dato del gestor): no es un fallo de Horizon, es la versión. El juego
rechaza el pack entero con «TOML parse error … `[vertex]`». La sección está comentada en el manifiesto (con su porqué)
y las dos opciones van como `override` sin entrada de menú. **Sin ver en el juego.** No hay una versión más nueva
instalada (la otra es la del 29 de octubre); instalar otra la decide el dueño.

Para activarla: quitar los `#` de `[vertex]` en el manifiesto y volver a declarar las opciones:

```toml
[[options]]
id = "ondulacion"
name = "Vegetación ondulante"
type = "bool"
default = true

[[options]]
id = "ondulacion_fuerza"
name = "Fuerza del viento"
type = "float"
default = 1.0
min = 0.0
max = 2.0
step = 0.05
```
y añadirlas a la página «Luz».

## Por qué del código

- `nucleo/superficie/viento.wgsl`: suma de senos con fase espacial (Sousa, GPU Gems 3 cap. 16). Plantas: periodos
  distintos en x (~4,5 s) y z (~6 s), fase anclada al mundo, sesgo en la dirección del viento, amplitud que respira
  con una onda lenta (×0,5–1,2), amplitud base 0,07 bloques, y la y baja lo que se inclina. Hojas: 3D, amplitud
  vertical 1/5, base 0,035.
- `adaptadores/vertice.wgsl`: familias por id de `[[materials]]`: plantas de suelo (ids 2 y 4) solo con la parte de
  arriba del sprite (`uv.y` < 0,5); **mitad superior de las plantas de dos bloques** (id 8, nuevo, con el SSS fuerte y
  como planta cruzada) entera; hojas (id 1) en 3D. La fase de las plantas se toma en la esquina entera del bloque
  (`floor`), así la base de la mitad superior y la punta de la inferior, que coinciden, se mueven igual.
  × fuerza × (1 + lluvia) × luz de cielo del vértice (mínimo 0,5 en plantas). Nada en fluidos.
- **Simplificación:** las enredaderas y lianas están en la familia de las plantas de suelo (id 4, por el SSS medio):
  solo se mueve su mitad de arriba en vez de balancearse enteras. Sin ráfagas (constante apagada en la especificación).

## Montaje del pack

Para poder dejar archivos `.wgsl` sin usar en el repo (el comprobador rechaza un `.wgsl` que ninguna etapa usa),
`tools/montar.sh` enlaza **por archivo** solo lo que nombra el manifiesto (ADR 0003, actualizado).
