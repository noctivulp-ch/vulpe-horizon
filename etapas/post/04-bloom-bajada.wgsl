// Pasada 4 (¼, destino «bloom»): bajada del bloom desde la salida del TAA (10).
// Porqué: docs/efectos/bloom.md
fn post(input: PostInput) -> vec4<f32> {
    return adp_bloom_bajada(input, historial_previous);
}
