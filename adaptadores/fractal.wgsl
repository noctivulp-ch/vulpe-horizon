// El cielo fractal de esta noche: día del mundo (del mod nativo, si lo hay) y opciones.
// Porqué: docs/efectos/cielo-fractal.md §Adaptadores

fn adp_fractal_sorteo(o: OpcFractal) -> CieFractalSorteo {
    let m = adp_mod();
    let dia = select(0.0, m.dia, m.tiene_tiempo) + frame.day_time;
    return CieFractalSorteo(o.semilla, 0, dia, o.cambios_por_noche, o.conjuntos, o.cobertura, o.sorteo_original);
}
