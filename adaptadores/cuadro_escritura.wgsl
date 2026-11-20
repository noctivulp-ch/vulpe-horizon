// Cálculo único por fotograma (pasada [[before_world]]): luces del terreno, tablas por elevación del sol,
// ambiente de nubes, cielo y horario. Porqué: docs/rendimiento.md

struct AdpCristalMod {
    activo: bool,
    es_v4: bool,
    escarcha: f32,
    repisa: f32,
    condensacion: f32,
    arena: f32,
    viento_xz: vec2<f32>,
    nivel_lluvia: u32,
    nivel_nieve: u32,
    nivel_arena: u32,
    estilo_regueros: bool,
    resolucion_cod: u32,
    seguir_viento: bool,
    interior: bool,
    borde_helado: u32,
    desenfoque: u32,
    arena_roja: bool,
    espectador: bool,
    bioma_seco: bool,
    bioma_frio: bool,
    llueve_en_bioma: bool,
    cond_opacidad: f32,
    cond_blancura: f32,
    aliento_opacidad: f32,
    aliento_blancura: f32,
    vaho_pos: vec3<f32>,
    vaho_peso: f32,
    vaho_escala: f32,
}

fn adp_cristal_mod_vacio() -> AdpCristalMod {
    return AdpCristalMod(
        false, false,
        0.0, 0.0, 0.0, 0.0,
        vec2<f32>(0.0),
        2u, 2u, 2u,
        false, 1u, true, true, 1u, 1u,
        false, false, false, false, false,
        1.0, 0.0, 1.5, 1.0,
        vec3<f32>(0.0), 0.0, 1.0,
    );
}

fn adp_mod_cristales() -> AdpCristalMod {
    let firma = frame.mods[0].x;
    let es_v4 = abs(firma - ADP_MOD_FIRMA_V4) < 0.5;
    let es_v3 = abs(firma - ADP_MOD_FIRMA_V3) < 0.5;
    if !es_v4 && !es_v3 {
        return adp_cristal_mod_vacio();
    }
    let banderas = u32(max(round(frame.mods[0].z), 0.0));
    if (banderas & 256u) == 0u {
        return adp_cristal_mod_vacio();
    }
    let m6 = frame.mods[6];
    let m7 = frame.mods[7];
    if es_v4 {
        let p0 = u32(max(round(m6.x), 0.0));
        let p1 = u32(max(round(m6.y), 0.0));
        let f24 = u32(max(round(m6.z), 0.0));
        let q4 = u32(max(round(m6.w), 0.0));
        let escarcha = f32(p0 & 255u) / 255.0;
        let repisa = f32((p0 >> 8u) & 255u) / 255.0;
        let condensacion = f32((p0 >> 16u) & 255u) / 255.0;
        let arena = f32(p1 & 255u) / 255.0;
        let vx = (f32((p1 >> 8u) & 255u) / 255.0) * 2.0 - 1.0;
        let vz = (f32((p1 >> 16u) & 255u) / 255.0) * 2.0 - 1.0;
        let cond_op = f32(q4 & 63u) / 63.0 * 2.5;
        let cond_bl = f32((q4 >> 6u) & 63u) / 63.0;
        let al_op = f32((q4 >> 12u) & 63u) / 63.0 * 2.5;
        let al_bl = f32((q4 >> 18u) & 63u) / 63.0;
        let vaho_esc = 1.0 + 0.7 * (f32((f24 >> 20u) & 15u) / 15.0);
        return AdpCristalMod(
            true, true,
            escarcha, repisa, condensacion, arena,
            vec2<f32>(vx, vz),
            f24 & 3u,
            (f24 >> 2u) & 3u,
            (f24 >> 4u) & 3u,
            (f24 & (1u << 6u)) != 0u,
            (f24 >> 7u) & 3u,
            (f24 & (1u << 9u)) != 0u,
            (f24 & (1u << 10u)) != 0u,
            (f24 >> 11u) & 3u,
            (f24 >> 13u) & 3u,
            (f24 & (1u << 15u)) != 0u,
            (f24 & (1u << 16u)) != 0u,
            (f24 & (1u << 17u)) != 0u,
            (f24 & (1u << 18u)) != 0u,
            (f24 & (1u << 19u)) != 0u,
            cond_op, cond_bl, al_op, al_bl,
            m7.xyz, clamp(m7.w, 0.0, 1.0), vaho_esc,
        );
    }
    let c_frio = u32(max(round(m6.y), 0.0));
    let c_arena = u32(max(round(m6.z), 0.0));
    let c_viento = u32(max(round(m6.w), 0.0));
    let flags12 = c_arena & 4095u;
    let vx = (f32(min(c_viento / 4096u, 4095u)) / 4095.0) * 2.0 - 1.0;
    let vz = (f32(c_viento & 4095u) / 4095.0) * 2.0 - 1.0;
    return AdpCristalMod(
        true, false,
        f32(c_frio & 255u) / 255.0,
        f32((c_frio >> 16u) & 255u) / 255.0,
        0.0,
        f32(min(c_arena / 4096u, 4095u)) / 4095.0,
        vec2<f32>(vx, vz),
        flags12 & 3u,
        (flags12 >> 2u) & 3u,
        (flags12 >> 4u) & 3u,
        false, 1u, true, true, 1u, 1u,
        (flags12 & 256u) != 0u,
        (flags12 & 512u) != 0u,
        (flags12 & 1024u) != 0u,
        (flags12 & 2048u) != 0u,
        frame.precipitation == 1u,
        1.0, 0.0, select(0.0, 1.5, (flags12 & 64u) != 0u), 1.0,
        m7.xyz, clamp(m7.w, 0.0, 1.0), 1.0,
    );
}

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
    let relampago_ant = datos_cuadro[ADP_CUADRO_RELAMPAGO].w;
    let relampago = adp_relampago();
    let relampago_activo = select(0.0, 1.0, relampago.brillo > 0.0 || relampago_ant > 0.0);

    datos_cuadro[ADP_CUADRO_LUZ_DIR] = vec4<f32>(luces.direccion, select(0.0, 1.0, luces.fija));
    datos_cuadro[ADP_CUADRO_LUZ_DIRECTA] = vec4<f32>(luces.directa, elev_sol);
    datos_cuadro[ADP_CUADRO_LUZ_CIELO] = vec4<f32>(luces.cielo, 0.0);
    datos_cuadro[ADP_CUADRO_LUZ_SUELO] = vec4<f32>(luces.suelo, 0.0);
    datos_cuadro[ADP_CUADRO_HORIZONTE] = vec4<f32>(horizonte, 0.0);
    datos_cuadro[ADP_CUADRO_CIELO_MEDIO] = vec4<f32>(cielo_medio, 0.0);
    datos_cuadro[ADP_CUADRO_NUBES_COB] = vec4<f32>(nubes.perfil.cobertura, 0.0);
    datos_cuadro[ADP_CUADRO_NUBES_DENS] = vec4<f32>(nubes.perfil.densidad, 0.0);
    datos_cuadro[ADP_CUADRO_VOL_CIELO] = vec4<f32>(despejado * frame.eye_light_smooth.y, relampago_activo);
    datos_cuadro[ADP_CUADRO_VOL_DIRECTA] = vec4<f32>(irr_astro, 0.0);
    datos_cuadro[ADP_CUADRO_SUELO_RAW] = vec4<f32>(suelo_raw, 0.0);
    datos_cuadro[ADP_CUADRO_SOL_MULT] = vec4<f32>(sol.multiple, 0.0);
    datos_cuadro[ADP_CUADRO_LUNA_MULT] = vec4<f32>(luna.multiple, peso_luna);
    datos_cuadro[ADP_CUADRO_SOL_DISCO] = vec4<f32>(directa_sol, 0.0);
    datos_cuadro[ADP_CUADRO_HORARIO] = vec4<f32>(horario.uniforme, horario.manchas, f32(clima_obj.tipo), clima_obj.peso);
    datos_cuadro[ADP_CUADRO_RELAMPAGO] = vec4<f32>(relampago.base, relampago.brillo);

    // Estado del cruce de la superficie del agua en f32 (F-73b): evita que la precisión f16 de bloom2 congele
    // las gotas tras un teletransporte y reinicia limpiamente al cambiar de dimensión. Porqué: docs/efectos/camara-y-juego.md
    let cruce_ant = datos_cuadro[ADP_CUADRO_CRUCE];
    let en_agua = frame.eye_in == 1u;
    let en_agua_f = select(0.0, 1.0, en_agua);
    let firma_dim = f32(frame.dimension) + 10.0;
    if abs(cruce_ant.w - firma_dim) > 0.5 {
        datos_cuadro[ADP_CUADRO_CRUCE] = vec4<f32>(-1.0, 0.0, en_agua_f, firma_dim);
    } else {
        let dentro_antes = cruce_ant.z > 0.5;
        let dt = max(frame.delta_time, 0.0);
        if en_agua != dentro_antes && dt > 0.0 {
            let rapidez = clamp(length(frame.camera_motion) / max(dt, 1e-3), 1.0, 16.0);
            datos_cuadro[ADP_CUADRO_CRUCE] = vec4<f32>(0.0, select(-rapidez, rapidez, !en_agua), en_agua_f, firma_dim);
        } else {
            var t_cruce = cruce_ant.x;
            var vel_cruce = cruce_ant.y;
            if t_cruce >= 0.0 {
                t_cruce += dt;
                if t_cruce >= OPC_GOTAS_DURACION {
                    t_cruce = -1.0;
                    vel_cruce = 0.0;
                }
            }
            datos_cuadro[ADP_CUADRO_CRUCE] = vec4<f32>(t_cruce, vel_cruce, en_agua_f, firma_dim);
        }
    }

    // Estado por fotograma de «el tiempo en los cristales» (27 v2): decodifica mods[6..7] (formato 4) una vez
    // por cuadro y suaviza el viento (tau ~1 s lluvia, ~5 s arena), con respaldo completo sin mod.
    let cm = adp_mod_cristales();
    let clima_global = frame.rain * (1.0 + 0.4 * frame.thunder);
    let dt_cr = clamp(frame.delta_time, 0.0, 0.5);
    let v_ant = datos_cuadro[ADP_CUADRO_CRISTAL_1];
    let reinicio_cr = frame.delta_time <= 0.0 || abs(cruce_ant.w - firma_dim) > 0.5;
    let alfa_vl = select(1.0 - exp(-dt_cr / OPC_CRISTAL_VIENTO_TAU_LLUVIA), 1.0, reinicio_cr);
    let alfa_va = select(1.0 - exp(-dt_cr / OPC_CRISTAL_VIENTO_TAU_ARENA), 1.0, reinicio_cr);

    if cm.activo {
        let escala_lluvia = opc_cristal_escala_lluvia(cm.nivel_lluvia);
        let escala_nieve = opc_cristal_escala_lluvia(cm.nivel_nieve);
        let escala_arena = opc_cristal_escala_arena(cm.nivel_arena);
        let v_obj = select(vec2<f32>(0.0), cm.viento_xz, cm.seguir_viento);
        let v_lluvia = mix(v_ant.xy, v_obj, alfa_vl);
        let v_arena = mix(v_ant.zw, v_obj, alfa_va);
        var flags: u32 = 0u;
        if cm.estilo_regueros { flags |= OPC_CR_FLAG_REGUEROS; }
        if cm.seguir_viento { flags |= OPC_CR_FLAG_VIENTO; }
        if cm.interior { flags |= OPC_CR_FLAG_INTERIOR; }
        if cm.arena_roja { flags |= OPC_CR_FLAG_ARENA_ROJA; }
        if cm.espectador { flags |= OPC_CR_FLAG_ESPECTADOR; }
        if cm.bioma_seco { flags |= OPC_CR_FLAG_BIOMA_SECO; }
        if cm.bioma_frio { flags |= OPC_CR_FLAG_BIOMA_FRIO; }
        if cm.llueve_en_bioma { flags |= OPC_CR_FLAG_LLUEVE_BIOMA; }
        flags |= (cm.borde_helado & 3u) << 8u;
        flags |= (cm.desenfoque & 3u) << 10u;

        datos_cuadro[ADP_CUADRO_CRISTAL_0] = vec4<f32>(clima_global, cm.escarcha, cm.repisa, cm.condensacion);
        datos_cuadro[ADP_CUADRO_CRISTAL_1] = vec4<f32>(v_lluvia, v_arena);
        datos_cuadro[ADP_CUADRO_CRISTAL_2] = vec4<f32>(cm.arena, escala_lluvia, escala_nieve, escala_arena);
        let vaho_activo = cm.interior && !cm.espectador && cm.aliento_opacidad > 0.001;
        let vaho_w = select(-1.0, cm.vaho_peso, vaho_activo);
        datos_cuadro[ADP_CUADRO_CRISTAL_VAHO] = vec4<f32>(cm.vaho_pos, vaho_w);
        datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS] = vec4<f32>(f32(flags), cm.cond_opacidad, cm.cond_blancura, cm.vaho_escala);
        datos_cuadro[ADP_CUADRO_CRISTAL_VAHO_OPT] = vec4<f32>(
            cm.aliento_opacidad,
            cm.aliento_blancura,
            opc_cristal_k_resolucion(cm.resolucion_cod),
            1.0,
        );
    } else {
        // Respaldo sin mod: deduce bioma frío/lluvia, noche y tormenta desde `frame`.
        let alt_extra = max(frame.camera_position.y - 80.0, 0.0);
        let temp_eff = frame.temperature - alt_extra * 0.00125;
        let bioma_seco = frame.precipitation == 0u && frame.temperature >= 1.0;
        let bioma_frio = (temp_eff < OPC_CRISTAL_TEMP_NIEVE || frame.precipitation == 2u) && !bioma_seco;
        let llueve_bioma = frame.precipitation == 1u;
        let precip = clima_global > OPC_CRISTAL_CLIMA_UMBRAL;
        let nevando = bioma_frio && precip;
        let noche = frame.day_time >= (12542.0 / 24000.0) && frame.day_time <= (23460.0 / 24000.0);
        let escarcha = select(0.0, select(select(0.45, 0.70, noche), 1.0, nevando), bioma_frio);
        let repisa = select(0.0, 1.0, nevando);
        let cond = select(0.0, 1.0, noche || (precip && frame.thunder > 0.5));
        let v_obj = select(vec2<f32>(0.0), normalize(OPC_VIENTO) * 0.55, OPC_CRISTAL_SEGUIR_VIENTO);
        let v_lluvia = mix(v_ant.xy, v_obj, alfa_vl);
        let v_arena = mix(v_ant.zw, v_obj, alfa_va);
        var flags: u32 = 0u;
        if OPC_CRISTAL_ESTILO_REGUEROS { flags |= OPC_CR_FLAG_REGUEROS; }
        if OPC_CRISTAL_SEGUIR_VIENTO { flags |= OPC_CR_FLAG_VIENTO; }
        if OPC_CRISTAL_INTERIOR_ACTIVO { flags |= OPC_CR_FLAG_INTERIOR; }
        if bioma_seco { flags |= OPC_CR_FLAG_BIOMA_SECO; }
        if bioma_frio { flags |= OPC_CR_FLAG_BIOMA_FRIO; }
        if llueve_bioma { flags |= OPC_CR_FLAG_LLUEVE_BIOMA; }
        flags |= (OPC_CRISTAL_BORDE_ESTILO_DEF & 3u) << 8u;
        flags |= (OPC_CRISTAL_DESENFOQUE_DEF & 3u) << 10u;

        datos_cuadro[ADP_CUADRO_CRISTAL_0] = vec4<f32>(clima_global, escarcha, repisa, cond);
        datos_cuadro[ADP_CUADRO_CRISTAL_1] = vec4<f32>(v_lluvia, v_arena);
        datos_cuadro[ADP_CUADRO_CRISTAL_2] = vec4<f32>(0.0, OPC_CRISTAL_NIVEL_DEFECTO, OPC_CRISTAL_NIVEL_DEFECTO, 0.0);
        datos_cuadro[ADP_CUADRO_CRISTAL_VAHO] = vec4<f32>(0.0, 0.0, 0.0, select(-1.0, 0.0, OPC_CRISTAL_ALIENTO_ACTIVO));
        datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS] = vec4<f32>(
            f32(flags),
            OPC_CRISTAL_COND_OPACIDAD_DEF,
            OPC_CRISTAL_COND_BLANCURA_DEF,
            1.0,
        );
        datos_cuadro[ADP_CUADRO_CRISTAL_VAHO_OPT] = vec4<f32>(
            OPC_CRISTAL_ALIENTO_OPACIDAD_DEF,
            OPC_CRISTAL_ALIENTO_BLANCURA_DEF,
            1.0,
            0.0,
        );
    }
}
