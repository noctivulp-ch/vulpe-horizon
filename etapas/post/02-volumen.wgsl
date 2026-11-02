// Pasada 1 (media resolución, destino «volumen»): aire, niebla y nubes en un solo raymarch (subsistema 05).
// Porqué: docs/efectos/niebla-y-nubes.md
fn post(input: PostInput) -> vec4<f32> {
    return adp_volumen_salida(adp_volumen(input.uv, input.pixel));
}
