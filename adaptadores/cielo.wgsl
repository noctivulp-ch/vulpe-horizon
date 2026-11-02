// SkyInput -> rayo y color de partida del núcleo. Porqué: docs/efectos/nucleo.md §Adaptadores

struct AdpRayoCielo {
    direccion: vec3<f32>,   // unitaria, ejes del mundo relativos a la cámara
    color_vanilla: vec3<f32>,
}

fn adp_cielo_rayo(input: SkyInput) -> AdpRayoCielo {
    return AdpRayoCielo(input.direction, input.color.rgb);
}

fn adp_cielo_salida(color: vec3<f32>) -> vec4<f32> {
    return vec4<f32>(color, 1.0);
}
