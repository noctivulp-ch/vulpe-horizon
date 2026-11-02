// Pasada 4, penúltima (history es su propia salida del fotograma anterior): TAA (subsistema 09).
// Porqué: docs/efectos/taa.md
fn post(input: PostInput) -> vec4<f32> {
    return adp_taa(input);
}
