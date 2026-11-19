// Copos pegados (1–2 texeles) y montón inferior de nieve (4–6 texeles) en cristales, rejilla de 32 (27 §3).
// Función pura del núcleo: no lee `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §3

struct SupCristalNieve {
    copo: f32,              // 0..1 copo suelto pegado (1–2 texeles)
    monton: f32,            // 0..1 franja acumulada abajo (4–6 texeles)
    cobertura: f32,         // max(copo, monton)
    relieve_y: f32,         // inclinación suave del montón hacia arriba
}

fn sup_cristal_nieve(
    plano: SupCristalPlano,
    normal_cara: vec3<f32>,
    luz_cielo: f32,
    ao_vertice: f32,
    viento_xz: vec2<f32>,
    tiempo: f32,
    nivel_copos: f32,
    nivel_monton: f32,
    escala_ajuste: f32,
    distancia: f32,
) -> SupCristalNieve {
    let vacio = SupCristalNieve(0.0, 0.0, 0.0, 0.0);
    if (nivel_copos <= 0.005 && nivel_monton <= 0.005) || escala_ajuste <= 0.0 {
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

    let texel = floor(plano.uv * OPC_CRISTAL_REJILLA);
    let uv_q = (texel + 0.5) / OPC_CRISTAL_REJILLA;

    // Barlovento recibe más copos pegados.
    let viento_len = length(viento_xz);
    let viento_dir = select(vec2<f32>(-1.0, 0.0), viento_xz / max(viento_len, 1e-4), viento_len > 0.01);
    let viento_3d = vec3<f32>(viento_dir.x, 0.0, viento_dir.y);
    let barlovento = select(0.6, dot(normal_cara, -viento_3d), plano.vertical);
    let factor_viento = clamp(1.0 + 0.35 * barlovento, 0.45, 1.35);

    // 1) Copos sueltos (1–2 texeles) en celdas de 4×4 texeles (= 8 celdas por bloque).
    var copo = 0.0;
    if nivel_copos > 0.005 {
        // Cambio lento por bloques de tiempo para que vayan pegándose y cayendo poco a poco.
        let ciclo = floor(tiempo * 0.12);
        let celda = floor(uv_q * 8.0);
        let h = rui_hash33(vec3<i32>(i32(celda.x), i32(celda.y), i32(ciclo) + 71));
        let densidad = clamp(0.32 * nivel_copos * factor_viento * escala_ajuste, 0.0, 0.78);
        if h.x < densidad {
            // Al parar de nevar (`nivel_copos` baja), los copos se van desprendiendo según su umbral.
            let retenido = smoothstep(0.0, 0.15, nivel_copos - h.z * 0.85);
            if retenido > 0.01 {
                let centro = vec2<f32>(0.25 + 0.5 * h.y, 0.25 + 0.5 * fract(h.z * 11.7));
                // Radio de 0,6 a 1,15 texeles -> copos de 1 a 2 texeles en la rejilla de 32.
                let r_tex = 0.58 + 0.58 * fract(h.x * 19.3);
                let r_celda = (r_tex / OPC_CRISTAL_REJILLA) * 8.0;
                let dq = (fract(uv_q * 8.0) - centro) / max(r_celda, 1e-4);
                // Forma ligeramente en cruz/diamante (norma L1+L2) para recordar a un copo pixel art.
                let d_copo = mix(length(dq), abs(dq.x) + abs(dq.y), 0.35);
                if d_copo <= 1.0 {
                    copo = retenido;
                }
            }
        }
    }

    // 2) Montón inferior de nieve en caras verticales (4–6 texeles de alto) y capa fina arriba.
    var monton = 0.0;
    var relieve_y = 0.0;
    if nivel_monton > 0.005 {
        if plano.vertical {
            let local_y = fract(uv_q.y);
            let y_tex = local_y * OPC_CRISTAL_REJILLA;
            let ondulacion = rui_valor2(vec2<f32>(uv_q.x * 3.5, floor(uv_q.y) * 1.7 + 9.3));
            let repisa = mix(OPC_CRISTAL_NIEVE_JUNTA_PESO, 1.0, smoothstep(0.99, 0.80, ao_vertice));
            let altura_tex = mix(OPC_CRISTAL_NIEVE_MONTON_MIN, OPC_CRISTAL_NIEVE_MONTON_MAX, ondulacion)
                           * nivel_monton * clamp(escala_ajuste, 0.0, 1.35) * repisa;
            if y_tex < altura_tex {
                monton = smoothstep(altura_tex, max(altura_tex - 1.2, 0.0), y_tex);
                relieve_y = 0.45 * (1.0 - y_tex / max(altura_tex, 1.0));
            }
        } else {
            // Cara superior (techo de cristal): polvo de nieve acumulado en manchas en la rejilla de 32.
            let n = rui_valor2(uv_q * 3.0 + vec2<f32>(5.2, 2.7));
            let umbral = 1.0 - clamp(nivel_monton * 0.65 * escala_ajuste, 0.0, 0.85);
            monton = smoothstep(umbral, umbral + 0.15, n);
            relieve_y = 0.25 * monton;
        }
    }

    let c = copo * exp_cielo * atenuacion_dist;
    let m = monton * exp_cielo * atenuacion_dist;
    return SupCristalNieve(c, m, max(c, m), relieve_y * exp_cielo * atenuacion_dist);
}
