// Última pasada post: exposición, gradación, mapeo de tonos y tramado sobre la luz lineal que deja la
// composición (ADR 0004); y las vistas de depuración.
fn post(input: PostInput) -> vec4<f32> {
    let p = adp_post_pixel(input);
    let depuracion = opc_depuracion();
    switch depuracion.vista {
        case OPC_VISTA_PROFUNDIDAD: {
            let d = adp_post_distancia(p);
            return adp_post_salida(vec3<f32>(1.0 - exp(-d / 64.0)), 1.0);
        }
        case OPC_VISTA_RUIDO: {
            let n = rui_fbm2(p.pixel / 64.0 + vec2<f32>(adp_tiempo().segundos, 0.0), rui_fbm_estandar(5));
            return adp_post_salida(vec3<f32>(n), 1.0);
        }
        case OPC_VISTA_TRAMADO: {
            return adp_post_salida(vec3<f32>(rui_tramado_ign(p.pixel)), 1.0);
        }
        default: {}
    }
    let ajustes = opc_imagen();
    let k = adp_codificacion();
    var c = p.color * k.exposicion;
    c = col_gradar(c, ajustes.gradacion);
    c = col_tonemap(c, ajustes.tonemap, k.blanco);
    var salida = col_lineal_a_srgb(c);
    if ajustes.tramado {
        // ±media unidad de 8 bits.
        salida += (rui_tramado_ign(p.pixel) - 0.5) / 255.0;
    }
    return adp_post_salida(salida, p.alfa);
}
