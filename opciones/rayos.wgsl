// Ajustes de los rayos del fractal. Porqué: docs/efectos/rayos-del-fractal.md §Opciones
override rayos: bool = false;               // apagado por defecto, como en Vulpe
override rayos_intensidad: f32 = 200.0;

// Valores de Vulpe: de frente y de espaldas (especificación 14 §4).
const OPC_RAYOS_FOCO: vec2<f32> = vec2<f32>(85.0, 35.0);
const OPC_RAYOS_LONGITUD: vec2<f32> = vec2<f32>(70.0, 90.0);
const OPC_RAYOS_CAIDA: f32 = 96.0;
const OPC_RAYOS_UMBRAL: vec2<f32> = vec2<f32>(2.0, 4.0);
const OPC_RAYOS_NUCLEO: vec2<f32> = vec2<f32>(100.0, 40.0);
const OPC_RAYOS_ESPALDAS: f32 = 100.0;      // % de la intensidad de frente
const OPC_RAYOS_OCLUSION: f32 = 60.0;
const OPC_RAYOS_ATRAS: f32 = 100.0;         // dispersión hacia atrás, %

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
    return OpcRayos(rayos, rayos_intensidad, muestras);
}
