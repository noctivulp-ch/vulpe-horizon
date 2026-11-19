// Índices del buffer por fotograma (`datos_cuadro`, 32 vec4<f32> = 512 bytes) y struct de luces.
// Compartido (sin referenciar el recurso, para que vertex y displacement no lo toquen).
// Porqué: docs/rendimiento.md

struct AdpLuces {
    fija: bool,             // ambiente de dimensión (17): no depende de la luz de cielo de Minecraft
    direccion: vec3<f32>,   // hacia el astro que da sombra (sol de día, luna de noche)
    directa: vec3<f32>,     // irradiancia perpendicular tras la atmósfera (π = sol de mediodía)
    cielo: vec3<f32>,       // radiancia media del cielo (ambiente)
    suelo: vec3<f32>,
}

const ADP_CUADRO_LUZ_DIR: u32 = 0u;      // xyz: direccion, w: fija (0/1)
const ADP_CUADRO_LUZ_DIRECTA: u32 = 1u;  // xyz: directa, w: elev_sol (grados)
const ADP_CUADRO_LUZ_CIELO: u32 = 2u;    // xyz: cielo
const ADP_CUADRO_LUZ_SUELO: u32 = 3u;    // xyz: suelo
const ADP_CUADRO_HORIZONTE: u32 = 4u;    // xyz: adp_tabla(sun.y, HORIZONTE) * sol_color
const ADP_CUADRO_CIELO_MEDIO: u32 = 5u;  // xyz: adp_cielo_medio(c)
const ADP_CUADRO_NUBES_COB: u32 = 6u;    // xyz: perfil.cobertura
const ADP_CUADRO_NUBES_DENS: u32 = 7u;   // xyz: perfil.densidad
const ADP_CUADRO_VOL_CIELO: u32 = 8u;    // xyz: ambiente de cielo despejado * eye_light_smooth.y, w: relámpago activo (este o anterior)
const ADP_CUADRO_VOL_DIRECTA: u32 = 9u;  // xyz: adp_irradiancia_astro(c)
const ADP_CUADRO_SUELO_RAW: u32 = 10u;   // xyz: adp_suelo(c)
const ADP_CUADRO_SOL_MULT: u32 = 11u;    // xyz: adp_luz_sol(c).multiple
const ADP_CUADRO_LUNA_MULT: u32 = 12u;   // xyz: adp_luz_luna(c).multiple, w: peso_luna
const ADP_CUADRO_SOL_DISCO: u32 = 13u;   // xyz: atm_luz_directa_sol(elev_sol) * sol_color
const ADP_CUADRO_HORARIO: u32 = 14u;     // xy: horario (uniforme, manchas), z: clima.tipo, w: clima.peso
const ADP_CUADRO_RELAMPAGO: u32 = 15u;   // xyz: relampago.base, w: relampago.brillo
const ADP_CUADRO_CRUCE: u32 = 16u;       // x: t en segundos (<0 sin cruce), y: rapidez con signo (+salida/-entrada), z: dentro_antes (0/1), w: firma dimensión+10
const ADP_CUADRO_CRISTAL_0: u32 = 17u;        // x: clima, y: escarcha, z: repisa, w: condensacion
const ADP_CUADRO_CRISTAL_1: u32 = 18u;        // xy: viento_lluvia (tau 1 s), zw: viento_arena (tau 5 s)
const ADP_CUADRO_CRISTAL_2: u32 = 19u;        // x: arena, y: escala_lluvia, z: escala_nieve, w: escala_arena
const ADP_CUADRO_CRISTAL_VAHO: u32 = 20u;     // xyz: pos relativa de vaho, w: peso (<0 desactivado/espectador)
const ADP_CUADRO_CRISTAL_FLAGS: u32 = 21u;    // x: flags24, y: cond_opacidad, z: cond_blancura, w: vaho_escala
const ADP_CUADRO_CRISTAL_VAHO_OPT: u32 = 22u; // x: aliento_opacidad, y: aliento_blancura, z: resolucion_k, w: con_mod
