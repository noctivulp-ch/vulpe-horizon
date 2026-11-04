// WeatherInput → la luz que recibe una gota o un copo (cielo, sol con su fase y su sombra, antorcha), atenuada por
// la niebla del momento, y la salida codificada (ADR 0004). Solo en la etapa weather.
// Porqué: docs/efectos/lluvia-y-nieve.md
fn adp_clima(input: WeatherInput) -> vec4<f32> {
    let c = opc_cielo();
    let o = opc_luz();
    let dist = length(input.position);
    let vista = input.position / max(dist, 1e-3);
    // Cielo (gris con la lluvia, como en 03) y sol con su sombra del mapa.
    var cielo = adp_cielo_medio(c) * OPC_LUZ_CIELO_BASE;
    cielo = mix(cielo, vec3<f32>(col_luminancia(cielo)) * 0.8, clamp(frame.rain, 0.0, 1.0));
    // La etapa weather no tiene el mapa de sombras (ni shadow_position, en contra de la referencia): sombra
    // aproximada por la luz de cielo de Minecraft, como más allá del mapa en 04.
    let sombra = smoothstep(0.86, 0.97, input.light.y);
    let cos_l = dot(vista, frame.light_direction);
    let fase = select(vol_hg(cos_l, 0.75), vol_hg(cos_l, 0.1), input.snow) * 4.0 * MAT_PI;
    let sol = adp_irradiancia_astro(c) / MAT_PI * sombra * fase * input.light.y;
    let bloque = o.bloque_color * luz_curva_bloque(input.light.x) * OPC_LUZ_BLOQUE * o.bloque;
    var luz = (cielo * luz_curva_cielo(input.light.y) + sol + bloque) * OPC_LLUVIA_ACLARADO;
    var alfa = input.color.a * clima_opacidad * select(OPC_LLUVIA_OPACIDAD, OPC_NIEVE_OPACIDAD, input.snow);
    if input.snow {
        luz *= col_luminancia(input.color.rgb) * 1.2;
    }
    // La niebla de post no ve las cortinas (no escriben profundidad): se atenúan aquí con la niebla uniforme del
    // momento y la distancia.
    let h = vol_horario(frame.day_time);
    let sigma = (h.uniforme + frame.rain * 0.5) * VOL_NIEBLA_SIGMA * opc_volumen().cantidad + 0.004;
    alfa *= exp(-sigma * dist);
    return vec4<f32>(col_codificar_escena(luz, adp_codificacion()), clamp(alfa, 0.0, 1.0));
}
