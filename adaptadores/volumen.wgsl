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
    var cielo = adp_cielo_medio(c) * OPC_LUZ_CIELO_BASE;
    let cubierto = clamp(frame.rain, 0.0, 1.0);
    cielo = mix(cielo, vec3<f32>(col_luminancia(cielo)) * 1.15, cubierto * 0.4);
    // De noche la niebla toma el azul del cielo nocturno (05.2): su ambiente, más saturado y más fuerte; sin esto salía
    // gris. Porqué: docs/efectos/niebla-y-nubes.md §Niebla nocturna
    let noche = adp_factor_noche() * (1.0 - cubierto);
    cielo = mix(cielo, col_saturar(cielo, 5.0) * 2.0, noche);
    return VolLuz(frame.light_direction, adp_irradiancia_astro(c), cielo, adp_suelo(c) * OPC_LUZ_CIELO_BASE);
}

fn adp_volumen_ajustes(bajo_agua: bool) -> VolAjustes {
    let o = opc_volumen();
    let m = adp_momento(o);
    let h = adp_horario();
    // En una cueva no entra la niebla de cielo: queda una tenue.
    let fuera = smoothstep(0.1, 0.7, frame.eye_light_smooth.y);
    let lluvia = frame.rain * o.lluvia;
    // Tormenta de nieve: lluvia en un bioma donde nieva (precipitation 2): densa y blanca.
    let nieve = select(0.0, frame.rain, frame.precipitation == 2u);

    // En lluvia se conmuta a los perfiles de lluvia para nubes y niebla (fino/05 §4 y paridad/05)
    let pl = vol_perfil_lluvia(u32(max(m.dia, 0.0)), lluvia);
    let peso_lluvia = smoothstep(0.0, 0.5, lluvia);
    let param_unif_base = mix(h.uniforme, pl.niebla_uniforme, peso_lluvia);
    let param_manchas_base = mix(h.manchas, pl.niebla_manchas, peso_lluvia);

    let uniforme = (param_unif_base + nieve * 0.8) * mix(0.05, 1.0, fuera);
    let manchas = (param_manchas_base + nieve * 0.5 + clamp(frame.downfall - 0.85, 0.0, 0.15) * 2.5 * smoothstep(0.5, 0.9, frame.temperature)) * fuera;
    let viento = vec3<f32>(OPC_VIENTO.x, 0.0, OPC_VIENTO.y) * o.viento * frame.time * 0.5;
    let niebla = VolAjustesNiebla(uniforme, manchas, o.cantidad, o.bruma, o.caida, viento, mix(1.0, 8.0, nieve));
    let con_niebla = o.niebla && !bajo_agua;
    let mapa = LuzMapa(frame.shadow_view_proj, frame.shadow_distortion);
    return VolAjustes(niebla, adp_nubes(), o.alcance, o.pasos, o.pasos_nubes, con_niebla, o.nubes,
                      frame.has_shadow == 1u, o.sombra_nubes, mapa, adp_aurora(o.alcance));
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
        var superficie = select(frame.camera_position.y + 8.0, frame.water_plane, frame.has_reflection == 1u);
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
