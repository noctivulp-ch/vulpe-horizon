// Pasadas de bloom 4 y 5: la bajada (RGB en `bloom`) y el ancho (`bloom2`, `[[resource]] rgba16float`),
// guardando el estado entre fotogramas en los téxeles `(0..7, 0).a` directamente en `bloom2` porque
// los destinos `[[post]] output` sin `[[resource]]` no conservan canal alfa (`shaders-reference-0.2.md:29`).
// Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Adaptadores

// Pasada 4: bajada a ¼ desde el historial del fotograma anterior.
fn adp_bloom_bajada(input: PostInput, tex: texture_2d<f32>) -> vec4<f32> {
    if opc_quitar(16u) {
        return vec4<f32>(0.0);
    }
    let rgb = img_bloom_bajada(tex, linear_sampler, input.uv);
    return vec4<f32>(rgb, 1.0);
}

// Pasada 5: desenfoque ancho de bloom y estado entre fotogramas en la fila 0 de `bloom2` (`rgba16float`).
fn adp_bloom_ancho(
    input: PostInput,
    t_bloom: texture_2d<f32>,
    t_hist: texture_2d<f32>,
    t_estado: texture_2d<f32>,
) -> vec4<f32> {
    let texel = vec2<i32>(input.pixel);
    let es_estado = texel.y == 0 && texel.x <= 7;
    if opc_quitar(16u) && !es_estado {
        return vec4<f32>(0.0);
    }
    let aspecto = frame.resolution.x / frame.resolution.y;
    let giro = rui_tramado_ign(input.pixel);
    let rgb = select(
        img_bloom_ancho(t_bloom, linear_sampler, input.uv, OPC_BLOOM_RADIO, aspecto, OPC_BLOOM_ANILLOS, giro).rgb,
        vec3<f32>(0.0),
        opc_quitar(16u),
    );
    if !es_estado {
        return vec4<f32>(rgb, 0.0);
    }
    if texel.x == 7 {
        return vec4<f32>(rgb, adp_estado_calor(textureLoad(t_estado, texel, 0).a));
    }
    if texel.x == 6 {
        return vec4<f32>(rgb, adp_clima_local_estado(textureLoad(t_estado, texel, 0).a));
    }
    if texel.x == 5 || texel.x == 4 {
        return vec4<f32>(rgb, 0.0);
    }
    if texel.x == 3 {
        return vec4<f32>(rgb, adp_estado_altura_entrada(textureLoad(t_estado, texel, 0).a));
    }
    if texel.x == 2 {
        return vec4<f32>(rgb, adp_estado_agua(textureLoad(t_estado, texel, 0).a));
    }
    let anterior = adp_estado(t_estado);
    let l = img_luminancia_media(t_hist, linear_sampler);
    let vel_mod = max(adp_mod_param(33u, 0.1, 10.0, VULPE_ADAPTACION_VELOCIDAD, 1.0), 0.1);
    var estado = 0.0;
    if texel.x == 0 {
        estado = img_adaptar(anterior.x, l, frame.delta_time, OPC_ADAPTACION_SUBE / vel_mod, OPC_ADAPTACION_BAJA / vel_mod);
    } else {
        estado = img_adaptar(anterior.y, l, frame.delta_time, OPC_BASTONES_TAU, OPC_BASTONES_TAU);
    }
    return vec4<f32>(rgb, estado);
}

// Pasada 5, téxel (7,0): nivel suavizado del calor (0..1), sube en 0,5 s y se apaga en 3 s (19).
// Activo cuando el mod indica llamas (`mods[3].z`) o la cámara está dentro de lava (`frame.eye_in == 2u`).
fn adp_estado_calor(anterior: f32) -> f32 {
    let m = adp_mod();
    let llamas = m.jugador.activo && m.jugador.en_llamas > 0.5;
    let activo = llamas || frame.eye_in == 2u;
    return img_calor_nivel(anterior, activo, frame.delta_time, OPC_CALOR_SUBE, OPC_CALOR_BAJA);
}
