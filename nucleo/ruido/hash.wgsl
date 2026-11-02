// Hash entero PCG y sus formas a flotante. Porqué: docs/efectos/nucleo.md §Ruido

// PCG (Jarzynski y Olano, «Hash Functions for GPU Rendering», JCGT 2020).
fn rui_pcg(v: u32) -> u32 {
    let estado = v * 747796405u + 2891336453u;
    let palabra = ((estado >> ((estado >> 28u) + 4u)) ^ estado) * 277803737u;
    return (palabra >> 22u) ^ palabra;
}

// PCG3D (mismo artículo): tres salidas mezcladas entre sí.
fn rui_pcg3(v_entrada: vec3<u32>) -> vec3<u32> {
    var v = v_entrada * 1664525u + 1013904223u;
    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v ^= v >> vec3<u32>(16u);
    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    return v;
}

fn rui_u32_a_unidad(x: u32) -> f32 {
    return f32(x >> 8u) * (1.0 / 16777216.0);
}

// Valor en [0, 1) para una celda entera 2D.
fn rui_hash21(celda: vec2<i32>) -> f32 {
    let c = bitcast<vec2<u32>>(celda);
    return rui_u32_a_unidad(rui_pcg(c.x + rui_pcg(c.y)));
}

// Valor en [0, 1) para una celda entera 3D.
fn rui_hash31(celda: vec3<i32>) -> f32 {
    return rui_u32_a_unidad(rui_pcg3(bitcast<vec3<u32>>(celda)).x);
}

// Tres valores en [0, 1) para una celda entera 3D.
fn rui_hash33(celda: vec3<i32>) -> vec3<f32> {
    let h = rui_pcg3(bitcast<vec3<u32>>(celda)) >> vec3<u32>(8u);
    return vec3<f32>(h) * (1.0 / 16777216.0);
}
