// Adaptador del efecto «el tiempo en los cristales» (27): lee el estado por cuadro de `datos_cuadro` y lo
// compone con la óptica del cristal de `22` (refracción, desenfoque, reflejo y especular) y los cristales transparentes.
// Porqué: docs/efectos/tiempo-en-los-cristales.md

struct AdpCristalResultado {
    activo: bool,           // false = sin efecto en este píxel -> camino idéntico a antes de F-74
    normal: vec3<f32>,      // normal perturbada por las gotas o escarcha
    refraccion: f32,        // fuerza de refracción en pantalla
    desenfoque: f32,        // 0..1 borrosidad detrás del cristal (escarcha, vaho)
    f0_extra: f32,          // reflejo adicional en cristal mojado
    mate: f32,              // 0..1 supresión de reflejo/brillo (arena opaca y nieve gruesa)
    oscurecer_fondo: f32,   // 0..1 oscurecimiento sutil del borde de la gota
    capa_color: vec3<f32>,  // color iluminado de las capas translúcidas/opacas encima (vaho, escarcha, nieve, arena)
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

// Composición Porter-Duff «sobre» en alfa recto: evita oscurecer capas translúcidas al mezclar sobre vec3(0.0).
fn adp_cristal_sobre(
    base_col: vec3<f32>,
    base_op: f32,
    nueva_col: vec3<f32>,
    nueva_op: f32,
) -> vec4<f32> {
    let op_out = nueva_op + base_op * (1.0 - nueva_op);
    if op_out <= 1e-4 {
        return vec4<f32>(0.0);
    }
    let col_out = (nueva_col * nueva_op + base_col * base_op * (1.0 - nueva_op)) / op_out;
    return vec4<f32>(col_out, op_out);
}

fn adp_cristal_evaluar(
    p: AdpPunto,
    n_base: vec3<f32>,
    luces: AdpLuces,
    sombra_luz: vec3<f32>,
    bloque_luz: vec3<f32>,
) -> AdpCristalResultado {
    var r = AdpCristalResultado(
        false,
        n_base,
        OPC_TRANSL_REFRACCION * 0.0006,
        0.0,
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
    let cv = datos_cuadro[ADP_CUADRO_CRISTAL_VAHO]; // xyz: pos relativa de vaho, w: peso (<0 desactivado/espectador)
    let cf = datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS]; // x: escarcha_interior, y: arena_roja, z: con_mod
    let plano = sup_cristal_plano(p.mundo, p.normal_cara);
    let dist = length(p.posicion);
    let curva_cielo = luz_curva_cielo(p.luz_cielo);

    // 1) Escarcha en el frío (27 §2) y vaho del aliento (27 §4).
    let esc_bruta = sup_cristal_escarcha(
        plano,
        p.luz_cielo,
        p.ao_vertice,
        c1.z,
        c1.w,
        cf.x > 0.5,
        dist,
    );
    let aliento = sup_cristal_aliento(
        plano,
        p.posicion,
        p.normal_cara,
        cv.xyz,
        cv.w,
        cf.z > 0.5,
        c1.z * min(c1.w, 1.0),
        adp_tiempo().segundos,
    );
    // Dentro de la mancha de vaho, la escarcha se disuelve suavemente en condensación lisa (sin aro duro).
    let suprime_helecho = 1.0 - smoothstep(0.0, 0.72, aliento.derrite) * 0.92;
    let esc = SupCristalEscarcha(
        esc_bruta.cobertura * suprime_helecho,
        max(esc_bruta.borroso, aliento.borroso),
        esc_bruta.cristalino * (1.0 - aliento.derrite),
        esc_bruta.grad_uv * suprime_helecho,
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

    // 3) Arena tras tormenta en bioma seco (27 §5).
    let arena = sup_cristal_arena(
        plano,
        p.normal_cara,
        p.luz_cielo,
        p.ao_vertice,
        c1.xy,
        c2.z,
        c2.w,
        dist,
    );

    // 4) Gotas de lluvia (27 §1): no se dibujan sobre escarcha gruesa, nieve ni arena (27 §Composición).
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
    let mascara_agua = (1.0 - smoothstep(0.35, 0.75, esc.cobertura))
                     * (1.0 - smoothstep(0.15, 0.55, nieve.cobertura))
                     * (1.0 - smoothstep(0.15, 0.55, arena.cobertura));
    let gota = lluvia.gota * mascara_agua;
    let rastro = lluvia.rastro * mascara_agua;
    let cobertura_agua = max(gota, rastro * 0.7);

    if cobertura_agua <= 0.001 && lluvia.mojado <= 0.001 && esc.cobertura <= 0.001 && nieve.cobertura <= 0.001 && aliento.vaho <= 0.001 && arena.cobertura <= 0.001 {
        return r;
    }
    r.activo = true;

    // Luz difusa + dispersión frontal (SSS) sobre capas del cristal (vaho, escarcha, nieve, arena).
    let n_l = max(dot(n_base, luces.direccion), 0.0);
    let contraluz = pow(max(dot(-p.vista, luces.direccion), 0.0), 3.0) * 0.35;
    let luz_capa = luces.directa * sombra_luz * (n_l + contraluz)
                 + luces.cielo * curva_cielo * 0.95
                 + bloque_luz
                 + vec3<f32>(OPC_LUZ_NOCHE_SUELO * curva_cielo);

    // Composición de dentro afuera (27 §Composición): vaho -> escarcha -> gotas -> copos/montón -> arena.
    if aliento.vaho > 0.001 {
        let col_vaho = OPC_CRISTAL_VAHO_COLOR * (luz_capa + luces.cielo * curva_cielo * 0.25);
        let op_vaho = clamp(aliento.vaho * OPC_CRISTAL_VAHO_OPACIDAD, 0.0, 0.72);
        let comp = adp_cristal_sobre(r.capa_color, r.capa_opacidad, col_vaho, op_vaho);
        r.capa_color = comp.rgb;
        r.capa_opacidad = comp.a;
        r.desenfoque = max(r.desenfoque, aliento.borroso);
    }

    if esc.cobertura > 0.001 {
        let n_esc = normalize(n_base + plano.tangente * esc.grad_uv.x + plano.bitangente * esc.grad_uv.y);
        // Iluminación cristalina de la escarcha: dispersión de luz + reflejo frío del cielo + destellos de facetas.
        let luz_esc = luz_capa * 1.18
                    + luces.cielo * curva_cielo * 0.45
                    + vec3<f32>(OPC_LUZ_NOCHE_SUELO * 1.8 * curva_cielo);
        let esp_esc = sup_especular(n_esc, p.vista, luces.direccion, 0.14, vec3<f32>(0.06))
                    * max(dot(n_esc, luces.direccion), 0.0) * luces.directa * sombra_luz * 0.8;
        let brillo_cristal = (0.4 + 2.2 * esc.cristalino)
                           * (luces.directa * sombra_luz + luces.cielo * curva_cielo * 1.3 + bloque_luz + vec3<f32>(OPC_LUZ_NOCHE_SUELO * 2.0 * curva_cielo));
        let col_esc = OPC_CRISTAL_ESCARCHA_COLOR * luz_esc + brillo_cristal * (0.35 * esc.cobertura) + esp_esc;
        let op_esc = clamp(esc.cobertura * OPC_CRISTAL_ESCARCHA_OPACIDAD, 0.0, 0.58);
        let comp = adp_cristal_sobre(r.capa_color, r.capa_opacidad, col_esc, op_esc);
        r.capa_color = comp.rgb;
        r.capa_opacidad = comp.a;
        r.desenfoque = max(r.desenfoque, esc.borroso);
        r.normal = normalize(mix(r.normal, n_esc, esc.cobertura * 0.45));
    }

    if cobertura_agua > 0.001 || lluvia.mojado > 0.001 {
        let grad_agua = lluvia.grad_uv * mascara_agua;
        let n_gota = normalize(
            n_base
            + plano.tangente * (grad_agua.x * 0.95)
            + plano.bitangente * (grad_agua.y * 0.95),
        );
        r.normal = normalize(mix(r.normal, n_gota, cobertura_agua));
        r.refraccion = mix(OPC_TRANSL_REFRACCION * 0.0006, OPC_CRISTAL_GOTA_REFRACCION, cobertura_agua);
        r.f0_extra = OPC_CRISTAL_MOJADO_F0_EXTRA * lluvia.mojado * mascara_agua + 0.08 * gota;
        r.oscurecer_fondo = lluvia.borde * mascara_agua * OPC_CRISTAL_GOTA_BORDE;

        // Brillo especular: astro directo + cenit del cielo nublado (visible también bajo lluvia cerrada) + luz cercana.
        let esp_astro = sup_especular(r.normal, p.vista, luces.direccion, 0.035, vec3<f32>(0.05))
                      * max(dot(r.normal, luces.direccion), 0.0) * luces.directa * sombra_luz;
        let dir_cielo = normalize(vec3<f32>(0.12, 0.96, 0.22));
        let esp_cielo = sup_especular(r.normal, p.vista, dir_cielo, 0.06, vec3<f32>(0.06))
                      * max(dot(r.normal, dir_cielo), 0.0) * luces.cielo * curva_cielo * 1.45;
        let esp_bloque = vec3<f32>(pow(max(dot(r.normal, normalize(p.vista + vec3<f32>(0.0, 0.35, 0.0))), 0.0), 32.0))
                       * bloque_luz * 0.55;
        let caustica = (luces.cielo * curva_cielo * 0.65 + luces.directa * sombra_luz * 0.35 + bloque_luz * 0.4)
                     * (lluvia.caustica * mascara_agua * OPC_CRISTAL_GOTA_CAUSTICA);
        r.especular_extra = (esp_astro + esp_cielo + esp_bloque) * (OPC_CRISTAL_GOTA_ESPECULAR * cobertura_agua) + caustica;
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
        let comp_nieve = adp_cristal_sobre(r.capa_color, r.capa_opacidad, color_nieve, op_nieve);
        r.capa_color = comp_nieve.rgb;
        r.capa_opacidad = comp_nieve.a;
        r.mate = max(r.mate, op_nieve * 0.85);
        r.especular_extra *= (1.0 - op_nieve);
    }

    // Capa más exterior (27 §5): arena opaca y mate (amarilla en desierto/sabana, roja en mesas).
    var color_arena = vec3<f32>(0.0);
    if arena.cobertura > 0.001 {
        let base_arena = select(OPC_CRISTAL_ARENA_COLOR_AMARILLA, OPC_CRISTAL_ARENA_COLOR_ROJA, cf.y > 0.5);
        let grano_color = base_arena * (0.82 + 0.36 * arena.variacion);
        let n_arena = normalize(n_base + vec3<f32>(0.0, arena.relieve_y, 0.0));
        let n_l_arena = max(dot(n_arena, luces.direccion), 0.0);
        let luz_arena = luces.directa * sombra_luz * n_l_arena
                      + luces.cielo * curva_cielo * 0.90
                      + bloque_luz
                      + vec3<f32>(OPC_LUZ_NOCHE_SUELO * curva_cielo);
        color_arena = grano_color * luz_arena;
        let op_arena = clamp(arena.cobertura, 0.0, 1.0);
        let comp_arena = adp_cristal_sobre(r.capa_color, r.capa_opacidad, color_arena, op_arena);
        r.capa_color = comp_arena.rgb;
        r.capa_opacidad = comp_arena.a;
        r.mate = max(r.mate, op_arena);
        r.especular_extra *= (1.0 - op_arena);
    }

    // Cristal transparente (cutout, `input.translucent == false`): en los texeles del interior dibuja
    // arena, nieve, gotas, escarcha y vaho (orden de fuera adentro).
    if !p.translucido {
        let texel = floor(plano.uv * OPC_CRISTAL_REJILLA);
        let dither = rui_hash21(vec2<i32>(i32(texel.x), i32(texel.y)));
        let dither_fino = rui_hash21(vec2<i32>(i32(p.pixel.x), i32(p.pixel.y)));
        let hay_arena = arena.cobertura >= 0.45;
        let hay_nieve = nieve.monton >= 0.40 || nieve.copo >= 0.45;
        let hay_vaho = aliento.vaho > 0.08 && aliento.vaho > dither_fino * 0.82;
        let hay_escarcha = esc.cobertura >= 0.58 || (esc.cobertura > 0.18 && esc.cobertura > dither * 0.85);
        let hay_gota = gota >= 0.45 || rastro >= 0.55;
        if hay_arena {
            r.cobertura_cutout = 1.0;
            r.color_cutout = color_arena;
        } else if hay_nieve {
            r.cobertura_cutout = 1.0;
            r.color_cutout = color_nieve;
        } else if hay_gota {
            let refl_dir = reflect(-p.vista, r.normal);
            let refl_cielo = adp_agua_reflejo(p, r.normal, refl_dir, luces) * luz_curva_cielo(max(p.luz_cielo, 0.3));
            let cuerpo = (luces.cielo * curva_cielo * 0.28 + bloque_luz * 0.2 + refl_cielo * 0.65) * (1.0 - r.oscurecer_fondo);
            r.cobertura_cutout = 1.0;
            r.color_cutout = cuerpo + r.especular_extra;
        } else if hay_escarcha || hay_vaho {
            r.cobertura_cutout = 1.0;
            r.color_cutout = r.capa_color;
        }
    }

    return r;
}
