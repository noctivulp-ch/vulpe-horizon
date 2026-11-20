// Arena tras la tormenta en biomas secos y mesas (27 v2 §Capa 4).
// Paletas de 5 tonos (amarilla y roja), manchas bilineales de 8 texeles, granos horizontales de 1-2 texeles,
// duna sinusoidal en el borde inferior activo de la ventana entera y modo específico a 16 texeles.
// Funciones puras del núcleo: no leen `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §5

fn sup_cristal_arena_paleta(idx: u32, roja: bool) -> vec3<f32> {
    if roja {
        switch idx {
            case 0u: { return OPC_CRISTAL_ARENA_ROJA_0; }
            case 1u: { return OPC_CRISTAL_ARENA_ROJA_1; }
            case 2u: { return OPC_CRISTAL_ARENA_ROJA_2; }
            case 3u: { return OPC_CRISTAL_ARENA_ROJA_3; }
            default: { return OPC_CRISTAL_ARENA_ROJA_4; }
        }
    }
    switch idx {
        case 0u: { return OPC_CRISTAL_ARENA_0; }
        case 1u: { return OPC_CRISTAL_ARENA_1; }
        case 2u: { return OPC_CRISTAL_ARENA_2; }
        case 3u: { return OPC_CRISTAL_ARENA_3; }
        default: { return OPC_CRISTAL_ARENA_4; }
    }
}

fn sup_cristal_arena_v2(
    plano: SupCristalPlano,
    normal_cara: vec3<f32>,
    bordes: u32,
    dist_marco: vec4<f32>,
    viento_xz: vec2<f32>,
    arena_nivel: f32,
    escala_arena: f32,
    k_res: f32,
    roja: bool,
) -> SupCristalCapa {
    let vacio = SupCristalCapa(vec3<f32>(0.0), 0.0, 0.0);
    if !plano.vertical || arena_nivel <= OPC_CRISTAL_ARENA_MIN || escala_arena <= 0.001 {
        return vacio;
    }

    // Factor de viento (27 v2 §Viento): 1 - 0,3 * fuerza * (1 - hacia_la_cara), en [0,4..1].
    let fuerza_v = clamp(length(viento_xz), 0.0, 1.0);
    let v_dir = select(vec2<f32>(1.0, 0.0), viento_xz / max(fuerza_v, 1e-4), fuerza_v > 0.02);
    let hacia = clamp(dot(-vec3<f32>(v_dir.x, 0.0, v_dir.y), normal_cara), -1.0, 1.0);
    let factor_viento = clamp(1.0 - OPC_CRISTAL_ARENA_BARLOVENTO * fuerza_v * (1.0 - hacia), 0.4, 1.0);
    let a = clamp(arena_nivel * factor_viento * clamp(escala_arena, 0.0, 1.4), 0.0, 1.0);
    if a <= OPC_CRISTAL_ARENA_MIN {
        return vacio;
    }

    let k = clamp(k_res, 0.5, 2.0);
    let res = OPC_CRISTAL_REJILLA * k;
    let gx = floor(plano.uv * res);
    let tx = floor(fract(plano.uv) * res);
    let cara = u32(sup_cristal_indice_cara(normal_cara));
    let off_cara = vec2<f32>(f32(cara) * 19.7 + 2.3, f32(cara) * 11.3 + 5.1);

    let d = sup_cristal_dist_bordes_tx(tx, res, dist_marco);
    let d_min = min(min(d.x, d.y), min(d.z, d.w));
    let h_tx = rui_hash33(vec3<i32>(i32(gx.x), i32(gx.y), i32(cara) * 37 + 97));

    // Duna en la base de la ventana entera (solo si el borde inferior de la ventana está activo).
    if (bordes & 2u) != 0u {
        let esq_izq = select(0.0, exp(-tx.x / (6.0 * k)), (bordes & 4u) != 0u);
        let esq_der = select(0.0, exp(-(res - 1.0 - tx.x) / (6.0 * k)), (bordes & 8u) != 0u);
        let onda = 0.5 + 0.5 * sin(plano.uv.x * 4.7 + f32(cara) * 1.9 + 0.4 * sin(plano.uv.x * 11.3));
        let base_h = select(2.2 + 2.4 * onda, 2.0 + 3.0 * onda, k < 0.75);
        let altura = (base_h * max(k, 1.0) + 3.2 * k * max(esq_izq, esq_der)) * a;
        if tx.y < altura {
            // Sombreado de la duna con la paleta de 5 tonos (claro en la cresta, más oscuro abajo).
            let frac_h = tx.y / max(altura, 1.0);
            var tono_idx = 1u;
            if frac_h > 0.72 {
                tono_idx = select(0u, 2u, h_tx.x > 0.45);
            } else if frac_h < 0.30 {
                tono_idx = select(3u, 4u, h_tx.x > 0.55);
            } else {
                tono_idx = select(1u, 3u, h_tx.x > 0.65);
            }
            return SupCristalCapa(sup_cristal_arena_paleta(tono_idx, roja), 0.97, 0.0);
        }
    }

    // Modo 16 texeles/bloque (27 v2 §Capa 4): velo 0,16*a + bordes +0,45*a*exp(-d/2), borde irregular 0,75, 5 % granos 0,9.
    if k < 0.75 {
        let borde_irreg = d_min < (1.2 + 1.4 * rui_valor2(gx * 0.45 + off_cara)) * a;
        if borde_irreg {
            let tono_b = u32(floor(h_tx.y * 5.0)) % 5u;
            return SupCristalCapa(sup_cristal_arena_paleta(tono_b, roja), 0.75 * clamp(a * 1.1, 0.0, 1.0), 0.0);
        }
        if h_tx.x < 0.05 * a {
            let tono_g = u32(floor(h_tx.z * 5.0)) % 5u;
            return SupCristalCapa(sup_cristal_arena_paleta(tono_g, roja), 0.90, 0.0);
        }
        let op16 = clamp(0.16 * a + 0.45 * a * exp(-d_min / 2.0), 0.0, 0.75);
        let tono_v = select(0u, 1u, h_tx.y > 0.5);
        return SupCristalCapa(sup_cristal_arena_paleta(tono_v, roja), op16, 0.0);
    }

    // Modo 32 y 64 texeles/bloque:
    // 1) Manchas suaves de ruido bilineal en celdas de 8 texeles, más densas hacia abajo (y^2) y bordes activos.
    let mancha = rui_valor2(gx / (8.0 * k) + off_cara);
    let detalle = rui_valor2(gx / (3.0 * k) + off_cara * 1.7 + vec2<f32>(3.1, 7.4));
    let y_abajo = clamp(1.0 - d.y / (res * 3.0), 0.0, 1.0);
    let grad_y2 = y_abajo * y_abajo;
    let borde_peso = exp(-d_min / (5.5 * k));

    // 2) Granos sueltos de 1-2 texeles en horizontal (alfa 0,9).
    let g_par = vec2<i32>(i32(floor(gx.x * 0.5)), i32(gx.y));
    let h_par = rui_hash33(vec3<i32>(g_par.x, g_par.y, i32(cara) * 43 + 131));
    let prob_grano = (0.018 + 0.055 * grad_y2 + 0.08 * borde_peso) * a * (0.65 + 0.7 * mancha);
    if h_par.x < prob_grano * 0.65 || h_tx.x < prob_grano * 0.45 {
        let tono_g = u32(floor(h_tx.y * 5.0)) % 5u;
        return SupCristalCapa(sup_cristal_arena_paleta(tono_g, roja), 0.90, 0.0);
    }

    let op_mancha = clamp(
        (0.10 + 0.34 * mancha * (0.45 + 0.55 * grad_y2) + 0.42 * borde_peso * (0.55 + 0.45 * detalle)) * a,
        0.0,
        0.74,
    );
    if op_mancha <= 0.01 {
        return vacio;
    }
    let tono_m = u32(clamp(floor((mancha * 0.55 + detalle * 0.30 + h_tx.z * 0.15) * 5.0), 0.0, 4.0));
    return SupCristalCapa(sup_cristal_arena_paleta(tono_m, roja), op_mancha, 0.0);
}
