// Gotas en la cámara al salir del agua (07.2). Porqué: docs/efectos/agua.md §Gotas en la cámara
const OPC_GOTAS_DURACION: f32 = 2.5;         // segundos que duran las gotas tras salir del agua
const OPC_GOTAS_INTENSIDAD: f32 = 0.5;       // intensidad media (50 % como el original)
const OPC_GOTAS_REFRACCION: f32 = 0.035;     // fuerza de distorsión UV
const OPC_GOTAS_ESCALA_Y: f32 = 12.0;        // celdas de gotas verticales
const OPC_GOTAS_VELOCIDAD: f32 = 0.35;       // velocidad de escurrimiento hacia abajo

fn opc_gotas() -> ImgGotasAjustes {
    return ImgGotasAjustes(
        OPC_GOTAS_DURACION,
        OPC_GOTAS_INTENSIDAD,
        OPC_GOTAS_REFRACCION,
        OPC_GOTAS_ESCALA_Y,
        OPC_GOTAS_VELOCIDAD,
    );
}
