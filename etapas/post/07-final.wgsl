// Última pasada: bloom, exposición automática, Purkinje, balance de blancos, mapeo de tonos, gradación,
// con nitidez al principio (sobre la imagen HDR comprimida) y tramado al final (subsistemas 10 y 11); y las vistas de depuración.
// Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Orden
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
            return adp_post_salida(vec3<f32>(adp_ruido_azul(p.pixel, 0u)), 1.0);
        }
        default: {}
    }
    let o = opc_imagen();
    var c = img_nitidez(previous, linear_sampler, p.uv, OPC_NITIDEZ);
    c = adp_bloom_final(c, p.uv, o);
    c = adp_estado_jugador(c, adp_post_distancia(p));
    let e = adp_exposicion(o);
    c *= e.exposicion;
    c = col_purkinje(c, e.bastones);
    c = col_balance_blancos(c, atm_cuerpo_negro(6500.0), atm_cuerpo_negro(OPC_BALANCE_K));
    c = col_tonemap(c, o.tonemap, OPC_BLANCO);
    c = col_gradar(c, o.gradacion);
    c = mat_saturar3(c);
    var salida = col_lineal_a_srgb(c);
    if o.tramado {
        // Tramado triangular de ±1 nivel con dos ruidos azules.
        let t = adp_ruido_azul(p.pixel, 1u) + adp_ruido_azul(p.pixel, 2u) - 1.0;
        salida += t / 255.0;
    }
    return adp_post_salida(salida, 1.0);
}
