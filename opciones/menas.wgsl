// Ajustes de las menas brillantes. Porqué: docs/efectos/menas-brillantes.md §Opciones
override menas: i32 = 60;                   // brillo de las menas (0..99, 0 = apagadas) (§1)
override menas_umbral: i32 = 6;             // umbral de menas (2..15) (§1)

const OPC_MENAS_CARBON: bool = true;
// Brillo de la emisión de las menas sobre la emisión global (F-46, observación del dueño 2.3): las vetas no son fuente
// de luz; su halo sobre la piedra lo pone el bloom, que necesita un píxel por encima de lo que el tonemap deja ver.
// Antes 1 (0,2 × albedo en lineal: no llegaba a derramar).
const OPC_MENAS_BRILLO: f32 = 6.0;
const OPC_MAT_MENA: u32 = 7u;

struct OpcMenas {
    activas: bool,
    intensidad: f32,    // 0..1
}

fn opc_menas() -> OpcMenas {
    return OpcMenas(menas > 0, f32(menas) * 0.01);
}
