# Vulpe para Horizon

Shader propio para [Horizon](https://github.com/horizon-rust/horizon) (Minecraft Java 26.3 en Rust), en
su API de shaders WGSL. Pensado para poder publicarse: está escrito en **sala limpia**, desde la
especificación de `../vulpe-horizon-spec/` y la bibliografía pública, sin código de Bliss
(ver [docs/decisiones/0001-sala-limpia.md](docs/decisiones/0001-sala-limpia.md)).

Organización por función y principios SOLID: ver
[docs/decisiones/0002-estructura-por-funcion.md](docs/decisiones/0002-estructura-por-funcion.md).

Licencia: **pendiente de decidir por el dueño** antes de publicar.

## Probar

- Validar: `tools/validar.sh` (monta el pack en `build/vulpe/` y pasa `horizon-shader check`; ver
  [ADR 0003](docs/decisiones/0003-pack-montado-en-build.md)).
- En el juego: `tools/probar.sh base [--dejar-abierto]` valida, abre Horizon con el pack, recorre
  `pruebas/escenas/base.ctl` y guarda las capturas en `pruebas/capturas/`. La recarga en caliente aplica
  cada archivo guardado.

Documentación: [docs/index.md](docs/index.md).
