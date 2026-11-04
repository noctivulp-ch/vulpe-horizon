// Niebla del agua con la cámara dentro: raymarch corto con absorción, dispersión y la luz del sol absorbida desde
// la superficie (rayos de luz con la sombra). Porqué: docs/efectos/agua.md §Bajo el agua

struct VolAgua {
    superficie: f32,        // Y de la superficie del agua
    medio: AguMedio,
    minimo: vec3<f32>,      // luz ambiente mínima (que no sea negro)
}

fn vol_agua(rayo: VolRayo, luz: VolLuz, a: VolAgua, mapa_l: LuzMapa, mapa: texture_depth_2d, comparacion: sampler_comparison,
            con_sombra: bool) -> VolResultado {
    var r = VolResultado(vec3<f32>(0.0), 1.0, 0.0, vec3<f32>(0.0));
    let fin = min(rayo.escena, 96.0);
    let pasos = 8;
    let paso = fin / f32(pasos);
    // La extinción medida (paridad 07) es la total: la misma que la de la superficie.
    let sigma = a.medio.absorcion;
    let fase = vol_fase_niebla(dot(rayo.dir, luz.direccion));
    var t_acum = vec3<f32>(1.0);
    var luz_acum = vec3<f32>(0.0);
    for (var i = 0; i < pasos; i++) {
        let t = paso * (f32(i) + rayo.ruido);
        let p_rel = rayo.dir * t;
        let y = rayo.camara.y + p_rel.y;
        let hondo = max(a.superficie - y, 0.0) / max(luz.direccion.y, 0.15);
        var visible = 1.0;
        if con_sombra {
            let m = luz_posicion_mapa(mapa_l, p_rel);
            if all(m.xy > vec2<f32>(0.0)) && all(m.xy < vec2<f32>(1.0)) {
                visible = textureSampleCompareLevel(mapa, comparacion, m.xy, m.z);
            }
        }
        let sol = luz.irradiancia * visible * agu_transmitancia(a.medio, hondo) * fase;
        let ambiente = max(luz.cielo * agu_transmitancia(a.medio, max(a.superficie - y, 0.0)), a.minimo);
        let fuente = a.medio.dispersion * (sol * 0.5 + ambiente * a.medio.color_disperso);
        let tramo = exp(-sigma * paso);
        luz_acum += t_acum * fuente * (1.0 - tramo) / sigma;
        t_acum *= tramo;
    }
    r.luz = luz_acum;
    r.transmitancia = col_luminancia(t_acum);
    return r;
}
