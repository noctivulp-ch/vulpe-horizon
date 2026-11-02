// Pasada 1 (¼ de resolución, destino «mapa_aurora»): el mapa de la aurora (subsistema 06). Solo de noche.
// Porqué: docs/efectos/aurora.md §Mapa
fn post(input: PostInput) -> vec4<f32> {
    if !adp_aurora(OPC_AURORA_RADIO).activa {
        return vec4<f32>(0.0, 0.0, 0.0, 1.0);
    }
    return adp_aurora_mapa(input.uv);
}
