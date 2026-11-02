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
    return VolNubes(vol_perfil_del_momento(adp_momento(o)), viento);
}

fn adp_sombra_nubes(mundo: vec3<f32>) -> f32 {
    if !opc_volumen().nubes {
        return 1.0;
    }
    return vol_sombra_nubes(mundo, frame.light_direction, adp_nubes(), ruido2d, ruido2d_sampler);
}
