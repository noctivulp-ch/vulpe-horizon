// Ajustes del agua. Porqué: docs/efectos/agua.md §Opciones
override agua_olas: f32 = 1.0;
override agua_claridad: f32 = 1.0;
override agua_refraccion: f32 = 50.0;

const OPC_AGUA_VELOCIDAD: f32 = 1.0;
const OPC_AGUA_CAUSTICAS: f32 = 1.0;
const OPC_AGUA_MINIMO: f32 = 1.0;           // brillo mínimo de la niebla bajo el agua
const OPC_AGUA_TEXTURA: bool = false;       // la textura vanilla del agua no se ve

struct OpcAgua {
    olas: AguOlas,
    claridad: f32,
    refraccion: f32,        // fracción de pantalla por unidad de normal tangente
}

fn opc_agua(tiempo: f32, lluvia: f32) -> OpcAgua {
    return OpcAgua(AguOlas(agua_olas * (1.0 + 0.8 * lluvia), tiempo * OPC_AGUA_VELOCIDAD), agua_claridad, agua_refraccion * 0.0006);
}
