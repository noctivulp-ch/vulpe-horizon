// ¿Se ve aquí el marco o un brillo del cristal transparente? Lo dibuja [material] en la pasada translúcida, sin
// `set_surface`, y el resto de la ventana (el cuerpo, dibujado por el DDA de `06-taa`) deja ver el terreno de detrás.
// Mismo interruptor que el DDA: solo cuando la caché de cristales está al día. Porqué:
// docs/efectos/aislamiento-de-color.md §«Marco y brillos del cristal transparente (F-102)»
fn adp_aislamiento_cristal_claro(texel: vec2<i32>) -> bool {
    if !OPC_CRISTAL_ACTIVO || !adp_es_superficie() || frame.has_ray_tracing == 0u {
        return false;
    }
    let resumen = cristal_sim[ADP_CS_RESUMEN];
    if resumen.z < 0.5 || resumen.y < 0.5 {
        return false;
    }
    let d = textureLoad(scene_depth, texel, 0);
    if d <= 0.0 {
        return false;
    }
    let pos = view_position((vec2<f32>(texel) + 0.5) / frame.resolution, d);
    let punto = frame.camera_position + pos;
    let dir = normalize(pos);
    let cam_b = vec3<i32>(floor(frame.camera_position));
    let mascara = ADP_CM_BIT_VALIDO | ADP_CM_BIT_ES_CRISTAL | ADP_CM_BIT_CLARO;
    // Un poco más allá de la superficie vista, por cada eje por separado: en el borde de la ventana el paso en diagonal
    // cae en el bloque de al lado (el muro) y dejaba una línea de un píxel con el matiz de la imagen.
    for (var k = 0; k < 3; k++) {
        var paso = vec3<f32>(0.0);
        paso[k] = select(-0.02, 0.02, dir[k] >= 0.0);
        let b = vec3<i32>(floor(punto + paso));
        let rel = b - cam_b;
        if abs(rel.x) >= (ADP_CM_SX / 2) || abs(rel.y) >= (ADP_CM_SY / 2) || abs(rel.z) >= (ADP_CM_SZ / 2) {
            continue;
        }
        let idx = adp_cm_indice(b);
        if (cristal_mapa[idx] & mascara) == mascara && ((cristal_mapa[idx + 1u] >> 24u) & 255u) == adp_cm_firma_bloque(b) {
            return true;
        }
    }
    return false;
}

// Matiz y saturación de la superficie antes de la luz en un píxel: z = 1 si se conoce (terreno sólido, o el marco del
// cristal transparente, que es incoloro), 0 si hay que usar el de la imagen.
fn adp_aislamiento_superficie(texel: vec2<i32>) -> vec3<f32> {
    let s = surface_at(texel);
    if s.present {
        return vec3<f32>(sup_desempaquetar_suavidad(s.smoothness).yz, 1.0);
    }
    if adp_aislamiento_cristal_claro(texel) {
        return vec3<f32>(0.0, 0.0, 1.0);
    }
    return vec3<f32>(0.0);
}

// Aislamiento de color (13): el matiz que se compara es el del color del bloque antes de la luz, que la etapa material
// guarda en la suavidad de set_surface; donde no hay terreno sólido (cielo, entidades, agua, cristal, partículas),
// el de la imagen. Así la luz de una antorcha o del cielo no mete ni saca colores del rango.
// Porqué: docs/efectos/aislamiento-de-color.md §«Color de la superficie (F-39)»
fn adp_aislamiento_hs(uv: vec2<f32>, a: ImgAislamiento) -> vec2<f32> {
    let s = adp_aislamiento_superficie(vec2<i32>(uv * frame.resolution));
    if s.z > 0.5 {
        return s.xy;
    }
    return sup_matiz_sat(img_aislamiento_muestra(historial, linear_sampler, uv, a));
}

fn adp_aislar(color: vec3<f32>, uv: vec2<f32>, a: ImgAislamiento) -> vec3<f32> {
    var hs = sup_matiz_sat(color);
    let centro = adp_aislamiento_superficie(vec2<i32>(uv * frame.resolution));
    let conocida = centro.z > 0.5;
    if conocida {
        hs = centro.xy;
    }
    var m = img_pertenece_hs(hs, a);
    // Freno con el matiz de la imagen, con margen amplio: solo saca del rango, nunca mete. Bajo el agua la luz es azul y los
    // bloques rojizos del fondo (tierra, arcilla) salían azul saturado, realzados (F-60).
    // Porqué: docs/efectos/aislamiento-de-color.md §«Bajo el agua (F-60)»
    if conocida {
        var ancho = a;
        ancho.rango = a.rango + OPC_AISLAMIENTO_MARGEN_IMAGEN;
        ancho.sat_minima = 0.0;
        let imagen = sup_matiz_sat(color);
        m *= mix(1.0, img_pertenece_hs(imagen, ancho), smoothstep(0.05, 0.15, imagen.y));
    }
    if a.tamano > 0.0 && m > 0.001 {
        let umbral = a.exigencia;
        let paso = img_aislamiento_paso(frame.resolution, a.tamano);
        var acc = 0.0;
        var dens = -1.0;
        for (var i = 0; i < IMG_AISLAMIENTO_MUESTRAS; i++) {
            acc += img_pertenece_hs(adp_aislamiento_hs(uv + img_vogel(i, paso), a), a);
            if i == 7 {
                dens = img_densidad_decidida(acc, umbral);
                if dens >= 0.0 {
                    break;
                }
            }
        }
        if dens < 0.0 {
            dens = acc / f32(IMG_AISLAMIENTO_MUESTRAS);
        }
        m = img_mancha(m, dens, umbral);
    }
    return img_aislar_mezcla(color, m, a);
}
