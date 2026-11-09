// Dispersión simple a lo largo de un rayo de vista, para hasta dos astros, con aproximación de la
// dispersión múltiple. Porqué: docs/efectos/cielo-y-atmosfera.md §Modelo

struct AtmLuz {
    direccion: vec3<f32>,   // unitaria, hacia el astro
    irradiancia: vec3<f32>, // en lo alto de la atmósfera, escala común
    multiple: vec3<f32>,    // radiancia media del cielo y el suelo que ve un punto del aire (dispersión múltiple)
}

struct AtmVenus {
    sol_min: f32,
    sol_max: f32,
    verde_naranja: f32,
    verde_azul: f32,
    rojo_ozono: f32,
    multiple_local: f32,
    color: vec3<f32>,
    altura_fin: f32,
    sombra_color: vec3<f32>,
    sombra_piso: f32,
    sombra_limbo: f32,
    refraccion: f32,
    luna_inicio: f32,
    luna_fin: f32,
    elevacion_fin: f32,     // seno de la elevación de la mirada donde acaba la banda del cinturón
}

struct AtmAjustes {
    bruma: f32,             // multiplicador de aerosoles
    pasos: i32,             // tramos del rayo de vista
    venus: AtmVenus,
}

struct AtmResultado {
    luz: vec3<f32>,             // radiancia dispersada hacia el ojo
    transmitancia: vec3<f32>,   // del ojo al final del rayo
}

// Peso continuo del crepúsculo por altura del sol. Porqué: docs/efectos/cielo-y-atmosfera.md §Cinturón de Venus
fn atm_peso_crepusculo(seno_sol: f32, v: AtmVenus) -> f32 {
    return smoothstep(v.sol_min, -0.04, seno_sol) * (1.0 - smoothstep(0.02, v.sol_max, seno_sol));
}

// Dispersión múltiple ambiente del sol: en el crepúsculo mantiene el gris azulado de la bóveda sobre la sombra de la
// Tierra, evitando que el hueco verde del ozono en la tabla la tiña de magenta. Porqué: docs/efectos/cielo-y-atmosfera.md §Cinturón de Venus
fn atm_multiple_crepusculo(base: vec3<f32>, seno_sol: f32, v: AtmVenus) -> vec3<f32> {
    let crep = atm_peso_crepusculo(seno_sol, v);
    let lum = col_luminancia(base);
    let piso = v.sombra_piso * smoothstep(-0.12, -0.01, seno_sol) * (1.0 - smoothstep(0.02, 0.14, seno_sol));
    let sombra = max(lum, piso) * v.sombra_color;
    return mix(base, sombra, crep);
}

// Aporte de un astro en un punto del rayo: dispersión simple por fase más el término isótropo. `hacia` es la
// transmitancia del punto al astro (la da quien llama: tabla o integración).
fn atm_aporte_luz(cos_vista: f32, medio: AtmMedio, hacia: vec3<f32>, luz: AtmLuz, p: AtmParametros) -> vec3<f32> {
    let fase = medio.rayleigh * atm_fase_elek(cos_vista) + vec3<f32>(medio.mie * atm_fase_cornette_shanks(cos_vista, p.mie_asimetria));
    let multiple = (medio.rayleigh + vec3<f32>(medio.mie)) * luz.multiple;
    return fase * hacia * luz.irradiancia + multiple;
}

// Aporte del sol con corrección espectral de tres canales en el camino rasante por el ozono y dispersión múltiple
// cálida en la banda del cinturón de Venus. Porqué: docs/efectos/cielo-y-atmosfera.md §Cinturón de Venus
// `vista_y`: seno de la elevación de la mirada; la banda del cinturón solo existe cerca del horizonte.
fn atm_aporte_sol(cos_vista: f32, vista_y: f32, altura: f32, medio: AtmMedio, hacia: vec3<f32>, sol: AtmLuz, p: AtmParametros, v: AtmVenus) -> vec3<f32> {
    let crep = atm_peso_crepusculo(sol.direccion.y, v);
    let anti = (1.0 - smoothstep(-0.5, -0.1, cos_vista)) * crep;
    let enrojecida = max(hacia.r - hacia.b, 0.0);
    var hacia_corr = hacia;
    if crep > 0.0 {
        let verde_piso = hacia.r * v.verde_naranja + hacia.b * v.verde_azul;
        hacia_corr.g = max(hacia.g, verde_piso);
        let azul_estrat = hacia.b * (1.0 - hacia.g / max(hacia.r, 1e-5));
        hacia_corr.r = hacia.r * (1.0 - v.rojo_ozono * clamp(azul_estrat, 0.0, 1.0));
    }

    let fase = medio.rayleigh * atm_fase_elek(cos_vista) + vec3<f32>(medio.mie * atm_fase_cornette_shanks(cos_vista, p.mie_asimetria));
    let banda_h = smoothstep(1500.0, 4500.0, altura) * (1.0 - smoothstep(v.altura_fin * 0.5, v.altura_fin, altura));
    let densidad_aire = medio.rayleigh.g + medio.mie;
    // Solo en el lado antisolar y por debajo de ~20° de elevación de la mirada (01.1: el rosa llegaba al cenit).
    let elevacion = 1.0 - smoothstep(v.elevacion_fin * 0.4, v.elevacion_fin, vista_y);
    let venus_local = densidad_aire * enrojecida * banda_h * v.color * (v.multiple_local * anti * elevacion);
    return (fase * hacia_corr + venus_local) * sol.irradiancia + (medio.rayleigh + vec3<f32>(medio.mie)) * sol.multiple;
}

// Qué astros aportan: la luna solo con el sol bajo (su luz es una pequeña fracción de la del sol), y
// ninguno muy por debajo del horizonte.
struct AtmAstrosActivos {
    sol: bool,
    luna: bool,
}

fn atm_astros_activos(sol: AtmLuz, luna: AtmLuz) -> AtmAstrosActivos {
    return AtmAstrosActivos(sol.direccion.y > -0.35, luna.direccion.y > -0.35 && sol.direccion.y < 0.1 && any(luna.irradiancia > vec3<f32>(0.0)));
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

// Transmitancia hacia el sol con sombra de limbo troposférico y refracción rasante en el lado antisolar, para que
// la sombra de la Tierra y el cinturón de Venus mantengan su separación entre 0° y −4°. Porqué: docs/efectos/cielo-y-atmosfera.md §Cinturón de Venus
fn atm_hacia_sol(pos: vec3<f32>, dir_sol: vec3<f32>, cos_sol: f32, p: AtmParametros, v: AtmVenus, tabla: texture_2d<f32>, muestreo: sampler) -> vec3<f32> {
    let r = length(pos);
    let mu = dot(pos, dir_sol) / r;
    let horizonte = -sqrt(max(1.0 - (p.radio_planeta / r) * (p.radio_planeta / r), 0.0));
    let crep = atm_peso_crepusculo(dir_sol.y, v);
    let anti = (1.0 - smoothstep(-0.5, -0.1, cos_sol)) * crep;
    let limbo = v.sombra_limbo * (1.0 - smoothstep(-0.05, 0.01, dir_sol.y)) * anti;
    let refrac = v.refraccion * (1.0 - smoothstep(-0.08, -0.01, dir_sol.y)) * anti;
    let umbral = horizonte + limbo - refrac;
    let penumbra = smoothstep(umbral - 0.004, umbral + 0.010, mu);
    if penumbra <= 0.0 {
        return vec3<f32>(0.0);
    }
    let mu_tabla = max(mu + refrac, horizonte + v.sombra_limbo * anti + 0.002);
    let c = textureSampleLevel(tabla, muestreo, atm_transmitancia_uv(r, mu_tabla, p), 0.0).rgb;
    return atm_transmitancia_decodificar(c) * penumbra;
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
        let altura = length(pos) - p.radio_planeta;
        let medio = atm_medio(altura, p, ajustes.bruma);
        var fuente = vec3<f32>(0.0);
        if activos.sol {
            let hacia_sol = atm_hacia_sol(pos, sol.direccion, cos_sol, p, ajustes.venus, tabla, muestreo);
            fuente += atm_aporte_sol(cos_sol, dir.y, altura, medio, hacia_sol, sol, p, ajustes.venus);
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
