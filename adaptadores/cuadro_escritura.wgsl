// Cálculo único por fotograma (pasada [[before_world]]): luces del terreno, tablas por elevación del sol,
// ambiente de nubes, cielo y horario. Porqué: docs/rendimiento.md

// Ganancia del ambiente de cielo de las superficies con el sol bajo, interpolada por elevación (F-54).
// Porqué: docs/efectos/luz-de-superficie.md §«Sombra y sol bajo (F-53, F-54)» › «Sol bajo (F-54)»
fn adp_sol_bajo_t(i: i32, elev: f32) -> f32 {
    return clamp((elev - OPC_LUZ_SOL_BAJO_ELEV[i - 1]) / (OPC_LUZ_SOL_BAJO_ELEV[i] - OPC_LUZ_SOL_BAJO_ELEV[i - 1]), 0.0, 1.0);
}

// x: ganancia del cielo, y: gris del cielo, z: gris del sol, interpolados por la elevación del sol.
fn adp_sol_bajo(elev: f32) -> vec3<f32> {
    var v = vec3<f32>(OPC_LUZ_SOL_BAJO_GANANCIA[0], OPC_LUZ_SOL_BAJO_GRIS[0], OPC_LUZ_SOL_BAJO_GRIS_SOL[0]);
    for (var i = 1; i < 6; i++) {
        v = mix(v, vec3<f32>(OPC_LUZ_SOL_BAJO_GANANCIA[i], OPC_LUZ_SOL_BAJO_GRIS[i], OPC_LUZ_SOL_BAJO_GRIS_SOL[i]), adp_sol_bajo_t(i, elev));
    }
    return v;
}

fn adp_hacia_gris(c: vec3<f32>, gris: f32) -> vec3<f32> {
    return mix(c, vec3<f32>(col_luminancia(c)), gris);
}

fn adp_cuadro_escribir() {
    let c = opc_cielo();
    let o = opc_luz();
    let elev_sol = degrees(asin(clamp(frame.sun_direction.y, -1.0, 1.0)));
    let nubes = adp_nubes();
    let irr_astro = adp_irradiancia_astro(c);
    let suelo_raw = adp_suelo(c);
    let cielo_medio = adp_cielo_medio(c);
    let horizonte = adp_tabla(frame.sun_direction.y, ATM_FILA_HORIZONTE) * c.sol_color;
    let despejado = adp_aplicar_crepusculo(atm_ambiente_cielo(elev_sol));

    var luces: AdpLuces;
    if !adp_es_superficie() {
        let fc = frame.fog_color;
        if frame.dimension == -1 {
            let bruma = fc / max(max(fc.r, max(fc.g, fc.b)), 1e-3);
            luces = AdpLuces(true, vec3<f32>(0.0, 1.0, 0.0), vec3<f32>(0.0), bruma * OPC_AMBIENTE_NETHER * 0.6, bruma * OPC_AMBIENTE_NETHER * 1.4);
        } else {
            let azul = vec3<f32>(0.55, 0.6, 1.0) * OPC_AMBIENTE_END;
            luces = AdpLuces(true, vec3<f32>(0.0, 1.0, 0.0), vec3<f32>(0.0), azul, azul * 0.7);
        }
    } else {
        let sol_bajo = adp_sol_bajo(elev_sol);
        let directa = adp_hacia_gris(irr_astro, sol_bajo.z);
        var amb_cielo = despejado;
        if opc_volumen().nubes && !opc_quitar(4096u) {
            let p = nubes.perfil;
            let con_nube = smoothstep(vec3<f32>(OPC_CUBIERTO_CON_NUBE.x), vec3<f32>(OPC_CUBIERTO_CON_NUBE.y), p.cobertura);
            let media = smoothstep(vec3<f32>(OPC_CUBIERTO_MEDIA.x), vec3<f32>(OPC_CUBIERTO_MEDIA.y), p.cobertura);
            let cubierto = 1.0 - (1.0 - con_nube.x) * (1.0 - con_nube.y) * (1.0 - con_nube.z);
            let espesor = dot(media, p.densidad);
            let dir_lum = col_luminancia(irr_astro) * max(frame.light_direction.y, 0.0);
            let nube = vec3<f32>(dir_lum * exp(-OPC_CUBIERTO_EXTINCION * espesor)) + despejado * OPC_CUBIERTO_CIELO;
            let ambiente = mix(despejado, nube, cubierto);
            amb_cielo = ambiente / (1.0 + col_luminancia(ambiente));
        }
        let cielo = (adp_hacia_gris(amb_cielo, sol_bajo.y) * sol_bajo.x + OPC_LUZ_NOCHE_COLOR * (OPC_LUZ_NOCHE_SUELO + OPC_LUZ_NOCHE_LUNA * adp_luna_factor_fase() * smoothstep(-0.2, 0.1, frame.moon_direction.y))) * o.cielo;
        luces = AdpLuces(false, frame.light_direction, directa, cielo, suelo_raw * o.cielo * OPC_LUZ_CIELO_BASE);
    }

    let sol = adp_luz_sol(c);
    let luna = adp_luz_luna(c);
    let crepusculo = 1.0 - smoothstep(c.venus.luna_inicio, c.venus.luna_fin, frame.sun_direction.y);
    let peso_luna = crepusculo * adp_luna_factor_fase();
    let directa_sol = atm_luz_directa_sol(elev_sol) * c.sol_color;
    let horario = adp_horario();
    let clima_obj = adp_clima_local_objetivo();
    let relampago = adp_relampago();

    datos_cuadro[ADP_CUADRO_LUZ_DIR] = vec4<f32>(luces.direccion, select(0.0, 1.0, luces.fija));
    datos_cuadro[ADP_CUADRO_LUZ_DIRECTA] = vec4<f32>(luces.directa, elev_sol);
    datos_cuadro[ADP_CUADRO_LUZ_CIELO] = vec4<f32>(luces.cielo, 0.0);
    datos_cuadro[ADP_CUADRO_LUZ_SUELO] = vec4<f32>(luces.suelo, 0.0);
    datos_cuadro[ADP_CUADRO_HORIZONTE] = vec4<f32>(horizonte, 0.0);
    datos_cuadro[ADP_CUADRO_CIELO_MEDIO] = vec4<f32>(cielo_medio, 0.0);
    datos_cuadro[ADP_CUADRO_NUBES_COB] = vec4<f32>(nubes.perfil.cobertura, 0.0);
    datos_cuadro[ADP_CUADRO_NUBES_DENS] = vec4<f32>(nubes.perfil.densidad, 0.0);
    datos_cuadro[ADP_CUADRO_VOL_CIELO] = vec4<f32>(despejado * frame.eye_light_smooth.y, 0.0);
    datos_cuadro[ADP_CUADRO_VOL_DIRECTA] = vec4<f32>(irr_astro, 0.0);
    datos_cuadro[ADP_CUADRO_SUELO_RAW] = vec4<f32>(suelo_raw, 0.0);
    datos_cuadro[ADP_CUADRO_SOL_MULT] = vec4<f32>(sol.multiple, 0.0);
    datos_cuadro[ADP_CUADRO_LUNA_MULT] = vec4<f32>(luna.multiple, peso_luna);
    datos_cuadro[ADP_CUADRO_SOL_DISCO] = vec4<f32>(directa_sol, 0.0);
    datos_cuadro[ADP_CUADRO_HORARIO] = vec4<f32>(horario.uniforme, horario.manchas, f32(clima_obj.tipo), clima_obj.peso);
    datos_cuadro[ADP_CUADRO_RELAMPAGO] = vec4<f32>(relampago.base, relampago.brillo);
}
