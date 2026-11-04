// El tiempo atmosférico de este momento: perfil de nubes, viento y horario de la niebla, desde frame y las
// opciones. Compartido (cielo, material y post). Porqué: docs/efectos/niebla-y-nubes.md §Adaptadores

fn adp_momento(o: OpcVolumen) -> VolMomento {
    let con_mod = frame.mods[0].x > 0.5;
    let dia = select(0.0, floor(frame.mods[0].z), con_mod);
    return VolMomento(dia, frame.day_time, frame.rain, o.aleatorio, OPC_PERFIL_FIJO);
}

fn adp_nubes() -> VolNubes {
    let o = opc_volumen();
    let viento = OPC_VIENTO * o.viento * frame.time;
    let m = adp_momento(o);
    let s = vol_sorteo(m, OPC_TIEMPO_SECUENCIA, OPC_TIEMPO_SECUENCIA_REPITE_DESDE, OPC_TIEMPO_FUNDIDO);
    let pa = VolPerfil(OPC_TIEMPO_COBERTURA[min(s.a, 10u)], OPC_TIEMPO_DENSIDAD[min(s.a, 10u)]);
    let pb = VolPerfil(OPC_TIEMPO_COBERTURA[min(s.b, 10u)], OPC_TIEMPO_DENSIDAD[min(s.b, 10u)]);
    var perfil = vol_perfil_del_momento(m, pa, pb, s.t);
    perfil.cobertura *= o.capas;
    return VolNubes(perfil, viento, normalize(OPC_VIENTO), o.forma_nubes);
}

fn adp_horario() -> VolHorario {
    return vol_horario(frame.day_time, OPC_NIEBLA_HORARIO_UNIFORME, OPC_NIEBLA_HORARIO_MANCHAS, OPC_NIEBLA_HORARIO_TRANSICION);
}

fn adp_sombra_nubes(mundo: vec3<f32>) -> f32 {
    if !opc_volumen().nubes {
        return 1.0;
    }
    return vol_sombra_nubes(mundo, frame.light_direction, adp_nubes(), ruido2d, ruido2d_sampler);
}
