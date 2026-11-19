// Adaptador del efecto «el tiempo en los cristales» (27): lee el estado por cuadro de `datos_cuadro` y lo
// compone con la óptica del cristal de `22` (refracción, desenfoque, reflejo y especular) y los cristales transparentes.
// Porqué: docs/efectos/tiempo-en-los-cristales.md

struct AdpCristalResultado {
    normal: vec3<f32>,      // normal perturbada por las gotas o escarcha
    refraccion: f32,        // fuerza de refracción en pantalla
    desenfoque: f32,        // 0..1 borrosidad detrás del cristal (escarcha)
    f0_extra: f32,          // reflejo adicional en cristal mojado
    oscurecer_fondo: f32,   // 0..1 oscurecimiento sutil del borde de la gota
    capa_color: vec3<f32>,  // color iluminado de las capas translúcidas/opacas encima (escarcha, nieve, arena)
    capa_opacidad: f32,     // 0..1 mezcla sobre el fondo refractado
    especular_extra: vec3<f32>,
    cobertura_cutout: f32,  // 0..1 cobertura para cristal transparente (cutout)
    color_cutout: vec3<f32>,// color de los texeles dibujados en cristal transparente
}

// Refracción en pantalla para caras verticales y horizontales de cristal: proyecta el desvío de normal al plano
// de vista para que las gotas actúen como lentes en cualquier orientación (N/S/E/O y horizontal), y aplica un
// desenfoque de 4 muestras detrás de la escarcha protegiendo la profundidad delantera.
fn adp_cristal_refraccion(p: AdpPunto, n: vec3<f32>, cantidad: f32, desenfoque: f32) -> AdpRefraccion {
    let uv0 = p.pixel / frame.resolution;
    let dist = length(p.posicion);
    let dist_factor = 1.0 + pow(dist, 0.75) * 0.08;
    let borde = smoothstep(0.0, 0.08, min(min(uv0.x, 1.0 - uv0.x), min(uv0.y, 1.0 - uv0.y)));
    let dn_vista = (frame.view * vec4<f32>(n - p.normal_cara, 0.0)).xy;
    let desplazamiento = vec2<f32>(dn_vista.x, -dn_vista.y) * cantidad * borde / dist_factor;
    var uv = uv0 + desplazamiento;
    let d_cristal = mat_proyectar(frame.projection * frame.view, p.posicion).z;
    if adp_agua_profundidad_opaca(uv) > d_cristal {
        uv = uv0;
    }
    let desp_croma = (uv - uv0) * OPC_AGUA_DISPERSION_CROMATICA;
    var uv_r = uv + desp_croma;
    var uv_b = uv - desp_croma;
    if adp_agua_profundidad_opaca(uv_r) > d_cristal {
        uv_r = uv;
    }
    if adp_agua_profundidad_opaca(uv_b) > d_cristal {
        uv_b = uv;
    }
    var col = vec3<f32>(
        adp_agua_color_opaco(uv_r).r,
        adp_agua_color_opaco(uv).g,
        adp_agua_color_opaco(uv_b).b,
    );

    // Escarcha (27 §2): dispersa la luz y emborrona lo de detrás (solo cuando hay escarcha en el píxel).
    if desenfoque > 0.01 {
        let radio = OPC_CRISTAL_ESCARCHA_DESENFOQUE * desenfoque * borde / (1.0 + dist * 0.04);
        let aspecto = frame.resolution.y / max(frame.resolution.x, 1.0);
        let paso = vec2<f32>(radio * aspecto, radio);
        let offs = array<vec2<f32>, 4>(
            vec2<f32>(paso.x, paso.y),
            vec2<f32>(-paso.x, paso.y),
            vec2<f32>(paso.x, -paso.y),
            vec2<f32>(-paso.x, -paso.y),
        );
        var suma = col;
        var peso = 1.0;
        for (var i = 0; i < 4; i++) {
            let u = clamp(uv + offs[i], vec2<f32>(0.0), vec2<f32>(1.0));
            if adp_agua_profundidad_opaca(u) <= d_cristal {
                suma += adp_agua_color_opaco(u);
                peso += 1.0;
            }
        }
        col = mix(col, suma / peso, desenfoque);
    }
    return AdpRefraccion(col, 0.0);
}

fn adp_cristal_evaluar(
    p: AdpPunto,
    n_base: vec3<f32>,
    luces: AdpLuces,
    sombra_luz: vec3<f32>,
    bloque_luz: vec3<f32>,
) -> AdpCristalResultado {
    var r = AdpCristalResultado(
        n_base,
        OPC_TRANSL_REFRACCION * 0.0006,
        0.0,
        0.0,
        0.0,
        vec3<f32>(0.0),
        0.0,
        vec3<f32>(0.0),
        0.0,
        vec3<f32>(0.0),
    );
    if !OPC_CRISTAL_ACTIVO || !adp_es_superficie() {
        return r;
    }

    let c0 = datos_cuadro[ADP_CUADRO_CRISTAL_0]; // x: lluvia_pico, y: secado (0..1), z: escala_lluvia, w: tormenta
    let c1 = datos_cuadro[ADP_CUADRO_CRISTAL_1]; // xy: viento_xz, z: escarcha, w: escala_nieve
    let c2 = datos_cuadro[ADP_CUADRO_CRISTAL_2]; // x: copos, y: monton, z: arena, w: escala_arena
    let cf = datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS]; // x: escarcha_interior, y: arena_roja, z: con_mod
    let plano = sup_cristal_plano(p.mundo, p.normal_cara);
    let dist = length(p.posicion);
    let curva_cielo = luz_curva_cielo(p.luz_cielo);

    // 1) Escarcha en el frío (27 §2).
    let esc = sup_cristal_escarcha(
        plano,
        p.luz_cielo,
        p.ao_vertice,
        c1.z,
        c1.w,
        cf.x > 0.5,
        dist,
    );

    // 2) Copos pegados y montón inferior de nieve (27 §3).
    let nieve = sup_cristal_nieve(
        plano,
        p.normal_cara,
        p.luz_cielo,
        p.ao_vertice,
        c1.xy,
        adp_tiempo().segundos,
        c2.x,
        c2.y,
        c1.w,
        dist,
    );

    // 3) Gotas de lluvia (27 §1): no se dibujan sobre escarcha gruesa ni sobre nieve (27 §Composición).
    let lluvia = sup_cristal_lluvia(
        plano,
        p.normal_cara,
        p.luz_cielo,
        c1.xy,
        adp_tiempo().segundos,
        c0.x,
        c0.y,
        c0.w,
        c0.z,
        dist,
    );
    let mascara_agua = (1.0 - smoothstep(0.35, 0.75, esc.cobertura)) * (1.0 - smoothstep(0.15, 0.55, nieve.cobertura));
    let gota = lluvia.gota * mascara_agua;
    let rastro = lluvia.rastro * mascara_agua;
    let cobertura_agua = max(gota, rastro * 0.7);

    if cobertura_agua <= 0.001 && lluvia.mojado <= 0.001 && esc.cobertura <= 0.001 && nieve.cobertura <= 0.001 {
        return r;
    }

    // Luz difusa + dispersión frontal (SSS) sobre capas del cristal (escarcha, nieve, arena).
    let n_l = max(dot(n_base, luces.direccion), 0.0);
    let contraluz = pow(max(dot(-p.vista, luces.direccion), 0.0), 3.0) * 0.35;
    let luz_capa = luces.directa * sombra_luz * (n_l + contraluz)
                 + luces.cielo * curva_cielo * 0.95
                 + bloque_luz
                 + vec3<f32>(OPC_LUZ_NOCHE_SUELO * curva_cielo);

    // Composición de dentro afuera (27 §Composición): escarcha -> gotas -> copos y montón de nieve.
    if esc.cobertura > 0.001 {
        let brillo_cristal = (0.35 + 1.4 * esc.cristalino) * (luces.directa * sombra_luz + luces.cielo * curva_cielo + bloque_luz);
        r.capa_color = OPC_CRISTAL_ESCARCHA_COLOR * luz_capa + brillo_cristal * (0.28 * esc.cobertura);
        r.capa_opacidad = clamp(esc.cobertura * OPC_CRISTAL_ESCARCHA_OPACIDAD, 0.0, 0.88);
        r.desenfoque = esc.borroso;
        let n_esc = normalize(n_base + plano.tangente * esc.grad_uv.x + plano.bitangente * esc.grad_uv.y);
        r.normal = normalize(mix(r.normal, n_esc, esc.cobertura * 0.45));
    }

    if cobertura_agua > 0.001 || lluvia.mojado > 0.001 {
        let grad_agua = lluvia.grad_uv * mascara_agua;
        let n_gota = normalize(
            n_base
            + plano.tangente * (grad_agua.x * 0.65)
            + plano.bitangente * (grad_agua.y * 0.65),
        );
        r.normal = normalize(mix(r.normal, n_gota, cobertura_agua));
        r.refraccion = mix(OPC_TRANSL_REFRACCION * 0.0006, OPC_CRISTAL_GOTA_REFRACCION, cobertura_agua);
        r.f0_extra = OPC_CRISTAL_MOJADO_F0_EXTRA * lluvia.mojado * mascara_agua + 0.04 * gota;
        r.oscurecer_fondo = lluvia.borde * mascara_agua * OPC_CRISTAL_GOTA_BORDE;

        let esp_astro = sup_especular(r.normal, p.vista, luces.direccion, 0.04, vec3<f32>(0.04))
                      * max(dot(r.normal, luces.direccion), 0.0) * luces.directa * sombra_luz;
        let esp_bloque = vec3<f32>(pow(max(dot(r.normal, normalize(p.vista + vec3<f32>(0.0, 0.35, 0.0))), 0.0), 32.0))
                       * bloque_luz * 0.45;
        r.especular_extra = (esp_astro + esp_bloque) * (OPC_CRISTAL_GOTA_ESPECULAR * cobertura_agua);
    }

    var color_nieve = vec3<f32>(0.0);
    if nieve.cobertura > 0.001 {
        let n_nieve = normalize(n_base + vec3<f32>(0.0, nieve.relieve_y, 0.0));
        let n_l_nieve = max(dot(n_nieve, luces.direccion), 0.0);
        let luz_nieve = luces.directa * sombra_luz * (n_l_nieve + contraluz * 0.4)
                      + luces.cielo * curva_cielo * (0.95 + 0.2 * nieve.relieve_y)
                      + bloque_luz
                      + vec3<f32>(OPC_LUZ_NOCHE_SUELO * curva_cielo);
        color_nieve = OPC_CRISTAL_NIEVE_COLOR * luz_nieve;
        let op_nieve = max(nieve.copo * OPC_CRISTAL_NIEVE_OPACIDAD_COPO, nieve.monton * OPC_CRISTAL_NIEVE_OPACIDAD_MONTON);
        r.capa_color = mix(r.capa_color, color_nieve, op_nieve);
        r.capa_opacidad = max(r.capa_opacidad, op_nieve);
        r.especular_extra *= (1.0 - op_nieve);
    }

    // Cristal transparente (cutout, `input.translucent == false`): en los texeles del interior dibuja
    // nieve, gotas y cristales de escarcha (orden de fuera adentro).
    if !p.translucido {
        let texel = floor(plano.uv * OPC_CRISTAL_REJILLA);
        let dither = rui_hash21(vec2<i32>(i32(texel.x), i32(texel.y)));
        let hay_nieve = nieve.monton >= 0.40 || nieve.copo >= 0.45;
        let hay_escarcha = esc.cobertura >= 0.42 || (esc.cobertura > 0.14 && esc.cobertura > dither * 0.65);
        let hay_gota = gota >= 0.45 || rastro >= 0.55;
        if hay_nieve {
            r.cobertura_cutout = 1.0;
            r.color_cutout = color_nieve;
        } else if hay_gota {
            let refl_dir = reflect(-p.vista, r.normal);
            let refl_cielo = adp_agua_reflejo(p, r.normal, refl_dir, luces) * luz_curva_cielo(max(p.luz_cielo, 0.3));
            let cuerpo = (luces.cielo * curva_cielo * 0.28 + bloque_luz * 0.2 + refl_cielo * 0.65) * (1.0 - r.oscurecer_fondo);
            r.cobertura_cutout = 1.0;
            r.color_cutout = cuerpo + r.especular_extra;
        } else if hay_escarcha {
            r.cobertura_cutout = 1.0;
            r.color_cutout = r.capa_color;
        }
    }

    return r;
}
