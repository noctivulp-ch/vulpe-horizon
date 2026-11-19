// Vaho del aliento al acercarse a un cristal con escarcha (27 §4).
// Empañado suave y continuo con ruido interpolado a >= 32 texeles/bloque y fundido gaussiano en el borde.
// Función pura del núcleo: no lee `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §4

struct SupCristalAliento {
    vaho: f32,              // 0..1 densidad continua de condensación
    derrite: f32,           // 0..1 máscara amplia y suave que disuelve el dibujo de escarcha
    borroso: f32,           // 0..1 desenfoque suave detrás del vaho
}

// Evalúa la mancha de vaho centrada en `centro_rel` (posición relativa a la cámara del punto más cercano
// del cristal), con pulso de respiración cada ~3,5 s hasta un radio de ~1 bloque.
fn sup_cristal_aliento(
    plano: SupCristalPlano,
    pos_rel: vec3<f32>,
    normal_cara: vec3<f32>,
    centro_rel: vec3<f32>,
    vaho_peso: f32,
    con_mod: bool,
    escarcha_nivel: f32,
    tiempo: f32,
) -> SupCristalAliento {
    let vacio = SupCristalAliento(0.0, 0.0, 0.0);
    if escarcha_nivel <= 0.05 || vaho_peso < 0.0 {
        return vacio;
    }

    var peso = vaho_peso;
    var centro = centro_rel;
    if !con_mod {
        // Sin mod: calcula en vivo el punto más cercano del plano del cristal a la cámara, sin memoria de 5 s.
        let d_plano = dot(pos_rel, normal_cara);
        let dist_cam = abs(d_plano);
        if dist_cam >= OPC_CRISTAL_VAHO_DIST {
            return vacio;
        }
        centro = normal_cara * d_plano;
        peso = smoothstep(OPC_CRISTAL_VAHO_DIST, 0.35, dist_cam);
    }

    if peso <= 0.005 {
        return vacio;
    }

    // Pulso de respiración cada ~3,5 s: crece suavemente con cada exhalación hasta ~1 bloque de radio.
    let fase = tiempo * (MAT_TAU / OPC_CRISTAL_VAHO_PERIODO);
    let pulso = 0.88 + 0.12 * (0.5 + 0.5 * sin(fase));
    let radio = OPC_CRISTAL_VAHO_RADIO * (0.34 + 0.66 * peso) * pulso;

    let d = length(pos_rel - centro);
    let limite = radio * 1.2;
    if d >= limite {
        return vacio;
    }

    // Ruido continuo interpolado a >= 32 texeles por bloque (sin cuantización en bloques gruesos).
    let uv = plano.uv;
    let n_suave = rui_valor2(uv * 5.5 + vec2<f32>(1.3, 4.7));
    let n_medio = rui_valor2(uv * 16.0 + vec2<f32>(n_suave * 0.4, -n_suave * 0.3));
    let n_fino = rui_valor2(uv * OPC_CRISTAL_REJILLA + vec2<f32>(7.1, 2.9));
    let micro_vaho = 0.78 + 0.22 * (n_suave * 0.45 + n_medio * 0.35 + n_fino * 0.20);

    // Deformación sutil y continua del borde para que no sea un círculo geométrico rígido.
    let rn = d / max(radio * (0.90 + 0.18 * n_suave), 1e-4);
    let gauss = exp(-2.5 * rn * rn) * smoothstep(1.15, 0.12, rn);
    let derrite = exp(-1.7 * rn * rn) * smoothstep(1.20, 0.05, rn) * clamp(peso, 0.0, 1.0);
    let vaho = clamp(gauss * micro_vaho * peso * (0.90 + 0.10 * pulso), 0.0, 1.0);
    let borroso = smoothstep(0.03, 0.55, vaho) * 0.90;

    return SupCristalAliento(vaho, derrite, borroso);
}
