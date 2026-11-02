// Conversión entre sRGB codificado y lineal. Porqué: docs/efectos/nucleo.md §Color

// Curva exacta de IEC 61966-2-1.
fn col_srgb_a_lineal(c: vec3<f32>) -> vec3<f32> {
    let bajo = c / 12.92;
    let alto = pow((c + 0.055) / 1.055, vec3<f32>(2.4));
    return select(alto, bajo, c <= vec3<f32>(0.04045));
}

fn col_lineal_a_srgb(c_entrada: vec3<f32>) -> vec3<f32> {
    let c = max(c_entrada, vec3<f32>(0.0));
    let bajo = c * 12.92;
    let alto = 1.055 * pow(c, vec3<f32>(1.0 / 2.4)) - 0.055;
    return select(alto, bajo, c <= vec3<f32>(0.0031308));
}
