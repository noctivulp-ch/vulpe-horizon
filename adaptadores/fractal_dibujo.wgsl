// Ajustes completos del dibujo del cielo fractal: los usan el cielo (02) y el mapa de la aurora (06), que
// dibujan el fractal; el sorteo es compartido (adaptadores/fractal.wgsl). Porqué: docs/efectos/cielo-fractal.md
fn adp_fractal_ajustes(o: OpcFractal, cielo_medio: vec3<f32>) -> CieFractalAjustes {
    return CieFractalAjustes(
        adp_fractal_sorteo(o),
        CiePaleta(o.paleta, o.contraste, o.saturacion, cielo_medio),
        o.dibujo, OPC_FRACTAL_ITERACIONES, o.mutacion, o.brillo, o.techo, o.hueco,
    );
}
