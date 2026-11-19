// Dibujo procedural y coordenadas de panel de la lluvia en los cristales (27 v2 §Capa 1).
// Funciones puras del núcleo: no leen `frame` ni recursos del motor.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §2

struct SupCristalPlano {
    uv: vec2<f32>,          // coordenadas continuas en la cara del cristal (bloques)
    tangente: vec3<f32>,    // eje +u sobre la cara (derecha mirando la cara)
    bitangente: vec3<f32>,  // eje +v sobre la cara (+Y en caras verticales)
    vertical: bool,
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

fn sup_cr_mod_i32(a: i32, m: i32) -> i32 {
    let r = a % m;
    return select(r, r + m, r < 0);
}

fn sup_cr_hash_u32(x: u32) -> u32 {
    var h = x;
    h ^= h >> 16u;
    h *= 0x7feb352du;
    h ^= h >> 15u;
    h *= 0x846ca68bu;
    h ^= h >> 16u;
    return h;
}

// Índice cardinal 0..3 de una cara vertical: 0 Norte (-Z), 1 Sur (+Z), 2 Oeste (-X), 3 Este (+X).
fn sup_cristal_indice_cara(normal_cara: vec3<f32>) -> i32 {
    if abs(normal_cara.z) > 0.5 {
        return select(0, 1, normal_cara.z > 0.0);
    }
    return select(2, 3, normal_cara.x > 0.0);
}

// Coordenada entera (x, y) en la textura `cristal_clima` (512x512) para un punto de cristal.
// - Caras verticales (y=0..127): 4 paneles cardinales de 128x128 (4x4 cuadros de 32x32).
//   La columna de cuadro depende solo de (bx, bz, cara) y la fila sigue -by, de modo que una gota
//   que baja cruza sin costuras del bloque `by` al bloque `by - 1` de abajo (27 §Capa 1).
// - Cara de arriba (y=128..255): 4 paneles de 128x128 elegidos por hash del bloque.
fn sup_cristal_lluvia_texel(
    b: vec3<i32>,
    normal_cara: vec3<f32>,
    plano: SupCristalPlano,
    k_res: f32,
) -> vec2<i32> {
    let paso = select(1.0, 2.0, k_res < 0.75);
    if plano.vertical {
        let cara = sup_cristal_indice_cara(normal_cara);
        let col_pos = select(b.z, b.x, abs(normal_cara.z) > 0.5);
        let prof_pos = select(b.x, b.z, abs(normal_cara.z) > 0.5);
        let h_prof = sup_cr_hash_u32(u32(prof_pos * 83492791) ^ u32(cara * 19349663));
        let tile_x = sup_cr_mod_i32(col_pos + i32(h_prof & 3u), 4);
        let tile_y = sup_cr_mod_i32(-b.y, 4);
        let loc_u = fract(plano.uv.x);
        let loc_v = fract(plano.uv.y);
        let px = clamp(i32(floor(loc_u * 32.0 / paso) * paso), 0, 31);
        let py = clamp(31 - i32(floor(loc_v * 32.0 / paso) * paso), 0, 31);
        return vec2<i32>(cara * 128 + tile_x * 32 + px, tile_y * 32 + py);
    }
    let h_top = sup_cr_hash_u32(u32((b.x >> 2) * 73856093) ^ u32((b.z >> 2) * 83492791) ^ u32(b.y * 19349663));
    let panel = i32(h_top & 3u);
    let tile_x = sup_cr_mod_i32(b.x, 4);
    let tile_y = sup_cr_mod_i32(b.z, 4);
    let px = clamp(i32(floor(fract(plano.uv.x) * 32.0 / paso) * paso), 0, 31);
    let py = clamp(i32(floor(fract(plano.uv.y) * 32.0 / paso) * paso), 0, 31);
    return vec2<i32>(panel * 128 + tile_x * 32 + px, 128 + tile_y * 32 + py);
}

// Distancia con envolvimiento toroidal en un panel de 128x128 texeles.
fn sup_cr_wrap_delta(d: vec2<f32>) -> vec2<f32> {
    var r = d;
    if r.x > 64.0 { r.x -= 128.0; }
    if r.x < -64.0 { r.x += 128.0; }
    if r.y > 64.0 { r.y -= 128.0; }
    if r.y < -64.0 { r.y += 128.0; }
    return r;
}

// Evalúa la contribución de una gota sobre el texel `(px, py)` del panel 128x128.
// Devuelve vec4(tono, alfa, pendiente_x, pendiente_y):
//   tono: 0.0 sombra, 0.5 cuerpo, 1.0 brillo; alfa: 0 si fuera de la gota.
// Sigue exactamente 27 §Capa 1 «Dibujo de cada gota» y «Modo regueros».
fn sup_cristal_dibujar_gota(
    p_tx: vec2<f32>,
    centro: vec2<f32>,
    tamano: f32,
    vy: f32,
    pace: f32,
    semilla: f32,
    es_reguero: bool,
) -> vec4<f32> {
    let delta = sup_cr_wrap_delta(p_tx - centro);

    // Modo regueros: cabeza de 2 texeles (brillo arriba 0,90; sombra abajo 0,75) y ancho 1 o 2.
    if es_reguero {
        let ancho = select(1.0, 2.0, tamano >= 1.5);
        let half_w = ancho * 0.5;
        if abs(delta.x) > half_w || delta.y < -1.5 || delta.y > 1.0 {
            return vec4<f32>(0.0);
        }
        if delta.y < 0.0 {
            return vec4<f32>(1.0, 0.90, -0.3, -0.5); // brillo arriba
        }
        return vec4<f32>(0.0, 0.75, 0.3, 0.5); // sombra abajo
    }

    let t = clamp(tamano, 0.8, 7.0);
    let corriendo = vy > 0.5;

    // 1) Tamaño 1: un texel de brillo (alfa 0,85) o de cuerpo (alfa 0,65).
    if t < 1.5 && !corriendo {
        if abs(delta.x) <= 0.5 && abs(delta.y) <= 0.5 {
            let es_brillo = fract(semilla * 17.31) < 0.55;
            return vec4<f32>(select(0.5, 1.0, es_brillo), select(0.65, 0.85, es_brillo), 0.0, 0.0);
        }
        return vec4<f32>(0.0);
    }

    // 2) Tamaño 2: 2x2, brillo arriba y sombra abajo.
    if t < 2.5 && !corriendo {
        if delta.x >= -1.0 && delta.x < 1.0 && delta.y >= -1.0 && delta.y < 1.0 {
            let arriba = delta.y < 0.0;
            return vec4<f32>(
                select(0.0, 1.0, arriba),
                select(0.85, 0.90, arriba),
                delta.x * 0.45,
                delta.y * 0.45,
            );
        }
        return vec4<f32>(0.0);
    }

    // 3) Gota que corre: lágrima alargada de alto `t + round(0,25 * t * ritmo)`.
    // Estrecha arriba (35 % del ancho), se ensancha con un seno hasta el 65 % de su altura,
    // acaba en base elíptica redondeada y serpentea ±0,33 texeles por fila.
    if corriendo {
        let ritmo = max(pace, 0.35);
        let alto = max(t + round(0.25 * t * ritmo), t + 1.0);
        let y_top = -alto * 0.65;
        let y_bot = alto * 0.35;
        if delta.y < y_top || delta.y > y_bot {
            return vec4<f32>(0.0);
        }
        let u_y = clamp((delta.y - y_top) / max(alto, 1.0), 0.0, 1.0);
        // Serpenteo suave ±0,33 texeles por fila.
        let serpenteo = sin((p_tx.y + semilla * 19.0) * 1.15) * 0.33;
        let dx = delta.x - serpenteo;
        let radio_max = max(t * 0.48, 1.0);
        var medio_ancho: f32;
        if u_y < 0.65 {
            let s = sin((u_y / 0.65) * (MAT_PI * 0.5));
            medio_ancho = radio_max * mix(0.35, 1.0, s);
        } else {
            let e = (u_y - 0.65) / 0.35;
            medio_ancho = radio_max * sqrt(max(1.0 - e * e, 0.0));
        }
        if abs(dx) > medio_ancho {
            return vec4<f32>(0.0);
        }
        let nx = dx / max(medio_ancho, 0.25);
        let ny = (u_y - 0.55) * 1.4;
        // Brillo en el borde izquierdo (20..62 % de altura), sombra en la punta y borde derecho (>= 70 %).
        if nx < -0.35 && u_y >= 0.20 && u_y <= 0.62 {
            return vec4<f32>(1.0, 0.95, nx, ny);
        }
        if u_y >= 0.70 || (nx > 0.45 && u_y >= 0.45) {
            return vec4<f32>(0.0, 0.90, nx, ny);
        }
        return vec4<f32>(0.5, 0.60, nx, ny);
    }

    // 4) Gota quieta de tamaño 3 o más: óvalo redondeado.
    // Brillo (0,95) en el arco arriba-izquierda, cuerpo (0,60) en el centro, sombra (0,90) en borde abajo-derecha.
    let rx = t * 0.50;
    let ry = t * 0.52;
    let q = vec2<f32>(delta.x / max(rx, 0.5), delta.y / max(ry, 0.5));
    let r2 = dot(q, q);
    if r2 > 1.0 {
        return vec4<f32>(0.0);
    }
    let diag = q.x + q.y; // negativo arriba-izquierda, positivo abajo-derecha
    if r2 > 0.32 && diag < -0.25 {
        return vec4<f32>(1.0, 0.95, q.x, q.y);
    }
    if r2 > 0.42 && diag > 0.25 {
        return vec4<f32>(0.0, 0.90, q.x, q.y);
    }
    return vec4<f32>(0.5, 0.60, q.x, q.y);
}

// Convierte el texel de `cristal_clima` (r=rastro, g=tono, b=alfa_gota, a=pendiente_empaquetada)
// en color lineal de la paleta de Weather Glass (cuerpo/brillo/sombra) y alfa final.
fn sup_cristal_lluvia_color(texel: vec4<f32>, es_reguero: bool) -> vec4<f32> {
    let rastro = clamp(texel.r, 0.0, 1.0);
    let tono = clamp(texel.g, 0.0, 1.0);
    let alfa_gota = clamp(texel.b, 0.0, 1.0);

    var col = vec3<f32>(0.0);
    var alfa = 0.0;

    if rastro > 0.005 {
        // Rastro mojado: 0,12 + 0,24 * rastro en modo gotas; 0,22 + 0,40 * rastro en modo regueros.
        let a_r = select(0.12 + 0.24 * rastro, 0.22 + 0.40 * rastro, es_reguero) * smoothstep(0.0, 0.08, rastro);
        col = mix(OPC_CRISTAL_LLUVIA_CUERPO, OPC_CRISTAL_LLUVIA_BRILLO, 0.22);
        alfa = a_r;
    }

    if alfa_gota > 0.01 {
        var col_g = OPC_CRISTAL_LLUVIA_CUERPO;
        if tono > 0.75 {
            col_g = OPC_CRISTAL_LLUVIA_BRILLO;
        } else if tono < 0.25 {
            col_g = OPC_CRISTAL_LLUVIA_SOMBRA;
        }
        let a_out = alfa_gota + alfa * (1.0 - alfa_gota);
        col = (col_g * alfa_gota + col * alfa * (1.0 - alfa_gota)) / max(a_out, 1e-4);
        alfa = a_out;
    }

    return vec4<f32>(col, alfa);
}

// Empaqueta pendiente 2D [-1, 1]^2 en un f16 positivo/negativo simple (almacenado en canal .a de cristal_clima).
fn sup_cr_empaquetar_pendiente(s: vec2<f32>) -> f32 {
    let qx = clamp(floor((s.x * 0.5 + 0.5) * 15.0 + 0.5), 0.0, 15.0);
    let qy = clamp(floor((s.y * 0.5 + 0.5) * 15.0 + 0.5), 0.0, 15.0);
    return qx + qy * 16.0;
}

fn sup_cr_desempaquetar_pendiente(v: f32) -> vec2<f32> {
    let iv = u32(clamp(round(v), 0.0, 255.0));
    let qx = f32(iv & 15u) / 15.0 * 2.0 - 1.0;
    let qy = f32((iv >> 4u) & 15u) / 15.0 * 2.0 - 1.0;
    return vec2<f32>(qx, qy);
}
