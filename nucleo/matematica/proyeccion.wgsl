// Paso entre coordenadas de pantalla, recorte y espacio. Porqué: docs/efectos/nucleo.md §Proyección

// uv de pantalla (0..1 desde arriba a la izquierda) a NDC de wgpu (y hacia arriba).
fn mat_uv_a_ndc(uv: vec2<f32>) -> vec2<f32> {
    return vec2<f32>(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0);
}

fn mat_ndc_a_uv(ndc: vec2<f32>) -> vec2<f32> {
    return vec2<f32>(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5);
}

// Aplica una matriz proyectiva a un punto y divide por w.
fn mat_proyectar(m: mat4x4<f32>, p: vec3<f32>) -> vec3<f32> {
    let h = m * vec4<f32>(p, 1.0);
    return h.xyz / h.w;
}
