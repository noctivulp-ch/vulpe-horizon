// Rasterización en [[before_world]] de los paneles de lluvia y las 8 tiras globales de copos desde `cristal_sim`
// a `cristal_clima` (512x512). Usa memoria compartida de grupo (`var<workgroup>`) y salida temprana de coste ~0
// cuando el panel está vacío o seco.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §2 y §4

var<workgroup> adp_cl_g0: array<vec4<f32>, 144>;
var<workgroup> adp_cl_g1: array<vec4<f32>, 112>;

fn adp_cristal_lienzo(cell: vec3<u32>, local: u32, in_bounds: bool) {
    let px_all = i32(cell.x);
    let py_all = i32(cell.y);
    let col_panel = u32(clamp(px_all / 128, 0, 3));
    let fila_panel = u32(clamp(py_all / 128, 0, 3));

    var panel_id = col_panel;
    if fila_panel == 1u {
        panel_id = 4u + col_panel;
    } else if fila_panel >= 2u {
        panel_id = 8u + (fila_panel - 2u) * 4u + col_panel;
    }

    let hdr = cristal_sim[panel_id];
    let activas = u32(max(round(hdr.z), 0.0));
    let trail_t = hdr.w;

    // Salida temprana uniforme de workgroup cuando el panel está seco/vacío.
    if activas == 0u && trail_t <= -0.5 {
        return;
    }

    let coord = vec2<i32>(px_all, py_all);
    let p_tx = vec2<f32>(f32(px_all % 128) + 0.5, f32(py_all % 128) + 0.5);

    // Paneles 8..15: 8 tiras globales de copos pegados (y=256..511; 27 v2 §Capa 3).
    if panel_id >= 8u {
        let tira = panel_id - 8u;
        let base_c = ADP_CS_OFF_COPOS + tira * ADP_CS_SLOT_COPOS;
        for (var idx = local; idx < ADP_CS_MAX_COPOS; idx += 64u) {
            adp_cl_g0[idx] = cristal_sim[base_c + idx];
        }
        workgroupBarrier();

        if !in_bounds {
            return;
        }
        if activas == 0u {
            textureStore(cristal_clima, coord, vec4<f32>(0.0));
            return;
        }

        var mejor = vec4<f32>(0.0);
        for (var i = 0u; i < ADP_CS_MAX_COPOS; i++) {
            let f0 = adp_cl_g0[i];
            if f0.z <= 0.0 {
                continue;
            }
            let d = sup_cr_wrap_delta(p_tx - f0.xy);
            if abs(d.x) > 2.6 || abs(d.y) > 2.6 {
                continue;
            }
            let forma = u32(floor(f0.z));
            var escala_a = 1.0;
            var reducido = false;
            if f0.w > 0.0 {
                let total_s = max(fract(f0.z) * 100.0, 20.0);
                let frac = clamp(f0.w / total_s, 0.0, 1.0);
                if frac < 0.40 {
                    escala_a = frac / 0.40;
                }
                reducido = frac < 0.25;
            }
            let c = sup_cristal_dibujar_copo(p_tx, f0.xy, forma, escala_a, reducido);
            if c.a > mejor.a {
                mejor = c;
            }
        }
        textureStore(cristal_clima, coord, mejor);
        return;
    }

    // Paneles 0..7: lluvia en caras laterales (0..3) y cara superior (4..7).
    let es_arriba = panel_id >= 4u;
    let max_slots = select(ADP_CS_MAX_GOTAS_LADO, ADP_CS_MAX_GOTAS_ARRIBA, es_arriba);
    let base = select(
        ADP_CS_OFF_LADO + panel_id * ADP_CS_SLOT_LADO * 2u,
        ADP_CS_OFF_ARRIBA + (panel_id - 4u) * ADP_CS_MAX_GOTAS_ARRIBA * 2u,
        es_arriba,
    );

    for (var idx = local; idx < max_slots; idx += 64u) {
        adp_cl_g0[idx] = cristal_sim[base + idx * 2u];
        adp_cl_g1[idx] = cristal_sim[base + idx * 2u + 1u];
    }
    workgroupBarrier();

    if !in_bounds {
        return;
    }
    if activas == 0u && trail_t <= 0.0 {
        textureStore(cristal_clima, coord, vec4<f32>(0.0));
        return;
    }

    let cf = datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS];
    let flags = u32(max(round(cf.x), 0.0));
    let regueros = !es_arriba && (flags & OPC_CR_FLAG_REGUEROS) != 0u;
    let dt = clamp(frame.delta_time, 0.0, 0.10);
    let fade_s = select(1.6, 2.4, regueros);

    let prev = textureLoad(cristal_clima_previous, coord, 0);
    var rastro = max(prev.r - dt / fade_s, 0.0);

    var mejor_tono = 0.5;
    var mejor_alfa = 0.0;
    var mejor_pend = vec2<f32>(0.0);

    for (var i = 0u; i < max_slots; i++) {
        let g0 = adp_cl_g0[i];
        if g0.z <= 0.0 {
            continue;
        }
        let delta = sup_cr_wrap_delta(p_tx - g0.xy);
        let margen = g0.z + 3.0;
        if abs(delta.x) > margen || abs(delta.y) > margen + 3.0 {
            continue;
        }
        let g1 = adp_cl_g1[i];

        if !es_arriba && g0.w > 0.5 {
            let medio_r = max(1.0, round(0.55 * g0.z)) * 0.5;
            if regueros {
                let medio_reg = select(0.55, 1.05, g0.z >= 1.5);
                if abs(delta.x) <= medio_reg && delta.y <= 0.5 && delta.y >= -2.5 {
                    rastro = 1.0;
                }
            } else if abs(delta.x) <= medio_r && delta.y <= 0.5 && delta.y >= -(g0.z * 0.8 + 1.5) {
                rastro = 1.0;
            }
        }

        let res = sup_cristal_dibujar_gota(p_tx, g0.xy, g0.z, select(0.0, g0.w, !es_arriba), g1.y, f32(i) * 0.37, regueros);
        if res.y > mejor_alfa {
            mejor_tono = res.x;
            mejor_alfa = res.y;
            mejor_pend = res.zw;
        }
    }

    textureStore(
        cristal_clima,
        coord,
        vec4<f32>(rastro, mejor_tono, mejor_alfa, sup_cr_empaquetar_pendiente(mejor_pend)),
    );
}
