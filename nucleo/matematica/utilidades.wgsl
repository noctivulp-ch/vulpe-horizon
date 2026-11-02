// Utilidades escalares y vectoriales sin estado. Porqué: docs/efectos/nucleo.md §Matemática

fn mat_saturar(x: f32) -> f32 {
    return clamp(x, 0.0, 1.0);
}

fn mat_saturar3(v: vec3<f32>) -> vec3<f32> {
    return clamp(v, vec3<f32>(0.0), vec3<f32>(1.0));
}

// Lleva x de [a, b] a [c, d] sin acotar.
fn mat_remapear(x: f32, a: f32, b: f32, c: f32, d: f32) -> f32 {
    return c + (x - a) * (d - c) / (b - a);
}

// Escalón quíntico (Perlin 2002): derivadas primera y segunda nulas en los extremos.
fn mat_escalon_quintico(t: f32) -> f32 {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

fn mat_escalon_quintico2(t: vec2<f32>) -> vec2<f32> {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

fn mat_escalon_quintico3(t: vec3<f32>) -> vec3<f32> {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}
