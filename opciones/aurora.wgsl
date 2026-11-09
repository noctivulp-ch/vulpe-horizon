// Ajustes de la aurora. Porqué: docs/efectos/aurora.md §Opciones
override aurora_brillo: i32 = 100;          // % (§1) (0 = apagada)

const OPC_AURORA_INTENSIDAD: f32 = 600.0;   // la de Vulpe; escala en adp_aurora
const OPC_AURORA_RADIO: f32 = 512.0;
const OPC_AURORA_FIN_VELO: f32 = 130.0;     // sobre el suelo de referencia
const OPC_AURORA_LARGO: f32 = 96.0;
const OPC_AURORA_SUELO: f32 = 70.0;         // Y fija del suelo de referencia (sin mod nativo)

struct OpcAurora {
    activa: bool,
    brillo: f32,            // multiplicador
    iteraciones: i32,
    muestras: i32,
}

fn opc_aurora() -> OpcAurora {
    let nivel = opc_calidad_fractal();
    var iteraciones = 24;
    var muestras = 4;
    switch nivel {
        case 0u: { // Baja: 12 iteraciones, 2 muestras
            iteraciones = 12;
            muestras = 2;
        }
        case 1u: { // Media: 24 iteraciones, 4 muestras
            iteraciones = 24;
            muestras = 4;
        }
        case 2u: { // Alta: 48 iteraciones, 8 muestras
            iteraciones = 48;
            muestras = 8;
        }
        default: { // Ultra: 96 iteraciones, 12 muestras
            iteraciones = 96;
            muestras = 12;
        }
    }
    return OpcAurora(aurora_brillo > 0, f32(aurora_brillo) * 0.01, iteraciones, muestras);
}
