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
    cielo = mix(cielo, vec3<f32>(col_luminancia(cielo)) * 0.8, cubierto) * (1.0 - 0.5 * frame.thunder);
    return VolLuz(frame.light_direction, adp_irradiancia_astro(c), cielo, adp_suelo(c) * OPC_LUZ_CIELO_BASE);
}

fn adp_volumen_ajustes() -> VolAjustes {
    let o = opc_volumen();
    let h = vol_horario(frame.day_time);
    // En una cueva no entra la niebla de cielo: queda una tenue.
    let fuera = smoothstep(0.1, 0.7, frame.eye_light_smooth.y);
    let lluvia = frame.rain * o.lluvia;
    // Tormenta de nieve: lluvia en un bioma donde nieva (precipitation 2): densa y blanca.
    let nieve = select(0.0, frame.rain, frame.precipitation == 2u);
    let uniforme = (h.uniforme + lluvia * 0.5 + nieve * 1.2) * mix(0.05, 1.0, fuera);
    let manchas = (h.manchas + lluvia * 0.4 + nieve * 0.5 + clamp(frame.downfall - 0.85, 0.0, 0.15) * 2.5 * smoothstep(0.5, 0.9, frame.temperature)) * fuera;
    let viento = vec3<f32>(OPC_VIENTO.x, 0.0, OPC_VIENTO.y) * o.viento * frame.time * 0.5;
    let niebla = VolAjustesNiebla(uniforme, manchas, o.cantidad, o.bruma, o.caida, viento, mix(1.0, 8.0, nieve));
    let con_niebla = o.niebla && frame.in_water < 0.5;
    let mapa = LuzMapa(frame.shadow_view_proj, frame.shadow_distortion);
    return VolAjustes(niebla, adp_nubes(), o.alcance, o.pasos, o.pasos_nubes, con_niebla, o.nubes,
                      frame.has_shadow == 1u, o.sombra_nubes, mapa, adp_aurora(o.alcance));
}

fn adp_volumen(uv: vec2<f32>, pixel: vec2<f32>) -> VolResultado {
    return vol_integrar(adp_volumen_rayo(uv, pixel), adp_volumen_luz(), adp_volumen_ajustes(),
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
