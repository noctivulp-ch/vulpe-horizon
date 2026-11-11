// El tiempo atmosférico de este momento: perfil de nubes, viento y horario de la niebla, desde frame y las
// opciones. Compartido (cielo, material y post). Porqué: docs/efectos/niebla-y-nubes.md §Adaptadores

fn adp_momento(o: OpcVolumen) -> VolMomento {
    let m = adp_mod();
    let dia = select(0.0, m.dia, m.tiene_tiempo);
    return VolMomento(dia, frame.day_time, frame.rain, o.aleatorio, OPC_PERFIL_FIJO);
}

fn adp_nubes() -> VolNubes {
    let o = opc_volumen();
    let viento = OPC_VIENTO * o.viento * frame.time;
    let m = adp_momento(o);
    let s = vol_sorteo(m, OPC_TIEMPO_SECUENCIA, OPC_TIEMPO_SECUENCIA_REPITE_DESDE, OPC_TIEMPO_FUNDIDO);
    let mt = opc_estilo_tiempo();
    let mult_lluvia = select(1.0, mt.densidad_lluvia, frame.rain > 0.01);
    let pa = VolPerfil(OPC_TIEMPO_COBERTURA[min(s.a, 10u)] * mt.mult_cobertura, OPC_TIEMPO_DENSIDAD[min(s.a, 10u)] * (mt.mult_densidad * mult_lluvia));
    let pb = VolPerfil(OPC_TIEMPO_COBERTURA[min(s.b, 10u)] * mt.mult_cobertura, OPC_TIEMPO_DENSIDAD[min(s.b, 10u)] * (mt.mult_densidad * mult_lluvia));
    var perfil = vol_perfil_del_momento(m, pa, pb, s.t);
    perfil.cobertura *= o.capas;
    return VolNubes(perfil, viento, normalize(OPC_VIENTO), o.forma_nubes);
}

fn adp_horario() -> VolHorario {
    return vol_horario(frame.day_time, opc_niebla_horario_uniforme(), opc_niebla_horario_manchas(), OPC_NIEBLA_HORARIO_TRANSICION);
}

// Luz ambiente de cielo sobre una superficie horizontal, escala común: la tabla medida del cielo despejado, mezclada con
// lo que dan las nubes del momento vistas desde abajo y comprimida (Reinhard sobre la luminancia). Aproxima el «promedio
// de cielo con nubes» del original (fino/01 §1), que aquí no se integra: las nubes poco espesas al sol son mucho más
// claras que el cielo azul y neutras; las de lluvia, oscuras. Porqué: docs/efectos/luz-de-superficie.md §«Ambiente con nubes» (F-16)
fn adp_ambiente_cielo() -> vec3<f32> {
    let elev = degrees(asin(clamp(frame.sun_direction.y, -1.0, 1.0)));
    let despejado = atm_ambiente_cielo(elev);
    if !opc_volumen().nubes {
        return despejado;
    }
    let p = adp_nubes().perfil;
    // Fracción del cielo con nube y forma media, por capa, según la cobertura del perfil (fino/05 P6).
    let con_nube = smoothstep(vec3<f32>(OPC_CUBIERTO_CON_NUBE.x), vec3<f32>(OPC_CUBIERTO_CON_NUBE.y), p.cobertura);
    let media = smoothstep(vec3<f32>(OPC_CUBIERTO_MEDIA.x), vec3<f32>(OPC_CUBIERTO_MEDIA.y), p.cobertura);
    let cubierto = 1.0 - (1.0 - con_nube.x) * (1.0 - con_nube.y) * (1.0 - con_nube.z);
    let espesor = dot(media, p.densidad);
    let directa = col_luminancia(adp_irradiancia_astro(opc_cielo())) * max(frame.light_direction.y, 0.0);
    let nube = vec3<f32>(directa * exp(-OPC_CUBIERTO_EXTINCION * espesor)) + despejado * OPC_CUBIERTO_CIELO;
    let ambiente = mix(despejado, nube, cubierto);
    return ambiente / (1.0 + col_luminancia(ambiente));
}

fn adp_sombra_nubes(mundo: vec3<f32>) -> f32 {
    if !opc_volumen().nubes {
        return 1.0;
    }
    return vol_sombra_nubes(mundo, frame.light_direction, adp_nubes(), ruido2d, ruido2d_sampler);
}
