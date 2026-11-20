// Adaptador del efecto «el tiempo en los cristales» (27): lee el estado por cuadro de `datos_cuadro` y lo
// compone con la óptica del cristal de `22` (refracción, desenfoque, reflejo y especular) y los cristales transparentes.
// Porqué: docs/efectos/tiempo-en-los-cristales.md

struct AdpCristalResultado {
    activo: bool,           // false = sin efecto en este píxel -> camino idéntico a antes de F-74
    normal: vec3<f32>,      // normal perturbada por las gotas o escarcha
    refraccion: f32,        // fuerza de refracción en pantalla
    usa_refraccion: bool,   // true si hay gotas/desenfoque que requieren muestrear opaque_color
    desenfoque: f32,        // 0..1 máscara de desenfoque detrás del cristal empañado
    desenfoque_nivel: u32,  // 0 apagado, 1 suave, 2 normal, 3 fuerte
    f0_extra: f32,          // reflejo adicional en cristal mojado
    mate: f32,              // 0..1 supresión de reflejo/brillo (arena opaca y nieve gruesa)
    oscurecer_fondo: f32,   // 0..1 oscurecimiento sutil del borde de la gota
    capa_color: vec3<f32>,  // color iluminado de las capas encima (vaho, condensación, escarcha, gotas, nieve, arena)
    capa_opacidad: f32,     // 0..1 mezcla sobre el fondo
    especular_extra: vec3<f32>,
}

// Refracción en pantalla para caras verticales y horizontales de cristal + desenfoque 2D detrás del
// cristal empañado conservando las luces (27 v2 §Capa 7: radios 3/2, 6/4, 11/7 y protección de profundidad).
fn adp_cristal_refraccion(p: AdpPunto, n: vec3<f32>, cantidad: f32, desenfoque: f32, nivel_blur: u32) -> AdpRefraccion {
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

    // Desenfoque de caja separable 2D detrás del cristal empañado conservando luces (27 v2 §Capa 7).
    if desenfoque > 0.01 && nivel_blur > 0u {
        let radios = sup_cristal_blur_radio(nivel_blur);
        let escala = (radios / vec2<f32>(3.0, 2.0)) / max(frame.resolution, vec2<f32>(1.0));
        var suma = vec3<f32>(0.0);
        var peso = 0.0;
        for (var dy = -2; dy <= 2; dy++) {
            for (var dx = -3; dx <= 3; dx++) {
                let u = clamp(uv + vec2<f32>(f32(dx), f32(dy)) * escala, vec2<f32>(0.0), vec2<f32>(1.0));
                if (dx == 0 && dy == 0) || adp_agua_profundidad_opaca(u) <= d_cristal {
                    suma += adp_agua_color_opaco(u);
                    peso += 1.0;
                }
            }
        }
        let borroso = suma / max(peso, 1.0);
        col = sup_cristal_blur_conservar_luces(col, borroso, desenfoque);
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
        false,
        0.0,
        0u,
        0.0,
        0.0,
        0.0,
        vec3<f32>(0.0),
        0.0,
        vec3<f32>(0.0),
    );
    if !OPC_CRISTAL_ACTIVO || !adp_es_superficie() {
        return r;
    }

    let dist = length(p.posicion);
    if dist > OPC_CRISTAL_DIST_MAX {
        return r;
    }

    let c0 = datos_cuadro[ADP_CUADRO_CRISTAL_0];        // x: clima, y: escarcha, z: repisa, w: condensacion
    let c1 = datos_cuadro[ADP_CUADRO_CRISTAL_1];        // xy: viento_lluvia, zw: viento_arena
    let c2 = datos_cuadro[ADP_CUADRO_CRISTAL_2];        // x: arena, y: escala_lluvia, z: escala_nieve, w: escala_arena
    let cv = datos_cuadro[ADP_CUADRO_CRISTAL_VAHO];     // xyz: pos relativa vaho, w: peso (<0 desactivado)
    let cf = datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS];    // x: flags24, y: cond_op, z: cond_bl, w: vaho_escala
    let co = datos_cuadro[ADP_CUADRO_CRISTAL_VAHO_OPT]; // x: aliento_op, y: aliento_bl, z: k_res, w: con_mod

    let flags = u32(max(round(cf.x), 0.0));
    let regueros = (flags & OPC_CR_FLAG_REGUEROS) != 0u;
    let interior_activo = (flags & OPC_CR_FLAG_INTERIOR) != 0u;
    let arena_roja = (flags & OPC_CR_FLAG_ARENA_ROJA) != 0u;
    let espectador = (flags & OPC_CR_FLAG_ESPECTADOR) != 0u;
    let bioma_seco = (flags & OPC_CR_FLAG_BIOMA_SECO) != 0u;
    let bioma_frio = (flags & OPC_CR_FLAG_BIOMA_FRIO) != 0u;
    let llueve_bioma = (flags & OPC_CR_FLAG_LLUEVE_BIOMA) != 0u;
    let borde_estilo = (flags >> 8u) & 3u;
    let blur_nivel = (flags >> 10u) & 3u;

    // Comprueba si el panel de lluvia de esta orientación (o su cara opuesta vista desde dentro) tiene gotas o rastros vivos.
    let es_arriba = p.normal_cara.y > 0.5;
    let es_abajo = p.normal_cara.y < -0.5;
    let cara_idx = u32(sup_cristal_indice_cara(p.normal_cara));
    let cara_opuesta_idx = cara_idx ^ 1u;
    let panel_lluvia = select(cara_idx, 4u, es_arriba);
    let panel_lluvia_op = select(cara_opuesta_idx, 4u, es_arriba);
    let hdr_lluvia = cristal_sim[panel_lluvia];
    let hdr_lluvia_op = cristal_sim[panel_lluvia_op];
    let panel_lluvia_vivo = !es_abajo && (hdr_lluvia.z > 0.5 || hdr_lluvia.w > 0.0 || hdr_lluvia_op.z > 0.5 || hdr_lluvia_op.w > 0.0);

    let copos_panel_vivo = bioma_frio && c2.z > 0.001 && (cristal_sim[8].z > 0.5 || cristal_sim[9].z > 0.5 || cristal_sim[10].z > 0.5 || cristal_sim[11].z > 0.5);
    let lluvia_activa = panel_lluvia_vivo && c2.y > 0.001;
    let frio_activo = bioma_frio && (c0.y > 0.001 || c0.z > 0.001 || copos_panel_vivo) && c2.z > 0.001;
    let arena_activa = bioma_seco && c2.x > OPC_CRISTAL_ARENA_MIN && c2.w > 0.001;
    let cond_activa = interior_activo && bioma_frio && (c0.w > 0.001 || (borde_estilo == 1u && c0.y > 0.001));
    let vaho_activo = interior_activo && !espectador && co.x > 0.001 && (cv.w > 0.001 || (co.w < 0.5 && dist < OPC_CRISTAL_VAHO_DIST));

    // Salida temprana sin lanzar ningún rayo cuando todo está apagado o despejado.
    if !lluvia_activa && !frio_activo && !arena_activa && !cond_activa && !vaho_activo {
        return r;
    }

    let plano = sup_cristal_plano(p.mundo, p.normal_cara);
    let necesita_bordes = frio_activo || arena_activa || cond_activa;
    let entorno = adp_cristal_entorno(p, plano, bioma_frio, necesita_bordes, cond_activa);
    if entorno.cerrada {
        return r;
    }

    let cielo_exposicion = select(0.0, 1.0, entorno.llega_cielo);
    let curva_cielo = luz_curva_cielo(p.luz_cielo);
    let aten_dist = 1.0 - smoothstep(OPC_CRISTAL_DIST_INICIO, OPC_CRISTAL_DIST_FIN, dist);
    let b_cristal = vec3<i32>(floor(p.mundo - p.normal_cara * 0.02));
    let variante = sup_cr_hash_u32(u32(b_cristal.x * 73856093) ^ u32(b_cristal.y * 19349663) ^ u32(b_cristal.z * 83492791) ^ cara_idx) & 3u;

    // Capa 5 (condensación) y Capa 6 (vaho del aliento): el aliento actúa donde cond_grosor < 0,5 y funde escarcha/copos.
    var cond_capa = SupCristalCondensacion(vec3<f32>(0.0), 0.0, 0.0);
    if cond_activa && entorno.es_interior_fria {
        cond_capa = sup_cristal_condensacion(
            plano,
            entorno.dist_marco,
            c0.y,
            c0.w,
            cf.y,
            cf.z,
            co.z,
            variante,
        );
        cond_capa.alfa *= aten_dist;
        cond_capa.grosor *= aten_dist;
    }

    var aliento = SupCristalAliento(vec3<f32>(0.0), 0.0, 0.0, 0.0);
    if vaho_activo {
        aliento = sup_cristal_aliento_v2(
            plano,
            p.posicion,
            p.normal_cara,
            cv.xyz,
            cv.w,
            cf.w,
            co.x,
            co.y,
            cond_capa.grosor,
            co.z,
            co.w > 0.5,
            entorno.es_interior,
            espectador,
            adp_tiempo().segundos,
        );
        aliento.alfa *= aten_dist;
        aliento.grosor *= aten_dist;
    }
    let suprime_escarcha = 1.0 - smoothstep(0.0, 0.70, aliento.derrite) * 0.92;

    var borde_capa = SupCristalCapa(vec3<f32>(0.0), 0.0, 0.0);
    if cond_activa && entorno.es_interior_fria {
        borde_capa = sup_cristal_borde_helado(
            plano,
            entorno.dist_marco,
            c0.y,
            c0.w,
            c2.z,
            co.z,
            borde_estilo,
            variante,
        );
        borde_capa.alfa *= suprime_escarcha * aten_dist;
    }

    // Capa 2 — Escarcha de fuera y repisa de nieve desde el marco de la ventana entera (27 v2 §Capa 2).
    let muestra_esc_ext = frio_activo && (entorno.es_exterior || entorno.es_interior_fria);
    var esc_capa = sup_cristal_escarcha_v2(
        plano,
        entorno.dist_marco,
        select(0.0, c0.y, muestra_esc_ext),
        c2.z,
        co.z,
        variante,
        false,
        1.0,
    );
    esc_capa.alfa *= suprime_escarcha * aten_dist;

    let muestra_repisa = frio_activo && c0.z > 0.005 && (entorno.llega_cielo || (entorno.es_interior && entorno.opuesta_llega_cielo));
    var repisa_capa = sup_cristal_repisa_nieve(
        plano,
        entorno.bordes,
        select(0.0, c0.z, muestra_repisa),
        c2.z,
        co.z,
    );
    repisa_capa.alfa *= aten_dist;

    // Capa 3 — Copos pegados desde las 8 tiras globales en `cristal_clima` (27 v2 §Capa 3).
    var copo_rgba = vec4<f32>(0.0);
    let copo_en_exterior = entorno.llega_cielo;
    let copo_desde_interior = !copo_en_exterior && entorno.es_interior && entorno.opuesta_llega_cielo;
    if copos_panel_vivo && plano.vertical && (copo_en_exterior || copo_desde_interior) {
        let normal_copo = select(-p.normal_cara, p.normal_cara, copo_en_exterior);
        var plano_copo = plano;
        if !copo_en_exterior {
            plano_copo = sup_cristal_plano(p.mundo, normal_copo);
        }
        let coord_copo = sup_cristal_copo_texel(b_cristal, normal_copo, plano_copo, co.z);
        copo_rgba = textureLoad(cristal_clima, coord_copo, 0);
        copo_rgba.a *= (1.0 - smoothstep(0.0, 0.65, aliento.derrite)) * aten_dist;
    }

    // Capa 4 — Arena tras la tormenta en biomas secos / mesas (27 v2 §Capa 4).
    let muestra_arena = arena_activa && plano.vertical && (entorno.llega_cielo || (entorno.es_interior && entorno.opuesta_llega_cielo));
    var arena_capa = sup_cristal_arena_v2(
        plano,
        select(-p.normal_cara, p.normal_cara, entorno.llega_cielo),
        entorno.bordes,
        entorno.dist_marco,
        c1.zw,
        select(0.0, c2.x, muestra_arena),
        c2.w,
        co.z,
        arena_roja,
    );
    arena_capa.alfa *= aten_dist;

    // Capa 1 — Lluvia global desde el lienzo de cómputo `cristal_clima` (27 v2 §Capa 1).
    // Se dibuja en caras exteriores mojadas, y también se ve a través del cristal cuando miramos desde la cara interior.
    var lluvia_rgba = vec4<f32>(0.0);
    var lluvia_pend = vec2<f32>(0.0);
    var lluvia_gota_a = 0.0;
    var lluvia_mojado = 0.0;
    let lluvia_en_exterior = entorno.llega_cielo;
    let lluvia_desde_interior = !lluvia_en_exterior && entorno.es_interior && entorno.opuesta_llega_cielo && plano.vertical;
    if lluvia_activa && (lluvia_en_exterior || lluvia_desde_interior) && !bioma_frio && !bioma_seco {
        let normal_muestra = select(-p.normal_cara, p.normal_cara, lluvia_en_exterior);
        var plano_muestra = plano;
        if !lluvia_en_exterior {
            plano_muestra = sup_cristal_plano(p.mundo, normal_muestra);
        }
        let coord_lluvia = sup_cristal_lluvia_texel(b_cristal, normal_muestra, plano_muestra, co.z);
        let tx = textureLoad(cristal_clima, coord_lluvia, 0);
        let mascara_agua = (1.0 - smoothstep(0.35, 0.75, esc_capa.alfa))
                         * (1.0 - smoothstep(0.15, 0.55, max(copo_rgba.a, repisa_capa.alfa)))
                         * (1.0 - smoothstep(0.15, 0.55, arena_capa.alfa))
                         * aten_dist;
        lluvia_rgba = sup_cristal_lluvia_color(tx, regueros && plano.vertical);
        lluvia_rgba.a *= mascara_agua;
        lluvia_gota_a = tx.b * mascara_agua;
        lluvia_pend = sup_cr_desempaquetar_pendiente(tx.a) * lluvia_gota_a;
        lluvia_mojado = select(0.0, clamp(c0.x, 0.0, 1.0) * 0.4 * mascara_agua, llueve_bioma && c0.x > OPC_CRISTAL_CLIMA_UMBRAL);
    }

    if lluvia_rgba.a <= 0.002 && lluvia_mojado <= 0.002 && esc_capa.alfa <= 0.002 && repisa_capa.alfa <= 0.002 && copo_rgba.a <= 0.002 && aliento.alfa <= 0.002 && arena_capa.alfa <= 0.002 && cond_capa.alfa <= 0.002 && borde_capa.alfa <= 0.002 {
        return r;
    }
    r.activo = true;
    r.desenfoque_nivel = blur_nivel;

    // Luz difusa + dispersión frontal (SSS) sobre capas del cristal.
    let n_l = max(dot(n_base, luces.direccion), 0.0);
    let contraluz = pow(max(dot(-p.vista, luces.direccion), 0.0), 3.0) * 0.35;
    let cielo_ext_ref = max(curva_cielo, select(0.0, 0.85, entorno.es_interior && (entorno.opuesta_llega_cielo || entorno.es_interior_fria)));
    let luz_capa = luces.directa * sombra_luz * (n_l + contraluz)
                 + luces.cielo * cielo_ext_ref * 0.95
                 + bloque_luz
                 + vec3<f32>(OPC_LUZ_NOCHE_SUELO * cielo_ext_ref);

    if esc_capa.alfa > 0.002 {
        let luz_esc = luz_capa * 1.15
                    + luces.cielo * cielo_ext_ref * 0.35
                    + vec3<f32>(OPC_LUZ_NOCHE_SUELO * 1.6 * cielo_ext_ref);
        let destello_luz = esc_capa.destello * (luces.directa * sombra_luz * 0.9 + luces.cielo * cielo_ext_ref * 0.8 + bloque_luz * 0.8);
        let col_esc = esc_capa.color * luz_esc + destello_luz;
        let comp = adp_cristal_sobre(r.capa_color, r.capa_opacidad, col_esc, esc_capa.alfa);
        r.capa_color = comp.rgb;
        r.capa_opacidad = comp.a;
    }

    if repisa_capa.alfa > 0.002 {
        // La repisa de nieve va por delante de la escarcha (27 §Bloques y caras: 0,005 vs 0,0025).
        let luz_rep = luz_capa * 1.10 + luces.cielo * cielo_ext_ref * 0.25;
        let col_rep = repisa_capa.color * luz_rep;
        let comp = adp_cristal_sobre(r.capa_color, r.capa_opacidad, col_rep, repisa_capa.alfa);
        r.capa_color = comp.rgb;
        r.capa_opacidad = comp.a;
        r.mate = max(r.mate, repisa_capa.alfa * 0.9);
    }

    if lluvia_rgba.a > 0.002 || lluvia_mojado > 0.002 {
        let n_gota = normalize(
            n_base
            + plano.tangente * (lluvia_pend.x * 0.65)
            - plano.bitangente * (lluvia_pend.y * 0.65),
        );
        r.normal = normalize(mix(r.normal, n_gota, lluvia_gota_a));
        r.refraccion = mix(OPC_TRANSL_REFRACCION * 0.0006, OPC_CRISTAL_GOTA_REFRACCION, lluvia_gota_a);
        r.usa_refraccion = lluvia_gota_a > 0.20;
        r.f0_extra = OPC_CRISTAL_MOJADO_F0_EXTRA * lluvia_mojado + 0.05 * lluvia_gota_a;

        // Iluminación del mundo sobre la capa de lluvia (paleta Weather Glass cuerpo/brillo/sombra).
        // Usa el cielo exterior real aunque se mire desde el interior, para que el brillo destaque bajo cielo lluvioso.
        let cielo_ext = max(curva_cielo, select(0.0, 0.85, lluvia_desde_interior));
        let luz_lluvia = luz_capa * 1.25 + luces.cielo * cielo_ext * 0.65 + vec3<f32>(0.06) * cielo_ext;
        let col_lluvia = lluvia_rgba.rgb * luz_lluvia;
        let comp_gota = adp_cristal_sobre(r.capa_color, r.capa_opacidad, col_lluvia, lluvia_rgba.a);
        r.capa_color = comp_gota.rgb;
        r.capa_opacidad = comp_gota.a;

        if lluvia_gota_a > 0.05 {
            let esp_astro = sup_especular(r.normal, p.vista, luces.direccion, 0.04, vec3<f32>(0.05))
                          * max(dot(r.normal, luces.direccion), 0.0) * luces.directa * sombra_luz;
            let dir_cielo = normalize(vec3<f32>(0.12, 0.96, 0.22));
            let esp_cielo = sup_especular(r.normal, p.vista, dir_cielo, 0.07, vec3<f32>(0.05))
                          * max(dot(r.normal, dir_cielo), 0.0) * luces.cielo * curva_cielo * 1.1;
            r.especular_extra = (esp_astro + esp_cielo) * (OPC_CRISTAL_GOTA_ESPECULAR * lluvia_gota_a);
        }
    }

    if copo_rgba.a > 0.002 {
        let luz_copo = luz_capa * 1.15 + luces.cielo * cielo_ext_ref * 0.35;
        let color_copo = copo_rgba.rgb * luz_copo;
        let comp_copo = adp_cristal_sobre(r.capa_color, r.capa_opacidad, color_copo, copo_rgba.a);
        r.capa_color = comp_copo.rgb;
        r.capa_opacidad = comp_copo.a;
        r.mate = max(r.mate, copo_rgba.a * 0.85);
        r.especular_extra *= (1.0 - copo_rgba.a);
    }

    if arena_capa.alfa > 0.002 {
        let luz_arena = luz_capa * 1.05 + luces.cielo * cielo_ext_ref * 0.20;
        let color_arena = arena_capa.color * luz_arena;
        let comp_arena = adp_cristal_sobre(r.capa_color, r.capa_opacidad, color_arena, arena_capa.alfa);
        r.capa_color = comp_arena.rgb;
        r.capa_opacidad = comp_arena.a;
        r.mate = max(r.mate, arena_capa.alfa);
        r.especular_extra *= (1.0 - arena_capa.alfa);
    }

    // Capas interiores (encima de las exteriores): condensación, vaho del aliento y borde helado.
    if cond_capa.alfa > 0.002 {
        let luz_cond = luz_capa * 1.08 + luces.cielo * cielo_ext_ref * 0.30 + bloque_luz * 0.35;
        let col_cond = cond_capa.color * luz_cond;
        let comp_cond = adp_cristal_sobre(r.capa_color, r.capa_opacidad, col_cond, cond_capa.alfa);
        r.capa_color = comp_cond.rgb;
        r.capa_opacidad = comp_cond.a;
        r.mate = max(r.mate, cond_capa.alfa * 0.5);
    }

    if aliento.alfa > 0.002 {
        let luz_vaho = luz_capa * 1.10 + luces.cielo * cielo_ext_ref * 0.30 + bloque_luz * 0.40;
        let col_vaho = aliento.color * luz_vaho;
        let comp_vaho = adp_cristal_sobre(r.capa_color, r.capa_opacidad, col_vaho, aliento.alfa);
        r.capa_color = comp_vaho.rgb;
        r.capa_opacidad = comp_vaho.a;
        r.mate = max(r.mate, aliento.alfa * 0.55);
    }

    if borde_capa.alfa > 0.002 {
        let luz_borde = luz_capa * 1.15 + luces.cielo * cielo_ext_ref * 0.35 + bloque_luz * 0.45;
        let dest_b = borde_capa.destello * (luces.directa * sombra_luz * 0.8 + luces.cielo * cielo_ext_ref * 0.8 + bloque_luz);
        let col_borde = borde_capa.color * luz_borde + dest_b;
        let comp_borde = adp_cristal_sobre(r.capa_color, r.capa_opacidad, col_borde, borde_capa.alfa);
        r.capa_color = comp_borde.rgb;
        r.capa_opacidad = comp_borde.a;
    }

    // Capa 7 — Máscara de desenfoque detrás del cristal empañado por dentro (27 v2 §Capa 7).
    if blur_nivel > 0u && entorno.es_interior {
        let grosor_empanado = max(cond_capa.grosor, aliento.grosor);
        let fuerza_blur = max(min(1.0, c0.y * 1.25), select(0.0, 1.0, aliento.grosor > 0.01));
        r.desenfoque = clamp(fuerza_blur * 0.95 * grosor_empanado, 0.0, 0.95);
    }

    return r;
}
