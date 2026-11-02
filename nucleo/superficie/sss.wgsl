// Dispersión bajo la superficie de hojas, plantas, nieve y hielo. Porqué: docs/efectos/luz-de-superficie.md §SSS

// Fracción que atraviesa un grosor (bloques) para una cantidad de SSS 0..1: caída exponencial, más larga
// cuanto más SSS (las hojas dejan pasar 1–2 bloques; la nieve, centímetros).
fn sup_sss_perfil(grosor: f32, cantidad: f32) -> f32 {
    let alcance = mix(0.05, 1.5, cantidad);
    return exp(-max(grosor, 0.0) / alcance) * cantidad;
}

// Color tras atravesar el material: el albedo, más saturado cuanto más grueso.
fn sup_sss_color(albedo: vec3<f32>, perfil: f32) -> vec3<f32> {
    let l = col_luminancia(albedo);
    return max(albedo + (albedo - vec3<f32>(l)) * (1.0 - perfil) * 1.5, vec3<f32>(0.0));
}

// Fase muy hacia delante: dos lóbulos de Henyey-Greenstein, uno estrecho y otro ancho, normalizados para
// que de lado valga ~1 y a contraluz unas diez veces más.
fn sup_sss_fase(cos_vista_luz: f32) -> f32 {
    let estrecho = sup_hg(cos_vista_luz, 0.85);
    let ancho = sup_hg(cos_vista_luz, 0.4);
    return (0.4 * estrecho + 0.6 * ancho) * 4.0 * MAT_PI * 0.6;
}

fn sup_hg(c: f32, g: f32) -> f32 {
    let g2 = g * g;
    let den = max(1.0 + g2 - 2.0 * g * c, 1e-4);
    return (1.0 - g2) / (4.0 * MAT_PI * den * sqrt(den));
}
