// Dispersión simple a lo largo de un rayo de vista, para hasta dos astros, con aproximación de la
// dispersión múltiple. Porqué: docs/efectos/cielo-y-atmosfera.md §Modelo

struct AtmLuz {
    direccion: vec3<f32>,   // unitaria, hacia el astro
    irradiancia: vec3<f32>, // en lo alto de la atmósfera, escala común
    multiple: vec3<f32>,    // radiancia media del cielo y el suelo que ve un punto del aire (dispersión múltiple)
}

struct AtmAjustes {
    bruma: f32,             // multiplicador de aerosoles
    pasos: i32,             // tramos del rayo de vista
}

struct AtmResultado {
    luz: vec3<f32>,             // radiancia dispersada hacia el ojo
    transmitancia: vec3<f32>,   // del ojo al final del rayo
}

// Aporte de un astro en un punto del rayo: dispersión simple por fase más el término isótropo. `hacia` es la
// transmitancia del punto al astro (la da quien llama: tabla o integración).
fn atm_aporte_luz(cos_vista: f32, medio: AtmMedio, hacia: vec3<f32>, luz: AtmLuz, p: AtmParametros) -> vec3<f32> {
    let fase = medio.rayleigh * atm_fase_rayleigh(cos_vista) + vec3<f32>(medio.mie * atm_fase_cornette_shanks(cos_vista, p.mie_asimetria));
    let multiple = (medio.rayleigh + vec3<f32>(medio.mie)) * luz.multiple;
    return fase * hacia * luz.irradiancia + multiple;
}

// Qué astros aportan: la luna solo con el sol bajo (su luz es una pequeña fracción de la del sol), y
// ninguno muy por debajo del horizonte.
struct AtmAstrosActivos {
    sol: bool,
    luna: bool,
}

fn atm_astros_activos(sol: AtmLuz, luna: AtmLuz) -> AtmAstrosActivos {
    return AtmAstrosActivos(sol.direccion.y > -0.35, luna.direccion.y > -0.35 && sol.direccion.y < 0.1);
}

// Transmitancia de `pos` (m desde el centro) hacia la dirección unitaria `dir`, leída de la tabla de
// transmitancia; 0 si el planeta tapa. La tabla llega por parámetro: el núcleo no sabe de dónde sale.
fn atm_hacia_astro(pos: vec3<f32>, dir: vec3<f32>, p: AtmParametros, tabla: texture_2d<f32>, muestreo: sampler) -> vec3<f32> {
    let r = length(pos);
    let mu = dot(pos, dir) / r;
    let horizonte = -sqrt(max(1.0 - (p.radio_planeta / r) * (p.radio_planeta / r), 0.0));
    if mu < horizonte {
        return vec3<f32>(0.0);
    }
    let c = textureSampleLevel(tabla, muestreo, atm_transmitancia_uv(r, mu, p), 0.0).rgb;
    return atm_transmitancia_decodificar(c);
}

// `origen` en m desde el centro del planeta, `dir` unitaria; `tabla`/`muestreo`: la de transmitancia.
fn atm_dispersion(origen: vec3<f32>, dir: vec3<f32>, sol: AtmLuz, luna: AtmLuz, p: AtmParametros, ajustes: AtmAjustes, tabla: texture_2d<f32>, muestreo: sampler) -> AtmResultado {
    let atm = atm_esfera(origen, dir, p.radio_atmosfera);
    if atm.y <= 0.0 {
        return AtmResultado(vec3<f32>(0.0), vec3<f32>(1.0));
    }
    let inicio = max(atm.x, 0.0);
    var fin = atm.y;
    let suelo = atm_esfera(origen, dir, p.radio_planeta);
    if suelo.x > 0.0 {
        fin = suelo.x;
    }
    let paso = (fin - inicio) / f32(ajustes.pasos);
    let cos_sol = dot(dir, sol.direccion);
    let cos_luna = dot(dir, luna.direccion);
    let activos = atm_astros_activos(sol, luna);
    var transmitancia = vec3<f32>(1.0);
    var luz = vec3<f32>(0.0);
    for (var i = 0; i < ajustes.pasos; i++) {
        let pos = origen + dir * (inicio + paso * (f32(i) + 0.5));
        let medio = atm_medio(length(pos) - p.radio_planeta, p, ajustes.bruma);
        var fuente = vec3<f32>(0.0);
        if activos.sol {
            fuente += atm_aporte_luz(cos_sol, medio, atm_hacia_astro(pos, sol.direccion, p, tabla, muestreo), sol, p);
        }
        if activos.luna {
            fuente += atm_aporte_luz(cos_luna, medio, atm_hacia_astro(pos, luna.direccion, p, tabla, muestreo), luna, p);
        }
        // Integración analítica dentro del tramo (Hillaire 2015): ∫ e^{−σx} dx = (1 − e^{−σΔ}) / σ.
        let ext = max(medio.extincion, vec3<f32>(1e-12));
        let t_tramo = exp(-ext * paso);
        luz += transmitancia * fuente * (1.0 - t_tramo) / ext;
        transmitancia *= t_tramo;
    }
    return AtmResultado(luz, transmitancia);
}
