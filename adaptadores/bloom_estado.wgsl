// Pasadas de bloom 4 y 5: la bajada y el ancho, con el estado entre fotogramas en los téxeles de la fila 0 (ver
// adaptadores/imagen.wgsl). Aparte de imagen.wgsl porque la pasada final no los usa y el validador cuenta las lecturas
// de textura de todo el módulo. Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Adaptadores

// Pasada 4: bajada a ¼ desde history; en la esquina, la medida y la adaptación (el estado anterior está en la
// esquina de bloom2, que aún guarda el del fotograma anterior).
fn adp_bloom_bajada(input: PostInput) -> vec4<f32> {
    let rgb = img_bloom_bajada(history, linear_sampler, input.uv);
    let texel = vec2<i32>(input.pixel);
    if texel.y != 0 || texel.x > 6 {
        return vec4<f32>(rgb, 0.0);
    }
    if texel.x == 6 {
        return vec4<f32>(rgb, adp_clima_local_estado(textureLoad(bloom2, texel, 0).a));
    }
    if texel.x == 5 {
        return vec4<f32>(rgb, select(0.0, 1.0, frame.eye_in == 1u));
    }
    if texel.x == 4 {
        return vec4<f32>(rgb, adp_estado_cruce(textureLoad(bloom2, texel, 0).a, textureLoad(bloom2, vec2<i32>(5, 0), 0).a));
    }
    if texel.x == 3 {
        return vec4<f32>(rgb, adp_estado_altura_entrada(textureLoad(bloom2, texel, 0).a));
    }
    if texel.x == 2 {
        return vec4<f32>(rgb, adp_estado_agua(textureLoad(bloom2, texel, 0).a));
    }
    let anterior = adp_estado(bloom2);
    let l = img_luminancia_media(history, linear_sampler);
    let vel_mod = max(adp_mod_param(33u, 0.1, 10.0, VULPE_ADAPTACION_VELOCIDAD, 1.0), 0.1);
    var estado = 0.0;
    if texel.x == 0 {
        estado = img_adaptar(anterior.x, l, frame.delta_time, OPC_ADAPTACION_SUBE / vel_mod, OPC_ADAPTACION_BAJA / vel_mod);
    } else {
        estado = img_adaptar(anterior.y, l, frame.delta_time, OPC_BASTONES_TAU, OPC_BASTONES_TAU);
    }
    return vec4<f32>(rgb, estado);
}

// Pasada 5: desenfoque ancho de bloom; copia el estado de la esquina.
fn adp_bloom_ancho(input: PostInput) -> vec4<f32> {
    let aspecto = frame.resolution.x / frame.resolution.y;
    let giro = rui_tramado_ign(input.pixel);
    let rgb = img_bloom_ancho(bloom, linear_sampler, input.uv, OPC_BLOOM_RADIO, aspecto, OPC_BLOOM_ANILLOS, giro).rgb;
    let texel = vec2<i32>(input.pixel);
    var alfa = 0.0;
    if texel.y == 0 && texel.x <= 6 {
        alfa = textureLoad(bloom, texel, 0).a;
    }
    return vec4<f32>(rgb, alfa);
}

// Pasada 4, téxeles (4,0) y (5,0): el cruce. (5,0).a guarda si la cámara estaba en el agua el fotograma anterior.
fn adp_estado_cruce(anterior: f32, dentro_antes: f32) -> f32 {
    let dentro = frame.eye_in == 1u;
    if dentro != (dentro_antes > 0.5) && frame.delta_time > 0.0 {
        let rapidez = length(frame.camera_motion) / max(frame.delta_time, 1e-3);
        return adp_cruce_codificar(0.0, !dentro, rapidez);
    }
    let c = adp_cruce_decodificar(anterior);
    if c.t < 0.0 || c.t + frame.delta_time >= OPC_GOTAS_DURACION {
        return 0.0;
    }
    return adp_cruce_codificar(c.t + frame.delta_time, c.salida, c.rapidez);
}
