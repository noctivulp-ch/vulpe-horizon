// Luz de las menas (25, efecto propio de Vulpe), ruta A: en la composición, cada píxel de terreno reúne la luz de los
// píxeles de mineral que ve en un disco de pantalla del radio del alcance a su profundidad; caída con la distancia en
// 3D y N·L, atenuada en el borde de la pantalla; el disco gira por fotograma y el TAA lo promedia.
// Porqué: docs/efectos/menas-brillantes.md §«Luz de las menas (F-50)»
fn adp_luz_menas(color: vec3<f32>, p: AdpPixel) -> vec3<f32> {
    let om = opc_menas();
    if !OPC_MENAS_LUZ || !om.activas || p.es_cielo {
        return color;
    }
    let s = surface_at(vec2<i32>(p.pixel));
    if !s.present {
        return color;
    }
    let c = LuzAo(frame.view_inverse * frame.projection_inverse, frame.projection * frame.view, frame.resolution,
                  OPC_AO_RADIO_K, OPC_AO_RADIO_MIN, OPC_AO_RADIO_MAX, OPC_AO_ESCALA, 0, 0.0, 0.0);
    let pos = luz_ao_posicion(c, scene_depth, (floor(p.pixel) + 0.5) / frame.resolution).xyz;
    let radio = OPC_MENAS_LUZ_ALCANCE * frame.projection[1][1] / max(length(pos), 0.1) * 0.5 * frame.resolution.y;
    if radio < 1.0 {
        return color;
    }
    let giro = fract(adp_ruido_azul(p.pixel, 2u) + 0.618034 * f32(frame.frame_index % 64u)) * MAT_TAU;
    var luz = vec3<f32>(0.0);
    for (var i = 0; i < OPC_MENAS_LUZ_MUESTRAS; i++) {
        let t = floor(p.pixel + luz_vogel(i, OPC_MENAS_LUZ_MUESTRAS, giro) * radio);
        let uv = (t + 0.5) / frame.resolution;
        if any(uv < vec2<f32>(0.0)) || any(uv > vec2<f32>(1.0)) {
            continue;
        }
        let m = surface_at(vec2<i32>(t));
        if !m.present || !sup_es_mena(m.smoothness) {
            continue;
        }
        let hs = sup_desempaquetar_suavidad(m.smoothness).yz;
        if hs.y < OPC_MENAS_LUZ_SAT_MIN {
            continue;
        }
        // La fuente, medio bloque fuera de la cara de la mena: la piedra del mismo muro también la recibe.
        let fuente = luz_ao_posicion(c, scene_depth, uv).xyz + m.normal * OPC_MENAS_LUZ_SALIDA;
        let l = fuente - pos;
        let d = length(l);
        let borde = smoothstep(0.0, 0.03, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
        luz += sup_color_matiz(hs.x, 1.0, 1.0) * (sup_mena_luz_caida(d, OPC_MENAS_LUZ_ALCANCE)
             * max(dot(s.normal, l / max(d, 1e-3)), 0.0) * borde);
    }
    // El albedo del receptor, aproximado por su matiz y saturación guardados (sin el valor, que no se guarda).
    let receptor = sup_desempaquetar_suavidad(s.smoothness).yz;
    let albedo = col_srgb_a_lineal(sup_color_matiz(receptor.x, receptor.y, 0.6));
    // Cada muestra representa πR²/N bloques² del disco: la suma estima la luz de la superficie de mineral que se ve,
    // no la fracción del disco que ocupa (que con una sola mena es de un 3–4 %).
    let area = MAT_PI * OPC_MENAS_LUZ_ALCANCE * OPC_MENAS_LUZ_ALCANCE / f32(OPC_MENAS_LUZ_MUESTRAS);
    return color + albedo * luz * (OPC_MENAS_LUZ_INTENSIDAD * om.intensidad * area);
}
