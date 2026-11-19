// Arena acumulada tras tormenta en bioma seco (desierto, sabana, mesa), rejilla de 32 (27 §5).
// Función pura del núcleo: no lee `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §5

struct SupCristalArena {
    cobertura: f32,         // 0..1 cobertura opaca de granos y acumulación
    variacion: f32,         // 0..1 variación tonal por grano en la rejilla de 32
    relieve_y: f32,         // leve inclinación del montículo inferior
}

fn sup_cristal_arena(
    plano: SupCristalPlano,
    normal_cara: vec3<f32>,
    luz_cielo: f32,
    ao_vertice: f32,
    viento_xz: vec2<f32>,
    nivel_arena: f32,
    escala_ajuste: f32,
    distancia: f32,
) -> SupCristalArena {
    let vacio = SupCristalArena(0.0, 0.5, 0.0);
    if nivel_arena <= 0.005 || escala_ajuste <= 0.0 {
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

    // Más arena en las caras que dan al viento.
    let viento_len = length(viento_xz);
    let viento_dir = select(vec2<f32>(-1.0, 0.0), viento_xz / max(viento_len, 1e-4), viento_len > 0.01);
    let viento_3d = vec3<f32>(viento_dir.x, 0.0, viento_dir.y);
    let barlovento = select(0.5, dot(normal_cara, -viento_3d), plano.vertical);
    let factor_viento = clamp(1.0 + OPC_CRISTAL_ARENA_BARLOVENTO * barlovento, 0.45, 1.45);
    let fuerza = clamp(nivel_arena * factor_viento * escala_ajuste, 0.0, 1.4);

    let h = rui_hash33(vec3<i32>(i32(texel.x), i32(texel.y), 97));
    let local = fract(uv_q);
    let dist_x = min(local.x, 1.0 - local.x);
    let dist_y = min(local.y, 1.0 - local.y);
    let dist_borde = min(dist_x, dist_y);
    let marco_solido = smoothstep(0.99, 0.80, ao_vertice);

    var cobertura = 0.0;
    var relieve_y = 0.0;

    if plano.vertical {
        // 1) Acumulación principal en la parte de abajo de la cara (más gruesa sobre marco/alféizar).
        let y_tex = local.y * OPC_CRISTAL_REJILLA;
        let duna = rui_valor2(vec2<f32>(uv_q.x * 4.5, floor(uv_q.y) * 2.1 + 3.7));
        let peso_base = mix(0.55, 1.0, marco_solido);
        let altura_base = mix(OPC_CRISTAL_ARENA_BASE_MIN, OPC_CRISTAL_ARENA_BASE_MAX, duna) * fuerza * peso_base;
        if y_tex < altura_base {
            cobertura = 1.0;
            relieve_y = 0.35 * (1.0 - y_tex / max(altura_base, 1.0));
        }

        // 2) Granos dispersos subiendo desde abajo y pegados al marco (menos hacia arriba).
        let peso_abajo = pow(1.0 - local.y, 2.2) * 0.72;
        let peso_marco = (1.0 - smoothstep(0.0, OPC_CRISTAL_ARENA_MARCO * mix(0.45, 1.0, marco_solido), dist_borde)) * 0.55;
        let prob_grano = clamp(max(peso_abajo, peso_marco) * fuerza, 0.0, 0.92);
        if h.x < prob_grano {
            cobertura = 1.0;
        }
    } else {
        // Cara superior: capa polvorienta de granos de arena en la rejilla de 32.
        let n = rui_valor2(uv_q * 3.2 + vec2<f32>(1.4, 8.2));
        let prob = clamp((0.25 + 0.65 * n) * fuerza, 0.0, 0.95);
        if h.x < prob {
            cobertura = 1.0;
            relieve_y = 0.2;
        }
    }

    return SupCristalArena(cobertura * exp_cielo * atenuacion_dist, h.y, relieve_y * exp_cielo * atenuacion_dist);
}
