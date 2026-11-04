// Ajustes del agua. Porqué: docs/efectos/agua.md §Opciones
override agua_olas: f32 = 1.0;
override agua_claridad: f32 = 1.0;
override agua_refraccion: f32 = 50.0;

const OPC_AGUA_VELOCIDAD: f32 = 1.0;
const OPC_AGUA_CAUSTICAS: f32 = 1.0;
const OPC_AGUA_MINIMO: f32 = 1.0;           // brillo mínimo de la niebla bajo el agua
const OPC_AGUA_TEXTURA: bool = false;       // la textura vanilla del agua no se ve
// Medidos en paridad/07: extinción por bloque (transmitancia a 4 bloques 0,21; 0,65; 0,77), Fresnel de n = 1,333.
const OPC_AGUA_ABSORCION: vec3<f32> = vec3<f32>(0.39, 0.108, 0.066);
const OPC_AGUA_F0: f32 = 0.02037;
const OPC_AGUA_DISPERSION: f32 = 0.035;     // dispersión hacia la vista (gris), por bloque
const OPC_AGUA_COLOR_DISPERSO: vec3<f32> = vec3<f32>(0.08, 0.45, 0.55);
const OPC_AGUA_CALMA: f32 = 0.30;           // escala mínima del oleaje en las zonas en calma (paridad/07 §2)
const OPC_AGUA_CAUSTICAS_AGUDEZA: f32 = 1.0;

struct OpcAgua {
    olas: AguOlas,
    claridad: f32,
    refraccion: f32,        // fracción de pantalla por unidad de normal tangente
}

fn opc_agua(tiempo: f32, lluvia: f32) -> OpcAgua {
    return OpcAgua(AguOlas(agua_olas * (1.0 + 0.8 * lluvia), tiempo * OPC_AGUA_VELOCIDAD, OPC_AGUA_CALMA, OPC_AGUA_CAUSTICAS_AGUDEZA),
                   agua_claridad, agua_refraccion * 0.0006);
}

fn opc_agua_medio(claridad: f32) -> AguMedio {
    return agu_medio(claridad, OPC_AGUA_ABSORCION, OPC_AGUA_DISPERSION, OPC_AGUA_COLOR_DISPERSO);
}
