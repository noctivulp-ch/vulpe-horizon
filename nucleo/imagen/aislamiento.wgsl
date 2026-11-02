// Aislamiento de color: calificador de matiz y saturación más una prueba de tamaño de mancha (apertura
// morfológica aproximada) en una pasada. PROPIO de Vulpe (especificación 13). La imagen llega por parámetro.
// Porqué: docs/efectos/aislamiento-de-color.md

struct ImgAislamiento {
    matiz: f32,         // grados
    rango: f32,         // grados
    suavidad: f32,      // grados
    sat_minima: f32,    // 0..1
    tamano: f32,        // píxeles a 1080p (0: sin prueba de tamaño)
    exigencia: f32,     // 0..1
    desaturacion: f32,  // 0..1
    realce: f32,        // 0..1
    exposicion: f32,    // para llevar las muestras HDR al mismo espacio que el color
}

// Matiz 0..1 y saturación 0..1 sin pasar a HSV completo.
fn img_matiz_sat(c: vec3<f32>) -> vec2<f32> {
    let mx = max(c.r, max(c.g, c.b));
    let mn = min(c.r, min(c.g, c.b));
    let d = mx - mn;
    if d < 1e-5 || mx < 1e-5 {
        return vec2<f32>(0.0);
    }
    var h: f32;
    if mx == c.r {
        h = (c.g - c.b) / d;
        h = h - 6.0 * floor(h / 6.0);
    } else if mx == c.g {
        h = (c.b - c.r) / d + 2.0;
    } else {
        h = (c.r - c.g) / d + 4.0;
    }
    return vec2<f32>(h / 6.0, d / mx);
}

fn img_pertenece(c: vec3<f32>, a: ImgAislamiento) -> f32 {
    let hs = img_matiz_sat(c);
    var d = abs(hs.x - a.matiz / 360.0);
    d = min(d, 1.0 - d) * 360.0;
    let m = 1.0 - smoothstep(a.rango, a.rango + max(a.suavidad, 0.001), d);
    return m * smoothstep(a.sat_minima * 0.5, a.sat_minima + 0.02, hs.y);
}

// Una muestra de la imagen HDR en el espacio del color final (aproximado: exposición, c/(1 + c) y sRGB).
fn img_aislamiento_muestra(t: texture_2d<f32>, s: sampler, uv: vec2<f32>, a: ImgAislamiento) -> vec3<f32> {
    let c = textureSampleLevel(t, s, uv, 0.0).rgb * a.exposicion;
    return col_lineal_a_srgb(c / (1.0 + c));
}

// Fracción del entorno circular (16 muestras de Vogel) que también pertenece al color, con salida a mitad.
fn img_densidad(t: texture_2d<f32>, s: sampler, uv: vec2<f32>, umbral: f32, a: ImgAislamiento) -> f32 {
    let texel = 1.0 / vec2<f32>(textureDimensions(t));
    let escala = clamp(1.0 / max(texel.y * 1080.0, 0.25), 0.5, 4.0);
    let paso = a.tamano * escala * texel;
    var acc = 0.0;
    for (var i = 0; i < 16; i++) {
        let r = sqrt((f32(i) + 0.5) / 16.0);
        let ang = f32(i) * 2.39996;
        acc += img_pertenece(img_aislamiento_muestra(t, s, uv + vec2<f32>(cos(ang), sin(ang)) * r * paso, a), a);
        if i == 7 {
            if acc + 8.0 <= (umbral - 0.18) * 16.0 {
                return 0.0;
            }
            if acc >= (umbral + 0.18) * 16.0 {
                return 1.0;
            }
        }
    }
    return acc / 16.0;
}

// `color`: el color final en sRGB 0..1.
fn img_aislar(color: vec3<f32>, uv: vec2<f32>, t: texture_2d<f32>, s: sampler, a: ImgAislamiento) -> vec3<f32> {
    var m = img_pertenece(color, a);
    if a.tamano > 0.0 && m > 0.001 {
        let umbral = a.exigencia;
        let dens = img_densidad(t, s, uv, umbral, a);
        let f_mancha = smoothstep(umbral - 0.18, umbral + 0.18, dens);
        // Cierre suave: rellena agujeros grises dentro de una mancha densa.
        m = mix(m * f_mancha, max(m, f_mancha * 0.85), smoothstep(umbral + 0.10, umbral + 0.35, dens));
    }
    let luma = col_luminancia(color);
    let fuera = mix(color, vec3<f32>(luma), a.desaturacion);
    let dentro = mix(vec3<f32>(luma), color, 1.0 + a.realce);
    return mix(fuera, max(dentro, vec3<f32>(0.0)), m);
}
