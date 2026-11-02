// Cielo fractal: suma de las instancias de la noche en una dirección. PROPIO de Vulpe (especificación 02).
// Porqué: docs/efectos/cielo-fractal.md

struct CieFractalAjustes {
    sorteo: CieFractalSorteo,
    paleta: CiePaleta,
    dibujo: u32,
    iteraciones: i32,       // N de las Julia (×3 en las ampliaciones)
    mutacion: f32,          // 0..1
    brillo: f32,            // radiancia de escala, ya multiplicada
    techo: f32,             // misma escala; 0 sin techo
    hueco: f32,             // tamaño del hueco de los astros (0..400; 40 ceñido)
}

struct CieFractalEscena {
    dir: vec3<f32>,
    sol: vec3<f32>,         // dirección del sol (el hueco cubre también la luna, opuesta)
    noche: f32,             // 0..1
    estrellas: f32,         // máscara de estrellas 0..1 en esta dirección
}

// Valor de iteración t de la instancia en un punto de su plano (0 sin escape).
fn cie_fractal_t(inst: CieFractalInstancia, punto: CieFractalPunto, a: CieFractalAjustes) -> f32 {
    var p = punto.q * 6.0 / inst.escala;
    let cg = cos(inst.giro);
    let sg = sin(inst.giro);
    p = vec2<f32>(cg * p.x - sg * p.y, sg * p.x + cg * p.y);
    // Mutación: el parámetro da una vuelta pequeña con el día del mundo.
    let ang = a.sorteo.dia * MAT_TAU * 0.35;
    let paso = select(0.01, 0.02 * inst.zoom, inst.es_zoom);
    let c = inst.forma + vec2<f32>(cos(ang), sin(ang)) * a.mutacion * paso;
    let iteraciones = select(a.iteraciones, a.iteraciones * 3, inst.es_zoom);
    return cie_tiempo_de_escape(p, CieConjunto(c, inst.es_zoom, inst.zoom, iteraciones, a.dibujo));
}

// Máscara de silueta de la instancia (la de la aurora, 06): `smoothstep(0,03; 0,30; t)` × caída ancha × lejos
// del polo.
fn cie_fractal_silueta(inst: CieFractalInstancia, punto: CieFractalPunto, a: CieFractalAjustes) -> f32 {
    let t = cie_fractal_t(inst, punto, a);
    return smoothstep(0.03, 0.30, t) * exp2(-punto.q2 / inst.alcance) * punto.lejos_del_polo;
}

// Aporte de una instancia (relleno «Original»): t² · caída ancha · ganancia, con el tono de la paleta.
fn cie_fractal_aporte(inst: CieFractalInstancia, punto: CieFractalPunto, a: CieFractalAjustes) -> vec3<f32> {
    let t = cie_fractal_t(inst, punto, a);
    if t <= 0.0 {
        return vec3<f32>(0.0);
    }
    let tono = cie_tono(cie_paleta(t, inst.desfase_paleta, a.paleta), a.paleta.saturacion);
    let caida_ancha = exp2(-punto.q2 / inst.alcance);
    return tono * (t * t) * caida_ancha * punto.lejos_del_polo * 4.0;
}

fn cie_fractal(e: CieFractalEscena, a: CieFractalAjustes) -> vec3<f32> {
    let horizonte = smoothstep(-0.04, 0.12, e.dir.y);
    if e.noche <= 0.0 || horizonte <= 0.0 {
        return vec3<f32>(0.0);
    }
    let s = cie_fractal_semilla(a.sorteo);
    let n = cie_fractal_cuantos(s, a.sorteo);
    var suma = vec3<f32>(0.0);
    for (var i = 0; i < n; i++) {
        let inst = cie_fractal_instancia(i, s, n, a.sorteo);
        let punto = cie_fractal_punto(inst, e.dir);
        // Corte temprano: más allá no aporta nada representable.
        if punto.q2 * 4.0 / inst.alcance > 12.0 {
            continue;
        }
        suma += cie_fractal_aporte(inst, punto, a);
    }
    let pico = cie_techo(suma * a.brillo, a.techo);
    let hueco = 1.0 - pow(abs(dot(e.dir, e.sol)), 8000.0 / max(a.hueco, 1.0));
    return pico * horizonte * hueco * e.noche * (1.0 - clamp(e.estrellas * 3.0, 0.0, 1.0));
}
