// Intersecciones de rayos con las esferas del planeta y de la atmósfera. Porqué: docs/efectos/cielo-y-atmosfera.md §Modelo

// Distancias (t0, t1) a la esfera de `radio` centrada en el origen; t1 < 0 si no la corta.
// `dir` unitaria. Forma estable de la cuadrática (Real-Time Rendering 4.ª ed., §22.6.2).
fn atm_esfera(origen: vec3<f32>, dir: vec3<f32>, radio: f32) -> vec2<f32> {
    let b = dot(origen, dir);
    let c = dot(origen, origen) - radio * radio;
    let disc = b * b - c;
    if disc < 0.0 {
        return vec2<f32>(-1.0, -1.0);
    }
    let s = sqrt(disc);
    return vec2<f32>(-b - s, -b + s);
}
