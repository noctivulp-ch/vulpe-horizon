// Condensación interior y borde helado en caras interiores frías (27 v2 §Capa 5).
// Funciones puras del núcleo: no leen `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §6

struct SupCristalCondensacion {
    color: vec3<f32>,       // color lineal de la condensación
    alfa: f32,              // 0..1 opacidad de la capa
    grosor: f32,            // 0..1 cobertura normalizada (para vaho < 0,5 y desenfoque §Capa 7)
}

// Condensación de dentro (27 v2 §Capa 5): color (232,240,246) aclarado hacia blanco por `blancura`,
// alfa base ~0,22 con variación suave (±0,025) y grano fino (±0,015), por `min(1, escarcha*1,25) * opacidad`.
// Avanza desde el marco de la ventana entera hacia el centro en 16 pasos discretos.
fn sup_cristal_condensacion(
    plano: SupCristalPlano,
    dist_marco: vec4<f32>,
    escarcha_nivel: f32,
    cond_nivel: f32,
    cond_opacidad: f32,
    cond_blancura: f32,
    k_res: f32,
    variante: u32,
) -> SupCristalCondensacion {
    let vacio = SupCristalCondensacion(vec3<f32>(0.0), 0.0, 0.0);
    if !plano.vertical || cond_nivel <= 0.001 || escarcha_nivel <= 0.005 || cond_opacidad <= 0.001 {
        return vacio;
    }

    let local = fract(plano.uv);
    let b_arr = dist_marco.x + (1.0 - local.y);
    let b_aba = dist_marco.y + local.y;
    let b_izq = dist_marco.z + local.x;
    let b_der = dist_marco.w + (1.0 - local.x);

    // Distancia relativa del marco al centro de la ventana entera (0 en el marco, 1 en el centro).
    let ancho_v = max(b_izq + b_der, 1.0);
    let alto_v = max(b_arr + b_aba, 1.0);
    let radio_v = max(min(ancho_v, alto_v) * 0.5, 0.5);
    let d_marco = min(min(b_arr, b_aba), min(b_izq, b_der));

    let off_v = vec2<f32>(f32(variante) * 13.7 + 2.1, f32(variante) * 7.9 + 4.3);
    let n_suave = rui_valor2(plano.uv * 2.6 + off_v);
    let d_norm = clamp(d_marco / radio_v + (n_suave - 0.5) * 0.08, 0.0, 1.0);

    // Avance en 16 pasos discretos desde el marco al centro según sube `cond_nivel`.
    let paso = floor(clamp(cond_nivel, 0.0, 1.0) * 16.0 + 0.5) / 16.0;
    if paso <= 0.0 {
        return vacio;
    }
    let avance = paso * 1.08;
    if d_norm > avance + 0.06 {
        return vacio;
    }

    let frente = smoothstep(avance + 0.06, max(avance - 0.08, 0.0), d_norm);
    let grosor = clamp(frente * clamp(cond_nivel * 1.15, 0.0, 1.0), 0.0, 1.0);
    if grosor <= 0.002 {
        return vacio;
    }

    // Grano fino en la rejilla de texeles elegida (±0,015) + variación suave (±0,025).
    let k = clamp(k_res, 0.5, 2.0);
    let res = OPC_CRISTAL_REJILLA * k;
    let gx = floor(plano.uv * res);
    let h_fino = rui_hash33(vec3<i32>(i32(gx.x), i32(gx.y), i32(variante) * 31 + 157)).x;
    let alfa_base = 0.22 + (n_suave - 0.5) * 0.05 + (h_fino - 0.5) * 0.03;

    let fuerza = min(1.0, escarcha_nivel * 1.25);
    let alfa = clamp(alfa_base * fuerza * cond_opacidad * grosor, 0.0, 0.85);
    let color = mix(OPC_CRISTAL_COND_COLOR, vec3<f32>(1.0), clamp(cond_blancura, 0.0, 1.0));
    return SupCristalCondensacion(color, alfa, grosor);
}

// Borde helado interior (27 v2 §Capa 5):
//   0 = apagado
//   1 = banda (por defecto): banda lisa con 7 escalones de alfa (0,82 -> 0,13) de denso a hielo,
//       alcance max(1,5, 0,9 * escarcha * 8 * k) * 1,35 texeles, 1,5 % destellos, contorno ondulado por 3 senos,
//       visibilidad max(0,45, condensacion).
//   2 = cristales: la escarcha de Capa 2 con contorno ondulado al 90 %, escalada por condensacion.
fn sup_cristal_borde_helado(
    plano: SupCristalPlano,
    dist_marco: vec4<f32>,
    escarcha_nivel: f32,
    cond_nivel: f32,
    escala_nieve: f32,
    k_res: f32,
    estilo: u32,
    variante: u32,
) -> SupCristalCapa {
    let vacio = SupCristalCapa(vec3<f32>(0.0), 0.0, 0.0);
    if !plano.vertical || estilo == 0u || escarcha_nivel <= 0.005 {
        return vacio;
    }

    if estilo == 2u {
        if cond_nivel <= 0.005 {
            return vacio;
        }
        var cr = sup_cristal_escarcha_v2(
            plano,
            dist_marco,
            escarcha_nivel,
            max(escala_nieve, 1.0),
            k_res,
            variante,
            true,
            0.90,
        );
        cr.alfa *= clamp(cond_nivel, 0.0, 1.0);
        return cr;
    }

    // Estilo 1: banda (por defecto).
    let k = clamp(k_res, 0.5, 2.0);
    let res = OPC_CRISTAL_REJILLA * k;
    let gx = floor(plano.uv * res);
    let tx = floor(fract(plano.uv) * res);

    let alcance = max(1.5, 0.9 * escarcha_nivel * 8.0 * k) * 1.35;
    let d_base = sup_cristal_dist_bordes_tx(tx, res, dist_marco);
    let d_rapido = min(min(d_base.x, d_base.y), min(d_base.z, d_base.w));
    if d_rapido > alcance + 3.0 * k {
        return vacio;
    }

    // Contorno ondulado por suma de 3 senos a lo largo de cada borde (4 variantes por cara).
    let ph = f32(variante) * 1.618 + 0.4;
    let onda_h = (sin(plano.uv.x * 6.283 + ph) * 0.50
                + sin(plano.uv.x * 13.4 + ph * 1.7) * 0.32
                + sin(plano.uv.x * 23.9 + ph * 0.9) * 0.18) * (1.6 * k);
    let onda_v = (sin(plano.uv.y * 6.283 + ph + 1.2) * 0.50
                + sin(plano.uv.y * 13.4 + ph * 2.1) * 0.32
                + sin(plano.uv.y * 23.9 + ph * 1.3) * 0.18) * (1.6 * k);

    let d_ond = max(d_base + vec4<f32>(onda_h, -onda_h, onda_v, -onda_v), vec4<f32>(0.0));
    let d_min = min(min(d_ond.x, d_ond.y), min(d_ond.z, d_ond.w));
    if d_min >= alcance {
        return vacio;
    }

    // 7 escalones de alfa (0,82 -> 0,13), del tono denso al de hielo.
    let esc_idx = i32(clamp(floor((d_min / max(alcance, 1e-3)) * 7.0), 0.0, 6.0));
    var alfa = 0.13;
    var color = OPC_CRISTAL_ESCARCHA_HIELO;
    switch esc_idx {
        case 0: { alfa = 0.82; color = OPC_CRISTAL_ESCARCHA_DENSO; }
        case 1: { alfa = 0.71; color = mix(OPC_CRISTAL_ESCARCHA_DENSO, OPC_CRISTAL_ESCARCHA_CRISTAL, 0.40); }
        case 2: { alfa = 0.59; color = OPC_CRISTAL_ESCARCHA_CRISTAL; }
        case 3: { alfa = 0.48; color = OPC_CRISTAL_ESCARCHA_CRISTAL; }
        case 4: { alfa = 0.36; color = mix(OPC_CRISTAL_ESCARCHA_CRISTAL, OPC_CRISTAL_ESCARCHA_HIELO, 0.55); }
        case 5: { alfa = 0.25; color = OPC_CRISTAL_ESCARCHA_HIELO; }
        default: { alfa = 0.13; color = OPC_CRISTAL_ESCARCHA_HIELO; }
    }

    // 1,5 % de destellos blancos.
    let h_tx = rui_hash33(vec3<i32>(i32(gx.x), i32(gx.y), i32(variante) * 53 + 193));
    var destello = 0.0;
    if h_tx.x < 0.015 {
        color = OPC_CRISTAL_ESCARCHA_DESTELLO;
        alfa = max(alfa, 0.90);
        destello = 1.0;
    }

    let vis = max(0.45, clamp(cond_nivel, 0.0, 1.0));
    return SupCristalCapa(color, alfa * vis, destello * vis);
}
