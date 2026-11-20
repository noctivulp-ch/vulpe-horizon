// Escritura incremental en [[before_world]] de la caché toroidal `cristal_mapa` usando ray queries (opción b).
// Sondea el borde opaco de 1 píxel (y=0,03 en caras verticales, x=0,03 arriba/abajo) para detectar tanto cristales
// tintados/ahumados como cristal transparente (`glass`, `glass_pane`) y orientación de brazos del panel.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §Arquitectura y coste

var<workgroup> adp_cm_wg_claro: array<u32, 32>;

// Comprueba si el vóxel `b` contiene algún cristal (bloque o panel, transparente o tintado).
fn adp_cm_contiene_cristal(b: vec3<i32>) -> bool {
    let base_v = (vec3<f32>(b) + vec3<f32>(0.5, 0.03, 0.5)) - frame.camera_position;
    let dirs_v = array<vec3<f32>, 4>(
        vec3<f32>(0.0, 0.0, -1.0),
        vec3<f32>(0.0, 0.0, 1.0),
        vec3<f32>(-1.0, 0.0, 0.0),
        vec3<f32>(1.0, 0.0, 0.0),
    );
    for (var i = 0; i < 4; i++) {
        let h = trace_layers(base_v, dirs_v[i], 0.54, RAY_TRANSLUCENT | RAY_SOLID);
        if h.distance >= 0.0 && (h.tags & OPC_TAG_CRISTAL) != 0u {
            if h.distance < 0.45 || h.back {
                return true;
            }
        }
    }
    let base_h = (vec3<f32>(b) + vec3<f32>(0.03, 0.5, 0.5)) - frame.camera_position;
    let dirs_h = array<vec3<f32>, 2>(
        vec3<f32>(0.0, 1.0, 0.0),
        vec3<f32>(0.0, -1.0, 0.0),
    );
    for (var i = 0; i < 2; i++) {
        let h = trace_layers(base_h, dirs_h[i], 0.54, RAY_TRANSLUCENT | RAY_SOLID);
        if h.distance >= 0.0 && (h.tags & OPC_TAG_CRISTAL) != 0u {
            if h.distance < 0.45 || h.back {
                return true;
            }
        }
    }
    return false;
}

// Detecta cristal en `b` y clasifica si es transparente (`glass`/`glass_pane`), si es panel fino y qué brazos tiene.
fn adp_cm_clasificar_cristal(b: vec3<i32>) -> u32 {
    let base_v = (vec3<f32>(b) + vec3<f32>(0.5, 0.03, 0.5)) - frame.camera_position;
    let dirs_v = array<vec3<f32>, 4>(
        vec3<f32>(0.0, 0.0, -1.0),
        vec3<f32>(0.0, 0.0, 1.0),
        vec3<f32>(-1.0, 0.0, 0.0),
        vec3<f32>(1.0, 0.0, 0.0),
    );
    var bits = 0u;
    var es_panel = false;
    for (var i = 0; i < 4; i++) {
        let h = trace_layers(base_v, dirs_v[i], 0.54, RAY_TRANSLUCENT | RAY_SOLID);
        if h.distance >= 0.0 && (h.tags & OPC_TAG_CRISTAL) != 0u {
            if h.distance < 0.45 {
                bits |= ADP_CM_BIT_ES_CRISTAL | ADP_CM_BIT_PANEL;
                es_panel = true;
                if h.material == OPC_MAT_CRISTAL_CLARO {
                    bits |= ADP_CM_BIT_CLARO;
                }
            } else if h.back {
                bits |= ADP_CM_BIT_ES_CRISTAL;
                if h.material == OPC_MAT_CRISTAL_CLARO {
                    bits |= ADP_CM_BIT_CLARO;
                }
            }
        }
    }
    if bits == 0u {
        let base_h = (vec3<f32>(b) + vec3<f32>(0.03, 0.5, 0.5)) - frame.camera_position;
        let dirs_h = array<vec3<f32>, 2>(
            vec3<f32>(0.0, 1.0, 0.0),
            vec3<f32>(0.0, -1.0, 0.0),
        );
        for (var i = 0; i < 2; i++) {
            let h = trace_layers(base_h, dirs_h[i], 0.54, RAY_TRANSLUCENT | RAY_SOLID);
            if h.distance >= 0.0 && (h.tags & OPC_TAG_CRISTAL) != 0u && (h.distance < 0.45 || h.back) {
                bits |= ADP_CM_BIT_ES_CRISTAL;
                if h.material == OPC_MAT_CRISTAL_CLARO {
                    bits |= ADP_CM_BIT_CLARO;
                }
                break;
            }
        }
    }
    if es_panel {
        // Detecta si el panel tiene brazo en X (caras +-Z) o brazo en Z (caras +-X).
        // Un poste aislado sin brazos queda con panel_x=0 y panel_z=0 (27 §Bloques y caras: no lleva nada).
        let px_w = (vec3<f32>(b) + vec3<f32>(0.22, 0.03, 0.5)) - frame.camera_position;
        let px_e = (vec3<f32>(b) + vec3<f32>(0.78, 0.03, 0.5)) - frame.camera_position;
        let hx1 = trace_layers(px_w, vec3<f32>(0.0, 0.0, 1.0), 0.14, RAY_TRANSLUCENT | RAY_SOLID);
        let hx2 = trace_layers(px_e, vec3<f32>(0.0, 0.0, 1.0), 0.14, RAY_TRANSLUCENT | RAY_SOLID);
        if (hx1.distance >= 0.0 && (hx1.tags & OPC_TAG_CRISTAL) != 0u)
            || (hx2.distance >= 0.0 && (hx2.tags & OPC_TAG_CRISTAL) != 0u) {
            bits |= ADP_CM_BIT_PANEL_X;
        }
        let pz_n = (vec3<f32>(b) + vec3<f32>(0.5, 0.03, 0.22)) - frame.camera_position;
        let pz_s = (vec3<f32>(b) + vec3<f32>(0.5, 0.03, 0.78)) - frame.camera_position;
        let hz1 = trace_layers(pz_n, vec3<f32>(1.0, 0.0, 0.0), 0.14, RAY_TRANSLUCENT | RAY_SOLID);
        let hz2 = trace_layers(pz_s, vec3<f32>(1.0, 0.0, 0.0), 0.14, RAY_TRANSLUCENT | RAY_SOLID);
        if (hz1.distance >= 0.0 && (hz1.tags & OPC_TAG_CRISTAL) != 0u)
            || (hz2.distance >= 0.0 && (hz2.tags & OPC_TAG_CRISTAL) != 0u) {
            bits |= ADP_CM_BIT_PANEL_Z;
        }
    }
    return bits;
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

fn adp_cristal_mapa_actualizar(cell: vec3<u32>, local: u32, in_bounds: bool) {
    if !OPC_CRISTAL_ACTIVO || !adp_es_superficie() || frame.has_ray_tracing == 0u {
        return;
    }
    // Solo actualizamos cuando hay algún efecto de cristal potencialmente activo en el bioma actual.
    let c0 = datos_cuadro[ADP_CUADRO_CRISTAL_0];
    let c2 = datos_cuadro[ADP_CUADRO_CRISTAL_2];
    let cv = datos_cuadro[ADP_CUADRO_CRISTAL_VAHO];
    let cf = datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS];
    let flags = u32(max(round(cf.x), 0.0));
    let bioma_seco = (flags & OPC_CR_FLAG_BIOMA_SECO) != 0u;
    let bioma_frio = (flags & OPC_CR_FLAG_BIOMA_FRIO) != 0u;
    let llueve_bioma = (flags & OPC_CR_FLAG_LLUEVE_BIOMA) != 0u;
    let sim_viva = (cristal_sim[0].z > 0.5) || (cristal_sim[1].z > 0.5) || (cristal_sim[2].z > 0.5) || (cristal_sim[3].z > 0.5)
                 || (cristal_sim[4].z > 0.5) || (cristal_sim[8].z > 0.5);
    let lluvia_act = llueve_bioma && (c0.x > OPC_CRISTAL_CLIMA_UMBRAL) && (c2.y > 0.001);
    let frio_act = bioma_frio && ((c0.y > 0.001) || (c0.z > 0.001) || (c0.w > 0.001)) && (c2.z > 0.001);
    let arena_act = bioma_seco && (c2.x > OPC_CRISTAL_ARENA_MIN) && (c2.w > 0.001);
    let activo = sim_viva || lluvia_act || frio_act || arena_act || (cv.w > 0.001);
    if !activo {
        return;
    }

    let cam_b = vec3<i32>(floor(frame.camera_position));
    let origen = cam_b - vec3<i32>(ADP_CM_SX / 2, ADP_CM_SY / 2, ADP_CM_SZ / 2);

    // Cada fotograma procesamos 2 planos Z (dispatch [48, 24, 2] = 2 304 vóxeles; ciclo completo en 24 cuadros).
    let z_base = i32((frame.frame_index * 2u) % u32(ADP_CM_SZ));
    let lz = (z_base + i32(cell.z)) % ADP_CM_SZ;
    var es_claro_local = 0u;

    if in_bounds {
        let b = origen + vec3<i32>(i32(cell.x), i32(cell.y), lz);
        let idx = adp_cm_indice(b);
        let firma = adp_cm_firma_bloque(b);
        let w0_ant = cristal_mapa[idx];
        let w1_ant = cristal_mapa[idx + 1u];
        let en_cache = (w0_ant & ADP_CM_BIT_VALIDO) != 0u && ((w1_ant >> 24u) & 255u) == firma;

        // Si el vóxel ya está en la caché 3D sin ser cristal, no relanzamos ray queries salvo cada 4 ciclos (96 cuadros).
        // Si ya era cristal en la caché, conservamos su indicador de baldosa entre ciclos.
        let redescanear = !en_cache || ((frame.frame_index / u32(ADP_CM_SZ / 2)) & 3u) == 0u;
        if !redescanear {
            if (w0_ant & ADP_CM_BIT_ES_CRISTAL) != 0u {
                es_claro_local = 2u | select(0u, 1u, (w0_ant & ADP_CM_BIT_CLARO) != 0u);
            }
        } else {
            let cls = adp_cm_clasificar_cristal(b);
            if (cls & ADP_CM_BIT_ES_CRISTAL) == 0u {
                cristal_mapa[idx] = ADP_CM_BIT_VALIDO;
                cristal_mapa[idx + 1u] = firma << 24u;
            } else {
                es_claro_local = 2u | select(0u, 1u, (cls & ADP_CM_BIT_CLARO) != 0u);
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
                       | cls
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
        }
    }

    // Reducción por workgroup [8, 4, 1] -> indica si esta baldosa contiene algún cristal transparente.
    adp_cm_wg_claro[local] = es_claro_local;
    workgroupBarrier();
    if local == 0u {
        var hay = 0u;
        for (var k = 0u; k < 32u; k++) {
            hay |= adp_cm_wg_claro[k];
        }
        let gx = cell.x / 8u;
        let gy = cell.y / 4u;
        let tile_id = u32(lz) * 36u + gy * 6u + gx;
        cristal_mapa[ADP_CM_META_OFF + tile_id] = hay;
    }
}
