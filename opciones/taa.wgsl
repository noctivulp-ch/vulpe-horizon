// Ajustes del TAA. Porqué: docs/efectos/taa.md §Opciones
override taa: u32 = 2u;                     // 0: apagado, 1: estándar, 2: reactivo (§1)
const OPC_TAA_NITIDEZ_DEFECTO: f32 = 0.75;  // nitidez del TAA por defecto

// Medidos en paridad/09: la mezcla en movimiento es la misma que en reposo y la caja no se estrecha.
const OPC_TAA_MEZCLA_QUIETO: f32 = 0.125;
const OPC_TAA_MEZCLA_MOVIMIENTO: f32 = 0.125;
const OPC_TAA_GAMMA: f32 = 1.25;            // anchura de la caja de recorte, en desviaciones
const OPC_TAA_GAMMA_MOVIMIENTO: f32 = 1.25; // la misma con movimiento (antes 0,75)
const OPC_TAA_FXAA: bool = true;            // añadido de Vulpe para Horizon: el original no tiene FXAA

struct OpcTaa {
    activo: bool,
    nitidez: f32,
}

fn opc_taa() -> OpcTaa {
    return OpcTaa(taa != 0u, OPC_TAA_NITIDEZ_DEFECTO);
}
