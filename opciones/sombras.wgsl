// Ajustes de las sombras. Porqué: docs/efectos/sombras.md §Opciones
override sombras_penumbra: u32 = 1u;        // básica, variable
const SOMBRAS_PENUMBRA_MIN: f32 = 5.0;   // 0..10 (ver opc_sombras)
const SOMBRAS_PENUMBRA_MAX: f32 = 20.0;  // texels
const SOMBRAS_MUESTRAS: i32 = 8;
const SOMBRAS_COLOR: bool = true;

const OPC_SOMBRA_TAMANO_SOL: f32 = 0.026;   // tan(1,5°): el sol aparente, mayor que el real por gusto

struct OpcSombras {
    ajustes: LuzAjustesSombra,
    color: bool,
}

fn opc_sombras() -> OpcSombras {
    // La penumbra mínima de la opción (0..10) va en cuartos de texel más 1: con 5, 2,25 texels, que tapa la
    // resolución del mapa sin emborronar.
    let minima = 1.0 + SOMBRAS_PENUMBRA_MIN * 0.25;
    return OpcSombras(
        LuzAjustesSombra(sombras_penumbra == 1u, minima, max(SOMBRAS_PENUMBRA_MAX, minima), SOMBRAS_MUESTRAS, OPC_SOMBRA_TAMANO_SOL),
        SOMBRAS_COLOR,
    );
}
