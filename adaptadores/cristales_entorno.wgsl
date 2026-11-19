// Lectura del entorno por cara de cristal desde la caché 3D `cristal_mapa` (sin ray queries en [material]).
// Respaldo automático (opción d) fuera de los ±24/±12 bloques de la caché o en GPUs sin ray queries.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §Arquitectura y coste

const ADP_CR_BORDE_ARRIBA: u32 = 1u << 0u;
const ADP_CR_BORDE_ABAJO: u32 = 1u << 1u;
const ADP_CR_BORDE_IZQ: u32 = 1u << 2u;
const ADP_CR_BORDE_DER: u32 = 1u << 3u;

struct AdpCristalEntorno {
    cerrada: bool,           // bloque macizo u otro cristal justo delante
    llega_cielo: bool,       // alcanza el cielo en <= 3 bloques (o justo encima en cara superior)
    es_exterior: bool,       // distancia al cielo por delante <= 8 y <= que por detrás
    es_interior: bool,       // no es exterior y el lado opuesto alcanza el cielo en <= 8 bloques
    es_interior_fria: bool,  // bioma frío + es_interior
    bordes: u32,             // máscara de 4 bits (arriba, abajo, izq, der): 1 si el vecino NO es cristal
    dist_marco: vec4<f32>,   // distancia en bloques al marco de la ventana (arriba, abajo, izq, der; 0..7)
}

fn adp_cristal_entorno(
    p: AdpPunto,
    plano: SupCristalPlano,
    bioma_frio: bool,
    _necesita_bordes: bool,
    _necesita_dist_marco: bool,
) -> AdpCristalEntorno {
    var r = AdpCristalEntorno(false, false, false, false, false, 0u, vec4<f32>(0.0));
    let n = p.normal_cara;

    let b = vec3<i32>(floor(p.mundo - n * 0.02));
    let cam_b = vec3<i32>(floor(frame.camera_position));
    let rel = b - cam_b;
    let en_rango = abs(rel.x) < (ADP_CM_SX / 2) && abs(rel.y) < (ADP_CM_SY / 2) && abs(rel.z) < (ADP_CM_SZ / 2);

    if frame.has_ray_tracing != 0u && en_rango {
        let idx = adp_cm_indice(b);
        let w0 = cristal_mapa[idx];
        let w1 = cristal_mapa[idx + 1u];
        let firma_ok = ((w1 >> 24u) & 255u) == adp_cm_firma_bloque(b);
        if firma_ok && (w0 & ADP_CM_BIT_VALIDO) != 0u && (w0 & ADP_CM_BIT_ES_CRISTAL) != 0u {
            if !plano.vertical {
                if n.y > 0.5 {
                    r.llega_cielo = (w0 & ADP_CM_BIT_ARRIBA_CIELO) != 0u;
                    r.es_exterior = r.llega_cielo;
                }
                return r;
            }

            // Extrae los 4 bits [cerrada, llega_cielo, exterior, interior] de la cara según su normal.
            var cara_bits = 0u;
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
                bordes_raw = w0 & 15u; // bit 0 +Y, 1 -Y, 2 -X, 3 +X
                // Tangente t = cross((0,1,0), n): para +Z es (+1,0,0), para -Z es (-1,0,0).
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
                bordes_raw = (w0 >> 4u) & 15u; // bit 0 +Y, 1 -Y, 2 -Z, 3 +Z
                // Tangente t = cross((0,1,0), n): para +X es (0,0,-1), para -X es (0,0,+1).
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
            r.es_exterior = (cara_bits & 4u) != 0u;
            r.es_interior = (cara_bits & 8u) != 0u;
            r.es_interior_fria = bioma_frio && r.es_interior;
            r.dist_marco = vec4<f32>(d_arr, d_aba, d_izq, d_der);
            return r;
        }
    }

    // Respaldo (opción d): luz de cielo de la cara y oclusión de vértice fuera de caché o sin RT.
    r.llega_cielo = p.luz_cielo >= OPC_CRISTAL_CIELO_MIN;
    r.es_exterior = p.luz_cielo >= 0.72;
    r.es_interior = !r.es_exterior && p.luz_cielo >= 0.35;
    r.es_interior_fria = bioma_frio && r.es_interior;
    let marco_ao = p.ao_vertice < 0.96;
    r.bordes = select(0u, 15u, marco_ao);
    r.dist_marco = select(vec4<f32>(2.0), vec4<f32>(0.0), marco_ao);
    return r;
}
