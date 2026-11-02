// Empaquetado del dato propio de set_surface: F0 y la fracción indirecta, 8 bits cada uno en un f32 (el
// destino es de 32 bits por canal: entero exacto hasta 2^24). Porqué: docs/efectos/luz-de-superficie.md §Datos para post

fn sup_empaquetar_dato(f0: f32, indirecta: f32) -> f32 {
    let a = round(clamp(f0, 0.0, 1.0) * 255.0);
    let b = round(clamp(indirecta, 0.0, 1.0) * 255.0);
    return a * 256.0 + b;
}

// x = F0, y = fracción indirecta.
fn sup_desempaquetar_dato(d: f32) -> vec2<f32> {
    let a = floor(d / 256.0);
    return vec2<f32>(a, d - a * 256.0) / 255.0;
}
