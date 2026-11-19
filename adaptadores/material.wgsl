// MaterialInput -> punto de superficie del núcleo, y vuelta a Surface (codificada, ADR 0004).
// Porqué: docs/efectos/luz-de-superficie.md §Adaptadores

struct AdpPunto {
    albedo: vec3<f32>,      // lineal, sin el sombreado por cara de vanilla
    alfa: f32,
    normal_cara: vec3<f32>, // geométrica
    normal: vec3<f32>,      // con el mapa de normales, si lo hay
    vista: vec3<f32>,       // hacia la cámara
    posicion: vec3<f32>,    // relativa a la cámara
    mundo: vec3<f32>,
    luz_bloque: f32,
    luz_cielo: f32,
    material: u32,
    emision_bloque: f32,
    translucido: bool,
    fluido: u32,
    cruzada: bool,          // planta de planos cruzados: N·L fijo
    pbr: SupMaterial,
    pixel: vec2<f32>,
    luz_colorida: vec3<f32>,
    desplazado: f32,
    altura_mapa: f32,
    con_pbr: bool,
    ao_vertice: f32,
}

fn adp_es_cruzada(m: u32) -> bool {
    return m == OPC_MAT_PLANTA_FUERTE || m == OPC_MAT_PLANTA_MEDIA || m == OPC_MAT_PLANTA_ALTA_ARRIBA || m == OPC_MAT_COLGANTES;
}

// El tinte de vanilla lleva un sombreado fijo por cara (arriba 1; abajo 0,5; norte/sur 0,8; este/oeste
// 0,6) que se sumaría al direccional real: se divide.
fn adp_sombreado_vanilla(n: vec3<f32>) -> f32 {
    let n2 = n * n;
    return select(0.5, 1.0, n.y > 0.0) * n2.y + 0.8 * n2.z + 0.6 * n2.x;
}

fn adp_sss_lista(m: u32) -> f32 {
    switch m {
        case 1u, 2u, 3u, 8u: { return 0.9; }
        case 4u, 5u, 9u: { return 0.6; }
        case 6u: { return 0.3; }
        default: { return 0.0; }
    }
}

fn adp_material_punto(input: MaterialInput, o: OpcLuz) -> AdpPunto {
    var p: AdpPunto;
    p.material = input.material;
    p.cruzada = adp_es_cruzada(input.material);
    let tinte_gamma = adp_lineal_a_gamma22(input.shaded_tint.rgb);
    let sombreado = max(adp_sombreado_vanilla(input.normal), 0.5);
    // La oclusión de vértice va en el tinte junto al color del bioma: el canal mayor, no la luminancia, para que el verde del
    // pasto no cuente como sombra (F-59). Porqué: docs/efectos/luz-de-superficie.md §«Noche y cuevas (F-59)»
    // En los bloques con color de bioma (tinte no gris) se divide además por el canal mayor de un verde típico de pasto.
    let tinte_max = max(tinte_gamma.r, max(tinte_gamma.g, tinte_gamma.b));
    let bioma_tinte = max(abs(tinte_gamma.r - tinte_gamma.g), abs(tinte_gamma.g - tinte_gamma.b)) > 0.03;
    let ref_bioma = select(1.0, OPC_AO_REF_BIOMA, bioma_tinte);
    p.ao_vertice = select(clamp(tinte_max / (sombreado * ref_bioma), 0.0, 1.0), 1.0, p.cruzada);
    let sombreado_lin = select(pow(sombreado, 2.2), 1.0, p.cruzada);
    p.albedo = mat_saturar3(input.albedo.rgb * (input.shaded_tint.rgb / sombreado_lin));
    // Estaciones (03.2): solo los bloques con color de bioma (tinte no blanco), y las hojas con su propio tinte. Con
    // mod nativo sigue la estación continua del mundo; sin mod nativo, queda fija en la estación inicial.
    let con_bioma = bioma_tinte;
    let est_act = adp_mod_param(18u, 0.0, 1.0, VULPE_ESTACIONES_ACTIVA, 1.0) >= 0.5;
    if estaciones && est_act && con_bioma && adp_es_superficie() {
        let m = adp_mod();
        let est_dias = adp_mod_param(19u, 1.0, 120.0, VULPE_ESTACION_DURACION_DIAS, 24.0);
        if m.tiene_estacion {
            p.albedo = sup_estacion_mod(p.albedo, m.estacion, input.material == OPC_MAT_HOJAS);
        } else {
            p.albedo = sup_estacion(p.albedo, 0.0, est_dias, i32(estacion_inicial), input.material == OPC_MAT_HOJAS);
        }
    }
    // Infrarrojo (24): la vegetación a rosa, antes de iluminar. Porqué: docs/efectos/varios.md
    if OPC_INFRARROJO > 0.0 {
        let m = input.material;
        let planta = m == OPC_MAT_HOJAS || m == OPC_MAT_PLANTA_FUERTE || m == OPC_MAT_PLANTA_MEDIA
                  || m == OPC_MAT_PLANTA_ALTA_ARRIBA || m == OPC_MAT_COLGANTES || con_bioma;
        if planta {
            p.albedo = sup_infrarrojo(p.albedo, OPC_INFRARROJO_COLOR, OPC_INFRARROJO);
        }
    }
    p.alfa = input.albedo.a;
    p.normal_cara = input.normal;
    p.posicion = input.position;
    p.mundo = input.position + frame.camera_position;
    p.vista = normalize(-input.position);
    // Recorte de las luces de vanilla, lo primero (implementacion/01 §0): −0,05 y reescala; «casi nada» pasa a cero.
    p.luz_bloque = luz_recorte_vanilla(input.light.x);
    p.luz_cielo = luz_recorte_vanilla(input.light.y);
    p.emision_bloque = input.emission;
    p.translucido = input.translucent;
    p.fluido = input.fluid;
    p.pixel = input.screen * frame.resolution;
    p.luz_colorida = select(vec3<f32>(0.0), input.colored_light, o.luz_mano > 0u);
    p.desplazado = input.displaced;

    let con_pbr = block_pbr_maps();
    p.con_pbr = con_pbr;
    if con_pbr {
        p.pbr = sup_labpbr(block_specular_map(input.uv), p.albedo);
        let mapa_n = block_normal_map(input.uv);
        p.normal = sup_normal_mapa(mapa_n, input.normal, input.tangent, o.normales_intensidad);
        // Oclusión del material (24): apagada por defecto en el original. Porqué: docs/efectos/varios.md
        if OPC_OCLUSION_MATERIAL {
            p.albedo *= 0.5 + 0.5 * mapa_n.b;
        }
        p.altura_mapa = sup_relieve_normalizar_altura(mapa_n.a, opc_relieve().piso_altura);
    } else {
        p.pbr = SupMaterial(0.15, 0.7225, vec3<f32>(0.04), false, 0.0, 0.0, 0.0);
        p.normal = input.normal;
        p.altura_mapa = 1.0;
    }
    var sss = 0.0;
    if o.sss_lista {
        sss = adp_sss_lista(input.material);
    }
    if o.sss_labpbr && con_pbr && p.pbr.sss > 0.0 {
        sss = p.pbr.sss;
    }
    p.pbr.sss = sss * o.sss_brillo;
    return p;
}

struct AdpSombra {
    luz: vec3<f32>,         // 0..1 por canal
    grosor: f32,            // distancia al ocluyente hacia la luz, bloques
}

fn adp_sombra(p: AdpPunto) -> AdpSombra {
    if opc_quitar(128u) {
        return AdpSombra(vec3<f32>(1.0), 0.0);
    }
    let r = adp_sombra_punto(AdpEntradaSombra(p.posicion, p.normal_cara, p.luz_cielo, p.pixel), opc_sombras());
    var nubes = 1.0;
    if !opc_quitar(2048u) && (!adp_sombra_nubes_en_post() || p.translucido || p.fluido == 1u) {
        nubes = mix(1.0, adp_sombra_nubes_cuadro(p.mundo), opc_volumen().sombra_nubes);
    }
    let horizonte = luz_sombra_horizonte(p.mundo.y, adp_elev_sol_cuadro(), OPC_SOMBRA_HORIZONTE);
    return AdpSombra(r.luz * nubes * horizonte, r.grosor);
}

// Color de la luz de bloque: el de [[lights]] cercano, si lo hay.
fn adp_color_luz_bloque(p: AdpPunto, o: OpcLuz) -> vec3<f32> {
    let tinte = block_light_color(p.posicion);
    return mix(o.bloque_color, tinte.rgb, min(tinte.a, 1.0));
}

fn adp_material_salida(color: vec3<f32>, alfa: f32, p: AdpPunto) -> Surface {
    if opc_depuracion().vista == OPC_VISTA_RELIEVE {
        let dbg = vec3<f32>(
            clamp(p.desplazado, 0.0, 1.0),
            clamp(p.altura_mapa, 0.0, 1.0),
            select(0.0, 1.0, p.con_pbr),
        );
        return Surface(vec4<f32>(dbg, alfa));
    }
    let v = col_codificar_escena(color, adp_codificacion());
    return Surface(vec4<f32>(v, alfa));
}

// Menas brillantes (12): las 16 muestras del sprite a mip 0 (block_texture lee el mismo sprite: sin mezcla con los
// vecinos del atlas) y la emisión que resulta, con el albedo aclarado en el carbón.
struct AdpMena {
    emision: f32,
    albedo: vec3<f32>,
    fuente: bool,           // bloque de mena: fuente de la luz de las menas (25)
    mineral: vec3<f32>,     // color del mineral del bloque (sRGB): la más saturada de las 16 muestras del sprite
}

fn adp_mena(input: MaterialInput, albedo: vec3<f32>) -> AdpMena {
    let o = opc_menas();
    if !o.activas || input.material != OPC_MAT_MENA {
        return AdpMena(0.0, albedo, false, vec3<f32>(0.0));
    }
    var m: array<vec3<f32>, 16>;
    var mineral = vec3<f32>(0.0);
    var sat_max = -1.0;
    for (var k = 0; k < 16; k++) {
        let uv = (vec2<f32>(f32(k / 4), f32(k % 4)) + 0.5) * 0.25;
        m[k] = adp_lineal_a_gamma22(block_texture_level(uv, 0.0).rgb);
        let sat = sup_matiz_sat(m[k]).y;
        if sat > sat_max {
            sat_max = sat;
            mineral = m[k];
        }
    }
    let r = sup_mena(adp_lineal_a_gamma22(input.albedo.rgb), m, f32(menas_umbral) * 0.01, OPC_MENAS_CARBON);
    let aclarado = mix(albedo, max(albedo, vec3<f32>(col_srgb_a_lineal(vec3<f32>(0.3)).x)), r.oscuro);
    return AdpMena(min(r.mascara * o.intensidad, 0.99), aclarado, true, mineral);
}

// Efectos de clima sobre el suelo según el bioma (16, observaciones 2026-11-13 §5.3):
// lluvia (mojado y charcos), bioma nevado (escarcha sutil con motas cristalinas) y desierto
// (granos de arena movidos por el viento). Porqué: docs/efectos/suelo-clima.md
struct AdpSueloClima {
    albedo: vec3<f32>,
    normal: vec3<f32>,
    pbr: SupMaterial,
    destello_escarcha: f32,
}

fn adp_suelo_clima(p: AdpPunto, o: OpcLuz, luz_dir: vec3<f32>) -> AdpSueloClima {
    var r = AdpSueloClima(p.albedo, p.normal, p.pbr, 0.0);
    if !(o.charcos || o.mojado) || !adp_es_superficie() || p.fluido != 0u || r.pbr.metal {
        return r;
    }
    let clima = adp_clima_local_cuadro();
    if clima.tipo == 2u {
        // Bioma nevado: escarcha sutil en caras de arriba, sin charcos ni oscurecimiento.
        if clima.peso > 0.0 {
            let pe = opc_escarcha();
            let e = sup_escarcha(p.mundo, p.luz_cielo, p.normal_cara.y, p.vista, luz_dir, length(p.posicion), clima.peso, pe);
            r.albedo = sup_albedo_escarcha(r.albedo, e, pe);
            r.pbr.suavidad = mix(r.pbr.suavidad, pe.mota_suavidad, e.mota);
            r.pbr.f0 = mix(r.pbr.f0, vec3<f32>(pe.mota_f0), e.mota);
            r.pbr.rugosidad = (1.0 - r.pbr.suavidad) * (1.0 - r.pbr.suavidad);
            r.destello_escarcha = e.destello;
        }
        return r;
    }
    if clima.tipo == 1u {
        // Bioma desértico: granos movidos en las caras de arriba de la arena, sin charcos.
        if clima.peso > 0.0 && p.material == OPC_MAT_ARENA {
            let pa = opc_arena_viento();
            let mod_datos = adp_mod();
            let dia = u32(max(select(0.0, mod_datos.dia, mod_datos.tiene_tiempo), 0.0));
            let nivel = adp_tormenta_nivel(dia);
            let a = sup_arena_viento(
                p.mundo, p.luz_cielo, p.normal_cara.y,
                normalize(OPC_VIENTO), adp_tiempo().segundos, clima.peso, nivel, length(p.posicion), pa,
            );
            r.albedo = sup_albedo_arena_viento(r.albedo, a, pa.contraste);
            r.normal = normalize(r.normal + vec3<f32>(a.pendiente_xz.x, 0.0, a.pendiente_xz.y));
        }
        return r;
    }
    // Lluvia en biomas donde llueve: mojado y charcos.
    if frame.precipitation == 1u && frame.wetness > 0.0 {
        let h = sup_humedad(frame.wetness, p.luz_cielo, p.mundo, p.normal_cara.y, adp_tiempo().segundos);
        let mojado = select(0.0, h.mojado, o.mojado);
        let charco = select(0.0, h.charco, o.charcos);
        r.albedo = sup_albedo_mojado(r.albedo, max(mojado, charco), r.pbr.porosidad);
        r.pbr.suavidad = mix(r.pbr.suavidad, 0.85, mojado * 0.6);
        r.pbr.suavidad = mix(r.pbr.suavidad, 0.97, charco);
        r.pbr.f0 = mix(r.pbr.f0, vec3<f32>(0.02), charco);
        r.normal = normalize(mix(r.normal, p.normal_cara, charco));
        r.pbr.rugosidad = (1.0 - r.pbr.suavidad) * (1.0 - r.pbr.suavidad);
    }
    return r;
}
