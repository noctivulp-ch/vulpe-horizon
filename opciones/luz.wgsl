// Ajustes de la luz de superficie. Porqué: docs/efectos/luz-de-superficie.md §Opciones
override luz_cielo: f32 = 1.0;
override luz_bloque: f32 = 1.0;
const LUZ_BLOQUE_COLOR: u32 = 0u;        // cálido, neutro, frío
override luz_minima_cuevas: f32 = 0.5;
override luz_minima_exterior: f32 = 0.0;
override sss: u32 = 1u;                     // apagado, lista, LabPBR, ambos
const SSS_BRILLO: f32 = 1.0;
const ESPECULAR_SOL: f32 = 1.0;
const EMISION_LABPBR: f32 = 1.0;
override charcos: u32 = 0u;                 // charcos y mojado, solo charcos, solo mojado, apagado

// Escalas en la escala común (convenciones.md): proporciones de partida afinadas en el juego.
const OPC_LUZ_BLOQUE: f32 = 1.0;            // × la curva medida de la antorcha (paridad/03; antes 0,012 × refuerzo 3)
const OPC_LUZ_MINIMA: f32 = 0.0004;           // base de otros mínimos (agua, ambiente del agua)
const OPC_LUZ_MINIMA_CUEVA: f32 = 0.00294;    // por unidad de la opción: con 0,6 da 0,001766, el del original (paridad/03)
// Ambiente de las otras dimensiones (17), en la misma escala.
const OPC_AMBIENTE_NETHER: f32 = 0.0035;
const OPC_AMBIENTE_END: f32 = 0.002;
const OPC_EMISION: f32 = 0.05;
// La luz de cielo de la tabla (≈0,08 del sol a mediodía) se refuerza hasta el 0,1–0,2 de convenciones.md.
const OPC_LUZ_CIELO_BASE: f32 = 1.8;

// Ids de [[materials]] (horizon-shaders.toml).
const OPC_MAT_HOJAS: u32 = 1u;
const OPC_MAT_PLANTA_FUERTE: u32 = 2u;      // planta cruzada, SSS fuerte
const OPC_MAT_HIELO: u32 = 3u;
const OPC_MAT_PLANTA_MEDIA: u32 = 4u;       // planta cruzada, SSS medio
const OPC_MAT_MEDIO: u32 = 5u;
const OPC_MAT_DEBIL: u32 = 6u;

struct OpcLuz {
    cielo: f32,
    bloque: f32,
    bloque_color: vec3<f32>,
    minima_cuevas: f32,
    minima_exterior: f32,
    sss_lista: bool,
    sss_labpbr: bool,
    sss_brillo: f32,
    especular_sol: f32,
    emision_labpbr: f32,
    charcos: bool,
    mojado: bool,
    pasos_reflejo: i32,     // 0 apagado
    suavidad_reflejo: f32,  // umbral de suavidad para trazado de pantalla (1 - rugosidad)
}

fn opc_luz() -> OpcLuz {
    var color = vec3<f32>(1.0, 0.5, 0.25);
    if LUZ_BLOQUE_COLOR == 1u {
        color = vec3<f32>(1.0, 0.78, 0.6);
    } else if LUZ_BLOQUE_COLOR == 2u {
        color = vec3<f32>(0.75, 0.85, 1.0);
    }

    let nivel = opc_calidad_reflejos();
    var pasos = 15;
    var suavidad = 0.7; // rugosidad 0,3 -> suavidad 0,7
    switch nivel {
        case 0u: { // Baja: 8 pasos, rugosidad 0,2
            pasos = 8;
            suavidad = 0.8;
        }
        case 1u: { // Media: 15 pasos, rugosidad 0,3
            pasos = 15;
            suavidad = 0.7;
        }
        case 2u: { // Alta: 30 pasos, rugosidad 0,4
            pasos = 30;
            suavidad = 0.6;
        }
        default: { // Ultra: 50 pasos, rugosidad 0,5
            pasos = 50;
            suavidad = 0.5;
        }
    }

    return OpcLuz(
        luz_cielo, luz_bloque, color, luz_minima_cuevas, luz_minima_exterior,
        sss == 1u || sss == 3u, sss == 2u || sss == 3u, SSS_BRILLO,
        ESPECULAR_SOL, EMISION_LABPBR,
        charcos == 0u || charcos == 1u, charcos == 0u || charcos == 2u,
        pasos, suavidad,
    );
}
