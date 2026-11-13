// Aislamiento de color (13): el matiz que se compara es el del color del bloque antes de la luz, que la etapa material
// guarda en la suavidad de set_surface; donde no hay terreno sólido (cielo, entidades, agua, cristal, partículas),
// el de la imagen. Así la luz de una antorcha o del cielo no mete ni saca colores del rango.
// Porqué: docs/efectos/aislamiento-de-color.md §«Color de la superficie (F-39)»
fn adp_aislamiento_hs(uv: vec2<f32>, a: ImgAislamiento) -> vec2<f32> {
    let s = surface_at(vec2<i32>(uv * frame.resolution));
    if s.present {
        return sup_desempaquetar_suavidad(s.smoothness).yz;
    }
    return sup_matiz_sat(img_aislamiento_muestra(previous, linear_sampler, uv, a));
}

fn adp_aislar(color: vec3<f32>, uv: vec2<f32>, a: ImgAislamiento) -> vec3<f32> {
    var hs = sup_matiz_sat(color);
    let centro = surface_at(vec2<i32>(uv * frame.resolution));
    if centro.present {
        hs = sup_desempaquetar_suavidad(centro.smoothness).yz;
    }
    var m = img_pertenece_hs(hs, a);
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
