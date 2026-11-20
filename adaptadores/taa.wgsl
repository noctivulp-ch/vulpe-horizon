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

fn adp_taa_alfa_niebla(input: PostInput) -> f32 {
    let opacidad = 1.0 - textureSampleLevel(volumen, linear_sampler, input.uv, 0.0).a;
    if frame.in_water > 0.5 || !adp_es_superficie() {
        return opacidad;
    }
    if input.depth <= 0.0 || surface_at(vec2<i32>(input.pixel)).present {
        return 0.0;
    }
    return OPC_BLOOM_NIEBLA_TRANSLUCIDO * opacidad;
}

fn adp_taa(input: PostInput) -> vec4<f32> {
    let o = opc_taa();
    let px = 1.0 / frame.resolution;
    let entrada = textureSampleLevel(composicion, linear_sampler, input.uv, 0.0);
    // `composicion` es un destino [[post]] sin canal alfa: el alfa de niebla se calcula aquí para `historial` (rgba16float).
    let alfa_niebla = adp_taa_alfa_niebla(input);
    var actual = entrada.rgb;
    if OPC_TAA_FXAA {
        actual = img_fxaa(composicion, linear_sampler, input.uv, actual);
    }
    if !o.activo {
        return vec4<f32>(actual, alfa_niebla);
    }
    // Vecindad 3×3 del fotograma actual, en YCoCg del espacio comprimido.
    var m1 = vec3<f32>(0.0);
    var m2 = vec3<f32>(0.0);
    for (var k = 0; k < 9; k++) {
        let o2 = vec2<f32>(f32(k % 3) - 1.0, f32(k / 3) - 1.0);
        let c = img_a_ycocg(img_comprimir(textureSampleLevel(composicion, nearest_sampler, input.uv + o2 * px, 0.0).rgb));
        m1 += c;
        m2 += c * c;
    }
    let media = m1 / 9.0;
    let sigma = sqrt(max(m2 / 9.0 - media * media, vec3<f32>(0.0)));

    let uv_ant = adp_taa_uv_anterior(input.uv);
    let fuera = any(uv_ant < vec2<f32>(0.0)) || any(uv_ant > vec2<f32>(1.0));
    let h_crudo = img_catmull_rom(historial_previous, linear_sampler, uv_ant, o.nitidez);
    if fuera || frame.delta_time <= 0.0 || dot(h_crudo, h_crudo) <= 0.0 {
        return vec4<f32>(actual, alfa_niebla);
    }
    // Movimiento en píxeles: más movimiento, caja más estrecha y más peso al fotograma actual.
    let movimiento = length((input.uv - uv_ant) * frame.resolution);
    let gamma = mix(OPC_TAA_GAMMA, OPC_TAA_GAMMA_MOVIMIENTO, smoothstep(0.0, 8.0, movimiento));
    let h_comp = img_a_ycocg(img_comprimir(h_crudo));
    let h_rec = img_recortar(h_comp, media, sigma * gamma);
    // Mitigación de estelas por retroceso al primer momento (Salvi 2016, fino/09 §1):
    let diff_recorte = length(h_rec - h_comp) / (length(h_comp) + 1e-4);
    let peso_retroceso = smoothstep(0.05, 0.45, diff_recorte);
    let h = mix(h_rec, media, peso_retroceso);
    let alfa = mix(OPC_TAA_MEZCLA_QUIETO, OPC_TAA_MEZCLA_MOVIMIENTO, smoothstep(0.0, 6.0, movimiento));
    let a = img_a_ycocg(img_comprimir(actual));
    let resultado = img_descomprimir(img_desde_ycocg(mix(h, a, alfa)));
    return vec4<f32>(max(resultado, vec3<f32>(0.0)), alfa_niebla);
}
