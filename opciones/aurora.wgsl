// Ajustes de la aurora. Porqué: docs/efectos/aurora.md §Opciones
override aurora: bool = true;
override aurora_brillo: f32 = 0.0;          // %, relativo, encima de todo

const OPC_AURORA_INTENSIDAD: f32 = 600.0;   // la de Vulpe; escala en adp_aurora
const OPC_AURORA_ITERACIONES: i32 = 24;
const OPC_AURORA_RADIO: f32 = 512.0;
const OPC_AURORA_FIN_VELO: f32 = 130.0;     // sobre el suelo de referencia
const OPC_AURORA_LARGO: f32 = 96.0;
const OPC_AURORA_SUELO: f32 = 70.0;         // Y fija del suelo de referencia (sin mod nativo)

struct OpcAurora {
    activa: bool,
    brillo: f32,            // multiplicador
}

fn opc_aurora() -> OpcAurora {
    return OpcAurora(aurora, 1.0 + aurora_brillo * 0.01);
}
