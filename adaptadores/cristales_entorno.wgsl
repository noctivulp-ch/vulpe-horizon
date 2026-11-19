// Lectura del entorno por cara de cristal desde la caché 3D `cristal_mapa` (sin ray queries en [material]).
// Respaldo automático (opción d) fuera de los ±24/±12 bloques de la caché o en GPUs sin ray queries.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §Arquitectura y coste

fn adp_cristal_entorno(
    p: AdpPunto,
    plano: SupCristalPlano,
    bioma_frio: bool,
    _necesita_bordes: bool,
    _necesita_dist_marco: bool,
) -> AdpCristalEntorno {
    var r = AdpCristalEntorno(false, false, false, false, false, false, 0u, vec4<f32>(0.0));
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
            return adp_cm_decodificar_entorno(w0, w1, n, plano.vertical, bioma_frio);
        }
    }

    // Respaldo (opción d): luz de cielo de la cara y oclusión de vértice fuera de caché o sin RT.
    r.llega_cielo = p.luz_cielo >= OPC_CRISTAL_CIELO_MIN;
    r.es_exterior = p.luz_cielo >= 0.72;
    r.es_interior = !r.es_exterior && p.luz_cielo >= 0.35;
    r.opuesta_llega_cielo = r.es_interior;
    r.es_interior_fria = bioma_frio && r.es_interior;
    let marco_ao = p.ao_vertice < 0.96;
    r.bordes = select(0u, 15u, marco_ao);
    r.dist_marco = select(vec4<f32>(2.0), vec4<f32>(0.0), marco_ao);
    return r;
}
