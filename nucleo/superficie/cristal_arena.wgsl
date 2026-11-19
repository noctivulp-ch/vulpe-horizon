// Velo fino de polvo y granos sutiles de arena tras tormenta en bioma seco, sin bandas horizontales (27 §5).
// Función pura del núcleo: no lee `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §5

struct SupCristalArena {
    cobertura: f32,         // 0..1 velo continuo de polvo + granos sutiles (más denso abajo)
    variacion: f32,         // 0..1 variación tonal suave del polvo y granos
    relieve_y: f32,         // leve inclinación difusa del polvo
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

    // Más polvo y arena en las caras que dan al viento.
    let viento_len = length(viento_xz);
    let viento_dir = select(vec2<f32>(-1.0, 0.0), viento_xz / max(viento_len, 1e-4), viento_len > 0.01);
    let viento_3d = vec3<f32>(viento_dir.x, 0.0, viento_dir.y);
    let barlovento = select(0.5, dot(normal_cara, -viento_3d), plano.vertical);
    let factor_viento = clamp(1.0 + OPC_CRISTAL_ARENA_BARLOVENTO * barlovento, 0.45, 1.40);
    let fuerza = clamp(nivel_arena * factor_viento * escala_ajuste, 0.0, 1.35);

    let uv = plano.uv;
    let texel = floor(uv * OPC_CRISTAL_REJILLA);

    // 1) Velo fino de polvo en coordenadas continuas del mundo (sin repetición ni bandas por bloque).
    // Ligeramente estirado horizontalmente por el viento para imitar polvo arrastrado sobre el cristal.
    let n_nube = rui_valor2(vec2<f32>(uv.x * 0.55, uv.y * 0.85) + vec2<f32>(2.3, 6.1));
    let n_estria = rui_valor2(vec2<f32>(uv.x * 1.9, uv.y * 3.4) + vec2<f32>(n_nube * 0.6, 1.7));
    let n_polvo = rui_valor2(uv * 11.0 + vec2<f32>(4.9, 8.3));
    let velo_base = 0.35 * n_nube + 0.40 * n_estria + 0.25 * n_polvo;

    // 2) Granos sutiles en la rejilla de 32 texeles/bloque (mezclados suavemente sobre el velo).
    let h = rui_hash33(vec3<i32>(i32(texel.x), i32(texel.y), 97));
    let grano = smoothstep(0.55, 0.96, h.x);

    var densidad = 0.0;
    var relieve_y = 0.0;

    if plano.vertical {
        // Más denso en la parte baja de cada cristal con gradiente continuo (sin franja dura ni bandas).
        let local_y = fract(uv.y);
        let peso_abajo = pow(1.0 - local_y, 2.4) * 0.42;
        let marco_solido = smoothstep(0.99, 0.80, ao_vertice);
        let grad_abajo = peso_abajo * (0.45 + 0.55 * n_nube) * mix(0.65, 1.25, marco_solido);
        let velo = (velo_base * 0.52 + grad_abajo) * OPC_CRISTAL_ARENA_VELO_MAX * fuerza;
        let aporte_grano = grano * (0.35 + 0.65 * (1.0 - local_y)) * OPC_CRISTAL_ARENA_GRANO_PESO * fuerza;
        densidad = clamp(velo + aporte_grano, 0.0, 0.72);
        relieve_y = 0.18 * densidad;
    } else {
        // Cara superior: capa fina y homogénea de polvo de arena.
        densidad = clamp((velo_base * 0.65 + grano * 0.25) * OPC_CRISTAL_ARENA_VELO_MAX * fuerza, 0.0, 0.68);
        relieve_y = 0.15 * densidad;
    }

    let variacion = mix(n_polvo, h.y, 0.35);
    return SupCristalArena(
        densidad * exp_cielo * atenuacion_dist,
        variacion,
        relieve_y * exp_cielo * atenuacion_dist,
    );
}
