// Gotas de lluvia, regueros y secado escalonado en cristales, cuantizados a 32 texeles por bloque (27 §1).
// Función pura del núcleo: no lee `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §1

struct SupCristalPlano {
    uv: vec2<f32>,          // coordenadas en la cara del cristal en bloques (continuas entre bloques)
    tangente: vec3<f32>,    // eje +u sobre la cara
    bitangente: vec3<f32>,  // eje +v sobre la cara (+Y en caras verticales)
    vertical: bool,
}

struct SupCristalLluvia {
    gota: f32,              // 0..1 máscara de gota (cuantizada a 32 texeles/bloque)
    rastro: f32,            // 0..1 rastro fino tras la gota que baja
    borde: f32,             // 0..1 borde oscuro por reflexión interna en el contorno
    caustica: f32,          // 0..1 brillo interno refractado en la base de la gota
    mojado: f32,            // 0..1 película húmeda sobre la cara
    grad_uv: vec2<f32>,     // pendiente óptica suave de la lente (sin cuantizar)
}

// Proyecta la posición de mundo sobre una base tangente continua por orientación de cara.
fn sup_cristal_plano(mundo: vec3<f32>, normal_cara: vec3<f32>) -> SupCristalPlano {
    let vertical = abs(normal_cara.y) < 0.5;
    if vertical {
        let t = normalize(cross(vec3<f32>(0.0, 1.0, 0.0), normal_cara));
        let b = vec3<f32>(0.0, 1.0, 0.0);
        return SupCristalPlano(vec2<f32>(dot(mundo, t), mundo.y), t, b, true);
    }
    let t = vec3<f32>(1.0, 0.0, 0.0);
    let b = vec3<f32>(0.0, 0.0, 1.0);
    return SupCristalPlano(vec2<f32>(mundo.x, mundo.z), t, b, false);
}

// Movimiento a tirones: permanece quieta ~68 % del ciclo y resbala de golpe hacia abajo.
fn sup_cristal_tiron(fase: f32) -> f32 {
    let entero = floor(fase);
    let f = fract(fase);
    return entero + smoothstep(0.68, 0.98, f);
}

// Resultado interno de una capa de gotas deslizantes.
struct SupGotaCapa {
    gota: f32,
    rastro: f32,
    borde: f32,
    caustica: f32,
    grad: vec2<f32>,
}

// Evalúa una capa de gotas que bajan a tirones en columnas del mundo (rejilla de 32 texeles/bloque).
fn sup_cristal_capa_deslizante(
    uv_q: vec2<f32>,
    uv_suave: vec2<f32>,
    celdas: vec2<f32>,
    tiempo: f32,
    viento_u: f32,
    densidad: f32,
    tormenta: f32,
    vivo_grande: f32,
    vivo_rastro: f32,
    semilla: i32,
) -> SupGotaCapa {
    let vacio = SupGotaCapa(0.0, 0.0, 0.0, 0.0, vec2<f32>(0.0));
    // Inclinación por viento: cuanto más baja, más deriva hacia el lado al que sopla.
    let uv_inclinada_q = vec2<f32>(uv_q.x + uv_q.y * viento_u, uv_q.y);
    let uv_inclinada_s = vec2<f32>(uv_suave.x + uv_suave.y * viento_u, uv_suave.y);

    let gq = uv_inclinada_q * celdas;
    let gs = uv_inclinada_s * celdas;
    let id = floor(gq);
    let h = rui_hash33(vec3<i32>(i32(id.x), i32(id.y), semilla));

    if h.x > densidad {
        return vacio;
    }

    // Desplazamiento a tirones: baja por el cristal cruzando entre bloques sin saltos.
    let vel = (0.35 + 0.55 * h.y) * (1.0 + 0.45 * tormenta);
    let avance = sup_cristal_tiron(tiempo * vel + h.z * 17.0);
    let y_gota = 1.0 - fract(avance * 0.25 + h.z);
    let x_gota = 0.24 + 0.52 * fract(h.y * 7.13 + sin(y_gota * MAT_TAU + h.x * 12.0) * 0.07);

    // Fusión: al cruzarse con zonas de gotas quietas, la gota deslizante crece.
    let h_est = rui_hash21(vec2<i32>(i32(floor(id.x * 2.0 + x_gota * 2.0)), i32(floor(id.y * 3.0 + y_gota * 3.0))));
    let fusion = smoothstep(0.52, 0.85, h_est) * (0.45 + 0.30 * tormenta);

    // Tamaño en texeles de la rejilla de 32: 1,5..3 texeles, hasta ~4 con tormenta/fusión.
    let radio_tex = (1.35 + 1.15 * h.z + 0.65 * tormenta + fusion) * (0.45 + 0.55 * vivo_grande);
    let radio_celda = (radio_tex / OPC_CRISTAL_REJILLA) * celdas;

    // Forma de lágrima cuantizada a la rejilla de 32: más ancha abajo y afinada arriba.
    let rel_q = fract(gq) - vec2<f32>(x_gota, y_gota);
    let ry_q = max(radio_celda.y * 1.38, 1e-4);
    let estrecha_q = 1.0 - 0.32 * clamp(rel_q.y / ry_q, 0.0, 1.0);
    let dq = vec2<f32>(rel_q.x / max(radio_celda.x * estrecha_q, 1e-4), rel_q.y / ry_q);
    let d2_q = dot(dq, dq);
    let gota = select(0.0, 1.0, d2_q <= 1.0) * vivo_grande;

    // Óptica suave (sin cuantizar): cúpula semiesférica para refracción fuerte, borde y cáustica inferior.
    let rel_s = fract(gs) - vec2<f32>(x_gota, y_gota);
    let estrecha_s = 1.0 - 0.32 * clamp(rel_s.y / ry_q, 0.0, 1.0);
    let ds = vec2<f32>(rel_s.x / max(radio_celda.x * estrecha_s, 1e-4), rel_s.y / ry_q);
    let r_s = length(ds);
    let cupula = sqrt(max(1.0 - min(r_s * r_s, 1.0), 0.05));
    // Pendiente de lente convexa: desvía la luz hacia el centro óptico y gira la normal en el contorno.
    let grad = clamp(-ds / max(cupula, 0.38), vec2<f32>(-1.8), vec2<f32>(1.8)) * gota;
    let borde = smoothstep(0.58, 0.98, r_s) * gota;
    // Cáustica interna: la luz del cielo se concentra en el arco inferior de la gota.
    let caustica = smoothstep(-0.05, -0.78, ds.y) * (1.0 - smoothstep(0.68, 1.02, r_s)) * gota;

    // Rastro fino encima de la gota que acaba de resbalar (se seca primero).
    let dy_arriba = fract(gq).y - y_gota;
    let dx_rastro = abs(fract(gq).x - x_gota) * (OPC_CRISTAL_REJILLA / celdas.x);
    let largo_rastro = 0.24 + 0.36 * vivo_rastro;
    var rastro = 0.0;
    if dy_arriba > 0.0 && dy_arriba < largo_rastro && dx_rastro < 0.72 {
        let t_r = 1.0 - dy_arriba / largo_rastro;
        let cuenta = rui_hash21(vec2<i32>(i32(floor(uv_inclinada_q.x * OPC_CRISTAL_REJILLA)), i32(floor(uv_inclinada_q.y * OPC_CRISTAL_REJILLA))));
        rastro = select(0.0, t_r, cuenta > 0.34) * vivo_rastro;
    }

    return SupGotaCapa(gota, rastro, borde, caustica, grad);
}

// Estilo alternativo: regueros verticales que bajan en la rejilla de 32 (OPC_CRISTAL_ESTILO_REGUEROS).
fn sup_cristal_regueros(
    uv_q: vec2<f32>,
    uv_suave: vec2<f32>,
    tiempo: f32,
    viento_u: f32,
    intensidad: f32,
    vivo_grande: f32,
    vivo_rastro: f32,
) -> SupCristalLluvia {
    let uv_inc_q = vec2<f32>(uv_q.x + uv_q.y * viento_u, uv_q.y);
    let uv_inc_s = vec2<f32>(uv_suave.x + uv_suave.y * viento_u, uv_suave.y);
    let col = floor(uv_inc_q.x * OPC_CRISTAL_REJILLA);
    let h = rui_hash21(vec2<i32>(i32(col), 41));
    let umbral = 1.0 - clamp(intensidad * 0.42, 0.0, 0.75);
    if h < umbral {
        return SupCristalLluvia(0.0, 0.0, 0.0, 0.0, intensidad * (1.0 - 0.8 * (1.0 - vivo_grande)), vec2<f32>(0.0));
    }
    let vel = 1.4 + 2.2 * fract(h * 13.7);
    let y_mov = uv_inc_q.y * 2.5 + tiempo * vel + h * 19.0;
    let tramo = fract(y_mov);
    let cabeza = select(0.0, 1.0, tramo < 0.14) * vivo_grande;
    let cola = select(0.0, (1.0 - (tramo - 0.14) / 0.55), tramo >= 0.14 && tramo < 0.69) * vivo_rastro;
    let fx = fract(uv_inc_s.x * OPC_CRISTAL_REJILLA) - 0.5;
    let grad = vec2<f32>(-fx * 1.8, -0.45 * cabeza) * max(cabeza, cola * 0.6);
    let borde = select(0.0, 1.0, abs(fx) > 0.34) * max(cabeza, cola * 0.5);
    let caustica = cabeza * (1.0 - abs(fx) * 1.5);
    return SupCristalLluvia(cabeza, cola, borde, max(caustica, 0.0), intensidad * max(vivo_grande, vivo_rastro * 0.5), grad);
}

// Lluvia en una cara de cristal: gotas quietas (1–2 texeles), gotas que bajan a tirones y se juntan (2–4 texeles)
// y secado escalonado (rastros -> pequeñas -> grandes).
fn sup_cristal_lluvia(
    plano: SupCristalPlano,
    normal_cara: vec3<f32>,
    luz_cielo: f32,
    viento_xz: vec2<f32>,
    tiempo: f32,
    lluvia_pico: f32,
    secado: f32,
    tormenta: f32,
    escala_ajuste: f32,
    distancia: f32,
) -> SupCristalLluvia {
    let vacio = SupCristalLluvia(0.0, 0.0, 0.0, 0.0, 0.0, vec2<f32>(0.0));
    if lluvia_pico <= 0.005 || escala_ajuste <= 0.0 || secado >= 0.999 {
        return vacio;
    }
    if normal_cara.y < -0.5 {
        return vacio;
    }
    let exp_cielo = smoothstep(OPC_CRISTAL_CIELO_MIN, OPC_CRISTAL_CIELO_MAX, luz_cielo);
    if exp_cielo <= 0.001 {
        return vacio;
    }
    let atenuacion_dist = 1.0 - smoothstep(OPC_CRISTAL_DIST_INICIO, OPC_CRISTAL_DIST_FIN, distancia);
    if atenuacion_dist <= 0.001 {
        return vacio;
    }

    // Factor barlovento / sotavento según la dirección del viento de 26.
    let viento_len = length(viento_xz);
    let viento_dir = select(vec2<f32>(-1.0, 0.0), viento_xz / max(viento_len, 1e-4), viento_len > 0.01);
    let viento_3d = vec3<f32>(viento_dir.x, 0.0, viento_dir.y);
    let barlovento = select(0.5, dot(normal_cara, -viento_3d), plano.vertical);
    let factor_viento = clamp(1.0 + OPC_CRISTAL_VIENTO_BARLOVENTO * barlovento, 0.35, 1.45);
    let viento_u = select(0.0, dot(viento_3d, plano.tangente) * viento_len * OPC_CRISTAL_VIENTO_INCLINACION, plano.vertical);

    let intensidad = clamp(lluvia_pico * exp_cielo * factor_viento * escala_ajuste, 0.0, 1.5);

    // Secado escalonado (0..1 sobre ~30 s): primero rastros, luego pequeñas, al final grandes.
    let vivo_rastro = 1.0 - smoothstep(OPC_CRISTAL_SECADO_RASTRO.x, OPC_CRISTAL_SECADO_RASTRO.y, secado);
    let vivo_pequenas = 1.0 - smoothstep(OPC_CRISTAL_SECADO_PEQUENAS.x, OPC_CRISTAL_SECADO_PEQUENAS.y, secado);
    let vivo_grandes = 1.0 - smoothstep(OPC_CRISTAL_SECADO_GRANDES.x, OPC_CRISTAL_SECADO_GRANDES.y, secado);

    let texel = floor(plano.uv * OPC_CRISTAL_REJILLA);
    let uv_q = (texel + 0.5) / OPC_CRISTAL_REJILLA;

    if OPC_CRISTAL_ESTILO_REGUEROS && plano.vertical {
        var r = sup_cristal_regueros(uv_q, plano.uv, tiempo, viento_u, intensidad, vivo_grandes, vivo_rastro);
        r.gota *= atenuacion_dist;
        r.rastro *= atenuacion_dist;
        r.borde *= atenuacion_dist;
        r.caustica *= atenuacion_dist;
        r.mojado *= exp_cielo * atenuacion_dist;
        r.grad_uv *= atenuacion_dist;
        return r;
    }

    // 1) Gotas sueltas quietas (1–2 texeles de la rejilla de 32), con lente convexa completa.
    let celda_est = floor(uv_q * 7.0);
    let h_est = rui_hash33(vec3<i32>(i32(celda_est.x), i32(celda_est.y), 19));
    let umbral_est = clamp(0.32 + 0.42 * intensidad + 0.14 * tormenta, 0.0, 0.92);
    var gota_est = 0.0;
    var borde_est = 0.0;
    var caustica_est = 0.0;
    var grad_est = vec2<f32>(0.0);
    if h_est.x < umbral_est && vivo_pequenas > 0.01 {
        let centro = vec2<f32>(0.25 + 0.5 * h_est.y, 0.25 + 0.5 * h_est.z);
        let r_tex = (0.85 + 0.90 * fract(h_est.x * 17.3) + 0.35 * tormenta) * (0.45 + 0.55 * vivo_pequenas);
        let r_celda = (r_tex / OPC_CRISTAL_REJILLA) * 7.0;
        let dq = (fract(uv_q * 7.0) - centro) / max(r_celda, 1e-4);
        if dot(dq, dq) <= 1.0 {
            gota_est = vivo_pequenas;
            let ds = (fract(plano.uv * 7.0) - centro) / max(r_celda, 1e-4);
            let r_s = length(ds);
            let cupula = sqrt(max(1.0 - min(r_s * r_s, 1.0), 0.08));
            grad_est = clamp(-ds / max(cupula, 0.45), vec2<f32>(-1.5), vec2<f32>(1.5)) * vivo_pequenas;
            borde_est = smoothstep(0.55, 0.98, r_s) * vivo_pequenas;
            caustica_est = smoothstep(-0.05, -0.75, ds.y) * (1.0 - smoothstep(0.65, 1.0, r_s)) * vivo_pequenas;
        }
    }

    // 2) Dos capas de gotas que bajan a tirones y dejan rastro (solo en caras verticales).
    var gota_desl = 0.0;
    var rastro = 0.0;
    var borde_desl = 0.0;
    var caustica_desl = 0.0;
    var grad_desl = vec2<f32>(0.0);
    if plano.vertical {
        let dens1 = clamp(0.28 + 0.44 * intensidad + 0.18 * tormenta, 0.0, 0.92);
        let c1 = sup_cristal_capa_deslizante(
            uv_q, plano.uv, vec2<f32>(4.0, 1.5), tiempo, viento_u, dens1, tormenta, vivo_grandes, vivo_rastro, 7,
        );
        let dens2 = clamp(0.22 + 0.36 * intensidad + 0.16 * tormenta, 0.0, 0.88);
        let c2 = sup_cristal_capa_deslizante(
            uv_q + vec2<f32>(0.37, 0.19), plano.uv + vec2<f32>(0.37, 0.19), vec2<f32>(5.0, 2.0), tiempo * 1.18,
            viento_u, dens2, tormenta, vivo_grandes, vivo_rastro, 23,
        );
        let gana2 = c2.gota > c1.gota;
        gota_desl = max(c1.gota, c2.gota);
        rastro = max(c1.rastro, c2.rastro);
        borde_desl = select(c1.borde, c2.borde, gana2);
        caustica_desl = select(c1.caustica, c2.caustica, gana2);
        grad_desl = select(c1.grad, c2.grad, gana2);
    }

    let gana_desl = gota_desl >= gota_est;
    let gota = max(gota_desl, gota_est);
    let borde = max(select(borde_est, borde_desl, gana_desl), rastro * 0.25);
    let caustica = select(caustica_est, caustica_desl, gana_desl);
    let grad_uv = select(grad_est, grad_desl, gana_desl)
                + vec2<f32>(0.0, -0.35 * rastro) * (1.0 - gota);
    let mojado = clamp(intensidad * (1.0 - smoothstep(0.0, 0.85, secado)), 0.0, 1.0);

    return SupCristalLluvia(
        gota * atenuacion_dist,
        rastro * atenuacion_dist,
        borde * atenuacion_dist,
        caustica * atenuacion_dist,
        mojado * atenuacion_dist,
        grad_uv * atenuacion_dist,
    );
}
