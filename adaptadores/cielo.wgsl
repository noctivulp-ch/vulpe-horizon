// SkyInput -> rayo del núcleo, y la salida codificada. Porqué: docs/efectos/nucleo.md §Adaptadores

struct AdpRayoCielo {
    direccion: vec3<f32>,   // unitaria, ejes del mundo relativos a la cámara
    color_vanilla: vec3<f32>,
}

fn adp_cielo_rayo(input: SkyInput) -> AdpRayoCielo {
    return AdpRayoCielo(normalize(input.direction), input.color.rgb);
}

// Luz lineal de la escena -> valor del «picture» (ADR 0004), con tramado de ±½ nivel.
fn adp_cielo_salida(luz: vec3<f32>, dir: vec3<f32>) -> vec4<f32> {
    let v = col_codificar_escena(luz, adp_codificacion());
    let tramado = (rui_tramado_direccion(dir) - 0.5) / 255.0;
    return vec4<f32>(v + tramado, 1.0);
}
