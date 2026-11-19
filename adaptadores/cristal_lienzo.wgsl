// Rasterización en [[before_world]] de los paneles de lluvia y copos desde `cristal_sim` a `cristal_clima` (512x512).
// Usa memoria compartida de grupo (`var<workgroup>`) para leer cada gota una sola vez por bloque de 8x8 texeles,
// y salida temprana de coste ~0 cuando el panel está seco.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §2

var<workgroup> adp_cl_g0: array<vec4<f32>, 112>;
var<workgroup> adp_cl_g1: array<vec4<f32>, 112>;

fn adp_cristal_lienzo(cell: vec3<u32>, local: u32, in_bounds: bool) {
    // Determina a qué panel pertenece este workgroup (todos los hilos del workgroup 8x8 comparten panel).
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

    // Paneles de copos (8..15) todavía inactivos hasta el paso 4; y paneles de lluvia completamente secos:
    // salen todos los hilos del workgroup antes de tocar memoria ni texturas.
    if panel_id >= 8u || (activas == 0u && trail_t <= -0.5) {
        return;
    }

    let es_arriba = panel_id >= 4u;
    let max_slots = select(ADP_CS_MAX_GOTAS_LADO, ADP_CS_MAX_GOTAS_ARRIBA, es_arriba);
    let base = select(
        ADP_CS_OFF_LADO + panel_id * ADP_CS_SLOT_LADO * 2u,
        ADP_CS_OFF_ARRIBA + (panel_id - 4u) * ADP_CS_MAX_GOTAS_ARRIBA * 2u,
        es_arriba,
    );

    // Carga cooperativa en memoria compartida (64 hilos cargan hasta 112 gotas en 2 iteraciones).
    for (var idx = local; idx < max_slots; idx += 64u) {
        adp_cl_g0[idx] = cristal_sim[base + idx * 2u];
        adp_cl_g1[idx] = cristal_sim[base + idx * 2u + 1u];
    }
    workgroupBarrier();

    if !in_bounds {
        return;
    }

    let coord = vec2<i32>(px_all, py_all);
    // Si el panel acaba de quedarse seco del todo (trail_t <= 0), limpia el texel a 0.
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

    let p_tx = vec2<f32>(f32(px_all % 128) + 0.5, f32(py_all % 128) + 0.5);
    var mejor_tono = 0.5;
    var mejor_alfa = 0.0;
    var mejor_pend = vec2<f32>(0.0);

    for (var i = 0u; i < max_slots; i++) {
        let g0 = adp_cl_g0[i];
        if g0.z <= 0.0 {
            continue;
        }
        let delta = sup_cr_wrap_delta(p_tx - g0.xy);
        // Descarte rápido por caja delimitadora.
        let margen = g0.z + 3.0;
        if abs(delta.x) > margen || abs(delta.y) > margen + 3.0 {
            continue;
        }
        let g1 = adp_cl_g1[i];

        // Estampa rastro mojado si la gota está corriendo (ancho max(1, round(0,55 * tam))).
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
