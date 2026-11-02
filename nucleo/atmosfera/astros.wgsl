// Color y disco de los astros. Porqué: docs/efectos/cielo-y-atmosfera.md §Astros

// Color de un cuerpo negro en sRGB lineal, normalizado a luminancia 1. Ajuste de Tanner Helland
// («How to Convert Temperature (K) to RGB», 2012), válido de 1000 a 40000 K; sus curvas dan valores
// codificados, que se pasan a lineal.
fn atm_cuerpo_negro(kelvin: f32) -> vec3<f32> {
    let t = clamp(kelvin, 1000.0, 40000.0) / 100.0;
    var c: vec3<f32>;
    if t <= 66.0 {
        c.r = 255.0;
        c.g = 99.4708025861 * log(t) - 161.1195681661;
        c.b = select(138.5177312231 * log(t - 10.0) - 305.0447927307, 0.0, t <= 19.0);
    } else {
        c.r = 329.698727446 * pow(t - 60.0, -0.1332047592);
        c.g = 288.1221695283 * pow(t - 60.0, -0.0755148492);
        c.b = 255.0;
    }
    let lineal = col_srgb_a_lineal(clamp(c / 255.0, vec3<f32>(0.0), vec3<f32>(1.0)));
    return lineal / max(col_luminancia(lineal), MAT_EPSILON);
}

// 1 dentro del disco de radio angular `radio` (rad), con borde suave de `borde` (fracción del radio).
fn atm_disco(cos_vista_astro: f32, radio: f32, borde: f32) -> f32 {
    let dentro = cos(radio * (1.0 - borde));
    let fuera = cos(radio * (1.0 + borde));
    return smoothstep(fuera, dentro, cos_vista_astro);
}
