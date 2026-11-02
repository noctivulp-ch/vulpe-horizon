// Pasada 2: decodifica la escena (ADR 0004) y compone el volumen y la niebla de borde. Sale luz lineal.
// Porqué: docs/efectos/niebla-y-nubes.md §Composición
fn post(input: PostInput) -> vec4<f32> {
    let p = adp_post_pixel(input);
    var c = adp_post_escena(p);
    let dir = adp_post_direccion(p);
    let borde = adp_post_borde(p, dir);
    c = mix(c, borde.rgb, borde.a);
    let v = adp_volumen_reescalado(p.pixel, adp_post_distancia(p));
    c = c * v.transmitancia + v.luz;
    return vec4<f32>(c, 1.0);
}
