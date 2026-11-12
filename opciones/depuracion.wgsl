// Ajustes de las vistas de depuración. Porqué: docs/efectos/nucleo.md §Vistas de depuración
const OPC_DEPURACION_VISTA_DEFECTO: u32 = 0u;

const OPC_VISTA_NORMAL: u32 = 0u;
const OPC_VISTA_PROFUNDIDAD: u32 = 1u;
const OPC_VISTA_RUIDO: u32 = 2u;
const OPC_VISTA_TRAMADO: u32 = 3u;
const OPC_VISTA_AURORA_CONOS: u32 = 4u;         // la escena normal con el volumen de los conos en rojo
const OPC_VISTA_AURORA_SIN_VENTANA: u32 = 5u;   // la escena normal sin la ventana al cielo
const OPC_VISTA_AURORA_MAPA: u32 = 6u;          // el mapa de la aurora a pantalla completa (rgb, sin escala)
const OPC_VISTA_RELIEVE: u32 = 7u;              // R = MaterialInput.displaced, G = altura LabPBR, B = 1 si hay mapas PBR
const OPC_VISTA_MOD_NATIVO: u32 = 8u;           // Mod nativo: firma, fase lunar y estación continua
// Formas aisladas (formas/README.md): mapa cenital de la forma horizontal de una capa de nubes alrededor de la cámara,
// y corte vertical (x, altura) de la densidad con erosión. Sin luz, sin niebla, sin tonemap. Porqué: docs/efectos/nucleo.md
const OPC_VISTA_FORMA_NUBES_0: u32 = 9u;        // cúmulos pequeños, 8 km de ancho
const OPC_VISTA_FORMA_NUBES_1: u32 = 10u;       // cúmulos grandes, 16 km
const OPC_VISTA_FORMA_NUBES_2: u32 = 11u;       // altoestratos, 160 km
const OPC_VISTA_CORTE_NUBES_0: u32 = 12u;       // corte vertical de los pequeños, 1 km × su espesor
const OPC_VISTA_CORTE_NUBES_1: u32 = 13u;       // corte vertical de los grandes, 2 km × su espesor
const OPC_VISTA_FORMA_AGUA: u32 = 14u;          // la normal de las olas en color (×4: x → rojo, z → azul), sin luz
const OPC_VISTA_FORMA_ANCHO = array<f32, 5>(8000.0, 16000.0, 160000.0, 1000.0, 2000.0);

fn opc_vista_forma(v: u32) -> bool {
    return v >= OPC_VISTA_FORMA_NUBES_0 && v <= OPC_VISTA_CORTE_NUBES_1;
}

struct OpcDepuracion {
    vista: u32,
}

fn opc_depuracion() -> OpcDepuracion {
    return OpcDepuracion(OPC_DEPURACION_VISTA_DEFECTO);
}
