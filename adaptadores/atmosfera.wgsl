// La atmósfera vista desde la cámara: tabla precalculada, astros y observador.
// Porqué: docs/efectos/cielo-y-atmosfera.md §Adaptadores

fn adp_tabla(seno_elevacion: f32, fila: f32) -> vec3<f32> {
    let c = textureSampleLevel(atmosfera, atmosfera_sampler, atm_tabla_uv(seno_elevacion, fila), 0.0).rgb;
    return atm_tabla_decodificar(c);
}

// Posición del ojo en el modelo de la atmósfera, m desde el centro del planeta. Por encima de y = 200 sube
// 20 m por bloque, para que volar muy alto se note.
fn adp_observador() -> vec3<f32> {
    let extra = max(frame.camera_position.y - 200.0, 0.0) * 20.0;
    return vec3<f32>(0.0, atm_tierra().radio_planeta + ATM_ALTURA_OBSERVADOR + extra, 0.0);
}

fn adp_luz_sol(ajustes: OpcCielo) -> AtmLuz {
    let d = frame.sun_direction;
    let color = ajustes.sol_color;
    let base = 0.5 * (adp_tabla(d.y, ATM_FILA_CIELO) + adp_tabla(d.y, ATM_FILA_SUELO)) * ATM_MULTIPLE
             * atm_refuerzo_crepuscular(degrees(asin(clamp(d.y, -1.0, 1.0))));
    // En el crepúsculo el ambiente mantiene el gris azulado de la bóveda sobre la sombra de la Tierra (01.1).
    // Porqué: docs/efectos/cielo-y-atmosfera.md §Cinturón de Venus
    let multiple = atm_multiple_crepusculo(base, d.y, ajustes.venus);
    return AtmLuz(d, ATM_IRRADIANCIA_SOL * color, multiple * color);
}

// Modulación de la luz de la luna según la fase lunar (formato v1 del mod nativo) y estilo_noches.
fn adp_luna_factor_fase() -> f32 {
    let mn = opc_estilo_noches();
    if !mn.sigue_fases {
        return 1.0;
    }
    let m = adp_mod();
    if !m.tiene_tiempo {
        return 1.0;
    }
    return abs(4.0 - f32(m.fase_luna)) / 4.0;
}

fn adp_luz_luna(ajustes: OpcCielo) -> AtmLuz {
    let d = frame.moon_direction;
    let crepusculo = 1.0 - smoothstep(ajustes.venus.luna_inicio, ajustes.venus.luna_fin, frame.sun_direction.y);
    let peso = crepusculo * adp_luna_factor_fase();
    let color = ajustes.luna_color * (ajustes.luna_proporcion * peso);
    let multiple = 0.5 * (adp_tabla(d.y, ATM_FILA_CIELO) + adp_tabla(d.y, ATM_FILA_SUELO)) * ATM_MULTIPLE;
    return AtmLuz(d, ATM_IRRADIANCIA_SOL * color, multiple * color);
}

// Radiancia media del cielo de este momento (sol + luna), para quien necesite su tono.
fn adp_cielo_medio(ajustes: OpcCielo) -> vec3<f32> {
    let sol = adp_tabla(frame.sun_direction.y, ATM_FILA_CIELO) * ajustes.sol_color;
    let luna = adp_tabla(frame.moon_direction.y, ATM_FILA_CIELO) * ajustes.luna_color * (ajustes.luna_proporcion * adp_luna_factor_fase());
    return (sol + luna) * ajustes.brillo;
}

fn adp_suelo(ajustes: OpcCielo) -> vec3<f32> {
    let sol = adp_tabla(frame.sun_direction.y, ATM_FILA_SUELO) * ajustes.sol_color;
    let luna = adp_tabla(frame.moon_direction.y, ATM_FILA_SUELO) * ajustes.luna_color * (ajustes.luna_proporcion * adp_luna_factor_fase());
    return (sol + luna) * ajustes.brillo;
}

// Por encima de la capa de nubes baja la lluvia deja de velar el cielo (especificación 01).
fn adp_lluvia(ajustes: OpcCielo) -> CieLluvia {
    let bajo = vol_bajo_las_nubes(frame.camera_position.y);
    return CieLluvia(frame.rain * bajo, frame.thunder * bajo, adp_cielo_medio(ajustes));
}

// La dispersión del núcleo con la tabla de transmitancia del pack.
fn adp_dispersion(dir: vec3<f32>, sol: AtmLuz, luna: AtmLuz, ajustes: OpcCielo) -> AtmResultado {
    var p = atm_tierra();
    let mc = opc_estilo_cielo();
    let aire_mod = vec3<f32>(
        adp_mod_param(1u, 0.0, 2.0, VULPE_AIRE_COLOR_R, 1.0),
        adp_mod_param(2u, 0.0, 2.0, VULPE_AIRE_COLOR_G, 1.0),
        adp_mod_param(3u, 0.0, 2.0, VULPE_AIRE_COLOR_B, 1.0),
    );
    let aero_mod = (
        adp_mod_param(4u, 0.0, 5.0, VULPE_BRUMA_AEROSOLES_R, 1.0) +
        adp_mod_param(5u, 0.0, 5.0, VULPE_BRUMA_AEROSOLES_G, 1.0) +
        adp_mod_param(6u, 0.0, 5.0, VULPE_BRUMA_AEROSOLES_B, 1.0)
    ) / 3.0;
    let asim_mod = adp_mod_param(7u, 0.0, 1.0, VULPE_HALO_ASIMETRIA, 0.8);
    p.rayleigh_dispersion *= mc.aire * aire_mod;
    p.mie_dispersion *= mc.aerosoles * aero_mod;
    p.mie_absorcion *= mc.aerosoles * aero_mod;
    p.mie_asimetria = clamp(mc.asimetria + (asim_mod - 0.8), 0.0, 0.99);
    return atm_dispersion(adp_observador(), dir, sol, luna, p, AtmAjustes(ajustes.bruma, 12, ajustes.venus), transmitancia, transmitancia_sampler);
}

// Irradiancia del astro que da sombra (frame.light_direction: el sol de día, la luna de noche), tras la
// atmósfera, con rampa de horizonte que anula a <= 0° y color enrojecido medido en paridad/01.
fn adp_irradiancia_astro(c: OpcCielo) -> vec3<f32> {
    let d = frame.light_direction;
    let elev_sol = degrees(asin(clamp(frame.sun_direction.y, -1.0, 1.0)));
    var e: vec3<f32>;
    if dot(d, frame.sun_direction) > 0.0 {
        e = atm_luz_directa_sol(elev_sol) * c.sol_color;
    } else {
        let peso = adp_luna_factor_fase();
        e = atm_luz_directa_luna(elev_sol) * c.luna_color * peso;
    }
    // Con lluvia el sol no se apaga aparte: lo tapan las nubes del perfil de lluvia con su sombra (fino/01 §7).
    return e;
}
