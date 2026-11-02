// Ajustes de las vistas de depuración. Porqué: docs/efectos/nucleo.md §Vistas de depuración
override depuracion_vista: u32 = 0u;

const OPC_VISTA_NORMAL: u32 = 0u;
const OPC_VISTA_PROFUNDIDAD: u32 = 1u;
const OPC_VISTA_RUIDO: u32 = 2u;
const OPC_VISTA_TRAMADO: u32 = 3u;
const OPC_VISTA_AURORA_CONOS: u32 = 4u;         // la escena normal con el volumen de los conos en rojo
const OPC_VISTA_AURORA_SIN_VENTANA: u32 = 5u;   // la escena normal sin la ventana al cielo
const OPC_VISTA_AURORA_MAPA: u32 = 6u;          // el mapa de la aurora a pantalla completa (rgb, sin escala)

struct OpcDepuracion {
    vista: u32,
}

fn opc_depuracion() -> OpcDepuracion {
    return OpcDepuracion(depuracion_vista);
}
