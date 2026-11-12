// Efectos de cámara de juego (19), sin opción de menú: constantes. Porqué: docs/efectos/camara-y-juego.md
const OPC_GOTAS_DURACION: f32 = 5.0;          // segundos tras cruzar la superficie del agua
const OPC_GOTAS_FUERZA: f32 = 0.5;            // ajuste del original, 50 por defecto
const OPC_GOTAS_RAPIDEZ_REF: f32 = 8.0;       // bloques/s de cruce para la fuerza completa (un chapuzón)
const OPC_CALOR_FUERZA: f32 = 0.7;            // ajuste del original, 70 por defecto
const OPC_CALOR_SUBE: f32 = 0.5;              // segundos para encenderse
const OPC_CALOR_BAJA: f32 = 3.0;              // segundos para apagarse

fn opc_gotas() -> ImgGotasAjustes {
    return ImgGotasAjustes(OPC_GOTAS_DURACION, OPC_GOTAS_FUERZA, OPC_GOTAS_RAPIDEZ_REF);
}
