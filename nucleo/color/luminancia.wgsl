// Luminancia relativa de un color lineal. Porqué: docs/efectos/nucleo.md §Color

// Pesos de Rec. 709 / sRGB.
fn col_luminancia(c: vec3<f32>) -> f32 {
    return dot(c, vec3<f32>(0.2126, 0.7152, 0.0722));
}
