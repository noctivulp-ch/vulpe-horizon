// Pasada 5 (¼, destino «bloom2» rgba16float): desenfoque ancho del bloom y estado de exposición/calor (10, 11, 19).
// Porqué: docs/efectos/bloom.md y docs/efectos/exposicion-tonemap-gradacion.md
fn post(input: PostInput) -> vec4<f32> {
    return adp_bloom_ancho(input, bloom, historial_previous, bloom2_previous);
}
