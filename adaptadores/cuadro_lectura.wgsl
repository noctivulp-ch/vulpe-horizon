// Lectura del buffer por fotograma (`datos_cuadro`) en las etapas que lo listan en `reads`.
// Porqué: docs/rendimiento.md

fn adp_luces_cuadro() -> AdpLuces {
    let d0 = datos_cuadro[ADP_CUADRO_LUZ_DIR];
    return AdpLuces(
        d0.w > 0.5,
        d0.xyz,
        datos_cuadro[ADP_CUADRO_LUZ_DIRECTA].xyz,
        datos_cuadro[ADP_CUADRO_LUZ_CIELO].xyz,
        datos_cuadro[ADP_CUADRO_LUZ_SUELO].xyz,
    );
}

fn adp_elev_sol_cuadro() -> f32 {
    return datos_cuadro[ADP_CUADRO_LUZ_DIRECTA].w;
}

fn adp_horizonte_cuadro() -> vec3<f32> {
    return datos_cuadro[ADP_CUADRO_HORIZONTE].xyz;
}

fn adp_cielo_medio_cuadro() -> vec3<f32> {
    return datos_cuadro[ADP_CUADRO_CIELO_MEDIO].xyz;
}

fn adp_suelo_cuadro() -> vec3<f32> {
    return datos_cuadro[ADP_CUADRO_SUELO_RAW].xyz;
}

fn adp_nubes_cuadro() -> VolNubes {
    let o = opc_volumen();
    let viento = OPC_VIENTO * o.viento * frame.time;
    let perfil = VolPerfil(datos_cuadro[ADP_CUADRO_NUBES_COB].xyz, datos_cuadro[ADP_CUADRO_NUBES_DENS].xyz);
    return VolNubes(perfil, viento, normalize(OPC_VIENTO), o.forma_nubes);
}

fn adp_sombra_nubes_cuadro(mundo: vec3<f32>) -> f32 {
    if !opc_volumen().nubes {
        return 1.0;
    }
    return vol_sombra_nubes(mundo, frame.light_direction, adp_nubes_cuadro(), ruido2d, ruido2d_sampler);
}

fn adp_luz_sol_cuadro(ajustes: OpcCielo) -> AtmLuz {
    return AtmLuz(frame.sun_direction, ATM_IRRADIANCIA_SOL * ajustes.sol_color, datos_cuadro[ADP_CUADRO_SOL_MULT].xyz);
}

fn adp_luz_luna_cuadro(ajustes: OpcCielo) -> AtmLuz {
    let m = datos_cuadro[ADP_CUADRO_LUNA_MULT];
    let color = ajustes.luna_color * (ajustes.luna_proporcion * m.w);
    return AtmLuz(frame.moon_direction, ATM_IRRADIANCIA_SOL * color, m.xyz);
}

fn adp_sol_disco_cuadro() -> vec3<f32> {
    return datos_cuadro[ADP_CUADRO_SOL_DISCO].xyz;
}

fn adp_lluvia_cuadro() -> CieLluvia {
    let bajo = vol_bajo_las_nubes(frame.camera_position.y);
    return CieLluvia(frame.rain * bajo, frame.thunder * bajo, adp_cielo_medio_cuadro());
}

fn adp_horario_cuadro() -> VolHorario {
    let h = datos_cuadro[ADP_CUADRO_HORARIO];
    return VolHorario(h.x, h.y);
}

fn adp_clima_local_cuadro() -> AdpClimaLocal {
    let h = datos_cuadro[ADP_CUADRO_HORARIO];
    return AdpClimaLocal(u32(h.z + 0.5), h.w);
}

fn adp_relampago_cuadro() -> LuzRelampago {
    let r = datos_cuadro[ADP_CUADRO_RELAMPAGO];
    return LuzRelampago(r.xyz, r.w);
}

fn adp_relampago_activo_cuadro() -> bool {
    return datos_cuadro[ADP_CUADRO_VOL_CIELO].w > 0.5;
}
