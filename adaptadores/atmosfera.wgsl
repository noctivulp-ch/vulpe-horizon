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
    let color = ajustes.sol_color * ajustes.brillo;
    let multiple = 0.5 * (adp_tabla(d.y, ATM_FILA_CIELO) + adp_tabla(d.y, ATM_FILA_SUELO)) * OPC_MULTIPLE_REFUERZO;
    return AtmLuz(d, ATM_IRRADIANCIA_SOL * color, multiple * color);
}

fn adp_luz_luna(ajustes: OpcCielo) -> AtmLuz {
    let d = frame.moon_direction;
    let color = ajustes.luna_color * ajustes.luna_proporcion * ajustes.brillo;
    let multiple = 0.5 * (adp_tabla(d.y, ATM_FILA_CIELO) + adp_tabla(d.y, ATM_FILA_SUELO)) * OPC_MULTIPLE_REFUERZO;
    return AtmLuz(d, ATM_IRRADIANCIA_SOL * color, multiple * color);
}

// Radiancia media del cielo de este momento (sol + luna), para quien necesite su tono.
fn adp_cielo_medio(ajustes: OpcCielo) -> vec3<f32> {
    let sol = adp_tabla(frame.sun_direction.y, ATM_FILA_CIELO) * ajustes.sol_color;
    let luna = adp_tabla(frame.moon_direction.y, ATM_FILA_CIELO) * ajustes.luna_color * ajustes.luna_proporcion;
    return (sol + luna) * ajustes.brillo;
}

fn adp_suelo(ajustes: OpcCielo) -> vec3<f32> {
    let sol = adp_tabla(frame.sun_direction.y, ATM_FILA_SUELO) * ajustes.sol_color;
    let luna = adp_tabla(frame.moon_direction.y, ATM_FILA_SUELO) * ajustes.luna_color * ajustes.luna_proporcion;
    return (sol + luna) * ajustes.brillo;
}

fn adp_lluvia(ajustes: OpcCielo) -> CieLluvia {
    return CieLluvia(frame.rain, frame.thunder, adp_cielo_medio(ajustes));
}

// La dispersión del núcleo con la tabla de transmitancia del pack.
fn adp_dispersion(dir: vec3<f32>, sol: AtmLuz, luna: AtmLuz, ajustes: OpcCielo) -> AtmResultado {
    return atm_dispersion(adp_observador(), dir, sol, luna, atm_tierra(), AtmAjustes(ajustes.bruma, 12), transmitancia, transmitancia_sampler);
}
