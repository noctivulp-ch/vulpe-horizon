// Simulación global por panel en [[before_world]] de gotas de lluvia, regueros y copos pegados (27 v2).
// Un hilo por panel (dispatch [16, 1, 1]) evita cualquier carrera al fusionar o crear microgotas.
// Constantes de disposición en `adaptadores/cristal_sim_datos.wgsl`.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §2

fn adp_cs_rand(estado: ptr<function, u32>) -> f32 {
    var x = *estado;
    x = x * 1664525u + 1013904223u;
    *estado = x;
    return f32((x >> 8u) & 0xFFFFu) / 65535.0;
}

fn adp_cs_tamano_inicial(u: f32, k: f32) -> f32 {
    if k < 0.75 {
        // 16: tamaños 1..2 con 62 / 38 %
        return select(2.0, 1.0, u < 0.62);
    }
    if k > 1.5 {
        // 64: tamaños 1..6 con 30/28/22/12/6/2 % (escalados al lienzo base de 32: /2, mínimo 1)
        if u < 0.30 { return 1.0; }
        if u < 0.58 { return 1.5; }
        if u < 0.80 { return 2.2; }
        if u < 0.92 { return 3.0; }
        if u < 0.98 { return 3.8; }
        return 4.5;
    }
    // 32 (base): tamaños 1..4 con 45 / 35 / 15 / 5 %
    if u < 0.45 { return 1.0; }
    if u < 0.80 { return 2.0; }
    if u < 0.95 { return 3.0; }
    return 4.0;
}

fn adp_cs_normal_cardinal(panel: u32) -> vec2<f32> {
    switch panel {
        case 0u: { return vec2<f32>(0.0, -1.0); } // Norte (-Z)
        case 1u: { return vec2<f32>(0.0, 1.0); }  // Sur (+Z)
        case 2u: { return vec2<f32>(-1.0, 0.0); } // Oeste (-X)
        default: { return vec2<f32>(1.0, 0.0); }  // Este (+X)
    }
}

fn adp_cs_tangente_cardinal(panel: u32) -> vec2<f32> {
    // cross((0,1,0), normal) en XZ:
    switch panel {
        case 0u: { return vec2<f32>(-1.0, 0.0); } // Norte (-Z) -> -X
        case 1u: { return vec2<f32>(1.0, 0.0); }  // Sur (+Z)   -> +X
        case 2u: { return vec2<f32>(0.0, 1.0); }  // Oeste (-X) -> +Z
        default: { return vec2<f32>(0.0, -1.0); } // Este (+X)  -> -Z
    }
}

fn adp_cs_wrap(v: f32) -> f32 {
    var r = v;
    if r >= 128.0 { r -= 128.0; }
    if r < 0.0 { r += 128.0; }
    return r;
}

fn adp_cs_simular_lluvia_lado(panel: u32, dt: f32) {
    let c0 = datos_cuadro[ADP_CUADRO_CRISTAL_0];
    let c1 = datos_cuadro[ADP_CUADRO_CRISTAL_1];
    let c2 = datos_cuadro[ADP_CUADRO_CRISTAL_2];
    let cf = datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS];
    let co = datos_cuadro[ADP_CUADRO_CRISTAL_VAHO_OPT];

    let flags = u32(max(round(cf.x), 0.0));
    let regueros = (flags & OPC_CR_FLAG_REGUEROS) != 0u;
    let llueve_bioma = (flags & OPC_CR_FLAG_LLUEVE_BIOMA) != 0u;
    let escala = c2.y;
    let clima = c0.x;
    let lloviendo = llueve_bioma && clima > OPC_CRISTAL_CLIMA_UMBRAL && escala > 0.001;
    let k = clamp(co.z, 0.5, 2.0);

    var hdr = cristal_sim[panel];
    var activas = u32(max(round(hdr.z), 0.0));
    var trail_t = hdr.w;

    // Salida temprana de coste ~0 cuando el panel está completamente seco y no llueve.
    if !lloviendo && activas == 0u && trail_t <= -0.5 {
        return;
    }

    var rng = u32(max(round(abs(hdr.y)), 1.0)) ^ (frame.frame_index * 747796405u + panel * 2891336453u + 1u);
    let base = ADP_CS_OFF_LADO + panel * ADP_CS_SLOT_LADO * 2u;

    // Si es el primer fotograma o cambió de modo (gotas <-> regueros), limpia las ranuras.
    let modo_ant_regueros = hdr.y < 0.0;
    var spawn_acc = hdr.x;
    if hdr.y == 0.0 || modo_ant_regueros != regueros {
        for (var i = 0u; i < ADP_CS_MAX_GOTAS_LADO; i++) {
            cristal_sim[base + i * 2u] = vec4<f32>(0.0);
            cristal_sim[base + i * 2u + 1u] = vec4<f32>(0.0);
        }
        activas = 0u;
        spawn_acc = 0.0;
    }

    // Viento proyectado sobre esta orientación cardinal (27 §Viento).
    let n_xz = adp_cs_normal_cardinal(panel);
    let t_xz = adp_cs_tangente_cardinal(panel);
    let viento = c1.xy;
    let hacia = clamp(dot(-viento, n_xz), -1.0, 1.0);
    let reparto = clamp(1.0 + OPC_CRISTAL_VIENTO_BARLOVENTO * hacia, 0.2, 1.8);
    let viento_u = clamp(dot(viento, t_xz), -1.0, 1.0);

    // 1) Aparición de nuevas gotas o regueros mientras llueve.
    if lloviendo {
        let tasa_base = select(12.0, 16.0, regueros);
        spawn_acc += tasa_base * min(clima, 1.4) * escala * reparto * dt;
        var por_crear = min(u32(floor(spawn_acc)), 6u);
        spawn_acc -= f32(por_crear);

        if por_crear > 0u {
            for (var s = 0u; s < por_crear; s++) {
                let nx = adp_cs_rand(&rng) * 128.0;
                let ny = adp_cs_rand(&rng) * 128.0;
                let tam_nuevo = adp_cs_tamano_inicial(adp_cs_rand(&rng), k);

                // Si el panel está cerca del tope de 110 gotas, la lluvia nueva cae sobre gotas quietas existentes
                // ponderando por tamaño (sección de captura proporcional al área) para que crezcan hasta 5 y bajen.
                if !regueros && activas >= 90u {
                    var mejor_v = 0u;
                    var mejor_t = 0.0;
                    for (var c = 0u; c < 4u; c++) {
                        let cand = u32(floor(adp_cs_rand(&rng) * f32(ADP_CS_MAX_GOTAS_LADO))) % ADP_CS_MAX_GOTAS_LADO;
                        let cv0 = cristal_sim[base + cand * 2u];
                        if cv0.z > mejor_t && cv0.w <= 0.5 {
                            mejor_t = cv0.z;
                            mejor_v = cand;
                        }
                    }
                    if mejor_t > 0.0 {
                        var v0 = cristal_sim[base + mejor_v * 2u];
                        var v1 = cristal_sim[base + mejor_v * 2u + 1u];
                        let nuevo_t = min(sqrt(v0.z * v0.z + tam_nuevo * tam_nuevo), 6.2);
                        v0.z = nuevo_t;
                        if nuevo_t >= 5.0 || (nuevo_t >= 4.0 && adp_cs_rand(&rng) < 0.10) {
                            v0.w = 14.0 + adp_cs_rand(&rng) * 16.0;
                            v1.x = clamp(mix((adp_cs_rand(&rng) * 2.0 - 1.0) * 0.3, viento_u, 0.7), -0.9, 0.9);
                            v1.y = 0.65 + adp_cs_rand(&rng) * 0.65;
                            v1.z = 0.20 + adp_cs_rand(&rng) * 0.55;
                            v1.w = 20.0 + adp_cs_rand(&rng) * 40.0;
                        } else {
                            v1.w = nuevo_t;
                        }
                        cristal_sim[base + mejor_v * 2u] = v0;
                        cristal_sim[base + mejor_v * 2u + 1u] = v1;
                        continue;
                    }
                }

                for (var i = 0u; i < ADP_CS_MAX_GOTAS_LADO; i++) {
                    let d0 = cristal_sim[base + i * 2u];
                    if d0.z <= 0.0 {
                        if regueros {
                            let ancho = select(2.0, 1.0, adp_cs_rand(&rng) < 0.85);
                            let vy = 30.0 + adp_cs_rand(&rng) * 50.0;
                            let largo = 10.0 + adp_cs_rand(&rng) * 34.0;
                            let tilt = clamp(mix((adp_cs_rand(&rng) * 2.0 - 1.0) * 0.25, viento_u, 0.7), -0.9, 0.9);
                            cristal_sim[base + i * 2u] = vec4<f32>(nx, ny, ancho, vy);
                            cristal_sim[base + i * 2u + 1u] = vec4<f32>(tilt, 1.0, 2.0 + adp_cs_rand(&rng) * 3.0, largo);
                        } else {
                            var vy = 0.0;
                            var pace = 1.0;
                            var timer = 0.0;
                            var budget = tam_nuevo;
                            var tilt = 0.0;
                            if tam_nuevo >= 4.0 && adp_cs_rand(&rng) < 0.10 {
                                vy = 14.0 + adp_cs_rand(&rng) * 16.0;
                                pace = 0.7 + adp_cs_rand(&rng) * 0.6;
                                timer = 0.20 + adp_cs_rand(&rng) * 0.55;
                                budget = 20.0 + adp_cs_rand(&rng) * 40.0;
                                tilt = clamp(mix((adp_cs_rand(&rng) * 2.0 - 1.0) * 0.3, viento_u, 0.7), -0.9, 0.9);
                            }
                            cristal_sim[base + i * 2u] = vec4<f32>(nx, ny, tam_nuevo, vy);
                            cristal_sim[base + i * 2u + 1u] = vec4<f32>(tilt, pace, timer, budget);
                        }
                        activas += 1u;
                        break;
                    }
                }
            }
        }
    } else {
        spawn_acc = 0.0;
    }

    // 2) Avance físico: caída hacia abajo (+y), tirones con pausas, desvío, microgotas y secado.
    var micro_pendiente_x = -1.0;
    var micro_pendiente_y = -1.0;
    var vivas = 0u;

    for (var i = 0u; i < ADP_CS_MAX_GOTAS_LADO; i++) {
        var d0 = cristal_sim[base + i * 2u];
        if d0.z <= 0.0 {
            continue;
        }
        var d1 = cristal_sim[base + i * 2u + 1u];

        if regueros {
            if d0.w > 0.5 {
                // Reguero en movimiento hacia abajo (+y).
                let dy = d0.w * dt;
                d0.y = adp_cs_wrap(d0.y + dy);
                d0.x = adp_cs_wrap(d0.x + dy * d1.x);
                d1.w -= dy;
                if d1.w <= 0.0 || !lloviendo {
                    // Al pararse deja una gotita que vive 2..5 s (d1.z).
                    d0.w = 0.0;
                    d0.z = 1.0;
                }
            } else {
                // Gotita residual al final del reguero (2..5 s).
                d1.z -= dt;
                if d1.z <= 0.0 {
                    d0 = vec4<f32>(0.0);
                    d1 = vec4<f32>(0.0);
                }
            }
        } else if d0.w > 0.5 {
            // Gota que corre hacia abajo (+y) a tirones.
            // d1: x=tilt, y=pace (0 si parada), z=timer (>0 en marcha, <0 en pausa), w=budget filas
            if d1.z < 0.0 {
                // En pausa (3..12 ticks = 0,15..0,60 s).
                d1.z += dt;
                d1.y = 0.0;
                if d1.z >= 0.0 {
                    d1.y = 0.45 + adp_cs_rand(&rng) * 1.05;
                    d1.z = 0.20 + adp_cs_rand(&rng) * 0.55;
                }
            } else {
                d1.z -= dt;
                if d1.z <= 0.0 {
                    if adp_cs_rand(&rng) < 0.22 {
                        // 22 % de probabilidad de pararse 3..12 ticks.
                        d1.y = 0.0;
                        d1.z = -(0.15 + adp_cs_rand(&rng) * 0.45);
                    } else {
                        d1.y = 0.45 + adp_cs_rand(&rng) * 1.05;
                        d1.z = 0.20 + adp_cs_rand(&rng) * 0.55;
                    }
                }
            }

            if !lloviendo {
                // Al parar la lluvia pierden velocidad (x0,8 por tick) y presupuesto.
                d0.w *= pow(0.8, dt * 20.0);
                d1.w -= dt * 28.0;
            }

            let dy = max(d0.w * d1.y * dt, 0.0);
            if dy > 0.0 {
                d0.y = adp_cs_wrap(d0.y + dy);
                d0.x = adp_cs_wrap(d0.x + dy * d1.x);

                // Desvío: cada ~6..20 filas re-elige inclinación en ±0,3 mezclada al 70 % con el viento (máx ±0,9).
                if adp_cs_rand(&rng) < (dy / 13.0) {
                    let azar = (adp_cs_rand(&rng) * 2.0 - 1.0) * 0.3;
                    d1.x = clamp(mix(azar, viento_u, 0.7), -0.9, 0.9);
                }

                // Microgotas de 1 texel detrás: prob (0,02 + 0,01 * tamaño) por fila.
                if micro_pendiente_x < 0.0 && adp_cs_rand(&rng) < (0.02 + 0.01 * d0.z) * dy {
                    micro_pendiente_x = adp_cs_wrap(d0.x - dy * d1.x);
                    micro_pendiente_y = adp_cs_wrap(d0.y - max(d0.z * 0.55, 1.5));
                }

                // Presupuesto de 20..60 filas por nivel de tamaño; al bajar de 2 se queda quieta.
                d1.w -= dy;
                if d1.w <= 0.0 {
                    d0.z -= 1.0;
                    d1.w = 20.0 + adp_cs_rand(&rng) * 40.0;
                }
            }

            if d0.z < 2.0 || d0.w < 2.0 {
                d0.w = 0.0;
                d0.z = max(d0.z, 1.0);
                d1 = vec4<f32>(0.0, 0.0, 0.0, d0.z);
            }
        } else {
            // Gota quieta: si llueve se mantiene; si paró de llover se seca en 6..26 s encogiendo el último 60 %.
            if lloviendo {
                d1.y = 0.0;
                d1.z = 0.0;
                d1.w = d0.z;
            } else {
                if d1.y <= 0.0 {
                    // Inicializa temporizador de secado: 6 + 20 * (tam/5) * azar(0,7..1).
                    let total_s = 6.0 + 20.0 * clamp(d0.z / 5.0, 0.0, 1.0) * (0.7 + 0.3 * adp_cs_rand(&rng));
                    d1.y = total_s;
                    d1.z = total_s;
                    d1.w = d0.z;
                } else {
                    d1.z -= dt;
                    if d1.z <= 0.0 {
                        d0 = vec4<f32>(0.0);
                        d1 = vec4<f32>(0.0);
                    } else {
                        let frac = d1.z / max(d1.y, 0.1);
                        if frac < 0.60 {
                            d0.z = mix(1.0, max(d1.w, 1.0), frac / 0.60);
                        }
                    }
                }
            }
        }

        cristal_sim[base + i * 2u] = d0;
        cristal_sim[base + i * 2u + 1u] = d1;
        if d0.z > 0.0 {
            vivas += 1u;
        }
    }

    // Coloca la microgota generada este paso en la primera ranura libre (solo modo gotas).
    if !regueros && micro_pendiente_x >= 0.0 && vivas < ADP_CS_MAX_GOTAS_LADO {
        for (var i = 0u; i < ADP_CS_MAX_GOTAS_LADO; i++) {
            if cristal_sim[base + i * 2u].z <= 0.0 {
                cristal_sim[base + i * 2u] = vec4<f32>(micro_pendiente_x, micro_pendiente_y, 1.0, 0.0);
                cristal_sim[base + i * 2u + 1u] = vec4<f32>(0.0, 0.0, 0.0, 1.0);
                vivas += 1u;
                break;
            }
        }
    }

    // 3) Fusión entre gotas (solo modo gotas): si dist < 0,85 * 0,5 * (t1 + t2), suman áreas y centro por masa.
    if !regueros && vivas >= 2u {
        for (var i = 0u; i < ADP_CS_MAX_GOTAS_LADO; i++) {
            var a0 = cristal_sim[base + i * 2u];
            if a0.z <= 0.0 {
                continue;
            }
            var a1 = cristal_sim[base + i * 2u + 1u];
            for (var j = i + 1u; j < ADP_CS_MAX_GOTAS_LADO; j++) {
                let b0 = cristal_sim[base + j * 2u];
                if b0.z <= 0.0 {
                    continue;
                }
                let delta = sup_cr_wrap_delta(b0.xy - a0.xy);
                let umbral = 0.85 * 0.5 * (a0.z + b0.z);
                if dot(delta, delta) < umbral * umbral {
                    let ma = a0.z * a0.z;
                    let mb = b0.z * b0.z;
                    let m_tot = ma + mb;
                    let nuevo_t = min(sqrt(m_tot), 6.2);
                    // Centro ponderado por masa con envolvimiento toroidal.
                    let cx = adp_cs_wrap(a0.x + delta.x * (mb / m_tot));
                    let cy = adp_cs_wrap(a0.y + delta.y * (mb / m_tot));
                    a0.x = cx;
                    a0.y = cy;
                    a0.z = nuevo_t;

                    let ya_corria = a0.w > 0.5 || b0.w > 0.5;
                    if ya_corria {
                        let v_max = max(a0.w, b0.w);
                        a0.w = min(v_max * 1.08, 45.0);
                        if a1.z == 0.0 {
                            a1.y = 0.8 + adp_cs_rand(&rng) * 0.5;
                            a1.z = 0.25 + adp_cs_rand(&rng) * 0.45;
                            a1.w = 25.0 + adp_cs_rand(&rng) * 35.0;
                            a1.x = clamp(mix((adp_cs_rand(&rng) * 2.0 - 1.0) * 0.3, viento_u, 0.7), -0.9, 0.9);
                        }
                    } else if nuevo_t >= 5.0 || (nuevo_t >= 4.0 && adp_cs_rand(&rng) < 0.10) {
                        // Al llegar a tamaño 5 (o 4 en el 10 %) empieza a bajar a 14..30 tx/s.
                        a0.w = 14.0 + adp_cs_rand(&rng) * 16.0;
                        a1.x = clamp(mix((adp_cs_rand(&rng) * 2.0 - 1.0) * 0.3, viento_u, 0.7), -0.9, 0.9);
                        a1.y = 0.65 + adp_cs_rand(&rng) * 0.65;
                        a1.z = 0.20 + adp_cs_rand(&rng) * 0.55;
                        a1.w = 20.0 + adp_cs_rand(&rng) * 40.0;
                    } else {
                        a1.w = nuevo_t;
                    }

                    cristal_sim[base + j * 2u] = vec4<f32>(0.0);
                    cristal_sim[base + j * 2u + 1u] = vec4<f32>(0.0);
                    vivas -= 1u;
                }
            }
            cristal_sim[base + i * 2u] = a0;
            cristal_sim[base + i * 2u + 1u] = a1;
        }
    }

    if vivas > 0u || lloviendo {
        trail_t = select(1.8, 2.6, regueros);
    } else if trail_t > 0.0 {
        trail_t = max(trail_t - dt, 0.0);
    } else {
        trail_t = -1.0;
    }

    let rng_f = f32((rng & 0x7FFFFFu) + 1u);
    cristal_sim[panel] = vec4<f32>(spawn_acc, select(rng_f, -rng_f, regueros), f32(vivas), trail_t);
}

// Simulación de la cara de arriba (paneles 4..7): las gotas se deslizan despacio (1,2..2,4 tx/s, máx 4)
// en dirección del viento o hacia el borde más cercano del bloque con histéresis (27 §Capa 1).
fn adp_cs_simular_lluvia_arriba(panel: u32, dt: f32) {
    let c0 = datos_cuadro[ADP_CUADRO_CRISTAL_0];
    let c1 = datos_cuadro[ADP_CUADRO_CRISTAL_1];
    let c2 = datos_cuadro[ADP_CUADRO_CRISTAL_2];
    let cf = datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS];
    let co = datos_cuadro[ADP_CUADRO_CRISTAL_VAHO_OPT];

    let flags = u32(max(round(cf.x), 0.0));
    let llueve_bioma = (flags & OPC_CR_FLAG_LLUEVE_BIOMA) != 0u;
    let escala = c2.y;
    let clima = c0.x;
    let lloviendo = llueve_bioma && clima > OPC_CRISTAL_CLIMA_UMBRAL && escala > 0.001;
    let k = clamp(co.z, 0.5, 2.0);

    var hdr = cristal_sim[panel];
    var activas = u32(max(round(hdr.z), 0.0));
    var trail_t = hdr.w;
    if !lloviendo && activas == 0u && trail_t <= -0.5 {
        return;
    }

    var rng = u32(max(round(hdr.y), 1.0)) ^ (frame.frame_index * 747796405u + panel * 2891336453u + 1u);
    let idx_top = panel - 4u;
    let base = ADP_CS_OFF_ARRIBA + idx_top * ADP_CS_MAX_GOTAS_ARRIBA * 2u;
    var spawn_acc = hdr.x;
    if hdr.y == 0.0 {
        for (var i = 0u; i < ADP_CS_MAX_GOTAS_ARRIBA; i++) {
            cristal_sim[base + i * 2u] = vec4<f32>(0.0);
            cristal_sim[base + i * 2u + 1u] = vec4<f32>(0.0);
        }
        activas = 0u;
        spawn_acc = 0.0;
    }

    if lloviendo {
        spawn_acc += 10.0 * min(clima, 1.4) * escala * dt;
        var por_crear = min(u32(floor(spawn_acc)), 4u);
        spawn_acc -= f32(por_crear);
        for (var i = 0u; i < ADP_CS_MAX_GOTAS_ARRIBA; i++) {
            if por_crear == 0u || activas >= ADP_CS_MAX_GOTAS_ARRIBA {
                break;
            }
            if cristal_sim[base + i * 2u].z <= 0.0 {
                let nx = adp_cs_rand(&rng) * 128.0;
                let ny = adp_cs_rand(&rng) * 128.0;
                let tam = adp_cs_tamano_inicial(adp_cs_rand(&rng), k);
                let vel = 1.2 + adp_cs_rand(&rng) * 1.2;
                cristal_sim[base + i * 2u] = vec4<f32>(nx, ny, tam, vel);
                cristal_sim[base + i * 2u + 1u] = vec4<f32>(0.0, 0.0, 0.0, tam);
                activas += 1u;
                por_crear -= 1u;
            }
        }
    } else {
        spawn_acc = 0.0;
    }

    let viento = c1.xy;
    let hay_viento = length(viento) > 0.08;
    var vivas = 0u;
    for (var i = 0u; i < ADP_CS_MAX_GOTAS_ARRIBA; i++) {
        var d0 = cristal_sim[base + i * 2u];
        if d0.z <= 0.0 {
            continue;
        }
        var d1 = cristal_sim[base + i * 2u + 1u];

        var dir = vec2<f32>(d1.x, 0.0);
        if hay_viento {
            dir = normalize(viento);
        } else {
            // Hacia el borde más cercano del cuadro 32x32 con histéresis.
            let lx = fract(d0.x / 32.0) - 0.5;
            let ly = fract(d0.y / 32.0) - 0.5;
            if abs(lx) > abs(ly) + 0.06 {
                dir = vec2<f32>(select(-1.0, 1.0, lx >= 0.0), 0.0);
            } else if abs(ly) > abs(lx) + 0.06 {
                dir = vec2<f32>(0.0, select(-1.0, 1.0, ly >= 0.0));
            } else {
                dir = normalize(vec2<f32>(lx + 1e-4, ly));
            }
        }
        let vel = min(d0.w * select(0.4, 1.0, d0.z >= 2.5), 4.0);
        d0.x = adp_cs_wrap(d0.x + dir.x * vel * dt);
        d0.y = adp_cs_wrap(d0.y + dir.y * vel * dt);
        d1.x = dir.x;

        if lloviendo {
            d1.y = 0.0;
            d1.z = 0.0;
            d1.w = d0.z;
        } else {
            if d1.y <= 0.0 {
                let total_s = 6.0 + 18.0 * clamp(d0.z / 5.0, 0.0, 1.0) * (0.7 + 0.3 * adp_cs_rand(&rng));
                d1.y = total_s;
                d1.z = total_s;
                d1.w = d0.z;
            } else {
                d1.z -= dt;
                if d1.z <= 0.0 {
                    d0 = vec4<f32>(0.0);
                    d1 = vec4<f32>(0.0);
                } else if d1.z / max(d1.y, 0.1) < 0.60 {
                    d0.z = mix(1.0, max(d1.w, 1.0), (d1.z / max(d1.y, 0.1)) / 0.60);
                }
            }
        }

        cristal_sim[base + i * 2u] = d0;
        cristal_sim[base + i * 2u + 1u] = d1;
        if d0.z > 0.0 {
            vivas += 1u;
        }
    }

    if vivas > 0u || lloviendo {
        trail_t = 1.8;
    } else if trail_t > 0.0 {
        trail_t = max(trail_t - dt, 0.0);
    } else {
        trail_t = -1.0;
    }
    let rng_f = f32((rng & 0x7FFFFFu) + 1u);
    cristal_sim[panel] = vec4<f32>(spawn_acc, rng_f, f32(vivas), trail_t);
}

fn adp_cs_forma_copo(u: f32, k: f32) -> f32 {
    if k < 0.75 {
        // 16: 80 / 15 / 5 / 0 %
        if u < 0.80 { return 1.0; }
        if u < 0.95 { return 2.0; }
        return 3.0;
    }
    if k > 1.5 {
        // 64: 45 / 25 / 20 / 10 %
        if u < 0.45 { return 1.0; }
        if u < 0.70 { return 2.0; }
        if u < 0.90 { return 3.0; }
        return 4.0;
    }
    // 32 (base): 60 / 25 / 12 / 3 %
    if u < 0.60 { return 1.0; }
    if u < 0.85 { return 2.0; }
    if u < 0.97 { return 3.0; }
    return 4.0;
}

// Simulación de las 8 tiras globales de copos pegados (paneles 8..15; 27 v2 §Capa 3).
// Cada ranura (1 vec4): xy=pos(0..128), z=forma(1..4)+0,01*vida_total(20..60), w=<0 nevando / >0 vida restante al fundirse.
fn adp_cs_simular_copos(panel: u32, dt: f32) {
    let c0 = datos_cuadro[ADP_CUADRO_CRISTAL_0];
    let c2 = datos_cuadro[ADP_CUADRO_CRISTAL_2];
    let cf = datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS];
    let co = datos_cuadro[ADP_CUADRO_CRISTAL_VAHO_OPT];

    let flags = u32(max(round(cf.x), 0.0));
    let bioma_frio = (flags & OPC_CR_FLAG_BIOMA_FRIO) != 0u;
    let escala = c2.z;
    let clima = c0.x;
    let nevando = bioma_frio && clima > OPC_CRISTAL_CLIMA_UMBRAL && escala > 0.001;
    let k = clamp(co.z, 0.5, 2.0);

    var hdr = cristal_sim[panel];
    var activas = u32(max(round(hdr.z), 0.0));
    var limpiar = hdr.w;
    if !nevando && activas == 0u && limpiar <= -0.5 {
        return;
    }

    var rng = u32(max(round(hdr.y), 1.0)) ^ (frame.frame_index * 747796405u + panel * 2891336453u + 17u);
    let tira = panel - 8u;
    let base = ADP_CS_OFF_COPOS + tira * ADP_CS_SLOT_COPOS;
    var spawn_acc = hdr.x;
    if hdr.y == 0.0 {
        for (var i = 0u; i < ADP_CS_MAX_COPOS; i++) {
            cristal_sim[base + i] = vec4<f32>(0.0);
        }
        activas = 0u;
        spawn_acc = 0.0;
    }

    if nevando {
        let tope = min(ADP_CS_MAX_COPOS, u32(clamp(140.0 * escala * clamp(clima, 0.35, 1.4), 16.0, f32(ADP_CS_MAX_COPOS))));
        spawn_acc += 6.0 * escala * min(clima, 1.4) * dt;
        var por_crear = min(u32(floor(spawn_acc)), 4u);
        spawn_acc -= f32(por_crear);
        for (var i = 0u; i < tope; i++) {
            if por_crear == 0u || activas >= tope {
                break;
            }
            if cristal_sim[base + i].z <= 0.0 {
                let nx = floor(adp_cs_rand(&rng) * 128.0) + 0.5;
                let ny = floor(adp_cs_rand(&rng) * 128.0) + 0.5;
                let forma = adp_cs_forma_copo(adp_cs_rand(&rng), k);
                let total_s = 20.0 + adp_cs_rand(&rng) * 40.0;
                cristal_sim[base + i] = vec4<f32>(nx, ny, forma + 0.01 * total_s, -total_s);
                activas += 1u;
                por_crear -= 1u;
            }
        }
    } else {
        spawn_acc = 0.0;
    }

    var vivas = 0u;
    for (var i = 0u; i < ADP_CS_MAX_COPOS; i++) {
        var f0 = cristal_sim[base + i];
        if f0.z <= 0.0 {
            continue;
        }
        if nevando {
            let total_s = max(fract(f0.z) * 100.0, 20.0);
            f0.w = -total_s;
        } else {
            if f0.w < 0.0 {
                f0.w = abs(f0.w);
            } else {
                f0.w -= dt;
                if f0.w <= 0.0 {
                    f0 = vec4<f32>(0.0);
                }
            }
        }
        cristal_sim[base + i] = f0;
        if f0.z > 0.0 {
            vivas += 1u;
        }
    }

    if vivas > 0u || nevando {
        limpiar = 0.5;
    } else if limpiar > 0.0 {
        limpiar = 0.0;
    } else {
        limpiar = -1.0;
    }
    let rng_f = f32((rng & 0x7FFFFFu) + 1u);
    cristal_sim[panel] = vec4<f32>(spawn_acc, rng_f, f32(vivas), limpiar);
}

fn adp_cristal_sim_paso(panel: u32) {
    if !OPC_CRISTAL_ACTIVO || !adp_es_superficie() {
        if panel == 0u {
            cristal_sim[ADP_CS_RESUMEN] = vec4<f32>(0.0);
        }
        return;
    }
    let dt = clamp(frame.delta_time, 0.0, 0.10);
    if dt > 0.0 || frame.frame_index <= 1u {
        if panel < 4u {
            adp_cs_simular_lluvia_lado(panel, max(dt, 0.016));
        } else if panel < 8u {
            adp_cs_simular_lluvia_arriba(panel, max(dt, 0.016));
        } else if panel < 16u {
            adp_cs_simular_copos(panel, max(dt, 0.016));
        }
    }

    // Resume si hay algún cristal cerca en el bioma activo (coste ~0 ms cuando el tiempo está despejado o no hay cristales).
    if panel == 0u {
        let c0 = datos_cuadro[ADP_CUADRO_CRISTAL_0];
        let c2 = datos_cuadro[ADP_CUADRO_CRISTAL_2];
        let cv = datos_cuadro[ADP_CUADRO_CRISTAL_VAHO];
        let cf = datos_cuadro[ADP_CUADRO_CRISTAL_FLAGS];
        let flags = u32(max(round(cf.x), 0.0));
        let bioma_seco = (flags & OPC_CR_FLAG_BIOMA_SECO) != 0u;
        let bioma_frio = (flags & OPC_CR_FLAG_BIOMA_FRIO) != 0u;
        let llueve_bioma = (flags & OPC_CR_FLAG_LLUEVE_BIOMA) != 0u;
        let sim_viva = (cristal_sim[0].z > 0.5) || (cristal_sim[1].z > 0.5) || (cristal_sim[2].z > 0.5)
                     || (cristal_sim[3].z > 0.5) || (cristal_sim[4].z > 0.5) || (cristal_sim[8].z > 0.5);
        let lluvia_act = llueve_bioma && (c0.x > OPC_CRISTAL_CLIMA_UMBRAL) && (c2.y > 0.001);
        let frio_act = bioma_frio && ((c0.y > 0.001) || (c0.z > 0.001) || (c0.w > 0.001)) && (c2.z > 0.001);
        let arena_act = bioma_seco && (c2.x > OPC_CRISTAL_ARENA_MIN) && (c2.w > 0.001);
        let activo = sim_viva || lluvia_act || frio_act || arena_act || (cv.w > 0.001);
        var hay_cristal = 0.0;
        if activo && frame.has_ray_tracing != 0u {
            for (var t = 0u; t < ADP_CM_META_TILES; t++) {
                if cristal_mapa[ADP_CM_META_OFF + t] != 0u {
                    hay_cristal = 1.0;
                    break;
                }
            }
        }
        cristal_sim[ADP_CS_RESUMEN] = vec4<f32>(hay_cristal, select(0.0, 1.0, activo), hay_cristal, 0.0);
    }
}
