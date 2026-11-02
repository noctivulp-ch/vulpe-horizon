// SkyInput -> rayo del núcleo, y la salida codificada. Porqué: docs/efectos/nucleo.md §Adaptadores

struct AdpRayoCielo {
    direccion: vec3<f32>,   // unitaria, ejes del mundo relativos a la cámara
    color_vanilla: vec3<f32>,
}

fn adp_cielo_rayo(input: SkyInput) -> AdpRayoCielo {
    return AdpRayoCielo(normalize(input.direction), input.color.rgb);
}

// Seno del ángulo bajo el horizonte al que se ve el final de la distancia de renderizado (0 a ras del mar).
fn adp_cielo_borde_del_mundo() -> f32 {
    let alto = max(frame.camera_position.y - VOL_MAR, 0.0);
    return alto / sqrt(alto * alto + frame.render_distance * frame.render_distance + 1.0);
}

// Luz lineal de la escena -> valor del «picture» (ADR 0004), con tramado de ±½ nivel.
fn adp_cielo_salida(luz: vec3<f32>, dir: vec3<f32>) -> vec4<f32> {
    let v = col_codificar_escena(luz, adp_codificacion());
    let tramado = (rui_tramado_direccion(dir) - 0.5) / 255.0;
    return vec4<f32>(v + tramado, 1.0);
}

// Ajustes completos del cielo fractal (solo la etapa sky dibuja el fractal; el sorteo es compartido).
fn adp_fractal_ajustes(o: OpcFractal, cielo_medio: vec3<f32>) -> CieFractalAjustes {
    return CieFractalAjustes(
        adp_fractal_sorteo(o),
        CiePaleta(o.paleta, o.contraste, o.saturacion, cielo_medio),
        o.dibujo, OPC_FRACTAL_ITERACIONES, o.mutacion, o.brillo, o.techo, o.hueco,
    );
}
