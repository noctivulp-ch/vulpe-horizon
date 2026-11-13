// Empaquetado del dato propio de set_surface: F0, la fracción indirecta y la luz de cielo de Minecraft, 8 bits
// cada uno en un f32 (el destino es de 32 bits por canal: entero exacto hasta 2^24).
// Porqué: docs/efectos/luz-de-superficie.md §Datos para post

fn sup_empaquetar_dato(f0: f32, indirecta: f32, luz_cielo: f32) -> f32 {
    let a = round(clamp(f0, 0.0, 1.0) * 255.0);
    let b = round(clamp(indirecta, 0.0, 1.0) * 255.0);
    let c = round(clamp(luz_cielo, 0.0, 1.0) * 255.0);
    return (a * 256.0 + b) * 256.0 + c;
}

// x = F0, y = fracción indirecta, z = luz de cielo.
fn sup_desempaquetar_dato(d: f32) -> vec3<f32> {
    let a = floor(d / 65536.0);
    let resto = d - a * 65536.0;
    let b = floor(resto / 256.0);
    return vec3<f32>(a, b, resto - b * 256.0) / 255.0;
}

// Matiz 0..1 y saturación 0..1 de un color, sin pasar a HSV completo (lo usan la suavidad empaquetada y el
// aislamiento de color, 13).
fn sup_matiz_sat(c: vec3<f32>) -> vec2<f32> {
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

// La suavidad de set_surface lleva además el matiz y la saturación del color del bloque antes de la luz (sRGB), para
// que el aislamiento de color (13) compare el color de la superficie y no el de la luz que le llega: tres bytes en un
// entero exacto (< 2²⁴). Porqué: docs/efectos/aislamiento-de-color.md §«Color de la superficie (F-39)»
fn sup_empaquetar_suavidad(suavidad: f32, albedo_srgb: vec3<f32>) -> f32 {
    let hs = sup_matiz_sat(albedo_srgb);
    let a = round(clamp(suavidad, 0.0, 1.0) * 255.0);
    let b = round(clamp(hs.x, 0.0, 1.0) * 255.0);
    let c = round(clamp(hs.y, 0.0, 1.0) * 255.0);
    return (a * 256.0 + b) * 256.0 + c;
}

// x = suavidad, y = matiz, z = saturación. El signo negativo marca un píxel de mineral de una mena (25, F-47b).
fn sup_desempaquetar_suavidad(v: f32) -> vec3<f32> {
    return sup_desempaquetar_dato(abs(v));
}

fn sup_es_mena(v: f32) -> bool {
    return v < 0.0;
}
