// Tinte del follaje por estación: verano → otoño → invierno → primavera, con transiciones suaves.
// Porqué: docs/efectos/luz-de-superficie.md §Estaciones

// Tintes multiplicativos sobre el color de bioma (verano = sin cambio). x hierba, y hojas.
fn sup_tinte_estacion(k: i32, hojas: bool) -> vec3<f32> {
    switch k {
        case 1: { return select(vec3<f32>(1.15, 0.95, 0.6), vec3<f32>(1.7, 0.7, 0.28), hojas); }    // otoño
        case 2: { return select(vec3<f32>(0.85, 0.85, 0.8), vec3<f32>(0.8, 0.72, 0.78), hojas); }    // invierno (malva)
        case 3: { return select(vec3<f32>(0.92, 1.05, 0.98), vec3<f32>(0.9, 1.06, 1.0), hojas); }    // primavera
        default: { return vec3<f32>(1.0); }                                                        // verano
    }
}

// `dia`: día del mundo (con fracción); `duracion`: días por estación; `inicial`: 0 verano, 1 otoño, 2 invierno,
// 3 primavera. El último 25 % de cada estación funde con la siguiente.
fn sup_estacion(albedo: vec3<f32>, dia: f32, duracion: f32, inicial: i32, hojas: bool) -> vec3<f32> {
    let pos = dia / duracion + f32(inicial);
    let k = i32(floor(pos)) % 4;
    let f = smoothstep(0.75, 1.0, fract(pos));
    let t = mix(sup_tinte_estacion(k, hojas), sup_tinte_estacion((k + 1) % 4, hojas), f);
    // Un tinte multiplicativo no saca naranja de un verde (su rojo es bajo): la mitad del efecto se aplica llevando el
    // color hacia el tono del tinte con su misma luminancia.
    let hacia = vec3<f32>(col_luminancia(albedo)) * t / max(col_luminancia(t), 1e-3);
    var c = mix(albedo * t, hacia, select(0.0, 0.55, hojas) * select(0.0, 1.0, any(abs(t - vec3<f32>(1.0)) > vec3<f32>(0.01))));
    if k == 2 || (k == 1 && f > 0.0) {
        // El invierno desatura.
        let w = select(f, 1.0, k == 2) * select(1.0 - f, 1.0, k != 2);
        c = mix(c, vec3<f32>(col_luminancia(c)), 0.35 * w);
    }
    return c;
}
