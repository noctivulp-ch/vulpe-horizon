// Reflejos de pantalla en la composición: la superficie de set_surface, el trazado del núcleo y el cielo
// aproximado cuando el rayo no impacta. Porqué: docs/efectos/luz-de-superficie.md §Reflejos de pantalla

// Reflejo de pantalla del píxel (subsistema 03): lo que ve el rayo reflejado (la escena si impacta, el cielo
// aproximado si no) por Fresnel. 0 si el píxel no es terreno sólido liso.
fn adp_post_reflejo(p: AdpPixel, dir: vec3<f32>, pasos: i32) -> vec3<f32> {
    if pasos <= 0 || p.es_cielo {
        return vec3<f32>(0.0);
    }
    let s = surface_at(vec2<i32>(p.pixel));
    if !s.present || s.smoothness < OPC_SUAVIDAD_REFLEJO_PANTALLA {
        return vec3<f32>(0.0);
    }
    let dato = sup_desempaquetar_dato(s.data);
    let pos = view_position(p.uv, p.profundidad);
    let n = s.normal;
    let rugosidad = (1.0 - s.smoothness) * (1.0 - s.smoothness);
    // Rugosidad: la normal de microfaceta se muestrea de la VNDF de GGX por píxel y fotograma (el TAA, 09,
    // promediará el ruido); en las superficies casi espejo apenas se desvía.
    let base = sup_base(n);
    let v_local = transpose(base) * (-dir);
    let u = vec2<f32>(adp_ruido_azul(p.pixel, 2u), adp_ruido_azul(p.pixel, 3u));
    let h = base * sup_muestrear_vndf(v_local, max(rugosidad, 1e-4), u);
    var r = reflect(dir, h);
    if dot(r, n) <= 0.0 {
        r = reflect(dir, n);
    }
    let f = sup_fresnel_schlick_rugosidad(max(dot(n, -dir), 0.0), vec3<f32>(dato.x), rugosidad);
    let vp = frame.projection * frame.view;
    let inv = frame.view_inverse * frame.projection_inverse;
    let camara = SupCamara(vp, inv, frame.resolution);
    let ruido = adp_ruido_azul(p.pixel, 0u);
    let impacto = sup_trazar_reflejo(pos + n * 0.02, r, camara, scene_depth, pasos, ruido, 48.0);
    // Sin impacto: el cielo aproximado de la tabla en la dirección reflejada, si el punto ve el cielo.
    let c = opc_cielo();
    let horizonte = adp_tabla(frame.sun_direction.y, ATM_FILA_HORIZONTE) * c.sol_color * c.brillo;
    var cielo = vol_cielo_aproximado(horizonte, adp_cielo_medio(c), r.y) * OPC_CIELO_BRILLO_DIBUJO;
    cielo = select(cielo, adp_suelo(c), r.y < 0.0) * luz_curva_cielo(dato.z);
    var visto = cielo;
    if impacto.peso > 0.0 {
        let escena = col_decodificar_escena(textureLoad(scene_color, vec2<i32>(impacto.uv * frame.resolution), 0).rgb, adp_codificacion());
        visto = mix(cielo, escena, impacto.peso);
    }
    return visto * f;
}
