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
    if opc_depuracion().vista == OPC_VISTA_RELIEVE {
        return c;
    }
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
    let fuera = 1.0 - adp_detector_cueva();
    let peso = vol_borde(length(pos.xz), frame.render_distance, dir.y, fuera);
    let c = opc_cielo();
    let horizonte = adp_tabla(frame.sun_direction.y, ATM_FILA_HORIZONTE) * c.sol_color * c.brillo;
    var cielo = vol_cielo_aproximado(horizonte, adp_cielo_medio(c), dir.y) * OPC_CIELO_BRILLO_DIBUJO;
    // El color del borde es el del cielo de detrás, así que lleva el mismo velo de lluvia que el cielo: sin él pintaba
    // el horizonte claro del cielo despejado sobre los bloques lejanos (observación del dueño 1.3).
    // Porqué: docs/efectos/niebla-y-nubes.md §«Borde con lluvia (F-42)»
    cielo = cie_aplicar_lluvia(cielo, dir.y, vec3<f32>(1.0), frame.camera_position.y, adp_lluvia(c));
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


// La sombra de las nubes del terreno que se ve en un píxel de una pasada de post (1 en el cielo).
fn adp_sombra_nubes_post(uv: vec2<f32>, profundidad: f32) -> f32 {
    if profundidad <= 0.0 {
        return 1.0;
    }
    let pos = view_position(uv, profundidad);
    return mix(1.0, adp_sombra_nubes(pos + frame.camera_position), opc_volumen().sombra_nubes);
}

// Aplica la sombra de nubes de ¼ de resolución a la parte directa de la luz del terreno sólido (F-68).
fn adp_aplicar_sombra_nubes(color: vec3<f32>, p: AdpPixel) -> vec3<f32> {
    if p.es_cielo || !adp_sombra_nubes_en_post() || opc_quitar(2048u) {
        return color;
    }
    let s = surface_at(vec2<i32>(p.pixel));
    if !s.present {
        return color;
    }
    let indirecta = sup_desempaquetar_dato(s.data).y;
    let nubes = textureSampleLevel(mapa_aurora, linear_sampler, p.uv, 0.0).r;
    return color * (indirecta + (1.0 - indirecta) * nubes);
}
