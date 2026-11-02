// Cielo fractal, modo automático: sorteo de las instancias de cada noche y su alcance en una dirección.
// Compartido (lo usan también la aurora y los rayos). PROPIO de Vulpe (especificación 02 §3).
// Porqué: docs/efectos/cielo-fractal.md §Colocación

struct CieFractalSorteo {
    semilla_opcion: i32,
    semilla_mundo: i32,     // 0 sin mod nativo
    dia: f32,               // número de día + fracción
    cambios_por_noche: bool,
    max_conjuntos: i32,
    cobertura: f32,         // % del hemisferio, 1..100
}

struct CieFractalInstancia {
    activa: bool,
    colocacion: mat3x3<f32>,    // lleva el cenit al eje de la instancia (su traspuesta, el eje al cenit)
    escala: f32,                // del plano estereográfico al complejo: p = q · 6 / escala
    alcance: f32,               // anchura de la caída por distancia («cover»)
    forma: vec2<f32>,           // c de la Julia, o centro de la ampliación del Mandelbrot
    es_zoom: bool,
    zoom: f32,                  // factor k de la ampliación
    desfase_paleta: f32,
    giro: f32,                  // ángulo propio en el plano (rad), ya con el giro por día
}

// Hash escalar de la semilla y un índice, en [0, 1). PCG sobre los bits de la semilla: igual en toda GPU.
fn cie_fractal_azar(s: f32, k: f32) -> f32 {
    return rui_u32_a_unidad(rui_pcg(bitcast<u32>(s) ^ rui_pcg(u32(k))));
}

fn cie_fractal_semilla(a: CieFractalSorteo) -> f32 {
    var s = f32(a.semilla_opcion) * 7.13 + 1.0;
    if a.semilla_mundo != 0 {
        // Plegada a un número pequeño: la semilla del mundo es enorme y perdería bits en f32.
        s += fract(f32(a.semilla_mundo % 4096) * 0.000244140625 * 7.0 + f32(a.semilla_mundo / 4096) * 0.6180339887) * 97.0;
    }
    if a.cambios_por_noche {
        s += floor(a.dia) * 13.71;
    }
    return s;
}

fn cie_fractal_cuantos(s: f32, a: CieFractalSorteo) -> i32 {
    return 1 + i32(floor(cie_fractal_azar(s, 1.0) * f32(a.max_conjuntos) * 0.999));
}

fn cie_fractal_instancia(i: i32, s: f32, n: i32, a: CieFractalSorteo) -> CieFractalInstancia {
    var inst: CieFractalInstancia;
    inst.activa = i < n;
    if !inst.activa {
        return inst;
    }
    // Áreas: la cobertura total repartida con pesos aleatorios, ±5 puntos alrededor de la elegida.
    var suma = 0.0;
    var mio = 0.0;
    for (var k = 0; k < n; k++) {
        let w = 0.35 + cie_fractal_azar(s, 10.0 + f32(k));
        suma += w;
        if k == i {
            mio = w;
        }
    }
    let cobertura = clamp(a.cobertura + (cie_fractal_azar(s, 70.0) * 2.0 - 1.0) * 5.0, 1.0, 100.0);
    let area = cobertura * 0.01 * MAT_TAU * mio / suma;
    let rho = min(acos(clamp(1.0 - area / MAT_TAU, -1.0, 1.0)), radians(80.0));

    // Sitio: espiral de Fibonacci de área igual sobre el hemisferio, del cenit hacia el horizonte.
    let cenital = acos(1.0 - (f32(i) + 0.5) / f32(n) * 0.82);
    let azimut = f32(i) * 2.39996 + cie_fractal_azar(s, 2.0) * MAT_TAU;
    let ry = mat3x3<f32>(cos(azimut), 0.0, -sin(azimut), 0.0, 1.0, 0.0, sin(azimut), 0.0, cos(azimut));
    let rx = mat3x3<f32>(1.0, 0.0, 0.0, 0.0, cos(cenital), sin(cenital), 0.0, -sin(cenital), cos(cenital));
    inst.colocacion = ry * rx;

    // Forma: ángulo áureo sobre el borde del cardioide (pares) o del bulbo de periodo 2 (impares).
    let th = fract(cie_fractal_azar(s, 3.0) + f32(i) * 0.6180339887) * MAT_TAU;
    let par = (i % 2) == 0;
    var borde = vec2<f32>(-1.0, 0.0) + 0.25 * vec2<f32>(cos(th), sin(th));
    if par {
        borde = vec2<f32>(0.5 * cos(th) - 0.25 * cos(2.0 * th), 0.5 * sin(th) - 0.25 * sin(2.0 * th));
    }
    inst.es_zoom = (i % 3) == 2;
    let centro_bulbo = select(vec2<f32>(-1.0, 0.0), vec2<f32>(0.0), par);
    let fuera = 1.0 + 0.06 * cie_fractal_azar(s, 20.0 + f32(i));
    inst.forma = select(centro_bulbo + (borde - centro_bulbo) * fuera, borde, inst.es_zoom);
    inst.zoom = select(0.0, mix(0.004, 0.03, cie_fractal_azar(s, 30.0 + f32(i))), inst.es_zoom);

    // Tamaño: el borde de la figura en el borde del casquete.
    let radio_figura = select(0.5 + 0.5 * sqrt(1.0 + 4.0 * length(inst.forma)), 1.6, inst.es_zoom);
    let q_borde = tan(rho * 0.5);
    inst.escala = 6.0 * q_borde / radio_figura;
    inst.alcance = max(q_borde * q_borde * 1.5, 1e-4);

    inst.desfase_paleta = cie_fractal_azar(s, 40.0 + f32(i));
    let velocidad = (cie_fractal_azar(s, 50.0 + f32(i)) - 0.5) * 0.5;
    let inicial = radians(cie_fractal_azar(s, 60.0 + f32(i)) * 360.0);
    inst.giro = inicial + velocidad * a.dia;
    return inst;
}

struct CieFractalPunto {
    q: vec2<f32>,           // plano estereográfico desde el eje (|q| = 1 en el horizonte del eje)
    q2: f32,                // |q|²
    lejos_del_polo: f32,    // 0 cerca de la antípoda del eje, donde la proyección va a infinito
}

// Dónde cae `dir` en el plano de la instancia.
fn cie_fractal_punto(inst: CieFractalInstancia, dir: vec3<f32>) -> CieFractalPunto {
    let local = transpose(inst.colocacion) * dir;
    let den = 1.0 + local.y;
    let q = local.xz / max(den, 1e-3);
    return CieFractalPunto(q, dot(q, q), smoothstep(0.02, 0.45, den));
}

// Cuánto alcanza la instancia en ese punto, 0..1 (caída por distancia).
fn cie_fractal_alcance(inst: CieFractalInstancia, punto: CieFractalPunto) -> f32 {
    return exp2(-punto.q2 * 4.0 / inst.alcance) * punto.lejos_del_polo;
}
