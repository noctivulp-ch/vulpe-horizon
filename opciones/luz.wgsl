// Ajustes de la luz de superficie. Porqué: docs/efectos/luz-de-superficie.md §Opciones
override luz_cielo: f32 = 1.0;
override luz_bloque: f32 = 1.0;
const LUZ_BLOQUE_COLOR: u32 = 0u;        // cálido, neutro, frío
override luz_minima_cuevas: f32 = 0.5;
const LUZ_MINIMA_EXTERIOR: f32 = 0.0;
override sss: u32 = 1u;                     // apagado, lista, LabPBR, ambos
const SSS_BRILLO: f32 = 1.0;
const ESPECULAR_SOL: f32 = 1.0;
const EMISION_LABPBR: f32 = 1.0;
override charcos: u32 = 0u;                 // charcos y mojado, solo charcos, solo mojado, apagado
override reflejos_pantalla: u32 = 1u;       // apagado, bajo, alto

// Escalas en la escala común (convenciones.md): proporciones de partida afinadas en el juego.
const OPC_LUZ_BLOQUE: f32 = 0.012;          // superficie blanca junto a una antorcha (antes del refuerzo)
const OPC_LUZ_BLOQUE_REFUERZO: f32 = 3.0;
const OPC_LUZ_MINIMA: f32 = 0.0004;
const OPC_EMISION: f32 = 0.05;
// La luz de cielo de la tabla (≈0,08 del sol a mediodía) se refuerza hasta el 0,1–0,2 de convenciones.md.
const OPC_LUZ_CIELO_BASE: f32 = 1.8;

// Ids de [[materials]] (horizon-shaders.toml).
// Suavidad desde la que el reflejo lo pone el trazado de pantalla (post) y no el material.
const OPC_SUAVIDAD_REFLEJO_PANTALLA: f32 = 0.7;

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
}

fn opc_luz() -> OpcLuz {
    var color = vec3<f32>(1.0, 0.5, 0.25);
    if LUZ_BLOQUE_COLOR == 1u {
        color = vec3<f32>(1.0, 0.78, 0.6);
    } else if LUZ_BLOQUE_COLOR == 2u {
        color = vec3<f32>(0.75, 0.85, 1.0);
    }
    return OpcLuz(
        luz_cielo, luz_bloque, color, luz_minima_cuevas, LUZ_MINIMA_EXTERIOR,
        sss == 1u || sss == 3u, sss == 2u || sss == 3u, SSS_BRILLO,
        ESPECULAR_SOL, EMISION_LABPBR,
        charcos == 0u || charcos == 1u, charcos == 0u || charcos == 2u,
        array<i32, 3>(0, 16, 32)[min(reflejos_pantalla, 2u)],
    );
}
