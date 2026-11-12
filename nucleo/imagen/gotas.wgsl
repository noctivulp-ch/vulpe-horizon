// Efectos de cámara de juego (19): agua en la cámara al cruzar la superficie y aire caliente en lava o en llamas.
// Solo deforman las coordenadas con ruido procedural: sin lecturas de textura (la pasada final va por 63 de 64).
// Porqué: docs/efectos/camara-y-juego.md

struct ImgGotasAjustes {
    duracion: f32,      // segundos que dura el efecto tras el cruce
    fuerza: f32,        // 0..1 (el ajuste 50 del original = 0,5: la gota más gruesa acerca al centro la mitad)
    rapidez_ref: f32,   // bloques/s de cruce que dan la fuerza completa
}

struct ImgGotasResultado {
    uv: vec2<f32>,
    borde: f32,         // oscurecimiento leve del borde de las gotas (0..1)
}

// Agua en la cámara. `t`: segundos desde el cruce; `salida`: la cámara salió del agua (si no, entró);
// `vel`: la velocidad del cruce en pantalla (x a la derecha, y hacia abajo), en bloques/s.
fn img_agua_camara(uv: vec2<f32>, aspecto: f32, t: f32, salida: bool, vel: vec2<f32>, a: ImgGotasAjustes) -> ImgGotasResultado {
    if t < 0.0 || t >= a.duracion || a.fuerza <= 0.0 {
        return ImgGotasResultado(uv, 0.0);
    }
    let vida = 1.0 - t / a.duracion;
    let rapidez = clamp(length(vel) / a.rapidez_ref, 0.25, 1.5);
    let dir = select(vec2<f32>(0.0, 1.0), normalize(vel), length(vel) > 0.1);
    let centro = vec2<f32>(0.5);
    let q = (uv - centro) * vec2<f32>(aspecto, 1.0);
    if salida {
        // Manchas de baja frecuencia estiradas en la dirección del cruce que escurren en el sentido contrario a la
        // entrada; el umbral sube con el tiempo y solo quedan las gruesas.
        let along = dot(q, dir);
        let across = dot(q, vec2<f32>(-dir.y, dir.x));
        let p = vec2<f32>(along * 0.5 + t * 0.12, across) * 3.0;
        let n = rui_valor2(p) * 0.65 + rui_valor2(p * 2.3 + vec2<f32>(5.2, 1.3)) * 0.35;
        let umbral = mix(0.25, 0.85, t / a.duracion);
        let gota = smoothstep(umbral, umbral + 0.12, n);
        let k = a.fuerza * gota * mix(0.3, 1.0, gota) * rapidez * vida;
        let borde = smoothstep(umbral, umbral + 0.04, n) - smoothstep(umbral + 0.04, umbral + 0.12, n);
        return ImgGotasResultado(mix(uv, centro, min(k, 0.5)), borde * vida);
    }
    // Entrada: una onda que se abre desde el centro, más suave.
    let r = length(q);
    let frente = t * 0.5;
    let x = (r - frente) * 6.0;
    let onda = sin(x * 6.0) * exp(-x * x);
    let k = 0.06 * a.fuerza * onda * rapidez * vida;
    return ImgGotasResultado(uv + (uv - centro) * k, 0.0);
}

// Aire caliente: ondas de ruido que suben (0,3 de la altura por segundo), fuertes abajo y nulas en el tercio superior,
// y un leve acercamiento al centro. `nivel` 0..1, `fuerza` el ajuste 0..1 (70 por defecto = 0,7).
fn img_calor(uv: vec2<f32>, aspecto: f32, segundos: f32, nivel: f32, fuerza: f32) -> vec2<f32> {
    if nivel <= 0.001 || fuerza <= 0.0 {
        return uv;
    }
    let abajo = smoothstep(0.33, 1.0, uv.y);
    let p = vec2<f32>(uv.x * aspecto * 8.0, (uv.y + segundos * 0.3) * 10.0);
    let n = vec2<f32>(rui_valor2(p), rui_valor2(p + vec2<f32>(13.1, 7.7))) - 0.5;
    let k = nivel * fuerza;
    return mix(uv, vec2<f32>(0.5), 0.02 * k) + n * (0.012 * k * abajo * abajo);
}
