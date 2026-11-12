// El rayo de cada píxel de la pasada de volumen y lo que necesita el bucle. Solo en post.
// Porqué: docs/efectos/niebla-y-nubes.md §Adaptadores

fn adp_volumen_rayo(uv: vec2<f32>, pixel: vec2<f32>) -> VolRayo {
    let d = depth_at(uv);
    var dir: vec3<f32>;
    var escena = 1e9;
    if d <= 0.0 {
        dir = normalize(view_position(uv, 1e-4));
        // Cielo mirando hacia abajo (más allá de la distancia de renderizado): el rayo acaba en el plano del
        // mar, como si el suelo siguiera. Sin esto la niebla se integraba cientos de bloques bajo el mundo,
        // donde las manchas ya no caen con la altura, y daba un velo opaco visto desde encima de las nubes.
        if dir.y < 0.0 {
            escena = max(frame.camera_position.y - VOL_MAR, 0.0) / -dir.y;
        }
    } else {
        let p = view_position(uv, d);
        escena = length(p);
        dir = p / escena;
    }
    let ruido = adp_ruido_azul(pixel, 0u);
    return VolRayo(frame.camera_position, dir, escena, ruido, d <= 0.0);
}

fn adp_volumen_luz() -> VolLuz {
    let c = opc_cielo();
    // El ambiente de la niebla y del aire es el del cielo despejado (implementacion/02 §3b), por la luz de cielo suavizada
    // de la cámara (bajo techo se apaga); la niebla toma 3/4 y el aire la mitad (fino/05 P2–P3), en el núcleo.
    let elev = degrees(asin(clamp(frame.sun_direction.y, -1.0, 1.0)));
    let cielo = atm_ambiente_cielo(elev) * frame.eye_light_smooth.y;
    return VolLuz(frame.light_direction, adp_irradiancia_astro(c), cielo, adp_suelo(c) * OPC_LUZ_CIELO_BASE);
}

// Peso del bloom de niebla (10), en el alfa de la composición (fino/10 «Respuesta a la pregunta 10», medido): en el mundo
// principal el terreno y el cielo valen 0 aunque haya niebla o nubes; a través del agua o de un translúcido, 0,75 de
// la opacidad del volumen que hay detrás; con la cámara bajo el agua, la opacidad del agua.
// Porqué: docs/efectos/bloom.md §«Bloom de niebla del original» (F-20)
fn adp_opacidad_bloom_niebla(v: VolResultado, p: AdpPixel) -> f32 {
    let opacidad = 1.0 - v.transmitancia;
    if frame.in_water > 0.5 || !adp_es_superficie() {
        return opacidad;
    }
    if p.es_cielo || surface_at(vec2<i32>(p.pixel)).present {
        return 0.0;
    }
    return OPC_BLOOM_NIEBLA_TRANSLUCIDO * opacidad;
}

fn adp_volumen_ajustes(bajo_agua: bool) -> VolAjustes {
    let o = opc_volumen();
    let m = adp_momento(o);
    let h = adp_horario();
    // En una cueva no entra la niebla de cielo: queda una tenue.
    let fuera = smoothstep(0.1, 0.7, frame.eye_light_smooth.y);
    let lluvia = frame.rain * o.lluvia;

    // En lluvia se conmuta a los perfiles de lluvia para nubes y niebla (fino/05 §4 y paridad/05)
    let pl = vol_perfil_lluvia(u32(max(m.dia, 0.0)), lluvia);
    let peso_lluvia = smoothstep(0.0, 0.5, lluvia);
    let param_unif_base = mix(h.uniforme, pl.niebla_uniforme, peso_lluvia);
    let param_manchas_base = mix(h.manchas, pl.niebla_manchas, peso_lluvia);

    // Niebla local (21): con un perfil activo la global se apaga (no se suman).
    let local = adp_niebla_local(u32(max(m.dia, 0.0)), fuera);
    let sin_global = 1.0 - local.peso;
    let uniforme = param_unif_base * mix(0.05, 1.0, fuera) * sin_global;
    let manchas = param_manchas_base * fuera * sin_global;
    let viento = vec3<f32>(OPC_VIENTO.x, 0.0, OPC_VIENTO.y) * o.viento * frame.time * 0.5;
    let niebla = VolAjustesNiebla(uniforme, manchas, o.cantidad, o.bruma, o.caida, viento, 1.0);
    let con_niebla = o.niebla && !bajo_agua;
    let mapa = LuzMapa(frame.shadow_view_proj, frame.shadow_distortion);
    let viento_local = viento * OPC_LOCAL_VIENTO + vec3<f32>(0.0, frame.time * OPC_LOCAL_DESCENSO, 0.0);
    let medio_local = VolNieblaLocal(local.uniforme * o.cantidad, local.manchas * o.cantidad, local.color, viento_local);
    return VolAjustes(niebla, adp_nubes(), o.alcance, o.pasos, o.pasos_nubes, con_niebla, o.nubes,
                      frame.has_shadow == 1u, o.sombra_nubes, mapa, adp_aurora(o.alcance), medio_local, OPC_LOCAL_ALCANCE);
}

struct AdpNieblaLocal {
    uniforme: f32,
    manchas: f32,
    color: vec3<f32>,
    peso: f32,              // 0..1: cuánto sustituye a la niebla global
}

// El perfil local del momento (21), decidido por el bioma de la cámara: calor o frío con la lluvia (uno de tres por día,
// con el sorteo diario de la lluvia), y pantano o jungla siempre. La categoría del bioma la da el mod (`mods[1].w`); sin
// él, por la temperatura y la humedad de vanilla. Sin suavizado temporal (no hay memoria): el clima entra con la fuerza de
// la lluvia y el bioma, de golpe al cruzar la frontera. Porqué: docs/efectos/niebla-local.md (F-28)
fn adp_niebla_local(dia: u32, fuera: f32) -> AdpNieblaLocal {
    var r = AdpNieblaLocal(0.0, 0.0, vec3<f32>(0.0), 0.0);
    let t = frame.temperature;
    let lluvia = smoothstep(0.0, OPC_LOCAL_RAMPA_LLUVIA, frame.rain);
    if lluvia > 0.0 && t > OPC_LOCAL_CALOR && frame.precipitation == 0u {
        let k = dia % 3u;
        r = AdpNieblaLocal(OPC_LOCAL_CALOR_UNIF[k], OPC_LOCAL_CALOR_MANCHAS[k], OPC_LOCAL_CALOR_COLOR[k], lluvia);
    } else if lluvia > 0.0 && t < OPC_LOCAL_FRIO && frame.precipitation == 2u {
        let k = dia % 3u;
        r = AdpNieblaLocal(OPC_LOCAL_FRIO_UNIF[k], OPC_LOCAL_FRIO_MANCHAS[k], OPC_LOCAL_FRIO_COLOR, lluvia);
    } else {
        var categoria = 0u;
        if abs(frame.mods[0].x - ADP_MOD_FIRMA_V1) < 0.5 && frame.mods[1].w > 0.5 {
            categoria = u32(round(frame.mods[1].w));
        } else if abs(t - 0.8) < 0.03 && abs(frame.downfall - 0.9) < 0.03 {
            categoria = 1u;
        } else if abs(t - 0.95) < 0.03 && frame.downfall > 0.77 && frame.downfall < 0.93 {
            categoria = 2u;
        }
        if categoria >= 1u && categoria <= 3u {
            let k = categoria - 1u;
            r = AdpNieblaLocal(OPC_LOCAL_BIOMA_UNIF[k], OPC_LOCAL_BIOMA_MANCHAS[k], OPC_LOCAL_BIOMA_COLOR[k], 1.0);
        }
    }
    r.uniforme *= r.peso * fuera;
    r.manchas *= r.peso * fuera;
    return r;
}

fn adp_volumen(uv: vec2<f32>, pixel: vec2<f32>) -> VolResultado {
    if !adp_es_superficie() {
        // Nether y End (17): su propia niebla; nada del Overworld (nubes, horario, aurora).
        let fc = frame.fog_color;
        let bruma = col_srgb_a_lineal(fc / max(max(fc.r, max(fc.g, fc.b)), 1e-3));
        let d = VolDimension(bruma, select(opc_niebla_end(), opc_niebla_nether(), frame.dimension == -1), frame.time);
        if frame.dimension == -1 {
            return vol_nether(adp_volumen_rayo(uv, pixel), d, ruido2d, ruido2d_sampler, ruido3d);
        }
        return vol_end(adp_volumen_rayo(uv, pixel), d, ruido3d);
    }
    let bajo_agua = adp_pixel_bajo_agua(uv);
    if bajo_agua {
        // Con la cámara bajo el agua, la niebla del agua sustituye a la de aire (07).
        let oa = opc_agua(adp_tiempo().segundos, frame.rain);
        let plano = adp_plano_agua_cercano();
        // La superficie congelada al entrar (fino/07 §7), no derivada de la cámara: así la luz no salta al subir o bajar.
        var superficie = adp_altura_entrada();
        if plano.y > 0.5 {
            superficie = frame.camera_position.y + plano.x;
        }
        let agua = VolAgua(superficie, opc_agua_medio(oa.claridad), vec3<f32>(OPC_LUZ_MINIMA * 40.0 * OPC_AGUA_MINIMO));
        return vol_agua(adp_volumen_rayo(uv, pixel), adp_volumen_luz(), agua, LuzMapa(frame.shadow_view_proj, frame.shadow_distortion),
                        shadow_map, shadow_sampler, frame.has_shadow == 1u);
    }
    return vol_integrar(adp_volumen_rayo(uv, pixel), adp_volumen_luz(), adp_volumen_ajustes(bajo_agua),
                        shadow_map, shadow_sampler, ruido2d, ruido2d_sampler, ruido3d, mapa_aurora, linear_sampler);
}

// Salida de la pasada de volumen: luz ya expuesta (no se pierde en media precisión) y transmitancia.
fn adp_volumen_salida(r: VolResultado) -> vec4<f32> {
    return vec4<f32>(r.luz * adp_codificacion().exposicion, r.transmitancia);
}

// Composición: el volumen de media resolución reescalado con pesos por parecido de distancia (filtro
// bilateral de 4 vecinos), para que no haya halos en los bordes de los objetos.
fn adp_volumen_reescalado(pixel: vec2<f32>, distancia: f32) -> VolResultado {
    let lado = vec2<f32>(textureDimensions(volumen));
    let q = pixel * 0.5 - 0.5;
    // Sobre el cielo no hay bordes que respetar: un filtro de tienda 3×3 de texeles del volumen que también sean cielo quita
    // el grano del tramado en los bordes tenues de las nubes (el original lo acumula en el tiempo, fino/05 §6; aquí no hay
    // destino libre para un historial del volumen). Porqué: docs/efectos/niebla-y-nubes.md §«Grano del borde» (F-23)
    if distancia >= 1e5 {
        let centro = floor(q + 0.5);
        var suma_c = vec4<f32>(0.0);
        var pesos_c = 0.0;
        for (var k = 0; k < 9; k++) {
            let o = vec2<f32>(f32(k % 3) - 1.0, f32(k / 3) - 1.0);
            let texel = clamp(centro + o, vec2<f32>(0.0), lado - 1.0);
            let uv = (texel + 0.5) / lado;
            if depth_at(uv) > 0.0 {
                continue;
            }
            let dq = abs(texel - q);
            let w = max(1.5 - dq.x, 0.0) * max(1.5 - dq.y, 0.0);
            suma_c += textureLoad(volumen, vec2<i32>(texel), 0) * w;
            pesos_c += w;
        }
        if pesos_c > 0.0 {
            let v = suma_c / pesos_c;
            return VolResultado(v.rgb / adp_codificacion().exposicion, v.a, 0.0, vec3<f32>(0.0));
        }
    }
    let base = floor(q);
    let f = q - base;
    var suma = vec4<f32>(0.0);
    var pesos = 0.0;
    for (var k = 0; k < 4; k++) {
        let o = vec2<f32>(f32(k & 1), f32(k >> 1));
        let texel = clamp(base + o, vec2<f32>(0.0), lado - 1.0);
        let uv = (texel + 0.5) / lado;
        let d = depth_at(uv);
        let dist = select(length(view_position(uv, d)), 1e6, d <= 0.0);
        let w_bil = mix(1.0 - f, f, o);
        let parecido = 1.0 / (1e-3 + abs(dist - distancia) / max(distancia, 1.0));
        let w = w_bil.x * w_bil.y * min(parecido, 1000.0);
        suma += textureLoad(volumen, vec2<i32>(texel), 0) * w;
        pesos += w;
    }
    let v = suma / max(pesos, 1e-6);
    return VolResultado(v.rgb / adp_codificacion().exposicion, v.a, 0.0, vec3<f32>(0.0));
}

// Cámara dentro de lava o de nieve en polvo (05 §«Cámara dentro de lava…»): niebla exponencial por distancia sobre todo,
// como la de vanilla que el pack apaga. Porqué: docs/efectos/niebla-y-nubes.md §Lava y nieve en polvo
fn adp_niebla_inmersion(color: vec3<f32>, distancia: f32) -> vec3<f32> {
    let lava = max(frame.in_lava, select(0.0, 1.0, frame.eye_in == 2u));
    let nieve = select(0.0, 1.0, frame.eye_in == 3u);
    if lava <= 0.0 && nieve <= 0.0 {
        return color;
    }
    let e = adp_codificacion().exposicion;
    // Colores en la escala de la escena: la lava, brillante (como su emisión); la nieve, la luz que entra.
    let c_lava = vec3<f32>(1.0, 0.35, 0.08) * 1.5 / e;
    let c_nieve = vec3<f32>(0.8, 0.88, 1.0) * 0.8 / e;
    var c = mix(color, c_nieve, (1.0 - exp(-distancia / 1.2)) * nieve);
    c = mix(c, c_lava, (1.0 - exp(-distancia / 0.5)) * lava);
    return c;
}

// Niebla de cueva (05.3): añade una niebla tenue azul oscura que crece con la distancia.
// Porqué: docs/efectos/niebla-y-nubes.md §Niebla de cueva
fn adp_niebla_cueva(color: vec3<f32>, p: AdpPixel, dir: vec3<f32>) -> vec3<f32> {
    if p.es_cielo || !adp_es_superficie() || frame.in_water > 0.0 || frame.in_lava > 0.0 || frame.eye_in != 0u {
        return color;
    }
    let o = opc_niebla_cueva();
    let cueva = 1.0 - smoothstep(0.05, 0.35, frame.eye_light_smooth.y);
    let d = adp_post_distancia(p);
    return color + vol_niebla_cueva(d, dir.y, cueva, o);
}

// Transmitancia para componer la escena: con la cámara bajo el agua, por canal (Beer-Lambert con la absorción del
// agua a lo largo de la vista, la misma del raymarch del agua): el rojo se pierde antes que el verde y el azul (07.1).
// El destino del volumen solo guarda una transmitancia, la luminancia. Porqué: docs/efectos/agua.md §Bajo el agua
fn adp_transmitancia_compuesta(v: VolResultado, distancia: f32, uv: vec2<f32>) -> vec3<f32> {
    if !adp_pixel_bajo_agua(uv) {
        return vec3<f32>(v.transmitancia);
    }
    let oa = opc_agua(adp_tiempo().segundos, frame.rain);
    let m = opc_agua_medio(oa.claridad);
    let d = min(distancia, 96.0);
    return exp(-m.absorcion * d);
}
