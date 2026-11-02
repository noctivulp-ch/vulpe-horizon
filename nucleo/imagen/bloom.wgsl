// Bloom sin umbral: bajada con la caja compuesta de 13 lecturas y desenfoque ancho disperso. Texturas por
// parámetro. Porqué: docs/efectos/bloom.md

// Caja 4×4 compuesta de 13 lecturas bilineales (Jimenez 2014), con el promedio de Karis (pesos 1/(1 + luma)) en
// cada uno de los cinco grupos: un píxel muy brillante aislado no da un halo que parpadea.
fn img_bloom_bajada(t: texture_2d<f32>, s: sampler, uv: vec2<f32>) -> vec3<f32> {
    let px = 1.0 / vec2<f32>(textureDimensions(t));
    let a = textureSampleLevel(t, s, uv + px * vec2<f32>(-2.0, -2.0), 0.0).rgb;
    let b = textureSampleLevel(t, s, uv + px * vec2<f32>(0.0, -2.0), 0.0).rgb;
    let c = textureSampleLevel(t, s, uv + px * vec2<f32>(2.0, -2.0), 0.0).rgb;
    let d = textureSampleLevel(t, s, uv + px * vec2<f32>(-1.0, -1.0), 0.0).rgb;
    let e = textureSampleLevel(t, s, uv + px * vec2<f32>(1.0, -1.0), 0.0).rgb;
    let f = textureSampleLevel(t, s, uv + px * vec2<f32>(-2.0, 0.0), 0.0).rgb;
    let g = textureSampleLevel(t, s, uv, 0.0).rgb;
    let h = textureSampleLevel(t, s, uv + px * vec2<f32>(2.0, 0.0), 0.0).rgb;
    let i = textureSampleLevel(t, s, uv + px * vec2<f32>(-1.0, 1.0), 0.0).rgb;
    let j = textureSampleLevel(t, s, uv + px * vec2<f32>(1.0, 1.0), 0.0).rgb;
    let k = textureSampleLevel(t, s, uv + px * vec2<f32>(-2.0, 2.0), 0.0).rgb;
    let l = textureSampleLevel(t, s, uv + px * vec2<f32>(0.0, 2.0), 0.0).rgb;
    let m = textureSampleLevel(t, s, uv + px * vec2<f32>(2.0, 2.0), 0.0).rgb;
    var suma = vec3<f32>(0.0);
    var pesos = 0.0;
    suma += img_bloom_grupo(d, e, i, j, 0.5, &pesos);
    suma += img_bloom_grupo(a, b, f, g, 0.125, &pesos);
    suma += img_bloom_grupo(b, c, g, h, 0.125, &pesos);
    suma += img_bloom_grupo(f, g, k, l, 0.125, &pesos);
    suma += img_bloom_grupo(g, h, l, m, 0.125, &pesos);
    return suma / max(pesos, 1e-6);
}

fn img_bloom_grupo(a: vec3<f32>, b: vec3<f32>, c: vec3<f32>, d: vec3<f32>, peso: f32, pesos: ptr<function, f32>) -> vec3<f32> {
    let m = (a + b + c + d) * 0.25;
    let w = peso / (1.0 + col_luminancia(m));
    *pesos += w;
    return m * w;
}

// Desenfoque ancho: 32 lecturas en un disco de Vogel fijo (sin rotar: el bloom no pasa por el TAA después),
// radio `radio` en uv (de altura), pesos gaussianos por distancia.
fn img_bloom_ancho(t: texture_2d<f32>, s: sampler, uv: vec2<f32>, radio: f32, aspecto: f32) -> vec3<f32> {
    var suma = vec3<f32>(0.0);
    var pesos = 0.0;
    for (var i = 0; i < 32; i++) {
        let r = sqrt((f32(i) + 0.5) / 32.0);
        let a = f32(i) * 2.39996323;
        let o = vec2<f32>(cos(a) / aspecto, sin(a)) * r * radio;
        let w = exp(-r * r * 2.5);
        suma += textureSampleLevel(t, s, uv + o, 0.0).rgb * w;
        pesos += w;
    }
    return suma / pesos;
}
