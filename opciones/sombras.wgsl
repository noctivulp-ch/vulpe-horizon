// Ajustes de las sombras. Porqué: docs/efectos/sombras.md §Opciones
override sombras_penumbra: u32 = 1u;        // básica, variable
const SOMBRAS_PENUMBRA_MAX: f32 = 30.0;  // radio, texels (el del original)
const SOMBRAS_MUESTRAS: i32 = 8;
const SOMBRAS_COLOR: bool = true;

// Radio de la penumbra = mínimo + crecimiento × distancia al ocluyente, en bloques: con el PCF de 8 muestras da una
// anchura 10–90 % de 0,07 + 0,027·h (paridad/04, ajustado con tools/paridad/penumbra.py).
const OPC_SOMBRA_PENUMBRA_MIN: f32 = 0.051;
const OPC_SOMBRA_PENUMBRA_CRECE: f32 = 0.0197;

struct OpcSombras {
    ajustes: LuzAjustesSombra,
    color: bool,
}

fn opc_sombras() -> OpcSombras {
    return OpcSombras(
        LuzAjustesSombra(sombras_penumbra == 1u, OPC_SOMBRA_PENUMBRA_MIN, SOMBRAS_PENUMBRA_MAX, SOMBRAS_MUESTRAS, OPC_SOMBRA_PENUMBRA_CRECE),
        SOMBRAS_COLOR,
    );
}
