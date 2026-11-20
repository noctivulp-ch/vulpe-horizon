// Vaho del aliento en caras interiores (27 v2 §Capa 6).
// Elipse de semiejes 0,26 x 0,22 bloques ensanchada hasta 1,7x tras 5 exhalaciones repetidas,
// color de condensación con blancura (100 % defecto) y opacidad (150 % defecto), perfil suave,
// grano fino y fusión de la escarcha/borde/copos que tenga debajo.
// Función pura del núcleo: no lee `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §7

struct SupCristalAliento {
    color: vec3<f32>,       // color lineal del vaho
    alfa: f32,              // 0..1 opacidad final
    grosor: f32,            // 0..1 grosor para el desenfoque detrás del cristal (§Capa 7)
    derrite: f32,           // 0..1 máscara que funde escarcha, borde helado y copos debajo
}

fn sup_cristal_aliento_v2(
    plano: SupCristalPlano,
    pos_rel: vec3<f32>,
    normal_cara: vec3<f32>,
    centro_rel: vec3<f32>,
    vaho_peso: f32,
    vaho_escala: f32,
    aliento_opacidad: f32,
    aliento_blancura: f32,
    cond_grosor: f32,
    k_res: f32,
    con_mod: bool,
    es_interior: bool,
    espectador: bool,
    tiempo: f32,
) -> SupCristalAliento {
    let vacio = SupCristalAliento(vec3<f32>(0.0), 0.0, 0.0, 0.0);
    if !plano.vertical || !es_interior || espectador || aliento_opacidad <= 0.001 || cond_grosor >= 0.5 {
        return vacio;
    }

    var peso = vaho_peso;
    var centro = centro_rel;
    var escala = clamp(vaho_escala, 1.0, 1.7);

    if !con_mod {
        // Respaldo sin mod: punto más cercano de la cara a <= 1,5 bloques con pulso de exhalación cada 3,3 s.
        let d_plano = dot(pos_rel, normal_cara);
        let dist_cam = abs(d_plano);
        if dist_cam >= OPC_CRISTAL_VAHO_DIST {
            return vacio;
        }
        centro = normal_cara * d_plano;
        let pulso = 0.55 + 0.45 * (0.5 + 0.5 * sin(tiempo * (MAT_TAU / OPC_CRISTAL_VAHO_PERIODO)));
        peso = smoothstep(OPC_CRISTAL_VAHO_DIST, 0.40, dist_cam) * pulso;
        escala = 1.0 + 0.35 * peso;
    }

    if peso <= 0.004 {
        return vacio;
    }

    // Evita que la elipse se proyecte en paredes de cristal perpendiculares o lejanas en profundidad.
    let delta = pos_rel - centro;
    if abs(dot(delta, normal_cara)) > 0.22 {
        return vacio;
    }

    let semi_x = OPC_CRISTAL_VAHO_SEMI_X * escala;
    let semi_y = OPC_CRISTAL_VAHO_SEMI_Y * escala;
    let du = dot(delta, plano.tangente) / max(semi_x, 1e-4);
    let dv = dot(delta, plano.bitangente) / max(semi_y, 1e-4);
    let r2_bruto = du * du + dv * dv;
    if r2_bruto > 1.85 {
        return vacio;
    }

    // Perfil suave y orgánico con grano fino en la rejilla elegida.
    let n_suave = rui_valor2(plano.uv * 5.2 + vec2<f32>(1.7, 4.3));
    let rn = sqrt(r2_bruto) / (0.92 + 0.16 * n_suave);
    let perfil = exp(-2.2 * rn * rn) * smoothstep(1.22, 0.15, rn);
    if perfil <= 0.002 {
        return vacio;
    }

    let k = clamp(k_res, 0.5, 2.0);
    let gx = floor(plano.uv * (OPC_CRISTAL_REJILLA * k));
    let h_fino = rui_hash33(vec3<i32>(i32(gx.x), i32(gx.y), 211)).x;
    let grano = 0.90 + 0.20 * h_fino;

    // Atenuación limpia al acercarse al umbral cond_grosor = 0,5.
    let libre_cond = smoothstep(0.50, 0.35, cond_grosor);
    let grosor = clamp(perfil * peso * libre_cond, 0.0, 1.0);
    let alfa = clamp(0.24 * aliento_opacidad * grosor * grano, 0.0, 0.78);
    let derrite = clamp(exp(-1.5 * rn * rn) * smoothstep(1.28, 0.05, rn) * peso, 0.0, 1.0);
    let color = mix(OPC_CRISTAL_COND_COLOR, vec3<f32>(1.0), clamp(aliento_blancura, 0.0, 1.0));

    return SupCristalAliento(color, alfa, grosor, derrite);
}
