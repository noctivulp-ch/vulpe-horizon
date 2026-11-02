// Fase de la niebla y las nubes: varios lóbulos de Henyey-Greenstein con el efecto «powder».
// Porqué: docs/efectos/niebla-y-nubes.md §Fase

fn vol_hg(c: f32, g: f32) -> f32 {
    let g2 = g * g;
    let den = max(1.0 + g2 - 2.0 * g * c, 1e-4);
    return (1.0 - g2) / (4.0 * MAT_PI * den * sqrt(den));
}

// `densidad_optica`: cuánto medio hay alrededor (0 bruma fina, >2 dentro de una nube densa). En lo poco
// denso domina el lóbulo muy hacia delante; en lo denso, el difuso (Schneider y Vos 2015; Wrenninge et al.
// 2013 para la suma de lóbulos como dispersión múltiple). Un lóbulo hacia atrás pequeño.
fn vol_fase(c: f32, densidad_optica: f32) -> f32 {
    let polvo = 1.0 - exp(-densidad_optica * 2.0);
    let delante = mix(vol_hg(c, 0.8), vol_hg(c, 0.45), polvo);
    let difuso = vol_hg(c, 0.1);
    let atras = vol_hg(c, -0.3);
    return delante * 0.6 + difuso * 0.32 + atras * 0.08;
}

// Fase de la niebla: casi todo hacia delante (el halo de la luna o del sol) y poca difusa. Con la de las nubes,
// la niebla nocturna se aclaraba en todas direcciones y quedaba gris (la referencia es azul marino oscuro
// salvo en el halo de la luna).
fn vol_fase_niebla(c: f32) -> f32 {
    return vol_hg(c, 0.9) * 0.96 + vol_hg(c, 0.3) * 0.025 + vol_hg(c, -0.3) * 0.015;
}
