// El cielo fractal de esta noche: día y semilla del mundo (del mod nativo, si lo hay) y opciones.
// Porqué: docs/efectos/cielo-fractal.md §Adaptadores

// frame.mods[0]: x mod activo, y semilla del mundo plegada (0..4095), z número de día (convenciones.md).
fn adp_fractal_sorteo(o: OpcFractal) -> CieFractalSorteo {
    let con_mod = frame.mods[0].x > 0.5;
    let semilla_mundo = select(0, i32(frame.mods[0].y), con_mod);
    let dia = select(0.0, floor(frame.mods[0].z), con_mod) + frame.day_time;
    return CieFractalSorteo(o.semilla, semilla_mundo, dia, o.cambios_por_noche, o.conjuntos, o.cobertura);
}
