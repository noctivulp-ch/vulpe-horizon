// Color y disco de los astros. Porqué: docs/efectos/cielo-y-atmosfera.md §Astros

// Color de un cuerpo negro en sRGB lineal, normalizado a luminancia 1. Ajuste de Tanner Helland
// («How to Convert Temperature (K) to RGB», 2012), válido de 1000 a 40000 K; sus curvas dan valores
// codificados, que se pasan a lineal.
fn atm_cuerpo_negro(kelvin: f32) -> vec3<f32> {
    let t = clamp(kelvin, 1000.0, 40000.0) / 100.0;
    var c: vec3<f32>;
    if t <= 66.0 {
        c.r = 255.0;
        c.g = 99.4708025861 * log(t) - 161.1195681661;
        c.b = select(138.5177312231 * log(t - 10.0) - 305.0447927307, 0.0, t <= 19.0);
    } else {
        c.r = 329.698727446 * pow(t - 60.0, -0.1332047592);
        c.g = 288.1221695283 * pow(t - 60.0, -0.0755148492);
        c.b = 255.0;
    }
    let lineal = col_srgb_a_lineal(clamp(c / 255.0, vec3<f32>(0.0), vec3<f32>(1.0)));
    return lineal / max(col_luminancia(lineal), MAT_EPSILON);
}

// 1 dentro del disco de radio angular `radio` (rad), con borde suave de `borde` (fracción del radio).
fn atm_disco(cos_vista_astro: f32, radio: f32, borde: f32) -> f32 {
    let dentro = cos(radio * (1.0 - borde));
    let fuera = cos(radio * (1.0 + borde));
    return smoothstep(fuera, dentro, cos_vista_astro);
}

// Luz directa del sol según su elevación en grados (escala común: cenit = [1.096, 0.991, 0.8062], luma 1.0).
// Anulación estricta a <= 0° por rampa de horizonte.
// Porqué: docs/efectos/cielo-y-atmosfera.md §Luz directa
fn atm_luz_directa_sol(elev: f32) -> vec3<f32> {
    if elev <= 0.0 {
        return vec3<f32>(0.0);
    }
    if elev < 1.0 {
        let t = elev;
        return mix(vec3<f32>(0.0), vec3<f32>(0.03398, 0.007042, 0.0001347), t);
    }
    if elev < 2.0 {
        let t = elev - 1.0;
        return mix(vec3<f32>(0.03398, 0.007042, 0.0001347), vec3<f32>(0.1891, 0.05665, 0.002768), t);
    }
    if elev < 4.0 {
        let t = (elev - 2.0) * 0.5;
        return mix(vec3<f32>(0.1891, 0.05665, 0.002768), vec3<f32>(0.554, 0.2464, 0.03296), t);
    }
    if elev < 6.0 {
        let t = (elev - 4.0) * 0.5;
        return mix(vec3<f32>(0.554, 0.2464, 0.03296), vec3<f32>(0.6674, 0.3634, 0.0813), t);
    }
    if elev < 8.0 {
        let t = (elev - 6.0) * 0.5;
        return mix(vec3<f32>(0.6674, 0.3634, 0.0813), vec3<f32>(0.7481, 0.4595, 0.1397), t);
    }
    if elev < 10.0 {
        let t = (elev - 8.0) * 0.5;
        return mix(vec3<f32>(0.7481, 0.4595, 0.1397), vec3<f32>(0.8077, 0.5372, 0.2001), t);
    }
    if elev < 15.0 {
        let t = (elev - 10.0) * 0.2;
        return mix(vec3<f32>(0.8077, 0.5372, 0.2001), vec3<f32>(0.9041, 0.6745, 0.3366), t);
    }
    if elev < 20.0 {
        let t = (elev - 15.0) * 0.2;
        return mix(vec3<f32>(0.9041, 0.6745, 0.3366), vec3<f32>(0.9605, 0.7615, 0.4437), t);
    }
    if elev < 30.0 {
        let t = (elev - 20.0) * 0.1;
        return mix(vec3<f32>(0.9605, 0.7615, 0.4437), vec3<f32>(1.022, 0.8623, 0.5884), t);
    }
    if elev < 40.0 {
        let t = (elev - 30.0) * 0.1;
        return mix(vec3<f32>(1.022, 0.8623, 0.5884), vec3<f32>(1.054, 0.9169, 0.6761), t);
    }
    if elev < 55.0 {
        let t = (elev - 40.0) / 15.0;
        return mix(vec3<f32>(1.054, 0.9169, 0.6761), vec3<f32>(1.079, 0.9607, 0.7516), t);
    }
    if elev < 70.0 {
        let t = (elev - 55.0) / 15.0;
        return mix(vec3<f32>(1.079, 0.9607, 0.7516), vec3<f32>(1.091, 0.9821, 0.7899), t);
    }
    if elev < 90.0 {
        let t = (elev - 70.0) * 0.05;
        return mix(vec3<f32>(1.091, 0.9821, 0.7899), vec3<f32>(1.096, 0.991, 0.8062), t);
    }
    return vec3<f32>(1.096, 0.991, 0.8062);
}

// Luz directa de la luna según la elevación del sol en grados.
// Anulación a >= 0° y transición suave hasta -4°.
// Porqué: docs/efectos/cielo-y-atmosfera.md §Luz directa
fn atm_luz_directa_luna(elev_sol: f32) -> vec3<f32> {
    if elev_sol >= 0.0 {
        return vec3<f32>(0.0);
    }
    if elev_sol <= -4.0 {
        return vec3<f32>(0.002473, 0.003302, 0.005518);
    }
    if elev_sol <= -2.0 {
        let t = (elev_sol - (-2.0)) * -0.5;
        return mix(vec3<f32>(0.001205, 0.001608, 0.002689), vec3<f32>(0.002473, 0.003302, 0.005518), t);
    }
    let t = elev_sol * -0.5;
    return mix(vec3<f32>(0.0), vec3<f32>(0.001205, 0.001608, 0.002689), t);
}

// Luz ambiente de cielo sobre una superficie horizontal según la elevación del sol en grados, en la escala común:
// tabla medida de paridad/01 §«Luz directa y ambiente de cielo» (19 filas, de −12° a 90°; por debajo, la de −12°, que ya
// es la de la noche con luna). Porqué: docs/efectos/luz-de-superficie.md §«Ambiente medido» (F-12)
const ATM_AMBIENTE_ELEV = array<f32, 19>(-12.0, -8.0, -6.0, -4.0, -2.0, 0.0, 1.0, 2.0, 4.0, 6.0, 8.0, 10.0, 15.0, 20.0, 30.0,
    40.0, 55.0, 70.0, 90.0);
const ATM_AMBIENTE_RGB = array<vec3<f32>, 19>(
    vec3<f32>(3.866e-05, 0.0001203, 0.0005483), vec3<f32>(3.569e-05, 0.0001048, 0.0004177),
    vec3<f32>(8.594e-05, 0.0001476, 0.0003841), vec3<f32>(0.0008634, 0.001043, 0.001525),
    vec3<f32>(0.004269, 0.005494, 0.007457), vec3<f32>(0.01447, 0.01676, 0.02249), vec3<f32>(0.01951, 0.026, 0.03396),
    vec3<f32>(0.02351, 0.03592, 0.04938), vec3<f32>(0.02908, 0.05326, 0.09091), vec3<f32>(0.03254, 0.06562, 0.1346),
    vec3<f32>(0.03479, 0.07329, 0.1637), vec3<f32>(0.0359, 0.07574, 0.1644), vec3<f32>(0.03752, 0.07695, 0.1531),
    vec3<f32>(0.04052, 0.08341, 0.1738), vec3<f32>(0.04687, 0.09407, 0.202), vec3<f32>(0.04726, 0.09759, 0.217),
    vec3<f32>(0.04906, 0.1025, 0.2329), vec3<f32>(0.04932, 0.1047, 0.2414), vec3<f32>(0.04982, 0.1059, 0.2453),
);

fn atm_ambiente_cielo(elev: f32) -> vec3<f32> {
    if elev <= ATM_AMBIENTE_ELEV[0] {
        return ATM_AMBIENTE_RGB[0];
    }
    for (var i = 1; i < 19; i++) {
        if elev < ATM_AMBIENTE_ELEV[i] {
            let t = (elev - ATM_AMBIENTE_ELEV[i - 1]) / (ATM_AMBIENTE_ELEV[i] - ATM_AMBIENTE_ELEV[i - 1]);
            return mix(ATM_AMBIENTE_RGB[i - 1], ATM_AMBIENTE_RGB[i], t);
        }
    }
    return ATM_AMBIENTE_RGB[18];
}
