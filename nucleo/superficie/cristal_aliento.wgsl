// Vaho del aliento al acercarse a un cristal con escarcha (27 §4).
// Función pura del núcleo: no lee `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §4

struct SupCristalAliento {
    vaho: f32,              // 0..1 mancha redonda y difusa de condensación
    borroso: f32,           // 0..1 desenfoque suave detrás del vaho
}

// Evalúa la mancha de vaho centrada en `centro_rel` (posición relativa a la cámara del punto más cercano
// del cristal), con pulso de respiración cada ~3,5 s hasta un radio de ~1 bloque.
fn sup_cristal_aliento(
    pos_rel: vec3<f32>,
    normal_cara: vec3<f32>,
    centro_rel: vec3<f32>,
    vaho_peso: f32,
    con_mod: bool,
    escarcha_nivel: f32,
    tiempo: f32,
) -> SupCristalAliento {
    let vacio = SupCristalAliento(0.0, 0.0);
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
    let pulso = 0.86 + 0.14 * (0.5 + 0.5 * sin(fase));
    let radio = OPC_CRISTAL_VAHO_RADIO * (0.30 + 0.70 * peso) * pulso;

    let d = length(pos_rel - centro);
    if d >= radio {
        return vacio;
    }

    // Mancha redonda y difusa, ligeramente más densa en el centro y con borde suave.
    let perfil = 1.0 - smoothstep(radio * 0.18, radio, d);
    let vaho = perfil * perfil * clamp(peso * (0.88 + 0.12 * pulso), 0.0, 1.0);
    return SupCristalAliento(vaho, smoothstep(0.05, 0.65, vaho) * 0.85);
}
