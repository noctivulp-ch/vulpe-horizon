// Pasadas de bloom 4 y 5: la bajada y el ancho, con el estado entre fotogramas en los téxeles de la fila 0 (ver
// adaptadores/imagen.wgsl). Aparte de imagen.wgsl porque la pasada final no los usa y el validador cuenta las lecturas
// de textura de todo el módulo. Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Adaptadores

// Pasada 4: bajada a ¼ desde history; en la esquina, la medida y la adaptación (el estado anterior está en la
// esquina de bloom2, que aún guarda el del fotograma anterior).
fn adp_bloom_bajada(input: PostInput, tex: texture_2d<f32>, t_estado: texture_2d<f32>) -> vec4<f32> {
    if opc_quitar(16u) && !(i32(input.pixel.y) == 0 && i32(input.pixel.x) <= 7) {
        return vec4<f32>(0.0);
    }
    let rgb = img_bloom_bajada(tex, linear_sampler, input.uv);
    let texel = vec2<i32>(input.pixel);
    if texel.y != 0 || texel.x > 7 {
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
    let l = img_luminancia_media(tex, linear_sampler);
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
fn adp_bloom_ancho(input: PostInput, t_bloom: texture_2d<f32>) -> vec4<f32> {
    if opc_quitar(16u) && !(i32(input.pixel.y) == 0 && i32(input.pixel.x) <= 7) {
        return vec4<f32>(0.0);
    }
    let aspecto = frame.resolution.x / frame.resolution.y;
    let giro = rui_tramado_ign(input.pixel);
    let rgb = img_bloom_ancho(t_bloom, linear_sampler, input.uv, OPC_BLOOM_RADIO, aspecto, OPC_BLOOM_ANILLOS, giro).rgb;
    let texel = vec2<i32>(input.pixel);
    var alfa = 0.0;
    if texel.y == 0 && texel.x <= 7 {
        alfa = textureLoad(t_bloom, texel, 0).a;
    }
    return vec4<f32>(rgb, alfa);
}

// Pasada 4, téxel (7,0): nivel suavizado del calor (0..1), sube en 0,5 s y se apaga en 3 s (19).
// Activo cuando el mod indica llamas (`mods[3].z`) o la cámara está dentro de lava (`frame.eye_in == 2u`).
fn adp_estado_calor(anterior: f32) -> f32 {
    let m = adp_mod();
    let llamas = m.jugador.activo && m.jugador.en_llamas > 0.5;
    let activo = llamas || frame.eye_in == 2u;
    return img_calor_nivel(anterior, activo, frame.delta_time, OPC_CALOR_SUBE, OPC_CALOR_BAJA);
}
