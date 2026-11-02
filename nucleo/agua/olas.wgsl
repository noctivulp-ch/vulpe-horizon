// Olas del agua: altura por octavas anisótropas con oleaje en parches, normal por diferencias finitas y
// cáusticas (material del agua y terreno bajo el agua; el struct AguOlas está en optica.wgsl). La textura de ruido llega por parámetro.
// Porqué: docs/efectos/agua.md §Olas

// Rota 137,5° (ángulo irracional) entre octavas para que no se alineen.
fn agu_rotar(p: vec2<f32>, k: f32) -> vec2<f32> {
    let a = 2.3999632 * k;
    return vec2<f32>(cos(a) * p.x - sin(a) * p.y, sin(a) * p.x + cos(a) * p.y);
}

// Oleaje en parches: ruido de muy baja frecuencia curvado en S (zonas movidas y zonas en calma).
fn agu_parches(xz: vec2<f32>, t: texture_2d<f32>, s: sampler) -> f32 {
    let n = textureSampleLevel(t, s, xz / 1800.0, 0.0).r;
    return smoothstep(0.3, 0.7, n) * 0.85 + 0.15;
}

// Altura (bloques) en el punto horizontal `xz` del mundo; `octavas` 2 o 3.
fn agu_altura(xz: vec2<f32>, o: AguOlas, octavas: i32, t: texture_2d<f32>, s: sampler) -> f32 {
    // Escalas anisótropas (bloques por periodo de la textura, que trae 16 celdas en G): alargada en x,
    // alargada en z, isótropa.
    let escalas = array<vec2<f32>, 3>(vec2<f32>(220.0, 90.0), vec2<f32>(70.0, 160.0), vec2<f32>(60.0, 60.0));
    let viento = array<vec2<f32>, 3>(vec2<f32>(1.1, 0.4), vec2<f32>(-0.5, 0.9), vec2<f32>(0.7, -0.6));
    let amplitud = array<f32, 3>(0.10, 0.06, 0.03);
    var h = 0.0;
    for (var k = 0; k < octavas; k++) {
        let q = agu_rotar(xz, f32(k)) / escalas[k] + viento[k] * o.tiempo * 0.01;
        h += (textureSampleLevel(t, s, q, 0.0).g - 0.5) * amplitud[k];
    }
    return h * o.fuerza * agu_parches(xz, t, s);
}

// Normal de las olas por diferencias finitas, con un paso que crece con la distancia (menos detalle que
// píxeles: no centellea) y dos octavas lejos.
fn agu_normal(xz: vec2<f32>, distancia: f32, o: AguOlas, t: texture_2d<f32>, s: sampler) -> vec3<f32> {
    let paso = clamp(distancia * 0.004, 0.05, 2.0);
    let octavas = select(3, 2, distancia > 48.0);
    let h0 = agu_altura(xz, o, octavas, t, s);
    let hx = agu_altura(xz + vec2<f32>(paso, 0.0), o, octavas, t, s);
    let hz = agu_altura(xz + vec2<f32>(0.0, paso), o, octavas, t, s);
    return normalize(vec3<f32>(h0 - hx, paso, h0 - hz));
}

// Cáusticas: las mismas octavas con el valor absoluto plegado (líneas finas) y una exponencial que concentra
// el brillo en las crestas. Media ≈ 1.
fn agu_causticas(xz: vec2<f32>, o: AguOlas, t: texture_2d<f32>, s: sampler) -> f32 {
    var c = 0.0;
    for (var k = 0; k < 2; k++) {
        let q = agu_rotar(xz, f32(k)) / (18.0 + 10.0 * f32(k)) + vec2<f32>(0.8, -0.5) * o.tiempo * 0.02 * (1.0 + f32(k));
        let n = textureSampleLevel(t, s, q, 0.0).g;
        let linea = abs(abs(2.0 * n - 1.0) * 2.0 - 1.0);
        c += exp(-linea * 6.0);
    }
    return mix(1.0, c * 1.6, agu_parches(xz, t, s));
}
