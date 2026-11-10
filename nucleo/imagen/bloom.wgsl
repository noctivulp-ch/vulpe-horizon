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

// Desenfoque ancho: anillos concéntricos de lecturas bilineales con pesos gaussianos, con `anillos` anillos y tantas
// muestras por anillo que la separación entre lecturas no pasa de ~2 téxeles (con 32 lecturas en un disco de Vogel una
// fuente pequeña y brillante salía repetida en copias: los «palitos» que vio el dueño). `giro` (0..1, por píxel) gira
// cada anillo para que el patrón no se alinee entre píxeles. Radio en uv del alto. Desenfoca los cuatro canales.
fn img_bloom_ancho(t: texture_2d<f32>, s: sampler, uv: vec2<f32>, radio: f32, aspecto: f32, anillos: i32, giro: f32) -> vec4<f32> {
    let lado = vec2<f32>(textureDimensions(t));
    let radio_tx = radio * lado.y;
    var suma = textureSampleLevel(t, s, uv, 0.0);
    var pesos = 1.0;
    for (var k = 1; k <= anillos; k++) {
        let r = f32(k) / f32(anillos);
        let n = max(i32(ceil(MAT_TAU * r * radio_tx / 2.0)), 6);
        // Gaussiana que llega a 0 en el borde: cortada en r = 1 dejaba un disco de borde recortado alrededor de las fuentes.
        let w = exp(-r * r * 2.5) * (1.0 - r * r) * (1.0 - r * r);
        let desfase = (giro + f32(k) * 0.618034) * MAT_TAU / f32(n);
        var anillo = vec4<f32>(0.0);
        for (var j = 0; j < n; j++) {
            let a = f32(j) * MAT_TAU / f32(n) + desfase;
            anillo += textureSampleLevel(t, s, uv + vec2<f32>(cos(a) / aspecto, sin(a)) * r * radio, 0.0);
        }
        // Peso del anillo proporcional a su área (su número de muestras) por la gaussiana.
        suma += anillo * w;
        pesos += f32(n) * w;
    }
    return suma / pesos;
}

// Opacidad de la niebla en las fuentes de luz de alrededor: media de `1 − a` de `niebla` pesada por la luminancia de
// `luz`, en los mismos anillos que el desenfoque ancho. Es la niebla que dispersa la luz de esas fuentes.
fn img_opacidad_fuentes(luz: texture_2d<f32>, niebla: texture_2d<f32>, s: sampler, uv: vec2<f32>, radio: f32, aspecto: f32, anillos: i32, giro: f32) -> f32 {
    var suma = 0.0;
    var pesos = 1e-6;
    for (var k = 0; k <= anillos; k++) {
        let r = f32(k) / f32(anillos);
        let n = select(max(i32(ceil(MAT_TAU * r * f32(anillos))), 6), 1, k == 0);
        let w = exp(-r * r * 2.5) * (1.0 - r * r) * (1.0 - r * r);
        let desfase = (giro + f32(k) * 0.618034) * MAT_TAU / f32(n);
        for (var j = 0; j < n; j++) {
            let a = f32(j) * MAT_TAU / f32(n) + desfase;
            let p = uv + vec2<f32>(cos(a) / aspecto, sin(a)) * r * radio;
            let l = col_luminancia(textureSampleLevel(luz, s, p, 0.0).rgb) * w;
            suma += (1.0 - textureSampleLevel(niebla, s, p, 0.0).a) * l;
            pesos += l;
        }
    }
    return suma / pesos;
}

// Respuesta del bloom del original a un punto de energía 1, por unidad de área en unidades del alto de pantalla, a la
// distancia `d` (alto = 1): cuatro gaussianas ajustadas a la energía encerrada de paridad/10 (46 % en 0,0037; 70 % en
// 0,0074; 84 % en 0,0148; 93 % en 0,0296; 97,6 % en 0,0593). Sin el factor de energía total ni el peso de mezcla.
// Porqué: docs/efectos/bloom.md §Destello del sol
fn img_bloom_respuesta(d: f32) -> f32 {
    let sigma = vec4<f32>(0.0022, 0.006, 0.015, 0.04);
    let peso = vec4<f32>(0.55, 0.25, 0.12, 0.08);
    let s2 = sigma * sigma;
    let g = peso / (MAT_TAU * s2) * exp(-vec4<f32>(d * d) / (2.0 * s2));
    return g.x + g.y + g.z + g.w;
}

// Destello de una fuente compacta cuya energía no cabe en la imagen: `exceso` (radiancia por encima del techo de la
// codificación) × `area` (alto² de pantalla) × respuesta del bloom a la distancia `d`, por `energia_total` (paridad/10).
fn img_destello(exceso: vec3<f32>, area: f32, d: f32, energia_total: f32) -> vec3<f32> {
    return exceso * (area * energia_total * img_bloom_respuesta(d));
}
