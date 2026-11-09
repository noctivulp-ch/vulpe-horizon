// El mapa de la aurora (solo en su pasada, que dibuja el fractal). Porqué: docs/efectos/aurora.md §Mapa
// El texel del mapa: la uv de la pasada es el punto del disco.
fn adp_aurora_mapa(uv: vec2<f32>) -> vec4<f32> {
    var ajustes = adp_fractal_ajustes(opc_fractal(), adp_cielo_medio(opc_cielo()));
    ajustes.iteraciones = opc_aurora().iteraciones;
    return cie_aurora_mapa(uv * 2.0 - 1.0, frame.sun_direction, ajustes);
}
