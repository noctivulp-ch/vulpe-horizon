// Etapa [[before_world]]: avanza la simulación global de paneles de lluvia y copos en `cristal_sim`.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §2
fn compute(input: ComputeInput) {
    if !input.in_bounds {
        return;
    }
    adp_cristal_sim_paso(input.cell.x);
}
