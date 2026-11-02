// Mapa de la aurora: el cielo fractal sobre el «disco del cielo» y la distancia con signo a su línea. PROPIO
// de Vulpe (especificación 06 §1–2). Porqué: docs/efectos/aurora.md §Mapa

const CIE_AURORA_NIVEL: f32 = 0.2;      // la línea: curva de nivel de la silueta
const CIE_AURORA_PASO: f32 = 0.002;     // diferencias finitas en el disco

// Disco del cielo: proyección ortográfica del hemisferio vista desde el cenit; (x, z) ↦ (x, √(1−x²−z²), z).
fn cie_aurora_direccion(p: vec2<f32>) -> vec3<f32> {
    return vec3<f32>(p.x, sqrt(max(1.0 - dot(p, p), 0.0)), p.y);
}

// rgb: color del fractal en esa dirección (sin el factor de noche); a: distancia con signo a la línea en
// unidades del disco (±1: ninguna cerca). Fuera del disco, nada.
fn cie_aurora_mapa(p: vec2<f32>, sol: vec3<f32>, a: CieFractalAjustes) -> vec4<f32> {
    if dot(p, p) >= 1.0 {
        return vec4<f32>(0.0, 0.0, 0.0, 1.0);
    }
    let dir = cie_aurora_direccion(p);
    let color = cie_fractal(CieFractalEscena(dir, sol, 1.0, 0.0), a);
    let s = cie_fractal_semilla(a.sorteo);
    let n = cie_fractal_cuantos(s, a.sorteo);
    let dx = cie_aurora_direccion(p + vec2<f32>(CIE_AURORA_PASO, 0.0));
    let dz = cie_aurora_direccion(p + vec2<f32>(0.0, CIE_AURORA_PASO));
    var distancia = 1.0;
    for (var i = 0; i < n; i++) {
        let inst = cie_fractal_instancia(i, s, n, a.sorteo);
        let punto = cie_fractal_punto(inst, dir);
        if punto.q2 * 4.0 / inst.alcance > 12.0 {
            continue;
        }
        let m0 = cie_fractal_silueta(inst, punto, a);
        let mx = cie_fractal_silueta(inst, cie_fractal_punto(inst, dx), a);
        let mz = cie_fractal_silueta(inst, cie_fractal_punto(inst, dz), a);
        let gradiente = vec2<f32>(mx - m0, mz - m0) / CIE_AURORA_PASO;
        // Un paso de Newton hacia la curva de nivel (Quílez, «Distance estimation»).
        let d = (m0 - CIE_AURORA_NIVEL) / max(length(gradiente), 1e-4);
        if abs(d) < abs(distancia) {
            distancia = d;
        }
    }
    return vec4<f32>(color, clamp(distancia, -1.0, 1.0));
}
