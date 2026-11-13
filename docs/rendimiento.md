# Rendimiento

Medidas y decisiones de coste del pack. Lo que el gestor tiene que mirar está también en
`docs/observaciones-del-gestor.md`.

## Cómo se mide

- `pruebas/escenas/rendimiento.ctl` abre el mundo; `tools/rendimiento/bench3.sh ETIQUETA` mide 10 s
  (`horizon-ctl bench 10`) en tres vistas fijas: Overworld (170,5, 90, 166,5), Nether (yermo, (0,5, 100, 0,5)) y End
  (hacia el vórtice desde (0,5, 90, 120,5)).
- La ventana de Horizon tiene que tener el foco (`niri msg action focus-window --id`). **Sin foco, Horizon se limita a
  10 fps (a veces a 30), la GPU baja de frecuencia y los milisegundos de GPU salen inflados (20–30 ms en vez de
  9–17).** Una medida a 10 fps no vale.
- Ablación: `OPC_DEPURACION_QUITAR` (`opciones/depuracion.wgsl`), un bit por pieza: 1 volumen, 2 oclusión, 4 luz de
  menas, 8 reflejos de pantalla, 16 bloom, 32 TAA, 64 mapa de la aurora, 128 sombras del sol, 256 cielo.
  `tools/rendimiento/ablacion.sh` recorre los bits. 0 en uso normal (no cuesta nada: son constantes).
- Ajustes: los del dueño (`gpuCulling`, recorte de hojas, entidades y partículas, `lodDistance:32`, FOV 1,0;
  distancia 8, como la suya), copiados a `vulpe-pruebas` solo para medir y restaurados después.

## 2026-11-13 (B-23 lote 2)

Datos crudos: `docs/rendimiento-ablacion-2026-11-13-a.txt` y `-b.txt`.

**Con foco** (primera serie, hasta el bit 4; GPU por fotograma, Horizon a 30 fps de tope):

| | Overworld | Nether | End |
|---|---|---|---|
| base | 17,3 ms | 10,5 ms | 8,5 ms |
| sin volumen (1) | −1,6 | −0,2 | −1,9 |
| sin oclusión (2) | −0,5 | −0,2 | −0,25 |
| sin luz de menas (4) | −0,5 | −0,3 | **−1,2** |

Una primera medida suelta en el Overworld dio 33,6 fps de media y 20,3 ms de GPU (el dueño ve ~30).

**Sin foco** (segunda serie y el resto de la primera: todo a 10 fps, GPU a ~1100 de 2100 MHz). Solo vale la
diferencia grande de quitarlo todo (511): Overworld 32,2 → 24,7 ms; Nether 25,4 → 17,9; End 19,6 → 11,9. Las piezas
de post quitables pesan juntas ~7,5 ms en las tres dimensiones a esa frecuencia (~4 a frecuencia normal); el resto
es el terreno (`material`), el cielo y lo fijo. Las sombras del sol se notan en el Overworld (−3,2 ms a 10 fps).

**Arreglo aplicado (sin pérdida visible):** la luz de las menas no corre en el End, donde no hay menas (−1,2 de 8,5
ms con foco).

**Lo que no cuadra con el dueño:** él ve ~17 fps en el Nether, y yo mido 10,5 ms de GPU allí (~95 fps posibles) y
4 ms de CPU. O su escena del Nether es otra (más humo en pantalla, otro bioma, lava cerca), o lo midió con el pack
anterior a F-57/F-63, o el cuello no es la GPU. Hace falta su sitio y su versión del pack para reproducirlo.

**Bloqueado:** desde mitad de la sesión Horizon no recibe el foco aunque niri se lo da (`is_focused: true`, y
Horizon sigue a 10 fps, incluso a 3,7). Sin eso no se puede atribuir el coste pieza a pieza ni comprobar arreglos
más finos. Candidatos para cuando se pueda medir, por orden:
1. Volumen en el Overworld y en el End (1,6–1,9 ms): `vol_ruido3d` hace 8 `textureLoad` por muestra (trilineal a
   mano); una textura 3D de verdad o 2 lecturas con filtrado lineal entre cortes lo bajaría.
2. Sombras del sol en el Overworld: PCF de receptor plano (F-40); probar menos muestras lejos de la cámara.
3. Luz de las menas: 12 lecturas por píxel de terreno en todo el Overworld; saltarla donde no hay ninguna mena en un
   mosaico de pantalla (una pasada barata que marque los mosaicos con mena).
