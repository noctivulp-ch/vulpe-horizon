// La aurora dentro del raymarch del volumen: cortinas colgadas del mapa, conos que despejan la niebla y la
// ventana al cielo. PROPIO de Vulpe (especificación 06 §3–7). El mapa llega por parámetro.
// Porqué: docs/efectos/aurora.md

struct VolAurora {
    activa: bool,
    noche: f32,
    radio: f32,             // R: radio del disco del cielo en el mundo, bloques
    base: f32,              // Y donde termina el velo (la cortina no baja de aquí)
    tope: f32,              // Y del borde superior
    intensidad: f32,        // multiplicador de la luz emitida (incluye el ajuste del usuario)
    dia: f32,               // día del mundo (mueve el ruido del despeje)
    depuracion: u32,        // 0 nada, 1 conos en rojo, 2 sin ventana
}

const VOL_AURORA_DEPURAR_CONOS: u32 = 1u;
const VOL_AURORA_DEPURAR_SIN_VENTANA: u32 = 2u;

// Constantes de Vulpe (prioridad baja en la especificación: no son opciones).
const VOL_AURORA_ALCANCE_CONO: f32 = 1.0;       // del velo
const VOL_AURORA_APERTURA: f32 = 1.5;           // radio del cono por bloque bajo el tope
const VOL_AURORA_PUNTOS: f32 = 0.3;             // fracción de la línea que emite cono
const VOL_AURORA_SEPARACION: f32 = 32.0;        // bloques
const VOL_AURORA_DESPEJE: f32 = 1.0;
const VOL_AURORA_RUIDO: f32 = 0.8;
const VOL_AURORA_TAMANO_RUIDO: f32 = 96.0;      // bloques
const VOL_AURORA_VENTANA: f32 = 2.0;
// Fracción de la intensidad de las cortinas con que se ve el fractal por la ventana (especificación 06 §7):
// el color del mapa es el cielo fractal, calibrado muy tenue. Porqué: docs/efectos/aurora.md §Ventana
const VOL_AURORA_VENTANA_ESCALA: f32 = 0.6;
const VOL_AURORA_MUESTRAS: i32 = 4;
const VOL_AURORA_VETAS: f32 = 0.3;
const VOL_AURORA_GROSOR_VETAS: f32 = 6.0;       // bloques
// La «densidad» con la que la especificación pesa la luz de la cortina está en las unidades de niebla de
// Vulpe, mucho mayores que nuestra extinción física (≈0,0076 por bloque de noche): con esta, el peso
// 1 − e^(−σ·largo) no pasaba de ~0,15 y la luz solo salía donde el rayo recorre mucho velo (un ribete en el
// borde). Se multiplica la extinción de la niebla para la cortina: así satura casi en cada muestra, como en
// Vulpe, y la cortina brilla en toda su altura. Porqué: docs/efectos/aurora.md §Peso de la luz
const VOL_AURORA_DENSIDAD: f32 = 25.0;

fn vol_aurora_largo_cono(a: VolAurora) -> f32 {
    return (a.tope - a.base) * VOL_AURORA_ALCANCE_CONO;
}

// 0 en la base (no toca el suelo), 1 en el tope; por encima se corta rápido (arriba nítida).
fn vol_aurora_perfil(y: f32, a: VolAurora) -> f32 {
    if y > a.tope {
        return exp2(-(y - a.tope) / 6.0);
    }
    let s = (y - a.base) / max(a.tope - a.base, 1.0);
    if s <= 0.0 {
        return 0.0;
    }
    return s * s * (3.0 - 2.0 * s);
}

// Lectura del mapa en el punto (x, z) del disco ([−1, 1]²).
fn vol_aurora_mapa(t: texture_2d<f32>, s: sampler, disco: vec2<f32>) -> vec4<f32> {
    return textureSampleLevel(t, s, disco * 0.5 + 0.5, 0.0);
}

fn vol_aurora_luz(rel: vec3<f32>, y: f32, a: VolAurora, t: texture_2d<f32>, s: sampler) -> vec3<f32> {
    if length(rel.xz) >= a.radio {
        return vec3<f32>(0.0);
    }
    let p = vol_aurora_perfil(y, a);
    if p < 0.01 {
        return vec3<f32>(0.0);
    }
    let emision = vol_aurora_mapa(t, s, rel.xz / a.radio).rgb;
    let vetas = mix(1.0, 0.3 + 1.4 * rui_valor2(rel.xz / VOL_AURORA_GROSOR_VETAS), VOL_AURORA_VETAS);
    return emision * p * vetas * a.noche * a.intensidad;
}

struct VolLinea {
    hay: bool,
    distancia: f32,         // bloques
    punto: vec2<f32>,       // punto más cercano de la línea (relativo a la cámara, xz)
    normal: vec2<f32>,
}

// La línea más cercana a (x, z), del canal a del mapa: distancia = |a|·R; normal = gradiente de a por
// diferencias entre texeles vecinos.
fn vol_aurora_linea(rel_xz: vec2<f32>, a: VolAurora, t: texture_2d<f32>, s: sampler) -> VolLinea {
    let disco = rel_xz / a.radio;
    let d = vol_aurora_mapa(t, s, disco).a;
    if abs(d) >= 0.999 {
        return VolLinea(false, 1e9, vec2<f32>(0.0), vec2<f32>(0.0));
    }
    let paso = 2.0 / vec2<f32>(textureDimensions(t));
    let gx = vol_aurora_mapa(t, s, disco + vec2<f32>(paso.x, 0.0)).a - d;
    let gz = vol_aurora_mapa(t, s, disco + vec2<f32>(0.0, paso.y)).a - d;
    let g = vec2<f32>(gx / paso.x, gz / paso.y);
    let normal = g / max(length(g), 1e-5);
    return VolLinea(true, abs(d) * a.radio, rel_xz - d * a.radio * normal, normal);
}

// Ruido del despeje: dos octavas, inclinado con la altura (no salen columnas), moviéndose con el día.
fn vol_aurora_ruido_despeje(rel: vec3<f32>, a: VolAurora) -> f32 {
    let q = (rel.xz + vec2<f32>(0.61, -0.37) * rel.y) / VOL_AURORA_TAMANO_RUIDO + vec2<f32>(a.dia * 0.37, a.dia * 0.21);
    let n = rui_valor2(q) * 0.65 + rui_valor2(q * 2.03 + 11.7) * 0.35;
    return mix(1.0, smoothstep(0.25, 0.75, n), VOL_AURORA_RUIDO);
}

// Fracción de niebla que quitan los conos en un punto (0..1).
fn vol_aurora_despeje(rel: vec3<f32>, y: f32, a: VolAurora, t: texture_2d<f32>, s: sampler) -> f32 {
    let largo = vol_aurora_largo_cono(a);
    let h = a.tope - y;
    if h < 0.0 || h > largo {
        return 0.0;
    }
    let rho = 1.5 + h * VOL_AURORA_APERTURA;
    let l = vol_aurora_linea(rel.xz, a, t, s);
    if !l.hay || l.distancia > rho {
        return 0.0;
    }
    // Qué tramos de la línea emiten cono: un ruido sobre el disco; la distancia a lo largo de la línea hasta
    // el tramo activo se combina con la distancia a la línea (conos redondos, sin puntas cortadas).
    var a_lo_largo = 0.0;
    if VOL_AURORA_PUNTOS < 1.0 {
        let n = rui_valor2_derivadas(l.punto / VOL_AURORA_SEPARACION);
        let falta = max(1.0 - VOL_AURORA_PUNTOS - n.x, 0.0);
        if falta > 0.0 {
            let tangente = vec2<f32>(-l.normal.y, l.normal.x);
            a_lo_largo = falta / max(abs(dot(n.yz / VOL_AURORA_SEPARACION, tangente)), 1e-4);
        }
    }
    let d = length(vec2<f32>(l.distancia, a_lo_largo));
    var cono = 1.0 - smoothstep(rho * 0.6, rho, d);
    cono *= 1.0 - smoothstep(0.8, 1.0, h / max(largo, 1.0));
    cono *= vol_aurora_ruido_despeje(rel, a);
    return cono * a.noche * VOL_AURORA_DESPEJE;
}

struct VolAuroraTramo {
    luz: vec3<f32>,         // ya pesada por la niebla que queda y por la transmitancia acumulada
    despeje: f32,           // medio en el tramo
    fraccion: f32,          // parte del paso del raymarch que ocupa el tramo
    ventana: f32,           // bloques de cono atravesados
    color_ventana: vec3<f32>, // color del mapa en las muestras, pesado por despeje × largo (sin normalizar)
}

// Lo que aporta la aurora en el paso [ta, tb] del raymarch: solo el tramo exacto que cruza la franja del
// velo, con varias muestras (un punto por paso caía unas veces dentro y otras fuera: era el parpadeo).
fn vol_aurora_tramo(camara: vec3<f32>, dir: vec3<f32>, ta: f32, tb: f32, ruido: f32, sigma: f32, transmitancia: f32,
                    a: VolAurora, t: texture_2d<f32>, s: sampler) -> VolAuroraTramo {
    var r = VolAuroraTramo(vec3<f32>(0.0), 0.0, 0.0, 0.0, vec3<f32>(0.0));
    let y0 = min(a.base, a.tope - vol_aurora_largo_cono(a));
    let y1 = a.tope + 24.0;
    var t0 = ta;
    var t1 = tb;
    if abs(dir.y) > 1e-5 {
        let ea = (y0 - camara.y) / dir.y;
        let eb = (y1 - camara.y) / dir.y;
        t0 = max(t0, min(ea, eb));
        t1 = min(t1, max(ea, eb));
    } else if camara.y < y0 || camara.y > y1 {
        return r;
    }
    if t1 <= t0 {
        return r;
    }
    let largo = t1 - t0;
    let muestra = largo / f32(VOL_AURORA_MUESTRAS);
    for (var k = 0; k < VOL_AURORA_MUESTRAS; k++) {
        let u = (f32(k) + fract(ruido + f32(k) * 0.618034)) / f32(VOL_AURORA_MUESTRAS);
        let rel = dir * (t0 + u * largo);
        let y = camara.y + rel.y;
        let despeje = vol_aurora_despeje(rel, y, a, t, s);
        let luz = vol_aurora_luz(rel, y, a, t, s);
        // Color del cono para la ventana (§7): el del mapa en el punto de la muestra, la misma lectura que la luz.
        if despeje > 0.0 && length(rel.xz) < a.radio {
            r.color_ventana += vol_aurora_mapa(t, s, rel.xz / a.radio).rgb * despeje * muestra;
        }
        r.luz += luz * (1.0 - exp(-sigma * VOL_AURORA_DENSIDAD * (1.0 - despeje) * muestra)) * transmitancia;
        if a.depuracion == VOL_AURORA_DEPURAR_CONOS {
            r.luz += vec3<f32>(despeje * muestra * 2e-3, 0.0, 0.0) * transmitancia;
        }
        r.despeje += despeje / f32(VOL_AURORA_MUESTRAS);
        r.ventana += despeje * muestra;
    }
    r.fraccion = largo / max(tb - ta, 1e-3);
    return r;
}

// La ventana al cielo al final del rayo: el fractal visto a través de los conos atravesados, sumado por
// encima de la niebla de delante (sin pesarlo por la transmitancia: pesado no se veía).
// `color_acumulado`: Σ color · despeje · largo de las muestras; se normaliza por la ventana.
fn vol_aurora_ventana(camara: vec3<f32>, dir: vec3<f32>, ventana: f32, color_acumulado: vec3<f32>, a: VolAurora) -> vec3<f32> {
    if ventana <= 0.0 || dir.y <= 0.0 || a.depuracion == VOL_AURORA_DEPURAR_SIN_VENTANA {
        return vec3<f32>(0.0);
    }
    let f = clamp(ventana / max(vol_aurora_largo_cono(a), 1.0), 0.0, 1.0) * VOL_AURORA_VENTANA;
    let medio = 0.5 * (a.base + a.tope);
    let rel = dir * max((medio - camara.y) / dir.y, 0.0);
    let ruido = vol_aurora_ruido_despeje(rel, a);
    let color = color_acumulado / max(ventana, 1e-4);
    return color * a.noche * f * ruido * a.intensidad * VOL_AURORA_VENTANA_ESCALA;
}
