// Gotas en la cámara al salir del agua (07.2): distorsión procedural de la lente con gotas que
// escurren hacia abajo y se desvanecen en unos segundos tras salir del agua.
// Sin lecturas de textura (presupuesto de 62/64 en la pasada final).
// Porqué: docs/efectos/agua.md §Gotas en la cámara

struct ImgGotasAjustes {
    duracion: f32,
    intensidad: f32,
    refraccion: f32,
    escala: f32,
    velocidad: f32,
}

struct ImgGotasResultado {
    uv: vec2<f32>,
    borde: f32,
}

fn img_gotas_lente(uv: vec2<f32>, aspecto: f32, t_salida: f32, a: ImgGotasAjustes) -> ImgGotasResultado {
    if t_salida >= a.duracion || a.intensidad <= 1e-4 {
        return ImgGotasResultado(uv, 0.0);
    }
    // Desvanecimiento suave en el tiempo
    let desvanecer = clamp(1.0 - t_salida / a.duracion, 0.0, 1.0);
    let fuerza = a.intensidad * desvanecer;

    var offset = vec2<f32>(0.0);
    var borde_total = 0.0;

    // Capa 1: Gotas principales que escurren hacia abajo
    let st1 = vec2<f32>(uv.x * aspecto, uv.y) * a.escala;
    let col1 = floor(st1.x);
    let h_col1 = rui_hash33(vec3<i32>(i32(col1), 17, 3)).x;
    let vel_col1 = a.velocidad * (0.7 + 0.6 * h_col1);
    let y_escurre1 = st1.y - t_salida * vel_col1;
    let celda1 = vec2<i32>(i32(col1), i32(floor(y_escurre1)));
    let f1 = vec2<f32>(fract(st1.x), fract(y_escurre1));
    let h1 = rui_hash33(vec3<i32>(celda1.x, celda1.y, 7));

    if h1.x > 0.35 {
        let centro = vec2<f32>(0.25 + 0.5 * h1.x, 0.25 + 0.5 * h1.y);
        let radio = 0.16 + 0.18 * h1.z;
        let d = f1 - centro;
        let dist = length(d);
        if dist < radio {
            let l = dist / radio;
            let z = sqrt(max(1.0 - l * l, 0.0));
            offset += -d * (1.0 - z) / radio;
            borde_total += smoothstep(0.7, 1.0, l) * 0.35;
        } else if abs(d.x) < radio * 0.45 && d.y < 0.0 && d.y > -0.7 {
            // Estela vertical que deja la gota al escurrir
            let ancho = abs(d.x) / (radio * 0.45);
            let rastro = (1.0 - ancho * ancho) * smoothstep(-0.7, -0.1, d.y);
            offset += vec2<f32>(-sign(d.x) * rastro * 0.15, 0.0);
        }
    }

    // Capa 2: Gotículas menores estáticas
    let st2 = vec2<f32>(uv.x * aspecto, uv.y) * (a.escala * 2.2);
    let celda2 = vec2<i32>(vec2<f32>(floor(st2.x), floor(st2.y)));
    let f2 = fract(st2);
    let h2 = rui_hash33(vec3<i32>(celda2.x, celda2.y, 41));
    if h2.x > 0.6 {
        let centro2 = vec2<f32>(0.2 + 0.6 * h2.x, 0.2 + 0.6 * h2.y);
        let radio2 = 0.12 + 0.14 * h2.z;
        let d2 = f2 - centro2;
        let dist2 = length(d2);
        if dist2 < radio2 {
            let l2 = dist2 / radio2;
            let z2 = sqrt(max(1.0 - l2 * l2, 0.0));
            offset += -d2 * (1.0 - z2) / radio2 * 0.5;
            borde_total += smoothstep(0.65, 1.0, l2) * 0.25;
        }
    }

    let uv_distorsionada = uv + offset * (a.refraccion * fuerza);
    return ImgGotasResultado(uv_distorsionada, borde_total * fuerza);
}
