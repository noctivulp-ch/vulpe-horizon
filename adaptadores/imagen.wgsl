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
    if texel.y != 0 || texel.x > 3 {
        return vec4<f32>(rgb, 0.0);
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
    if texel.y == 0 && texel.x <= 3 {
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
    // Sin medida aún, lo oscuro o lo claro según la hora.
    var claridad = adp_factor_dia();
    if estado.x > 0.0 && exposicion_auto {
        let automatica = img_exposicion_tabla(estado.x);
        e = exp2(mix(log2(previa), log2(automatica), OPC_EXPOSICION_PESO_AUTO));
        claridad = smoothstep(log2(OPC_EXPOSICION_L_OSCURO), log2(OPC_EXPOSICION_L_CLARO), log2(estado.x));
    }
    // Oscuridad mínima y máxima (fase 2b, punto 5): pasos aparte para lo oscuro y lo claro.
    e *= exp2(mix(o.oscuro, o.claro, claridad));
    var bastones = select(0.0, col_peso_bastones(estado.y, OPC_BASTONES_L0), estado.y > 0.0) * (OPC_PURKINJE * opc_estilo_noches().mult_purkinje);
    // Fuera del Overworld no hay noche que adaptar (17): sin Purkinje (teñía de azul el Nether).
    bastones *= select(0.0, 1.0, adp_es_superficie());
    // En cuevas o interiores sin cielo no hay visión escotópica exterior (fino/03 §3 y banco cueva-oscura).
    bastones *= smoothstep(0.0, 0.15, frame.eye_light_smooth.y);
    // Junto a una fuente de luz (luz de bloque en la cámara) el ojo no está en visión escotópica: los colores de las
    // antorchas no se pierden en el azul (visto con el 03.1).
    bastones *= 1.0 - smoothstep(0.15, 0.6, frame.eye_light_smooth.x);
    // Visión nocturna: sin Purkinje y exposición alta.
    bastones *= 1.0 - frame.night_vision;
    e *= mix(1.0, 4.0, frame.night_vision);
    return AdpExposicion(e * o.compensacion, bastones);
}

// Destello del sol en el bloom: la parte de la radiancia del disco que la codificación de 8 bits recorta (ADR 0004)
// se devuelve con la respuesta del bloom del original, pesada por la parte visible del disco (profundidad) y por la
// transmitancia del volumen (nubes y niebla) delante del sol. Porqué: docs/efectos/bloom.md §Destello del sol
fn adp_destello_sol(uv: vec2<f32>) -> vec3<f32> {
    let d_sol = frame.sun_direction;
    if !adp_es_superficie() || d_sol.y <= 0.0 || frame.rain >= 1.0 {
        return vec3<f32>(0.0);
    }
    let h = frame.projection * frame.view * vec4<f32>(d_sol, 0.0);
    if h.w <= 1e-4 {
        return vec3<f32>(0.0);
    }
    let uv_sol = mat_ndc_a_uv(h.xy / h.w);
    let aspecto = frame.resolution.x / frame.resolution.y;
    // Radio del disco en unidades del alto de pantalla.
    let rho = tan(OPC_SOL_DISCO_RADIO) * frame.projection[1][1] * 0.5;
    if any(uv_sol < vec2<f32>(-rho)) || any(uv_sol > vec2<f32>(1.0 + rho)) {
        return vec3<f32>(0.0);
    }
    var visible = select(0.0, 1.0, depth_at(clamp(uv_sol, vec2<f32>(0.0), vec2<f32>(1.0))) <= 0.0);
    for (var i = 0; i < OPC_DESTELLO_MUESTRAS; i++) {
        let a = f32(i) * MAT_TAU / f32(OPC_DESTELLO_MUESTRAS);
        let m = uv_sol + vec2<f32>(cos(a) / aspecto, sin(a)) * rho * 0.7;
        let dentro = all(m >= vec2<f32>(0.0)) && all(m <= vec2<f32>(1.0));
        visible += select(0.0, 1.0, dentro && depth_at(clamp(m, vec2<f32>(0.0), vec2<f32>(1.0))) <= 0.0);
    }
    visible /= f32(OPC_DESTELLO_MUESTRAS + 1);
    if visible <= 0.0 {
        return vec3<f32>(0.0);
    }
    let t_vol = textureSampleLevel(volumen, linear_sampler, clamp(uv_sol, vec2<f32>(0.0), vec2<f32>(1.0)), 0.0).a;
    let elev = degrees(asin(clamp(d_sol.y, -1.0, 1.0)));
    let disco = atm_luz_directa_sol(elev) * opc_cielo().sol_color * OPC_SOL_DISCO_BRILLO * t_vol * (1.0 - frame.rain);
    let techo = OPC_BLANCO / adp_codificacion().exposicion;
    let exceso = max(disco - vec3<f32>(techo), vec3<f32>(0.0)) * visible;
    let d = length((uv - uv_sol) * vec2<f32>(aspecto, 1.0));
    return img_destello(exceso, MAT_PI * rho * rho, d, OPC_BLOOM_ENERGIA);
}

// Bloom de la pasada final: núcleo (bicúbico de bloom) más ancho (bloom2), y bloom de niebla.
fn adp_bloom_final(color: vec3<f32>, uv: vec2<f32>, o: OpcImagen) -> vec3<f32> {
    let nucleo = img_catmull_rom(bloom, linear_sampler, uv, 1.0);
    let ancho4 = textureSampleLevel(bloom2, linear_sampler, uv, 0.0);
    let ancho = ancho4.rgb;
    let b = mix(ancho, nucleo, OPC_BLOOM_NUCLEO) + adp_destello_sol(uv);
    let vineta = mix(OPC_BLOOM_VINETA_CENTRO, OPC_BLOOM_VINETA_ESQUINA, saturate(length(uv - 0.5) * 1.41421356));
    // La opacidad de la niebla del propio píxel, sin nubes, que deja la composición en su alfa (pasa por el TAA).
    // Porqué: docs/efectos/bloom.md §«Bloom de niebla» (F-11).
    let t = 1.0 - textureSampleLevel(previous, nearest_sampler, uv, 0.0).a;
    let mult = bloom_niebla * mix(1.0, OPC_BLOOM_NIEBLA_AGUA, frame.in_water);
    let borde = smoothstep(0.0, 0.05, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
    // Mezcla lineal con la opacidad (el cuadrado de 10 no era del original).
    let niebla = clamp((1.0 - t) * mult, 0.0, 1.0) * borde;
    return mix(color, mix(ancho, nucleo, OPC_BLOOM_NIEBLA_NUCLEO), niebla) + b * o.bloom * vineta * borde;
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

// Gotas en la cámara al salir del agua (07.2). Porqué: docs/efectos/agua.md §Gotas en la cámara
fn adp_gotas_camara(uv: vec2<f32>) -> ImgGotasResultado {
    if frame.eye_in != 0u || frame.in_water <= 0.001 {
        return ImgGotasResultado(uv, 0.0);
    }
    let t_salida = -log2(clamp(frame.in_water, 0.001, 1.0)) * 0.25;
    let aspecto = frame.resolution.x / max(frame.resolution.y, 1.0);
    return img_gotas_lente(uv, aspecto, t_salida, opc_gotas());
}

