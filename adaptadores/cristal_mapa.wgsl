// Caché espacial 3D toroidal de caras de cristal (48 x 24 x 48 bloques alrededor de la cámara).
// Se actualiza en [[before_world]] con ray queries (API 0.2), dejando [material] libre de ray queries
// (sin penalizar el sombreado del terreno en escenas sin cristal).
// Porqué: docs/efectos/tiempo-en-los-cristales.md §Arquitectura y coste

const ADP_CM_SX: i32 = 48;
const ADP_CM_SY: i32 = 24;
const ADP_CM_SZ: i32 = 48;
const ADP_CM_VOXELES: u32 = 55296u; // 48 * 24 * 48
const ADP_CM_CABECERA: u32 = 4u;    // u32 reservados (0: epoch/estado)

// Bits de la palabra 0 por vóxel:
//  0..3  : bordes_z (+Y, -Y, -X, +X) para caras N/S
//  4..7  : bordes_x (+Y, -Y, -Z, +Z) para caras W/E
//  8..11 : cara 0 (-Z, Norte) [cerrada, llega_cielo, exterior, interior]
// 12..15 : cara 1 (+Z, Sur)   [cerrada, llega_cielo, exterior, interior]
// 16..19 : cara 2 (-X, Oeste) [cerrada, llega_cielo, exterior, interior]
// 20..23 : cara 3 (+X, Este)  [cerrada, llega_cielo, exterior, interior]
// 24     : cara 4 (+Y, Arriba) llega_cielo
// 25     : es_cristal
// 26     : valido
const ADP_CM_BIT_ARRIBA_CIELO: u32 = 1u << 24u;
const ADP_CM_BIT_ES_CRISTAL: u32 = 1u << 25u;
const ADP_CM_BIT_VALIDO: u32 = 1u << 26u;

fn adp_cm_mod(a: i32, m: i32) -> u32 {
    let r = a % m;
    return u32(select(r, r + m, r < 0));
}

fn adp_cm_indice(b: vec3<i32>) -> u32 {
    let ix = adp_cm_mod(b.x, ADP_CM_SX);
    let iy = adp_cm_mod(b.y, ADP_CM_SY);
    let iz = adp_cm_mod(b.z, ADP_CM_SZ);
    return ADP_CM_CABECERA + ((iy * u32(ADP_CM_SZ) + iz) * u32(ADP_CM_SX) + ix) * 2u;
}

// Firma de 8 bits de la coordenada entera del bloque para detectar ranuras obsoletas al moverse.
fn adp_cm_firma_bloque(b: vec3<i32>) -> u32 {
    let ux = u32(b.x * 73856093);
    let uy = u32(b.y * 19349663);
    let uz = u32(b.z * 83492791);
    let h = (ux ^ uy ^ uz) & 255u;
    return select(h, 1u, h == 0u);
}
