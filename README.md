# Vulpe para Horizon

Shader propio para [Horizon](https://github.com/horizon-rust/horizon) (Minecraft Java 26.3 en Rust), en
su API de shaders WGSL. Pensado para poder publicarse: está escrito en **sala limpia**, desde la
especificación de `../vulpe-horizon-spec/` y la bibliografía pública, sin código de Bliss
(ver [docs/decisiones/0001-sala-limpia.md](docs/decisiones/0001-sala-limpia.md)).

Organización por función y principios SOLID: ver
[docs/decisiones/0002-estructura-por-funcion.md](docs/decisiones/0002-estructura-por-funcion.md).

Licencia: **pendiente de decidir por el dueño** antes de publicar.

## Probar

- Validar: `../trabajo/horizon-shader-build/target/release/horizon-shader check .`
- En el juego: `HORIZON_SHADER_PACK=$PWD horizon-ctl launch --world VulpePrueba --seed 1 --creative --wait`
  (`horizon-ctl` está en `~/.local/share/horizon-launcher/versions/<versión>/`), luego `time`, `look`,
  `screenshot`. La recarga en caliente aplica cada archivo guardado.
