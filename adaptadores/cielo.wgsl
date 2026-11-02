// SkyInput -> rayo del núcleo, y la salida codificada. Porqué: docs/efectos/nucleo.md §Adaptadores

struct AdpRayoCielo {
    direccion: vec3<f32>,   // unitaria, ejes del mundo relativos a la cámara
    color_vanilla: vec3<f32>,
}

fn adp_cielo_rayo(input: SkyInput) -> AdpRayoCielo {
    return AdpRayoCielo(normalize(input.direction), input.color.rgb);
}

// Jitter propio del cielo (02 §5 bis): Horizon no desplaza la cámara entre fotogramas, así que el fractal
// desplaza su dirección una fracción de píxel con R2; el TAA (09) promedia y los filamentos no centellean.
fn adp_cielo_jitter(dir: vec3<f32>) -> vec3<f32> {
    let o = rui_r2(frame.frame_index) - 0.5;
    let pixel = 2.0 / (frame.projection[1][1] * frame.resolution.y);
    let eje_x = frame.view_inverse[0].xyz;
    let eje_y = frame.view_inverse[1].xyz;
    return normalize(dir + (o.x * eje_x + o.y * eje_y) * pixel);
}

// Luz lineal de la escena -> valor del «picture» (ADR 0004), con tramado de ±½ nivel.
fn adp_cielo_salida(luz: vec3<f32>, dir: vec3<f32>) -> vec4<f32> {
    let v = col_codificar_escena(luz, adp_codificacion());
    let tramado = (rui_tramado_direccion(dir) - 0.5) / 255.0;
    return vec4<f32>(v + tramado, 1.0);
}

