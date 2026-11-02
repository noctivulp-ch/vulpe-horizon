// Campo de estrellas fijo en una bóveda girada. Porqué: docs/efectos/cielo-y-atmosfera.md §Estrellas

struct CieAjustesEstrellas {
    celdas: f32,        // celdas de la rejilla por radián
    umbral: f32,        // fracción de esquinas sin estrella (0,99: una de cada cien)
    brillo: f32,        // radiancia de la estrella más brillante, escala común
}

// Giro fijo de la bóveda respecto a los ejes del mundo (para que no coincida con la rejilla de bloques).
fn cie_giro_boveda() -> mat3x3<f32> {
    let a = 0.6;    // alrededor de x
    let b = 1.1;    // alrededor de y
    let rx = mat3x3<f32>(1.0, 0.0, 0.0, 0.0, cos(a), sin(a), 0.0, -sin(a), cos(a));
    let ry = mat3x3<f32>(cos(b), 0.0, -sin(b), 0.0, 1.0, 0.0, sin(b), 0.0, cos(b));
    return ry * rx;
}

// Brillo de una esquina de la rejilla: 0 casi siempre, una estrella de brillo aleatorio en las demás.
fn cie_estrella_esquina(celda: vec3<i32>, umbral: f32) -> f32 {
    let h = rui_hash33(celda);
    let brillo = h.y * h.y * 0.9 + 0.1;     // muchas tenues, pocas brillantes
    return select(0.0, brillo, h.x > umbral);
}

// Intensidad de estrellas en `dir` (unitaria, ejes del mundo), en [0, ajustes.brillo]. Las esquinas se
// interpolan trilinealmente: al girar la cámara una estrella se desplaza suave, sin centellear.
fn cie_estrellas(dir: vec3<f32>, ajustes: CieAjustesEstrellas) -> f32 {
    let p = cie_giro_boveda() * dir * ajustes.celdas;
    let i = vec3<i32>(floor(p));
    let f = fract(p);
    var v = 0.0;
    for (var k = 0; k < 8; k++) {
        let o = vec3<i32>(k & 1, (k >> 1) & 1, (k >> 2) & 1);
        let w = mix(1.0 - f, f, vec3<f32>(o));
        v += cie_estrella_esquina(i + o, ajustes.umbral) * w.x * w.y * w.z;
    }
    // Afilado: la tienda trilineal mide dos celdas; al cubo queda un punto de 2–3 píxeles.
    return v * v * v * ajustes.brillo;
}
