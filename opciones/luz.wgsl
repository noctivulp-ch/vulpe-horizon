// Ajustes de la luz de superficie. Porqué: docs/efectos/luz-de-superficie.md §Opciones
override charcos: u32 = 1u;                 // 0: apagado, 1: charcos y mojado, 2: solo charcos, 3: solo mojado (§1)
override charcos_tamano: f32 = 1.0;         // tamaño de los charcos (§1)
override luz_mano: u32 = 1u;                // 0: apagada, 1: normal, 2: linterna (§1)
override sss: u32 = 1u;                     // 0: apagada, 1: lista, 2: LabPBR, 3: ambos (§1)
override normales_intensidad: f32 = 1.0;    // intensidad de mapas de normales (§1)
override brillo_especular_sol: f32 = 1.0;   // brillo del destello solar (§1)

// Opciones que pasaron a constantes con nombre resueltas por presets o mod nativo (§2.2 y §3)
const OPC_LUZ_CIELO_DEFECTO: f32 = 1.0;
const OPC_LUZ_BLOQUE_DEFECTO: f32 = 1.0;
const OPC_LUZ_MINIMA_CUEVAS_DEFECTO: f32 = 1.0;
const OPC_LUZ_MINIMA_EXTERIOR_DEFECTO: f32 = 0.0;
const SSS_BRILLO: f32 = 1.0;
const EMISION_LABPBR: f32 = 1.0;

// Escalas en la escala común (convenciones.md): proporciones de partida afinadas en el juego.
const OPC_LUZ_BLOQUE: f32 = 1.0;            // × la curva medida de la antorcha (paridad/03; antes 0,012 × refuerzo 3)
const OPC_LUZ_MINIMA: f32 = 0.0004;           // base de otros mínimos (agua, ambiente del agua)
const OPC_LUZ_MINIMA_CUEVA: f32 = 0.0018;
const OPC_LUZ_MINIMA_FRENTE: f32 = 0.30;      // multiplicador de la luz mínima de frente a la cámara (1 de canto; fino/03 §Medidos)
const OPC_SSS_CIELO: f32 = 0.4;               // escala de la fase medida del SSS de cielo (1..2): 0,4..0,8, el tope de antes     // por unidad de la opción: calibrada con la medida exacta de paridad/03 (0.001766)
// Ambiente de las otras dimensiones (17), en la misma escala.
const OPC_AMBIENTE_NETHER: f32 = 0.035;      // F-45: ×10 (antes 0,0035), decisión del dueño 2.2
const OPC_AMBIENTE_END: f32 = 0.008;         // F-45: ×4 (antes 0,002), decisión del dueño 2.2
// Mínimo de luz de cielo de noche (F-45, decisión del dueño 2.1): ambiente azulado que se suma al del cielo nocturno a
// cielo abierto (pasa por la curva de la luz de cielo: en cuevas no llega). Antes no había (0).
const OPC_LUZ_NOCHE_CIELO: f32 = 0.006;
const OPC_LUZ_NOCHE_COLOR: vec3<f32> = vec3<f32>(0.55, 0.7, 1.0);
const OPC_EMISION: f32 = 0.05;
// La luz de cielo de la tabla (≈0,08 del sol a mediodía) se refuerza hasta el 0,1–0,2 de convenciones.md.
const OPC_LUZ_CIELO_BASE: f32 = 1.8;
// Rebote del suelo sobre las caras que lo ven (28 §2, F-53): × la luz del suelo × (1 − n.y)/2. Antes no había (0);
// 0.4 por medida (docs/efectos/luz-de-superficie.md §«Sombra y sol bajo (F-53)»).
const OPC_LUZ_REBOTE_SUELO: f32 = 0.4;
const OPC_LUZ_ABAJO_NEUTRA: f32 = 0.5;       // componente vertical de la normal desde la que la luz de cielo ya es gris (caras hacia abajo)

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
    luz_mano: u32,          // 0 apagada, 1 normal, 2 linterna
    normales_intensidad: f32,
}

fn opc_luz() -> OpcLuz {
    let mod_bloque = opc_estilo_luz_bloque();
    let mod_cuevas = opc_estilo_cuevas();
    let mod_noches = opc_estilo_noches();

    let color = mod_bloque.color;
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

    let con_charcos = charcos == 1u || charcos == 2u;
    let con_mojado = charcos == 1u || charcos == 3u;

    let amb_mod = adp_mod_param(15u, 0.0, 5.0, VULPE_LUZ_AMBIENTE_BRILLO, 1.0);
    let min_ext_mod = adp_mod_param(16u, 0.0, 1.0, VULPE_LUZ_MINIMA_EXTERIOR, 0.05) - 0.05;
    let bloq_mod = adp_mod_param(17u, 0.0, 5.0, VULPE_LUZ_BLOQUE_INTENSIDAD, 1.0);

    return OpcLuz(
        OPC_LUZ_CIELO_DEFECTO * amb_mod,
        OPC_LUZ_BLOQUE_DEFECTO * mod_bloque.intensidad * bloq_mod,
        color,
        OPC_LUZ_MINIMA_CUEVAS_DEFECTO * mod_cuevas.mult_luz_minima,
        max(max(OPC_LUZ_MINIMA_EXTERIOR_DEFECTO + min_ext_mod, 0.0), mod_noches.luz_minima_exterior),
        sss == 1u || sss == 3u, sss == 2u || sss == 3u, SSS_BRILLO,
        brillo_especular_sol, EMISION_LABPBR,
        con_charcos, con_mojado,
        pasos, suavidad,
        luz_mano,
        normales_intensidad,
    );
}

// Relámpago (20), sin opción de menú: constantes. Porqué: docs/efectos/relampago.md
const OPC_RELAMPAGO: bool = true;                               // activo por defecto
const OPC_RELAMPAGO_DURACION: f32 = 1.0;                        // segundos de destello tras la caída
const OPC_RELAMPAGO_BRILLO: f32 = 6.0;                          // luz sobre superficies, escala de la luz de bloque
const OPC_RELAMPAGO_COLOR: vec3<f32> = vec3<f32>(0.80, 0.88, 1.0); // blanco algo azulado
const OPC_RELAMPAGO_NUBES: f32 = 3.0;                           // luz dentro de nubes y niebla

// Ganancia de la luz de cielo sobre las superficies con el sol bajo (28 §1–2, F-54), por elevación del sol en grados.
// Solo superficies (adp_luces): las nubes y la niebla siguen con atm_ambiente_cielo sin tocar.
// Porqué: docs/efectos/luz-de-superficie.md §«Sombra y sol bajo (F-53, F-54)» › «Sol bajo (F-54)»
const OPC_LUZ_SOL_BAJO_ELEV = array<f32, 6>(-6.0, 0.0, 6.0, 12.0, 20.0, 30.0);
const OPC_LUZ_SOL_BAJO_GANANCIA = array<f32, 6>(1.0, 1.4, 1.9, 1.6, 1.2, 1.0);
// Cuánto se acerca ese ambiente a gris (0 = color de la tabla del cielo, 1 = gris de igual luminancia).
const OPC_LUZ_SOL_BAJO_GRIS = array<f32, 6>(0.0, 0.5, 0.6, 0.5, 0.25, 0.0);
// Lo mismo para la luz directa del sol sobre las superficies (28 §1: saturación ≤ 0,25, crema y no naranja).
const OPC_LUZ_SOL_BAJO_GRIS_SOL = array<f32, 6>(0.0, 0.25, 0.28, 0.2, 0.0, 0.0);
