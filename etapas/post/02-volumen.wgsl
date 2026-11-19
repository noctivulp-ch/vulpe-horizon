// Pasada 2 (cómputo a media resolución, destinos «volumen» y «volumen_prof»):
// aire, niebla y nubes con caché temporal 2×2 y reproyección (subsistema 05).
// Porqué: docs/efectos/niebla-y-nubes.md y docs/rendimiento.md
fn compute(input: ComputeInput) {
    adp_volumen_temporal(input);
}
