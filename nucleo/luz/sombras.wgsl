// Sombras con penumbra variable (PCSS) sobre un mapa de profundidad ortográfico distorsionado.
// Los mapas llegan por parámetro: el núcleo no sabe de dónde salen. Porqué: docs/efectos/sombras.md

struct LuzPuntoSombra {
    mapa: vec3<f32>,            // xy en el mapa (0..1), z profundidad desde la luz (0..1)
    texeles_por_bloque: f32,    // densidad del mapa en este punto (crece hacia el centro por la distorsión)
    bloques_por_profundidad: f32, // bloques por unidad de profundidad (proyección ortográfica: lineal)
    resolucion: f32,            // lado del mapa en texels
    ruido: f32,                 // 0..1 por píxel y fotograma: gira el disco de muestras
}

struct LuzAjustesSombra {
    variable: bool,             // PCSS; si no, PCF de radio fijo (la penumbra mínima)
    penumbra_min: f32,          // radio, bloques
    penumbra_max: f32,          // radio, texels
    muestras: i32,
    penumbra_crece: f32,        // radio que crece por bloque de distancia al ocluyente
    muestras_busqueda: i32,     // muestras de búsqueda de ocluyentes en PCSS
}

struct LuzSombra {
    luz: f32,                   // 0 en sombra, 1 iluminado
    grosor: f32,                // distancia media al ocluyente hacia la luz, bloques (0 sin ocluyente)
}

// Disco de Vogel (espiral áurea): muestra i de n, girado `giro` radianes, radio 0..1 de área igual (para filtrado PCF).
fn luz_vogel(i: i32, n: i32, giro: f32) -> vec2<f32> {
    let r = sqrt((f32(i) + 0.5) / f32(n));
    let a = f32(i) * 2.39996323 + giro;
    return vec2<f32>(cos(a), sin(a)) * r;
}

// Muestreo con distribución radial lineal (fino/04 §1): concentra más muestras cerca del centro para búsqueda de ocluyentes.
fn luz_vogel_lineal(i: i32, n: i32, giro: f32) -> vec2<f32> {
    let r = (f32(i) + 0.5) / f32(n);
    let a = f32(i) * 2.39996323 + giro;
    return vec2<f32>(cos(a), sin(a)) * r;
}

fn luz_sombra(p: LuzPuntoSombra, a: LuzAjustesSombra, mapa: texture_depth_2d, comparacion: sampler_comparison) -> LuzSombra {
    let giro = p.ruido * MAT_TAU;
    let lado = vec2<f32>(p.resolucion);
    var radio_texeles = clamp(a.penumbra_min * p.texeles_por_bloque, 1.0, a.penumbra_max);
    var grosor = 0.0;
    if a.variable {
        // 1. Búsqueda de ocluyentes: distribución radial lineal (fino/04 §1) para concentrar muestras en el centro
        let busqueda = clamp(2.5 * p.texeles_por_bloque, 2.0, 36.0);
        var suma = 0.0;
        var cuenta = 0.0;
        let n_busqueda = a.muestras_busqueda;
        for (var i = 0; i < n_busqueda; i++) {
            let uv = p.mapa.xy + luz_vogel_lineal(i, n_busqueda, giro + 1.3) * busqueda / lado;
            let texel = vec2<i32>(clamp(uv * lado, vec2<f32>(0.0), lado - 1.0));
            let d = textureLoad(mapa, texel, 0);
            if d < p.mapa.z {
                suma += d;
                cuenta += 1.0;
            }
        }
        if cuenta > 0.0 {
            // 2. Penumbra: un mínimo más una parte proporcional a la distancia al ocluyente, en bloques.
            grosor = (p.mapa.z - suma / cuenta) * p.bloques_por_profundidad;
            let penumbra_bloques = a.penumbra_min + grosor * a.penumbra_crece;
            radio_texeles = clamp(penumbra_bloques * p.texeles_por_bloque, 1.0, a.penumbra_max);
        }
    }
    // 3. PCF con ese radio: si la búsqueda no detectó ocluyentes, no se salta el filtrado, sino que se
    // ejecuta con el radio mínimo (fino/04 §Lo que está mal 1), evitando cortes bruscos en la silueta.
    var luz = 0.0;
    for (var i = 0; i < a.muestras; i++) {
        let uv = p.mapa.xy + luz_vogel(i, a.muestras, giro) * radio_texeles / lado;
        luz += textureSampleCompareLevel(mapa, comparacion, uv, p.mapa.z);
    }
    return LuzSombra(luz / f32(a.muestras), grosor);
}

// Color de la luz que atraviesa un translúcido: `color` el de shadow_color (rgb el téxel por el tinte, a 1
// en el agua), `agua` el tinte del agua. El cristal tiñe con su color al cuadrado según su opacidad.
fn luz_tinte_translucido(color: vec4<f32>, agua: vec3<f32>) -> vec3<f32> {
    if color.a >= 0.999 {
        return agua;
    }
    let c = color.rgb / max(max(color.r, max(color.g, color.b)), 1e-3);
    return mix(vec3<f32>(1.0), c * c, color.a);
}

// Dónde guarda el mapa un punto relativo a la cámara, con la fórmula de distorsión que documenta el motor
// (xy/(|xy|·k + 1 − k)); para quien no tiene a mano el ayudante del motor (el bucle del volumen).
struct LuzMapa {
    vista_proyeccion: mat4x4<f32>,
    distorsion: f32,
}

fn luz_posicion_mapa(m: LuzMapa, p: vec3<f32>) -> vec3<f32> {
    let clip = m.vista_proyeccion * vec4<f32>(p, 1.0);
    let xy = clip.xy / (length(clip.xy) * m.distorsion + 1.0 - m.distorsion);
    return vec3<f32>(xy.x * 0.5 + 0.5, 0.5 - xy.y * 0.5, min(clip.z, 1.0));
}
