// PostInput y recursos de la etapa post -> píxel del núcleo. Porqué: docs/efectos/nucleo.md §Adaptadores

struct AdpPixel {
    uv: vec2<f32>,
    pixel: vec2<f32>,
    color: vec3<f32>,       // tal como llega (en la primera pasada, el «picture» codificado)
    alfa: f32,
    profundidad: f32,       // invertida: 0 cielo, 1 cerca
    es_cielo: bool,
}

fn adp_post_pixel(input: PostInput) -> AdpPixel {
    return AdpPixel(input.uv, input.pixel, input.color.rgb, input.color.a, input.depth, input.depth <= 0.0);
}

// Luz lineal de la escena a partir del «picture» codificado (ADR 0004), leído de scene_color: la pasada de
// composición no recibe el «picture» en input.color (la de volumen escribe su propio destino).
fn adp_post_escena(p: AdpPixel) -> vec3<f32> {
    let c = textureLoad(scene_color, vec2<i32>(p.pixel), 0).rgb;
    return col_decodificar_escena(c, adp_codificacion());
}

// Dirección de vista del píxel (unitaria).
fn adp_post_direccion(p: AdpPixel) -> vec3<f32> {
    return normalize(view_position(p.uv, select(p.profundidad, 1e-4, p.es_cielo)));
}

// Niebla de borde: el cielo aproximado en la dirección del píxel y cuánto pesa.
fn adp_post_borde(p: AdpPixel, dir: vec3<f32>) -> vec4<f32> {
    if p.es_cielo || !adp_es_superficie() {
        return vec4<f32>(0.0);
    }
    let pos = view_position(p.uv, p.profundidad);
    let fuera = smoothstep(0.1, 0.7, frame.eye_light_smooth.y);
    let peso = vol_borde(length(pos.xz), frame.render_distance, dir.y, fuera);
    let c = opc_cielo();
    let horizonte = adp_tabla(frame.sun_direction.y, ATM_FILA_HORIZONTE) * c.sol_color * c.brillo;
    let cielo = vol_cielo_aproximado(horizonte, adp_cielo_medio(c), dir.y) * OPC_CIELO_BRILLO_DIBUJO;
    return vec4<f32>(cielo, peso);
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

