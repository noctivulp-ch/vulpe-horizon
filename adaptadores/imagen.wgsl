// Las pasadas de bloom y la final: el estado de la exposición en los texeles de esquina de los destinos de bloom
// (realimentación entre fotogramas sin compute), el bloom de niebla y los efectos de estado del jugador.
// Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Adaptadores y docs/efectos/bloom.md

// Texeles de esquina: (0,0).a la luminancia adaptada; (1,0).a la de los bastones (más lenta); (2,0).a el nivel del
// agua junto a la cámara (adaptadores/cruce_agua.wgsl).
fn adp_estado(t: texture_2d<f32>) -> vec2<f32> {
    return vec2<f32>(textureLoad(t, vec2<i32>(0, 0), 0).a, textureLoad(t, vec2<i32>(1, 0), 0).a);
}

// Pasada 4: bajada a ¼ desde history; en la esquina, la medida y la adaptación (el estado anterior está en la
// esquina de bloom2, que aún guarda el del fotograma anterior).
fn adp_bloom_bajada(input: PostInput) -> vec4<f32> {
    let rgb = img_bloom_bajada(history, linear_sampler, input.uv);
    let texel = vec2<i32>(input.pixel);
    if texel.y != 0 || texel.x > 2 {
        return vec4<f32>(rgb, 0.0);
    }
    if texel.x == 2 {
        return vec4<f32>(rgb, adp_estado_agua(textureLoad(bloom2, texel, 0).a));
    }
    let anterior = adp_estado(bloom2);
    let l = img_luminancia_media(history, linear_sampler);
    var estado = 0.0;
    if texel.x == 0 {
        estado = img_adaptar(anterior.x, l, frame.delta_time, OPC_ADAPTACION_SUBE, OPC_ADAPTACION_BAJA);
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
    // Opacidad de la niebla en las fuentes de alrededor: pesa el bloom de niebla (ver adp_bloom_final).
    let niebla = img_opacidad_fuentes(bloom, volumen, linear_sampler, input.uv, OPC_BLOOM_RADIO, aspecto, OPC_BLOOM_ANILLOS_NIEBLA, giro);
    let texel = vec2<i32>(input.pixel);
    var alfa = niebla;
    if texel.y == 0 && texel.x <= 2 {
        alfa = textureLoad(bloom, texel, 0).a;
    }
    return vec4<f32>(rgb, alfa);
}

struct AdpExposicion {
    exposicion: f32,
    bastones: f32,          // peso del efecto Purkinje
}

fn adp_exposicion(o: OpcImagen) -> AdpExposicion {
    let estado = adp_estado(bloom2);
    let previa = adp_codificacion().exposicion;
    var e = previa;
    if estado.x > 0.0 {
        let automatica = img_exposicion_objetivo(estado.x, ImgCurvaExposicion(OPC_EXPOSICION_K, OPC_EXPOSICION_C));
        e = exp2(mix(log2(previa), log2(automatica), OPC_EXPOSICION_PESO_AUTO));
    }
    var bastones = select(0.0, col_peso_bastones(estado.y, OPC_BASTONES_L0), estado.y > 0.0) * OPC_PURKINJE;
    // Fuera del Overworld no hay noche que adaptar (17): sin Purkinje (teñía de azul el Nether).
    bastones *= select(0.0, 1.0, adp_es_superficie());
    // Junto a una fuente de luz (luz de bloque en la cámara) el ojo no está en visión escotópica: los colores de las
    // antorchas no se pierden en el azul (visto con el 03.1).
    bastones *= 1.0 - smoothstep(0.15, 0.6, frame.eye_light_smooth.x);
    // Visión nocturna: sin Purkinje y exposición alta.
    bastones *= 1.0 - frame.night_vision;
    e *= mix(1.0, 4.0, frame.night_vision);
    return AdpExposicion(e * o.compensacion, bastones);
}

// Bloom de la pasada final: núcleo (bicúbico de bloom) más ancho (bloom2), y bloom de niebla.
fn adp_bloom_final(color: vec3<f32>, uv: vec2<f32>, o: OpcImagen) -> vec3<f32> {
    let nucleo = img_catmull_rom(bloom, linear_sampler, uv, 1.0);
    let ancho4 = textureSampleLevel(bloom2, linear_sampler, uv, 0.0);
    let ancho = ancho4.rgb;
    let b = mix(ancho, nucleo, OPC_BLOOM_NUCLEO);
    let vineta = mix(OPC_BLOOM_VINETA_CENTRO, OPC_BLOOM_VINETA_ESQUINA, saturate(length(uv - 0.5) * 1.41421356));
    // La niebla que dispersa la luz de una fuente es la que hay alrededor, no solo la del píxel: con la del píxel el
    // halo quedaba recortado por los objetos cercanos y parecía un disco desplazado. Porqué: docs/efectos/bloom.md §«Bloom de niebla».
    let t = 1.0 - max(1.0 - textureSampleLevel(volumen, linear_sampler, uv, 0.0).a, ancho4.a);
    let mult = OPC_BLOOM_NIEBLA * (1.0 + 0.5 * frame.rain) + OPC_BLOOM_NIEBLA_AGUA * frame.in_water;
    let borde = smoothstep(0.0, 0.05, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
    // Al cuadrado: solo la niebla espesa; la bruma de día (opacidad 0,2–0,4) mezclaba media imagen con el
    // desenfoque ancho y la lavaba.
    let opaco = clamp((1.0 - t) * mult, 0.0, 1.0);
    let niebla = opaco * opaco * borde;
    return mix(color, ancho, niebla) + b * o.bloom * vineta * borde;
}

// Ceguera y oscuridad del Warden: Horizon las aplica a su niebla, que el pack apaga; se oscurece con la
// distancia hasta negro a pocos bloques.
fn adp_estado_jugador(color: vec3<f32>, distancia: f32) -> vec3<f32> {
    let efecto = max(frame.blindness, frame.darkness);
    if efecto <= 0.0 {
        return color;
    }
    let alcance = mix(64.0, 4.0, efecto);
    return color * exp(-distancia / alcance * 2.0) * mix(1.0, 0.6, frame.darkness);
}
