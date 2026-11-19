// Pasada previa al mundo: calcula una vez por fotograma las luces, tablas por elevación del sol y nubes.
// Porqué: docs/rendimiento.md
fn compute(input: ComputeInput) {
    if !input.in_bounds {
        return;
    }
    adp_cuadro_escribir();
}
