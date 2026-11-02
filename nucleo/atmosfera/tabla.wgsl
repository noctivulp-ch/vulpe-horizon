// Formato de la tabla precalculada de la atmósfera (texturas/atmosfera.png). Porqué: docs/efectos/cielo-y-atmosfera.md §Tabla
// La escribe tools/atmosfera/generar_tabla.py; aquí solo su geometría y su decodificación.

const ATM_TABLA_ANCHO: f32 = 64.0;
const ATM_TABLA_ALTO: f32 = 4.0;
const ATM_TABLA_ELEVACION_MIN: f32 = -20.0;   // grados
const ATM_TABLA_ELEVACION_MAX: f32 = 90.0;
const ATM_TABLA_LOG_MIN: f32 = -20.0;         // log2 del valor que codifica 0
const ATM_TABLA_LOG_RANGO: f32 = 24.0;        // log2 del valor que codifica 1, menos el mínimo

// Filas
const ATM_FILA_SOL: f32 = 0.0;      // irradiancia del astro tras la atmósfera, perpendicular a él
const ATM_FILA_CIELO: f32 = 1.0;    // radiancia media del cielo (irradiancia horizontal / π)
const ATM_FILA_SUELO: f32 = 2.0;    // radiancia del suelo (albedo medio) bajo esa luz
const ATM_FILA_HORIZONTE: f32 = 3.0; // radiancia media del cielo junto al horizonte

// Coordenada de textura para el seno de la elevación del astro y una fila.
fn atm_tabla_uv(seno_elevacion: f32, fila: f32) -> vec2<f32> {
    let elev = degrees(asin(clamp(seno_elevacion, -1.0, 1.0)));
    let t = clamp((elev - ATM_TABLA_ELEVACION_MIN) / (ATM_TABLA_ELEVACION_MAX - ATM_TABLA_ELEVACION_MIN), 0.0, 1.0);
    return vec2<f32>((0.5 + t * (ATM_TABLA_ANCHO - 1.0)) / ATM_TABLA_ANCHO, (fila + 0.5) / ATM_TABLA_ALTO);
}

// Valor codificado (log2 por canal) a luz lineal; 0 exacto en el mínimo.
fn atm_tabla_decodificar(c: vec3<f32>) -> vec3<f32> {
    let v = exp2(c * ATM_TABLA_LOG_RANGO + ATM_TABLA_LOG_MIN);
    return select(v, vec3<f32>(0.0), c <= vec3<f32>(0.5 / 255.0));
}

// Tabla de transmitancia (texturas/transmitancia.png): transmitancia desde un punto de la atmósfera hasta
// su borde, por altura y coseno cenital, con la parametrización de Bruneton («Precomputed Atmospheric
// Scattering», revisión de 2017, §«Transmittance»), que reparte la resolución cerca del horizonte.
// Guarda T^(1/3) por canal: más precisión en las transmitancias bajas del atardecer.
const ATM_TRANS_ANCHO: f32 = 128.0;
const ATM_TRANS_ALTO: f32 = 32.0;

fn atm_transmitancia_uv(r: f32, mu: f32, p: AtmParametros) -> vec2<f32> {
    let h = sqrt(p.radio_atmosfera * p.radio_atmosfera - p.radio_planeta * p.radio_planeta);
    let rho = sqrt(max(r * r - p.radio_planeta * p.radio_planeta, 0.0));
    let disc = r * r * (mu * mu - 1.0) + p.radio_atmosfera * p.radio_atmosfera;
    let d = max(-r * mu + sqrt(max(disc, 0.0)), 0.0);
    let d_min = p.radio_atmosfera - r;
    let d_max = rho + h;
    let x_mu = (d - d_min) / max(d_max - d_min, 1.0);
    let x_r = rho / h;
    // De [0, 1] a centros de texel.
    let u = 0.5 / ATM_TRANS_ANCHO + x_mu * (1.0 - 1.0 / ATM_TRANS_ANCHO);
    let v = 0.5 / ATM_TRANS_ALTO + x_r * (1.0 - 1.0 / ATM_TRANS_ALTO);
    return vec2<f32>(u, v);
}

fn atm_transmitancia_decodificar(c: vec3<f32>) -> vec3<f32> {
    return c * c * c;
}
