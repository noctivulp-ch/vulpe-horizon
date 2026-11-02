// BRDF de microfacetas GGX con Smith correlacionado y Fresnel de Schlick. Porqué: docs/efectos/luz-de-superficie.md §Especular

// Distribución GGX / Trowbridge-Reitz (Walter et al. 2007), `a` = rugosidad lineal².
fn sup_ggx(n_h: f32, a: f32) -> f32 {
    let a2 = a * a;
    let d = n_h * n_h * (a2 - 1.0) + 1.0;
    return a2 / (MAT_PI * d * d + 1e-7);
}

// Visibilidad de Smith-GGX correlacionada en altura (Heitz 2014), ya dividida por 4·N·V·N·L.
fn sup_visibilidad_smith(n_v: f32, n_l: f32, a: f32) -> f32 {
    let a2 = a * a;
    let gv = n_l * sqrt(n_v * n_v * (1.0 - a2) + a2);
    let gl = n_v * sqrt(n_l * n_l * (1.0 - a2) + a2);
    return 0.5 / max(gv + gl, 1e-5);
}

fn sup_fresnel_schlick(cos_theta: f32, f0: vec3<f32>) -> vec3<f32> {
    let k = pow(1.0 - clamp(cos_theta, 0.0, 1.0), 5.0);
    return f0 + (vec3<f32>(1.0) - f0) * k;
}

// Schlick con rugosidad (Lagarde y de Rousiers 2014): el reflejo del ambiente de una superficie rugosa no
// llega a blanco en ángulo rasante.
fn sup_fresnel_schlick_rugosidad(cos_theta: f32, f0: vec3<f32>, rugosidad: f32) -> vec3<f32> {
    let k = pow(1.0 - clamp(cos_theta, 0.0, 1.0), 5.0);
    return f0 + (max(vec3<f32>(1.0 - rugosidad), f0) - f0) * k;
}

// BRDF especular f_s(l, v) en sr⁻¹ (sin el N·L).
fn sup_especular(n: vec3<f32>, v: vec3<f32>, l: vec3<f32>, rugosidad: f32, f0: vec3<f32>) -> vec3<f32> {
    let h = normalize(v + l);
    let n_v = max(dot(n, v), 1e-4);
    let n_l = max(dot(n, l), 0.0);
    let n_h = max(dot(n, h), 0.0);
    let a = max(rugosidad * rugosidad, 0.002);
    return sup_ggx(n_h, a) * sup_visibilidad_smith(n_v, n_l, a) * sup_fresnel_schlick(dot(v, h), f0);
}
