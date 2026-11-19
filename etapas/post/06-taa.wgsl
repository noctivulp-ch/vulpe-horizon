// Pasada 4, penúltima (history es su propia salida del fotograma anterior): TAA (subsistema 09).
// Porqué: docs/efectos/taa.md
fn post(input: PostInput) -> vec4<f32> {
    if opc_depuracion().vista == OPC_VISTA_RELIEVE || opc_quitar(32u) {
        return textureSampleLevel(composicion, nearest_sampler, input.uv, 0.0);
    }
    return adp_taa(input);
}
