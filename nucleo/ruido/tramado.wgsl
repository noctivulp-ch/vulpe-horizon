// Ruido de tramado por píxel para romper bandas. Porqué: docs/efectos/nucleo.md §Ruido

// Interleaved gradient noise (Jimenez, «Next Generation Post Processing in Call of Duty:
// Advanced Warfare», SIGGRAPH 2014). `pixel` en píxeles; resultado en [0, 1).
fn rui_tramado_ign(pixel: vec2<f32>) -> f32 {
    return fract(52.9829189 * fract(dot(pixel, vec2<f32>(0.06711056, 0.00583715))));
}

// Ruido blanco por dirección, para etapas sin píxel (sky): cada píxel ve una dirección distinta y sus bits
// mezclados dan un valor independiente. Resultado en [0, 1).
fn rui_tramado_direccion(dir: vec3<f32>) -> f32 {
    return rui_u32_a_unidad(rui_pcg3(bitcast<vec3<u32>>(dir)).x);
}

// Ruido blanco por píxel y fotograma (PCG): sin la estructura diagonal del IGN, que en los raymarch de pocos
// pasos se veía como estrías paralelas. Resultado en [0, 1).
fn rui_blanco_pixel(pixel: vec2<f32>, fotograma: u32) -> f32 {
    let p = vec2<u32>(pixel);
    return rui_u32_a_unidad(rui_pcg(p.x + rui_pcg(p.y + rui_pcg(fotograma))));
}

// Secuencia R2 (Roberts 2018): desplazamiento cuasialeatorio por fotograma en dos ejes, en [0, 1).
fn rui_r2(fotograma: u32) -> vec2<f32> {
    let n = f32(fotograma % 65536u);
    return fract(vec2<f32>(0.5) + n * vec2<f32>(0.7548776662, 0.5698402910));
}

// Un valor de ruido azul de la textura desplazado por fotograma con R2 (eje 0 o 1 de la secuencia).
fn rui_azul(valor: f32, fotograma: u32, eje: u32) -> f32 {
    return fract(valor + rui_r2(fotograma)[eje & 1u]);
}
