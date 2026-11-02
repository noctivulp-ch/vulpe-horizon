// Pasada 4 (¼, destino «bloom»): bajada del bloom desde la salida del TAA y medida de la exposición (10, 11).
// Porqué: docs/efectos/bloom.md y docs/efectos/exposicion-tonemap-gradacion.md
fn post(input: PostInput) -> vec4<f32> {
    return adp_bloom_bajada(input);
}
