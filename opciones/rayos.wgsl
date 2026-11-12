// Ajustes de los rayos del fractal. Porqué: docs/efectos/rayos-del-fractal.md §Opciones
override rayos_intensidad: i32 = 0;         // intensidad de los rayos (0..500 %, 0 = apagados) (§1)

// Valores de Vulpe: de frente y de espaldas (especificación 14 §4).
const OPC_RAYOS_FOCO: vec2<f32> = vec2<f32>(85.0, 35.0);
const OPC_RAYOS_LONGITUD: vec2<f32> = vec2<f32>(70.0, 90.0);
const OPC_RAYOS_CAIDA: f32 = 96.0;
const OPC_RAYOS_UMBRAL: vec2<f32> = vec2<f32>(2.0, 4.0);
const OPC_RAYOS_NUCLEO: vec2<f32> = vec2<f32>(100.0, 40.0);
const OPC_RAYOS_ESPALDAS: f32 = 100.0;      // % de la intensidad de frente
const OPC_RAYOS_OCLUSION: f32 = 60.0;
const OPC_RAYOS_ATRAS: f32 = 100.0;         // dispersión hacia atrás, %
const OPC_RAYOS_FASE_NORMA: f32 = 8.771;    // HG(1; 0,85) + HG(1; 0,75): la fase directa vale 1 de frente (fino/14 §1)

struct OpcRayos {
    activo: bool,
    intensidad: f32,
    muestras: i32,
}

fn opc_rayos() -> OpcRayos {
    let nivel = opc_calidad_fractal();
    var muestras = 32;
    switch nivel {
        case 0u: { // Baja: 16 muestras
            muestras = 16;
        }
        case 1u: { // Media: 32 muestras
            muestras = 32;
        }
        case 2u: { // Alta: 48 muestras
            muestras = 48;
        }
        default: { // Ultra: 64 muestras
            muestras = 64;
        }
    }
    return OpcRayos(rayos_intensidad > 0, f32(rayos_intensidad), muestras);
}
