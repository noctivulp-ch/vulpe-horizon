// Ruido azul de la textura del pack (tools/ruido/generar_ruido_azul.py), por píxel y fotograma. Compartido.
// Porqué: docs/efectos/taa.md §Ruido azul

// `canal` 0..3: cuatro ruidos independientes (uno por canal de la textura).
fn adp_ruido_azul(pixel: vec2<f32>, canal: u32) -> f32 {
    let t = textureLoad(ruido_azul, vec2<i32>(pixel) & vec2<i32>(63), 0);
    return rui_azul(t[canal & 3u], frame.frame_index, canal);
}
