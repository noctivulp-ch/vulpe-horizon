// Granos de arena movidos por el viento en biomas desérticos: ondulaciones finas alineadas
// con el viento, de 3 a 6 texeles de la rejilla de 32, que se desplazan despacio.
// Porqué: docs/efectos/suelo-clima.md §Arena

struct SupParamArenaViento {
    rejilla: f32,               // texeles por bloque (32)
    ancho: f32,                 // espaciado transversal medio, en texeles de 32 (3..6)
    largo: f32,                 // alargamiento en la dirección del viento, texeles de 32
    meandro_escala: vec2<f32>,  // frecuencia del meandro suave (u, v) en texeles⁻¹
    meandro_amp: f32,           // amplitud del meandro en ciclos
    velocidad_min: f32,         // texeles de 32 por segundo en nivel 1
    velocidad_max: f32,         // texeles de 32 por segundo en nivel 10
    nivel_min: f32,             // intensidad relativa en nivel 1
    nivel_max: f32,             // intensidad relativa en nivel 10
    contraste: f32,             // modulación de brillo en el albedo
    relieve: f32,               // inclinación de la normal de las ondulaciones
    dist_inicio: f32,           // bloques desde donde se atenúan
    dist_fin: f32,              // bloques donde se apagan para evitar aliasing
}

struct SupArenaViento {
    onda: f32,                  // -1..1: cresta (+1) o valle (-1) de la ondulación
    pendiente_xz: vec2<f32>,    // perturbación de normal en XZ
}

fn sup_arena_viento(
    mundo: vec3<f32>,
    cielo: f32,
    arriba: f32,
    dir_viento: vec2<f32>,
    tiempo: f32,
    peso: f32,
    nivel: f32,
    distancia: f32,
    p: SupParamArenaViento,
) -> SupArenaViento {
    if arriba <= 0.9 || peso <= 0.0 {
        return SupArenaViento(0.0, vec2<f32>(0.0));
    }
    let borde = rui_valor2(mundo.xz * 0.7) * 0.06;
    let expuesto = smoothstep(0.82, 0.92, cielo + borde);
    let lejos = 1.0 - smoothstep(p.dist_inicio, p.dist_fin, distancia);
    let fuerza_nivel = mix(p.nivel_min, p.nivel_max, clamp(nivel, 0.0, 1.0));
    let intensidad = peso * expuesto * lejos * fuerza_nivel;
    if intensidad <= 0.0 {
        return SupArenaViento(0.0, vec2<f32>(0.0));
    }

    // Cuantización a la rejilla de 32 texeles por bloque en coordenadas del mundo.
    let celda = floor(mundo.xz * p.rejilla);
    let perp = vec2<f32>(-dir_viento.y, dir_viento.x);
    let u = dot(celda, dir_viento);
    let v = dot(celda, perp);

    // Desplazamiento lento en la dirección del viento (más rápido cuanto mayor el nivel).
    let vel = mix(p.velocidad_min, p.velocidad_max, clamp(nivel, 0.0, 1.0));
    let u_mov = u - tiempo * vel;

    // Meandro suave para que las ondulaciones varíen entre 3 y 6 texeles sin líneas rígidas.
    let meandro = (rui_valor2(vec2<f32>(u_mov * p.meandro_escala.x, v * p.meandro_escala.y)) - 0.5) * 2.0;
    // Crestas de 3 a 6 texeles que avanzan despacio en la dirección del viento (+u).
    let fase = fract(u_mov / p.ancho + meandro * p.meandro_amp) * MAT_TAU;
    let seno = sin(fase);
    let coseno = cos(fase);

    // Envolvente de bancos de granos alargados en la dirección del viento que se desplazan con él.
    let vetas = rui_valor2(vec2<f32>(u_mov / p.largo, v / (p.ancho * 1.4)));
    let modulacion = 0.5 + 0.5 * vetas;

    let onda = seno * modulacion * intensidad;
    // Pendiente principal a lo largo del viento (crestas que avanzan) más leve variación transversal.
    let pend_u = coseno * modulacion * p.relieve * intensidad;
    let pend_v = (vetas - 0.5) * 0.35 * p.relieve * intensidad;
    let pendiente_xz = dir_viento * pend_u + perp * pend_v;
    return SupArenaViento(onda, pendiente_xz);
}

// Albedo de arena con ondulaciones: conserva el color propio (amarilla o roja en mesas).
fn sup_albedo_arena_viento(albedo: vec3<f32>, a: SupArenaViento, contraste: f32) -> vec3<f32> {
    return max(albedo * (1.0 + a.onda * contraste), vec3<f32>(0.0));
}
