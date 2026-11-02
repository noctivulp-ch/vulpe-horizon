// Ajustes de las menas brillantes. Porqué: docs/efectos/menas-brillantes.md §Opciones
override menas: bool = true;
override menas_intensidad: f32 = 60.0;      // %

const OPC_MENAS_SENSIBILIDAD: f32 = 6.0;
const OPC_MENAS_CARBON: bool = true;
const OPC_MAT_MENA: u32 = 7u;

struct OpcMenas {
    activas: bool,
    intensidad: f32,    // 0..1
}

fn opc_menas() -> OpcMenas {
    return OpcMenas(menas, menas_intensidad * 0.01);
}
