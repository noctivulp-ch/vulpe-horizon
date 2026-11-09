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
