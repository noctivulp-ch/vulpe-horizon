// Funciones de fase de la dispersión. Porqué: docs/efectos/cielo-y-atmosfera.md §Modelo

fn atm_fase_rayleigh(cos_theta: f32) -> f32 {
    return 3.0 / (16.0 * MAT_PI) * (1.0 + cos_theta * cos_theta);
}

// Fase molecular de Elek (2009): ligera asimetría hacia adelante (doble hacia el sol que hacia atrás).
// Porqué: docs/efectos/cielo-y-atmosfera.md §Modelo
fn atm_fase_elek(cos_theta: f32) -> f32 {
    return (2.8 + cos_theta) / (10.0 * MAT_PI);
}

// Cornette-Shanks (Applied Optics 31, 1992): Henyey-Greenstein con el término (1+cos²) que da algo de
// retrodispersión; normalizada sobre la esfera.
fn atm_fase_cornette_shanks(cos_theta: f32, g: f32) -> f32 {
    let g2 = g * g;
    let k = 3.0 / (8.0 * MAT_PI) * (1.0 - g2) / (2.0 + g2);
    let den = max(1.0 + g2 - 2.0 * g * cos_theta, 1e-4);
    return k * (1.0 + cos_theta * cos_theta) / (den * sqrt(den));
}
