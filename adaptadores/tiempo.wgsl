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

// Fracción de la luz ambiente de cielo que queda bajo las nubes del momento: aproxima el «promedio de cielo con nubes»
// del original (fino/01 §1), que aquí no se integra. Por capa, la fracción de cielo con nube densa (fino/05 P6) deja
// pasar exp(−k·densidad). Porqué: docs/efectos/luz-de-superficie.md §«Ambiente medido» (F-12)
fn adp_cielo_bajo_nubes() -> f32 {
    if !opc_volumen().nubes {
        return 1.0;
    }
    let p = adp_nubes().perfil;
    let densa = smoothstep(vec3<f32>(OPC_CUBIERTO_COBERTURA.x), vec3<f32>(OPC_CUBIERTO_COBERTURA.y), p.cobertura);
    let capa = 1.0 - densa * (1.0 - exp(-OPC_CUBIERTO_EXTINCION * p.densidad));
    return capa.x * capa.y * capa.z;
}

// Luz ambiente de cielo sobre una superficie horizontal, escala común: la tabla medida, filtrada por las nubes del
// momento (lo que pasa por ellas llega gris).
fn adp_ambiente_cielo() -> vec3<f32> {
    let elev = degrees(asin(clamp(frame.sun_direction.y, -1.0, 1.0)));
    let despejado = atm_ambiente_cielo(elev);
    let paso = adp_cielo_bajo_nubes();
    return mix(vec3<f32>(col_luminancia(despejado)), despejado, paso) * mix(OPC_CUBIERTO_MINIMO, 1.0, paso);
}

fn adp_sombra_nubes(mundo: vec3<f32>) -> f32 {
    if !opc_volumen().nubes {
        return 1.0;
    }
    return vol_sombra_nubes(mundo, frame.light_direction, adp_nubes(), ruido2d, ruido2d_sampler);
}
