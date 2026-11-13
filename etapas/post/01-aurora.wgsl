// Pasada 1 (¼ de resolución, destino «mapa_aurora»): el mapa de la aurora (subsistema 06). Solo de noche.
// Porqué: docs/efectos/aurora.md §Mapa
fn post(input: PostInput) -> vec4<f32> {
    if !adp_aurora(OPC_AURORA_RADIO).activa {
        // De día el destino está libre: guarda en r la sombra de las nubes del terreno (F-68).
        if adp_sombra_nubes_en_post() {
            return vec4<f32>(adp_sombra_nubes_post(input.uv, input.depth), 0.0, 0.0, 1.0);
        }
        return vec4<f32>(0.0, 0.0, 0.0, 1.0);
    }
    return adp_aurora_mapa(input.uv);
}
