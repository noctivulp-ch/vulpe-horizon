// Copos pegados en 8 tiras globales con 4 formas pixel-art y derretimiento progresivo (27 v2 §Capa 3).
// Funciones puras del núcleo: no leen `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §4

// Coordenada entera (x, y) en `cristal_clima` (512x512, filas y=256..511) para las 8 tiras globales de copos.
fn sup_cristal_copo_texel(
    b: vec3<i32>,
    normal_cara: vec3<f32>,
    plano: SupCristalPlano,
    k_res: f32,
) -> vec2<i32> {
    let paso = select(1.0, 2.0, k_res < 0.75);
    let cara = sup_cristal_indice_cara(normal_cara);
    let h = sup_cr_hash_u32(
        u32(b.x * 374761393) ^ u32(b.y * 668265263) ^ u32(b.z * 2147483647) ^ u32(cara * 1597334677),
    );
    let tira = i32(h & 7u);
    let tile_x = i32((h >> 3u) & 3u);
    let tile_y = i32((h >> 5u) & 3u);

    let local = fract(plano.uv);
    let lx = clamp(i32(floor(local.x * 32.0 / paso) * paso), 0, 31);
    let ly = clamp(i32(floor((1.0 - local.y) * 32.0 / paso) * paso), 0, 31);

    let ox = (tira & 3) * 128;
    let oy = 256 + (tira >> 2) * 128;
    return vec2<i32>(ox + tile_x * 32 + lx, oy + tile_y * 32 + ly);
}

// Dibuja una de las 4 formas exactas de copo pegado (27 v2 §Capa 3):
//   1: punto 1x1 blanco (alfa 0,90)
//   2: pareja diagonal 2 texeles, blanco (0,90) y suave (236,250,251) (0,75)
//   3: cruz 3x3, centro blanco (0,95) y brazos blancos (0,80)
//   4: estrella 5x5, cruz interior blanca (0,95 / 0,85), puntas y diagonales azul hielo (188,214,255) (0,70 / 0,60)
// Devuelve vec4(color.rgb, alfa) en luz lineal.
fn sup_cristal_dibujar_copo(
    p_tx: vec2<f32>,
    centro: vec2<f32>,
    forma_raw: u32,
    escala_alfa: f32,
    reducido: bool,
) -> vec4<f32> {
    let delta = sup_cr_wrap_delta(p_tx - centro);
    let dx = i32(round(delta.x));
    let dy = i32(round(delta.y));
    let adx = abs(dx);
    let ady = abs(dy);
    if adx > 2 || ady > 2 {
        return vec4<f32>(0.0);
    }

    var forma = forma_raw;
    if reducido {
        // En el último 25 % de vida el copo se reduce a un punto o una pareja diagonal.
        if forma >= 3u {
            forma = 2u;
        } else {
            forma = 1u;
        }
    }

    if forma == 1u {
        if adx == 0 && ady == 0 {
            return vec4<f32>(OPC_CRISTAL_COPO_BLANCO, 0.90 * escala_alfa);
        }
        return vec4<f32>(0.0);
    }

    if forma == 2u {
        if dx == 0 && dy == 0 {
            return vec4<f32>(OPC_CRISTAL_COPO_BLANCO, 0.90 * escala_alfa);
        }
        if dx == 1 && dy == 1 {
            return vec4<f32>(OPC_CRISTAL_COPO_SUAVE, 0.75 * escala_alfa);
        }
        return vec4<f32>(0.0);
    }

    if forma == 3u {
        if adx == 0 && ady == 0 {
            return vec4<f32>(OPC_CRISTAL_COPO_BLANCO, 0.95 * escala_alfa);
        }
        if (adx == 1 && ady == 0) || (adx == 0 && ady == 1) {
            return vec4<f32>(OPC_CRISTAL_COPO_BLANCO, 0.80 * escala_alfa);
        }
        return vec4<f32>(0.0);
    }

    // Forma 4: estrella 5x5.
    if adx == 0 && ady == 0 {
        return vec4<f32>(OPC_CRISTAL_COPO_BLANCO, 0.95 * escala_alfa);
    }
    if (adx == 1 && ady == 0) || (adx == 0 && ady == 1) {
        return vec4<f32>(OPC_CRISTAL_COPO_BLANCO, 0.85 * escala_alfa);
    }
    if (adx == 2 && ady == 0) || (adx == 0 && ady == 2) {
        return vec4<f32>(OPC_CRISTAL_COPO_HIELO, 0.70 * escala_alfa);
    }
    if adx == 1 && ady == 1 {
        return vec4<f32>(OPC_CRISTAL_COPO_HIELO, 0.60 * escala_alfa);
    }
    return vec4<f32>(0.0);
}
