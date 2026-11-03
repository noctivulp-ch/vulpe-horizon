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
    let base = 0.5 * (adp_tabla(d.y, ATM_FILA_CIELO) + adp_tabla(d.y, ATM_FILA_SUELO)) * ATM_MULTIPLE;
    // En el crepúsculo el ambiente mantiene el gris azulado de la bóveda sobre la sombra de la Tierra (01.1).
    // Porqué: docs/efectos/cielo-y-atmosfera.md §Cinturón de Venus
    let multiple = atm_multiple_crepusculo(base, d.y, ajustes.venus);
    return AtmLuz(d, ATM_IRRADIANCIA_SOL * color, multiple * color);
}

fn adp_luz_luna(ajustes: OpcCielo) -> AtmLuz {
    let d = frame.moon_direction;
    // La luna sale por el horizonte antisolar: entra tras el crepúsculo civil para que su halo Mie no pinte de naranja
    // la sombra de la Tierra (01.1). Porqué: docs/efectos/cielo-y-atmosfera.md §Cinturón de Venus
    let peso = 1.0 - smoothstep(ajustes.venus.luna_inicio, ajustes.venus.luna_fin, frame.sun_direction.y);
    let color = ajustes.luna_color * (ajustes.luna_proporcion * peso) * ajustes.brillo;
    let multiple = 0.5 * (adp_tabla(d.y, ATM_FILA_CIELO) + adp_tabla(d.y, ATM_FILA_SUELO)) * ATM_MULTIPLE;
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

// Por encima de la capa de nubes baja la lluvia deja de velar el cielo (especificación 01).
fn adp_lluvia(ajustes: OpcCielo) -> CieLluvia {
    let bajo = vol_bajo_las_nubes(frame.camera_position.y);
    return CieLluvia(frame.rain * bajo, frame.thunder * bajo, adp_cielo_medio(ajustes));
}

// La dispersión del núcleo con la tabla de transmitancia del pack.
fn adp_dispersion(dir: vec3<f32>, sol: AtmLuz, luna: AtmLuz, ajustes: OpcCielo) -> AtmResultado {
    return atm_dispersion(adp_observador(), dir, sol, luna, atm_tierra(), AtmAjustes(ajustes.bruma, 12, ajustes.venus), transmitancia, transmitancia_sampler);
}

// Irradiancia del astro que da sombra (frame.light_direction: el sol de día, la luna de noche), tras la
// atmósfera, con el cielo cubierto por la lluvia.
fn adp_irradiancia_astro(c: OpcCielo) -> vec3<f32> {
    let d = frame.light_direction;
    var e: vec3<f32>;
    if dot(d, frame.sun_direction) > 0.0 {
        e = adp_tabla(d.y, ATM_FILA_SOL) * c.sol_color * c.brillo;
    } else {
        e = adp_tabla(d.y, ATM_FILA_SOL) * c.luna_color * c.luna_proporcion * c.brillo;
    }
    return e * (1.0 - 0.9 * clamp(frame.rain, 0.0, 1.0));
}
