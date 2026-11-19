// Etapa [[before_world]]: rasteriza las gotas y rastros de lluvia en `cristal_clima` (512x512).
// Porqué: docs/efectos/tiempo-en-los-cristales.md §2
fn compute(input: ComputeInput) {
    adp_cristal_lienzo(input.cell, input.local, input.in_bounds);
}
