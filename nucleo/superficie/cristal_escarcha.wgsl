// Escarcha cristalina ramificada (dibujo de helecho) en los bordes y esquinas del cristal, rejilla de 32 (27 §2).
// Función pura del núcleo: no lee `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §2

struct SupCristalEscarcha {
    cobertura: f32,         // 0..1 densidad de escarcha en este texel de 32
    borroso: f32,           // 0..1 cuánto emborrona lo que hay detrás
    cristalino: f32,        // 0..1 facetas brillantes del cristal de hielo
    grad_uv: vec2<f32>,     // rugosidad fina de los cristales para la luz
}

// Ruido en cresta 2D en espacio de mundo cuantizado a 32 texeles/bloque para formar ramas de helecho.
fn sup_cristal_cresta(p: vec2<f32>) -> f32 {
    let n = rui_valor2(p);
    return 1.0 - abs(n * 2.0 - 1.0);
}

// Evalúa la escarcha desde bordes y esquinas con ramas tipo helecho en la rejilla de 32 texeles/bloque.
// `ao_vertice` permite distinguir el perímetro junto a bloques sólidos (AO < 1) de las juntas interiores entre
// cristales (AO ≈ 1), haciendo la escarcha más fina en las juntas para no dibujar una cuadrícula.
fn sup_cristal_escarcha(
    plano: SupCristalPlano,
    luz_cielo: f32,
    ao_vertice: f32,
    escarcha_nivel: f32,
    escala_ajuste: f32,
    escarcha_interior: bool,
    distancia: f32,
) -> SupCristalEscarcha {
    let vacio = SupCristalEscarcha(0.0, 0.0, 0.0, vec2<f32>(0.0));
    if escarcha_nivel <= 0.005 || escala_ajuste <= 0.0 {
        return vacio;
    }

    // Exposición exterior (luz de cielo >= 11/15); opcionalmente también por dentro en ventanas con algo de cielo.
    let exp_ext = smoothstep(OPC_CRISTAL_ESCARCHA_CIELO_MIN, OPC_CRISTAL_ESCARCHA_CIELO_MAX, luz_cielo);
    let exp_int = select(0.0, smoothstep(0.22, 0.55, luz_cielo) * OPC_CRISTAL_ESCARCHA_INT_PESO, escarcha_interior);
    let exposicion = max(exp_ext, exp_int);
    if exposicion <= 0.001 {
        return vacio;
    }
    let atenuacion_dist = 1.0 - smoothstep(OPC_CRISTAL_DIST_INICIO, OPC_CRISTAL_DIST_FIN, distancia);
    if atenuacion_dist <= 0.001 {
        return vacio;
    }

    // Cuantización al centro de cada texel de la rejilla de 32 × 32 por bloque.
    let texel = floor(plano.uv * OPC_CRISTAL_REJILLA);
    let uv_q = (texel + 0.5) / OPC_CRISTAL_REJILLA;

    // Coordenadas locales dentro de la cara de bloque (0..1) y distancia a bordes y esquinas.
    let local = fract(uv_q);
    let dist_x = min(local.x, 1.0 - local.x);
    let dist_y = min(local.y, 1.0 - local.y);
    let dist_borde = min(dist_x, dist_y);
    let dist_esquina = length(vec2<f32>(dist_x, dist_y));

    // Perímetro junto a marco sólido (AO reducido) frente a junta interior entre dos bloques de cristal (AO ≈ 1).
    let marco_solido = smoothstep(0.99, 0.78, ao_vertice);
    // Modulación orgánica de gran escala (varios bloques) para romper cualquier cuadrícula repetitiva.
    let escala_grande = rui_valor2(uv_q * 0.55 + vec2<f32>(3.1, 7.4));
    let peso_borde = mix(OPC_CRISTAL_ESCARCHA_JUNTA_PESO + 0.25 * escala_grande, 1.0, marco_solido);

    // Proximidad efectiva: más gruesa en las esquinas y en los bordes exteriores.
    let prox_borde = 1.0 - smoothstep(0.0, OPC_CRISTAL_ESCARCHA_ALCANCE * peso_borde, dist_borde);
    let prox_esquina = 1.0 - smoothstep(0.0, OPC_CRISTAL_ESCARCHA_ESQUINA * (0.55 + 0.45 * peso_borde), dist_esquina);
    let perfil = max(prox_borde, prox_esquina * 1.15);

    // Dibujo de cristales ramificados (helecho): ejes girados ±45° con dos frecuencias de crestas.
    let rot_a = vec2<f32>(uv_q.x + uv_q.y, uv_q.x - uv_q.y);
    let rot_b = vec2<f32>(uv_q.x * 0.866 + uv_q.y * 0.5, -uv_q.x * 0.5 + uv_q.y * 0.866);
    let tronco = sup_cristal_cresta(rot_a * 4.5 + vec2<f32>(1.7, 4.3));
    let ramas = sup_cristal_cresta(rot_b * 11.0 + vec2<f32>(tronco * 1.1, -tronco * 0.9));
    let agujas = sup_cristal_cresta(rot_a * 22.0 + vec2<f32>(ramas * 0.8, tronco * 0.6));
    let helecho = tronco * 0.45 + ramas * 0.35 + agujas * 0.20;

    let fuerza = clamp(escarcha_nivel * exposicion * escala_ajuste, 0.0, 1.4);
    let umbral = mix(0.95, 0.26, clamp(perfil * fuerza, 0.0, 1.0));
    let cobertura = smoothstep(umbral - 0.14, umbral + 0.12, helecho) * clamp(fuerza, 0.0, 1.0) * atenuacion_dist;
    if cobertura <= 0.001 {
        return vacio;
    }

    // Facetas cristalinas en la rejilla de 32 y pendiente fina para dispersión de luz.
    let h = rui_hash33(vec3<i32>(i32(texel.x), i32(texel.y), 53));
    let cristalino = smoothstep(0.72, 0.96, h.x) * cobertura;
    let grad = (h.yz - 0.5) * (0.55 * cobertura);
    let borroso = smoothstep(0.08, 0.65, cobertura);

    return SupCristalEscarcha(cobertura, borroso, cristalino, grad);
}
