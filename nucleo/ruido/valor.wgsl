// Ruido de valor 2D y 3D con interpolación quíntica. Porqué: docs/efectos/nucleo.md §Ruido

// Resultado en [0, 1].
fn rui_valor2(p: vec2<f32>) -> f32 {
    let i = vec2<i32>(floor(p));
    let f = mat_escalon_quintico2(fract(p));
    let a = rui_hash21(i);
    let b = rui_hash21(i + vec2<i32>(1, 0));
    let c = rui_hash21(i + vec2<i32>(0, 1));
    let d = rui_hash21(i + vec2<i32>(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Resultado en [0, 1].
fn rui_valor3(p: vec3<f32>) -> f32 {
    let i = vec3<i32>(floor(p));
    let f = mat_escalon_quintico3(fract(p));
    let n000 = rui_hash31(i);
    let n100 = rui_hash31(i + vec3<i32>(1, 0, 0));
    let n010 = rui_hash31(i + vec3<i32>(0, 1, 0));
    let n110 = rui_hash31(i + vec3<i32>(1, 1, 0));
    let n001 = rui_hash31(i + vec3<i32>(0, 0, 1));
    let n101 = rui_hash31(i + vec3<i32>(1, 0, 1));
    let n011 = rui_hash31(i + vec3<i32>(0, 1, 1));
    let n111 = rui_hash31(i + vec3<i32>(1, 1, 1));
    let x00 = mix(n000, n100, f.x);
    let x10 = mix(n010, n110, f.x);
    let x01 = mix(n001, n101, f.x);
    let x11 = mix(n011, n111, f.x);
    return mix(mix(x00, x10, f.y), mix(x01, x11, f.y), f.z);
}
