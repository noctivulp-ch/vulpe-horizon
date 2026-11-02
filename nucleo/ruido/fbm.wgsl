// Movimiento browniano fraccionario sobre ruido de valor. Porqué: docs/efectos/nucleo.md §Ruido

struct RuiParametrosFbm {
    octavas: i32,
    lacunaridad: f32,   // multiplicador de frecuencia por octava
    ganancia: f32,      // multiplicador de amplitud por octava
}

fn rui_fbm_estandar(octavas: i32) -> RuiParametrosFbm {
    return RuiParametrosFbm(octavas, 2.0, 0.5);
}

// Resultado normalizado a [0, 1].
fn rui_fbm2(p: vec2<f32>, ajustes: RuiParametrosFbm) -> f32 {
    var suma = 0.0;
    var total = 0.0;
    var amplitud = 1.0;
    var q = p;
    for (var o = 0; o < ajustes.octavas; o++) {
        suma += rui_valor2(q) * amplitud;
        total += amplitud;
        amplitud *= ajustes.ganancia;
        // Giro de unos 37° entre octavas para que las rejillas no se alineen.
        q = mat2x2<f32>(0.8, 0.6, -0.6, 0.8) * q * ajustes.lacunaridad + vec2<f32>(17.3, 9.1);
    }
    return suma / max(total, MAT_EPSILON);
}

// Resultado normalizado a [0, 1].
fn rui_fbm3(p: vec3<f32>, ajustes: RuiParametrosFbm) -> f32 {
    var suma = 0.0;
    var total = 0.0;
    var amplitud = 1.0;
    var q = p;
    for (var o = 0; o < ajustes.octavas; o++) {
        suma += rui_valor3(q) * amplitud;
        total += amplitud;
        amplitud *= ajustes.ganancia;
        q = q * ajustes.lacunaridad + vec3<f32>(17.3, 9.1, 4.7);
    }
    return suma / max(total, MAT_EPSILON);
}
