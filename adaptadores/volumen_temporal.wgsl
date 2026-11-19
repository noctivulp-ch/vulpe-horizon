// Caché temporal del volumen (tablero 2×2 en cómputo con mapeo por cuadrantes para coherencia de warp).
// Porqué: docs/rendimiento.md

fn adp_vol_prof_compatible(dist_ant: f32, es_cielo: bool, dist_esp: f32) -> bool {
    if dist_ant <= 0.0 {
        return false;
    }
    if es_cielo {
        return dist_ant >= OPC_VOL_CACHE_CIELO_DIST;
    }
    if dist_ant >= OPC_VOL_CACHE_CIELO_DIST {
        return false;
    }
    return abs(dist_ant - dist_esp) / max(dist_esp, 1.0) <= OPC_VOL_CACHE_UMBRAL_PROF;
}

fn adp_volumen_temporal(input: ComputeInput) {
    if !input.in_bounds {
        return;
    }
    let dims = textureDimensions(volumen);
    let mitad = (dims + vec2<u32>(1u)) / 2u;
    let cx = input.cell.x;
    let cy = input.cell.y;
    if cx >= mitad.x * 2u || cy >= mitad.y * 2u {
        return;
    }
    // Mapeo por cuadrantes: los 4 subgrupos del tablero 2×2 quedan contiguos en el despacho,
    // así 3 de cada 4 warps evitan el raymarch completo.
    let qx = select(0u, 1u, cx >= mitad.x);
    let qy = select(0u, 1u, cy >= mitad.y);
    let lx = cx - qx * mitad.x;
    let ly = cy - qy * mitad.y;
    let px = lx * 2u + qx;
    let py = ly * 2u + qy;
    if px >= dims.x || py >= dims.y {
        return;
    }
    let texel = vec2<i32>(i32(px), i32(py));
    let dims_f = vec2<f32>(dims);
    let uv = (vec2<f32>(texel) + 0.5) / dims_f;
    let pixel = vec2<f32>(texel) + 0.5;

    if opc_quitar(1u) {
        textureStore(volumen, texel, adp_volumen_salida(VolResultado(vec3<f32>(0.0), 1.0, 0.0, vec3<f32>(0.0))));
        textureStore(volumen_prof, texel, vec4<f32>(1e6, 0.0, 0.0, 0.0));
        return;
    }

    let d = depth_at(uv);
    let es_cielo = d <= 0.0;
    var pos = vec3<f32>(0.0);
    var dist_act = 1e6;
    if !es_cielo {
        pos = view_position(uv, d);
        dist_act = length(pos);
    }

    // Orden Bayer 2×2: (0,0), (1,1), (1,0), (0,1).
    let fase = frame.frame_index & 3u;
    let bx = (fase & 1u) ^ ((fase >> 1u) & 1u);
    let by = fase & 1u;
    let toca = qx == bx && qy == by;
    let transicion_agua = frame.in_water > 0.01 && frame.in_water < 0.99;
    let reinicio = frame.delta_time <= 0.0 || transicion_agua
        || (frame.reset_reasons & (REASON_LOAD | REASON_RESET | REASON_WORLD | REASON_TELEPORT | REASON_PAUSE | REASON_SIZE)) != 0u;

    if !toca && !reinicio {
        var h: vec4<f32>;
        var dist_esp = 1e6;
        if es_cielo {
            let dir = normalize(view_position(uv, 1e-4));
            h = frame.previous_view_projection * vec4<f32>(dir, 0.0);
        } else {
            let pos_ant = pos + frame.camera_motion;
            h = frame.previous_view_projection * vec4<f32>(pos_ant, 1.0);
            dist_esp = length(pos_ant);
        }
        if h.w > 0.0 {
            let uv_ant = mat_ndc_a_uv(h.xy / h.w);
            if all(uv_ant >= vec2<f32>(0.0)) && all(uv_ant <= vec2<f32>(1.0)) {
                let q = uv_ant * dims_f - 0.5;
                let base = floor(q);
                let max_t = dims_f - 1.0;
                let t00 = vec2<i32>(clamp(base, vec2<f32>(0.0), max_t));
                let t10 = vec2<i32>(clamp(base + vec2<f32>(1.0, 0.0), vec2<f32>(0.0), max_t));
                let t01 = vec2<i32>(clamp(base + vec2<f32>(0.0, 1.0), vec2<f32>(0.0), max_t));
                let t11 = vec2<i32>(clamp(base + vec2<f32>(1.0, 1.0), vec2<f32>(0.0), max_t));
                let ok00 = adp_vol_prof_compatible(textureLoad(volumen_prof_previous, t00, 0).x, es_cielo, dist_esp);
                let ok10 = adp_vol_prof_compatible(textureLoad(volumen_prof_previous, t10, 0).x, es_cielo, dist_esp);
                let ok01 = adp_vol_prof_compatible(textureLoad(volumen_prof_previous, t01, 0).x, es_cielo, dist_esp);
                let ok11 = adp_vol_prof_compatible(textureLoad(volumen_prof_previous, t11, 0).x, es_cielo, dist_esp);
                if ok00 && ok10 && ok01 && ok11 {
                    let col = textureSampleLevel(volumen_previous, linear_sampler, uv_ant, 0.0);
                    textureStore(volumen, texel, col);
                    textureStore(volumen_prof, texel, vec4<f32>(dist_act, 0.0, 0.0, 0.0));
                    return;
                }
                let t_cerca = vec2<i32>(clamp(floor(uv_ant * dims_f), vec2<f32>(0.0), max_t));
                if adp_vol_prof_compatible(textureLoad(volumen_prof_previous, t_cerca, 0).x, es_cielo, dist_esp) {
                    let col = textureLoad(volumen_previous, t_cerca, 0);
                    textureStore(volumen, texel, col);
                    textureStore(volumen_prof, texel, vec4<f32>(dist_act, 0.0, 0.0, 0.0));
                    return;
                }
            }
        }
    }

    let col = adp_volumen_salida(adp_volumen(uv, pixel));
    textureStore(volumen, texel, col);
    textureStore(volumen_prof, texel, vec4<f32>(dist_act, 0.0, 0.0, 0.0));
}
