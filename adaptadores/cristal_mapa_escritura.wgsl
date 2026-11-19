// Escritura incremental en [[before_world]] de la caché toroidal `cristal_mapa` usando ray queries (opción b).
// Solo sondea bloques con cristal: en un bosque sin cristales cada vóxel se descarta en 2 rayos cortos de 0,96 bloques.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §Arquitectura y coste

// Detecta si el vóxel `b` contiene un bloque o panel de cristal (tag `OPC_TAG_CRISTAL`).
fn adp_cm_contiene_cristal(b: vec3<i32>) -> bool {
    let base = vec3<f32>(b) - frame.camera_position;
    let h1 = trace_layers(base + vec3<f32>(0.02, 0.5, 0.5), vec3<f32>(1.0, 0.0, 0.0), 0.96, RAY_TRANSLUCENT);
    if h1.distance >= 0.0 && (h1.tags & OPC_TAG_CRISTAL) != 0u {
        return true;
    }
    let h2 = trace_layers(base + vec3<f32>(0.5, 0.5, 0.02), vec3<f32>(0.0, 0.0, 1.0), 0.96, RAY_TRANSLUCENT);
    return h2.distance >= 0.0 && (h2.tags & OPC_TAG_CRISTAL) != 0u;
}

// Busca la distancia (1..8 bloques, o 9 si no llega) al primer punto bajo cielo abierto en dirección `dir`.
fn adp_cm_dist_cielo(centro_cam: vec3<f32>, dir: vec3<f32>) -> i32 {
    var actual = centro_cam;
    for (var paso = 1; paso <= 8; paso++) {
        if paso == 1 {
            if trace_any_layers(actual + dir * 0.52, dir, 0.45, RAY_SOLID | RAY_TRANSLUCENT) {
                return 9;
            }
        } else {
            if trace_any_layers(actual, dir, 1.0, RAY_SOLID | RAY_TRANSLUCENT) {
                return 9;
            }
        }
        actual += dir;
        if !trace_any_layers(actual, vec3<f32>(0.0, 1.0, 0.0), 64.0, RAY_SOLID) {
            return paso;
        }
    }
    return 9;
}

// Evalúa los 4 bits [cerrada, llega_cielo, exterior, interior] de una cara horizontal de `b` con normal `n`.
fn adp_cm_evaluar_cara(centro_cam: vec3<f32>, n: vec3<f32>) -> u32 {
    let cerrada = trace_any_layers(centro_cam + n * 0.52, n, 0.44, RAY_SOLID | RAY_TRANSLUCENT);
    var llega_cielo = false;
    var dist_frente = 9;
    if !cerrada {
        var c_low = centro_cam + n;
        var c_high = c_low + vec3<f32>(0.0, 1.0, 0.0);
        for (var paso = 0; paso < 3; paso++) {
            var wall_low = false;
            var wall_high = false;
            if paso > 0 {
                wall_low = trace_any_layers(c_low - n, n, 1.0, RAY_SOLID | RAY_TRANSLUCENT);
                wall_high = trace_any_layers(c_high - n, n, 1.0, RAY_SOLID | RAY_TRANSLUCENT);
                if wall_low && wall_high {
                    break;
                }
            }
            let cielo_low = !wall_low && !trace_any_layers(c_low, vec3<f32>(0.0, 1.0, 0.0), 64.0, RAY_SOLID);
            let cielo_high = !wall_high && !trace_any_layers(c_high, vec3<f32>(0.0, 1.0, 0.0), 64.0, RAY_SOLID);
            if cielo_low || cielo_high {
                llega_cielo = true;
                dist_frente = paso + 1;
                break;
            }
            c_low += n;
            c_high += n;
        }
    }

    var es_exterior = false;
    var es_interior = false;
    if dist_frente == 1 {
        es_exterior = true;
    } else {
        if !cerrada && dist_frente > 8 {
            dist_frente = adp_cm_dist_cielo(centro_cam, n);
        }
        let dist_atras = adp_cm_dist_cielo(centro_cam, -n);
        es_exterior = (dist_frente <= 8) && (dist_frente <= dist_atras);
        es_interior = !es_exterior && (dist_atras <= 8);
    }

    var bits = 0u;
    if cerrada { bits |= 1u; }
    if llega_cielo { bits |= 2u; }
    if es_exterior { bits |= 4u; }
    if es_interior { bits |= 8u; }
    return bits;
}

// Distancia en bloques (0..7) hasta el borde del conjunto de cristales en dirección `paso`.
fn adp_cm_dist_marco(b: vec3<i32>, paso: vec3<i32>) -> u32 {
    for (var k = 1; k <= 7; k++) {
        if !adp_cm_contiene_cristal(b + paso * k) {
            return u32(k - 1);
        }
    }
    return 7u;
}

fn adp_cristal_mapa_actualizar(cell: vec3<u32>) {
    if !OPC_CRISTAL_ACTIVO || !adp_es_superficie() || frame.has_ray_tracing == 0u {
        return;
    }
    // Solo actualizamos cuando hay algún efecto de cristal potencialmente activo (o mientras la caché se calienta).
    let c0 = datos_cuadro[ADP_CUADRO_CRISTAL_0];
    let c2 = datos_cuadro[ADP_CUADRO_CRISTAL_2];
    let cv = datos_cuadro[ADP_CUADRO_CRISTAL_VAHO];
    let activo = (c0.x > OPC_CRISTAL_CLIMA_UMBRAL) || (c0.y > 0.001) || (c0.z > 0.001)
               || (c0.w > 0.001) || (c2.x > OPC_CRISTAL_ARENA_MIN) || (cv.w > 0.001);
    if !activo {
        return;
    }

    let cam_b = vec3<i32>(floor(frame.camera_position));
    let origen = cam_b - vec3<i32>(ADP_CM_SX / 2, ADP_CM_SY / 2, ADP_CM_SZ / 2);

    // Cada fotograma procesamos 2 planos Z (dispatch [48, 24, 2] = 2 304 vóxeles; ciclo completo en 24 cuadros).
    let z_base = i32((frame.frame_index * 2u) % u32(ADP_CM_SZ));
    let lz = (z_base + i32(cell.z)) % ADP_CM_SZ;
    let b = origen + vec3<i32>(i32(cell.x), i32(cell.y), lz);
    let idx = adp_cm_indice(b);
    let firma = adp_cm_firma_bloque(b);

    let es_cristal = adp_cm_contiene_cristal(b);
    if !es_cristal {
        cristal_mapa[idx] = ADP_CM_BIT_VALIDO;
        cristal_mapa[idx + 1u] = firma << 24u;
        return;
    }

    let centro_cam = (vec3<f32>(b) + vec3<f32>(0.5)) - frame.camera_position;
    let d_py = adp_cm_dist_marco(b, vec3<i32>(0, 1, 0));
    let d_ny = adp_cm_dist_marco(b, vec3<i32>(0, -1, 0));
    let d_nx = adp_cm_dist_marco(b, vec3<i32>(-1, 0, 0));
    let d_px = adp_cm_dist_marco(b, vec3<i32>(1, 0, 0));
    let d_nz = adp_cm_dist_marco(b, vec3<i32>(0, 0, -1));
    let d_pz = adp_cm_dist_marco(b, vec3<i32>(0, 0, 1));

    var bordes_z = 0u;
    if d_py == 0u { bordes_z |= 1u; }
    if d_ny == 0u { bordes_z |= 2u; }
    if d_nx == 0u { bordes_z |= 4u; }
    if d_px == 0u { bordes_z |= 8u; }

    var bordes_x = 0u;
    if d_py == 0u { bordes_x |= 1u; }
    if d_ny == 0u { bordes_x |= 2u; }
    if d_nz == 0u { bordes_x |= 4u; }
    if d_pz == 0u { bordes_x |= 8u; }

    let c_n = adp_cm_evaluar_cara(centro_cam, vec3<f32>(0.0, 0.0, -1.0));
    let c_s = adp_cm_evaluar_cara(centro_cam, vec3<f32>(0.0, 0.0, 1.0));
    let c_w = adp_cm_evaluar_cara(centro_cam, vec3<f32>(-1.0, 0.0, 0.0));
    let c_e = adp_cm_evaluar_cara(centro_cam, vec3<f32>(1.0, 0.0, 0.0));
    let cielo_arriba = !trace_any_layers(centro_cam + vec3<f32>(0.0, 0.55, 0.0), vec3<f32>(0.0, 1.0, 0.0), 64.0, RAY_SOLID);

    let w0 = bordes_z
           | (bordes_x << 4u)
           | (c_n << 8u)
           | (c_s << 12u)
           | (c_w << 16u)
           | (c_e << 20u)
           | select(0u, ADP_CM_BIT_ARRIBA_CIELO, cielo_arriba)
           | ADP_CM_BIT_ES_CRISTAL
           | ADP_CM_BIT_VALIDO;

    let w1 = (d_py & 15u)
           | ((d_ny & 15u) << 4u)
           | ((d_nx & 15u) << 8u)
           | ((d_px & 15u) << 12u)
           | ((d_nz & 15u) << 16u)
           | ((d_pz & 15u) << 20u)
           | (firma << 24u);

    cristal_mapa[idx] = w0;
    cristal_mapa[idx + 1u] = w1;
}
