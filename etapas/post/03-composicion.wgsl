// Pasada 2: decodifica la escena (ADR 0004), añade los reflejos de pantalla (03) y compone la niebla de
// borde y el volumen (05). Sale luz lineal. Porqué: docs/efectos/niebla-y-nubes.md §Composición y
// docs/efectos/luz-de-superficie.md §Reflejos de pantalla
fn post(input: PostInput) -> vec4<f32> {
    let p = adp_post_pixel(input);
    var c = adp_post_escena(p);
    let dir = adp_post_direccion(p);
    c += adp_post_reflejo(p, dir, opc_luz().pasos_reflejo);
    let borde = adp_post_borde(p, dir);
    c = mix(c, borde.rgb, borde.a);
    let v = adp_volumen_reescalado(p.pixel, adp_post_distancia(p));
    c = c * v.transmitancia + v.luz;
    return vec4<f32>(c, 1.0);
}
