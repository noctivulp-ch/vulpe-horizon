// Etapa material: compone la luz de superficie (subsistema 03).
// Porqué: docs/efectos/luz-de-superficie.md §Composición
fn material(input: MaterialInput) -> Surface {
    let o = opc_luz();
    var p = adp_material_punto(input, o);
    let luces = adp_luces(o);
    let sombra = adp_sombra(p);

    // Humedad: más oscuro, más liso; en los charcos, normal plana y suavidad máxima.
    var albedo = p.albedo;
    var n = p.normal;
    var m = p.pbr;
    if (o.charcos || o.mojado) && p.fluido == 0u && !m.metal {
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
    let directa_luz = luces.directa / MAT_PI;

    // Luz directa y SSS: el SSS llena lo que la difusa no ilumina.
    var directa = albedo * difusa * sombra.luz;
    if m.sss > 0.0 {
        let perfil = sup_sss_perfil(sombra.grosor, m.sss);
        let color_sss = sup_sss_color(albedo, perfil);
        let fase = sup_sss_fase(dot(-p.vista, l));
        let sss_directo = color_sss * perfil * fase;
        directa = mix(sss_directo, albedo, clamp(difusa * col_luminancia(sombra.luz), 0.0, 1.0));
    }
    directa *= directa_luz;

    // Ambiente: cielo hemisférico × curva de la luz de cielo; bloque; mínima.
    let curva_cielo = luz_curva_cielo(p.luz_cielo);
    let ambiente_cielo = luz_hemisferica(n.y, luces.cielo, luces.suelo) * curva_cielo;
    var sss_cielo = vec3<f32>(0.0);
    if m.sss > 0.0 {
        sss_cielo = sup_sss_color(albedo, 0.5) * luces.cielo * curva_cielo * m.sss * mix(0.3, 0.8, p.vista.y * -0.5 + 0.5);
    }
    let bloque = adp_color_luz_bloque(p, o) * luz_curva_bloque(p.luz_bloque, OPC_LUZ_BLOQUE_REFUERZO) * OPC_LUZ_BLOQUE * o.bloque;
    let cielo_camara = frame.eye_light_smooth.y;
    let minima = OPC_LUZ_MINIMA * (mix(o.minima_cuevas, o.minima_exterior, max(p.luz_cielo, cielo_camara)) + frame.night_vision * 20.0);
    let indirecta = albedo * (ambiente_cielo + bloque + vec3<f32>(minima)) + sss_cielo;

    // Especular del sol y reflejo del ambiente.
    let f_ambiente = sup_fresnel_schlick_rugosidad(max(dot(n, p.vista), 0.0), m.f0, m.rugosidad);
    var especular = sup_especular(n, p.vista, l, m.rugosidad, m.f0) * max(dot(n, l), 0.0) * luces.directa * sombra.luz * o.especular_sol;
    var reflejo = vec3<f32>(0.0);
    let visible = smoothstep(0.45, 0.7, m.suavidad) * select(1.0, 1.0, m.metal);
    if visible > 0.0 || m.metal {
        let r = reflect(-p.vista, n);
        let horizonte = adp_tabla(frame.sun_direction.y, ATM_FILA_HORIZONTE) * opc_cielo().sol_color;
        let cielo_r = mix(horizonte, luces.cielo * 2.0, sqrt(max(r.y, 0.0)));
        let ambiente_r = select(cielo_r, luces.suelo, r.y < 0.0);
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

    // Emisión: mezcla hacia el color emitido.
    var emision = sup_emision_texeles(p.albedo, p.emision_bloque);
    var brillo_emision = 1.0;
    if m.emision > 0.0 {
        emision = pow(m.emision, 2.0);
        brillo_emision = o.emision_labpbr;
    }
    color = mix(color, p.albedo * OPC_EMISION * brillo_emision * 4.0, emision);

    if !p.translucido {
        let total = col_luminancia(directa + indirecta) + 1e-6;
        set_surface(n, m.suavidad, sup_empaquetar_dato(m.f0.g, col_luminancia(indirecta) / total));
    }
    return adp_material_salida(color, p.alfa, p);
}
