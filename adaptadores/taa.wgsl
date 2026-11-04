// La pasada de TAA desde los recursos de post: reproyección con las matrices de frame, la imagen de este
// fotograma (previous) y el historial (history). Porqué: docs/efectos/taa.md §Adaptadores

// La profundidad más cercana a la cámara en una cruz (Karis 2014): los bordes en movimiento reproyectan con
// el objeto de delante. Profundidad invertida: más cercana = mayor.
fn adp_taa_profundidad_cercana(uv: vec2<f32>) -> f32 {
    let px = 1.0 / frame.resolution;
    var d = depth_at(uv);
    d = max(d, depth_at(uv + vec2<f32>(px.x, 0.0)));
    d = max(d, depth_at(uv - vec2<f32>(px.x, 0.0)));
    d = max(d, depth_at(uv + vec2<f32>(0.0, px.y)));
    d = max(d, depth_at(uv - vec2<f32>(0.0, px.y)));
    return d;
}

// uv del punto en el fotograma anterior (x < 0 si no hay).
fn adp_taa_uv_anterior(uv: vec2<f32>) -> vec2<f32> {
    let d = adp_taa_profundidad_cercana(uv);
    var h: vec4<f32>;
    if d <= 0.0 {
        // Cielo: solo la dirección (sin traslación).
        let dir = normalize(view_position(uv, 1e-4));
        h = frame.previous_view_projection * vec4<f32>(dir, 0.0);
    } else {
        let p = view_position(uv, d);
        h = frame.previous_view_projection * vec4<f32>(p + frame.camera_motion, 1.0);
    }
    if h.w <= 0.0 {
        return vec2<f32>(-1.0);
    }
    return mat_ndc_a_uv(h.xy / h.w);
}

fn adp_taa(input: PostInput) -> vec4<f32> {
    let o = opc_taa();
    let px = 1.0 / frame.resolution;
    var actual = textureSampleLevel(previous, linear_sampler, input.uv, 0.0).rgb;
    if OPC_TAA_FXAA {
        actual = img_fxaa(previous, linear_sampler, input.uv, actual);
    }
    if !o.activo {
        return vec4<f32>(actual, 1.0);
    }
    // Vecindad 3×3 del fotograma actual, en YCoCg del espacio comprimido.
    var m1 = vec3<f32>(0.0);
    var m2 = vec3<f32>(0.0);
    for (var k = 0; k < 9; k++) {
        let o2 = vec2<f32>(f32(k % 3) - 1.0, f32(k / 3) - 1.0);
        let c = img_a_ycocg(img_comprimir(textureSampleLevel(previous, nearest_sampler, input.uv + o2 * px, 0.0).rgb));
        m1 += c;
        m2 += c * c;
    }
    let media = m1 / 9.0;
    let sigma = sqrt(max(m2 / 9.0 - media * media, vec3<f32>(0.0)));

    let uv_ant = adp_taa_uv_anterior(input.uv);
    let fuera = any(uv_ant < vec2<f32>(0.0)) || any(uv_ant > vec2<f32>(1.0));
    let h_crudo = img_catmull_rom(history, linear_sampler, uv_ant, o.nitidez);
    if fuera || frame.delta_time <= 0.0 || dot(h_crudo, h_crudo) <= 0.0 {
        return vec4<f32>(actual, 1.0);
    }
    // Movimiento en píxeles: más movimiento, caja más estrecha y más peso al fotograma actual.
    let movimiento = length((input.uv - uv_ant) * frame.resolution);
    let gamma = mix(OPC_TAA_GAMMA, OPC_TAA_GAMMA_MOVIMIENTO, smoothstep(0.0, 8.0, movimiento));
    let h = img_recortar(img_a_ycocg(img_comprimir(h_crudo)), media, sigma * gamma);
    let alfa = mix(OPC_TAA_MEZCLA_QUIETO, OPC_TAA_MEZCLA_MOVIMIENTO, smoothstep(0.0, 6.0, movimiento));
    let a = img_a_ycocg(img_comprimir(actual));
    let resultado = img_descomprimir(img_desde_ycocg(mix(h, a, alfa)));
    return vec4<f32>(max(resultado, vec3<f32>(0.0)), 1.0);
}
