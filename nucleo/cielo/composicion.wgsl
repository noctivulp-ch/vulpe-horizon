// Montaje del cielo: el suelo bajo el horizonte y el velo de la lluvia. Porqué: docs/efectos/cielo-y-atmosfera.md §Montaje

// 1 sobre el horizonte, cae como una gaussiana a 0 en unos pocos grados por debajo (sin escalón).
fn cie_factor_suelo(dir_y: f32, anchura: f32) -> f32 {
    let bajo = min(dir_y, 0.0) / anchura;
    return exp(-bajo * bajo);
}

struct CieLluvia {
    lluvia: f32,            // 0..1
    tormenta: f32,          // 0..1
    cielo_medio: vec3<f32>, // radiancia media del cielo despejado
}

// Cuánto de bruma (y no de suelo) hay en una dirección bajo el horizonte: 1 cerca de él, 0 mirando hacia abajo
// más de unos 30°. Lo comparten el cielo bajo el horizonte y la niebla de borde, para que casen.
fn cie_peso_bruma_horizonte(dir_y: f32) -> f32 {
    return 1.0 - smoothstep(0.15, 0.5, max(-dir_y, 0.0));
}

// Color del «suelo» que se ve bajo el horizonte más allá del terreno: oscuro y teñido del cielo, no el
// suelo iluminado de la tabla (que sale casi blanco con la exposición del día).
fn cie_color_bajo_horizonte(cielo_medio: vec3<f32>, suelo: vec3<f32>, oscuridad: f32) -> vec3<f32> {
    return mix(suelo, cielo_medio, 0.6) * oscuridad;
}

// Peso de la mezcla de lluvia por componente vertical de la vista (fino/01 §7, Tabla A).
// 0 en el cenit y último cuarto de bóveda; crece hacia el horizonte y satura por debajo.
fn cie_peso_lluvia_vertical(dir_y: f32) -> f32 {
    if dir_y >= 0.90 {
        return 0.0;
    }
    if dir_y >= 0.80 {
        let t = (0.90 - dir_y) / 0.10;
        return mix(0.0, 0.0488, t);
    }
    if dir_y >= 0.70 {
        let t = (0.80 - dir_y) / 0.10;
        return mix(0.0488, 0.1813, t);
    }
    if dir_y >= 0.50 {
        let t = (0.70 - dir_y) / 0.20;
        return mix(0.1813, 0.5507, t);
    }
    if dir_y >= 0.30 {
        let t = (0.50 - dir_y) / 0.20;
        return mix(0.5507, 0.8347, t);
    }
    if dir_y >= 0.20 {
        let t = (0.30 - dir_y) / 0.10;
        return mix(0.8347, 0.9137, t);
    }
    if dir_y >= 0.10 {
        let t = (0.20 - dir_y) / 0.10;
        return mix(0.9137, 0.9592, t);
    }
    if dir_y >= 0.0 {
        let t = (0.10 - dir_y) / 0.10;
        return mix(0.9592, 0.9826, t);
    }
    if dir_y >= -0.20 {
        let t = -dir_y / 0.20;
        return mix(0.9826, 0.9933, t);
    }
    return 0.9933;
}

// Mezcla el cielo con lluvia hacia el promedio despejado teñido por la transmitancia del rayo (fino/01 §7).
// Nula en el cenit y sobre la base de los cúmulos bajos. Sin oscurecimiento adicional de tormenta.
fn cie_aplicar_lluvia(cielo: vec3<f32>, dir_y: f32, trans: vec3<f32>, camara_y: f32, l: CieLluvia) -> vec3<f32> {
    if l.lluvia <= 0.001 {
        return cielo;
    }
    let factor_altura = 1.0 - clamp((camara_y - 238.0) / 200.0, 0.0, 1.0);
    let peso = l.lluvia * cie_peso_lluvia_vertical(dir_y) * factor_altura;
    let velo = l.cielo_medio * mix(vec3<f32>(1.0), trans, 0.35);
    return mix(cielo, velo, peso);
}
