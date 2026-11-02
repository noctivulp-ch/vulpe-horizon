// Ajustes de las sombras. Porqué: docs/efectos/sombras.md §Opciones
override sombras_penumbra: u32 = 1u;        // básica, variable
override sombras_penumbra_min: f32 = 5.0;   // 0..10 (ver opc_sombras)
override sombras_penumbra_max: f32 = 20.0;  // texels
override sombras_muestras: i32 = 8;
override sombras_color: bool = true;

const OPC_SOMBRA_TAMANO_SOL: f32 = 0.026;   // tan(1,5°): el sol aparente, mayor que el real por gusto
const OPC_AGUA_TINTE: vec3<f32> = vec3<f32>(0.55, 0.8, 0.85);

struct OpcSombras {
    ajustes: LuzAjustesSombra,
    color: bool,
}

fn opc_sombras() -> OpcSombras {
    // La penumbra mínima de la opción (0..10) va en cuartos de texel más 1: con 5, 2,25 texels, que tapa la
    // resolución del mapa sin emborronar.
    let minima = 1.0 + sombras_penumbra_min * 0.25;
    return OpcSombras(
        LuzAjustesSombra(sombras_penumbra == 1u, minima, max(sombras_penumbra_max, minima), sombras_muestras, OPC_SOMBRA_TAMANO_SOL),
        sombras_color,
    );
}
