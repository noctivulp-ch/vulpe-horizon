// Etapa vertex: compone la vegetación ondulante (subsistema 15), en el mundo y en el mapa de sombras.
// Porqué: docs/efectos/vegetacion-ondulante.md
fn vertex(input: VertexInput) -> vec3<f32> {
    return adp_vertice_ondulado(input);
}
