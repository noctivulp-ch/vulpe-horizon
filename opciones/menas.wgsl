// Ajustes de las menas brillantes. Porqué: docs/efectos/menas-brillantes.md §Opciones
override menas: i32 = 60;                   // brillo de las menas (0..99, 0 = apagadas) (§1)
override menas_umbral: i32 = 6;             // umbral de menas (2..15) (§1)

const OPC_MENAS_CARBON: bool = true;
// Brillo de la emisión de las menas sobre la emisión global (F-46, observación del dueño 2.3): las vetas no son fuente
// de luz; su halo sobre la piedra lo pone el bloom, que necesita un píxel por encima de lo que el tonemap deja ver.
// Antes 1 (0,2 × albedo en lineal: no llegaba a derramar).
const OPC_MENAS_BRILLO: f32 = 6.0;
// Luz de las menas (25, efecto propio): reunida en pantalla en la composición. Porqué: docs/efectos/menas-brillantes.md §«Luz de las menas (F-50)»
const OPC_MENAS_LUZ: bool = true;
const OPC_MENAS_LUZ_ALCANCE: f32 = 3.0;        // bloques (R)
const OPC_MENAS_LUZ_INTENSIDAD: f32 = 0.05;    // con la opción de menas a 60: ~nivel 3–4 de vanilla a 1 bloque de la mena
const OPC_MENAS_LUZ_MUESTRAS: i32 = 6;         // 6 × (superficie + profundidad) = 12 lecturas
const OPC_MENAS_LUZ_SAT_MIN: f32 = 0.25;       // por debajo (carbón, minerales grises) no emite
const OPC_MENAS_LUZ_SALIDA: f32 = 0.5;         // bloques que la fuente sale de la cara de la mena, como la celda de aire vecina
const OPC_MAT_MENA: u32 = 7u;

struct OpcMenas {
    activas: bool,
    intensidad: f32,    // 0..1
}

fn opc_menas() -> OpcMenas {
    return OpcMenas(menas > 0, f32(menas) * 0.01);
}
