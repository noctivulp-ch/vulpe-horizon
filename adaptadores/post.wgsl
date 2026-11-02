// PostInput y recursos de la etapa post -> píxel del núcleo. Porqué: docs/efectos/nucleo.md §Adaptadores

struct AdpPixel {
    uv: vec2<f32>,
    pixel: vec2<f32>,
    color: vec3<f32>,       // codificado como lo entrega Horizon (sRGB)
    alfa: f32,
    profundidad: f32,       // invertida: 0 cielo, 1 cerca
    es_cielo: bool,
}

fn adp_post_pixel(input: PostInput) -> AdpPixel {
    return AdpPixel(input.uv, input.pixel, input.color.rgb, input.color.a, input.depth, input.depth <= 0.0);
}

// Distancia a la cámara en bloques; muy grande en el cielo.
fn adp_post_distancia(p: AdpPixel) -> f32 {
    if p.es_cielo {
        return 1e6;
    }
    return length(view_position(p.uv, p.profundidad));
}

fn adp_post_salida(color: vec3<f32>, alfa: f32) -> vec4<f32> {
    return vec4<f32>(color, alfa);
}
