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

// Pertenencia de un matiz y una saturación (sup_matiz_sat) al rango.
fn img_pertenece_hs(hs: vec2<f32>, a: ImgAislamiento) -> f32 {
    var d = abs(hs.x - a.matiz / 360.0);
    d = min(d, 1.0 - d) * 360.0;
    let m = 1.0 - smoothstep(a.rango, a.rango + max(a.suavidad, 0.001), d);
    return m * smoothstep(a.sat_minima * 0.5, a.sat_minima + 0.02, hs.y);
}

fn img_pertenece(c: vec3<f32>, a: ImgAislamiento) -> f32 {
    return img_pertenece_hs(sup_matiz_sat(c), a);
}

// Una muestra de la imagen HDR en el espacio del color final (aproximado: exposición, c/(1 + c) y sRGB).
fn img_aislamiento_muestra(t: texture_2d<f32>, s: sampler, uv: vec2<f32>, a: ImgAislamiento) -> vec3<f32> {
    let c = textureSampleLevel(t, s, uv, 0.0).rgb * a.exposicion;
    return col_lineal_a_srgb(c / (1.0 + c));
}

// El entorno circular de la prueba de tamaño: 16 muestras de Vogel en un radio de `tamano` píxeles a 1080p.
const IMG_AISLAMIENTO_MUESTRAS: i32 = 16;

fn img_aislamiento_paso(resolucion: vec2<f32>, tamano: f32) -> vec2<f32> {
    let texel = 1.0 / resolucion;
    let escala = clamp(1.0 / max(texel.y * 1080.0, 0.25), 0.5, 4.0);
    return tamano * escala * texel;
}

fn img_vogel(i: i32, paso: vec2<f32>) -> vec2<f32> {
    let r = sqrt((f32(i) + 0.5) / f32(IMG_AISLAMIENTO_MUESTRAS));
    let ang = f32(i) * 2.39996;
    return vec2<f32>(cos(ang), sin(ang)) * r * paso;
}

// Salida a mitad de la prueba de tamaño: tras 8 muestras, -1 si sigue, si no la densidad ya decidida (0 o 1).
fn img_densidad_decidida(acc: f32, umbral: f32) -> f32 {
    if acc + 8.0 <= (umbral - 0.18) * 16.0 {
        return 0.0;
    }
    if acc >= (umbral + 0.18) * 16.0 {
        return 1.0;
    }
    return -1.0;
}

// Pertenencia del píxel corregida por la densidad de su entorno (apertura y cierre suaves).
fn img_mancha(m: f32, dens: f32, umbral: f32) -> f32 {
    let f_mancha = smoothstep(umbral - 0.18, umbral + 0.18, dens);
    // Cierre suave: rellena agujeros grises dentro de una mancha densa.
    return mix(m * f_mancha, max(m, f_mancha * 0.85), smoothstep(umbral + 0.10, umbral + 0.35, dens));
}

// `color`: el color final en sRGB 0..1; `m`: su pertenencia ya corregida.
fn img_aislar_mezcla(color: vec3<f32>, m: f32, a: ImgAislamiento) -> vec3<f32> {
    let luma = col_luminancia(color);
    let fuera = mix(color, vec3<f32>(luma), a.desaturacion);
    let dentro = mix(vec3<f32>(luma), color, 1.0 + a.realce);
    return mix(fuera, max(dentro, vec3<f32>(0.0)), m);
}
