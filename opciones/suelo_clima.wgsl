// Constantes del suelo con el clima según el bioma (escarcha en nieve, arena movida en desierto).
// Sin opciones nuevas en el menú (64/64). Porqué: docs/efectos/suelo-clima.md §Constantes

const OPC_SUELO_REJILLA: f32 = 32.0;                        // texeles por bloque (27 §«Detalle: 32 texeles por bloque»)

// Escarcha en biomas nevados (caras superiores expuestas al cielo).
const OPC_ESCARCHA_COLOR: vec3<f32> = vec3<f32>(0.84, 0.92, 1.0);
const OPC_ESCARCHA_VELO: f32 = 0.22;                        // aclarado frío sutil sobre la superficie
const OPC_ESCARCHA_MOTA_UMBRAL: f32 = 0.87;                 // ~13 % de texeles de la rejilla de 32 con mota cristalina
const OPC_ESCARCHA_MOTA_ALBEDO: f32 = 0.35;                 // blanqueado de la mota
const OPC_ESCARCHA_MOTA_SUAVIDAD: f32 = 0.90;               // suavidad especular de la mota
const OPC_ESCARCHA_MOTA_F0: f32 = 0.08;                     // F0 del cristal de hielo
const OPC_ESCARCHA_INCLINACION: f32 = 0.55;                 // inclinación máxima de microfacetas
const OPC_ESCARCHA_EXPONENTE: f32 = 28.0;                   // nitidez del destello especular
const OPC_ESCARCHA_DESTELLO: f32 = 2.2;                     // brillo del destello con la luz recibida
const OPC_ESCARCHA_DIST_INICIO: f32 = 20.0;                 // bloques: inicio de atenuación de destellos
const OPC_ESCARCHA_DIST_FIN: f32 = 52.0;                    // bloques: fin de atenuación

// Granos de arena movidos por el viento en biomas desérticos (caras superiores de arena).
const OPC_ARENA_ANCHO: f32 = 4.5;                           // espaciado medio en texeles de 32 (rango 3–6)
const OPC_ARENA_LARGO: f32 = 14.0;                          // alargamiento a lo largo del viento, texeles de 32
const OPC_ARENA_MEANDRO_ESCALA: vec2<f32> = vec2<f32>(0.035, 0.075);
const OPC_ARENA_MEANDRO_AMP: f32 = 0.45;
const OPC_ARENA_VELOCIDAD_MIN: f32 = 6.0;                   // texeles de 32 / s en nivel 1
const OPC_ARENA_VELOCIDAD_MAX: f32 = 15.0;                  // texeles de 32 / s en nivel 10
const OPC_ARENA_NIVEL_MIN: f32 = 0.45;                      // intensidad relativa en nivel 1
const OPC_ARENA_NIVEL_MAX: f32 = 1.0;                       // intensidad relativa en nivel 10
const OPC_ARENA_CONTRASTE: f32 = 0.30;                      // modulación de brillo en el albedo
const OPC_ARENA_RELIEVE: f32 = 0.42;                        // perturbación de normal de las ondulaciones
const OPC_ARENA_DIST_INICIO: f32 = 24.0;                    // bloques: inicio de atenuación
const OPC_ARENA_DIST_FIN: f32 = 64.0;                       // bloques: fin de atenuación

fn opc_escarcha() -> SupParamEscarcha {
    return SupParamEscarcha(
        OPC_SUELO_REJILLA,
        OPC_ESCARCHA_COLOR,
        OPC_ESCARCHA_VELO,
        OPC_ESCARCHA_MOTA_UMBRAL,
        OPC_ESCARCHA_MOTA_ALBEDO,
        OPC_ESCARCHA_MOTA_SUAVIDAD,
        OPC_ESCARCHA_MOTA_F0,
        OPC_ESCARCHA_INCLINACION,
        OPC_ESCARCHA_EXPONENTE,
        OPC_ESCARCHA_DESTELLO,
        OPC_ESCARCHA_DIST_INICIO,
        OPC_ESCARCHA_DIST_FIN,
    );
}

fn opc_arena_viento() -> SupParamArenaViento {
    return SupParamArenaViento(
        OPC_SUELO_REJILLA,
        OPC_ARENA_ANCHO,
        OPC_ARENA_LARGO,
        OPC_ARENA_MEANDRO_ESCALA,
        OPC_ARENA_MEANDRO_AMP,
        OPC_ARENA_VELOCIDAD_MIN,
        OPC_ARENA_VELOCIDAD_MAX,
        OPC_ARENA_NIVEL_MIN,
        OPC_ARENA_NIVEL_MAX,
        OPC_ARENA_CONTRASTE,
        OPC_ARENA_RELIEVE,
        OPC_ARENA_DIST_INICIO,
        OPC_ARENA_DIST_FIN,
    );
}
