// Nitidez adaptativa por contraste, a la manera de CAS (AMD FidelityFX, 2019): la cruz de vecinos define cuánto
// se puede afilar sin crear halos. Trabaja en el espacio comprimido c/(1 + luma) (la imagen es HDR) y devuelve
// luz lineal. Textura por parámetro. Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Nitidez
fn img_nitidez(t: texture_2d<f32>, s: sampler, uv: vec2<f32>, cantidad: f32) -> vec3<f32> {
    let px = 1.0 / vec2<f32>(textureDimensions(t));
    let centro = img_comprimir(textureSampleLevel(t, s, uv, 0.0).rgb);
    let n = img_comprimir(textureSampleLevel(t, s, uv + vec2<f32>(0.0, -px.y), 0.0).rgb);
    let so = img_comprimir(textureSampleLevel(t, s, uv + vec2<f32>(0.0, px.y), 0.0).rgb);
    let e = img_comprimir(textureSampleLevel(t, s, uv + vec2<f32>(px.x, 0.0), 0.0).rgb);
    let o = img_comprimir(textureSampleLevel(t, s, uv + vec2<f32>(-px.x, 0.0), 0.0).rgb);
    let mn = min(min(min(n, so), min(e, o)), centro);
    let mx = max(max(max(n, so), max(e, o)), centro);
    // Margen hasta los extremos: donde ya hay mucho contraste se afila poco.
    let margen = clamp(min(mn, 1.0 - mx) / max(mx, vec3<f32>(1e-4)), vec3<f32>(0.0), vec3<f32>(1.0));
    let w = -sqrt(margen) * mix(0.125, 0.2, cantidad);
    let r = clamp((centro + (n + so + e + o) * w) / (1.0 + 4.0 * w), vec3<f32>(0.0), vec3<f32>(0.999));
    return img_descomprimir(r);
}
