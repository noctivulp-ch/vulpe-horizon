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
    return vol_hg(c, 0.95) * 0.985 + vol_hg(c, 0.3) * 0.01 + vol_hg(c, -0.3) * 0.005;
}

// Fase de aerosoles del aire (Mie): tres lóbulos ajustados a la tabla «Halo solar de la perspectiva aérea» de fino/05
// (se aplica dos veces a la luz del sol: como fase de los aerosoles y como «fase solar directa»; F-5).
// Porqué: docs/efectos/niebla-y-nubes.md §Perspectiva aérea (F-5)
fn vol_fase_aire_mie(c: f32) -> f32 {
    return vol_hg(c, 0.9) * 0.5 + vol_hg(c, 0.55) * 5.0 + vol_hg(c, 0.3) * 1.0;
}

// Fase cenital del ambiente de la niebla (fino/05 §2 y su tabla medida: 0,5 en el nadir, 1,97 a −30°, 2,46 en el
// horizonte, 2,5 hacia arriba): `2,5 − 2·max(−y, 0)²` pasa por los cinco puntos con error < 0,04.
// Porqué: docs/efectos/niebla-y-nubes.md §Ambiente de la niebla (F-3)
fn vol_fase_cenital(dir_y: f32) -> f32 {
    let abajo = max(-dir_y, 0.0);
    return 2.5 - 2.0 * abajo * abajo;
}
