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
    var tinte = input.tint.rgb;
    let sombreado = max(adp_sombreado_vanilla(input.normal), 0.5);
    if !p.cruzada {
        tinte /= sombreado;
    }
    p.ao_vertice = select(clamp(col_luminancia(input.tint.rgb) / sombreado, 0.0, 1.0), 1.0, p.cruzada);
    p.albedo = col_srgb_a_lineal(mat_saturar3(input.albedo.rgb * tinte));
    // Estaciones (03.2): solo los bloques con color de bioma (tinte no blanco), y las hojas con su propio tinte. Con
    // mod nativo sigue la estación continua del mundo; sin mod nativo, queda fija en la estación inicial.
    let con_bioma = max(abs(input.tint.r - input.tint.g), abs(input.tint.g - input.tint.b)) > 0.03;
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
        p.albedo *= 0.5 + 0.5 * mapa_n.b;
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

struct AdpLuces {
    fija: bool,             // ambiente de dimensión (17): no depende de la luz de cielo de Minecraft
    direccion: vec3<f32>,   // hacia el astro que da sombra (sol de día, luna de noche)
    directa: vec3<f32>,     // irradiancia perpendicular tras la atmósfera (π = sol de mediodía)
    cielo: vec3<f32>,       // radiancia media del cielo (ambiente)
    suelo: vec3<f32>,
}

fn adp_luces(o: OpcLuz) -> AdpLuces {
    if !adp_es_superficie() {
        // Nether y End (17): sin sol ni cielo; un ambiente propio, hemisférico (en el Nether, más desde abajo).
        let fc = frame.fog_color;
        if frame.dimension == -1 {
            let bruma = col_srgb_a_lineal(fc / max(max(fc.r, max(fc.g, fc.b)), 1e-3));
            return AdpLuces(true, vec3<f32>(0.0, 1.0, 0.0), vec3<f32>(0.0), bruma * OPC_AMBIENTE_NETHER * 0.6, bruma * OPC_AMBIENTE_NETHER * 1.4);
        }
        let azul = vec3<f32>(0.55, 0.6, 1.0) * OPC_AMBIENTE_END;
        return AdpLuces(true, vec3<f32>(0.0, 1.0, 0.0), vec3<f32>(0.0), azul, azul * 0.7);
    }
    let c = opc_cielo();
    let d = frame.light_direction;
    let directa = adp_irradiancia_astro(c);
    // Ambiente medido de paridad/01, filtrado por las nubes del momento (F-12).
    let cielo = adp_ambiente_cielo() * o.cielo;
    return AdpLuces(false, d, directa, cielo, adp_suelo(c) * o.cielo * OPC_LUZ_CIELO_BASE);
}

struct AdpSombra {
    luz: vec3<f32>,         // 0..1 por canal
    grosor: f32,            // distancia al ocluyente hacia la luz, bloques
}

fn adp_sombra(p: AdpPunto) -> AdpSombra {
    let r = adp_sombra_punto(AdpEntradaSombra(p.posicion, p.normal_cara, p.luz_cielo, p.pixel), opc_sombras());
    let nubes = mix(1.0, adp_sombra_nubes(p.mundo), opc_volumen().sombra_nubes);
    let elev_sol = degrees(asin(clamp(frame.sun_direction.y, -1.0, 1.0)));
    let horizonte = luz_sombra_horizonte(p.mundo.y, elev_sol, OPC_SOMBRA_HORIZONTE);
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
    let tramado = (rui_tramado_ign(p.pixel) - 0.5) / 255.0;
    return Surface(vec4<f32>(v + tramado, alfa));
}

// Menas brillantes (12): las 16 muestras del sprite a mip 0 (block_texture lee el mismo sprite: sin mezcla con los
// vecinos del atlas) y la emisión que resulta, con el albedo aclarado en el carbón.
struct AdpMena {
    emision: f32,
    albedo: vec3<f32>,
}

fn adp_mena(input: MaterialInput, albedo: vec3<f32>) -> AdpMena {
    let o = opc_menas();
    if !o.activas || input.material != OPC_MAT_MENA {
        return AdpMena(0.0, albedo);
    }
    var m: array<vec3<f32>, 16>;
    for (var k = 0; k < 16; k++) {
        let uv = (vec2<f32>(f32(k / 4), f32(k % 4)) + 0.5) * 0.25;
        m[k] = block_texture_level(uv, 0.0).rgb;
    }
    let r = sup_mena(input.albedo.rgb, m, f32(menas_umbral) * 0.01, OPC_MENAS_CARBON);
    let aclarado = mix(albedo, max(albedo, vec3<f32>(col_srgb_a_lineal(vec3<f32>(0.3)).x)), r.oscuro);
    return AdpMena(min(r.mascara * o.intensidad, 0.99), aclarado);
}
