// Constantes y ajustes de «el tiempo en los cristales» (subsistema 27 v2, sin opciones nuevas en el menú 64/64).
// Porqué: docs/efectos/tiempo-en-los-cristales.md

const OPC_TAG_CRISTAL: u32 = 1u;                 // bit 0 de MaterialInput.tags ([[tags]] id = "cristal")
const OPC_MAT_CRISTAL_CLARO: u32 = 11u;          // [[materials]] id = 11: block/glass y block/glass_pane_top (translucent = true)
const OPC_CRISTAL_ALFA_CLARO_MAX: f32 = 0.08;    // interior transparente del cristal claro (~6/255 = 0,0235 en el mod)
const OPC_CRISTAL_REJILLA: f32 = 32.0;           // resolución base: 32 texeles por bloque (decisión del dueño, 27 §Base)

// Interruptor maestro y valores por defecto sin mod (con mod manda [cristales] en config/vulpe-horizon.toml).
const OPC_CRISTAL_ACTIVO: bool = true;
const OPC_CRISTAL_NIVEL_DEFECTO: f32 = 1.0;      // 0 apagada, 0,5 poca, 1,0 normal, 1,7 mucha (arena: 1,4)
const OPC_CRISTAL_ESTILO_REGUEROS: bool = false; // false = gotas (por defecto), true = regueros
const OPC_CRISTAL_SEGUIR_VIENTO: bool = true;
const OPC_CRISTAL_INTERIOR_ACTIVO: bool = true;
const OPC_CRISTAL_COND_OPACIDAD_DEF: f32 = 1.0;  // 100 %
const OPC_CRISTAL_COND_BLANCURA_DEF: f32 = 0.0;  // 0 %
const OPC_CRISTAL_BORDE_ESTILO_DEF: u32 = 1u;    // 0 apagado, 1 banda (por defecto), 2 cristales
const OPC_CRISTAL_DESENFOQUE_DEF: u32 = 1u;      // 0 apagado, 1 suave (por defecto), 2 normal, 3 fuerte
const OPC_CRISTAL_ALIENTO_OPACIDAD_DEF: f32 = 1.5; // 150 %
const OPC_CRISTAL_ALIENTO_BLANCURA_DEF: f32 = 1.0; // 100 %

// Banderas empaquetadas en `datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS].x` (entero exacto de 24 bits).
const OPC_CR_FLAG_REGUEROS: u32 = 1u << 0u;
const OPC_CR_FLAG_VIENTO: u32 = 1u << 1u;
const OPC_CR_FLAG_INTERIOR: u32 = 1u << 2u;
const OPC_CR_FLAG_ARENA_ROJA: u32 = 1u << 3u;
const OPC_CR_FLAG_ESPECTADOR: u32 = 1u << 4u;
const OPC_CR_FLAG_BIOMA_SECO: u32 = 1u << 5u;
const OPC_CR_FLAG_BIOMA_FRIO: u32 = 1u << 6u;
const OPC_CR_FLAG_LLUEVE_BIOMA: u32 = 1u << 7u;
// bits 8..9: estilo borde helado (0 apagado, 1 banda, 2 cristales)
// bits 10..11: nivel desenfoque (0 apagado, 1 suave, 2 normal, 3 fuerte)

// Constantes de tiempo y suavizado (27 §Tiempo y estado, §Viento).
const OPC_CRISTAL_CLIMA_UMBRAL: f32 = 0.05;
const OPC_CRISTAL_TEMP_NIEVE: f32 = 0.15;
const OPC_CRISTAL_VIENTO_TAU_LLUVIA: f32 = 1.0;  // ~1 s de suavizado para lluvia
const OPC_CRISTAL_VIENTO_TAU_ARENA: f32 = 5.0;   // ~5 s de suavizado para arena
const OPC_CRISTAL_ARENA_MIN: f32 = 0.015625;     // 1/64

// Alcances espaciales y respaldo sin RT (27 §Decisión por cara, §Capa 7).
const OPC_CRISTAL_DIST_MAX: f32 = 48.0;          // alcance máximo de las capas de cristal (48 bloques)
const OPC_CRISTAL_DIST_INICIO: f32 = 34.0;
const OPC_CRISTAL_DIST_FIN: f32 = 48.0;
const OPC_CRISTAL_CIELO_MIN: f32 = 0.85;         // respaldo sin RT: luz de cielo ~14/15
const OPC_CRISTAL_CIELO_MAX: f32 = 0.93;

// Paleta de lluvia (27 §Capa 1, convertida de sRGB/255 a luz lineal ^2,2).
const OPC_CRISTAL_LLUVIA_CUERPO: vec3<f32> = vec3<f32>(0.155, 0.238, 0.517);   // (109, 133, 189)
const OPC_CRISTAL_LLUVIA_BRILLO: vec3<f32> = vec3<f32>(0.811, 0.874, 1.000);   // (232, 240, 255)
const OPC_CRISTAL_LLUVIA_SOMBRA: vec3<f32> = vec3<f32>(0.042, 0.097, 0.388);   // (60, 88, 166)
const OPC_CRISTAL_GOTA_REFRACCION: f32 = 0.045;
const OPC_CRISTAL_GOTA_ESPECULAR: f32 = 1.25;
const OPC_CRISTAL_GOTA_CAUSTICA: f32 = 0.35;
const OPC_CRISTAL_GOTA_BORDE: f32 = 0.24;
const OPC_CRISTAL_MOJADO_F0_EXTRA: f32 = 0.035;
const OPC_CRISTAL_VIENTO_BARLOVENTO: f32 = 0.80; // 1 + 0,8 * hacia_la_cara (0,2..1,8)
const OPC_CRISTAL_VIENTO_INCLINACION: f32 = 0.90;
const OPC_CRISTAL_SECADO_RASTRO: vec2<f32> = vec2<f32>(0.0, 0.28);
const OPC_CRISTAL_SECADO_PEQUENAS: vec2<f32> = vec2<f32>(0.18, 0.62);
const OPC_CRISTAL_SECADO_GRANDES: vec2<f32> = vec2<f32>(0.50, 1.0);

// Paleta de escarcha y repisa de nieve (27 §Capa 2, sRGB -> lineal ^2,2).
const OPC_CRISTAL_ESCARCHA_HIELO: vec3<f32> = vec3<f32>(0.363, 0.555, 1.000);  // (161, 195, 255)
const OPC_CRISTAL_ESCARCHA_CRISTAL: vec3<f32> = vec3<f32>(0.587, 0.723, 1.000);// (200, 220, 255)
const OPC_CRISTAL_ESCARCHA_DENSO: vec3<f32> = vec3<f32>(0.842, 0.924, 1.000);  // (236, 246, 255)
const OPC_CRISTAL_ESCARCHA_DESTELLO: vec3<f32> = vec3<f32>(1.000, 1.000, 1.000);
const OPC_CRISTAL_REPISA_TONO_A: vec3<f32> = vec3<f32>(0.907, 0.974, 0.974);   // (244, 252, 252)
const OPC_CRISTAL_REPISA_TONO_B: vec3<f32> = vec3<f32>(1.000, 1.000, 1.000);   // (255, 255, 255)
// Alias temporales para compatibilidad durante los pasos intermedios de N-09:
const OPC_CRISTAL_ESCARCHA_COLOR: vec3<f32> = vec3<f32>(0.842, 0.924, 1.000);
const OPC_CRISTAL_ESCARCHA_OPACIDAD: f32 = 0.85;
const OPC_CRISTAL_ESCARCHA_DESENFOQUE: f32 = 0.010;
const OPC_CRISTAL_ESCARCHA_CIELO_MIN: f32 = 0.68;
const OPC_CRISTAL_ESCARCHA_CIELO_MAX: f32 = 0.88;
const OPC_CRISTAL_ESCARCHA_INT_PESO: f32 = 0.65;
const OPC_CRISTAL_ESCARCHA_ALCANCE: f32 = 0.24;
const OPC_CRISTAL_ESCARCHA_ESQUINA: f32 = 0.34;
const OPC_CRISTAL_ESCARCHA_JUNTA_PESO: f32 = 0.22;
const OPC_CRISTAL_ESCARCHA_TEMP_NIEVE: f32 = 0.15;
const OPC_CRISTAL_ESCARCHA_INTERIOR: bool = true;

// Paleta de copos pegados (27 §Capa 3, sRGB -> lineal ^2,2).
const OPC_CRISTAL_COPO_BLANCO: vec3<f32> = vec3<f32>(1.000, 1.000, 1.000);     // (255, 255, 255)
const OPC_CRISTAL_COPO_SUAVE: vec3<f32> = vec3<f32>(0.842, 0.957, 0.966);      // (236, 250, 251)
const OPC_CRISTAL_COPO_HIELO: vec3<f32> = vec3<f32>(0.511, 0.680, 1.000);      // (188, 214, 255)
const OPC_CRISTAL_NIEVE_COLOR: vec3<f32> = vec3<f32>(0.92, 0.95, 1.0);
const OPC_CRISTAL_NIEVE_MONTON_MIN: f32 = 3.0;
const OPC_CRISTAL_NIEVE_MONTON_MAX: f32 = 5.0;
const OPC_CRISTAL_NIEVE_JUNTA_PESO: f32 = 0.0;
const OPC_CRISTAL_NIEVE_OPACIDAD_COPO: f32 = 0.90;
const OPC_CRISTAL_NIEVE_OPACIDAD_MONTON: f32 = 0.96;

// Paletas de 5 tonos de arena (27 §Capa 4, sRGB -> lineal ^2,2).
const OPC_CRISTAL_ARENA_0: vec3<f32> = vec3<f32>(0.716, 0.632, 0.373);         // (219, 207, 163)
const OPC_CRISTAL_ARENA_1: vec3<f32> = vec3<f32>(0.673, 0.561, 0.311);         // (213, 196, 150)
const OPC_CRISTAL_ARENA_2: vec3<f32> = vec3<f32>(0.774, 0.708, 0.442);         // (227, 218, 176)
const OPC_CRISTAL_ARENA_3: vec3<f32> = vec3<f32>(0.587, 0.470, 0.234);         // (200, 181, 132)
const OPC_CRISTAL_ARENA_4: vec3<f32> = vec3<f32>(0.442, 0.330, 0.145);         // (176, 154, 106)
const OPC_CRISTAL_ARENA_ROJA_0: vec3<f32> = vec3<f32>(0.529, 0.136, 0.011);    // (191, 103, 33)
const OPC_CRISTAL_ARENA_ROJA_1: vec3<f32> = vec3<f32>(0.453, 0.117, 0.010);    // (178, 96, 31)
const OPC_CRISTAL_ARENA_ROJA_2: vec3<f32> = vec3<f32>(0.619, 0.167, 0.017);    // (205, 113, 40)
const OPC_CRISTAL_ARENA_ROJA_3: vec3<f32> = vec3<f32>(0.358, 0.087, 0.009);    // (160, 84, 30)
const OPC_CRISTAL_ARENA_ROJA_4: vec3<f32> = vec3<f32>(0.234, 0.058, 0.007);    // (132, 70, 26)
const OPC_CRISTAL_ARENA_BARLOVENTO: f32 = 0.30;
const OPC_CRISTAL_ARENA_VELO_MAX: f32 = 0.52;
const OPC_CRISTAL_ARENA_GRANO_PESO: f32 = 0.24;
const OPC_CRISTAL_ARENA_COLOR_AMARILLA: vec3<f32> = vec3<f32>(0.716, 0.632, 0.373);
const OPC_CRISTAL_ARENA_COLOR_ROJA: vec3<f32> = vec3<f32>(0.529, 0.136, 0.011);

// Condensación interior y vaho del aliento (27 §Capas 5 y 6, sRGB -> lineal ^2,2).
const OPC_CRISTAL_COND_COLOR: vec3<f32> = vec3<f32>(0.811, 0.874, 0.924);      // (232, 240, 246)
const OPC_CRISTAL_ALIENTO_ACTIVO: bool = true;
const OPC_CRISTAL_VAHO_DIST: f32 = 1.5;
const OPC_CRISTAL_VAHO_SEMI_X: f32 = 0.26;       // elipse 0,26 x 0,22 bloques
const OPC_CRISTAL_VAHO_SEMI_Y: f32 = 0.22;
const OPC_CRISTAL_VAHO_RADIO: f32 = 0.26;
const OPC_CRISTAL_VAHO_PERIODO: f32 = 3.3;
const OPC_CRISTAL_VAHO_COLOR: vec3<f32> = vec3<f32>(1.000, 1.000, 1.000);
const OPC_CRISTAL_VAHO_OPACIDAD: f32 = 0.62;

// Desenfoque detrás del cristal empañado (27 §Capa 7).
const OPC_CRISTAL_BLUR_UMBRAL_LUZ: f32 = 0.04;
const OPC_CRISTAL_BLUR_CONSERVA_LUZ: f32 = 0.80;

// Multiplicador de intensidad de lluvia/nieve (27 §Opciones: apagado / poca 0,5 / normal 1 / mucha 1,7).
fn opc_cristal_escala_lluvia(codigo: u32) -> f32 {
    switch codigo {
        case 0u: { return 0.0; }
        case 1u: { return 0.5; }
        case 2u: { return 1.0; }
        default: { return 1.7; }
    }
}

// Multiplicador de intensidad de arena (27 §Opciones: apagado / poca 0,5 / normal 1 / mucha 1,4).
fn opc_cristal_escala_arena(codigo: u32) -> f32 {
    switch codigo {
        case 0u: { return 0.0; }
        case 1u: { return 0.5; }
        case 2u: { return 1.0; }
        default: { return 1.4; }
    }
}

// Factor de escala `k = texeles / 32` desde el código de resolución (0=16, 1=32, 2=64).
fn opc_cristal_k_resolucion(codigo: u32) -> f32 {
    switch codigo {
        case 0u: { return 0.5; }
        case 2u: { return 2.0; }
        default: { return 1.0; }
    }
}
