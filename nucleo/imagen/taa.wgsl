// Acumulación temporal: espacio comprimido, YCoCg, recorte por varianza, Catmull-Rom y FXAA.
// Las texturas llegan por parámetro. Porqué: docs/efectos/taa.md

// Compresión reversible para mezclar (Karis 2014): los píxeles muy brillantes no dominan la media.
fn img_comprimir(c: vec3<f32>) -> vec3<f32> {
    return c / (1.0 + col_luminancia(c));
}

fn img_descomprimir(c: vec3<f32>) -> vec3<f32> {
    return c / max(1.0 - col_luminancia(c), 1e-4);
}

fn img_a_ycocg(c: vec3<f32>) -> vec3<f32> {
    return vec3<f32>(0.25 * c.r + 0.5 * c.g + 0.25 * c.b, 0.5 * c.r - 0.5 * c.b, -0.25 * c.r + 0.5 * c.g - 0.25 * c.b);
}

fn img_desde_ycocg(c: vec3<f32>) -> vec3<f32> {
    return vec3<f32>(c.x + c.y - c.z, c.x + c.z, c.x - c.y - c.z);
}

// Recorte del historial hacia el centro de la caja (Salvi 2016): conserva el tono, a diferencia de pinzar
// cada canal.
fn img_recortar(historial: vec3<f32>, centro: vec3<f32>, extension: vec3<f32>) -> vec3<f32> {
    let d = historial - centro;
    let unidades = abs(d) / max(extension, vec3<f32>(1e-5));
    let m = max(unidades.x, max(unidades.y, unidades.z));
    return select(historial, centro + d / m, m > 1.0);
}

// Historial con Catmull-Rom en 5 lecturas bilineales (Jimenez 2016, «Filmic SMAA», la versión de 9 en 5).
// `nitidez` 0..1 pasa del bilineal (0) al Catmull-Rom (1).
fn img_catmull_rom(t: texture_2d<f32>, s: sampler, uv: vec2<f32>, nitidez: f32) -> vec3<f32> {
    let lado = vec2<f32>(textureDimensions(t));
    let pos = uv * lado;
    let centro = floor(pos - 0.5) + 0.5;
    let f = pos - centro;
    let f2 = f * f;
    let f3 = f2 * f;
    let w0 = -0.5 * f3 + f2 - 0.5 * f;
    let w1 = 1.5 * f3 - 2.5 * f2 + 1.0;
    let w2 = -1.5 * f3 + 2.0 * f2 + 0.5 * f;
    let w3 = 0.5 * f3 - 0.5 * f2;
    let w12 = w1 + w2;
    let tc0 = (centro - 1.0) / lado;
    let tc3 = (centro + 2.0) / lado;
    let tc12 = (centro + w2 / w12) / lado;
    var c = textureSampleLevel(t, s, vec2<f32>(tc12.x, tc0.y), 0.0).rgb * (w12.x * w0.y);
    c += textureSampleLevel(t, s, vec2<f32>(tc0.x, tc12.y), 0.0).rgb * (w0.x * w12.y);
    c += textureSampleLevel(t, s, tc12, 0.0).rgb * (w12.x * w12.y);
    c += textureSampleLevel(t, s, vec2<f32>(tc3.x, tc12.y), 0.0).rgb * (w3.x * w12.y);
    c += textureSampleLevel(t, s, vec2<f32>(tc12.x, tc3.y), 0.0).rgb * (w12.x * w3.y);
    let peso = w12.x * w0.y + w0.x * w12.y + w12.x * w12.y + w3.x * w12.y + w12.x * w3.y;
    let cr = max(c / peso, vec3<f32>(0.0));
    let bilineal = textureSampleLevel(t, s, uv, 0.0).rgb;
    return mix(bilineal, cr, nitidez);
}

// Antialiasing de bordes por luminancia, a la manera de FXAA (Lottes 2009, versión de consola): donde hay
// contraste, dos lecturas a lo largo del borde (perpendicular al gradiente de luminancia).
fn img_fxaa(t: texture_2d<f32>, s: sampler, uv: vec2<f32>, actual: vec3<f32>) -> vec3<f32> {
    let px = 1.0 / vec2<f32>(textureDimensions(t));
    let ln = col_luminancia(img_comprimir(textureSampleLevel(t, s, uv + vec2<f32>(0.0, -px.y), 0.0).rgb));
    let ls = col_luminancia(img_comprimir(textureSampleLevel(t, s, uv + vec2<f32>(0.0, px.y), 0.0).rgb));
    let le = col_luminancia(img_comprimir(textureSampleLevel(t, s, uv + vec2<f32>(px.x, 0.0), 0.0).rgb));
    let lo = col_luminancia(img_comprimir(textureSampleLevel(t, s, uv + vec2<f32>(-px.x, 0.0), 0.0).rgb));
    let lm = col_luminancia(img_comprimir(actual));
    let rango = max(max(max(ln, ls), max(le, lo)), lm) - min(min(min(ln, ls), min(le, lo)), lm);
    if rango < max(0.05, 0.15 * max(max(max(ln, ls), max(le, lo)), lm)) {
        return actual;
    }
    // Gradiente de luminancia: el borde va perpendicular a él.
    let g = vec2<f32>(le - lo, ls - ln);
    let borde = normalize(vec2<f32>(-g.y, g.x) + vec2<f32>(1e-6, 0.0));
    let a = textureSampleLevel(t, s, uv + borde * px * 0.5, 0.0).rgb;
    let b = textureSampleLevel(t, s, uv - borde * px * 0.5, 0.0).rgb;
    return mix(actual, 0.5 * (a + b), 0.5);
}
