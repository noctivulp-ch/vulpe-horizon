// Escarcha cristalina ramificada (dibujo de helecho) en los bordes y esquinas del cristal, rejilla de 32 (27 §2).
// Función pura del núcleo: no lee `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §2

struct SupCristalEscarcha {
    cobertura: f32,         // 0..1 densidad translúcida de escarcha
    borroso: f32,           // 0..1 cuánto emborrona lo que hay detrás
    cristalino: f32,        // 0..1 facetas brillantes del cristal de hielo
    grad_uv: vec2<f32>,     // rugosidad fina de los cristales para reflejo y brillo
}

// Ruido en cresta 2D para formar ramas finas de helecho helado.
fn sup_cristal_cresta(p: vec2<f32>) -> f32 {
    let n = rui_valor2(p);
    return 1.0 - abs(n * 2.0 - 1.0);
}

// Evalúa la escarcha desde bordes y esquinas con ramas tipo helecho en la rejilla de 32 texeles/bloque.
// Combina una variación orgánica de gran escala (varios bloques) con ramificaciones finas para no dibujar
// un marco grueso y repetitivo alrededor de cada bloque individual.
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

    // Rejilla de 32 texeles/bloque suavizada de muy cerca para evitar cuadrados gigantes al acercarse a < 1 bloque.
    let texel = floor(plano.uv * OPC_CRISTAL_REJILLA);
    let uv_q = (texel + 0.5) / OPC_CRISTAL_REJILLA;
    let mezcla_cerca = smoothstep(0.6, 2.2, distancia);
    let uv_m = mix(plano.uv, uv_q, mezcla_cerca);

    // Distancia al borde y a las esquinas de la cara.
    let local = fract(uv_m);
    let dist_x = min(local.x, 1.0 - local.x);
    let dist_y = min(local.y, 1.0 - local.y);
    let dist_borde = min(dist_x, dist_y);
    let dist_esquina = length(vec2<f32>(dist_x, dist_y));

    // Perímetro junto a marco sólido (si vanilla da AO) + variación orgánica multiblque para romper la cuadrícula.
    let marco_solido = smoothstep(0.99, 0.80, ao_vertice);
    let escala_grande = rui_valor2(uv_m * 0.42 + vec2<f32>(3.1, 7.4));
    let peso_borde = mix(OPC_CRISTAL_ESCARCHA_JUNTA_PESO + 0.42 * escala_grande, 1.0, marco_solido);

    // Crecimiento delicado desde bordes y esquinas, dejando el centro despejado y translúcido.
    let prox_borde = 1.0 - smoothstep(0.0, OPC_CRISTAL_ESCARCHA_ALCANCE * peso_borde, dist_borde);
    let prox_esquina = 1.0 - smoothstep(0.0, OPC_CRISTAL_ESCARCHA_ESQUINA * peso_borde, dist_esquina);
    // Velo muy tenue de cristales sueltos en zonas orgánicas frías del conjunto.
    let mancha_fria = smoothstep(0.58, 0.92, escala_grande) * 0.30;
    let perfil = max(max(prox_borde * 0.85, prox_esquina), mancha_fria);

    // Cristales ramificados (helecho helado): dos ejes girados y tres frecuencias en la rejilla de 32.
    let rot_a = vec2<f32>(uv_m.x + uv_m.y, uv_m.x - uv_m.y);
    let rot_b = vec2<f32>(uv_m.x * 0.866 + uv_m.y * 0.5, -uv_m.x * 0.5 + uv_m.y * 0.866);
    let tronco = sup_cristal_cresta(rot_a * 5.0 + vec2<f32>(1.7, 4.3));
    let ramas = sup_cristal_cresta(rot_b * 12.0 + vec2<f32>(tronco * 1.15, -tronco * 0.95));
    let agujas = sup_cristal_cresta(rot_a * 24.0 + vec2<f32>(ramas * 0.85, tronco * 0.65));
    let helecho = tronco * 0.40 + ramas * 0.36 + agujas * 0.24;

    let fuerza = clamp(escarcha_nivel * exposicion * escala_ajuste, 0.0, 1.35);
    let umbral = mix(0.92, 0.38, clamp(perfil * fuerza, 0.0, 1.0));
    let filigrana = smoothstep(umbral - 0.16, umbral + 0.16, helecho);
    let cobertura = filigrana * (0.28 + 0.72 * perfil) * clamp(fuerza, 0.0, 1.0) * atenuacion_dist;
    if cobertura <= 0.002 {
        return vacio;
    }

    // Facetas cristalinas en la rejilla de 32 para destellos de luz (sol, luna, antorchas).
    let h = rui_hash33(vec3<i32>(i32(texel.x), i32(texel.y), 53));
    let cristalino = smoothstep(0.62, 0.95, h.x) * cobertura;
    let grad = (h.yz - 0.5) * (0.65 * cobertura);
    let borroso = smoothstep(0.05, 0.55, cobertura);

    return SupCristalEscarcha(cobertura, borroso, cristalino, grad);
}
