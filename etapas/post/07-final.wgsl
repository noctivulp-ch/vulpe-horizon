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
        case OPC_VISTA_AURORA_MAPA: {
            // El disco del cielo ocupa el alto de la pantalla; brillo normalizado para verlo (×1/medio del mapa).
            let lado = vec2<f32>(textureDimensions(mapa_aurora));
            let aspecto = frame.resolution.x / frame.resolution.y;
            let d = vec2<f32>((p.uv.x - 0.5) * aspecto + 0.5, p.uv.y);
            if any(d < vec2<f32>(0.0)) || any(d > vec2<f32>(1.0)) {
                return adp_post_salida(vec3<f32>(0.0), 1.0);
            }
            let m = textureLoad(mapa_aurora, vec2<i32>(d * lado), 0).rgb;
            // Lineal, con una ganancia fija: el pico del mapa (el techo del fractal) llega a ~1.
            return adp_post_salida(col_lineal_a_srgb(min(m * 600.0, vec3<f32>(1.0))), 1.0);
        }
        case OPC_VISTA_RELIEVE: {
            if p.es_cielo {
                return adp_post_salida(vec3<f32>(0.0), 1.0);
            }
            return adp_post_salida(p.color, 1.0);
        }
        case OPC_VISTA_MOD_NATIVO: {
            return adp_post_salida(adp_mod_depuracion(p.uv), 1.0);
        }
        default: {}
    }
    let o = opc_imagen();
    let gotas = adp_gotas_camara(p.uv);
    var c = img_nitidez(previous, linear_sampler, gotas.uv, nitidez);
    c = c * (1.0 - gotas.borde * 0.3);
    c = adp_bloom_final(c, gotas.uv, o);
    c = adp_estado_jugador(c, adp_post_distancia(p));
    let e = adp_exposicion(o);
    c *= e.exposicion * OPC_TONEMAP_EXPOSICION[min(o.tonemap, 2u)];
    c = col_purkinje(c, e.bastones, OPC_PURKINJE_K);
    c = col_balance_blancos(c, atm_cuerpo_negro(6500.0), atm_cuerpo_negro(opc_balance_k()));
    c = col_tonemap(c, o.tonemap, OPC_BLANCO, OPC_FILMICO_BLANCO);
    c = col_gradar(c, o.gradacion);
    c = mat_saturar3(c);
    // Rayos del fractal (14): luz de la escena tras el tonemap y antes del aislamiento de color.
    c += adp_rayos(p.uv, p.pixel, e.exposicion);
    var salida = col_lineal_a_srgb(c);
    if aislamiento_rango > 0 {
        salida = img_aislar(salida, p.uv, previous, linear_sampler, opc_aislamiento(e.exposicion));
    }
    if o.tramado {
        // Tramado triangular de ±1 nivel con dos ruidos azules.
        let t = adp_ruido_azul(p.pixel, 1u) + adp_ruido_azul(p.pixel, 2u) - 1.0;
        salida += t / 255.0;
    }
    return adp_post_salida(salida, 1.0);
}
