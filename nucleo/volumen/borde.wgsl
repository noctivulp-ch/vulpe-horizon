// Niebla de borde: el terreno del final de la distancia de renderizado se funde con el cielo.
// Porqué: docs/efectos/niebla-y-nubes.md §Borde

// `cilindrica`: distancia horizontal del punto; `alcance`: distancia de renderizado; `dir_y`: componente
// vertical de la vista; `fuera`: 0 en una cueva (nunca se aplica allí). Solo el último tercio, y solo cerca
// del horizonte (no mirando arriba ni abajo).
fn vol_borde(cilindrica: f32, alcance: f32, dir_y: f32, fuera: f32) -> f32 {
    let f = smoothstep(alcance * 0.66, alcance * 0.98, cilindrica);
    let horizonte = 1.0 - smoothstep(0.15, 0.5, abs(dir_y));
    return f * horizonte * fuera;
}

// Color del cielo cerca del horizonte en la dirección `dir_y`, desde la tabla: del horizonte al cielo medio.
fn vol_cielo_aproximado(horizonte: vec3<f32>, cielo_medio: vec3<f32>, dir_y: f32) -> vec3<f32> {
    return mix(horizonte, cielo_medio * 2.0, sqrt(max(dir_y, 0.0)));
}
