// Empaquetado del dato propio de set_surface: F0, la fracción indirecta y la luz de cielo de Minecraft, 8 bits
// cada uno en un f32 (el destino es de 32 bits por canal: entero exacto hasta 2^24).
// Porqué: docs/efectos/luz-de-superficie.md §Datos para post

fn sup_empaquetar_dato(f0: f32, indirecta: f32, luz_cielo: f32) -> f32 {
    let a = round(clamp(f0, 0.0, 1.0) * 255.0);
    let b = round(clamp(indirecta, 0.0, 1.0) * 255.0);
    let c = round(clamp(luz_cielo, 0.0, 1.0) * 255.0);
    return (a * 256.0 + b) * 256.0 + c;
}

// x = F0, y = fracción indirecta, z = luz de cielo.
fn sup_desempaquetar_dato(d: f32) -> vec3<f32> {
    let a = floor(d / 65536.0);
    let resto = d - a * 65536.0;
    let b = floor(resto / 256.0);
    return vec3<f32>(a, b, resto - b * 256.0) / 255.0;
}
