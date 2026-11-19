// Caché espacial 3D toroidal de caras de cristal (48 x 24 x 48 bloques alrededor de la cámara).
// Se actualiza en [[before_world]] con ray queries (API 0.2), dejando [material] libre de ray queries
// (sin penalizar el sombreado del terreno en escenas sin cristal).
// Porqué: docs/efectos/tiempo-en-los-cristales.md §Arquitectura y coste

const ADP_CM_SX: i32 = 48;
const ADP_CM_SY: i32 = 24;
const ADP_CM_SZ: i32 = 48;
const ADP_CM_VOXELES: u32 = 55296u; // 48 * 24 * 48
const ADP_CM_CABECERA: u32 = 4u;    // u32 reservados (0: epoch/estado)
const ADP_CM_META_OFF: u32 = 110596u; // 4 + 55296 * 2: 1 728 indicadores por workgroup (6 * 6 * 48)
const ADP_CM_META_TILES: u32 = 1728u;

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
// 27     : es_claro (`block/glass` o `block/glass_pane_top`, dibujado en pasada post DDA)
// 28     : es_panel (panel fino de cristal)
// 29     : panel_x (panel con brazo a lo largo de X, caras +-Z)
// 30     : panel_z (panel con brazo a lo largo de Z, caras +-X)
const ADP_CM_BIT_ARRIBA_CIELO: u32 = 1u << 24u;
const ADP_CM_BIT_ES_CRISTAL: u32 = 1u << 25u;
const ADP_CM_BIT_VALIDO: u32 = 1u << 26u;
const ADP_CM_BIT_CLARO: u32 = 1u << 27u;
const ADP_CM_BIT_PANEL: u32 = 1u << 28u;
const ADP_CM_BIT_PANEL_X: u32 = 1u << 29u;
const ADP_CM_BIT_PANEL_Z: u32 = 1u << 30u;

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

const ADP_CR_BORDE_ARRIBA: u32 = 1u << 0u;
const ADP_CR_BORDE_ABAJO: u32 = 1u << 1u;
const ADP_CR_BORDE_IZQ: u32 = 1u << 2u;
const ADP_CR_BORDE_DER: u32 = 1u << 3u;

struct AdpCristalEntorno {
    cerrada: bool,              // bloque macizo u otro cristal justo delante
    llega_cielo: bool,          // alcanza el cielo en <= 3 bloques (o justo encima en cara superior)
    opuesta_llega_cielo: bool,  // la cara opuesta de esta ventana recibe cielo (visible desde dentro)
    es_exterior: bool,          // distancia al cielo por delante <= 8 y <= que por detrás
    es_interior: bool,          // no es exterior y el lado opuesto alcanza el cielo en <= 8 bloques
    es_interior_fria: bool,     // bioma frío + es_interior
    bordes: u32,                // máscara de 4 bits (arriba, abajo, izq, der): 1 si el vecino NO es cristal
    dist_marco: vec4<f32>,      // distancia en bloques al marco de la ventana (arriba, abajo, izq, der; 0..7)
}

fn adp_cm_decodificar_entorno(
    w0: u32,
    w1: u32,
    n: vec3<f32>,
    vertical: bool,
    bioma_frio: bool,
) -> AdpCristalEntorno {
    var r = AdpCristalEntorno(false, false, false, false, false, false, 0u, vec4<f32>(0.0));
    if !vertical {
        if n.y > 0.5 {
            r.llega_cielo = (w0 & ADP_CM_BIT_ARRIBA_CIELO) != 0u;
            r.es_exterior = r.llega_cielo;
        }
        return r;
    }

    var cara_bits = 0u;
    var opuesta_bits = 0u;
    var bordes_raw = 0u;
    var d_izq = 0.0;
    var d_der = 0.0;
    let d_arr = f32(w1 & 15u);
    let d_aba = f32((w1 >> 4u) & 15u);
    let d_nx = f32((w1 >> 8u) & 15u);
    let d_px = f32((w1 >> 12u) & 15u);
    let d_nz = f32((w1 >> 16u) & 15u);
    let d_pz = f32((w1 >> 20u) & 15u);

    if abs(n.z) > 0.5 {
        let es_sur = n.z > 0.0;
        cara_bits = select((w0 >> 8u) & 15u, (w0 >> 12u) & 15u, es_sur);
        opuesta_bits = select((w0 >> 12u) & 15u, (w0 >> 8u) & 15u, es_sur);
        bordes_raw = w0 & 15u; // bit 0 +Y, 1 -Y, 2 -X, 3 +X
        if es_sur {
            r.bordes = bordes_raw;
            d_izq = d_nx;
            d_der = d_px;
        } else {
            r.bordes = (bordes_raw & 3u) | select(0u, 4u, (bordes_raw & 8u) != 0u) | select(0u, 8u, (bordes_raw & 4u) != 0u);
            d_izq = d_px;
            d_der = d_nx;
        }
    } else {
        let es_este = n.x > 0.0;
        cara_bits = select((w0 >> 16u) & 15u, (w0 >> 20u) & 15u, es_este);
        opuesta_bits = select((w0 >> 20u) & 15u, (w0 >> 16u) & 15u, es_este);
        bordes_raw = (w0 >> 4u) & 15u; // bit 0 +Y, 1 -Y, 2 -Z, 3 +Z
        if es_este {
            r.bordes = (bordes_raw & 3u) | select(0u, 4u, (bordes_raw & 8u) != 0u) | select(0u, 8u, (bordes_raw & 4u) != 0u);
            d_izq = d_pz;
            d_der = d_nz;
        } else {
            r.bordes = bordes_raw;
            d_izq = d_nz;
            d_der = d_pz;
        }
    }

    r.cerrada = (cara_bits & 1u) != 0u;
    r.llega_cielo = (cara_bits & 2u) != 0u;
    r.opuesta_llega_cielo = (opuesta_bits & 2u) != 0u;
    r.es_exterior = (cara_bits & 4u) != 0u;
    r.es_interior = (cara_bits & 8u) != 0u;
    r.es_interior_fria = bioma_frio && r.es_interior;
    r.dist_marco = vec4<f32>(d_arr, d_aba, d_izq, d_der);
    return r;
}
