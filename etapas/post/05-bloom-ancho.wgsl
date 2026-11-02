// Pasada 5 (¼, destino «bloom2»): desenfoque ancho del bloom; guarda el estado de la exposición (10, 11).
// Porqué: docs/efectos/bloom.md
fn post(input: PostInput) -> vec4<f32> {
    return adp_bloom_ancho(input);
}
