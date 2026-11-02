// Ajustes de gradación sobre color lineal. Porqué: docs/efectos/nucleo.md §Color

struct ColParametrosGradacion {
    exposicion: f32,    // en pasos (EV)
    saturacion: f32,    // 1 neutro
    contraste: f32,     // 1 neutro, pivote en el gris medio
}

fn col_gradacion_neutra() -> ColParametrosGradacion {
    return ColParametrosGradacion(0.0, 1.0, 1.0);
}

fn col_gradar(c_entrada: vec3<f32>, g: ColParametrosGradacion) -> vec3<f32> {
    var c = c_entrada * exp2(g.exposicion);
    let l = col_luminancia(c);
    c = mix(vec3<f32>(l), c, g.saturacion);
    // Contraste en log2 alrededor del gris medio (0,18).
    let gris = 0.18;
    c = gris * pow(max(c, vec3<f32>(0.0)) / gris, vec3<f32>(g.contraste));
    return max(c, vec3<f32>(0.0));
}

// Saturación respecto a la luminancia, sin dejar canales negativos.
fn col_saturar(c: vec3<f32>, saturacion: f32) -> vec3<f32> {
    let l = col_luminancia(c);
    return max(mix(vec3<f32>(l), c, saturacion), vec3<f32>(0.0));
}

// Balance de blancos: divide por el color de un cuerpo negro a la temperatura elegida, relativo al de
// referencia (6500 K neutro). Los colores llegan normalizados a luminancia 1.
fn col_balance_blancos(c: vec3<f32>, referencia: vec3<f32>, elegido: vec3<f32>) -> vec3<f32> {
    return c * referencia / max(elegido, vec3<f32>(1e-4));
}
