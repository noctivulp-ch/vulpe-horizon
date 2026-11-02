// Ajustes del TAA. Porqué: docs/efectos/taa.md §Opciones
override taa: bool = true;
override taa_nitidez: f32 = 0.5;

const OPC_TAA_MEZCLA_QUIETO: f32 = 0.125;
const OPC_TAA_MEZCLA_MOVIMIENTO: f32 = 0.33;
const OPC_TAA_GAMMA: f32 = 1.1;             // anchura de la caja de recorte, en desviaciones
const OPC_TAA_FXAA: bool = true;

struct OpcTaa {
    activo: bool,
    nitidez: f32,
}

fn opc_taa() -> OpcTaa {
    return OpcTaa(taa, taa_nitidez);
}
