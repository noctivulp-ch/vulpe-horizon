// Transmitancia a lo largo de un rayo hasta salir de la atmósfera. Porqué: docs/efectos/cielo-y-atmosfera.md §Modelo

// Transmitancia desde `origen` (m, desde el centro del planeta) en `dir` hasta el borde de la atmósfera;
// 0 si el planeta tapa. Regla del punto medio con `pasos` tramos.
fn atm_transmitancia(origen: vec3<f32>, dir: vec3<f32>, p: AtmParametros, bruma: f32, pasos: i32) -> vec3<f32> {
    let suelo = atm_esfera(origen, dir, p.radio_planeta);
    if suelo.x > 0.0 {
        return vec3<f32>(0.0);
    }
    let longitud = atm_esfera(origen, dir, p.radio_atmosfera).y;
    if longitud <= 0.0 {
        return vec3<f32>(1.0);
    }
    let paso = longitud / f32(pasos);
    var profundidad = vec3<f32>(0.0);
    for (var i = 0; i < pasos; i++) {
        let pos = origen + dir * (paso * (f32(i) + 0.5));
        profundidad += atm_medio(length(pos) - p.radio_planeta, p, bruma).extincion * paso;
    }
    return exp(-profundidad);
}
