// Niebla de borde: el terreno del final de la distancia de renderizado se funde con el cielo.
// Porqué: docs/efectos/niebla-y-nubes.md §Borde

// `cilindrica`: distancia horizontal del punto; `alcance`: distancia de renderizado; `dir_y`: componente
// vertical de la vista; `fuera`: 0 en una cueva (nunca se aplica allí). Solo el último tercio, y solo cerca
// del horizonte (no mirando arriba ni abajo).
// Niebla de borde (23 §2): densidad con la distancia horizontal en el último tercio (`smoothstep(0,67; 1)` de la
// distancia de renderizado) y, con la vista, total al frente y abajo y nula mirando 10°–15° arriba
// (`e^(−(y/0,079)²)`, tabla con error < 0,01). `fuera`: 1 − detector de cueva.
fn vol_borde(cilindrica: f32, alcance: f32, dir_y: f32, fuera: f32) -> f32 {
    let f = smoothstep(alcance * 0.67, alcance, cilindrica);
    let arriba = max(dir_y, 0.0) / 0.079;
    return f * exp(-arriba * arriba) * fuera;
}

// Color del cielo cerca del horizonte en la dirección `dir_y`, desde la tabla: del horizonte al cielo medio.
fn vol_cielo_aproximado(horizonte: vec3<f32>, cielo_medio: vec3<f32>, dir_y: f32) -> vec3<f32> {
    return mix(horizonte, cielo_medio * 2.0, sqrt(max(dir_y, 0.0)));
}
