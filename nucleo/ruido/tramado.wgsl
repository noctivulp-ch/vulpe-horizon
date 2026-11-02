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
