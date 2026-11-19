// Adaptador del efecto «el tiempo en los cristales» (27): lee el estado por cuadro de `datos_cuadro` y lo
// compone con la óptica del cristal de `22` (refracción, reflejo y especular) y los cristales transparentes (cutout).
// Porqué: docs/efectos/tiempo-en-los-cristales.md

struct AdpCristalResultado {
    normal: vec3<f32>,      // normal perturbada por las gotas (lente)
    refraccion: f32,        // fuerza de refracción en pantalla
    f0_extra: f32,          // reflejo adicional en cristal mojado
    oscurecer_fondo: f32,   // 0..1 oscurecimiento sutil del borde de la gota
    especular_extra: vec3<f32>,
    cobertura_cutout: f32,  // 0..1 cobertura para cristal transparente (cutout)
    color_cutout: vec3<f32>,// color de los texeles dibujados en cristal transparente
}

// Refracción en pantalla para caras verticales y horizontales de cristal: proyecta el desvío de normal al plano
// de vista para que las gotas actúen como lentes en cualquier orientación (N/S/E/O y horizontal), reutilizando
// la profundidad opaca, el color opaco y la dispersión cromática de `22`.
fn adp_cristal_refraccion(p: AdpPunto, n: vec3<f32>, cantidad: f32) -> AdpRefraccion {
    let uv0 = p.pixel / frame.resolution;
    let dist = length(p.posicion);
    let dist_factor = 1.0 + pow(dist, 0.75) * 0.08;
    let borde = smoothstep(0.0, 0.08, min(min(uv0.x, 1.0 - uv0.x), min(uv0.y, 1.0 - uv0.y)));
    let dn_vista = (frame.view * vec4<f32>(n - p.normal_cara, 0.0)).xy;
    let desplazamiento = vec2<f32>(dn_vista.x, -dn_vista.y) * cantidad * borde / dist_factor;
    var uv = uv0 + desplazamiento;
    var d = adp_agua_profundidad_opaca(uv);
    let d_cristal = mat_proyectar(frame.projection * frame.view, p.posicion).z;
    if d > d_cristal {
        uv = uv0;
        d = adp_agua_profundidad_opaca(uv);
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
    let col_g = adp_agua_color_opaco(uv).g;
    let col_r = adp_agua_color_opaco(uv_r).r;
    let col_b = adp_agua_color_opaco(uv_b).b;
    return AdpRefraccion(vec3<f32>(col_r, col_g, col_b), 0.0);
}

fn adp_cristal_evaluar(
    p: AdpPunto,
    n_base: vec3<f32>,
    luces: AdpLuces,
    sombra_luz: vec3<f32>,
    bloque_luz: vec3<f32>,
) -> AdpCristalResultado {
    var r = AdpCristalResultado(n_base, OPC_TRANSL_REFRACCION * 0.0006, 0.0, 0.0, vec3<f32>(0.0), 0.0, vec3<f32>(0.0));
    if !OPC_CRISTAL_ACTIVO || !adp_es_superficie() {
        return r;
    }

    let c0 = datos_cuadro[ADP_CUADRO_CRISTAL_0]; // x: lluvia_pico, y: secado (0..1), z: escala_lluvia, w: tormenta
    let c1 = datos_cuadro[ADP_CUADRO_CRISTAL_1]; // xy: viento_xz, z: escarcha, w: escala_nieve
    let plano = sup_cristal_plano(p.mundo, p.normal_cara);
    let dist = length(p.posicion);

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

    let cobertura_agua = max(lluvia.gota, lluvia.rastro * 0.7);
    if cobertura_agua <= 0.001 && lluvia.mojado <= 0.001 {
        return r;
    }

    // Lente óptica de cada gota: desvía la normal en espacio tangente para refracción (22), reflejo y especular.
    let n_gota = normalize(
        n_base
        + plano.tangente * (lluvia.grad_uv.x * 0.65)
        + plano.bitangente * (lluvia.grad_uv.y * 0.65),
    );
    r.normal = normalize(mix(n_base, n_gota, cobertura_agua));
    r.refraccion = mix(OPC_TRANSL_REFRACCION * 0.0006, OPC_CRISTAL_GOTA_REFRACCION, cobertura_agua);
    r.f0_extra = OPC_CRISTAL_MOJADO_F0_EXTRA * lluvia.mojado + 0.04 * lluvia.gota;
    r.oscurecer_fondo = lluvia.borde * OPC_CRISTAL_GOTA_BORDE;

    // Brillo especular del sol/luna y luz cercana (antorchas) en la gota.
    let curva_cielo = luz_curva_cielo(p.luz_cielo);
    let esp_astro = sup_especular(r.normal, p.vista, luces.direccion, 0.04, vec3<f32>(0.04))
                  * max(dot(r.normal, luces.direccion), 0.0) * luces.directa * sombra_luz;
    let esp_bloque = vec3<f32>(pow(max(dot(r.normal, normalize(p.vista + vec3<f32>(0.0, 0.35, 0.0))), 0.0), 32.0))
                   * bloque_luz * 0.45;
    r.especular_extra = (esp_astro + esp_bloque) * (OPC_CRISTAL_GOTA_ESPECULAR * cobertura_agua);

    // En cristal transparente (cutout, `input.translucent == false`), los texeles de gota se dibujan
    // con reflejo del cielo/nubes de 22 + brillo especular + borde oscuro.
    if !p.translucido && cobertura_agua > 0.01 {
        let refl_dir = reflect(-p.vista, r.normal);
        let refl_cielo = adp_agua_reflejo(p, r.normal, refl_dir, luces) * luz_curva_cielo(max(p.luz_cielo, 0.3));
        let cuerpo = (luces.cielo * curva_cielo * 0.28 + bloque_luz * 0.2 + refl_cielo * 0.65) * (1.0 - r.oscurecer_fondo);
        r.cobertura_cutout = select(0.0, 1.0, lluvia.gota >= 0.45 || lluvia.rastro >= 0.55);
        r.color_cutout = cuerpo + r.especular_extra;
    }

    return r;
}
