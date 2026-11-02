// Exposición automática: curva compresiva y adaptación temporal. Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Exposición

struct ImgCurvaExposicion {
    k: f32,
    c: f32,
}

// exposición = k / ln(L + 1 + c): en lo oscuro sube mucho menos que 1/L (la noche sigue siendo noche) y tiende a
// k / ln(1 + c) cuando L → 0.
fn img_exposicion_objetivo(l: f32, curva: ImgCurvaExposicion) -> f32 {
    return curva.k / log(max(l, 0.0) + 1.0 + curva.c);
}

// Mezcla exponencial hacia el valor nuevo con constante de tiempo distinta al subir y al bajar.
fn img_adaptar(anterior: f32, nueva: f32, dt: f32, tau_sube: f32, tau_baja: f32) -> f32 {
    if anterior <= 0.0 || dt <= 0.0 {
        return nueva;
    }
    let tau = select(tau_baja, tau_sube, nueva > anterior);
    return mix(anterior, nueva, 1.0 - exp(-dt / tau));
}

// Media logarítmica (geométrica) de la luminancia en una rejilla de 8×8 con más peso en el centro (Reinhard
// et al. 2002, la «clave» de la escena). La imagen llega por parámetro.
fn img_luminancia_media(t: texture_2d<f32>, s: sampler) -> f32 {
    var suma = 0.0;
    var pesos = 0.0;
    for (var i = 0; i < 64; i++) {
        let uv = (vec2<f32>(f32(i % 8), f32(i / 8)) + 0.5) / 8.0;
        let c = textureSampleLevel(t, s, uv, 0.0).rgb;
        let d = length(uv - 0.5);
        let w = 1.0 - 0.7 * smoothstep(0.1, 0.7, d);
        suma += log(col_luminancia(max(c, vec3<f32>(0.0))) + 1e-6) * w;
        pesos += w;
    }
    return exp(suma / pesos);
}
