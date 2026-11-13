// Niebla del Nether y del End: raymarch propio de cada dimensión con la integración del 05. Texturas por parámetro.
// Porqué: docs/efectos/otras-dimensiones.md

struct VolDimension {
    bruma: vec3<f32>,       // color de la bruma (frame.fog_color normalizado)
    cantidad: f32,          // opción
    tiempo: f32,
}

// Nether (observación del dueño 2026-11-12, 6.1; respuesta 18 de A y observación 2026-11-13 §7, F-63): la masa de humo
// cuelga en una banda a media altura (tabla de extinción absoluta por bloque), recortada por el «penacho» (ruido 2D de
// periodo ~256 bloques, al cuadrado, desplazado por el viento más cuanto más alto) en la medida que decide una erosión 3D
// que se mueve; se aclara con la distancia a la cámara ((1 − d/render)^5); una capa fina sobre el mar de lava (Y 31),
// recortada por el mismo penacho y despejada a menos de 24 bloques de la cámara (la única zona despejada); y el humo del
// techo desde Y 40. Porqué: docs/efectos/otras-dimensiones.md §«Humo del Nether (F-63)»
const VOL_NETHER_LAVA: f32 = 31.0;
// Extinción del humo por bloque según la altura (absoluta, con la densidad del menú a 1; respuesta 18).
const VOL_NETHER_PERFIL_Y = array<f32, 12>(31.0, 35.0, 40.0, 50.0, 60.0, 65.0, 70.0, 75.0, 80.0, 85.0, 90.0, 95.0);
const VOL_NETHER_PERFIL_D = array<f32, 12>(0.0, 0.07, 0.04, 0.07, 0.14, 0.19, 0.27, 0.18, 0.10, 0.05, 0.01, 0.0);
const VOL_NETHER_CAPA: f32 = 1.0;           // extinción de la capa sobre la lava en Y 31 (relación capa : pico de la banda = 1 : 0,27 de F-47)
const VOL_NETHER_CAPA_CAIDA: f32 = 1.74;    // bloques: una décima en 4
const VOL_NETHER_CAPA_CLARO: f32 = 24.0;    // bloques alrededor de la cámara sin capa (entra lineal hasta aquí)
const VOL_NETHER_PENACHO_MOSAICO: f32 = 256.0;
const VOL_NETHER_VIENTO: vec2<f32> = vec2<f32>(0.6, -0.4);   // dirección del desplazamiento con la altura
const VOL_NETHER_EROSION_MOSAICO: vec3<f32> = vec3<f32>(180.0, 90.0, 180.0); // celdas de ~36 × 18 bloques (canal r, 5 celdas por mosaico)
const VOL_NETHER_EROSION_VELOCIDAD: f32 = 10.0;              // bloques por segundo
const VOL_NETHER_LUZ_HUMO: f32 = 0.004;     // luz de la lava en el humo
// Apagado de esa luz dentro de lo denso: exp(−15 · extinción), el 22 % con 0,1 y el 1 % con 0,3 (spec y respuesta 18).
const VOL_NETHER_APAGADO: f32 = 15.0;
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
    // x: humo (extinción por bloque, resta transmitancia), y: techo
    let sobre = max(mundo.y - 30.0, 0.0);
    let viento = VOL_NETHER_VIENTO * pow(sobre / 15.0, 2.1);
    let penacho = vol_ruido2d(t2, s2, (mundo.xz + viento) / VOL_NETHER_PENACHO_MOSAICO).r;
    let erosion = vol_ruido3d(t3, (mundo + vec3<f32>(d.tiempo * VOL_NETHER_EROSION_VELOCIDAD, 0.0, 0.0)) / VOL_NETHER_EROSION_MOSAICO).r;
    let corte = mix(0.3, 1.0, erosion) * penacho * penacho;
    let lejos = pow(clamp(1.0 - length(rel) / max(frame.render_distance, 16.0), 0.0, 1.0), 5.0);
    let humo = vol_nether_perfil(mundo.y) * max(1.0 - 2.0 * corte, 0.0) * lejos;
    // Capa sobre la lava: recortada por el penacho suavizado y abierta a menos de 24 bloques (en horizontal).
    let suave = smoothstep(0.2, 0.8, penacho);
    let capa = VOL_NETHER_CAPA * exp(-max(mundo.y - VOL_NETHER_LAVA, 0.0) / VOL_NETHER_CAPA_CAIDA)
             * (1.0 - 0.7 * suave) * clamp(length(rel.xz) / VOL_NETHER_CAPA_CLARO, 0.0, 1.0);
    let techo = smoothstep(40.0, 90.0, mundo.y);
    return vec2<f32>(humo + capa, techo);
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
        let sigma_humo = den.x * d.cantidad;
        let sigma_techo = den.y * 0.02 * d.cantidad;
        // Luz del humo: un naranja cálido fijo de la lava, que se apaga algo dentro de lo denso; más la bruma del bioma.
        // El techo, gris muy oscuro.
        let fuente = (sigma_humo * (lava * VOL_NETHER_LUZ_HUMO * exp(-den.x * VOL_NETHER_APAGADO) + d.bruma * 0.0006) + sigma_techo * vec3<f32>(0.0004)) * VOL_NETHER_LUZ;
        vol_tramo(&r, fuente, sigma_humo + sigma_techo, paso);
        // Bruma del color de la niebla del bioma: añade luz sin restar transmitancia.
        r.luz += r.transmitancia * d.bruma * (0.000012 * VOL_NETHER_LUZ) * d.cantidad * paso;
    }
    return r;
}

// End (formas/otras-dimensiones.md §End; observación del dueño 2026-11-12, 6.2): bancos de un ruido 3D grande donde el
// ruido es bajo, girados alrededor del eje vertical con un ángulo que crece con la altura y con el tiempo (la espiral),
// con una esfera limpia alrededor de la isla y un anillo limpio a 150 bloques (el pasillo de los pilares), la niebla del
// vacío bajo la isla y un claro alrededor de la cámara. Porqué: docs/efectos/otras-dimensiones.md §«Tormenta del End (F-49)»
const VOL_END_CENTRO: vec3<f32> = vec3<f32>(0.0, 100.0, 0.0);
const VOL_END_VORTICE: vec3<f32> = vec3<f32>(0.0, 200.0, 0.0);
const VOL_END_ALCANCE: f32 = 384.0;
const VOL_END_PASOS: i32 = 16;
const VOL_END_GIRO_ALTURA: f32 = 450.0;     // bloques de altura por vuelta
const VOL_END_GIRO_TIEMPO: f32 = 300.0;     // segundos por vuelta
const VOL_END_MOSAICO: vec2<f32> = vec2<f32>(1200.0, 4000.0); // ruido base: grano ~300 bloques en horizontal (4 celdas), lento en vertical
const VOL_END_MOSAICO_EROSION: f32 = 240.0; // erosión: grano ~30 bloques (8 celdas)
const VOL_END_CAIDA_LUZ: f32 = 25.4;        // bloques: la luz de un foco cae a un 14 % a 50, un 2 % a 100
// Luz del vórtice (respuesta 17 de A, F-62): un término directo que cae con e^(−d/50) y lo atenúa la niebla entre el punto
// y el foco, y un halo que cae con e^(−d/25) sin esa atenuación (el núcleo, que el dueño quiere como lo dejó F-56). Más
// un ambiente azulado igual en todo el volumen, ~1/100 del foco, 10 veces mayor en niebla fina que en espesa: es lo que
// se ve lejos del vórtice y en el cielo del End. Porqué: docs/efectos/otras-dimensiones.md §«Cielo del End (F-62)»
const VOL_END_LUZ_NUCLEO: f32 = 3.0;        // halo (F-56; antes 0,03)
const VOL_END_LUZ_DIRECTA: f32 = 1.2;
const VOL_END_CAIDA_DIRECTA: f32 = 50.0;    // bloques
const VOL_END_LUZ_AMBIENTE: f32 = 0.03;      // 1/100 del halo en su máximo (3,0), como dice la respuesta 17
const VOL_END_AMBIENTE_COLOR: vec3<f32> = vec3<f32>(0.5, 0.75, 1.0);

fn vol_end_densidad(mundo: vec3<f32>, rel: vec3<f32>, d: VolDimension, t3: texture_2d<f32>) -> f32 {
    let c = mundo - VOL_END_CENTRO;
    let r_eje = length(mundo.xz);
    // La espiral: giro con la altura y el tiempo, que se apaga de 200 a 400 bloques del centro.
    let giro = (1.0 - smoothstep(200.0, 400.0, length(c)))
             * MAT_TAU * (mundo.y / VOL_END_GIRO_ALTURA + d.tiempo / VOL_END_GIRO_TIEMPO);
    let cg = cos(giro);
    let sg = sin(giro);
    let p = vec3<f32>(cg * mundo.x - sg * mundo.z, mundo.y, sg * mundo.x + cg * mundo.z);
    let n = vol_ruido3d(t3, p / vec3<f32>(VOL_END_MOSAICO.x, VOL_END_MOSAICO.y, VOL_END_MOSAICO.x)).a;
    // Bancos donde el ruido es bajo; fuera de la zona del vórtice, curva más abrupta y el doble de densos.
    let fuera = smoothstep(250.0, 350.0, r_eje);
    let corte = mix(0.12, 0.06, fuera);
    var bancos = smoothstep(0.5 + corte, 0.5 - corte, n) * (1.0 + fuera);
    let erosion = vol_ruido3d(t3, (p + vec3<f32>(d.tiempo * 0.5, 0.0, 0.0)) / VOL_END_MOSAICO_EROSION).g;
    bancos *= 1.0 - 0.3 * erosion;
    // Huecos: esfera algo achatada alrededor de la isla (75 bloques) y anillo horizontal a 150 bloques del eje.
    let esfera = smoothstep(0.0, 75.0, length(vec3<f32>(c.x, c.y * 1.3, c.z)));
    let anillo = smoothstep(12.0, 85.0, length(vec2<f32>(r_eje - 150.0, c.y)));
    // Claro alrededor de la cámara: nada a 0, total a 100 (al cuadrado).
    let claro = clamp(length(rel) / 100.0, 0.0, 1.0);
    // Niebla del vacío: total bajo Y −60; un 11 % a −50, un 1 % a −20.
    let sobre = mundo.y + 60.0;
    let vacio = select(exp(-sobre / 4.5) + 0.02 * exp(-sobre / 40.0), 1.0, sobre <= 0.0);
    return max(bancos * esfera * anillo * claro * claro, vacio);
}

// Luz de un foco con la caída del original.
fn vol_end_foco(d: f32) -> f32 {
    return exp(-d / VOL_END_CAIDA_LUZ);
}

fn vol_end(rayo: VolRayo, d: VolDimension, t3: texture_2d<f32>) -> VolResultado {
    var r = VolResultado(vec3<f32>(0.0), 1.0, 0.0, vec3<f32>(0.0));
    let fin = min(rayo.escena, VOL_END_ALCANCE);
    let f = 6.0;
    var anterior = 0.0;
    // Relámpago magenta: un punto en una celda de 200 bloques alrededor de la cámara que salta cada 1,5 s; el 40 % de
    // los ciclos se queda encendido (sube en medio segundo, baja en uno). Más brillo cuanto más lejos del centro de la
    // celda (nulo a 5 bloques, total a 200).
    let ciclo = floor(d.tiempo / 1.5);
    let fase = fract(d.tiempo / 1.5) * 1.5;
    let h = rui_hash33(vec3<i32>(i32(ciclo), 7, 13));
    let encendido = select(0.0, 1.0, rui_hash21(vec2<i32>(i32(ciclo), 29)) < 0.4);
    let celda = floor(rayo.camara / 200.0) * 200.0 + vec3<f32>(100.0);
    let destello_pos = celda + (h - 0.5) * 200.0;
    let destello = encendido * smoothstep(0.0, 0.5, fase) * (1.0 - smoothstep(0.5, 1.5, fase))
                 * smoothstep(5.0, 200.0, length(destello_pos - celda) * 1.7);
    let azul = vec3<f32>(0.3, 0.5, 1.0);
    let magenta = vec3<f32>(1.0, 0.0, 0.5);
    for (var i = 0; i < VOL_END_PASOS; i++) {
        let t = (pow(f, (f32(i) + rayo.ruido) / f32(VOL_END_PASOS)) - 1.0) / (f - 1.0) * fin;
        let siguiente = (pow(f, (f32(i) + 1.0) / f32(VOL_END_PASOS)) - 1.0) / (f - 1.0) * fin;
        let paso = max(siguiente - anterior, 1e-3);
        anterior = siguiente;
        let rel = rayo.dir * t;
        let mundo = rayo.camara + rel;
        // Bruma tenue azulada, más clara mirando arriba: solo suma.
        r.luz += r.transmitancia * vec3<f32>(0.3, 0.35, 0.6) * (0.000004 * d.cantidad * (0.6 + 0.4 * max(rayo.dir.y, 0.0)) * paso);
        let den = vol_end_densidad(mundo, rel, d, t3);
        if den <= 0.001 {
            continue;
        }
        let sigma = den * 0.03 * d.cantidad;
        // Cada punto recibe el foco que le toca: el vórtice cerca del origen, el relámpago lejos.
        let r_origen = length(mundo);
        let peso_v = 1.0 - smoothstep(250.0, 350.0, r_origen);
        let hacia_v = normalize(VOL_END_VORTICE - mundo);
        let hacia_d = normalize(destello_pos - mundo);
        // Sombra de la propia niebla hacia el foco (dos tomas): apaga y tiñe (lo denso recibe una luz más saturada).
        let sombra_v = den + vol_end_densidad(mundo + hacia_v * 15.0, rel + hacia_v * 15.0, d, t3);
        let t_v = exp(-sombra_v * 1.2);
        let d_v = length(VOL_END_VORTICE - mundo);
        let directa_v = azul * t_v * (VOL_END_LUZ_DIRECTA * exp(-d_v / VOL_END_CAIDA_DIRECTA));
        let halo_v = (azul * t_v + azul * azul * (1.0 - t_v) * 0.5) * (VOL_END_LUZ_NUCLEO * vol_end_foco(d_v));
        let luz_v = (directa_v + halo_v) * peso_v;
        let luz_d = magenta * (0.15 * destello * vol_end_foco(length(destello_pos - mundo))) * (1.0 - peso_v)
                  * exp(-den * 1.2);
        // Ambiente azul muy tenue, solo en los bordes finos de los bancos.
        let ambiente = VOL_END_AMBIENTE_COLOR * (VOL_END_LUZ_AMBIENTE * mix(1.0, 0.1, smoothstep(0.0, 0.5, den)));
        vol_tramo(&r, sigma * (luz_v + luz_d + ambiente), sigma, paso);
    }
    return r;
}
