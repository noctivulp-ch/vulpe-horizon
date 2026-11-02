// Lectura de las texturas de ruido en mosaico (tools/ruido/generar_ruido.py). Las texturas llegan por
// parámetro. Porqué: docs/efectos/niebla-y-nubes.md §Ruido

// `uv` en periodos del mosaico (1 = una vuelta de la textura).
fn vol_ruido2d(t: texture_2d<f32>, s: sampler, uv: vec2<f32>) -> vec4<f32> {
    return textureSampleLevel(t, s, uv, 0.0);
}

// Volumen 32³ guardado como 32 cortes en fila; `p` en periodos. Trilineal a mano con textureLoad, para
// que repita exacto en los tres ejes sin sangrar entre cortes vecinos del atlas.
fn vol_ruido3d(t: texture_2d<f32>, p: vec3<f32>) -> vec4<f32> {
    let q = p * 32.0 - 0.5;
    let i = vec3<i32>(floor(q));
    let f = q - floor(q);
    var r = vec4<f32>(0.0);
    for (var k = 0; k < 8; k++) {
        let o = vec3<i32>(k & 1, (k >> 1) & 1, (k >> 2) & 1);
        let c = (i + o) & vec3<i32>(31);
        let w = mix(1.0 - f, f, vec3<f32>(o));
        r += textureLoad(t, vec2<i32>(c.z * 32 + c.x, c.y), 0) * (w.x * w.y * w.z);
    }
    return r;
}
