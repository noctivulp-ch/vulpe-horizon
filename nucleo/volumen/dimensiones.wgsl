// Niebla del Nether y del End: raymarch propio de cada dimensión con la integración del 05. Texturas por parámetro.
// Porqué: docs/efectos/otras-dimensiones.md

struct VolDimension {
    bruma: vec3<f32>,       // color de la bruma (frame.fog_color normalizado)
    cantidad: f32,          // opción
    tiempo: f32,
}

// Nether (observación del dueño 2026-11-12, 6.1): la masa de niebla cuelga del techo como columnas y cortinas, en una
// banda a media altura (Y 55–85, máximo en 70) que recorta el ruido de columnas, inclinada por el viento con la altura;
// una capa fina sobre el mar de lava (Y 31), despejada alrededor de la cámara; y el humo del techo desde Y 40.
// Porqué: docs/efectos/otras-dimensiones.md §«Niebla del Nether (F-47)»
const VOL_NETHER_LAVA: f32 = 31.0;
// Densidad máxima de las columnas por altura (sin el recorte del ruido), relativa a la capa sobre la lava (1).
const VOL_NETHER_PERFIL_Y = array<f32, 12>(31.0, 35.0, 40.0, 50.0, 60.0, 65.0, 70.0, 75.0, 80.0, 85.0, 90.0, 95.0);
const VOL_NETHER_PERFIL_D = array<f32, 12>(0.0, 0.07, 0.04, 0.07, 0.14, 0.19, 0.27, 0.18, 0.10, 0.05, 0.01, 0.0);
const VOL_NETHER_ESCALA: f32 = 2.5;         // densidad relativa → extinción del humo (× 0,06 por bloque)
const VOL_NETHER_LUZ: f32 = 10.0;           // escala de la luz de la niebla, la misma subida que el ambiente del Nether (F-45)

fn vol_nether_perfil(y: f32) -> f32 {
    if y <= VOL_NETHER_PERFIL_Y[0] || y >= VOL_NETHER_PERFIL_Y[11] {
        return 0.0;
    }
    for (var k = 1; k < 12; k++) {
        if y <= VOL_NETHER_PERFIL_Y[k] {
            let f = (y - VOL_NETHER_PERFIL_Y[k - 1]) / (VOL_NETHER_PERFIL_Y[k] - VOL_NETHER_PERFIL_Y[k - 1]);
            return mix(VOL_NETHER_PERFIL_D[k - 1], VOL_NETHER_PERFIL_D[k], f);
        }
    }
    return 0.0;
}

fn vol_nether_densidad(mundo: vec3<f32>, rel: vec3<f32>, d: VolDimension, t2: texture_2d<f32>, s2: sampler, t3: texture_2d<f32>) -> vec2<f32> {
    // x: humo (resta transmitancia), y: techo
    let sobre_lava = max(mundo.y - VOL_NETHER_LAVA, 0.0);
    // Columnas: ruido 2D desplazado por el viento más cuanto más alto (inclinadas), erosionado por un 3D que baja.
    let torcido = mundo.xz + vec2<f32>(0.6, -0.4) * sobre_lava * 0.35;
    let columnas = smoothstep(0.45, 0.7, vol_ruido2d(t2, s2, torcido / 900.0).r);
    let erosion = vol_ruido3d(t3, (mundo + vec3<f32>(0.0, -d.tiempo * 2.0, 0.0)) / 48.0).r;
    var humo = vol_nether_perfil(mundo.y) * columnas * smoothstep(0.25, 0.7, erosion);
    // Capa fina sobre la lava: cae a una décima en 4 bloques, despejada en ~24 bloques alrededor de la cámara.
    let capa = exp(-sobre_lava / 1.74) * smoothstep(16.0, 32.0, length(rel.xz));
    humo += capa * smoothstep(0.2, 0.6, erosion);
    let techo = smoothstep(40.0, 90.0, mundo.y);
    // Aire más limpio alrededor del jugador.
    let cerca = smoothstep(6.0, 24.0, length(rel));
    return vec2<f32>(humo * VOL_NETHER_ESCALA * cerca, techo * cerca);
}

fn vol_nether(rayo: VolRayo, d: VolDimension, t2: texture_2d<f32>, s2: sampler, t3: texture_2d<f32>) -> VolResultado {
    var r = VolResultado(vec3<f32>(0.0), 1.0, 0.0, vec3<f32>(0.0));
    let fin = min(rayo.escena, 192.0);
    let pasos = 12;
    let f = 8.0;
    var anterior = 0.0;
    let lava = vec3<f32>(1.0, 0.45, 0.15);
    for (var i = 0; i < pasos; i++) {
        let t = (pow(f, (f32(i) + rayo.ruido) / f32(pasos)) - 1.0) / (f - 1.0) * fin;
        let siguiente = (pow(f, (f32(i) + 1.0) / f32(pasos)) - 1.0) / (f - 1.0) * fin;
        let paso = max(siguiente - anterior, 1e-3);
        anterior = siguiente;
        let rel = rayo.dir * t;
        let mundo = rayo.camara + rel;
        let den = vol_nether_densidad(mundo, rel, d, t2, s2, t3);
        let sigma_humo = den.x * 0.06 * d.cantidad;
        let sigma_techo = den.y * 0.02 * d.cantidad;
        // Luz del humo: un naranja cálido fijo de la lava, que se apaga algo dentro de lo denso; más la bruma del bioma.
        // El techo, gris muy oscuro.
        let fuente = (sigma_humo * (lava * 0.004 * exp(-den.x * 1.5) + d.bruma * 0.0006) + sigma_techo * vec3<f32>(0.0004)) * VOL_NETHER_LUZ;
        vol_tramo(&r, fuente, sigma_humo + sigma_techo, paso);
        // Bruma del color de la niebla del bioma: añade luz sin restar transmitancia.
        r.luz += r.transmitancia * d.bruma * (0.000012 * VOL_NETHER_LUZ) * d.cantidad * paso;
    }
    return r;
}

// End: anillo de niebla que gira alrededor del origen, hueco en la isla central, con la niebla del vacío debajo; luz
// del vórtice sobre el centro y destellos magenta.
fn vol_end_densidad(mundo: vec3<f32>, d: VolDimension, t3: texture_2d<f32>) -> f32 {
    let r = length(mundo.xz);
    let giro = d.tiempo * 0.02 * (1.0 + 80.0 / (r + 40.0));
    let c = cos(giro);
    let s = sin(giro);
    let p = vec3<f32>(c * mundo.x - s * mundo.z, mundo.y, s * mundo.x + c * mundo.z);
    let n = vol_ruido3d(t3, p / 70.0).a * 0.7 + vol_ruido3d(t3, p / 25.0).g * 0.3;
    // Toro de radio 150 alrededor del origen, a Y ≈ 60, y hueco en la isla central.
    let toro = length(vec2<f32>(r - 150.0, (mundo.y - 60.0) * 1.5));
    let anillo = 1.0 - smoothstep(40.0, 110.0, toro);
    let hueco = smoothstep(60.0, 90.0, length(mundo - vec3<f32>(0.0, 100.0, 0.0)));
    let vacio = smoothstep(-20.0, -60.0, mundo.y);
    return max(smoothstep(0.35, 0.75, n) * anillo * hueco, vacio * 0.6);
}

fn vol_end(rayo: VolRayo, d: VolDimension, t3: texture_2d<f32>) -> VolResultado {
    var r = VolResultado(vec3<f32>(0.0), 1.0, 0.0, vec3<f32>(0.0));
    let fin = min(rayo.escena, 320.0);
    let pasos = 12;
    let f = 6.0;
    var anterior = 0.0;
    let vortice = vec3<f32>(0.0, 200.0, 0.0);
    // Destello: posición sorteada cada 4 s, subida rápida y caída lenta.
    let ciclo = floor(d.tiempo / 4.0);
    let fase_d = fract(d.tiempo / 4.0);
    let h = rui_hash33(vec3<i32>(i32(ciclo), 7, 13));
    let destello_pos = vec3<f32>((h.x - 0.5) * 360.0, 40.0 + h.y * 80.0, (h.z - 0.5) * 360.0);
    let destello = smoothstep(0.0, 0.03, fase_d) * exp(-fase_d * 12.0);
    for (var i = 0; i < pasos; i++) {
        let t = (pow(f, (f32(i) + rayo.ruido) / f32(pasos)) - 1.0) / (f - 1.0) * fin;
        let siguiente = (pow(f, (f32(i) + 1.0) / f32(pasos)) - 1.0) / (f - 1.0) * fin;
        let paso = max(siguiente - anterior, 1e-3);
        anterior = siguiente;
        let mundo = rayo.camara + rayo.dir * t;
        let den = vol_end_densidad(mundo, d, t3);
        if den <= 0.001 {
            continue;
        }
        let sigma = den * 0.03 * d.cantidad;
        let dv = length(vortice - mundo);
        let dd = length(destello_pos - mundo);
        let luz_v = vec3<f32>(0.7, 0.75, 1.0) * 0.0025 / (1.0 + dv * dv / 20000.0);
        let luz_d = vec3<f32>(1.0, 0.25, 0.9) * 0.02 * destello / (1.0 + dd * dd / 3000.0);
        let fuente = sigma * (luz_v + luz_d + vec3<f32>(0.25, 0.22, 0.4) * 0.0002);
        vol_tramo(&r, fuente, sigma, paso);
    }
    return r;
}
