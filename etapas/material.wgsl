// Etapa material: compone la luz de superficie (subsistema 03).
// Porqué: docs/efectos/luz-de-superficie.md §Composición
fn material(input: MaterialInput) -> Surface {
    let o = opc_luz();
    var p = adp_material_punto(input, o);
    let luces = adp_luces(o);
    if p.fluido == 1u && p.translucido {
        return agua(input, p, luces);
    }
    // La sombra solo se busca donde puede verse: cara hacia la luz o con SSS, y con algo de cielo.
    let hacia_luz = p.cruzada || dot(p.normal_cara, luces.direccion) > -0.05 || p.pbr.sss > 0.0;
    var sombra = AdpSombra(vec3<f32>(0.0), 2.0);
    if hacia_luz && p.luz_cielo > 0.02 && !luces.fija {
        sombra = adp_sombra(p);
    }

    // Humedad: más oscuro, más liso; en los charcos, normal plana y suavidad máxima.
    var albedo = p.albedo;
    var n = p.normal;
    var m = p.pbr;
    if (o.charcos || o.mojado) && frame.wetness > 0.0 && adp_es_superficie() && p.fluido == 0u && !m.metal {
        let h = sup_humedad(frame.wetness, p.luz_cielo, p.mundo, p.normal_cara.y, adp_tiempo().segundos);
        let mojado = select(0.0, h.mojado, o.mojado);
        let charco = select(0.0, h.charco, o.charcos);
        albedo = sup_albedo_mojado(albedo, max(mojado, charco), m.porosidad);
        m.suavidad = mix(m.suavidad, 0.85, mojado * 0.6);
        m.suavidad = mix(m.suavidad, 0.97, charco);
        m.f0 = mix(m.f0, vec3<f32>(0.02), charco);
        n = normalize(mix(n, p.normal_cara, charco));
        m.rugosidad = (1.0 - m.suavidad) * (1.0 - m.suavidad);
    }

    let l = luces.direccion;
    let n_l = select(dot(n, l), 0.75, p.cruzada);
    let difusa = luz_lambert(n_l);
    let directa_luz = luces.directa;

    let cielo_camara = frame.eye_light_smooth.y;
    let apertura = clamp(p.luz_cielo + cielo_camara * (1.0 - p.luz_cielo), 0.0, 1.0);

    // Luz directa y SSS: el SSS llena lo que la difusa no ilumina.
    var directa = albedo * difusa * sombra.luz;
    if m.sss > 0.0 {
        let perfil = sup_sss_perfil(sombra.grosor, m.sss);
        let color_sss = sup_sss_color(albedo, perfil);
        let fase = sup_sss_fase(dot(-p.vista, l));
        let sss_directo = color_sss * perfil * fase;
        directa = mix(sss_directo, albedo, clamp(difusa * col_luminancia(sombra.luz), 0.0, 1.0));
    }
    // Prevención de fugas solares y SSS en cuevas (fino/03 §4). Porqué: docs/efectos/luz-de-superficie.md §Cuevas
    // Fugas (implementacion/01 §1.5): el cuadrado de «luz de cielo de la cámara + del punto», recortado a 1.
    let suma_cielo = min(cielo_camara + p.luz_cielo, 1.0);
    let proteccion_cueva = select(suma_cielo * suma_cielo, 1.0, frame.in_water > 0.5);
    directa *= directa_luz * proteccion_cueva;

    // Ambiente: cielo modulado por norma L1 (Overworld) o hemisférico (Nether/End) × curva de cielo.
    let curva_cielo = select(luz_curva_cielo(p.luz_cielo), 1.0, luces.fija);
    // Las caras que miran hacia abajo no ven el cielo sino lo que hay debajo: su luz ambiente va sin el azul del cielo
    // (en el original son gris neutro; panel cielo-dia). Porqué: docs/efectos/luz-de-superficie.md §«Caras hacia abajo» (F-14)
    let cielo_cara = mix(vec3<f32>(col_luminancia(luces.cielo)), luces.cielo, smoothstep(-OPC_LUZ_ABAJO_NEUTRA, 0.0, n.y));
    var ambiente_cielo = cielo_cara * luz_direccion_cielo(n, p.luz_cielo, p.cruzada, p.ao_vertice) * curva_cielo;
    if luces.fija {
        ambiente_cielo = luz_hemisferica(n.y, luces.cielo, luces.suelo) * curva_cielo;
    }
    var sss_cielo = vec3<f32>(0.0);
    if m.sss > 0.0 {
        // Fase del SSS de cielo por la dirección de vista del píxel (fino/03 §Medidos, corregido 2026-11-10): 1 mirando
        // hacia abajo, 2 hacia arriba; aquí escalada por OPC_SSS_CIELO. Porqué: docs/efectos/luz-de-superficie.md §SSS de cielo (F-9)
        sss_cielo = sup_sss_color(albedo, 0.5) * luces.cielo * curva_cielo * m.sss * (sup_sss_fase_cielo(-p.vista.y) * OPC_SSS_CIELO);
    }
    let bloque = (adp_color_luz_bloque(p, o) * luz_curva_bloque(p.luz_bloque) + p.luz_colorida) * OPC_LUZ_BLOQUE * o.bloque;
    // Relámpago (20): solo donde llega el cielo (luz de cielo a la cuarta). Porqué: docs/efectos/relampago.md
    let cielo2 = p.luz_cielo * p.luz_cielo;
    let relampago = OPC_RELAMPAGO_COLOR * (OPC_RELAMPAGO_BRILLO * cielo2 * cielo2 * luz_relampago_superficie(adp_relampago(), p.posicion, n));
    // Luz mínima direccional (fino/03 §3, corregido 2026-11-10): atenuador frontal, 0,30 de frente a la cámara y 1 de
    // canto (medido: 1 − 0,7·N·V), sin caída con la distancia. Porqué: docs/efectos/luz-de-superficie.md §Cuevas (F-9)
    let frontal = max(dot(n, p.vista), 0.0);
    let atenuador = 1.0 - (1.0 - OPC_LUZ_MINIMA_FRENTE) * frontal;
    let factor_cueva = mix(o.minima_cuevas, o.minima_exterior, smoothstep(0.0, 0.6, apertura)) * (1.0 - p.luz_cielo);
    let minima = OPC_LUZ_MINIMA_CUEVA * factor_cueva * atenuador + frame.night_vision * 0.08;
    let indirecta = albedo * (ambiente_cielo + bloque + relampago + vec3<f32>(minima)) + sss_cielo;

    // Especular del sol y reflejo del ambiente.
    let f_ambiente = sup_fresnel_schlick_rugosidad(max(dot(n, p.vista), 0.0), m.f0, m.rugosidad);
    var especular = sup_especular(n, p.vista, l, m.rugosidad, m.f0) * max(dot(n, l), 0.0) * luces.directa * sombra.luz * o.especular_sol;
    var reflejo = vec3<f32>(0.0);
    let visible = smoothstep(0.45, 0.7, m.suavidad);
    // Superficies lisas y sólidas: su reflejo lo pone el trazado de pantalla de la composición.
    let por_pantalla = o.pasos_reflejo > 0 && !p.translucido && m.suavidad >= o.suavidad_reflejo;
    if (visible > 0.0 || m.metal) && !por_pantalla {
        let r = reflect(-p.vista, n);
        let horizonte = adp_tabla(frame.sun_direction.y, ATM_FILA_HORIZONTE) * opc_cielo().sol_color;
        let cielo_r = mix(horizonte, luces.cielo * 2.0, sqrt(max(r.y, 0.0)));
        let ambiente_r = select(cielo_r, select(luces.cielo * 0.08, luces.suelo, luces.fija), r.y < 0.0);
        reflejo = ambiente_r * f_ambiente * curva_cielo * max(visible, select(0.0, 1.0, m.metal));
    }
    var difusa_total = directa + indirecta;
    if m.metal {
        difusa_total = vec3<f32>(0.0);
        especular *= 1.0;
    } else {
        difusa_total *= vec3<f32>(1.0) - f_ambiente * max(visible, 0.0);
    }
    var color = difusa_total + especular + reflejo;

    // Emisión: mezcla hacia el color emitido (bloques que dan luz, LabPBR o menas, 12).
    var emision = sup_emision_texeles(p.albedo, p.emision_bloque);
    var color_emision = p.albedo;
    var brillo_emision = 1.0;
    let mena = adp_mena(input, p.albedo);
    if mena.emision > emision {
        emision = mena.emision;
        color_emision = mena.albedo;
    }
    if m.emision > 0.0 {
        emision = pow(m.emision, 2.0);
        brillo_emision = o.emision_labpbr;
    }
    color = mix(color, color_emision * OPC_EMISION * brillo_emision * 4.0, emision);

    if !p.translucido {
        let total = col_luminancia(directa + indirecta) + 1e-6;
        set_surface(n, sup_empaquetar_suavidad(m.suavidad, col_lineal_a_srgb(albedo)), sup_empaquetar_dato(m.f0.g, col_luminancia(indirecta) / total, p.luz_cielo));
        return adp_material_salida(color, p.alfa, p);
    }
    return adp_material_salida(translucido(p, n, m, luces, color), 1.0, p);
}

// Translúcidos que no son agua (22): lo de detrás refractado y teñido por el color normalizado, la superficie encima
// por su opacidad y el reflejo con Fresnel, que la vuelve espejo de refilón. Sale opaco, como el agua.
// Porqué: docs/efectos/translucidos.md
fn translucido(p: AdpPunto, n: vec3<f32>, m: SupMaterial, luces: AdpLuces, superficie: vec3<f32>) -> vec3<f32> {
    let refr = adp_agua_refraccion(p, n, OPC_TRANSL_REFRACCION * 0.0006);
    let a = clamp(p.alfa, 0.0, 1.0);
    let peso_tinte = select(0.0, clamp(a / OPC_TRANSL_TINTE_MIN, 0.0, 1.0), OPC_TRANSL_TINTE);
    let tinte = mix(vec3<f32>(1.0), normalize(max(p.albedo, vec3<f32>(1e-4))), peso_tinte);
    let fondo = mix(refr.color * tinte, superficie, a);
    let f0 = select(vec3<f32>(OPC_TRANSL_F0), m.f0, p.con_pbr);
    let f = col_luminancia(sup_fresnel_schlick(max(dot(n, p.vista), 0.0), f0));
    let reflejo = adp_agua_reflejo(p, n, reflect(-p.vista, n), luces) * luz_curva_cielo(max(p.luz_cielo, 0.3));
    return mix(fondo, reflejo, f);
}

// El agua (subsistema 07): olas, refracción absorbida, reflejo con Fresnel y especular del sol, o la superficie
// vista desde abajo. Sale opaca: lo de detrás ya va dentro. Porqué: docs/efectos/agua.md
fn agua(input: MaterialInput, p: AdpPunto, luces: AdpLuces) -> Surface {
    let oa = adp_agua_opciones();
    let medio = opc_agua_medio(oa.claridad);
    let dist = length(p.posicion);
    let n = agu_normal(p.mundo, p.normal_cara, dist, oa.olas, ruido2d, ruido2d_sampler);
    if opc_depuracion().vista == OPC_VISTA_FORMA_AGUA {
        return adp_material_salida(clamp(vec3<f32>(0.5 + 4.0 * n.x, 0.5, 0.5 + 4.0 * n.z), vec3<f32>(0.0), vec3<f32>(1.0)), 1.0, p);
    }
    let v = p.vista;
    let cos_v = max(dot(n, v), 0.0);
    let ambiente = luces.cielo * luz_curva_cielo(p.luz_cielo) + vec3<f32>(OPC_LUZ_MINIMA * 2.0);
    let refr = adp_agua_refraccion(p, n, oa.refraccion);
    // Absorción mínima en zonas oscuras: el agua tiene color propio aunque no haya luz de cielo.
    let minima = mix(4.0, 0.0, smoothstep(0.2, 0.8, p.luz_cielo));
    let sombra = adp_sombra(p);
    let a_traves = agu_a_traves(refr.color, max(refr.distancia, minima), adp_agua_luz_volumen(p, luces, col_luminancia(sombra.luz), medio), medio);

    if input.face == 0u {
        // Desde abajo: fuera del cono de Snell, reflexión total (agua profunda); dentro, lo de arriba.
        let f = agu_fresnel_dentro(cos_v, OPC_AGUA_F0);
        let hondo = medio.color_disperso * ambiente * 0.3;
        return adp_material_salida(mix(refr.color, hondo, f), 1.0, p);
    }
    let r = reflect(-v, n);
    let f = agu_fresnel(cos_v, OPC_AGUA_F0);
    var reflejo = adp_agua_reflejo(p, n, r, luces) * luz_curva_cielo(max(p.luz_cielo, 0.3));
    let especular = sup_especular(n, v, luces.direccion, OPC_AGUA_ESPECULAR_RUGOSIDAD, vec3<f32>(OPC_AGUA_F0))
                  * max(dot(n, luces.direccion), 0.0) * luces.directa * sombra.luz;
    var color = mix(a_traves, reflejo, f) + especular;
    if OPC_AGUA_TEXTURA {
        color = mix(color, p.albedo * ambiente, 0.3);
    }
    return adp_material_salida(color, 1.0, p);
}

// Punto de entrada de la etapa de desplazamiento (subsistema 18).
// Porqué: docs/efectos/relieve.md §Desplazamiento
fn displacement(input: DisplacementInput) -> f32 {
    return adp_desplazamiento(input);
}

