// Etapa [[before_world]]: actualiza la caché espacial 3D de caras de cristal (`cristal_mapa`).
// Porqué: docs/efectos/tiempo-en-los-cristales.md §Arquitectura y coste
fn compute(input: ComputeInput) {
    if !input.in_bounds {
        return;
    }
    adp_cristal_mapa_actualizar(input.cell);
}
