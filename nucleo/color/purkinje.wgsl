// Visión con poca luz (efecto Purkinje). Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Purkinje

// Luminancia escotópica aproximada para primarios sRGB lineales (máximo hacia 507 nm: favorece verde azulado).
fn col_luminancia_escotopica(c: vec3<f32>) -> f32 {
    return dot(c, vec3<f32>(0.06, 0.53, 0.41));
}

// Mezcla hacia la luminancia escotópica × un azul pálido con el peso `bastones` (0..1) de la escena, menor cuanto más
// brillante es el píxel ya expuesto: peso · k / (k + luminancia) (fino/02 «Respuesta a la pregunta 13», medido: de noche
// un ámbar de 6·10⁻⁵ expuesto conserva el 19 % del color; de 0,0057, el 49 %; de 0,057, el 88 %).
fn col_purkinje(c: vec3<f32>, bastones: f32, k: f32) -> vec3<f32> {
    let tinte = vec3<f32>(0.4, 0.7, 1.0) / col_luminancia(vec3<f32>(0.4, 0.7, 1.0));
    let peso = clamp(bastones, 0.0, 1.0) * k / (k + col_luminancia(max(c, vec3<f32>(0.0))));
    return mix(c, vec3<f32>(col_luminancia_escotopica(c)) * tinte, peso);
}

// Peso de los bastones con la luminancia adaptada de la escena: L₀ / (L₀ + L).
fn col_peso_bastones(l_adaptada: f32, l0: f32) -> f32 {
    return l0 / (l0 + max(l_adaptada, 0.0));
}
