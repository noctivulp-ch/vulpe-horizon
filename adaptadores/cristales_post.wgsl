// Composición en pasada post (`03-composicion`) de las capas climáticas sobre el cristal transparente
// (`minecraft:glass` y `minecraft:glass_pane`), cuyo interior de alfa 0 es recortado por Horizon bajo
// `coverage = "engine"` (`shaders-reference-0.2.md:103-111`).
// Recorre la caché 3D `cristal_mapa` con DDA entero sin lanzar ray queries; coste ~0 ms cuando no hay
// cristales transparentes cerca o el tiempo está despejado.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §Arquitectura y coste

fn adp_cp_sobre(base_col: vec3<f32>, base_op: f32, nueva_col: vec3<f32>, nueva_op: f32) -> vec4<f32> {
    let op_out = nueva_op + base_op * (1.0 - nueva_op);
    if op_out <= 1e-4 {
        return vec4<f32>(0.0);
    }
    let col_out = (nueva_col * nueva_op + base_col * base_op * (1.0 - nueva_op)) / op_out;
    return vec4<f32>(col_out, op_out);
}

fn adp_cristales_post_evaluar_cara(
    b: vec3<i32>,
    p_mundo: vec3<f32>,
    n_cara: vec3<f32>,
    vista: vec3<f32>,
    dist: f32,
    w0: u32,
    w1: u32,
    luces: AdpLuces,
) -> vec4<f32> {
    let c0 = datos_cuadro[ADP_CUADRO_CRISTAL_0];
    let c1 = datos_cuadro[ADP_CUADRO_CRISTAL_1];
    let c2 = datos_cuadro[ADP_CUADRO_CRISTAL_2];
    let cv = datos_cuadro[ADP_CUADRO_CRISTAL_VAHO];
    let cf = datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS];
    let co = datos_cuadro[ADP_CUADRO_CRISTAL_VAHO_OPT];

    let flags = u32(max(round(cf.x), 0.0));
    let regueros = (flags & OPC_CR_FLAG_REGUEROS) != 0u;
    let interior_activo = (flags & OPC_CR_FLAG_INTERIOR) != 0u;
    let arena_roja = (flags & OPC_CR_FLAG_ARENA_ROJA) != 0u;
    let espectador = (flags & OPC_CR_FLAG_ESPECTADOR) != 0u;
    let bioma_seco = (flags & OPC_CR_FLAG_BIOMA_SECO) != 0u;
    let bioma_frio = (flags & OPC_CR_FLAG_BIOMA_FRIO) != 0u;
    let borde_estilo = (flags >> 8u) & 3u;

    let plano = sup_cristal_plano(p_mundo, n_cara);
    let entorno = adp_cm_decodificar_entorno(w0, w1, n_cara, plano.vertical, bioma_frio);
    if entorno.cerrada {
        return vec4<f32>(0.0);
    }

    let aten_dist = 1.0 - smoothstep(OPC_CRISTAL_DIST_INICIO, OPC_CRISTAL_DIST_FIN, dist);
    if aten_dist <= 0.001 {
        return vec4<f32>(0.0);
    }

    let es_arriba = n_cara.y > 0.5;
    let es_abajo = n_cara.y < -0.5;
    let cara_idx = u32(sup_cristal_indice_cara(n_cara));
    let variante = sup_cr_hash_u32(u32(b.x * 73856093) ^ u32(b.y * 19349663) ^ u32(b.z * 83492791) ^ cara_idx) & 3u;

    let n_l = max(dot(n_cara, luces.direccion), 0.0);
    let contraluz = pow(max(dot(-vista, luces.direccion), 0.0), 3.0) * 0.35;
    let cielo_ext_ref = select(0.85, 1.0, entorno.llega_cielo || entorno.es_exterior);
    let luz_base = luces.directa * (n_l + contraluz) * 0.60
                 + luces.cielo * cielo_ext_ref * 1.10
                 + vec3<f32>(OPC_LUZ_NOCHE_SUELO * 1.8 * cielo_ext_ref);

    var capa_col = vec3<f32>(0.0);
    var capa_op = 0.0;

    // Evalúa primero condensación interior y vaho del aliento para conocer `derrite` y `cond.grosor`.
    let cond_activa = interior_activo && bioma_frio && (c0.w > 0.001 || (borde_estilo == 1u && c0.y > 0.001));
    var cond = SupCristalCondensacion(vec3<f32>(0.0), 0.0, 0.0);
    if cond_activa && entorno.es_interior_fria {
        cond = sup_cristal_condensacion(plano, entorno.dist_marco, c0.y, c0.w, cf.y, cf.z, co.z, variante);
        cond.alfa *= aten_dist;
        cond.grosor *= aten_dist;
    }

    let vaho_activo = interior_activo && !espectador && co.x > 0.001 && (cv.w > 0.001 || (co.w < 0.5 && dist < OPC_CRISTAL_VAHO_DIST));
    var aliento = SupCristalAliento(vec3<f32>(0.0), 0.0, 0.0, 0.0);
    if vaho_activo {
        aliento = sup_cristal_aliento_v2(
            plano,
            p_mundo - frame.camera_position,
            n_cara,
            cv.xyz,
            cv.w,
            cf.w,
            co.x,
            co.y,
            cond.grosor,
            co.z,
            co.w > 0.5,
            entorno.es_interior,
            espectador,
            adp_tiempo().segundos,
        );
        aliento.alfa *= aten_dist;
        aliento.grosor *= aten_dist;
    }
    let suprime_esc = 1.0 - smoothstep(0.0, 0.70, aliento.derrite) * 0.92;

    // Capa 1 — Lluvia global desde el lienzo `cristal_clima` (27 v2 §Capa 1).
    let cara_op_idx = cara_idx ^ 1u;
    let panel_ll = select(cara_idx, 4u, es_arriba);
    let panel_ll_op = select(cara_op_idx, 4u, es_arriba);
    let hdr_ll = cristal_sim[panel_ll];
    let hdr_ll_op = cristal_sim[panel_ll_op];
    let panel_vivo = !es_abajo && (hdr_ll.z > 0.5 || hdr_ll.w > 0.0 || hdr_ll_op.z > 0.5 || hdr_ll_op.w > 0.0);

    let lluvia_en_exterior = entorno.llega_cielo;
    let lluvia_desde_interior = !lluvia_en_exterior && entorno.es_interior && entorno.opuesta_llega_cielo && plano.vertical;
    if panel_vivo && c2.y > 0.001 && (lluvia_en_exterior || lluvia_desde_interior) && !bioma_frio && !bioma_seco {
        let normal_muestra = select(-n_cara, n_cara, lluvia_en_exterior);
        var plano_muestra = plano;
        if !lluvia_en_exterior {
            plano_muestra = sup_cristal_plano(p_mundo, normal_muestra);
        }
        let coord_ll = sup_cristal_lluvia_texel(b, normal_muestra, plano_muestra, co.z);
        let tx = textureLoad(cristal_clima, coord_ll, 0);
        var lluvia_rgba = sup_cristal_lluvia_color(tx, regueros && plano.vertical);
        lluvia_rgba.a *= aten_dist;

        if lluvia_rgba.a > 0.002 {
            let luz_lluvia = luces.directa * (n_l + contraluz) * 0.55
                           + luces.cielo * cielo_ext_ref * 1.45
                           + vec3<f32>(0.06) * cielo_ext_ref;
            var col_ll = lluvia_rgba.rgb * luz_lluvia;
            let gota_a = tx.b * aten_dist;
            if gota_a > 0.05 {
                let pend = sup_cr_desempaquetar_pendiente(tx.a) * gota_a;
                let n_gota = normalize(n_cara + plano.tangente * (pend.x * 0.65) - plano.bitangente * (pend.y * 0.65));
                let dir_cielo = normalize(vec3<f32>(0.12, 0.96, 0.22));
                let esp = sup_especular(n_gota, vista, dir_cielo, 0.07, vec3<f32>(0.05))
                        * max(dot(n_gota, dir_cielo), 0.0) * luces.cielo * (OPC_CRISTAL_GOTA_ESPECULAR * gota_a);
                col_ll += esp / max(lluvia_rgba.a, 0.05);
            }
            let comp = adp_cp_sobre(capa_col, capa_op, col_ll, lluvia_rgba.a);
            capa_col = comp.rgb;
            capa_op = comp.a;
        }
    }

    // Capa 2 y 3 — Escarcha de fuera, repisa de nieve y copos pegados (27 v2 §Capas 2 y 3).
    let copos_vivos = bioma_frio && c2.z > 0.001 && (cristal_sim[8].z > 0.5 || cristal_sim[9].z > 0.5 || cristal_sim[10].z > 0.5 || cristal_sim[11].z > 0.5);
    let frio_activo = bioma_frio && (c0.y > 0.001 || c0.z > 0.001 || copos_vivos) && c2.z > 0.001;
    if frio_activo && (entorno.es_exterior || entorno.es_interior_fria) {
        var esc = sup_cristal_escarcha_v2(plano, entorno.dist_marco, c0.y, c2.z, co.z, variante, false, 1.0);
        esc.alfa *= suprime_esc * aten_dist;
        if esc.alfa > 0.002 {
            let col_esc = esc.color * (luz_base * 1.15 + luces.cielo * cielo_ext_ref * 0.30)
                        + vec3<f32>(esc.destello) * (luces.directa * 0.6 + luces.cielo * cielo_ext_ref * 0.9);
            let comp = adp_cp_sobre(capa_col, capa_op, col_esc, esc.alfa);
            capa_col = comp.rgb;
            capa_op = comp.a;
        }

        let copo_ext = entorno.llega_cielo;
        let copo_int = !copo_ext && entorno.es_interior && entorno.opuesta_llega_cielo;
        if copos_vivos && plano.vertical && (copo_ext || copo_int) {
            let n_copo = select(-n_cara, n_cara, copo_ext);
            var pl_copo = plano;
            if !copo_ext {
                pl_copo = sup_cristal_plano(p_mundo, n_copo);
            }
            let coord_c = sup_cristal_copo_texel(b, n_copo, pl_copo, co.z);
            var copo = textureLoad(cristal_clima, coord_c, 0);
            copo.a *= (1.0 - smoothstep(0.0, 0.65, aliento.derrite)) * aten_dist;
            if copo.a > 0.002 {
                let col_c = copo.rgb * (luz_base * 1.15 + luces.cielo * cielo_ext_ref * 0.35);
                let comp = adp_cp_sobre(capa_col, capa_op, col_c, copo.a);
                capa_col = comp.rgb;
                capa_op = comp.a;
            }
        }

        let muestra_rep = c0.z > 0.005 && (entorno.llega_cielo || (entorno.es_interior && entorno.opuesta_llega_cielo));
        if muestra_rep {
            var rep = sup_cristal_repisa_nieve(plano, entorno.bordes, c0.z, c2.z, co.z);
            rep.alfa *= aten_dist;
            if rep.alfa > 0.002 {
                let col_rep = rep.color * (luz_base * 1.12 + luces.cielo * cielo_ext_ref * 0.25);
                let comp = adp_cp_sobre(capa_col, capa_op, col_rep, rep.alfa);
                capa_col = comp.rgb;
                capa_op = comp.a;
            }
        }
    }

    // Capa 4 — Arena tras la tormenta en biomas secos y mesas (27 v2 §Capa 4).
    let arena_activa = bioma_seco && c2.x > OPC_CRISTAL_ARENA_MIN && c2.w > 0.001;
    let muestra_arena = arena_activa && plano.vertical && (entorno.llega_cielo || (entorno.es_interior && entorno.opuesta_llega_cielo));
    if muestra_arena {
        var ar = sup_cristal_arena_v2(
            plano,
            select(-n_cara, n_cara, entorno.llega_cielo),
            entorno.bordes,
            entorno.dist_marco,
            c1.zw,
            c2.x,
            c2.w,
            co.z,
            arena_roja,
        );
        ar.alfa *= aten_dist;
        if ar.alfa > 0.002 {
            let col_ar = ar.color * (luz_base * 1.05 + luces.cielo * cielo_ext_ref * 0.20);
            let comp = adp_cp_sobre(capa_col, capa_op, col_ar, ar.alfa);
            capa_col = comp.rgb;
            capa_op = comp.a;
        }
    }

    // Capas 5 y 6 — Condensación interior, vaho del aliento y borde helado (27 v2 §Capas 5 y 6).
    if cond.alfa > 0.002 {
        let col_cond = cond.color * (luz_base * 1.12 + luces.cielo * cielo_ext_ref * 0.30);
        let comp = adp_cp_sobre(capa_col, capa_op, col_cond, cond.alfa);
        capa_col = comp.rgb;
        capa_op = comp.a;
    }

    if aliento.alfa > 0.002 {
        let col_vaho = aliento.color * (luz_base * 1.14 + luces.cielo * cielo_ext_ref * 0.30);
        let comp = adp_cp_sobre(capa_col, capa_op, col_vaho, aliento.alfa);
        capa_col = comp.rgb;
        capa_op = comp.a;
    }

    if cond_activa && entorno.es_interior_fria {
        var borde = sup_cristal_borde_helado(plano, entorno.dist_marco, c0.y, c0.w, c2.z, co.z, borde_estilo, variante);
        borde.alfa *= suprime_esc * aten_dist;
        if borde.alfa > 0.002 {
            let col_b = borde.color * (luz_base * 1.18 + luces.cielo * cielo_ext_ref * 0.35)
                      + vec3<f32>(borde.destello) * (luces.directa * 0.6 + luces.cielo * cielo_ext_ref * 0.9);
            let comp = adp_cp_sobre(capa_col, capa_op, col_b, borde.alfa);
            capa_col = comp.rgb;
            capa_op = comp.a;
        }
    }

    return vec4<f32>(capa_col, capa_op);
}

fn adp_cristales_post(
    base_color: vec3<f32>,
    p: AdpPixel,
    dir: vec3<f32>,
    dist_escena: f32,
) -> vec3<f32> {
    if !OPC_CRISTAL_ACTIVO || !adp_es_superficie() || frame.has_ray_tracing == 0u {
        return base_color;
    }
    // Salida uniforme de coste ~0 ms cuando no hay cristal transparente cerca o el clima está inactivo.
    let resumen = cristal_sim[ADP_CS_RESUMEN];
    if resumen.x < 0.5 || resumen.y < 0.5 {
        return base_color;
    }

    let orig = frame.camera_position;
    let t_max = min(select(dist_escena, OPC_CRISTAL_DIST_MAX, p.es_cielo), OPC_CRISTAL_DIST_MAX);
    if t_max <= 0.05 {
        return base_color;
    }

    var b = vec3<i32>(floor(orig));
    let cam_b = b;
    let step_v = vec3<i32>(
        select(-1, 1, dir.x >= 0.0),
        select(-1, 1, dir.y >= 0.0),
        select(-1, 1, dir.z >= 0.0),
    );
    let inv_d = vec3<f32>(
        select(1e6, 1.0 / dir.x, abs(dir.x) > 1e-6),
        select(1e6, 1.0 / dir.y, abs(dir.y) > 1e-6),
        select(1e6, 1.0 / dir.z, abs(dir.z) > 1e-6),
    );
    let t_delta = abs(inv_d);
    let nx = select(f32(b.x), f32(b.x + 1), dir.x >= 0.0);
    let ny = select(f32(b.y), f32(b.y + 1), dir.y >= 0.0);
    let nz = select(f32(b.z), f32(b.z + 1), dir.z >= 0.0);
    var t_next = vec3<f32>(
        select(1e6, (nx - orig.x) * inv_d.x, abs(dir.x) > 1e-6),
        select(1e6, (ny - orig.y) * inv_d.y, abs(dir.y) > 1e-6),
        select(1e6, (nz - orig.z) * inv_d.z, abs(dir.z) > 1e-6),
    );

    let luces = adp_luces_cuadro();
    let vista = -dir;
    var accum_col = vec3<f32>(0.0);
    var accum_a = 0.0;
    let mascara_claro = ADP_CM_BIT_VALIDO | ADP_CM_BIT_ES_CRISTAL | ADP_CM_BIT_CLARO;

    for (var paso = 0; paso < 52; paso++) {
        var t_hit = 0.0;
        var n_enter = vec3<f32>(0.0);
        if t_next.x <= t_next.y && t_next.x <= t_next.z {
            t_hit = t_next.x;
            t_next.x += t_delta.x;
            b.x += step_v.x;
            n_enter = vec3<f32>(-f32(step_v.x), 0.0, 0.0);
        } else if t_next.y <= t_next.z {
            t_hit = t_next.y;
            t_next.y += t_delta.y;
            b.y += step_v.y;
            n_enter = vec3<f32>(0.0, -f32(step_v.y), 0.0);
        } else {
            t_hit = t_next.z;
            t_next.z += t_delta.z;
            b.z += step_v.z;
            n_enter = vec3<f32>(0.0, 0.0, -f32(step_v.z));
        }

        if t_hit >= t_max - 0.015 {
            break;
        }
        let rel = b - cam_b;
        if abs(rel.x) >= (ADP_CM_SX / 2) || abs(rel.y) >= (ADP_CM_SY / 2) || abs(rel.z) >= (ADP_CM_SZ / 2) {
            break;
        }

        let idx = adp_cm_indice(b);
        let w0 = cristal_mapa[idx];
        if (w0 & mascara_claro) != mascara_claro {
            continue;
        }
        let w1 = cristal_mapa[idx + 1u];
        if ((w1 >> 24u) & 255u) != adp_cm_firma_bloque(b) {
            continue;
        }

        var t_surf = t_hit;
        var n_surf = n_enter;
        var valido = true;

        if (w0 & ADP_CM_BIT_PANEL) != 0u {
            // Panel fino: interseca el plano del brazo activo (+-0,0625 desde el centro del bloque).
            valido = false;
            var mejor_t = t_max - 0.015;
            if (w0 & ADP_CM_BIT_PANEL_X) != 0u && abs(dir.z) > 1e-4 {
                let z_pl = f32(b.z) + 0.5 + select(0.0625, -0.0625, dir.z > 0.0);
                let tp = (z_pl - orig.z) / dir.z;
                if tp >= t_hit - 0.002 && tp < mejor_t {
                    let hp = orig + dir * tp;
                    if hp.x >= f32(b.x) && hp.x <= f32(b.x + 1) && hp.y >= f32(b.y) && hp.y <= f32(b.y + 1) {
                        mejor_t = tp;
                        t_surf = tp;
                        n_surf = vec3<f32>(0.0, 0.0, select(1.0, -1.0, dir.z > 0.0));
                        valido = true;
                    }
                }
            }
            if (w0 & ADP_CM_BIT_PANEL_Z) != 0u && abs(dir.x) > 1e-4 {
                let x_pl = f32(b.x) + 0.5 + select(0.0625, -0.0625, dir.x > 0.0);
                let tp = (x_pl - orig.x) / dir.x;
                if tp >= t_hit - 0.002 && tp < mejor_t {
                    let hp = orig + dir * tp;
                    if hp.z >= f32(b.z) && hp.z <= f32(b.z + 1) && hp.y >= f32(b.y) && hp.y <= f32(b.y + 1) {
                        mejor_t = tp;
                        t_surf = tp;
                        n_surf = vec3<f32>(select(1.0, -1.0, dir.x > 0.0), 0.0, 0.0);
                        valido = true;
                    }
                }
            }
        }

        if !valido {
            continue;
        }

        let p_mundo = orig + dir * t_surf;
        let capa = adp_cristales_post_evaluar_cara(b, p_mundo, n_surf, vista, t_surf, w0, w1, luces);
        if capa.a > 0.002 {
            let peso = capa.a * (1.0 - accum_a);
            accum_col += capa.rgb * peso;
            accum_a += peso;
            if accum_a > 0.95 {
                break;
            }
        }
    }

    if accum_a <= 0.002 {
        return base_color;
    }
    return accum_col + base_color * (1.0 - accum_a);
}
