// Las pasadas de bloom y la final: el estado de la exposición en los texeles de esquina de los destinos de bloom
// (realimentación entre fotogramas sin compute), el bloom de niebla y los efectos de estado del jugador.
// Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Adaptadores y docs/efectos/bloom.md

// Texeles de esquina: (0,0).a la luminancia adaptada; (1,0).a la de los bastones (más lenta); (2,0).a el nivel del
// agua junto a la cámara (adaptadores/cruce_agua.wgsl).
fn adp_estado(t: texture_2d<f32>) -> vec2<f32> {
    return vec2<f32>(textureLoad(t, vec2<i32>(0, 0), 0).a, textureLoad(t, vec2<i32>(1, 0), 0).a);
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
fn adp_bloom_final(color: vec3<f32>, alfa_niebla: f32, uv: vec2<f32>, o: OpcImagen) -> vec3<f32> {
    let nucleo = img_catmull_rom(bloom, linear_sampler, uv, 1.0);
    let ancho4 = textureSampleLevel(bloom2, linear_sampler, uv, 0.0);
    let ancho = ancho4.rgb;
    let b = mix(ancho, nucleo, OPC_BLOOM_NUCLEO) + adp_destello_sol(uv);
    let vineta = mix(OPC_BLOOM_VINETA_CENTRO, OPC_BLOOM_VINETA_ESQUINA, saturate(length(uv - 0.5) * 1.41421356));
    // La opacidad de la niebla del propio píxel, sin nubes, que deja la composición en su alfa (pasa por el TAA); llega
    // de la muestra central de la nitidez. Porqué: docs/efectos/bloom.md §«Bloom de niebla» (F-11).
    let t = 1.0 - alfa_niebla;
    let mult = bloom_niebla * mix(1.0, OPC_BLOOM_NIEBLA_AGUA, frame.in_water);
    let borde = smoothstep(0.0, 0.05, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
    // Mezcla lineal con la opacidad (el cuadrado de 10 no era del original).
    let niebla = clamp((1.0 - t) * mult, 0.0, 1.0) * borde;
    return mix(color, mix(ancho, nucleo, OPC_BLOOM_NIEBLA_NUCLEO), niebla) + b * o.bloom * vineta * borde;
}


// Agua en la cámara (19): el estado del cruce está en el téxel (4,0) de bloom2. Porqué: docs/efectos/camara-y-juego.md
fn adp_gotas_camara(uv: vec2<f32>) -> ImgGotasResultado {
    let c = adp_cruce_decodificar(textureLoad(bloom2, vec2<i32>(4, 0), 0).a);
    if c.t < 0.0 {
        return ImgGotasResultado(uv, 0.0);
    }
    let aspecto = frame.resolution.x / max(frame.resolution.y, 1.0);
    // Sentido en pantalla: el del cruce vertical (al salir sube, al entrar baja).
    let vel = vec2<f32>(0.0, select(c.rapidez, -c.rapidez, c.salida));
    return img_agua_camara(uv, aspecto, c.t, c.salida, vel, opc_gotas());
}

// Calor (19): en lava (frame.in_lava, ya suavizado) o en llamas con el mod (mods[3].z). Porqué: docs/efectos/camara-y-juego.md
fn adp_calor(uv: vec2<f32>) -> vec2<f32> {
    let m = adp_mod();
    let llamas = select(0.0, m.jugador.en_llamas, m.jugador.activo);
    let nivel = max(frame.in_lava, llamas);
    let aspecto = frame.resolution.x / max(frame.resolution.y, 1.0);
    return img_calor(uv, aspecto, adp_tiempo().segundos, nivel, OPC_CALOR_FUERZA);
}

// Estado del cruce del agua en un solo valor (texel (4,0).a): 0 sin cruce; si no, ±(1 + 8·nivel de rapidez + t),
// positivo al salir y negativo al entrar, con t en segundos (< 8) y la rapidez en 8 niveles de 2 bloques/s.
struct AdpCruce {
    t: f32,             // segundos desde el cruce (negativo: sin efecto)
    salida: bool,
    rapidez: f32,       // bloques/s
}

fn adp_cruce_decodificar(v: f32) -> AdpCruce {
    let a = abs(v) - 1.0;
    if a < 0.0 {
        return AdpCruce(-1.0, false, 0.0);
    }
    let nivel = floor(a / 8.0);
    return AdpCruce(a - nivel * 8.0, v > 0.0, nivel * 2.0 + 1.0);
}

fn adp_cruce_codificar(t: f32, salida: bool, rapidez: f32) -> f32 {
    let nivel = clamp(floor(rapidez / 2.0), 0.0, 7.0);
    return select(-1.0, 1.0, salida) * (1.0 + nivel * 8.0 + clamp(t, 0.0, 7.9));
}



// Desenfoque de movimiento (19, opción `desenfoque_movimiento`): tres muestras más a lo largo del desplazamiento del
// píxel (reproyección por profundidad con la vista anterior), con tramado; la mano no se desenfoca.
// Porqué: docs/efectos/camara-y-juego.md §«Ajustes de cámara»
fn adp_desenfoque_movimiento(c: vec3<f32>, uv: vec2<f32>, p: AdpPixel) -> vec3<f32> {
    if desenfoque_movimiento <= 0 || frame.delta_time <= 0.0 {
        return c;
    }
    var rel = vec3<f32>(0.0);
    if p.es_cielo {
        rel = adp_post_direccion(p) * 1e4;
    } else {
        rel = view_position(p.uv, p.profundidad);
        if length(rel) < OPC_CAM_MANO {
            return c;
        }
    }
    let ndc = mat_proyectar(frame.previous_view_projection, rel + frame.camera_motion).xy;
    let antes = vec2<f32>(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5);
    let v = img_movimiento(uv, antes, frame.delta_time, f32(desenfoque_movimiento) / 100.0);
    let j = adp_ruido_azul(p.pixel, 3u);
    var suma = c;
    for (var i = 1; i <= 3; i++) {
        suma += textureSampleLevel(previous, linear_sampler, uv - v * ((f32(i) - 1.0 + j) / 3.0), 0.0).rgb;
    }
    return suma * 0.25;
}

// Viñeta, grano, bandas de cine y líneas de encuadre (19), sobre la imagen sRGB. Todos en 0: no hace nada.
fn adp_camara_final(c: vec3<f32>, p: AdpPixel) -> vec3<f32> {
    var s = c;
    if OPC_CAM_VINETA > 0.0 {
        s *= img_vineta(p.uv, frame.resolution.x / frame.resolution.y, OPC_CAM_VINETA);
    }
    if OPC_CAM_GRANO > 0.0 {
        // Ruido blanco por canal, distinto en cada fotograma con un ciclo de 60.
        let r = rui_hash33(vec3<i32>(vec2<i32>(p.pixel), i32(frame.frame_index % 60u)));
        s = img_grano(s, r, OPC_CAM_GRANO);
    }
    if OPC_CAM_BANDAS_ALTO > 0.0 || OPC_CAM_BANDAS_ANCHO > 0.0 {
        s *= img_bandas(p.uv, OPC_CAM_BANDAS_ALTO, OPC_CAM_BANDAS_ANCHO);
    }
    if OPC_CAM_TERCIOS {
        s = mix(s, vec3<f32>(1.0), 0.5 * img_tercios(p.pixel, frame.resolution));
    }
    return s;
}

