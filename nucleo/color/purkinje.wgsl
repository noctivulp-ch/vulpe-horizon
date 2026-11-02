// Visión con poca luz (efecto Purkinje). Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Purkinje

// Luminancia escotópica aproximada para primarios sRGB lineales (máximo hacia 507 nm: favorece verde azulado).
fn col_luminancia_escotopica(c: vec3<f32>) -> f32 {
    return dot(c, vec3<f32>(0.06, 0.53, 0.41));
}

// Mezcla hacia la luminancia escotópica × un azul pálido con el peso `bastones` (0..1).
fn col_purkinje(c: vec3<f32>, bastones: f32) -> vec3<f32> {
    let tinte = vec3<f32>(0.4, 0.7, 1.0) / col_luminancia(vec3<f32>(0.4, 0.7, 1.0));
    return mix(c, vec3<f32>(col_luminancia_escotopica(c)) * tinte, clamp(bastones, 0.0, 1.0));
}

// Peso de los bastones con la luminancia adaptada de la escena: L₀ / (L₀ + L).
fn col_peso_bastones(l_adaptada: f32, l0: f32) -> f32 {
    return l0 / (l0 + max(l_adaptada, 0.0));
}
