// Luz del relámpago (20): una columna vertical desde donde cae, con caída larga y orientación hacia su base y su parte
// alta. Posiciones en el mismo marco (relativas a la cámara). Porqué: docs/efectos/relampago.md

struct LuzRelampago {
    base: vec3<f32>,    // donde cae, relativo a la cámara
    brillo: f32,        // destello del momento (0 = sin rayo)
}

const LUZ_RELAMPAGO_ALTO: f32 = 150.0;   // bloques de columna sobre el punto de caída
const LUZ_RELAMPAGO_CERCA: f32 = 30.0;   // bloques: fuerte hasta aquí
const LUZ_RELAMPAGO_LEJOS: f32 = 500.0;  // bloques: nula aquí

// Destello: sube en medio segundo, parpadea cada tick (1/20 s) y se corta al acabar el rayo.
fn luz_relampago_destello(edad: f32, duracion: f32) -> f32 {
    if edad < 0.0 || edad > duracion {
        return 0.0;
    }
    let tick = i32(floor(edad * 20.0));
    let parpadeo = 0.35 + 0.65 * rui_hash21(vec2<i32>(tick, 17));
    return smoothstep(0.0, 0.5, edad) * parpadeo;
}

// Distancia de un punto a la columna del rayo.
fn luz_relampago_distancia(punto: vec3<f32>, base: vec3<f32>) -> f32 {
    let cerca = vec3<f32>(base.x, clamp(punto.y, base.y, base.y + LUZ_RELAMPAGO_ALTO), base.z);
    return distance(punto, cerca);
}

// Caída suave y larga: ~1 de cerca, la mitad a 30 bloques, cero a 500.
fn luz_relampago_caida(d: f32) -> f32 {
    let x = d / LUZ_RELAMPAGO_CERCA;
    let fin = 1.0 - clamp(d / LUZ_RELAMPAGO_LEJOS, 0.0, 1.0);
    return fin * fin / (1.0 + x * x);
}

// Sobre una superficie: caída por la orientación media hacia la base y hacia lo alto de la columna.
fn luz_relampago_superficie(r: LuzRelampago, punto: vec3<f32>, n: vec3<f32>) -> f32 {
    if r.brillo <= 0.0 {
        return 0.0;
    }
    let alto = r.base + vec3<f32>(0.0, LUZ_RELAMPAGO_ALTO, 0.0);
    let o = 0.5 * (max(dot(n, normalize(r.base - punto)), 0.0) + max(dot(n, normalize(alto - punto)), 0.0));
    return r.brillo * o * luz_relampago_caida(luz_relampago_distancia(punto, r.base));
}
