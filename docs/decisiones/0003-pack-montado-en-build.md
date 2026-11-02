# 0003 — El pack se monta en `build/vulpe/` con enlaces simbólicos

**Fecha:** 2026-11-01 · **Estado:** aceptada

## Contexto

`horizon-shader check` rechaza una carpeta de pack que tenga algo más que `horizon-shaders.toml`, los
`.wgsl`, sus `[[textures]]`, `README.md`, `LICENSE*` e `icon.png` («a pack holds only…»). El ADR 0002 pone
el manifiesto y las carpetas de WGSL en la raíz del repo, junto a `docs/`, `tools/` y `pruebas/`.

## Decisión

La raíz del repo sigue siendo la fuente (estructura del ADR 0002 intacta). `tools/montar.sh` crea
`build/vulpe/` con **enlaces simbólicos** al manifiesto, el README, `LICENSE` y las carpetas `nucleo/`,
`adaptadores/`, `opciones/`, `etapas/` y `texturas/`. Esa es la carpeta que se valida y la que se pasa al juego en
`HORIZON_SHADER_PACK`. `build/` no va a git.

## Alternativas descartadas

- **Copiar los archivos** a `build/`: rompe la recarga en caliente (el juego mira la copia, no lo que se
  edita) y obliga a un vigilante que vuelva a copiar.
- **Mover el pack a una subcarpeta** (`pack/`) con `docs/` y `tools/` fuera: cambia la estructura que pidió
  el usuario y alarga todas las rutas.

## Comprobado

Con enlaces, el comprobador acepta el pack (los `.gitkeep` de carpetas vacías no le molestan) y la recarga en
caliente aplica cada archivo guardado en la raíz («Shader pack Vulpe reloaded» en el chat, ~50 ms).

Para publicar hará falta `horizon-shader pack build/vulpe` (sigue los enlaces al empaquetar: pendiente de
comprobar cuando toque).

## Cambio del 2026-11-02: enlaces por archivo

El comprobador rechaza también un `.wgsl` que ninguna etapa usa («is not used by any stage or in shared»). Para poder
tener en el repo código escrito pero desactivado (la etapa `[vertex]` del 15, que el juego instalado no admite),
`tools/montar.sh` ya no enlaza carpetas enteras sino **cada archivo que el manifiesto nombra** (rutas `.wgsl` y
`.png` de sus líneas no comentadas), más el manifiesto, README y LICENSE. La carpeta no se borra al montar (el juego
la vigila mientras está abierto): se añaden los enlaces que faltan y se quitan los que sobran. La recarga en
caliente sigue funcionando con enlaces por archivo (comprobado).
