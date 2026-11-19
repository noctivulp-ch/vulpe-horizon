// Escarcha de fuera y repisa de nieve en el marco de la ventana (27 v2 §Capa 2).
// Funciones puras del núcleo: no leen `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §3

struct SupCristalCapa {
    color: vec3<f32>,       // color lineal de la capa (sin iluminar aún)
    alfa: f32,              // 0..1 opacidad
    destello: f32,          // 0..1 si el texel es destello brillante de hielo
}

// Distancia en texeles desde el texel local `tx` al marco de la ventana en las 4 direcciones
// (arriba, abajo, izquierda, derecha) usando `dist_marco` en bloques (0..7).
fn sup_cristal_dist_bordes_tx(tx: vec2<f32>, res: f32, dist_marco: vec4<f32>) -> vec4<f32> {
    let d_arr = dist_marco.x * res + (res - 1.0 - tx.y);
    let d_aba = dist_marco.y * res + tx.y;
    let d_izq = dist_marco.z * res + tx.x;
    let d_der = dist_marco.w * res + (res - 1.0 - tx.x);
    return vec4<f32>(d_arr, d_aba, d_izq, d_der);
}

// Escarcha de fuera (27 v2 §Capa 2): crece desde el marco activo de la ventana entera con `exp(-d / alcance)`,
// ruido granular de 2 octavas en grupos de 1-2 texeles, cuantizada en 3 niveles (hielo/cristal/denso) + 4 % destellos.
// También la reutiliza el estilo `cristales` del borde helado interior (27 v2 §Capa 5) con `ondulado = true`.
fn sup_cristal_escarcha_v2(
    plano: SupCristalPlano,
    dist_marco: vec4<f32>,
    escarcha_nivel: f32,
    escala_nieve: f32,
    k_res: f32,
    variante: u32,
    ondulado: bool,
    escala_alcance: f32,
) -> SupCristalCapa {
    let vacio = SupCristalCapa(vec3<f32>(0.0), 0.0, 0.0);
    if !plano.vertical || escarcha_nivel <= 0.005 || escala_nieve <= 0.001 {
        return vacio;
    }

    let k = clamp(k_res, 0.5, 2.0);
    let res = OPC_CRISTAL_REJILLA * k;
    let gx = floor(plano.uv * res);
    let tx = floor(fract(plano.uv) * res);

    var d = sup_cristal_dist_bordes_tx(tx, res, dist_marco);
    if ondulado {
        // Contorno ondulado por suma de 3 senos a lo largo de cada borde (usado por el borde interior).
        let ph = f32(variante) * 1.73;
        let ox = (sin(plano.uv.x * 6.283 + ph) * 0.50 + sin(plano.uv.x * 13.7 + ph * 1.9) * 0.30 + sin(plano.uv.x * 25.1 + ph * 0.7) * 0.20) * (1.4 * k);
        let oy = (sin(plano.uv.y * 6.283 + ph + 1.1) * 0.50 + sin(plano.uv.y * 13.7 + ph * 2.3) * 0.30 + sin(plano.uv.y * 25.1 + ph * 1.3) * 0.20) * (1.4 * k);
        d = max(d + vec4<f32>(ox, -ox, oy, -oy), vec4<f32>(0.0));
    }

    let d_min = min(min(d.x, d.y), min(d.z, d.w));
    let alcance = max(0.5, escarcha_nivel * 6.0 * k) * escala_alcance;
    // Descarte rápido para bloques interiores de una ventana grande (d_min >> alcance).
    if d_min > alcance * 3.5 {
        return vacio;
    }

    // Crecimiento acumulado desde los bordes activos de la ventana (se refuerza en las esquinas del marco).
    let g = min(
        1.35,
        exp(-d.x / alcance) + exp(-d.y / alcance) + exp(-d.z / alcance) + exp(-d.w / alcance),
    );

    // Ruido granular de 2 octavas en grupos de 1-2 texeles (sin costuras entre bloques vecinos).
    let off_v = vec2<f32>(f32(variante) * 17.3, f32(variante) * 9.1);
    let g2 = floor(gx * 0.5);
    let n_oct1 = rui_valor2(g2 * 0.85 + off_v);
    let h_tx = rui_hash33(vec3<i32>(i32(gx.x), i32(gx.y), i32(variante) * 29 + 41));
    let ruido = 0.52 + (n_oct1 * 0.65 + h_tx.x * 0.35) * 1.35;

    let intensidad = clamp(0.70 + 0.30 * escala_nieve, 0.55, 1.25);
    let val = g * ruido * intensidad;
    if val <= 0.60 {
        return vacio;
    }

    // Cuantización en 3 niveles exactos (27 v2 §Capa 2): hielo, cristal, denso.
    var color = OPC_CRISTAL_ESCARCHA_HIELO;
    var alfa = 0.45;
    if val > 1.25 {
        color = OPC_CRISTAL_ESCARCHA_DENSO;
        alfa = 0.85;
    } else if val > 0.85 {
        color = OPC_CRISTAL_ESCARCHA_CRISTAL;
        alfa = 0.65;
    }

    // Un 4 % de los texeles cubiertos son destellos blancos (alfa 0,95).
    var destello = 0.0;
    if h_tx.y < 0.04 {
        color = OPC_CRISTAL_ESCARCHA_DESTELLO;
        alfa = 0.95;
        destello = 1.0;
    }

    return SupCristalCapa(color, alfa, destello);
}

// Repisa de nieve (27 v2 §Capa 2): si el borde de abajo de la ventana está activo, franja en la base de
// alto `repisa * 3 * k` texeles, más alta en las esquinas inferiores del marco, dos tonos y alfa 0,95-0,96.
fn sup_cristal_repisa_nieve(
    plano: SupCristalPlano,
    bordes: u32,
    repisa_nivel: f32,
    escala_nieve: f32,
    k_res: f32,
) -> SupCristalCapa {
    let vacio = SupCristalCapa(vec3<f32>(0.0), 0.0, 0.0);
    if !plano.vertical || (bordes & 2u) == 0u || repisa_nivel <= 0.005 || escala_nieve <= 0.001 {
        return vacio;
    }

    let k = clamp(k_res, 0.5, 2.0);
    let res = OPC_CRISTAL_REJILLA * k;
    let gx = floor(plano.uv * res);
    let tx = floor(fract(plano.uv) * res);

    // Más alta en las esquinas inferiores activas del marco de la ventana.
    let esq_izq = select(0.0, exp(-tx.x / (5.5 * k)), (bordes & 4u) != 0u);
    let esq_der = select(0.0, exp(-(res - 1.0 - tx.x) / (5.5 * k)), (bordes & 8u) != 0u);
    let onda = 0.78 + 0.42 * rui_valor2(vec2<f32>(gx.x * (0.16 / k), 5.3));
    let altura = repisa_nivel * 3.0 * k * clamp(0.75 + 0.25 * escala_nieve, 0.6, 1.3) * (onda + 0.95 * max(esq_izq, esq_der));
    if tx.y >= altura {
        return vacio;
    }

    let h = rui_hash33(vec3<i32>(i32(gx.x), i32(gx.y), 83));
    let claro = h.x > 0.45 || tx.y >= altura - 1.0;
    let color = select(OPC_CRISTAL_REPISA_TONO_A, OPC_CRISTAL_REPISA_TONO_B, claro);
    let alfa = select(0.95, 0.96, claro);
    return SupCristalCapa(color, alfa, select(0.0, 0.25, claro));
}
