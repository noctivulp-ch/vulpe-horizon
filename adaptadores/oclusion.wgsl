// La oclusión ambiental en la composición, a resolución completa: Horizon admite 4 destinos propios y ya los usan
// el mapa de la aurora, el volumen y los dos de bloom; 7 lecturas de profundidad por píxel son baratas.
// Porqué: docs/efectos/oclusion-ambiental.md §Adaptadores

// Solo a la luz indirecta del terreno sólido (la fracción del dato de set_surface).
fn adp_aplicar_oclusion(color: vec3<f32>, p: AdpPixel) -> vec3<f32> {
    let o = opc_ao();
    if o.muestras == 0 || p.es_cielo {
        return color;
    }
    let s = surface_at(vec2<i32>(p.pixel));
    if !s.present {
        return color;
    }
    let c = LuzAo(frame.view_inverse * frame.projection_inverse, frame.projection * frame.view, frame.resolution,
                  OPC_AO_RADIO, o.muestras, o.fuerza, adp_ruido_azul(p.pixel, 3u));
    // La posición del punto con la misma reconstrucción que las muestras (no con view_position): una diferencia
    // mínima entre las dos daba autooclusión en las caras planas.
    let pos = luz_ao_posicion(c, scene_depth, (floor(p.pixel) + 0.5) / frame.resolution).xyz;
    let ao = luz_ao(pos + s.normal * 0.02, s.normal, c, scene_depth);
    let indirecta = sup_desempaquetar_dato(s.data).y;
    return color * (1.0 - indirecta * (1.0 - pow(ao, OPC_AO_CURVA)));
}
