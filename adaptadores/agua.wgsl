// El agua en el pase translúcido: lo que hay detrás (opaque_depth, opaque_color), el espejo de Horizon y el cielo
// del pack. Solo en material. Porqué: docs/efectos/agua.md §Adaptadores

fn adp_agua_opciones() -> OpcAgua {
    return opc_agua(adp_tiempo().segundos, frame.rain);
}

// Posición relativa a la cámara del punto de pantalla `uv` con la profundidad invertida `d`.
fn adp_agua_posicion(uv: vec2<f32>, d: f32) -> vec3<f32> {
    let inv = frame.view_inverse * frame.projection_inverse;
    return mat_proyectar(inv, vec3<f32>(mat_uv_a_ndc(uv), d));
}

fn adp_agua_profundidad_opaca(uv: vec2<f32>) -> f32 {
    let lado = vec2<f32>(textureDimensions(opaque_depth));
    return textureLoad(opaque_depth, vec2<i32>(clamp(uv * lado, vec2<f32>(0.0), lado - 1.0)), 0);
}

fn adp_agua_color_opaco(uv: vec2<f32>) -> vec3<f32> {
    let lado = vec2<f32>(textureDimensions(opaque_color));
    let c = textureLoad(opaque_color, vec2<i32>(clamp(uv * lado, vec2<f32>(0.0), lado - 1.0)), 0).rgb;
    return col_decodificar_escena(c, adp_codificacion());
}

struct AdpRefraccion {
    color: vec3<f32>,       // lo que hay detrás, en luz lineal
    distancia: f32,         // bloques de agua atravesados a lo largo de la vista
}

// Refracción en pantalla (Sousa 2005): desplazamiento por la normal tangente, caída sublineal por distancia,
// viñeta suave en bordes y dispersión cromática (fino/07 §3).
fn adp_agua_refraccion(p: AdpPunto, n: vec3<f32>, cantidad: f32) -> AdpRefraccion {
    let uv0 = p.pixel / frame.resolution;
    let dist = length(p.posicion);
    // Caída sublineal por distancia y protección suave de bordes (fino/07 §3)
    let dist_factor = select(1.0 + pow(dist, 0.75) * 0.08, 1.0 + dist * 0.015, frame.in_water > 0.5);
    let borde = smoothstep(0.0, 0.08, min(min(uv0.x, 1.0 - uv0.x), min(uv0.y, 1.0 - uv0.y)));
    let desplazamiento = (n.xz - p.normal_cara.xz) * cantidad * borde / dist_factor;
    var uv = uv0 + desplazamiento;
    var d = adp_agua_profundidad_opaca(uv);
    // Profundidad invertida: mayor = más cerca. Si lo desplazado está delante del agua, no refractar ahí.
    let d_agua = mat_proyectar(frame.projection * frame.view, p.posicion).z;
    if d > d_agua {
        uv = uv0;
        d = adp_agua_profundidad_opaca(uv);
    }
    var distancia = 200.0;
    if d > 0.0 {
        distancia = max(length(adp_agua_posicion(uv, d)) - dist, 0.0);
    }
    // Dispersión cromática simétrica en R y B (fino/07 §3)
    let desp_croma = (uv - uv0) * OPC_AGUA_DISPERSION_CROMATICA;
    var uv_r = uv + desp_croma;
    var uv_b = uv - desp_croma;
    if adp_agua_profundidad_opaca(uv_r) > d_agua {
        uv_r = uv;
    }
    if adp_agua_profundidad_opaca(uv_b) > d_agua {
        uv_b = uv;
    }
    let col_g = adp_agua_color_opaco(uv).g;
    let col_r = adp_agua_color_opaco(uv_r).r;
    let col_b = adp_agua_color_opaco(uv_b).b;
    return AdpRefraccion(vec3<f32>(col_r, col_g, col_b), distancia);
}

// Lo que se refleja: el espejo de Horizon con su cielo vanilla sustituido por el del pack y nubes reflejadas.
fn adp_agua_reflejo(p: AdpPunto, n: vec3<f32>, r: vec3<f32>, luces: AdpLuces) -> vec3<f32> {
    let c = opc_cielo();
    let horizonte = adp_tabla(frame.sun_direction.y, ATM_FILA_HORIZONTE) * c.sol_color * c.brillo;
    var cielo = vol_cielo_aproximado(horizonte, adp_cielo_medio(c), max(r.y, 0.0)) * OPC_CIELO_BRILLO_DIBUJO;
    // Nubes reflejadas en la dirección reflejada (subsistemas/07 §4)
    if r.y > 0.02 && opc_volumen().nubes {
        let nubes_cfg = adp_nubes();
        let h_nube = VOL_MAR + VOL_BASE[1];
        let t_plano = max((h_nube - p.mundo.y) / r.y, 0.0);
        let pos_nube = p.mundo.xz + r.xz * t_plano;
        let cob = vol_cobertura(pos_nube, 1, nubes_cfg, ruido2d, ruido2d_sampler);
        let lum_cielo = col_luminancia(cielo + luces.cielo * 0.5);
        cielo = mix(cielo, vec3<f32>(lum_cielo * 1.3), cob * 0.85);
    }
    // Disco del sol reflejado se hace con el especular
    if frame.has_reflection == 1u && abs(p.mundo.y - frame.water_plane) < 1.5 {
        let uv = p.pixel / frame.resolution + (n.xz - p.normal_cara.xz) * 0.03;
        let texel = textureSampleLevel(reflection, reflection_sampler, uv, 0.0);
        let peso = agu_peso_cielo(texel.rgb, r.y, frame.sky_color, frame.fog_color);
        var terreno = col_decodificar_escena(texel.rgb, adp_codificacion());
        // Alfa < 0,75: bloque emisivo (marca de HDR del motor): reforzarlo.
        terreno *= select(1.0, 3.0, texel.a < 0.75);
        return mix(terreno, cielo, peso);
    }
    return cielo;
}

// La luz del volumen de agua de este punto: las radiancias medidas del agua profunda (sol a 55°, todo iluminado), escaladas
// por la luz de cielo y la directa del momento, y por el estilo de agua. Porqué: docs/efectos/agua.md §«Color del agua profunda» (F-18)
fn adp_agua_luz_volumen(p: AdpPunto, luces: AdpLuces, sombra: f32, m: AguMedio) -> AguLuzVolumen {
    let cielo = col_luminancia(luces.cielo) * luz_curva_cielo(p.luz_cielo) / OPC_AGUA_FONDO_REF.y;
    let sol = col_luminancia(luces.directa) * sombra / OPC_AGUA_FONDO_REF.x;
    let estilo = (m.color_disperso / OPC_AGUA_COLOR_DISPERSO_REF) * (m.dispersion / OPC_AGUA_DISPERSION_REF);
    // De espaldas al sol la medida mezcla cielo y sol sin separar: a partes iguales.
    let espaldas = OPC_AGUA_FONDO_ESPALDAS * (0.5 * (cielo + sol)) * estilo;
    let hacia = (OPC_AGUA_FONDO_HACIA - OPC_AGUA_FONDO_ESPALDAS) * sol * estilo;
    let lh = luces.direccion.xz;
    let vh = -p.vista.xz;
    let w = 0.5 + 0.5 * dot(lh, vh) / max(length(lh) * length(vh), 1e-3);
    return AguLuzVolumen(espaldas, hacia, w, OPC_AGUA_FONDO_SATURACION);
}
